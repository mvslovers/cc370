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
 * A member name that does not fit the header's 16 bytes with its "/" goes into
 * the GNU "//" long-name member, and the header names it "/<offset>" -- the
 * layout ld370 already reads (#805).  It used to be cut to 16 bytes silently.
 *
 * Usage: ar370 rc  ARCHIVE.a  OBJ1.o [OBJ2.o ...]   (re)create with symbol table
 *        ar370 t   ARCHIVE.a                          list members + symbols
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "mvs370.h"
#include "cc370-version.h"   /* CC370_VERSION, CC370_COMMIT (common/mkversion.sh) */

/* Objects and symbols grow as needed.  They were fixed at 2048 and 16384, and
 * the 2049th object and the 16385th symbol were dropped silently at rc 0
 * (#805). */
struct objf { const char *member; unsigned char *data; long size; long lnoff; };
struct sym  { char name[64]; int obj; };

static struct objf *O; static int nO, capO;
static struct sym  *S; static int nS, capS;

/* ld370 keeps a member name in 64 bytes; a longer one could never be named by
 * --include, so it is refused rather than stored. */
#define MEMBER_NAME_MAX 63

static void *grow(void *p, int *cap, int need, size_t size)
{
    if (need <= *cap) return p;
    int nc = *cap ? *cap * 2 : 256;
    while (nc < need) nc *= 2;
    void *q = realloc(p, (size_t)nc * size);
    if (!q) { fprintf(stderr, "ar370: out of memory\n"); exit(1); }
    *cap = nc;
    return q;
}

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
            for (j = 0; j < 8; j++) { nm[j] = mvs_e2a_pr(e[j]); if (e[j] != 0x40) blank = 0; }
            nm[8] = 0;
            for (j = 7; j >= 0 && nm[j] == ' '; j--) nm[j] = 0;
            if (blank) continue;                                    /* unnamed private code */
            S = grow(S, &capS, nS + 1, sizeof *S);
            strcpy(S[nS].name, nm); S[nS].obj = oi; nS++;
        }
    }
}

/* write a 60-byte `ar` member header with a verbatim 16-byte name field */
/* The `ar` size field is ten characters wide, so a header cannot express a
 * member of 10**10 bytes or more -- and h[] is exactly the 60-byte header
 * plus its NUL, with no slack for an eleventh digit.  Refusing is the only
 * honest answer: truncating would write a header that looks well-formed for
 * the wrong length, and every member after it is found by walking from that
 * length, so the whole archive past this point would be misread.
 *
 * Narrowing the range is also what silences GCC's -Wformat-truncation here
 * (#452), which on GCC 12 is an error under -Werror and on 16.1 needs
 * -Wformat-truncation=2 to show.  The diagnostic going away is a consequence
 * of the bound, not the reason for it. */
#define AR_SIZE_MAX 9999999999L

static void ar_hdr(FILE *f, const char *namefield, long size)
{
    char h[61];
    if (size < 0 || size > AR_SIZE_MAX) {
        fprintf(stderr, "ar370: member is %ld bytes; an ar header's size field "
                        "holds 10 digits and cannot express it\n", size);
        exit(1);
    }
    snprintf(h, sizeof h, "%-16.16s%-12d%-6d%-6d%-8.8s%-10ld`\n",
             namefield, 0, 0, 0, "100644", size);
    fwrite(h, 1, 60, f);
}
/* Is this an OS/360 object deck: 80-byte cards, each beginning X'02' and
 * carrying a card type, with an END card?  ar370 stored any file it was given,
 * an archive included (#805); ld370 would then fail on it far from the cause. */
static const char *not_a_deck(const unsigned char *d, long n)
{
    long i; int end = 0;
    if (n >= 8 && !memcmp(d, "!<arch>\n", 8)) return "is an archive, not an object deck";
    if (n <= 0 || n % 80) return "is not an object deck (not a multiple of 80-byte cards)";
    for (i = 0; i < n; i += 80) {
        if (d[i] != 0x02) return "is not an object deck (a card does not begin X'02')";
        if (d[i + 1] == 0xC5 && d[i + 2] == 0xD5 && d[i + 3] == 0xC4) end = 1;   /* END */
    }
    return end ? NULL : "is not an object deck (no END card)";
}

static int create(const char *arch, int argc, char **argv, int first)
{
    long stringtab = 0, symdata, symmember, lndata = 0, lnmember = 0, off; int i, s; FILE *f;

    for (i = first; i < argc; i++) {
        const char *why;
        O = grow(O, &capO, nO + 1, sizeof *O);
        O[nO].member = basename_of(argv[i]);
        O[nO].lnoff = -1;
        O[nO].data = mvs_read_file(argv[i], &O[nO].size);
        if (!O[nO].data) { perror(argv[i]); return 1; }
        if ((why = not_a_deck(O[nO].data, O[nO].size)) != NULL) {
            fprintf(stderr, "ar370: %s %s\n", argv[i], why);
            return 1;
        }
        if (strlen(O[nO].member) > MEMBER_NAME_MAX) {
            fprintf(stderr, "ar370: %s: member name longer than %d characters\n", argv[i], MEMBER_NAME_MAX);
            return 1;
        }
        if (strlen(O[nO].member) > 15) {          /* "name/" does not fit 16 bytes */
            O[nO].lnoff = lndata;
            lndata += (long)strlen(O[nO].member) + 2;    /* "name/\n" */
        }
        scan_esd(nO);
        nO++;
    }

    /* symbol-table member ("/"): count(4) + offsets(4*nS) + NUL-term names */
    for (s = 0; s < nS; s++) stringtab += (long)strlen(S[s].name) + 1;
    symdata = 4 + 4 * nS + stringtab;
    symmember = 60 + symdata + (symdata & 1);             /* header + even-padded data */
    if (lndata) lnmember = 60 + lndata + (lndata & 1);    /* "//" long names, after "/" */

    /* member-header offsets (symbol table points at these) */
    long *objoff = malloc((size_t)(nO ? nO : 1) * sizeof *objoff);
    if (!objoff) { fprintf(stderr, "ar370: out of memory\n"); return 1; }
    off = 8 + symmember + lnmember;                       /* after magic + symtab + long names */
    for (i = 0; i < nO; i++) { objoff[i] = off; off += 60 + O[i].size + (O[i].size & 1); }

    f = fopen(arch, "wb");
    if (!f) { perror(arch); return 1; }
    fwrite("!<arch>\n", 1, 8, f);

    ar_hdr(f, "/", symdata);
    { unsigned char b[4]; mvs_put32(b, (unsigned long)nS); fwrite(b, 1, 4, f); }
    for (s = 0; s < nS; s++) { unsigned char b[4]; mvs_put32(b, (unsigned long)objoff[S[s].obj]); fwrite(b, 1, 4, f); }
    for (s = 0; s < nS; s++) fwrite(S[s].name, 1, strlen(S[s].name) + 1, f);
    if (symdata & 1) fputc('\n', f);

    if (lndata) {
        ar_hdr(f, "//", lndata);
        for (i = 0; i < nO; i++)
            if (O[i].lnoff >= 0) fprintf(f, "%s/\n", O[i].member);
        if (lndata & 1) fputc('\n', f);
    }

    for (i = 0; i < nO; i++) {
        char nf[17];
        if (O[i].lnoff >= 0) snprintf(nf, sizeof nf, "/%ld", O[i].lnoff);
        else snprintf(nf, sizeof nf, "%s/", O[i].member);
        ar_hdr(f, nf, O[i].size);
        fwrite(O[i].data, 1, (size_t)O[i].size, f);
        if (O[i].size & 1) fputc('\n', f);
    }
    free(objoff);
    if (fclose(f)) { perror(arch); return 1; }
    return 0;
}

/* A member's name as the header gives it: "name/" short, "/NNN" an offset into
 * the "//" long-name member.  Without the trailing "/" either way (#805: `t'
 * printed "name/"). */
static void member_name(const unsigned char *h, const unsigned char *ln, long lnlen, char *out, size_t outsz)
{
    size_t L = 0;
    if (h[0] == '/' && h[1] >= '0' && h[1] <= '9' && ln) {
        long o = atol((const char *)h + 1);
        while (o < lnlen && ln[o] != '/' && ln[o] != '\n' && L + 1 < outsz) out[L++] = (char)ln[o++];
    } else {
        while (L < 16 && h[L] != '/' && h[L] != ' ' && L + 1 < outsz) { out[L] = (char)h[L]; L++; }
    }
    out[L] = 0;
}

/* list the members, then every symbol with the member that defines it -- the
 * symbol table holds the member's header offset, which is what ties them */
static int list(const char *arch)
{
    long n; unsigned char *a = mvs_read_file(arch, &n); long p = 8, q;
    const unsigned char *symtab = NULL, *ln = NULL; long lnlen = 0;
    if (!a) { perror(arch); return 1; }
    if (n < 8 || memcmp(a, "!<arch>\n", 8)) { fprintf(stderr, "ar370: %s: not an archive\n", arch); free(a); return 1; }
    for (q = 8; q + 60 <= n; ) {                   /* find "/" and "//" first */
        long size = atol((const char *)a + q + 48);
        if (a[q] == '/' && a[q + 1] == ' ') symtab = a + q + 60;
        else if (a[q] == '/' && a[q + 1] == '/') { ln = a + q + 60; lnlen = size; }
        q += 60 + size + (size & 1);
    }
    printf("members:\n");
    while (p + 60 <= n) {
        long size = atol((const char *)a + p + 48);
        if (a[p] != '/' || (a[p + 1] >= '0' && a[p + 1] <= '9')) {
            char name[MEMBER_NAME_MAX + 1];
            member_name(a + p, ln, lnlen, name, sizeof name);
            printf("  %-16s %ld bytes\n", name, size);
        }
        p += 60 + size + (size & 1);
    }
    if (symtab) {
        unsigned long cnt = ((unsigned long)symtab[0] << 24) | ((unsigned long)symtab[1] << 16) | ((unsigned long)symtab[2] << 8) | symtab[3], s;
        const char *names = (const char *)(symtab + 4 + 4 * cnt);
        printf("symbol table: %lu symbol(s)\n", cnt);
        for (s = 0; s < cnt; s++) {
            const unsigned char *o4 = symtab + 4 + 4 * s;
            long mo = ((long)o4[0] << 24) | ((long)o4[1] << 16) | ((long)o4[2] << 8) | o4[3];
            char name[MEMBER_NAME_MAX + 1] = "?";
            if (mo >= 8 && mo + 60 <= n) member_name(a + mo, ln, lnlen, name, sizeof name);
            printf("  %-8s  %s\n", names, name);
            names += strlen(names) + 1;
        }
    }
    free(a);
    return 0;
}

static void usage(FILE *f)
{
    fprintf(f, "usage: ar370 rc ARCHIVE.a OBJ...   (re)create ARCHIVE.a from the object decks,\n"
               "                                    with a symbol table; an existing archive\n"
               "                                    is replaced, not added to\n"
               "       ar370 t  ARCHIVE.a           list the members and which defines each symbol\n"
               "       ar370 --version | -V         toolchain version + commit\n"
               "       ar370 --help | -h            this text\n"
               "The operation is r, c, rc or cr (create) or t (list), optionally after a '-'.\n");
}

int main(int argc, char **argv)
{
    const char *op;
    if (argc >= 2 && (!strcmp(argv[1], "--version") || !strcmp(argv[1], "-V"))) {
        printf("ar370 %s (%s)\n", CC370_VERSION, CC370_COMMIT); return 0;
    }
    if (argc >= 2 && (!strcmp(argv[1], "--help") || !strcmp(argv[1], "-h"))) { usage(stdout); return 0; }
    if (argc < 3) { usage(stderr); return 2; }
    /* The operation is matched whole.  It was matched letter by letter, so
     * `ar370 --version x' -- which contains an r -- created an empty archive
     * named x at rc 0 (#805). */
    op = argv[1];
    if (*op == '-') op++;
    if (!strcmp(op, "t")) return list(argv[2]);
    if (!strcmp(op, "r") || !strcmp(op, "c") || !strcmp(op, "rc") || !strcmp(op, "cr"))
        return create(argv[2], argc, argv, 3);
    fprintf(stderr, "ar370: unknown operation '%s' (r, c, rc, cr or t)\n", argv[1]);
    return 2;
}
