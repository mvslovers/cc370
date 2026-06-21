/* ar370 - object-deck archiver for the host-native MVS toolchain.
 *
 * Packages OS/360 object decks (as produced by as370) into a standard `ar`
 * archive (`!<arch>`, host-inspectable with `ar t`) and writes a symbol table
 * built from each member's ESD -- the static-library / NCALIB equivalent that
 * ld370's automatic library call resolves unresolved ERs against.
 *
 * The symbol table uses the GNU `ar` "/" member layout: a 4-byte count, that
 * many 4-byte big-endian member-header offsets, then the symbol names as a
 * NUL-terminated string table. Names are variable length -- ready for the
 * planned move from 8-char OS/360 externals to long symbols (no format change).
 * The names come from our own ESD scan (SD/CM/LD + named PC); host `ranlib`
 * cannot index OS/360 decks.
 *
 * Build: gcc -O2 -Wall -Wextra -Werror -o ld/ar370 ld/ar370.c
 * Usage: ar370 rc  ARCHIVE.a  OBJ1.o [OBJ2.o ...]   create with symbol table
 *        ar370 t   ARCHIVE.a                          list members + symbols
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAXOBJ 2048
#define MAXSYM 16384

/* EBCDIC (CP037) -> ASCII, for ESD symbol names (uppercase/digits/nationals) */
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

struct objf { const char *member; unsigned char *data; long size; };
struct sym  { char name[64]; int obj; };

static struct objf O[MAXOBJ]; static int nO;
static struct sym  S[MAXSYM]; static int nS;

static const char *basename_of(const char *p)
{
    const char *s = p, *q;
    for (q = p; *q; q++) if (*q == '/' || *q == '\\') s = q + 1;
    return s;
}

/* scan one object deck's ESD cards; record EVERY exported symbol (SD/LD/CM,
 * non-blank name) -- including duplicates across members.  A symbol defined by
 * more than one member (e.g. @@CRT0 by @@crt0/@@crt1/@@crtm, @@EXITA by @@crtm
 * and @@exita) gets one symtab entry per definer, so the linker (ld370) can
 * pick a NON-CONFLICTING definer at autocall time -- pulling @@exita.o for
 * @@EXITA instead of the @@crtm.o startup that also re-defines @@CRT0.  The GNU
 * ar symbol table permits duplicate names. */
static void scan_esd(int oi)
{
    unsigned char *d = O[oi].data; long n = O[oi].size, i;
    for (i = 0; i + 80 <= n; i += 80) {
        unsigned char *c = d + i;
        if (!(c[0] == 0x02 && c[1] == 0xC5 && c[2] == 0xE2 && c[3] == 0xC4)) continue;  /* ESD */
        int cnt = (c[10] << 8) | c[11], k;
        for (k = 0; k * 16 < cnt && 16 + (k + 1) * 16 <= 80; k++) {
            unsigned char *e = c + 16 + k * 16;
            int t = e[8] & 0x0f, j, blank = 1;
            char nm[9];
            if (!(t == 0x00 || t == 0x01 || t == 0x04 || t == 0x05)) continue;  /* SD/LD/PC/CM */
            for (j = 0; j < 8; j++) { nm[j] = e2a1(e[j]); if (e[j] != 0x40) blank = 0; }
            nm[8] = 0;
            for (j = 7; j >= 0 && nm[j] == ' '; j--) nm[j] = 0;
            if (blank) continue;                                    /* unnamed private code */
            if (nS < MAXSYM) { strcpy(S[nS].name, nm); S[nS].obj = oi; nS++; }
        }
    }
}

static unsigned char *read_file(const char *path, long *len)
{
    FILE *f = fopen(path, "rb"); long n; unsigned char *b; size_t got;
    if (!f) { perror(path); return NULL; }
    fseek(f, 0, SEEK_END); n = ftell(f); fseek(f, 0, SEEK_SET);
    b = malloc((size_t)n ? (size_t)n : 1);
    got = fread(b, 1, (size_t)n, f); (void)got; fclose(f);
    *len = n; return b;
}

/* write a 60-byte `ar` member header with a verbatim 16-byte name field */
static void ar_hdr(FILE *f, const char *namefield, long size)
{
    char h[61];
    snprintf(h, sizeof h, "%-16.16s%-12d%-6d%-6d%-8.8s%-10ld`\n",
             namefield, 0, 0, 0, "100644", size);
    fwrite(h, 1, 60, f);
}
static void put_be32(unsigned char *p, unsigned long v)
{ p[0] = (v >> 24) & 0xff; p[1] = (v >> 16) & 0xff; p[2] = (v >> 8) & 0xff; p[3] = v & 0xff; }

static int create(const char *arch, int argc, char **argv, int first)
{
    long stringtab = 0, symdata, symmember, off; int i, s; FILE *f;

    for (i = first; i < argc && nO < MAXOBJ; i++) {
        O[nO].member = basename_of(argv[i]);
        O[nO].data = read_file(argv[i], &O[nO].size);
        if (!O[nO].data) return 1;
        scan_esd(nO);
        nO++;
    }

    /* symbol-table member ("/"): count(4) + offsets(4*nS) + NUL-term names */
    for (s = 0; s < nS; s++) stringtab += (long)strlen(S[s].name) + 1;
    symdata = 4 + 4 * nS + stringtab;
    symmember = 60 + symdata + (symdata & 1);             /* header + even-padded data */

    /* member-header offsets (symbol table points at these) */
    static long objoff[MAXOBJ];
    off = 8 + symmember;                                  /* after magic + symtab member */
    for (i = 0; i < nO; i++) { objoff[i] = off; off += 60 + O[i].size + (O[i].size & 1); }

    f = fopen(arch, "wb");
    if (!f) { perror(arch); return 1; }
    fwrite("!<arch>\n", 1, 8, f);

    ar_hdr(f, "/", symdata);
    { unsigned char b[4]; put_be32(b, (unsigned long)nS); fwrite(b, 1, 4, f); }
    for (s = 0; s < nS; s++) { unsigned char b[4]; put_be32(b, (unsigned long)objoff[S[s].obj]); fwrite(b, 1, 4, f); }
    for (s = 0; s < nS; s++) fwrite(S[s].name, 1, strlen(S[s].name) + 1, f);
    if (symdata & 1) fputc('\n', f);

    for (i = 0; i < nO; i++) {
        char nf[17]; snprintf(nf, sizeof nf, "%s/", O[i].member);
        ar_hdr(f, nf, O[i].size);
        fwrite(O[i].data, 1, (size_t)O[i].size, f);
        if (O[i].size & 1) fputc('\n', f);
    }
    fclose(f);
    return 0;
}

/* list members + the symbol table of an existing archive */
static int list(const char *arch)
{
    long n; unsigned char *a = read_file(arch, &n); long p = 8; int s;
    if (!a) return 1;
    if (n < 8 || memcmp(a, "!<arch>\n", 8)) { fprintf(stderr, "ar370: %s: not an archive\n", arch); return 1; }
    while (p + 60 <= n) {
        char name[17], szs[11]; long size;
        memcpy(name, a + p, 16); name[16] = 0;
        memcpy(szs, a + p + 48, 10); szs[10] = 0; size = atol(szs);
        { char *e = strchr(name, ' '); if (e) *e = 0; }            /* trim padding */
        if (!strcmp(name, "/")) {
            long q = p + 60; unsigned long cnt = ((unsigned long)a[q] << 24) | (a[q+1] << 16) | (a[q+2] << 8) | a[q+3];
            const char *names = (const char *)(a + q + 4 + 4 * cnt);
            printf("symbol table: %lu symbol(s)\n", cnt);
            for (s = 0; (unsigned)s < cnt; s++) { printf("  %s\n", names); names += strlen(names) + 1; }
        } else {
            printf("%-16s %ld bytes\n", name, size);
        }
        p += 60 + size + (size & 1);
    }
    free(a);
    return 0;
}

int main(int argc, char **argv)
{
    if (argc < 3) {
        fprintf(stderr, "usage: ar370 rc ARCHIVE.a OBJ...   (create with symbol table)\n"
                        "       ar370 t  ARCHIVE.a           (list members + symbols)\n");
        return 2;
    }
    if (strchr(argv[1], 't')) return list(argv[2]);
    if (strchr(argv[1], 'r') || strchr(argv[1], 'c')) return create(argv[2], argc, argv, 3);
    fprintf(stderr, "ar370: unknown operation '%s'\n", argv[1]);
    return 2;
}
