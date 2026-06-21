/* ld370 - host-native MVS linkage editor (prototype).
 *
 * Reads one or more OS/360 object decks (as produced by as370 / IFOX00) and
 * emits an MVS load-module member RECORD STREAM, byte-identical to IEWL
 * (F-level) over the deterministic records. The IDR identity records
 * (LKED/translator) are NOT emitted -- ld stamps its own identity, a
 * documented carve-out (see ld/tests/lmdiff.py). Byte-exact target:
 *     CESD + SPZAP-IDR(251B zeros) + control + text + RLD
 *
 * Scope: multiple single-CSECT objects (the cc370/as370 case). Builds a
 * composite ESD, resolves ER->SD by name across objects, stacks section
 * origins, relocates address constants, and remaps RLDs to global ESDIDs /
 * module-relative addresses. Validated against the ld/tests/fixtures oracles.
 *
 * Automatic library call: -L DIR / -l NAME autocall unresolved ERs against an
 * ar370 archive (libNAME.a).  When a wanted symbol has several definers (e.g.
 * @@CRT0 by @@crt0/@@crt1/@@crtm), the one that does NOT also re-define an
 * already-resolved section is preferred, so a "bundle" member cannot drag a
 * duplicate startup into the link.  --include/-i NAME force-includes a member
 * (by basename or a symbol it defines) BEFORE autocall -- the IEWL INCLUDE
 * equivalent for pinning a specific runtime variant (e.g. --include @@CRT1).
 * --entry/-e NAME sets the load-module entry point.
 *
 * Build:  gcc -O2 -Wall -Wextra -Werror -o ld/ld370 ld/ld370.c
 * Usage:  ld370 [--verbose] -o OUT.bin OBJ1.obj [OBJ2.obj ...]
 *               [-L DIR -l NAME] [--include NAME] [--entry NAME]
 */
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* ---- big-endian field access ---- */
static int be16(const unsigned char *p) { return (p[0] << 8) | p[1]; }
static long be24(const unsigned char *p) { return ((long)p[0] << 16) | (p[1] << 8) | p[2]; }
static void put16(unsigned char *p, int v) { p[0] = (v >> 8) & 0xff; p[1] = v & 0xff; }
static void put24(unsigned char *p, long v) { p[0] = (v >> 16) & 0xff; p[1] = (v >> 8) & 0xff; p[2] = v & 0xff; }
static long rdval(const unsigned char *p, int n) { long v = 0; int i; for (i = 0; i < n; i++) v = (v << 8) | p[i]; return v; }
static void wrval(unsigned char *p, long v, int n) { int i; for (i = n - 1; i >= 0; i--) { p[i] = v & 0xff; v >>= 8; } }
static long roundup8(long v) { return (v + 7) & ~7L; }

/* ---- verbose trace: narrate the linker's phases (off by default) ---- */
static int verbose = 0;
/* leftover strong (type-02) ERs zero-fill to a NULL adcon -> the module installs
 * clean but S0C4s on the first indirect call.  Fail the link by default; only an
 * explicit --allow-unresolved leaves them for the loader. */
static int allow_unresolved = 0;
static void trace(const char *fmt, ...)
{
    va_list ap;
    if (!verbose) return;
    fputs("[ld370] ", stderr);
    va_start(ap, fmt); vfprintf(stderr, fmt, ap); va_end(ap);
    fputc('\n', stderr);
}
static char e2a1(unsigned char e)
{
    if (e >= 0xC1 && e <= 0xC9) return (char)('A' + (e - 0xC1));
    if (e >= 0xD1 && e <= 0xD9) return (char)('J' + (e - 0xD1));
    if (e >= 0xE2 && e <= 0xE9) return (char)('S' + (e - 0xE2));
    if (e >= 0xF0 && e <= 0xF9) return (char)('0' + (e - 0xF0));
    if (e == 0x40) return ' ';
    if (e == 0x5B) return '$'; if (e == 0x7B) return '#';
    if (e == 0x7C) return '@'; if (e == 0x6D) return '_';
    return '?';
}
static const char *nm(const unsigned char *n)
{
    static char b[9]; int i;
    for (i = 0; i < 8; i++) b[i] = e2a1(n[i]);
    b[8] = 0;
    for (i = 7; i >= 0 && b[i] == ' '; i--) b[i] = 0;
    return b;
}
/* ASCII -> EBCDIC (CP037), single char; inverse of e2a1. Unmappable -> space. */
static unsigned char a2e1(char a)
{
    if (a >= 'A' && a <= 'I') return (unsigned char)(0xC1 + (a - 'A'));
    if (a >= 'J' && a <= 'R') return (unsigned char)(0xD1 + (a - 'J'));
    if (a >= 'S' && a <= 'Z') return (unsigned char)(0xE2 + (a - 'S'));
    if (a >= '0' && a <= '9') return (unsigned char)(0xF0 + (a - '0'));
    if (a == '$') return 0x5B; if (a == '#') return 0x7B;
    if (a == '@') return 0x7C; if (a == '_') return 0x6D;
    return 0x40;
}
/* build an 8-byte EBCDIC, space-padded member name from an ASCII string */
static void member_name(unsigned char d[8], const char *s)
{
    int i, n = (int)strlen(s);
    for (i = 0; i < 8; i++) {
        char c = (i < n) ? s[i] : ' ';
        if (c >= 'a' && c <= 'z') c = (char)(c - 'a' + 'A');
        d[i] = a2e1(c);
    }
}

/* ---- model ----
 * MAXESD bounds one OBJECT's local ESD (small); MAXOBJ and MAXG bound the
 * whole link -- a real C program autocalls a large runtime closure, so these
 * are sized for hundreds of pulled members and thousands of composite symbols. */
#define MAXESD 512
#define MAXOBJ 1024
#define MAXG   8192
#define MAXTEXT 18432             /* pack member-data into logical records <= this; must stay
                                   * <= the unload BLKSIZE (below) so RECVRCPY writes each one
                                   * in a single unblocked PUT -- a record larger than BLKSIZE
                                   * would span and break the IEBCOPY reload (IEB139I) */
/* The IEBCOPY-unloaded form's BLKSIZE.  Real IEBCOPY's unload DCB-exit forces
 * BLKSIZE = MINBLK = 12 + 8 + keylen + source-BLKSIZE (IEBLDUL); a load library
 * has keylen=0, so for a 19069-byte source library it is 19089.  ld370 must
 * declare this in the INMCOPY INMR02 so RECVRCPY blocks SYSUT1 wide enough to
 * hold a full member-data record unspanned (the 3120 it replaced was xmit370's
 * static template placeholder, never the real unloaded blocksize). */
#define UNLOAD_SRC_BLKSIZE 19069
#define UNLOAD_BLKSIZE     (12 + 8 + 0 + UNLOAD_SRC_BLKSIZE)   /* IEBCOPY MINBLK = 19089 */
enum { T_SD = 0x00, T_LD = 0x01, T_ER = 0x02, T_PC = 0x04, T_CM = 0x05 };
static int is_sect_type(int t) { return t == T_SD || t == T_PC || t == T_CM; }

/* composite (global) symbol = one CESD entry */
struct gsym { unsigned char name[8]; int type; int is_sect; int gid; long org, len;
              int def_obj; long in_addr;   /* section: defining object + origin within it */
              int owner; };                /* LR (label/entry): gsym index of the owning section */
static struct gsym G[MAXG];
static int nG = 0;

static int g_find(const unsigned char *name)
{
    int i;
    for (i = 0; i < nG; i++)
        if (memcmp(G[i].name, name, 8) == 0) return i;
    return -1;
}
/* a fresh composite symbol, NOT merged by name -- for private code (PC)
 * sections, which are distinct per object even though they share a blank name */
static int g_new(const unsigned char *name)
{
    if (nG >= MAXG) { fprintf(stderr, "ld370: composite symbol table full (MAXG=%d)\n", MAXG); exit(1); }
    memcpy(G[nG].name, name, 8);
    G[nG].type = 0; G[nG].is_sect = 0; G[nG].gid = 0; G[nG].org = 0; G[nG].len = 0;
    G[nG].def_obj = -1; G[nG].in_addr = 0; G[nG].owner = -1;
    return nG++;
}
static int g_intern(const unsigned char *name, int type)
{
    int i = g_find(name);
    if (i >= 0) return i;
    i = g_new(name);
    G[i].type = type;
    return i;
}

/* per input object (each is single-CSECT in the cc370/as370 case) */
struct lent { int used; unsigned char name[8]; int type; long addr, len; };
struct orld { int R, P, flag; long addr; };
struct obj {
    struct lent loc[MAXESD];          /* local ESD by local ESDID */
    int loc_g[MAXESD];                /* composite gsym index for each local ESDID */
    int sect_local;                   /* local id of this object's section */
    unsigned char *text;              /* object text, grown on demand (was a fixed 16384-byte */
    long textcap;                     /*   buffer that SILENTLY dropped text past 16K -> any   */
    long textlen;                     /*   module > 16K truncated to zeros, S0C1 at run time)  */
    struct orld rld[512];
    int nrld;
    struct { unsigned char name[8]; long addr; int owner_local; } ld[64];   /* label defs (entries) */
    int nld;
    long object_base;                 /* assigned base address of this object's section(s) */
    int has_entry, entry_id; long entry_off;   /* END-card entry: section local ESDID + offset */
};
static struct obj O[MAXOBJ];
static int nO = 0;
static long entry_pt = 0;

/* read a whole file into a malloc'd buffer (caller frees) */
static unsigned char *read_file(const char *path, long *len)
{
    FILE *f = fopen(path, "rb"); long n; unsigned char *b; size_t got;
    if (!f) { perror(path); return NULL; }
    fseek(f, 0, SEEK_END); n = ftell(f); fseek(f, 0, SEEK_SET);
    b = malloc((size_t)(n > 0 ? n : 1));
    got = fread(b, 1, (size_t)n, f); (void)got; fclose(f);
    *len = n; return b;
}

/* ---- PASS 1: object-deck reader (inverse of as370.c) ---- */
static void parse_object(const unsigned char *buf, long len, struct obj *o)
{
    long off;
    memset(o, 0, sizeof *o);
    o->sect_local = -1;
    for (off = 0; off + 80 <= len; off += 80) {
        const unsigned char *c = buf + off;
        if (c[0] != 0x02) continue;
        if (c[1] == 0xC5 && c[2] == 0xE2 && c[3] == 0xC4) {            /* ESD */
            int cnt = be16(c + 10), first = be16(c + 14), k, nid = 0;
            for (k = 0; k < cnt / 16; k++) {
                const unsigned char *e = c + 16 + k * 16;
                int ty = e[8] & 0x0f;
                if (ty == T_LD) {            /* label def (entry): carries no ESDID; record for the composite ESD */
                    if (o->nld < 64) {
                        memcpy(o->ld[o->nld].name, e, 8);
                        o->ld[o->nld].addr = be24(e + 9);
                        o->ld[o->nld].owner_local = (int)be24(e + 13);   /* owning section's local ESDID */
                        o->nld++;
                    }
                    continue;
                }
                int id = first + nid; nid++;                 /* non-LD entries are numbered; LD slots are skipped */
                if (id < 1 || id >= MAXESD) continue;
                o->loc[id].used = 1;
                memcpy(o->loc[id].name, e, 8);
                o->loc[id].type = ty;
                o->loc[id].addr = be24(e + 9);
                o->loc[id].len = be24(e + 13);
                if (is_sect_type(ty) && o->sect_local < 0) o->sect_local = id;
                trace("  ESD id=%d  %-8s  %s  len=%06lX", id, nm(o->loc[id].name),
                      is_sect_type(ty) ? "SD(section)" : ty == T_ER ? "ER(extern ref)" : "?",
                      o->loc[id].len);
            }
        } else if (c[1] == 0xE3 && c[2] == 0xE7 && c[3] == 0xE3) {     /* TXT */
            long addr = be24(c + 5), cnt = be16(c + 10), need = addr + cnt;
            if (need > o->textcap) {                       /* grow on demand; never silently drop */
                long ncap = o->textcap ? o->textcap : 4096;
                unsigned char *nt;
                while (ncap < need) ncap *= 2;
                nt = realloc(o->text, (size_t)ncap);
                if (!nt) { fprintf(stderr, "ld370: out of memory for object text (%ld bytes)\n", ncap); exit(1); }
                memset(nt + o->textcap, 0, (size_t)(ncap - o->textcap));   /* zero-fill gaps */
                o->text = nt; o->textcap = ncap;
            }
            if (cnt > 0) {
                memcpy(o->text + addr, c + 16, cnt);
                if (need > o->textlen) o->textlen = need;
            }
            trace("  TXT  %ld bytes -> local section id=%d at offset %06lX", cnt, be16(c + 14), addr);
        } else if (c[1] == 0xD9 && c[2] == 0xD3 && c[3] == 0xC4) {     /* RLD */
            int cnt = be16(c + 10), p = 16, end = 16 + cnt, R = 0, P = 0, same = 0;
            while (p + 4 <= end && p + 4 <= 80) {
                if (!same) { R = be16(c + p); P = be16(c + p + 2); p += 4; }
                if (p + 4 > end) break;
                o->rld[o->nrld].R = R; o->rld[o->nrld].P = P;
                o->rld[o->nrld].flag = c[p]; o->rld[o->nrld].addr = be24(c + p + 1);
                same = c[p] & 0x01; p += 4; o->nrld++;
            }
        } else if (c[1] == 0xC5 && c[2] == 0xD5 && c[3] == 0xC4) {     /* END */
            if (!(c[5] == 0x40 && c[6] == 0x40 && c[7] == 0x40)) {     /* entry by section ESDID + offset */
                entry_pt = be24(c + 5);
                o->has_entry = 1; o->entry_id = be16(c + 14); o->entry_off = be24(c + 5);
            }
        }
    }
}

/* map a local ESDID in object o to its index in the composite symbol table
 * (the mapping is built in PASS 2; uses loc_g so private blank-named PC
 * sections map to THIS object's section, not the first blank one by name) */
static int local_to_g(struct obj *o, int localid)
{
    if (localid < 1 || localid >= MAXESD || !o->loc[localid].used) return -1;
    return o->loc_g[localid];
}

/* ---- automatic library call (autocall) ----
 * After the explicit objects are read, pull from the archives (.a, ar370
 * format) any member that defines a still-unresolved ER, to a fixpoint:
 * pulling a member may expose new ERs that pull further members.  Members are
 * object decks, so a pulled member is just another parse_object into O[].
 * Runs as a standalone step BEFORE the composite ESD is built, so it does not
 * perturb the ESDID order (appearance order: explicit objects, then pulls). */
#define MAXAR 32
#define MAXARSYM 16384
#define MAXARMEM 4096
struct archive {
    unsigned char *data; long size;
    struct { char name[64]; long off; } sym[MAXARSYM];
    int nsym;
    struct { char name[64]; long off; } mem[MAXARMEM];   /* member basenames, for --include */
    int nmem;
};
static struct archive AR[MAXAR];
static int nAR = 0;
static struct { int ar; long off; } pulled[MAXOBJ];
static int npulled = 0;

/* load an ar370/GNU `ar` archive and parse its "/" symbol table */
static int load_archive(const char *path)
{
    long n, p; unsigned char *a; struct archive *ar;
    if (nAR >= MAXAR) { fprintf(stderr, "ld370: too many archives\n"); return 1; }
    a = read_file(path, &n);
    if (!a) return 1;
    if (n < 8 || memcmp(a, "!<arch>\n", 8)) { fprintf(stderr, "ld370: %s: not an archive\n", path); free(a); return 1; }
    ar = &AR[nAR]; ar->data = a; ar->size = n; ar->nsym = 0; ar->nmem = 0;
    /* first member must be the "/" symbol table */
    if (a[8] == '/' && a[9] == ' ') {
        long q = 8 + 60;
        unsigned long cnt = ((unsigned long)a[q] << 24) | ((unsigned long)a[q+1] << 16)
                          | ((unsigned long)a[q+2] << 8) | a[q+3], k;
        const char *names = (const char *)(a + q + 4 + 4 * cnt);
        for (k = 0; k < cnt && ar->nsym < MAXARSYM; k++) {
            long off = ((long)a[q+4+4*k] << 24) | ((long)a[q+4+4*k+1] << 16)
                     | ((long)a[q+4+4*k+2] << 8) | a[q+4+4*k+3];
            strncpy(ar->sym[ar->nsym].name, names, 63);
            ar->sym[ar->nsym].name[63] = 0;
            ar->sym[ar->nsym].off = off;
            ar->nsym++;
            names += strlen(names) + 1;
        }
    }
    /* member-name table (for --include by member name): walk every header,
     * resolving GNU short ("name/") and long ("/NNN" -> "//" member) names. */
    {
        long q = 8; const unsigned char *longnames = NULL; long longlen = 0;
        while (q + 60 <= n) {
            char szs[11]; long msize; int k, L = 0; char nmbuf[64];
            memcpy(szs, a + q + 48, 10); szs[10] = 0; msize = atol(szs);
            if (a[q] == '/' && a[q + 1] == '/') {                 /* long-name table */
                longnames = a + q + 60; longlen = msize;
            } else if (a[q] == '/' && (a[q + 1] == ' ' || a[q + 1] == 0x60)) {
                /* "/" symbol table -- skip */
            } else if (ar->nmem < MAXARMEM) {
                if (a[q] == '/' && a[q + 1] >= '0' && a[q + 1] <= '9' && longnames) {
                    long lo = atol((const char *)(a + q + 1));    /* /NNN -> offset in "//" */
                    while (lo < longlen && longnames[lo] != '/' && longnames[lo] != '\n' && L < 63)
                        nmbuf[L++] = (char)longnames[lo++];
                } else {
                    for (k = 0; k < 16 && a[q + k] != '/' && a[q + k] != ' ' && L < 63; k++)
                        nmbuf[L++] = (char)a[q + k];
                }
                nmbuf[L] = 0;
                strcpy(ar->mem[ar->nmem].name, nmbuf); ar->mem[ar->nmem].off = q; ar->nmem++;
            }
            q += 60 + msize + (msize & 1);
        }
    }
    (void)p;
    nAR++;
    trace("- archive %s: %d exported symbol(s), %d member(s)", path, ar->nsym, ar->nmem);
    return 0;
}

/* is symbol name (8-byte EBCDIC) defined by any loaded object (SD/PC/CM/LD)? */
static int is_defined(const unsigned char *name8)
{
    int i, j;
    for (i = 0; i < nO; i++) {
        for (j = 1; j < MAXESD; j++)
            if (O[i].loc[j].used && is_sect_type(O[i].loc[j].type)
                && memcmp(O[i].loc[j].name, name8, 8) == 0) return 1;
        for (j = 0; j < O[i].nld; j++)
            if (memcmp(O[i].ld[j].name, name8, 8) == 0) return 1;
    }
    return 0;
}

/* extract the object deck at member-header offset `off` of archive `ai` and
 * parse it into a new O[] slot */
static int pull_member(int ai, long off)
{
    unsigned char *a = AR[ai].data; char szs[11]; long size;
    if (nO >= MAXOBJ) { fprintf(stderr, "ld370: too many objects (autocall)\n"); return 1; }
    memcpy(szs, a + off + 48, 10); szs[10] = 0; size = atol(szs);
    parse_object(a + off + 60, size, &O[nO]);
    pulled[npulled].ar = ai; pulled[npulled].off = off; npulled++;
    nO++;
    return 0;
}

/* does the archive member at AR[ai] header-offset `off` define a strong symbol
 * (SD/LD/CM) that is ALREADY defined by a loaded object?  Scans its ESD without
 * pulling it.  Used to prefer a NON-conflicting definer during autocall: a
 * symbol like @@EXITA is defined both by the standalone @@exita.o and by the
 * @@crtm.o startup that also re-defines @@CRT0 -- pulling @@crtm.o would drag a
 * duplicate @@CRT0 into the link (and displace the real startup).
 *
 * Order assumption: this only flags a bundle whose colliding symbol is ALREADY
 * resolved.  It works because the colliding section (@@CRT0) is pulled before
 * the bundle's secondary symbol (@@EXITA) is resolved.  If a future closure
 * resolved a bundle's secondary symbol first, the bundle could still win -- pin
 * the wanted variant with --include in that case. */
static int member_conflicts(int ai, long off)
{
    unsigned char *a = AR[ai].data; char szs[11]; long size, i;
    unsigned char *d;
    memcpy(szs, a + off + 48, 10); szs[10] = 0; size = atol(szs);
    d = a + off + 60;
    for (i = 0; i + 80 <= size; i += 80) {
        unsigned char *c = d + i;
        if (!(c[0] == 0x02 && c[1] == 0xC5 && c[2] == 0xE2 && c[3] == 0xC4)) continue;  /* ESD */
        int cnt = (c[10] << 8) | c[11], k;
        for (k = 0; k * 16 < cnt && 16 + (k + 1) * 16 <= 80; k++) {
            unsigned char *e = c + 16 + k * 16;
            int t = e[8] & 0x0f, j, blank = 1;
            if (!(t == T_SD || t == T_LD || t == T_CM)) continue;   /* a section/label def */
            for (j = 0; j < 8; j++) if (e[j] != 0x40) blank = 0;
            if (!blank && is_defined(e)) return 1;                  /* already defined -> conflict */
        }
    }
    return 0;
}

/* resolve unresolved ERs from the archives, to a fixpoint */
static int autocall(void)
{
    int changed = 1;
    while (changed) {
        int i, j, a, s, cur = nO;
        changed = 0;
        for (i = 0; i < cur; i++) {
            for (j = 1; j < MAXESD; j++) {
                const char *want;
                if (!O[i].loc[j].used || O[i].loc[j].type != T_ER) continue;
                if (is_defined(O[i].loc[j].name)) continue;       /* already satisfied */
                want = nm(O[i].loc[j].name);
                /* among ALL definers of `want`, prefer one that does not also
                 * re-define an already-resolved strong symbol; fall back to the
                 * first definer only if every candidate conflicts. */
                {
                    int pick_ai = -1, conflicting = 0, fb_ai = -1; long pick_off = -1, fb_off = -1;
                    for (a = 0; a < nAR && pick_off < 0; a++)
                        for (s = 0; s < AR[a].nsym; s++)
                            if (!strcmp(AR[a].sym[s].name, want)) {
                                long off = AR[a].sym[s].off; int pk, dup = 0;
                                for (pk = 0; pk < npulled; pk++)
                                    if (pulled[pk].ar == a && pulled[pk].off == off) { dup = 1; break; }
                                if (dup) continue;                 /* this definer already pulled; try others */
                                if (fb_off < 0) { fb_ai = a; fb_off = off; }
                                if (!member_conflicts(a, off)) { pick_ai = a; pick_off = off; break; }
                            }
                    if (pick_off < 0 && fb_off >= 0) { pick_ai = fb_ai; pick_off = fb_off; conflicting = 1; }
                    if (pick_off >= 0) {
                        trace("  autocall: '%s' -> archive %d member @%ld%s", want, pick_ai, pick_off,
                              conflicting ? " [no clean definer; took first]" : "");
                        if (pull_member(pick_ai, pick_off)) return 1;
                        changed = 1;
                    }
                }
            }
        }
    }
    return 0;
}

/* case-insensitive ASCII string equality (member names are lower-case .o files;
 * --include args follow the IEWL/NCALIB upper-case member convention) */
static int ci_eq(const char *a, const char *b)
{
    for (; *a && *b; a++, b++) {
        int ca = (*a >= 'a' && *a <= 'z') ? *a - 32 : *a;
        int cb = (*b >= 'a' && *b <= 'z') ? *b - 32 : *b;
        if (ca != cb) return 0;
    }
    return *a == *b;
}

/* locate the archive member an --include NAME refers to: first by member
 * basename (a trailing ".o" ignored, case-insensitive -- so @@CRT1 finds
 * @@crt1.o), then by a strong symbol it defines (preferring a non-conflicting
 * definer). Returns 1 and sets ai/off, else 0. */
static int find_include(const char *name, int *ai, long *off)
{
    int a, m, s, fa = -1; long fo = -1;
    for (a = 0; a < nAR; a++)
        for (m = 0; m < AR[a].nmem; m++) {
            const char *mn = AR[a].mem[m].name; size_t L = strlen(mn); char base[64];
            if (L >= 2 && mn[L - 2] == '.' && (mn[L - 1] == 'o' || mn[L - 1] == 'O')) L -= 2;
            if (L > 63) L = 63;
            memcpy(base, mn, L); base[L] = 0;
            if (ci_eq(base, name)) { *ai = a; *off = AR[a].mem[m].off; return 1; }
        }
    for (a = 0; a < nAR; a++)
        for (s = 0; s < AR[a].nsym; s++)
            if (ci_eq(AR[a].sym[s].name, name)) {
                long o = AR[a].sym[s].off;
                if (!member_conflicts(a, o)) { *ai = a; *off = o; return 1; }
                if (fo < 0) { fa = a; fo = o; }
            }
    if (fo >= 0) { *ai = fa; *off = fo; return 1; }
    return 0;
}

/* force-include the members named by --include (IEWL INCLUDE) BEFORE autocall,
 * so the chosen runtime variant (e.g. @@CRT1) is the one linked and autocall
 * does not pull a conflicting one. */
static int do_includes(const char **incspec, int ninc)
{
    int n, ai, pk, dup; long off;
    for (n = 0; n < ninc; n++) {
        if (!find_include(incspec[n], &ai, &off)) {
            fprintf(stderr, "ld370: --include '%s' not found in any archive\n", incspec[n]);
            return 1;
        }
        for (pk = 0, dup = 0; pk < npulled; pk++)
            if (pulled[pk].ar == ai && pulled[pk].off == off) { dup = 1; break; }
        if (dup) continue;
        trace("  include: '%s' -> archive %d member @%ld", incspec[n], ai, off);
        if (pull_member(ai, off)) return 1;
    }
    return 0;
}

/* ---- emitter ---- */
static unsigned char out[1 << 22];        /* load-module emit buffer (4 MB) */
static long olen = 0;
static void emit(const unsigned char *b, long n) { memcpy(out + olen, b, n); olen += n; }
static void emitb(int b) { out[olen++] = (unsigned char)b; }

/* ============================================================================
 * IEBCOPY unloaded-PDS emitter
 *
 * Wraps the load-module member record stream into the sequential format an
 * IEBCOPY UNLOAD produces -- the transport for host->MVS install: a byte
 * stream IEBCOPY LOADs back into a real load library (mvsMF cannot write
 * RECFM=U PDS members directly, so we ship the unloaded image instead).
 *
 * Structure: COPYR1 (eye-catcher X'CA6D0F') + COPYR2 (source DEB/device
 * descriptors), then a sequence of CKD record images.  Each record image =
 *      F(1) MBBCCHHR(8: M BB CC HH R) KL(1) DL(2)  [+ KEY(KL)] + DATA(DL)
 * Layout:
 *   [328B env header]          COPYR1 + COPYR2                (echoed verbatim)
 *   [dir record]               count(KL=8,DL=256) + key FF*8 + 256B dir block
 *   [dir EOF]                  12 zero bytes (end-of-directory marker record)
 *   per member, per block:     count(KL=0, DL=blocklen, R ascending) + DATA
 *   [EOM]                      count(KL=0, DL=0, R = last+1)
 *
 * Field classes (advisor reframe -- this is synthesis, not byte-identity to a
 * member function): COPYR1/COPYR2, device geometry (CC=0x8d) and the base R
 * (0x0c) are *environment* and echoed from a known-good unload; member name,
 * block split, R sequence, DL and the directory TTRs are *member-derived* and
 * built here.  v1 validates by host byte-identity to e2e.iebcopy-unload.bin;
 * the real oracle is IEBCOPY LOAD + run on MVS.
 * ==========================================================================*/

/* COPYR1 + COPYR2 (328B), echoed verbatim from a real IEBCOPY unload. Describes
 * the synthetic source PDS DCB (DSORG=PO, BLKSIZE=19069, RECFM=U) + volume DEB
 * extents (UDEBX) + device type.  None of it is member-derived. */
static const unsigned char unload_env_hdr[328] = {
    0x00, 0xca, 0x6d, 0x0f, 0x02, 0x00, 0x4a, 0x7d, 0x00, 0x00, 0xc0, 0x00,
    0x00, 0x00, 0x4a, 0x7d, 0x30, 0x50, 0x20, 0x0b, 0x00, 0x00, 0x4a, 0x7d,
    0x02, 0x30, 0x00, 0x1e, 0x4b, 0x36, 0x01, 0x0b, 0x52, 0x08, 0x02, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0xff, 0x00, 0x00, 0x00,
    0x8f, 0x09, 0x66, 0x44, 0x04, 0x9b, 0xd0, 0xe8, 0x50, 0x00, 0x27, 0xc8,
    0x00, 0x00, 0x00, 0x8d, 0x00, 0x00, 0x00, 0x8d, 0x00, 0x1d, 0x00, 0x1e,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00 };

/* PDS2 directory user-data (24B), echoed template.  build_userdata() overlays
 * the computed first-text TTR.  TODO(generalise): compute the module
 * attributes (PDS2ATR), entry point (PDS2EPA) and total length (PDS2STOR) from
 * the member's CESD/control records per the IHAPDS layout, instead of echoing
 * this one member's values. */
static const unsigned char unload_userdata[24] = {
    0x00, 0x00, 0x11, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc3, 0xf2, 0x00, 0x00,
    0x08, 0x00, 0x08, 0x00, 0x00, 0x00, 0x88, 0x00, 0x00, 0x01, 0x00, 0x00 };

/* echoed environment: cylinder of the source PDS data extent (= UDEBX extent
 * start in the env header) and the base record number on its first track (the
 * source PDS reserved R=1..0x0b for directory blocks before member data). */
#define UNLOAD_DATA_CC  0x008d
#define UNLOAD_FIRST_R  0x0c
#define UNLOAD_TRKPERCYL 30      /* 3350 tracks/cylinder (env header DEBNMTRK / offset 83) */
/* UDEBX (DEB data extent) fields within the 328-byte env header, patched when a
 * member needs more than one cylinder of tracks. */
#define UDEBX_ENDCC  78          /* DEBENDCC  (end cylinder)   */
#define UDEBX_ENDHH  80          /* DEBENDHH  (end head)       */
#define UDEBX_NMTRK  82          /* DEBNMTRK  (tracks in extent) */

/* write a 12-byte CKD count image: F + MBBCCHHR(M,BB,CC,HH,R) + KL + DL */
static void put_count(unsigned char *p, int cc, int hh, int r, int kl, int dl)
{
    p[0] = 0;                                   /* F flag */
    p[1] = 0; p[2] = 0; p[3] = 0;               /* M(1) + BB(2) */
    put16(p + 4, cc); put16(p + 6, hh); p[8] = (unsigned char)r;   /* CC HH R */
    p[9] = (unsigned char)kl; put16(p + 10, dl);                   /* KL DL */
}

/* one physical block of a load-module member */
struct lmblock { long off, len; int is_text; };
/* a member to be unloaded */
struct umember {
    unsigned char name[8];
    const unsigned char *bytes; long len;
    struct lmblock *blk; int nblk;   /* allocated by split_member; free after emit */
    int first_tt, text_tt;   /* relative track of first block / first text block (one block/track, R=1) */
    long entry, modlen;   /* PDS2EPA / PDS2STOR for the dir entry; <0 = echo template */
};

/* Split a load-module member byte stream into its physical blocks (the records
 * a loader/IEWFETCH would see).  Record types by byte 0:
 *   X'20' CESD  -> 8-byte header + ESD bytes (count at off 6)
 *   X'80' IDR   -> length = byte 1 + 1
 *   high nibble 0 (control/RLD): 16 + ID-list(off 4) + RLD bytes(off 6);
 *                 if the TXT bit (X'01') is set a pure-text record of length
 *                 (off 14) follows as its OWN block.
 * Returns block count, or -1 on an unrecognised record. */
static int split_member(const unsigned char *m, long n, struct lmblock **out)
{
    long p = 0; int k = 0, cap = 256;
    struct lmblock *b = malloc(cap * sizeof *b);
    *out = NULL;
    if (!b) return -1;
#define ADDBLK(O, L, T) do {                                          \
        if (k >= cap) { cap *= 2; b = realloc(b, cap * sizeof *b);    \
                        if (!b) return -1; }                          \
        b[k].off = (O); b[k].len = (L); b[k].is_text = (T); k++;      \
    } while (0)
    while (p < n) {
        int b0 = m[p], hi = b0 & 0xf0; long blen;
        if (hi == 0x20) {                               /* CESD */
            blen = 8 + be16(m + p + 6);
        } else if (hi == 0x80) {                        /* IDR */
            blen = m[p + 1] + 1;
        } else if (hi == 0x00) {                        /* control / RLD record (16-byte hdr) */
            int txt = b0 & 0x01;                        /* TXT bit -> pure-text record follows */
            long tlen = txt ? be16(m + p + 14) : 0;     /* its length = the control record's CCW count */
            blen = 16 + be16(m + p + 4) + be16(m + p + 6);
            ADDBLK(p, blen, 0);
            p += blen;
            if (txt && tlen) {
                ADDBLK(p, tlen, 1);
                p += tlen;
            }
            continue;                                   /* self-contained; skip the CESD/IDR tail below */
        } else {
            free(b); return -1;                         /* SYM/scatter: not produced by cc370/as370 yet */
        }
        ADDBLK(p, blen, 0);                              /* CESD / IDR: one block, advance and loop */
        p += blen;
    }
#undef ADDBLK
    *out = b;
    return k;
}

/* build the 24-byte PDS2 user-data for a member: echo template, overlay the
 * computed first-text TTR (relative track 0, record text_r). */
static void build_userdata(unsigned char ud[24], const struct umember *m)
{
    memcpy(ud, unload_userdata, 24);
    put16(ud, m->text_tt); ud[2] = 1;                /* PDS2TTRT = (text_tt, 1) */
    if (m->modlen >= 0) {                                     /* computed from the link */
        long ftbl = m->modlen, origin = 0; int j, ntext = 0, have_rld = 0, first_text = -1;
        for (j = 0; j < m->nblk; j++) {
            if (m->blk[j].is_text) {                         /* PDS2FTBL = length of the FIRST text */
                if (first_text < 0) { first_text = j; ftbl = m->blk[j].len; }
                ntext++;                                     /* record, not the whole module -- they */
            } else if (m->bytes[m->blk[j].off] & 0x02)       /* coincide only for a 1-text module */
                have_rld = 1;                                /* a control/RLD record carrying RLD items */
        }
        if (first_text > 0) {                                /* control record precedes the first text */
            long co = m->blk[first_text - 1].off;            /* its CCW load address (off 9-11) = origin */
            origin = ((long)m->bytes[co + 9] << 16) | (m->bytes[co + 10] << 8) | m->bytes[co + 11];
        }
        put24(ud + 10, m->modlen);                           /* PDS2STOR (total storage) */
        put16(ud + 13, (int)ftbl);                           /* PDS2FTBL (first text block len) */
        /* PDS2ATR1/2: the template is from a single-text, no-RLD, origin=0,
         * entry=0 module.  Recompute the per-module flags so multi-text / RLD /
         * non-zero-entry modules are described truthfully -- PDS21BLK left set on
         * a multi-block module makes program fetch take the single-block load
         * path and load ONLY the first text block (-> S0C1 past it).  Keep
         * RENT/REUS/EXEC (ATR1) and FLVL/LEF (ATR2) from the template. */
        ud[8] = (unsigned char)((ud[8] & ~0x01)              /* PDS21BLK: one text block AND no RLD */
                 | ((ntext == 1 && !have_rld) ? 0x01 : 0));
        ud[9] = (unsigned char)((ud[9] & ~(0x10 | 0x40 | 0x20))
                 | (have_rld ? 0 : 0x10)                     /* PDS2NRLD: no RLD items */
                 | (origin == 0 ? 0x40 : 0)                  /* PDS2ORG0: first-text origin is zero */
                 | (m->entry == 0 ? 0x20 : 0));              /* PDS2EP0:  entry point is zero */
    }
    if (m->entry >= 0)
        put24(ud + 15, m->entry);                            /* PDS2EPA (entry point) */
    /* ud+21 (on-disk off 33-35) is the APF/SSI region past the basic section,
     * NOT a second entry field -- IEWL leaves it zero (APFCODE 0).  Writing the
     * entry here marked the module authorized (AMBLIST APFCODE=nonzero). */
    ud[21] = ud[22] = ud[23] = 0;
}

/* COPYR1 logical-record length within the 328-byte env header (COPYR2 is the
 * remaining 276). IEBCOPY/TRANSMIT writes COPYR1 and COPYR2 as separate
 * records (confirmed by IDCAMS PRINT of a real unload). */
#define UNLOAD_COPYR1_LEN 52

/* Emit the IEBCOPY unloaded image of one-or-more members into o[]; return the
 * byte length.  If bounds!=NULL, fill the 4 logical-record end offsets the
 * unload is split into when transmitted: COPYR1, COPYR2, directory(+EOD),
 * member-data(+EOM) -- the 4 data records of the XMIT payload.
 * v2: device-agnostic -- one block per track (block g alone on relative track g
 * at R=1).  A single block <= UBLKSIZE fits any target DASD track, so the image
 * loads regardless of the end-user's device (3.8j IEBCOPY writes RECFM=U blocks
 * as-is + relocates TTRs; it has no COPYMOD).  One directory block. */
static long emit_unload(unsigned char *o, struct umember *mem, int nmem, long *bounds)
{
    long p = 0; int i, j, ntracks, ncyl;
    unsigned char dir[256]; long used;

    /* PDS directory entries must be in ascending EBCDIC name order; sort the
     * members once so both the directory and the data area agree (insertion
     * sort -- nmem is small). */
    for (i = 1; i < nmem; i++) {
        struct umember t = mem[i];
        for (j = i; j > 0 && memcmp(mem[j - 1].name, t.name, 8) > 0; j--)
            mem[j] = mem[j - 1];
        mem[j] = t;
    }

    memcpy(o + p, unload_env_hdr, 328); p += 328;       /* COPYR1 + COPYR2 */
    if (bounds) { bounds[0] = UNLOAD_COPYR1_LEN; bounds[1] = 328; }

    /* one block per track: block g (global, across all members) lives alone on
     * relative track g.  Record each member's first-block and first-text-block
     * track so the directory TTR / PDS2TTRT point at them (R is always 1). */
    {
        int g = 0, sawtext;
        for (i = 0; i < nmem; i++) {
            mem[i].first_tt = g;
            mem[i].text_tt = g;
            sawtext = 0;
            for (j = 0; j < mem[i].nblk; j++) {
                if (mem[i].blk[j].is_text && !sawtext) { mem[i].text_tt = g; sawtext = 1; }
                g++;
            }
        }
        ntracks = g;                                    /* data tracks; EOM sits on track g */
    }

    /* grow the UDEBX data extent to span every track used (incl. the EOM track),
     * in whole cylinders, so the fake-DEB TTR<->MBBCCHHR conversion stays valid. */
    ncyl = (ntracks + 1 + UNLOAD_TRKPERCYL - 1) / UNLOAD_TRKPERCYL;
    if (ncyl < 1) ncyl = 1;
    put16(o + UDEBX_ENDCC, UNLOAD_DATA_CC + ncyl - 1);
    put16(o + UDEBX_ENDHH, UNLOAD_TRKPERCYL - 1);
    put16(o + UDEBX_NMTRK, ncyl * UNLOAD_TRKPERCYL);

    /* directory block: 2-byte used count, member entries (assumed name-sorted
     * by the caller -- true for v1), FF terminator entry, zero pad. */
    memset(dir, 0, sizeof dir);
    used = 2;
    for (i = 0; i < nmem; i++) {
        unsigned char *e = dir + used;
        memcpy(e, mem[i].name, 8);
        put16(e + 8, mem[i].first_tt); e[10] = 1;    /* TTR = (first_tt, 1) */
        e[11] = 0x2c;                                /* alias=0, 1 TTR, 12 halfwords user data */
        build_userdata(e + 12, &mem[i]);
        used += 8 + 3 + 1 + 24;
    }
    memset(dir + used, 0xff, 8); used += 12;          /* end-of-directory: FF name + zero TTR/C */
    put16(dir, (int)used);
    if (used > 256) trace("WARNING: directory overflows one block -- multi-block dir not yet emitted");

    put_count(o + p, 0, 0, 0, 8, 256); p += 12;        /* directory record */
    memset(o + p, 0xff, 8); p += 8;                    /* key = high values */
    memcpy(o + p, dir, 256); p += 256;

    memset(o + p, 0, 12); p += 12;                     /* end-of-directory marker record */
    if (bounds) bounds[2] = p;                          /* directory record + EOD marker */

    /* member data: one CKD record image per physical block, one block per
     * relative track (CC advances every UNLOAD_TRKPERCYL tracks), R always 1. */
    {
        int g = 0;
        for (i = 0; i < nmem; i++)
            for (j = 0; j < mem[i].nblk; j++) {
                long bl = mem[i].blk[j].len;
                put_count(o + p, UNLOAD_DATA_CC + g / UNLOAD_TRKPERCYL,
                          g % UNLOAD_TRKPERCYL, 1, 0, (int)bl); p += 12;
                memcpy(o + p, mem[i].bytes + mem[i].blk[j].off, bl); p += bl;
                g++;
            }
        /* EOM: zero-length record alone on the track after the last block */
        put_count(o + p, UNLOAD_DATA_CC + g / UNLOAD_TRKPERCYL,
                  g % UNLOAD_TRKPERCYL, 1, 0, 0); p += 12;
    }
    if (bounds) bounds[3] = p;                          /* member data + EOM */
    return p;
}

/* Split each member, emit the unloaded image of all of them and write it to
 * path.  mem[].name/.bytes/.len must be set by the caller. Returns 0 on ok. */
static int write_unload_mem(const char *path, struct umember *mem, int nmem)
{
    static unsigned char unl[1 << 22];     /* unload image (4 MB) */
    long ulen; FILE *f; int i;

    for (i = 0; i < nmem; i++) {
        mem[i].nblk = split_member(mem[i].bytes, mem[i].len, &mem[i].blk);
        if (mem[i].nblk < 0) {
            fprintf(stderr, "ld370: cannot split member '%s' (unknown record)\n", nm(mem[i].name));
            return 1;
        }
        trace("=== unload: member '%s', %d block(s), %ld bytes ===",
              nm(mem[i].name), mem[i].nblk, mem[i].len);
    }
    ulen = emit_unload(unl, mem, nmem, NULL);
    f = fopen(path, "wb");
    if (!f) { perror(path); return 1; }
    fwrite(unl, 1, (size_t)ulen, f);
    fclose(f);
    for (i = 0; i < nmem; i++) { free(mem[i].blk); mem[i].blk = NULL; }
    trace("=== done: wrote %ld-byte unloaded image (%d member%s) to %s ===",
          ulen, nmem, nmem == 1 ? "" : "s", path);
    return 0;
}

/* convenience: unload a single in-memory member */
static int write_unload(const char *path, const char *name,
                        const unsigned char *member, long mlen, long entry, long modlen)
{
    struct umember m;
    memset(&m, 0, sizeof m);
    member_name(m.name, name);
    m.bytes = member; m.len = mlen; m.entry = entry; m.modlen = modlen;
    return write_unload_mem(path, &m, 1);
}

/* ============================================================================
 * XMIT (TSO TRANSMIT / NETDATA) emitter
 *
 * Wraps the IEBCOPY unloaded image (the 4 logical records emit_unload marks via
 * its bounds[]) in the NETDATA/INMR control structure TSO TRANSMIT generates,
 * as RECFM=FB LRECL=80.  This is the host->MVS install transport: FB80 uploads
 * cleanly as a binary sequential dataset (mvsMF splits on the 80-byte records)
 * and TSO RECEIVE / RECV370 reinstates the load-library member.  (The bare
 * IEBCOPY-unload path is blocked -- mvsMF cannot rebuild the unload's
 * variable-spanned records on upload; FB80 sidesteps it.  Precedent: Dignus
 * PLINK ships a TSO TRANSMIT file.)
 *
 * Logical records (NETDATA-segmented into the FB80 stream):
 *   INMR01  header      node/user/timestamp/file-count
 *   INMR02  control #1   IEBCOPY -> the SOURCE load library DCB (RECFM=U, PO)
 *   INMR02  control #2   INMCOPY -> the unloaded form DCB (RECFM=VS, PS)
 *   INMR03  data descriptor
 *   COPYR1 COPYR2 dir+EOD member+EOM   the 4 unload records (data)
 *   INMR06  trailer
 * Each is split into <=253-byte segments: len(1, incl. 2-byte hdr) + flags(1) +
 * data; flags 0x80=first-of-record, 0x40=last, 0x20=control.  Segments pack
 * continuously into 80-byte records; the final record is zero-padded.
 *
 * One file is transmitted (a load library) => INMNUMF=1; a multi-member library
 * is still one file, its members inside the unload directory (no wrapper change
 * for --pack).  Validated host-side structurally vs an e2e.xmit.bin oracle
 * modulo INMFTIME (an inherent timestamp carve-out); real oracle = RECEIVE+run.
 *
 * Size hints (INMSIZE) and the source DCB are echoed E2E-correct constants for
 * now; computing them from the member is the open generalisation -- see TODOs.
 * ==========================================================================*/

/* NETDATA text-unit keys (subset emitted here) */
enum { INMDSNAM = 0x0002, INMDIR = 0x000c, INMBLKSZ = 0x0030, INMDSORG = 0x003c,
       INMLRECL = 0x0042, INMRECFM = 0x0049, INMTNODE = 0x1001, INMTUID = 0x1002,
       INMFNODE = 0x1011, INMFUID = 0x1012, INMFTIME = 0x1024, INMUTILN = 0x1028,
       INMSIZE = 0x102c, INMNUMF = 0x102f };

/* one text unit: key(2) + count(2, =1) + length(2) + value */
static void tu(unsigned char *b, long *p, int key, const unsigned char *val, int len)
{
    put16(b + *p, key); *p += 2;
    put16(b + *p, 1);   *p += 2;
    put16(b + *p, len); *p += 2;
    memcpy(b + *p, val, len); *p += len;
}
static void tui(unsigned char *b, long *p, int key, long v, int n)   /* integer value */
{
    unsigned char t[4]; wrval(t, v, n); tu(b, p, key, t, n);
}
static void tus(unsigned char *b, long *p, int key, const char *s)   /* EBCDIC string value */
{
    unsigned char t[44]; int i, n = (int)strlen(s); if (n > 44) n = 44;
    for (i = 0; i < n; i++) t[i] = a2e1(s[i]);
    tu(b, p, key, t, n);
}
/* INMDSNAM: one value per '.'-separated qualifier of dsn */
static void tu_dsname(unsigned char *b, long *p, const char *dsn)
{
    const char *s = dsn; int nq = 1, i; const char *q;
    for (q = dsn; *q; q++) if (*q == '.') nq++;
    put16(b + *p, INMDSNAM); *p += 2;
    put16(b + *p, nq);       *p += 2;
    for (;;) {
        int qn = 0; while (s[qn] && s[qn] != '.') qn++;
        put16(b + *p, qn); *p += 2;
        for (i = 0; i < qn; i++) b[(*p)++] = a2e1(s[i]);
        if (!s[qn]) break;
        s += qn + 1;
    }
}
static long inmr_hdr(unsigned char *r, int n)        /* 'INMR0n' eyecatcher */
{
    r[0] = 0xc9; r[1] = 0xd5; r[2] = 0xd4; r[3] = 0xd9; r[4] = 0xf0;
    r[5] = (unsigned char)(0xf0 + n);
    return 6;
}

/* append a logical record as NETDATA segments (<=253 data bytes each) */
static void netdata_seg(unsigned char *o, long *p, const unsigned char *rec, long len, int control)
{
    long off = 0; int ctl = control ? 0x20 : 0;
    do {
        long n = len - off; if (n > 253) n = 253;
        int flags = ctl | (off == 0 ? 0x80 : 0) | (off + n >= len ? 0x40 : 0);
        o[(*p)++] = (unsigned char)(n + 2);
        o[(*p)++] = (unsigned char)flags;
        memcpy(o + *p, rec + off, n); *p += n;
        off += n;
    } while (off < len);
}

/* current local time as a 16-EBCDIC-digit INMFTIME (YYYYMMDDHHMMSShh) */
static void xmit_ftime(unsigned char e[16])
{
    char a[17]; time_t t = time(NULL); struct tm *tm = localtime(&t); int i;
    sprintf(a, "%04d%02d%02d%02d%02d%02d00",
            tm->tm_year + 1900, tm->tm_mon + 1, tm->tm_mday,
            tm->tm_hour, tm->tm_min, tm->tm_sec);
    for (i = 0; i < 16; i++) e[i] = a2e1(a[i]);
}

/* Build the XMIT of one unloaded image (unl[0..bounds[3]) split at bounds[])
 * into o[]; dsn = target load-library name (informational + RECEIVE default).
 * Returns the FB80 byte length. */
static long emit_xmit(unsigned char *o, const unsigned char *unl, const long *bounds,
                      const char *dsn)
{
    unsigned char r[1024]; long rp, p = 0; unsigned char ft[16];

    /* INMR01 -- transmission header */
    rp = inmr_hdr(r, 1);
    tui(r, &rp, INMLRECL, 80, 4);
    tus(r, &rp, INMFNODE, "ORIGNODE");
    tus(r, &rp, INMFUID,  "IBMUSER");
    tus(r, &rp, INMTNODE, "IBMUSER");
    tus(r, &rp, INMTUID,  "DUMMY");
    xmit_ftime(ft); tu(r, &rp, INMFTIME, ft, 16);
    tui(r, &rp, INMNUMF, 1, 1);
    netdata_seg(o, &p, r, rp, 1);

    /* INMR02 #1 -- IEBCOPY: attributes of the SOURCE load library (recreated by
     * RECEIVE).  TODO(generalise): compute INMSIZE/INMBLKSZ/INMDIR + parameterise
     * the DCB from the target library instead of echoing E2E constants. */
    rp = inmr_hdr(r, 2);
    put24(r + rp, 0); r[rp + 3] = 1; rp += 4;            /* file number = 1 */
    tus(r, &rp, INMUTILN, "IEBCOPY");
    tui(r, &rp, INMSIZE, 19069, 4);
    tui(r, &rp, INMDIR, 10, 3);
    tui(r, &rp, INMLRECL, 0, 4);
    tui(r, &rp, INMDSORG, 0x0200, 2);                   /* PO */
    tui(r, &rp, INMBLKSZ, UNLOAD_SRC_BLKSIZE, 4);       /* source load-library BLKSIZE */
    tui(r, &rp, INMRECFM, 0xc002, 2);                   /* U */
    tu_dsname(r, &rp, dsn);
    netdata_seg(o, &p, r, rp, 1);

    /* INMR02 #2 -- INMCOPY: attributes of the unloaded form (the in-stream data,
     * RECFM=VS).  Constant for our IEBCOPY-unload format. */
    rp = inmr_hdr(r, 2);
    put24(r + rp, 0); r[rp + 3] = 1; rp += 4;
    tus(r, &rp, INMUTILN, "INMCOPY");
    tui(r, &rp, INMSIZE, 15600, 4);
    tui(r, &rp, INMLRECL, UNLOAD_BLKSIZE - 4, 4);       /* VS: max logical record = BLKSIZE-4 */
    tui(r, &rp, INMDSORG, 0x4000, 2);                   /* PS */
    tui(r, &rp, INMBLKSZ, UNLOAD_BLKSIZE, 4);           /* = IEBCOPY MINBLK; must hold one record unspanned */
    tui(r, &rp, INMRECFM, 0x4802, 2);                   /* VS */
    netdata_seg(o, &p, r, rp, 1);

    /* INMR03 -- data record descriptor */
    rp = inmr_hdr(r, 3);
    tui(r, &rp, INMSIZE, 19069, 4);
    tui(r, &rp, INMLRECL, 80, 4);
    tui(r, &rp, INMDSORG, 0x4000, 2);
    tui(r, &rp, INMRECFM, 0x0001, 2);
    netdata_seg(o, &p, r, rp, 1);

    /* COPYR1 / COPYR2 / directory+EOD are one logical record each */
    netdata_seg(o, &p, unl,             bounds[0],              0);
    netdata_seg(o, &p, unl + bounds[0], bounds[1] - bounds[0], 0);
    netdata_seg(o, &p, unl + bounds[1], bounds[2] - bounds[1], 0);
    /* member data: the IEBCOPY-unload's variable records cannot exceed the
     * reload buffer, so pack whole CKD records (count12 + KL + DL) into logical
     * records of <= MAXTEXT bytes instead of one giant record. */
    {
        long q = bounds[2];
        while (q < bounds[3]) {
            long cs = q, clen = 0;
            while (q < bounds[3]) {
                long reclen = 12 + unl[q + 9] + be16(unl + q + 10);
                if (clen > 0 && clen + reclen > MAXTEXT) break;
                clen += reclen; q += reclen;
                if (clen >= MAXTEXT) break;
            }
            netdata_seg(o, &p, unl + cs, clen, 0);
        }
    }

    /* INMR06 -- trailer */
    rp = inmr_hdr(r, 6);
    netdata_seg(o, &p, r, rp, 1);

    while (p % 80) o[p++] = 0;                           /* pad final FB80 record */
    return p;
}

/* Build the XMIT image of members[] and write it to path. */
static int write_xmit(const char *path, struct umember *mem, int nmem, const char *dsn)
{
    static unsigned char unl[1 << 22], xm[1 << 22];   /* unload + XMIT (4 MB each) */
    long bounds[4], ulen, xlen; FILE *f; int i;

    for (i = 0; i < nmem; i++) {
        mem[i].nblk = split_member(mem[i].bytes, mem[i].len, &mem[i].blk);
        if (mem[i].nblk < 0) {
            fprintf(stderr, "ld370: cannot split member '%s' (unknown record)\n", nm(mem[i].name));
            return 1;
        }
    }
    ulen = emit_unload(unl, mem, nmem, bounds);
    (void)ulen;
    xlen = emit_xmit(xm, unl, bounds, dsn);
    f = fopen(path, "wb");
    if (!f) { perror(path); return 1; }
    fwrite(xm, 1, (size_t)xlen, f);
    fclose(f);
    for (i = 0; i < nmem; i++) { free(mem[i].blk); mem[i].blk = NULL; }
    trace("=== done: wrote %ld-byte XMIT (%d FB80 recs, %d member%s) to %s ===",
          xlen, (int)(xlen / 80), nmem, nmem == 1 ? "" : "s", path);
    return 0;
}

/* convenience: XMIT a single in-memory member */
static int write_xmit1(const char *path, const char *name, const unsigned char *member,
                       long mlen, const char *dsn, long entry, long modlen)
{
    struct umember m;
    memset(&m, 0, sizeof m);
    member_name(m.name, name);
    m.bytes = member; m.len = mlen; m.entry = entry; m.modlen = modlen;
    return write_xmit(path, &m, 1, dsn);
}

/* derive an 8-char member name from a file path basename (strip dir + ext) */
static const char *basename_member(const char *path)
{
    static char nm8[9]; const char *s = path, *p; int i;
    for (p = path; *p; p++) if (*p == '/' || *p == '\\') s = p + 1;
    for (i = 0; i < 8 && s[i] && s[i] != '.'; i++) nm8[i] = s[i];
    nm8[i] = 0;
    return nm8;
}

/* resolve -lNAME to lib<NAME>.a in the -L dirs (then '.') and load it */
static int load_lib(const char *name, char **Ldir, int nLdir)
{
    char path[1024]; int d;
    for (d = 0; d <= nLdir; d++) {
        const char *dir = (d < nLdir) ? Ldir[d] : "."; FILE *t;
        snprintf(path, sizeof path, "%s/lib%s.a", dir, name);
        t = fopen(path, "rb");
        if (t) { fclose(t); return load_archive(path); }
    }
    fprintf(stderr, "ld370: cannot find -l%s\n", name);
    return 1;
}
static int ends_with(const char *s, const char *suf)
{
    size_t ls = strlen(s), lf = strlen(suf);
    return ls >= lf && !strcmp(s + ls - lf, suf);
}

int main(int argc, char **argv)
{
    const char *outfile = NULL, *unloadfile = NULL, *unloadfrom = NULL, *mname = NULL;
    const char *xmitfile = NULL, *dsn = NULL, *entryname = NULL;
    const char *objfiles[MAXOBJ];
    char *packspec[MAXOBJ], *Ldir[32];
    const char *incspec[64]; int ninc = 0;
    int nobjf = 0, npack = 0, nLdir = 0, i, j;
    FILE *f;

    for (i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "-o") && i + 1 < argc) outfile = argv[++i];
        else if (!strcmp(argv[i], "--unload") && i + 1 < argc) unloadfile = argv[++i];
        else if (!strcmp(argv[i], "--unload-from") && i + 1 < argc) unloadfrom = argv[++i];
        else if (!strcmp(argv[i], "--xmit") && i + 1 < argc) xmitfile = argv[++i];
        else if (!strcmp(argv[i], "--dsn") && i + 1 < argc) dsn = argv[++i];
        else if (!strcmp(argv[i], "--name") && i + 1 < argc) mname = argv[++i];
        else if ((!strcmp(argv[i], "--entry") || !strcmp(argv[i], "-e")) && i + 1 < argc) entryname = argv[++i];
        else if ((!strcmp(argv[i], "--include") || !strcmp(argv[i], "-i")) && i + 1 < argc && ninc < 64) incspec[ninc++] = argv[++i];
        else if (!strcmp(argv[i], "--pack") && i + 1 < argc && npack < MAXOBJ) packspec[npack++] = argv[++i];
        else if (!strcmp(argv[i], "--verbose") || !strcmp(argv[i], "-v")) verbose = 1;
        else if (!strcmp(argv[i], "--allow-unresolved")) allow_unresolved = 1;
        else if (!strcmp(argv[i], "-L") && i + 1 < argc) { if (nLdir < 32) Ldir[nLdir++] = argv[++i]; }
        else if (!strncmp(argv[i], "-L", 2)) { if (nLdir < 32) Ldir[nLdir++] = argv[i] + 2; }
        else if (!strcmp(argv[i], "-l") && i + 1 < argc) { if (load_lib(argv[++i], Ldir, nLdir)) return 1; }
        else if (!strncmp(argv[i], "-l", 2)) { if (load_lib(argv[i] + 2, Ldir, nLdir)) return 1; }
        else if (ends_with(argv[i], ".a")) { if (load_archive(argv[i])) return 1; }
        else if (nobjf < MAXOBJ) objfiles[nobjf++] = argv[i];
    }
    if (!dsn) dsn = "IBMUSER.HOST.LOAD";       /* INMDSNAM default; RECEIVE DA(...) overrides */

    /* --- standalone wrap: an existing flat member, no object linking.
     *     ld370 --unload-from MEMBER.lm [--name NAME] [--unload OUT] [--xmit OUT] --- */
    if (unloadfrom) {
        static unsigned char memb[1 << 20];
        long mlen; const char *name;
        if (!unloadfile && !xmitfile) { fprintf(stderr, "ld370: --unload-from needs --unload and/or --xmit OUT\n"); return 2; }
        f = fopen(unloadfrom, "rb");
        if (!f) { perror(unloadfrom); return 1; }
        mlen = (long)fread(memb, 1, sizeof memb, f);
        fclose(f);
        name = mname ? mname : basename_member(unloadfrom);
        if (unloadfile && write_unload(unloadfile, name, memb, mlen, -1, -1)) return 1;
        if (xmitfile && write_xmit1(xmitfile, name, memb, mlen, dsn, -1, -1)) return 1;
        return 0;
    }

    /* --- multi-member: pack several flat members into one image/library.
     *     ld370 --pack NAME1=FILE1 --pack NAME2=FILE2 ... [--unload OUT] [--xmit OUT]
     *     (single-track geometry: total records must fit one track for now) --- */
    if (npack) {
        struct umember m[MAXOBJ]; int rc = 0;
        if (!unloadfile && !xmitfile) { fprintf(stderr, "ld370: --pack needs --unload and/or --xmit OUT\n"); return 2; }
        memset(m, 0, sizeof m);
        for (i = 0; i < npack; i++) {
            char *eq = strchr(packspec[i], '='); long n; unsigned char *buf; size_t got;
            if (!eq) { fprintf(stderr, "ld370: bad --pack '%s' (need NAME=FILE)\n", packspec[i]); return 2; }
            *eq = 0;
            f = fopen(eq + 1, "rb");
            if (!f) { perror(eq + 1); return 1; }
            fseek(f, 0, SEEK_END); n = ftell(f); fseek(f, 0, SEEK_SET);
            buf = malloc((size_t)n);
            if (!buf) { fclose(f); fprintf(stderr, "ld370: out of memory\n"); return 1; }
            got = fread(buf, 1, (size_t)n, f); (void)got; fclose(f);
            member_name(m[i].name, packspec[i]); m[i].bytes = buf; m[i].len = n;
            m[i].entry = -1; m[i].modlen = -1;          /* multi-member: echo dir template */
        }
        if (unloadfile) rc = write_unload_mem(unloadfile, m, npack);
        if (!rc && xmitfile) rc = write_xmit(xmitfile, m, npack, dsn);
        for (i = 0; i < npack; i++) free((void *)m[i].bytes);
        return rc;
    }

    /* a link needs content: explicit objects, or --include members to pull
     * (the faithful mbt model -- INCLUDE the listed NCALIB members + autocall,
     * no "explicit object" concept). */
    if ((!nobjf && !ninc) || !outfile) {
        fprintf(stderr,
                "usage: ld370 [-v] -o OUT.bin [-L DIR -l NAME] [--include NAME] [--entry NAME]\n"
                "             [--unload U] [--xmit X [--dsn DS]] [--name N] OBJ...\n"
                "       ld370 --unload-from MEMBER.lm [--name N] [--unload U] [--xmit X]\n"
                "       ld370 --pack N1=M1.lm [--pack N2=M2.lm ...] [--unload U] [--xmit X]\n");
        return 2;
    }

    /* --- PASS 1: read every explicit object module --- */
    trace("=== PASS 1: read %d object module(s) ===", nobjf);
    for (i = 0; i < nobjf; i++) {
        long n; unsigned char *b = read_file(objfiles[i], &n);
        trace("- object: %s", objfiles[i]);
        if (!b) return 1;
        parse_object(b, n, &O[nO]);
        free(b);
        nO++;
    }

    /* --- force-include (IEWL INCLUDE) before autocall, then autocall --- */
    if (ninc) {
        trace("=== include: %d forced member(s) ===", ninc);
        if (do_includes(incspec, ninc)) return 1;
    }
    if (nAR) {
        trace("=== autocall: %d archive(s) ===", nAR);
        if (autocall()) return 1;
        if (nO > nobjf) trace("  pulled %d member(s); %d object(s) total", nO - nobjf, nO);
    }

    /* --- PASS 2: build the composite ESD (resolve ER -> SD/LR by name) --- */
    trace("=== PASS 2: build composite ESD, resolve references ===");
    for (i = 0; i < nO; i++) {
        struct obj *o = &O[i];
        for (j = 1; j < MAXESD; j++) {
            int t, gi;
            if (!o->loc[j].used) continue;
            t = o->loc[j].type;
            /* PC (private code) is a distinct section per object even though its
             * name is blank -- give it a fresh gsym; named SD/CM/ER merge. */
            gi = (t == T_PC) ? g_new(o->loc[j].name) : g_intern(o->loc[j].name, t);
            o->loc_g[j] = gi;
            if (is_sect_type(t)) {                    /* a section definition */
                G[gi].is_sect = 1; G[gi].type = t; G[gi].len = o->loc[j].len;
                G[gi].def_obj = i; G[gi].in_addr = o->loc[j].addr;   /* its object + origin within it */
            }
        }
        for (j = 0; j < o->nld; j++) {            /* label defs (entries) -> composite LR (type 03) */
            int gi = g_intern(o->ld[j].name, T_LD);
            int ol = o->ld[j].owner_local;
            G[gi].type = 0x03; G[gi].in_addr = o->ld[j].addr;
            G[gi].owner = (ol >= 1 && ol < MAXESD && o->loc[ol].used) ? o->loc_g[ol] : -1;
        }
    }
    {
        int nunres = 0;
        for (i = 0; i < nG; i++)
            if (!G[i].is_sect && G[i].type == T_ER) {
                if (nunres == 0)
                    fprintf(stderr, "ld370: unresolved external reference(s):\n");
                fprintf(stderr, "    %s\n", nm(G[i].name));
                nunres++;
            }
        if (nunres && !allow_unresolved) {
            fprintf(stderr, "ld370: %d unresolved external(s) -- the module would S0C4 "
                            "at runtime (each is a NULL adcon); add the defining object/"
                            "archive, or pass --allow-unresolved to override\n", nunres);
            return 1;
        }
        if (nunres)
            fprintf(stderr, "ld370: %d unresolved external(s) left for the loader "
                            "(--allow-unresolved)\n", nunres);
    }

    /* --- address assignment ---
     * Stack whole OBJECTS, each at a doubleword base; within an object the
     * assembler already laid out its sections, so a section's final origin =
     * its object's base + the section's origin within that object. ESDIDs:
     * sections first (appearance order), then unresolved ERs. */
    trace("=== assign addresses: stack objects, place sections ===");
    long running = 0;
    for (i = 0; i < nO; i++) {
        struct obj *o = &O[i];
        long osize = 0; int jj;
        for (jj = 1; jj < MAXESD; jj++)
            if (o->loc[jj].used && is_sect_type(o->loc[jj].type)
                && o->loc[jj].addr + o->loc[jj].len > osize)
                osize = o->loc[jj].addr + o->loc[jj].len;
        o->object_base = running;
        running += roundup8(osize);
    }
    long modlen = roundup8(running);
    int gid = 0;
    for (i = 0; i < nG; i++)
        if (G[i].is_sect) {
            G[i].gid = ++gid;
            G[i].org = (G[i].def_obj >= 0 ? O[G[i].def_obj].object_base : 0) + G[i].in_addr;
            trace("  section '%s' -> ESDID %d  origin=%06lX  length=%ld",
                  nm(G[i].name), G[i].gid, G[i].org, G[i].len);
        }
    int nsect = gid;
    for (i = 0; i < nG; i++)
        if (!G[i].is_sect) G[i].gid = ++gid;          /* unresolved ERs get ids after sections */
    static int gidx[MAXG + 1];                        /* gid -> G[] index */
    for (i = 0; i < nG; i++) gidx[G[i].gid] = i;

    /* entry point: --entry NAME resolves a named section/LD entry (the working
     * crent convention is ENTRY @@CRT0 -- the C startup that establishes the
     * runtime; the cc370 END-card entry is the @@MAIN stub, and entering there
     * skips @@CRT0's setup -> the runtime can't find its anchor -> S0C4). Without
     * --entry, fall back to the END-card section origin + offset of the first
     * object that names one. */
    long entry_addr = 0;
    if (entryname) {
        unsigned char en[8]; int gi, found = 0;
        member_name(en, entryname);
        for (gi = 0; gi < nG; gi++) {
            if (memcmp(G[gi].name, en, 8)) continue;
            if (G[gi].is_sect) { entry_addr = G[gi].org; found = 1; break; }
            if (G[gi].type == 0x03 && G[gi].owner >= 0 && G[G[gi].owner].is_sect) {
                entry_addr = G[G[gi].owner].org + G[gi].in_addr; found = 1; break;
            }
        }
        if (!found) { fprintf(stderr, "ld370: --entry symbol '%s' not found or unresolved\n", entryname); return 1; }
        trace("  --entry %s -> %06lX", entryname, entry_addr);
    } else {
        for (i = 0; i < nO; i++)
            if (O[i].has_entry && O[i].entry_id >= 1 && O[i].entry_id < MAXESD && O[i].loc[O[i].entry_id].used) {
                entry_addr = G[O[i].loc_g[O[i].entry_id]].org + O[i].entry_off;
                break;
            }
    }
    trace("  module length = %ld  entry point = %06lX", modlen, entry_addr);

    /* --- build module text image + relocate address constants --- */
    static unsigned char mod[1 << 20];
    memset(mod, 0, modlen);
    for (i = 0; i < nO; i++) if (O[i].textlen) memcpy(mod + O[i].object_base, O[i].text, O[i].textlen);
    trace("=== relocate address constants ===");
    for (i = 0; i < nO; i++) {
        struct obj *o = &O[i];
        for (j = 0; j < o->nrld; j++) {
            int Rg = local_to_g(o, o->rld[j].R);
            long loc = o->object_base + o->rld[j].addr;
            int len = ((o->rld[j].flag >> 2) & 3) + 1;
            long base = -1;                           /* resolved final target address */
            if (Rg >= 0 && G[Rg].is_sect)
                base = G[Rg].org;                     /* section: its final origin */
            else if (Rg >= 0 && G[Rg].type == 0x03 && G[Rg].owner >= 0 && G[G[Rg].owner].is_sect)
                base = G[G[Rg].owner].org + G[Rg].in_addr;   /* LR (entry): owner origin + offset */
            if (base >= 0) {                          /* relocate by (final target - input value) */
                long delta = base - o->loc[o->rld[j].R].addr;
                long v = rdval(mod + loc, len) + delta;
                wrval(mod + loc, v, len);
                trace("  adcon@%06lX -> %s: %+ld (final %06lX)", loc, nm(G[Rg].name), delta, base);
            } else {
                trace("  adcon@%06lX -> %s: UNRESOLVED, left for the loader",
                      loc, Rg >= 0 ? nm(G[Rg].name) : "?");
            }
        }
    }

    /* --- emit: CESD (composite ESD), <= 15 entries (240 bytes) per record like
     * IEWL/HEWLFOUT.  A single oversized CESD record is a format violation
     * (the doc/spec cap each record at 15 entries). Header: byte0=20, off4-5 =
     * ESD-ID of first entry, off6-7 = 16 x entries. All records carry byte0=20
     * (following IDR/text means none is the last-of-module 0x28). --- */
    trace("=== emit load-module record stream ===");
    long cesd_off = olen;
    {
        int in_rec = 0, nrec = 0;
        for (gid = 1; gid <= nG; gid++) {
            int gi = -1;
            for (i = 0; i < nG; i++) if (G[i].gid == gid) { gi = i; break; }
            if (in_rec == 0) {                        /* open a new CESD record */
                unsigned char h[8]; memset(h, 0, 8);
                h[0] = 0x20; put16(h + 4, gid);       /* off4-5 = first ESD-ID; off6-7 set on close */
                emit(h, 8); nrec++;
            }
            unsigned char e[16]; memset(e, 0, 16);
            memcpy(e, G[gi].name, 8);
            e[8] = (unsigned char)G[gi].type;
            if (G[gi].is_sect) {
                put24(e + 9, G[gi].org); e[12] = 0x01; put24(e + 13, G[gi].len);
            } else if (G[gi].type == 0x03) {  /* LR (label/entry): label address + owning section's ESDID */
                long oorg = G[gi].owner >= 0 ? G[G[gi].owner].org : 0;
                int  ogid = G[gi].owner >= 0 ? G[G[gi].owner].gid : 0;
                put24(e + 9, oorg + G[gi].in_addr); e[12] = 0x01; put24(e + 13, ogid);
            } else {                          /* unresolved ER: 00 .. 00 40 40 (matches IEWL) */
                e[12] = 0x00; e[13] = 0x00; e[14] = 0x40; e[15] = 0x40;
            }
            emit(e, 16); in_rec++;
            if (in_rec == 15 || gid == nG) {          /* close record: byte count at record off 6 */
                put16(out + olen - 16 * in_rec - 2, 16 * in_rec);
                in_rec = 0;
            }
        }
        trace("  CESD:            %d record(s) <=15 entries (%d entr%s: %d section(s) + %d ER)",
              nrec, nG, nG == 1 ? "y" : "ies", nsect, nG - nsect);
    }
    (void)cesd_off;

    /* --- SPZAP IDR (fixed 251B, header 80 FA 01 00, zero) --- */
    emitb(0x80); emitb(0xFA); emitb(0x01); emitb(0x00);
    for (i = 0; i < 247; i++) emitb(0);
    trace("  SPZAP-IDR:       251 bytes");

    int total_rld = 0;
    for (i = 0; i < nO; i++) total_rld += O[i].nrld;
    int have_rld = total_rld > 0;

    /* --- control + text records: split the module text into <= MAXTEXT-byte
     * records, each preceded by a control record naming the CSECTs it carries
     * (load address at off 9, length at off 14, ID/length list at off 16). A
     * single text record larger than the load-library blocksize overflows the
     * reload buffer (RECV370 U0200), so real modules are split. Sections are
     * gid 1..nsect in origin order; we pack whole sections per chunk, and split
     * a single section that is itself larger than MAXTEXT (see below). --- */
    {
        int sg = 1, nchunk = 0;
        while (sg <= nsect) {
            long cstart = G[gidx[sg]].org, cend = cstart; int first = sg, g, k, idlen;
            static unsigned char cr[16 + 4 * MAXG];
            while (sg <= nsect) {                      /* greedily pack whole sections, >= 1 */
                long send = (sg < nsect) ? G[gidx[sg]].org + roundup8(G[gidx[sg]].len) : modlen;
                if (sg > first && send - cstart > MAXTEXT) break;
                cend = send; sg++;
            }
            /* Emit the chunk [cstart,cend) as one or more text records, each
             * <= MAXTEXT.  A multi-section chunk is always <= MAXTEXT (the
             * greedy loop guarantees it) -> one record carrying every section's
             * (id,length).  A single section larger than MAXTEXT is split into
             * MAXTEXT-sized records (intra-section split), each control record
             * carrying that one section's PARTIAL length -- byte-for-byte the
             * layout IEWL emits (a 40000-byte CSECT -> 18432/18432/3136).
             * Oversized records would blow the RECV370 reload buffer
             * (U0200-13 .RECVBLK) and the IEBCOPY reload BLKSIZE. */
            {
                int multi = (sg - first) > 1, last_chunk = (sg > nsect);
                long p = cstart;
                do {
                    long rlen = cend - p; if (rlen > MAXTEXT) rlen = MAXTEXT;
                    int is_last = last_chunk && (p + rlen >= cend);
                    idlen = multi ? 4 * (sg - first) : 4;
                    memset(cr, 0, (size_t)(16 + idlen));
                    cr[0] = (is_last && !have_rld) ? 0x0D : 0x01;   /* MODEND on the very last record */
                    put16(cr + 4, idlen); put16(cr + 6, 0);
                    cr[8] = 0x06; put24(cr + 9, p); cr[12] = 0x40; put16(cr + 14, (int)rlen);
                    if (multi) {
                        for (g = first, k = 0; g < sg; g++, k++) {
                            int gi = gidx[g];
                            long span = (g < nsect ? G[gi].org + roundup8(G[gi].len) : modlen) - G[gi].org;
                            put16(cr + 16 + 4 * k, g); put16(cr + 18 + 4 * k, (int)span);
                        }
                    } else {                            /* one section (whole or a split piece) */
                        put16(cr + 16, first); put16(cr + 18, (int)rlen);
                    }
                    emit(cr, 16 + idlen);               /* control record */
                    emit(mod + p, rlen);                /* text record (<= MAXTEXT) */
                    nchunk++; p += rlen;
                } while (p < cend);
            }
        }
        trace("  control+text:    %d chunk(s) over %ld-byte text", nchunk, modlen);
    }

    /* --- RLD records: emit RLD items in records of <= RLDMAX bytes of RLD
     * data.  IEWL caps each RLD record at 236 so the whole record (16-byte
     * header + data) fits program fetch's 256-byte RLD buffer (IEWFETCH FTRBUF);
     * one oversized RLD record makes fetch read past the buffer and relocate
     * garbage addresses -> S106 reason 0E.  Records are byte0=02 (RLD only)
     * except the last, which is 0E (RLD + MODEND + SEGEND).  The SAMERP
     * R/P-continuation must NOT cross a record boundary -- fetch reads each
     * record into a fresh buffer, so every record's first item carries its full
     * R/P. --- */
    if (have_rld) {
        const long RLDMAX = 236;
        long rec_hdr = -1, rec_data = 0;
        int prevR = -1, prevP = -1; long prevflag_off = -1;
        for (i = 0; i < nO; i++) {
            struct obj *o = &O[i];
            for (j = 0; j < o->nrld; j++) {
                int Rg = local_to_g(o, o->rld[j].R);
                int Pg = local_to_g(o, o->rld[j].P);
                int Pgid = (Pg >= 0) ? G[Pg].gid : 0;
                long addr = o->object_base + o->rld[j].addr;
                int flag = o->rld[j].flag, Rgid = 0, resolved = 0, same, isize;
                if (Rg >= 0 && G[Rg].is_sect) { Rgid = G[Rg].gid; resolved = 1; }
                else if (Rg >= 0 && G[Rg].type == 0x03 && G[Rg].owner >= 0 && G[G[Rg].owner].is_sect) {
                    Rgid = G[G[Rg].owner].gid; resolved = 1;     /* LR adcon relocates via its owner section */
                } else if (Rg >= 0) Rgid = G[Rg].gid;
                if (!resolved) flag |= 0x80;                     /* unresolved -> do not relocate */
                same  = (rec_hdr >= 0 && Rgid == prevR && Pgid == prevP && prevflag_off >= 0);
                isize = same ? 4 : 8;                            /* flag+addr, or + R/P prefix */
                if (rec_hdr < 0 || rec_data + isize > RLDMAX) {  /* close prev record, start a new one */
                    unsigned char rh[16];
                    if (rec_hdr >= 0) put16(out + rec_hdr + 6, (int)rec_data);
                    memset(rh, 0, 16); rh[0] = 0x02;
                    rec_hdr = olen; emit(rh, 16); rec_data = 0;
                    prevR = prevP = -1; prevflag_off = -1; same = 0;   /* no continuation across records */
                }
                if (same) out[prevflag_off] |= 0x01;
                else { unsigned char rp[4]; put16(rp, Rgid); put16(rp + 2, Pgid); emit(rp, 4); rec_data += 4; }
                prevflag_off = olen;
                emitb(flag); { unsigned char a[3]; put24(a, addr); emit(a, 3); }
                rec_data += 4;
                prevR = Rgid; prevP = Pgid;
            }
        }
        if (rec_hdr >= 0) { put16(out + rec_hdr + 6, (int)rec_data); out[rec_hdr] = 0x0E; }
        trace("  RLD records:     %d item(s) in <=%ld-byte records (last byte0=0E)", total_rld, RLDMAX);
    }

    (void)entry_pt;
    f = fopen(outfile, "wb");
    if (!f) { perror(outfile); return 1; }
    fwrite(out, 1, olen, f);
    fclose(f);
    trace("=== done: wrote %ld-byte load module to %s ===", olen, outfile);

    /* optional: also emit the IEBCOPY unloaded image and/or the XMIT of the
     * linked member (the host->MVS install transport). The member just written
     * to -o is the ".lm"; --xmit is the shippable result, --unload the raw
     * unloaded image. */
    {
        const char *name = mname ? mname : basename_member(outfile);
        if (unloadfile && write_unload(unloadfile, name, out, olen, entry_addr, modlen)) return 1;
        if (xmitfile && write_xmit1(xmitfile, name, out, olen, dsn, entry_addr, modlen)) return 1;
    }
    return 0;
}
