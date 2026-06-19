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

int main(int argc, char **argv)
{
    const char *outfile = NULL, *objfiles[MAXOBJ];
    int nobjf = 0, i, j;
    FILE *f;

    for (i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "-o") && i + 1 < argc) outfile = argv[++i];
        else if (!strcmp(argv[i], "--verbose") || !strcmp(argv[i], "-v")) verbose = 1;
        else if (nobjf < MAXOBJ) objfiles[nobjf++] = argv[i];
    }
    if (!nobjf || !outfile) {
        fprintf(stderr, "usage: ld370 [--verbose] -o OUT.bin OBJ1.obj [OBJ2.obj ...]\n");
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
    return 0;
}
