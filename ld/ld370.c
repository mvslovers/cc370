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
 * Build:  gcc -O2 -Wall -Wextra -Werror -o ld/ld370 ld/ld370.c
 * Usage:  ld370 [--verbose] -o OUT.bin OBJ1.obj [OBJ2.obj ...]
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

/* ---- model ---- */
#define MAXESD 512
#define MAXOBJ 32
enum { T_SD = 0x00, T_LD = 0x01, T_ER = 0x02, T_PC = 0x04, T_CM = 0x05 };
static int is_sect_type(int t) { return t == T_SD || t == T_PC || t == T_CM; }

/* composite (global) symbol = one CESD entry */
struct gsym { unsigned char name[8]; int type; int is_sect; int gid; long org, len;
              int def_obj; long in_addr;   /* section: defining object + origin within it */
              int owner; };                /* LR (label/entry): gsym index of the owning section */
static struct gsym G[MAXESD];
static int nG = 0;

static int g_find(const unsigned char *name)
{
    int i;
    for (i = 0; i < nG; i++)
        if (memcmp(G[i].name, name, 8) == 0) return i;
    return -1;
}
static int g_intern(const unsigned char *name, int type)
{
    int i = g_find(name);
    if (i >= 0) return i;
    memcpy(G[nG].name, name, 8);
    G[nG].type = type; G[nG].is_sect = 0; G[nG].gid = 0; G[nG].org = 0; G[nG].len = 0;
    G[nG].def_obj = -1; G[nG].in_addr = 0; G[nG].owner = -1;
    return nG++;
}

/* per input object (each is single-CSECT in the cc370/as370 case) */
struct lent { int used; unsigned char name[8]; int type; long addr, len; };
struct orld { int R, P, flag; long addr; };
struct obj {
    struct lent loc[MAXESD];          /* local ESD by local ESDID */
    int sect_local;                   /* local id of this object's section */
    unsigned char text[1 << 14];
    long textlen;
    struct orld rld[512];
    int nrld;
    struct { unsigned char name[8]; long addr; int owner_local; } ld[64];   /* label defs (entries) */
    int nld;
    long object_base;                 /* assigned base address of this object's section(s) */
};
static struct obj O[MAXOBJ];
static int nO = 0;
static long entry_pt = 0;

/* ---- PASS 1: object-deck reader (inverse of as370.c) ---- */
static void parse_object(FILE *f, struct obj *o)
{
    unsigned char c[80];
    memset(o, 0, sizeof *o);
    o->sect_local = -1;
    while (fread(c, 1, 80, f) == 80) {
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
            long addr = be24(c + 5); int cnt = be16(c + 10);
            if (addr + cnt <= (long)sizeof o->text) {
                memcpy(o->text + addr, c + 16, cnt);
                if (addr + cnt > o->textlen) o->textlen = addr + cnt;
            }
            trace("  TXT  %d bytes -> local section id=%d at offset %06lX", cnt, be16(c + 14), addr);
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
            if (!(c[5] == 0x40 && c[6] == 0x40 && c[7] == 0x40)) entry_pt = be24(c + 5);
        }
    }
}

/* map a local ESDID in object o to its index in the composite symbol table */
static int local_to_g(struct obj *o, int localid)
{
    if (localid < 1 || localid >= MAXESD || !o->loc[localid].used) return -1;
    return g_find(o->loc[localid].name);
}

/* ---- emitter ---- */
static unsigned char out[1 << 16];
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
    struct lmblock blk[128]; int nblk;
    int first_r, text_r;
};

/* Split a load-module member byte stream into its physical blocks (the records
 * a loader/IEWFETCH would see).  Record types by byte 0:
 *   X'20' CESD  -> 8-byte header + ESD bytes (count at off 6)
 *   X'80' IDR   -> length = byte 1 + 1
 *   high nibble 0 (control/RLD): 16 + ID-list(off 4) + RLD bytes(off 6);
 *                 if the TXT bit (X'01') is set a pure-text record of length
 *                 (off 14) follows as its OWN block.
 * Returns block count, or -1 on an unrecognised record. */
static int split_member(const unsigned char *m, long n, struct lmblock *b, int maxb)
{
    long p = 0; int k = 0;
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
            if (k >= maxb) return -1;
            b[k].off = p; b[k].len = blen; b[k].is_text = 0; k++;
            p += blen;
            if (txt && tlen) {
                if (k >= maxb) return -1;
                b[k].off = p; b[k].len = tlen; b[k].is_text = 1; k++;
                p += tlen;
            }
            continue;                                   /* self-contained; skip the CESD/IDR tail below */
        } else {
            return -1;                                  /* SYM/scatter: not produced by cc370/as370 yet */
        }
        if (k >= maxb) return -1;                        /* CESD / IDR: one block, advance and loop */
        b[k].off = p; b[k].len = blen; b[k].is_text = 0; k++;
        p += blen;
    }
    return k;
}

/* build the 24-byte PDS2 user-data for a member: echo template, overlay the
 * computed first-text TTR (relative track 0, record text_r). */
static void build_userdata(unsigned char ud[24], const struct umember *m)
{
    memcpy(ud, unload_userdata, 24);
    ud[0] = 0; ud[1] = 0; ud[2] = (unsigned char)m->text_r;   /* PDS2TTRT = (0, text_r) */
}

/* COPYR1 logical-record length within the 328-byte env header (COPYR2 is the
 * remaining 276). IEBCOPY/TRANSMIT writes COPYR1 and COPYR2 as separate
 * records (confirmed by IDCAMS PRINT of a real unload). */
#define UNLOAD_COPYR1_LEN 52

/* Emit the IEBCOPY unloaded image of one-or-more members into o[]; return the
 * byte length.  If bounds!=NULL, fill the 4 logical-record end offsets the
 * unload is split into when transmitted: COPYR1, COPYR2, directory(+EOD),
 * member-data(+EOM) -- the 4 data records of the XMIT payload.
 * v1: single track, ascending R (no track-overflow), one directory block. */
static long emit_unload(unsigned char *o, struct umember *mem, int nmem, long *bounds)
{
    long p = 0; int i, j, r, eom_r;
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

    /* assign each block a record number, single track ascending from base.
     * TODO(multi-track): when blocks overflow one track, advance HH then CC
     * (and grow UDEBX) keeping MBBCCHHR monotonic; today we assume one track. */
    r = UNLOAD_FIRST_R;
    for (i = 0; i < nmem; i++) {
        mem[i].first_r = r;
        mem[i].text_r = r;
        for (j = 0; j < mem[i].nblk; j++) {
            if (mem[i].blk[j].is_text) mem[i].text_r = r;
            r++;
        }
    }
    eom_r = r;
    if (r > 255) trace("WARNING: %d records exceed one track -- multi-track not yet emitted", r);

    /* directory block: 2-byte used count, member entries (assumed name-sorted
     * by the caller -- true for v1), FF terminator entry, zero pad. */
    memset(dir, 0, sizeof dir);
    used = 2;
    for (i = 0; i < nmem; i++) {
        unsigned char *e = dir + used;
        memcpy(e, mem[i].name, 8);
        e[8] = 0; e[9] = 0; e[10] = (unsigned char)mem[i].first_r;   /* TTR = (0, first_r) */
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

    /* member data: one CKD record image per physical block */
    r = UNLOAD_FIRST_R;
    for (i = 0; i < nmem; i++)
        for (j = 0; j < mem[i].nblk; j++) {
            long bl = mem[i].blk[j].len;
            put_count(o + p, UNLOAD_DATA_CC, 0, r, 0, (int)bl); p += 12;
            memcpy(o + p, mem[i].bytes + mem[i].blk[j].off, bl); p += bl;
            r++;
        }
    put_count(o + p, UNLOAD_DATA_CC, 0, eom_r, 0, 0); p += 12;   /* EOM */
    if (bounds) bounds[3] = p;                          /* member data + EOM */
    return p;
}

/* Split each member, emit the unloaded image of all of them and write it to
 * path.  mem[].name/.bytes/.len must be set by the caller. Returns 0 on ok. */
static int write_unload_mem(const char *path, struct umember *mem, int nmem)
{
    static unsigned char unl[1 << 18];
    long ulen; FILE *f; int i;

    for (i = 0; i < nmem; i++) {
        mem[i].nblk = split_member(mem[i].bytes, mem[i].len, mem[i].blk, 128);
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
    trace("=== done: wrote %ld-byte unloaded image (%d member%s) to %s ===",
          ulen, nmem, nmem == 1 ? "" : "s", path);
    return 0;
}

/* convenience: unload a single in-memory member */
static int write_unload(const char *path, const char *name,
                        const unsigned char *member, long mlen)
{
    struct umember m;
    memset(&m, 0, sizeof m);
    member_name(m.name, name);
    m.bytes = member; m.len = mlen;
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
    tui(r, &rp, INMBLKSZ, 19069, 4);
    tui(r, &rp, INMRECFM, 0xc002, 2);                   /* U */
    tu_dsname(r, &rp, dsn);
    netdata_seg(o, &p, r, rp, 1);

    /* INMR02 #2 -- INMCOPY: attributes of the unloaded form (the in-stream data,
     * RECFM=VS).  Constant for our IEBCOPY-unload format. */
    rp = inmr_hdr(r, 2);
    put24(r + rp, 0); r[rp + 3] = 1; rp += 4;
    tus(r, &rp, INMUTILN, "INMCOPY");
    tui(r, &rp, INMSIZE, 15600, 4);
    tui(r, &rp, INMLRECL, 19085, 4);
    tui(r, &rp, INMDSORG, 0x4000, 2);                   /* PS */
    tui(r, &rp, INMBLKSZ, 3120, 4);
    tui(r, &rp, INMRECFM, 0x4802, 2);                   /* VS */
    netdata_seg(o, &p, r, rp, 1);

    /* INMR03 -- data record descriptor */
    rp = inmr_hdr(r, 3);
    tui(r, &rp, INMSIZE, 19069, 4);
    tui(r, &rp, INMLRECL, 80, 4);
    tui(r, &rp, INMDSORG, 0x4000, 2);
    tui(r, &rp, INMRECFM, 0x0001, 2);
    netdata_seg(o, &p, r, rp, 1);

    /* the 4 unloaded data records (COPYR1 / COPYR2 / dir+EOD / member+EOM) */
    netdata_seg(o, &p, unl,             bounds[0],              0);
    netdata_seg(o, &p, unl + bounds[0], bounds[1] - bounds[0], 0);
    netdata_seg(o, &p, unl + bounds[1], bounds[2] - bounds[1], 0);
    netdata_seg(o, &p, unl + bounds[2], bounds[3] - bounds[2], 0);

    /* INMR06 -- trailer */
    rp = inmr_hdr(r, 6);
    netdata_seg(o, &p, r, rp, 1);

    while (p % 80) o[p++] = 0;                           /* pad final FB80 record */
    return p;
}

/* Build the XMIT image of members[] and write it to path. */
static int write_xmit(const char *path, struct umember *mem, int nmem, const char *dsn)
{
    static unsigned char unl[1 << 18], xm[1 << 18];
    long bounds[4], ulen, xlen; FILE *f; int i;

    for (i = 0; i < nmem; i++) {
        mem[i].nblk = split_member(mem[i].bytes, mem[i].len, mem[i].blk, 128);
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
    trace("=== done: wrote %ld-byte XMIT (%d FB80 recs, %d member%s) to %s ===",
          xlen, (int)(xlen / 80), nmem, nmem == 1 ? "" : "s", path);
    return 0;
}

/* convenience: XMIT a single in-memory member */
static int write_xmit1(const char *path, const char *name,
                       const unsigned char *member, long mlen, const char *dsn)
{
    struct umember m;
    memset(&m, 0, sizeof m);
    member_name(m.name, name);
    m.bytes = member; m.len = mlen;
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

int main(int argc, char **argv)
{
    const char *outfile = NULL, *unloadfile = NULL, *unloadfrom = NULL, *mname = NULL;
    const char *xmitfile = NULL, *dsn = NULL;
    const char *objfiles[MAXOBJ];
    char *packspec[MAXOBJ];
    int nobjf = 0, npack = 0, i, j;
    FILE *f;

    for (i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "-o") && i + 1 < argc) outfile = argv[++i];
        else if (!strcmp(argv[i], "--unload") && i + 1 < argc) unloadfile = argv[++i];
        else if (!strcmp(argv[i], "--unload-from") && i + 1 < argc) unloadfrom = argv[++i];
        else if (!strcmp(argv[i], "--xmit") && i + 1 < argc) xmitfile = argv[++i];
        else if (!strcmp(argv[i], "--dsn") && i + 1 < argc) dsn = argv[++i];
        else if (!strcmp(argv[i], "--name") && i + 1 < argc) mname = argv[++i];
        else if (!strcmp(argv[i], "--pack") && i + 1 < argc && npack < MAXOBJ) packspec[npack++] = argv[++i];
        else if (!strcmp(argv[i], "--verbose") || !strcmp(argv[i], "-v")) verbose = 1;
        else if (nobjf < MAXOBJ) objfiles[nobjf++] = argv[i];
    }
    if (!dsn) dsn = "IBMUSER.HOST.LOAD";       /* INMDSNAM default; RECEIVE DA(...) overrides */

    /* --- standalone wrap: an existing flat member, no object linking.
     *     ld370 --unload-from MEMBER.lm [--name NAME] [--unload OUT] [--xmit OUT] --- */
    if (unloadfrom) {
        static unsigned char memb[1 << 16];
        long mlen; const char *name;
        if (!unloadfile && !xmitfile) { fprintf(stderr, "ld370: --unload-from needs --unload and/or --xmit OUT\n"); return 2; }
        f = fopen(unloadfrom, "rb");
        if (!f) { perror(unloadfrom); return 1; }
        mlen = (long)fread(memb, 1, sizeof memb, f);
        fclose(f);
        name = mname ? mname : basename_member(unloadfrom);
        if (unloadfile && write_unload(unloadfile, name, memb, mlen)) return 1;
        if (xmitfile && write_xmit1(xmitfile, name, memb, mlen, dsn)) return 1;
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
        }
        if (unloadfile) rc = write_unload_mem(unloadfile, m, npack);
        if (!rc && xmitfile) rc = write_xmit(xmitfile, m, npack, dsn);
        for (i = 0; i < npack; i++) free((void *)m[i].bytes);
        return rc;
    }

    if (!nobjf || !outfile) {
        fprintf(stderr,
                "usage: ld370 [-v] -o OUT.bin [--unload U] [--xmit X [--dsn DS]] [--name N] OBJ...\n"
                "       ld370 --unload-from MEMBER.lm [--name N] [--unload U] [--xmit X]\n"
                "       ld370 --pack N1=M1.lm [--pack N2=M2.lm ...] [--unload U] [--xmit X]\n");
        return 2;
    }

    /* --- PASS 1: read every object module --- */
    trace("=== PASS 1: read %d object module(s) ===", nobjf);
    for (i = 0; i < nobjf; i++) {
        trace("- object: %s", objfiles[i]);
        f = fopen(objfiles[i], "rb");
        if (!f) { perror(objfiles[i]); return 1; }
        parse_object(f, &O[nO]);
        fclose(f);
        nO++;
    }

    /* --- PASS 2: build the composite ESD (resolve ER -> SD by name) --- */
    trace("=== PASS 2: build composite ESD, resolve references ===");
    for (i = 0; i < nO; i++) {
        struct obj *o = &O[i];
        for (j = 1; j < MAXESD; j++) {
            if (!o->loc[j].used) continue;
            int gi = g_intern(o->loc[j].name, o->loc[j].type);
            if (is_sect_type(o->loc[j].type)) {       /* a section definition */
                G[gi].is_sect = 1; G[gi].type = o->loc[j].type; G[gi].len = o->loc[j].len;
                G[gi].def_obj = i; G[gi].in_addr = o->loc[j].addr;   /* its object + origin within it */
            }
        }
        for (j = 0; j < o->nld; j++) {            /* label defs (entries) -> composite LR (type 03) */
            int gi = g_intern(o->ld[j].name, T_LD);
            G[gi].type = 0x03; G[gi].in_addr = o->ld[j].addr;
            int ol = o->ld[j].owner_local;
            G[gi].owner = (ol >= 1 && ol < MAXESD && o->loc[ol].used) ? g_find(o->loc[ol].name) : -1;
        }
    }
    for (i = 0; i < nG; i++)
        if (!G[i].is_sect && G[i].type == T_ER)
            trace("  '%s': UNRESOLVED external (no defining section)", nm(G[i].name));

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
    trace("  module length = %ld", modlen);

    /* --- build module text image + relocate address constants --- */
    static unsigned char mod[1 << 16];
    memset(mod, 0, modlen);
    for (i = 0; i < nO; i++) memcpy(mod + O[i].object_base, O[i].text, O[i].textlen);
    trace("=== relocate address constants ===");
    for (i = 0; i < nO; i++) {
        struct obj *o = &O[i];
        for (j = 0; j < o->nrld; j++) {
            int Rg = local_to_g(o, o->rld[j].R);
            long loc = o->object_base + o->rld[j].addr;
            int len = ((o->rld[j].flag >> 2) & 3) + 1;
            if (Rg >= 0 && G[Rg].is_sect) {           /* resolved: relocate by (final origin - input origin) */
                long delta = G[Rg].org - o->loc[o->rld[j].R].addr;
                long v = rdval(mod + loc, len) + delta;
                wrval(mod + loc, v, len);
                trace("  adcon@%06lX -> %s: %+ld (final %06lX - input %06lX)",
                      loc, nm(G[Rg].name), delta, G[Rg].org, o->loc[o->rld[j].R].addr);
            } else {
                trace("  adcon@%06lX -> %s: UNRESOLVED, left for the loader",
                      loc, Rg >= 0 ? nm(G[Rg].name) : "?");
            }
        }
    }

    /* --- emit: CESD --- */
    trace("=== emit load-module record stream ===");
    long cesd_off = olen;
    emitb(0x20); emitb(0); emitb(0); emitb(0);
    { unsigned char h[4]; put16(h, 1); put16(h + 2, 16 * nG); emit(h, 4); }
    for (gid = 1; gid <= nG; gid++) {
        int gi = -1;
        for (i = 0; i < nG; i++) if (G[i].gid == gid) { gi = i; break; }
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
        emit(e, 16);
    }
    trace("  CESD record:     %ld bytes  (%d entr%s: %d section(s) + %d unresolved ER)",
          olen - cesd_off, nG, nG == 1 ? "y" : "ies", nsect, nG - nsect);

    /* --- SPZAP IDR (fixed 251B, header 80 FA 01 00, zero) --- */
    emitb(0x80); emitb(0xFA); emitb(0x01); emitb(0x00);
    for (i = 0; i < 247; i++) emitb(0);
    trace("  SPZAP-IDR:       251 bytes");

    int total_rld = 0;
    for (i = 0; i < nO; i++) total_rld += O[i].nrld;
    int have_rld = total_rld > 0;

    /* --- control record (ID-length list over the sections, in origin order) --- */
    {
        int idlen = 4 * nsect;
        unsigned char cr[16 + 4 * MAXESD]; memset(cr, 0, (size_t)(16 + idlen));
        cr[0] = have_rld ? 0x01 : 0x0D;
        put16(cr + 4, idlen); put16(cr + 6, 0);
        cr[8] = 0x06; put24(cr + 9, 0); cr[12] = 0x40; put16(cr + 14, (int)modlen);
        for (gid = 1; gid <= nsect; gid++) {          /* sections are gid 1..nsect, in origin order */
            int gi = -1; for (i = 0; i < nG; i++) if (G[i].gid == gid) { gi = i; break; }
            long span = (gid < nsect ? G[gi].org + roundup8(G[gi].len) : modlen) - G[gi].org;
            put16(cr + 16 + 4 * (gid - 1), gid);
            put16(cr + 18 + 4 * (gid - 1), (int)span);
        }
        emit(cr, 16 + idlen);
        trace("  control record:  %d bytes  byte0=%02X, %d section(s), %ld-byte text",
              16 + idlen, cr[0], nsect, modlen);
    }

    /* --- text record --- */
    emit(mod, modlen);
    trace("  text record:     %ld bytes", modlen);

    /* --- RLD record (0E = RLD + EOM): all objects' RLDs, remapped to global --- */
    if (have_rld) {
        long hdr = olen; unsigned char rh[16]; memset(rh, 0, 16); rh[0] = 0x0E; emit(rh, 16);
        long data = olen;
        int prevR = -1, prevP = -1; long prevflag_off = -1;
        for (i = 0; i < nO; i++) {
            struct obj *o = &O[i];
            for (j = 0; j < o->nrld; j++) {
                int Rg = local_to_g(o, o->rld[j].R);
                int Pg = local_to_g(o, o->rld[j].P);
                int Rgid = (Rg >= 0) ? G[Rg].gid : 0;
                int Pgid = (Pg >= 0) ? G[Pg].gid : 0;
                long addr = o->object_base + o->rld[j].addr;
                int flag = o->rld[j].flag;
                if (!(Rg >= 0 && G[Rg].is_sect)) flag |= 0x80;   /* unresolved -> do not relocate */
                if (Rgid == prevR && Pgid == prevP && prevflag_off >= 0) {
                    out[prevflag_off] |= 0x01;
                } else {
                    unsigned char rp[4]; put16(rp, Rgid); put16(rp + 2, Pgid); emit(rp, 4);
                }
                prevflag_off = olen;
                emitb(flag);
                { unsigned char a[3]; put24(a, addr); emit(a, 3); }
                prevR = Rgid; prevP = Pgid;
            }
        }
        put16(out + hdr + 6, (int)(olen - data));
        trace("  RLD record:      %ld bytes  byte0=0E (RLD + EOM), %d item(s)", olen - hdr, total_rld);
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
        if (unloadfile && write_unload(unloadfile, name, out, olen)) return 1;
        if (xmitfile && write_xmit1(xmitfile, name, out, olen, dsn)) return 1;
    }
    return 0;
}
