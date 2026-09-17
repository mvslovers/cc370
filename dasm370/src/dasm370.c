/* dasm370 -- disassemble one CSECT of an OS/360 object deck back into
 * assembler source that as370 can assemble again (cc370#381, stage 1 of #112).
 *
 * THE DECODER IS THE ASSEMBLER'S OWN TABLE, INVERTED.  as370/include/opc_table.h
 * is included here, not copied: a decoder built from a second copy of that data
 * can drift from the encoder silently -- it would still assemble, still compare,
 * and disagree about an instruction neither tool reports on.  #374 made the
 * table invertible for this (`opw' says how many bytes an opcode is, `dec' says
 * which mnemonic to print when several claim one encoding) and #387 moved the SS
 * operand shape in beside it.  This file is the third consumer of that header.
 *
 * It is also the licensing constraint, and it is not only paperwork: the
 * Waterloo `dasm370.c' in circulation reserves all rights and cannot seed a tool
 * we intend to publish.  Inverting our own table is the clean route AND the one
 * that makes the round trip mean something, because the two directions then
 * agree by construction.  Nothing here was read from that source.
 *
 * NOTHING IS EMITTED THAT DOES NOT REPRODUCE ITS OWN BYTES.  Every instruction
 * is decoded, re-encoded from the decoded fields, and compared against the bytes
 * it came from; a mismatch falls back to `DC X'..''.  So the output assembles to
 * the input by construction rather than by hope, and the round trip
 * `dasm370 -> as370 -> cmplmd370' tests the CLAIM that it does, which is a
 * different thing and worth running.
 *
 * WHAT THE ROUND TRIP CANNOT SEE, and why this file says so out loud: a byte
 * decoded as the wrong instruction that re-encodes to the same bytes passes it.
 * Exit 0 proves fidelity to the member, not correctness of the reading.  That is
 * why the acceptance runs against 30 CSECTs whose source we already have before
 * the 66 that have none.
 */
#include <ctype.h>
#include <errno.h>
#include <sys/stat.h>
#include <unistd.h>
#include <sys/wait.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "mvs370.h"
#include "obj370.h"
#include "opc_table.h"

#define DASM_NAME "dasm370"
#define DASM_VER  "V1.0"

#define MAXSECT_BYTES (1024L * 1024L)
#define MAXRLD 8192
#define MAXESD 4096

struct rlditem { long addr; int len; int r; };

/* C has no nested functions, so the two obj370 walkers hand their items to these
 * and the caller reads what they collected. */
struct esd_item { int id; long addr; long len; int type; char name[9]; };
struct esd_collect { int n; struct esd_item it[8]; };
static int dasm_esd_cb(const struct obj_esd *e, void *ctx);
static int dasm_rld_cb(const struct obj_rld *r, void *ctx);

/* Buffer sizes, argued rather than tried: the Mac cannot see the
 * fortify-dependent warnings CI's Linux gcc raises, so every snprintf below has
 * to close on paper.  A label is at most LABBUF-1 = 23 (prefix 2 + %06lX, which
 * gcc must assume is 16); a symbol expression adds "+X'" + %lX + "'" = 20, so
 * SYMBUF 48 holds it; an address adds "(" + %d + ")" = 13, so ADRBUF 64 holds
 * that; and the widest operand is "%s,%s,%d" = 63+1+63+1+11+1 = 140, so
 * OPNDBUF 192 holds the lot. */
#define LABBUF 24
#define SYMBUF 48
#define ADRBUF 64
#define OPNDBUF 192

static unsigned char img[MAXSECT_BYTES];      /* the section's text */
static unsigned char cov[MAXSECT_BYTES];      /* 1 = a TXT card covered it */
static unsigned char lab[MAXSECT_BYTES];      /* 1 = something names this offset */
static unsigned char stbrk[MAXSECT_BYTES];    /* 1 = a statement must start here */
static struct rlditem rld[MAXRLD];
static int nrld;
static char esdname[MAXESD][9];               /* ESDID -> name, for V-cons */
static int  esdtype[MAXESD];

/* An LD is an ENTRY: a name the module exports at an offset inside a section.
 * It carries no ESDID of its own -- its `len' field is the owning section's id
 * and its `addr' the offset within it (obj370.h says so, and the RLD's R and P
 * are numbered on that basis).  Without these the ESD comes back one entry
 * short, which no comparison of TEXT can see: tests/ref/ldentry.obj round-trips
 * byte-identically in its text and differs in its ESD, and that is the whole
 * reason the acceptance compares decks and not section bytes. */
struct lditem { long addr; int owner; char name[9]; };
static struct lditem ld[256];
static int nld;

static int  end_has_entry;                    /* the END card names one, and in OUR section */
static long end_entry;
/* THE SECTION'S ORIGIN IN THE SPACE ITS INPUT NUMBERS IN, and both inputs number
 * in the same one: a bound member's CESD origin and a DECK's ESD SD address are
 * each module-absolute.  This used to be documented as "0 for a deck", and it
 * was 0 because nothing set it -- so every address a deck files under a section
 * at a non-zero origin was read as an offset into that section (cc370#415).
 * Measured over the 5,528-deck corpus: 503 of 6,366 SD/PC sections, in 309
 * modules, and in all 438 of those carrying TXT the lowest TXT address is at or
 * above the ESD address, never below it. */
static long sect_org;
static int  from_member;
static int  scanning;                         /* pass one: decode, record, write nothing */
static int  collecting;                       /* --align-diff: record statements, write nothing */
static int  lab_changed;                      /* pass one found a branch target that had no label */
static long sect_len;                         /* the ESD-declared length */
static int  sect_esdid;
static char sect_name[9];

/* ---------------------------------------------------------------- names -- */

/* An EBCDIC name as the source spells it.  Trailing blanks go; nothing else is
 * touched, because a name that is not a valid symbol is a fact about the deck
 * and not something to paper over -- it comes out as it is and as370 says so. */
static void name_of(const unsigned char *e, char *out)
{
    int i, n = 8;
    for (i = 0; i < 8; i++) out[i] = (char)mvs_e2a_tab[e[i]];
    while (n > 0 && out[n - 1] == ' ') n--;
    out[n] = 0;
}

/* ---------------------------------------------------------------- hints -- */

/* A hint file says what the bytes cannot: which run is data, what an offset is
 * called, and which register is based on what OVER WHICH RANGE.  It is a TOML
 * subset parsed here -- no dependency, and a deliberately small grammar, so that
 * everything outside it is REFUSED rather than skipped.  A hint that is silently
 * ignored is the worst outcome available: the run looks applied, the output
 * looks plausible, and nothing anywhere reports the difference.
 *
 * The grammar in full:
 *
 *     # comment                to end of line; a blank line is ignored
 *     key = value              at the ROOT, before any table header
 *     [[table]]                begins one element of an array of tables
 *     key = value              belonging to it
 *
 *     value ::= "string" | integer          (decimal, or 0x-prefixed hex)
 *
 * Single-bracket `[table]' is refused so there is exactly one way to write a
 * table.  An unknown table, an unknown key, a key given twice, a missing
 * required key, a value of the wrong kind, and any offset outside the section
 * are each rc 16 naming the line.
 *
 *   ROOT        isa = "s370"    as --isa; the command line wins over the file
 *               prefix = "P"    the manufactured label's prefix, 1-2 characters
 *                               (a name is the prefix plus six hex digits, and
 *                               eight is all a symbol has)
 *   [[label]]   at, name        what the source called this offset
 *   [[data]]    at, len         do not decode this run as instructions
 *   [[fill]]    at, len         one repeated byte, written with a duplication
 *                               factor; refused when the run is not uniform
 *   [[base]]    reg, value, from [, to]
 *                               a base register covering a range of THIS
 *                               section; value is a symbol or an offset, and
 *                               `to' defaults to from + 4096, which is one
 *                               base register's addressing range
 *   [[replace]] at, bytes       patch the text before disassembly
 *   [[verify]]  at, bytes       assert the text before anything is patched
 *               at, date = "mdy" | "julian"
 *
 * BASE AND USING ARE TWO STATEMENTS, NOT ONE, and #112 lists both for a reason
 * that took a third tree to find.  Pospischil's mvs38dasm documents the split in
 * its own control statements, and it is clean: a BASE is a base register
 * covering a range of the CSECT ITSELF -- ordinary addressing, "where am I in my
 * own section" -- while a USING points a register at a DSECT and carries the
 * mapping.  Its BASE also has the lifetime and the `from + 4096' default this
 * one does, because that is one base register's range.  Read for the meaning of
 * a word, not copied: the semantics are theirs, the shape of this file is ours.
 *
 * [[using]] and [[dsect]] therefore parse and are refused as not implemented
 * together: pointing a register at a dummy section needs a symbol table, which
 * is what --derive-hints brings.  `base' at the ROOT is refused too, with the
 * table named -- it is a table here and not a scalar.
 */

/* Sized for a DERIVED file over a real module, not for a hand-written one.
 * --derive-hints writes one anchor per label, so these scale with the module's
 * symbol count rather than with a human's patience: 61 of the caller's 2,292
 * length-differing CSECTs hit the old 512 and 3 hit the old 64 bases, and a
 * module refused for a build constant is one nobody can measure by any other
 * route.  Overflow is still REPORTED either way -- see hint_flush -- because a
 * cap that truncates in silence is as370's usings[32], which lost every further
 * USING in 31 modules without a word. */
#define MAXHLABEL 16384
#define MAXHRANGE 4096
#define MAXHBASE  256
#define MAXHB     64
#define MAXHVR    16384
#define MAXKV     12

struct hlabel { long at; char name[9]; int line; int dropped; };
struct hrange { long at, len; int line; };
struct hbase { int reg; long baseval; char basename[16]; int by_name; long from, to; int line; };
struct hbytes { long at; unsigned char b[MAXHB]; int n; int kind; int line; };
                                       /* kind 0 = literal bytes, 1 = mm/dd/yy, 2 = yy.ddd */
struct uev    { long at; int open; int u; };

static struct hlabel hlab[MAXHLABEL];  static int nhlab;
static struct hrange hdata[MAXHRANGE]; static int nhdata;
static struct hrange hfill[MAXHRANGE]; static int nhfill;
static struct hbase hbas[MAXHBASE];   static int nhbas;
static struct hbytes hver[MAXHVR];     static int nhver;
static struct hbytes hrep[MAXHVR];     static int nhrep;
static struct uev    uevs[2 * MAXHBASE]; static int nuev;
/* A failed anchor is a MEASUREMENT under --anchors=report and an error under
 * --anchors=refuse, and which it is depends on what the file is.  In a
 * hand-written hint file a failed assertion is a mistake and stopping is right.
 * In a derived one applied across the 2,292 length-differing modules the failure
 * IS the result -- it says where our source and IBM's object part company -- and
 * a refusal yields one bit per module where the run exists to collect a number. */
struct afail { long at; int n; unsigned char want[MAXHB]; };
static struct afail afails[MAXHVR]; static int nafail;
static int anchor_report;

/* A note is a refusal that --anchors=report turns into a measurement.
 *
 * report mode used to mean "a failed [[verify]] is recorded rather than fatal",
 * and that was too narrow: measured by the caller over the 2,292, of 634 refused
 * applications 404 were a derived base's range overflowing a SHORTER section --
 * which is the population's defining property, not an error -- and 158 were the
 * label collision detector firing, which is a divergence report with both
 * offsets in it.  562 of 634 were measurements being refused instead of
 * reported.  So under report EVERY detector reports: the run continues and the
 * finding comes out as a comment, at its offset where it has one. */
struct hnote { long at; int has_at; char text[220]; };
static struct hnote hnotes[MAXHVR]; static int nhnote;
static int herr(int line, const char *msg);            /* defined with the parser */

static void hnote_add(long at, int has_at, const char *text)
{
    if (nhnote >= MAXHVR) return;
    hnotes[nhnote].at = at; hnotes[nhnote].has_at = has_at;
    snprintf(hnotes[nhnote].text, sizeof hnotes[0].text, "%.200s", text);
    nhnote++;
}

/* Refuse, or record and carry on.  One place, so a detector added later cannot
 * forget to honour the mode. */
static int hrefuse(int line, const char *msg, long at, int has_at)
{
    if (!anchor_report) return herr(line, msg);
    hnote_add(at, has_at, msg);
    return 0;
}
static char  hprefix[4] = "L";
static char  hisa[8];
static const char *hfile;
/* One message buffer, and it is generously sized ON PURPOSE.  gcc cannot prove
 * that a char array inside a struct stops at its own end, so a %s of hkvs[i].k
 * reads to it as "up to 863 bytes" and -Wformat-truncation fires -- on CI's
 * Linux gcc and not on this Mac, which is how #375 landed red.  Every message
 * here is a line or two at run time; the size is what makes the arithmetic
 * close without sprinkling precisions over a dozen formats. */
static char  hmsg[1024];

static int herr(int line, const char *msg)
{
    fprintf(stderr, "dasm370: %s:%d: %s\n", hfile, line, msg);
    return 16;
}

/* ------------------------------------------------------------ the parse -- */

struct hval { int isstr; char s[32]; long i; };
struct hkv  { char k[16]; struct hval v; int line; };
static struct hkv hkvs[MAXKV]; static int nhkv;

static char *htrim(char *s)
{
    char *e;
    while (*s == ' ' || *s == '\t') s++;
    e = s + strlen(s);
    while (e > s && (e[-1] == ' ' || e[-1] == '\t')) e--;
    *e = 0;
    return s;
}

static int hval_parse(const char *t, struct hval *v)
{
    size_t n = strlen(t);
    memset(v, 0, sizeof *v);
    if (!n) return 0;
    if (t[0] == '"') {
        if (n < 2 || t[n - 1] != '"') return 0;
        if (n - 2 >= sizeof v->s) return 0;
        memcpy(v->s, t + 1, n - 2);
        v->s[n - 2] = 0;
        /* No escapes: a symbol never needs one, and a backslash accepted here
         * would be a second spelling of a name that has to compare equal. */
        if (strchr(v->s, '"') || strchr(v->s, '\\')) return 0;
        v->isstr = 1;
        return 1;
    }
    {
        char *e;
        long x;
        errno = 0;
        x = strtol(t, &e, 0);
        if (*e || errno) return 0;
        v->i = x;
        return 1;
    }
}

static int hexparse(const char *t, unsigned char *b, int max, int *n)
{
    int i, L = (int)strlen(t);
    if (L == 0 || L % 2 || L / 2 > max) return 0;
    for (i = 0; i < L; i++) if (!isxdigit((unsigned char)t[i])) return 0;
    for (i = 0; i < L / 2; i++) {
        char h[3];
        h[0] = t[2 * i]; h[1] = t[2 * i + 1]; h[2] = 0;
        b[i] = (unsigned char)strtol(h, NULL, 16);
    }
    *n = L / 2;
    return 1;
}

static struct hkv *kv(const char *k)
{
    int i;
    for (i = 0; i < nhkv; i++) if (!strcmp(hkvs[i].k, k)) return &hkvs[i];
    return NULL;
}

static int kv_only(const char *const *ok)
{
    int i, j;
    for (i = 0; i < nhkv; i++) {
        for (j = 0; ok[j]; j++) if (!strcmp(hkvs[i].k, ok[j])) break;
        if (!ok[j]) {
            snprintf(hmsg, sizeof hmsg, "`%s' is not a key of this table", hkvs[i].k);
            return herr(hkvs[i].line, hmsg);
        }
    }
    return 0;
}

static int kv_int(const char *k, long *out, int line)
{
    struct hkv *p = kv(k);
    if (!p) {
        snprintf(hmsg, sizeof hmsg, "`%s' is required here", k);
        return herr(line, hmsg);
    }
    if (p->v.isstr) {
        snprintf(hmsg, sizeof hmsg, "`%s' takes an integer", k);
        return herr(p->line, hmsg);
    }
    *out = p->v.i;
    return 0;
}

static int kv_str(const char *k, char *out, size_t n, int line)
{
    struct hkv *p = kv(k);
    if (!p) {
        snprintf(hmsg, sizeof hmsg, "`%s' is required here", k);
        return herr(line, hmsg);
    }
    if (!p->v.isstr) {
        snprintf(hmsg, sizeof hmsg, "`%s' takes a \"string\"", k);
        return herr(p->line, hmsg);
    }
    if (strlen(p->v.s) >= n) {
        snprintf(hmsg, sizeof hmsg, "`%s' is longer than %d characters", k, (int)n - 1);
        return herr(p->line, hmsg);
    }
    strcpy(out, p->v.s);
    return 0;
}

/* One element is complete: check it and keep it.  Everything that can be
 * decided from the file alone is decided HERE; anything needing the section's
 * bytes waits for hints_verify_patch / hints_bind, which is the only reason
 * this is two stages and not one. */
static int hint_flush(int tab, int line)
{
    static const char *const k_root[]  = { "isa", "prefix", NULL };
    static const char *const k_label[] = { "at", "name", NULL };
    static const char *const k_range[] = { "at", "len", NULL };
    static const char *const k_base[] = { "reg", "value", "from", "to", NULL };
    static const char *const k_rep[]   = { "at", "bytes", NULL };
    static const char *const k_ver[]   = { "at", "bytes", "date", NULL };
    int rc;
    long a, n;

    /* Only the ROOT may be empty.  An empty [[label]] would otherwise be
     * skipped, and skipping is the one thing this format does not do. */
    if (!nhkv && tab == 0) return 0;
    switch (tab) {
    case 0:                                        /* the root */
        if (kv("base"))
            return herr(kv("base")->line,
                        "`base' is a table, not a root key: [[base]] with reg, value, from "
                        "and an optional to");
        if ((rc = kv_only(k_root)) != 0) return rc;
        if (kv("isa")) {
            if ((rc = kv_str("isa", hisa, sizeof hisa, line)) != 0) return rc;
            if (strcmp(hisa, "app") && strcmp(hisa, "s370") && strcmp(hisa, "s360") && strcmp(hisa, "full")) {
                snprintf(hmsg, sizeof hmsg, "isa = \"%s\" is not one of app|s370|s360|full", hisa);
                return herr(kv("isa")->line, hmsg);
            }
        }
        if (kv("prefix")) {
            char p[8];
            if ((rc = kv_str("prefix", p, sizeof p, line)) != 0) return rc;
            /* A name is the prefix plus six hex digits and a symbol holds eight
             * characters, so two is the arithmetic limit and not a taste. */
            if (!p[0] || strlen(p) > 2) return herr(kv("prefix")->line, "prefix is 1 or 2 characters");
            strcpy(hprefix, p);
        }
        return 0;
    case 1:                                        /* [[label]] */
        if ((rc = kv_only(k_label)) != 0) return rc;
        if (nhlab >= MAXHLABEL) return herr(line, "too many [[label]] entries for this build");
        if ((rc = kv_int("at", &a, line)) != 0) return rc;
        if ((rc = kv_str("name", hlab[nhlab].name, sizeof hlab[nhlab].name, line)) != 0) return rc;
        if (!hlab[nhlab].name[0]) return herr(line, "a [[label]] name is empty");
        hlab[nhlab].at = a; hlab[nhlab].line = line; nhlab++;
        return 0;
    case 2:                                        /* [[data]] */
    case 3:                                        /* [[fill]] */
    {
        struct hrange *t = (tab == 2) ? &hdata[nhdata] : &hfill[nhfill];
        if ((rc = kv_only(k_range)) != 0) return rc;
        if ((tab == 2 ? nhdata : nhfill) >= MAXHRANGE) return herr(line, "too many ranges for this build");
        if ((rc = kv_int("at", &a, line)) != 0) return rc;
        if ((rc = kv_int("len", &n, line)) != 0) return rc;
        if (n <= 0) return herr(line, "len must be positive");
        t->at = a; t->len = n; t->line = line;
        if (tab == 2) nhdata++; else nhfill++;
        return 0;
    }
    case 4:                                        /* [[base]] */
    {
        struct hbase *u = &hbas[nhbas];
        struct hkv *b;
        if ((rc = kv_only(k_base)) != 0) return rc;
        if (nhbas >= MAXHBASE) return herr(line, "too many [[base]] entries for this build");
        memset(u, 0, sizeof *u);
        if ((rc = kv_int("reg", &a, line)) != 0) return rc;
        if (a < 0 || a > 15) return herr(line, "reg is 0 through 15");
        u->reg = (int)a;
        if ((rc = kv_int("from", &u->from, line)) != 0) return rc;
        /* The LIFETIME is the point of this table.  #112's argument is that a
         * base register is not "R12 holds X" but "from here until it is dropped,
         * resolve D(12) against X" -- so there is no form without a range.  `to'
         * may be left out because there IS a right default and it is not a
         * guess: one base register addresses 4096 bytes, so that is where it
         * stops on its own.  Clamped to the section in hints_bind, where the
         * length is known -- an omitted `to' is computed, an explicit one is
         * asserted, and only the asserted one is refused for running off the
         * end. */
        if (kv("to")) {
            if ((rc = kv_int("to", &u->to, line)) != 0) return rc;
            if (u->to <= u->from) return herr(line, "to must be greater than from");
        } else u->to = -1;
        if (!(b = kv("value"))) return herr(line, "`value' is required here -- what the register points at");
        if (b->v.isstr) {
            if (strlen(b->v.s) >= sizeof u->basename) return herr(b->line, "value name too long");
            strcpy(u->basename, b->v.s);
            u->by_name = 1;
        } else u->baseval = b->v.i;
        u->line = line;
        nhbas++;
        return 0;
    }
    case 5:                                        /* [[using]] and [[dsect]] */
        return herr(line, "[[using]] and [[dsect]] are not implemented yet: a USING points a register "
                          "at a DSECT, and resolving into a dummy section needs a symbol table, which "
                          "--derive-hints brings (#382).  A base register covering this section is "
                          "[[base]]");
    case 6:                                        /* [[replace]] */
    {
        struct hbytes *r = &hrep[nhrep];
        char t[2 * MAXHB + 1];
        if ((rc = kv_only(k_rep)) != 0) return rc;
        if (nhrep >= MAXHVR) return herr(line, "too many [[replace]] entries for this build");
        memset(r, 0, sizeof *r);
        if ((rc = kv_int("at", &r->at, line)) != 0) return rc;
        if ((rc = kv_str("bytes", t, sizeof t, line)) != 0) return rc;
        if (!hexparse(t, r->b, MAXHB, &r->n)) return herr(line, "bytes is an even number of hex digits");
        r->line = line;
        nhrep++;
        return 0;
    }
    case 7:                                        /* [[verify]] */
    {
        struct hbytes *v = &hver[nhver];
        if ((rc = kv_only(k_ver)) != 0) return rc;
        if (nhver >= MAXHVR) return herr(line, "too many [[verify]] entries for this build");
        memset(v, 0, sizeof *v);
        if ((rc = kv_int("at", &v->at, line)) != 0) return rc;
        if (kv("bytes") && kv("date")) return herr(line, "a [[verify]] takes bytes or date, not both");
        if (kv("bytes")) {
            char t[2 * MAXHB + 1];
            if ((rc = kv_str("bytes", t, sizeof t, line)) != 0) return rc;
            if (!hexparse(t, v->b, MAXHB, &v->n)) return herr(line, "bytes is an even number of hex digits");
            v->kind = 0;
        } else if (kv("date")) {
            char d[16];
            if ((rc = kv_str("date", d, sizeof d, line)) != 0) return rc;
            /* Two shapes, because the corpus holds two: `mm/dd/yy' is what
             * &SYSDATE writes and `yy.ddd' is the Julian form in an eyecatcher.
             * #112 measured that one shape alone is noisy over 430 decks. */
            if (!strcmp(d, "mdy")) v->kind = 1;
            else if (!strcmp(d, "julian")) v->kind = 2;
            else return herr(kv("date")->line, "date is \"mdy\" (mm/dd/yy) or \"julian\" (yy.ddd)");
        } else return herr(line, "a [[verify]] needs bytes or date");
        v->line = line;
        nhver++;
        return 0;
    }
    }
    return 0;
}

static int hints_load(const char *fn)
{
    FILE *f;
    char line[512];
    int ln = 0, tab = 0, tabline = 0, rc = 0;

    hfile = fn;
    if (!(f = fopen(fn, "r"))) { perror(fn); return 16; }
    while (fgets(line, sizeof line, f)) {
        char *s = line, *p;
        ln++;
        if ((p = strchr(s, '\n'))) *p = 0;
        if ((p = strchr(s, '\r'))) *p = 0;
        /* A `#' ends the line -- but only OUTSIDE a quoted string.  `#', `$'
         * and `@' are alphabetic to Assembler XF, so R#SAVE and TCB# are
         * ordinary labels and IBM's own source is full of them.  Stripping from
         * the first `#' anywhere would cut `name = "R#SAVE"' in half, and
         * --derive-hints will write exactly those names out of real source. */
        {
            int q = 0;
            for (p = s; *p; p++) {
                if (*p == '"') q = !q;
                else if (*p == '#' && !q) { *p = 0; break; }
            }
        }
        s = htrim(s);
        if (!*s) continue;
        if (s[0] == '[') {
            size_t n = strlen(s);
            char nm[32];
            if (s[1] != '[') { rc = herr(ln, "a table is written [[name]]; single brackets are not in this subset"); break; }
            if (n < 5 || s[n - 1] != ']' || s[n - 2] != ']') { rc = herr(ln, "a table header ends with ]]"); break; }
            if (n - 4 >= sizeof nm) { rc = herr(ln, "table name too long"); break; }
            memcpy(nm, s + 2, n - 4); nm[n - 4] = 0;
            if ((rc = hint_flush(tab, tabline)) != 0) break;
            nhkv = 0; tabline = ln;
            if      (!strcmp(nm, "label"))   tab = 1;
            else if (!strcmp(nm, "data"))    tab = 2;
            else if (!strcmp(nm, "fill"))    tab = 3;
            else if (!strcmp(nm, "base"))    tab = 4;
            else if (!strcmp(nm, "using"))   tab = 5;
            else if (!strcmp(nm, "dsect"))   tab = 5;
            else if (!strcmp(nm, "replace")) tab = 6;
            else if (!strcmp(nm, "verify"))  tab = 7;
            else {
                snprintf(hmsg, sizeof hmsg, "[[%s]] is not a table of this format "
                         "(label data fill base using dsect replace verify)", nm);
                rc = herr(ln, hmsg);
                break;
            }
            continue;
        }
        if (!(p = strchr(s, '='))) { rc = herr(ln, "not a comment, a table header or `key = value'"); break; }
        *p = 0;
        {
            char *kk = htrim(s), *vv = htrim(p + 1);
            struct hval v;
            if (!*kk || strlen(kk) >= sizeof hkvs[0].k) { rc = herr(ln, "the key is empty or too long"); break; }
            if (kv(kk)) {
                snprintf(hmsg, sizeof hmsg, "`%s' is given twice in this table", kk);
                rc = herr(ln, hmsg);
                break;
            }
            if (!hval_parse(vv, &v)) { rc = herr(ln, "a value is \"a string\" or an integer (decimal or 0x...)"); break; }
            if (nhkv >= MAXKV) { rc = herr(ln, "too many keys in one table"); break; }
            strcpy(hkvs[nhkv].k, kk); hkvs[nhkv].v = v; hkvs[nhkv].line = ln; nhkv++;
        }
    }
    if (!rc) rc = hint_flush(tab, tabline);
    fclose(f);
    return rc;
}


/* A dropped label is one the module's own ESD contradicted, and it must not be
 * reachable from here either: clearing lab[] alone left the name still findable,
 * so the disassembly carried it at BOTH offsets -- the module's and the hint's --
 * which is the duplicate symbol the collision detector exists to prevent,
 * reintroduced by the detector's own report path. */
static const char *hlab_name(long a)
{
    int i;
    for (i = 0; i < nhlab; i++) if (hlab[i].at == a && !hlab[i].dropped) return hlab[i].name;
    return NULL;
}

static long hfill_at(long a)
{
    int i;
    for (i = 0; i < nhfill; i++) if (hfill[i].at == a) return hfill[i].len;
    return 0;
}

static int hin_data(long a)
{
    int i;
    for (i = 0; i < nhdata; i++) if (a >= hdata[i].at && a < hdata[i].at + hdata[i].len) return 1;
    return 0;
}

static int hnote_cmp(const void *x, const void *y)
{
    const struct hnote *p = x, *q = y;
    return p->at < q->at ? -1 : p->at > q->at ? 1 : 0;
}

static int afail_cmp(const void *x, const void *y)
{
    const struct afail *p = x, *q = y;
    return p->at < q->at ? -1 : p->at > q->at ? 1 : 0;
}

static int uev_cmp(const void *x, const void *y)
{
    const struct uev *p = x, *q = y;
    if (p->at != q->at) return p->at < q->at ? -1 : 1;
    return p->open - q->open;                  /* a DROP before a USING at one offset */
}
/* --------------------------------------------------------------- output -- */

static FILE *outf;
static long seq = 100;                        /* sequence numbers 73-80, by 100 */
static int  card_format = 1;
static long nline;

/* One statement.  In card format the content lives in columns 1-71, column 72
 * stays blank -- it is the continuation column, and a card that reaches it eats
 * the NEXT card, statement and all, at severity 4.  That is measured, it is
 * silent, and it is why the operand is truncated here rather than wrapped: a
 * wrapped continuation would be a second guess about a line we already could not
 * fit.  Nothing this emits is long enough to hit it; the guard is for the day
 * something is. */
static void emit(const char *label, const char *op, const char *opnd, const char *rem)
{
    char line[256];
    int n;
    /* Pass one exists only to find branch targets under a hint USING, so it
     * must not advance the sequence number or write a card.  One walk in two
     * modes rather than two walks: a second copy of the decode loop would drift
     * from this one exactly the way a second copy of the opcode table would. */
    if (scanning || collecting) return;
    memset(line, ' ', sizeof line);
    if (label && *label) { n = (int)strlen(label); memcpy(line, label, (size_t)(n > 8 ? 8 : n)); }
    if (op && *op)       { n = (int)strlen(op);    memcpy(line + 9, op, (size_t)(n > 5 ? 5 : n)); }
    if (opnd && *opnd) {
        n = (int)strlen(opnd);
        if (n > 55) n = 55;                   /* columns 16..70 */
        memcpy(line + 15, opnd, (size_t)n);
    }
    if (rem && *rem) {
        int at = 15 + (opnd && *opnd ? (int)strlen(opnd) + 2 : 0);
        if (at < 40) at = 40;
        n = (int)strlen(rem);
        if (at + n > 71) n = 71 - at;
        if (n > 0) memcpy(line + at, rem, (size_t)n);
    }
    if (card_format) {
        char s[16];
        sprintf(s, "%08ld", seq);
        memcpy(line + 72, s, 8);
        fwrite(line, 1, 80, outf);
        fputc('\n', outf);
        seq += 100;
    } else {
        int e = 71;
        while (e > 0 && line[e - 1] == ' ') e--;
        fwrite(line, 1, (size_t)e, outf);
        fputc('\n', outf);
    }
    nline++;
}

/* A comment card: `*' in column 1, and in card format still exactly 80 columns
 * with the sequence number in 73-80 and column 72 blank.  A comment that reached
 * column 72 would eat the next card exactly as a statement does. */
static void emit_comment(const char *text)
{
    char line[256];
    int n;
    if (scanning || collecting) return;
    /* WRAPPED, not truncated.  These carry divergence reports with two offsets
     * in them and are read by the hundred over a corpus; a note cut at column 71
     * is a note whose second offset is gone.  Broken at a blank where there is
     * one, so a hex number is never split. */
    n = (int)strlen(text);
    if (n > 69) {
        int cut = 69;
        while (cut > 40 && text[cut] != ' ') cut--;
        if (text[cut] != ' ') cut = 69;
        { char head[80];
          memcpy(head, text, (size_t)cut); head[cut] = 0;
          emit_comment(head); }
        while (text[cut] == ' ') cut++;
        emit_comment(text + cut);
        return;
    }
    memset(line, ' ', sizeof line);
    line[0] = '*';
    memcpy(line + 2, text, (size_t)n);
    if (card_format) {
        char sq[16];
        sprintf(sq, "%08ld", seq);
        memcpy(line + 72, sq, 8);
        fwrite(line, 1, 80, outf);
        fputc('\n', outf);
        seq += 100;
    } else {
        int e = 71;
        while (e > 0 && line[e - 1] == ' ') e--;
        fwrite(line, 1, (size_t)e, outf);
        fputc('\n', outf);
    }
    nline++;
}

/* A name the module already has beats one we invent: an ENTRY's own name is
 * what the source called that address, and it is the one label here that is
 * recovered rather than manufactured.  A [[label]] hint outranks even that --
 * it is the reader stating what the source called the offset, which is the
 * whole reason the file exists; an ENTRY name is the module's own and is right
 * where no hint disagrees.  The manufactured form is last, and `prefix' is what
 * keeps two disassemblies in one assembly from colliding.
 *
 * `out' is LABBUF bytes: the prefix is at most 2 and %06lX at most 16, so the
 * arithmetic closes without the caller having to think about it. */
/* SEQUENTIAL LABELS (#396), and the reason is not cosmetic.  A name derived
 * from a displacement -- L0000A4 for offset X'A4' -- is WRONG THE MOMENT ANYONE
 * INSERTS A STATEMENT: the label still reads L0000A4 and now points at X'B2'.
 * And it still assembles.  No diagnostic, no failing test, no moved byte, so it
 * is invisible to the round trip, to cmplmd370, to reachgate.py and to
 * --align-diff -- every instrument this project has reports success on it.
 *
 * Inserting statements is not hypothetical for the caller; it IS the repair
 * workflow, and every repair shifts every displacement after it.  So the failure
 * is: disassemble, deposit, repair, and every generated label in the file names
 * an address it does not occupy -- silently, permanently, in a file nobody will
 * re-derive because it is checked in.
 *
 * The numbering is assigned ONCE, after the labels have settled.  A hint USING
 * can plant new branch targets across up to eight scanning passes, so numbering
 * earlier would renumber under the caller and produce two different names for
 * one offset in one run. */
static long *labord;                          /* labelled offsets, ascending */
static long  nlabord;
static int   label_seq;                       /* #396: number them, do not name them */

static void label_order(void)
{
    long a;
    free(labord); labord = NULL; nlabord = 0;
    if (!label_seq) return;
    labord = malloc((size_t)(sect_len ? sect_len : 1) * sizeof *labord);
    if (!labord) { fprintf(stderr, "dasm370: out of memory numbering labels\n"); exit(16); }
    for (a = 0; a < sect_len; a++) if (lab[a]) labord[nlabord++] = a;
}

static void label_name(long a, char *out)
{
    const char *h;
    int i;
    if ((h = hlab_name(a)) != NULL) { strcpy(out, h); return; }
    for (i = 0; i < nld; i++)
        if (ld[i].addr == a) { strcpy(out, ld[i].name); return; }
    if (label_seq) {
        long lo = 0, hi = nlabord - 1;
        while (lo <= hi) {                    /* the offset's ordinal among the labels */
            long m = (lo + hi) / 2;
            if (labord[m] == a) { snprintf(out, LABBUF, "%s%04ld", hprefix, (m + 1) * 10); return; }
            if (labord[m] < a) lo = m + 1; else hi = m - 1;
        }
        /* An offset nothing marked cannot be numbered, and inventing one here
         * would hand back a name that collides with a real label's.  The
         * displacement form is at least unambiguous about what it means. */
    }
    snprintf(out, LABBUF, "%s%06lX", hprefix, (unsigned long)a);
}

/* ------------------------------------------------------------- decoding -- */

/* The hint USING in force for register `r' at offset `a', or NULL.  There is at
 * most one: two live USINGs on one register is refused when the file is read. */
static const struct hbase *base_at(long a, int r)
{
    int i;
    for (i = 0; i < nhbas; i++)
        if (hbas[i].reg == r && a >= hbas[i].from && a < hbas[i].to) return &hbas[i];
    return NULL;
}

/* Which register as370 would pick for `target' at offset `a'.  This reproduces
 * using_for() (as370.c:1040): the smallest displacement still in range, and on a
 * tie the HIGHER register.
 *
 * It is the whole safety argument for writing a symbol instead of D(B).  The
 * bytes name a base register; a symbol names an address and lets the assembler
 * choose one back.  Where two hint USINGs cover the same target the assembler
 * may well choose the OTHER one, and then the reassembled deck differs -- in a
 * displacement, in the middle of an instruction that still looks right.  The
 * round trip does catch that, but only for a case some fixture happens to hold,
 * so it is decided here by arithmetic and the fixture merely confirms it. */
static int as370_base_for(long a, long target)
{
    int i, best = -1;
    long bd = 0;
    for (i = 0; i < nhbas; i++) {
        long dd;
        if (a < hbas[i].from || a >= hbas[i].to) continue;
        dd = target - hbas[i].baseval;
        if (dd < 0 || dd >= 4096) continue;
        if (best < 0 || dd < bd || (dd == bd && hbas[i].reg > hbas[best].reg)) { best = i; bd = dd; }
    }
    return best < 0 ? -1 : hbas[best].reg;
}

/* D(B) as a symbol, when a hint USING makes that safe.  0 leaves the numeric
 * form alone, which is the answer whenever anything at all is uncertain -- an
 * unresolved 4(,12) costs a reader one lookup, and a confident wrong symbol is
 * believed and propagates (#112). */
static int sym_disp(long a, int d, int b, char *out, size_t n)
{
    const struct hbase *u;
    long target, L;
    char nm[LABBUF];
    if (!nhbas || b == 0) return 0;
    if (!(u = base_at(a, b))) return 0;
    target = u->baseval + d;
    if (target < 0 || target >= sect_len) return 0;       /* outside: not ours to name */
    if (as370_base_for(a, target) != b) return 0;
    for (L = target; L > 0 && !lab[L]; L--) ;
    if (!lab[L]) return 0;                                /* lab[0] is always set; belt and braces */
    label_name(L, nm);
    if (L == target) snprintf(out, n, "%s", nm);
    else snprintf(out, n, "%s+X'%lX'", nm, (unsigned long)(target - L));
    return 1;
}

/* The three address shapes an operand can take.  An index register survives
 * either spelling: `LOOP(3)' is the same address as `4(3,12)' and reads as one.
 * `out' is ADRBUF; see the note beside the buffer sizes for why that closes. */
static void addr_x(long a, int d, int x, int b, char *out, size_t n)
{
    char t[SYMBUF];
    if (sym_disp(a, d, b, t, sizeof t)) {
        if (x) snprintf(out, n, "%s(%d)", t, x);
        else   snprintf(out, n, "%s", t);
    } else snprintf(out, n, "%d(%d,%d)", d, x, b);
}

static void addr_b(long a, int d, int b, char *out, size_t n)
{
    char t[SYMBUF];
    if (sym_disp(a, d, b, t, sizeof t)) snprintf(out, n, "%s", t);
    else snprintf(out, n, "%d(%d)", d, b);
}

static void addr_l(long a, int d, int l, int b, char *out, size_t n)
{
    char t[SYMBUF];
    if (sym_disp(a, d, b, t, sizeof t)) snprintf(out, n, "%s(%d)", t, l);
    else snprintf(out, n, "%d(%d,%d)", d, l, b);
}

/* The entry that decodes a byte pattern: the PRIMARY one for this opcode, and
 * for a branch pseudo the PRIMARY one for this mask.  OPD_NEVER is skipped --
 * X'84'/X'85' are WRD/RDD on System/370 and BRXH/BRXLE on ESA/390, and a module
 * this old cannot hold the second reading.  When no PRIMARY claims the mask, the
 * generic BC/BCR (OPD_ALIAS) is what is left, which is the whole reason they
 * carry that value. */
static const struct opc *find_op(int b0, int b1, int mask, int *is_mask_form)
{
    const struct opc *alias = NULL;
    int i;
    for (i = 0; optab[i].name; i++) {
        const struct opc *o = &optab[i];
        int code = (o->opw == 2) ? ((o->fmt == F_S || o->fmt == F_S0) ? o->op : -1)
                                 : ((o->fmt == F_S || o->fmt == F_S0) ? ((o->op >> 8) & 0xff) : o->op);
        int want = (o->opw == 2) ? ((b0 << 8) | b1) : b0;
        if (code != want) continue;
        if (o->dec == OPD_NEVER) continue;
        if (o->fmt == F_BC || o->fmt == F_BR) {
            if (o->m1 != mask) continue;
            if (o->dec == OPD_PRIMARY) { *is_mask_form = 1; return o; }
            continue;
        }
        if (o->dec == OPD_PRIMARY) { *is_mask_form = 0; return o; }
        if (!alias) alias = o;
    }
    if (alias) { *is_mask_form = 0; return alias; }
    return NULL;
}

static int ins_len_of(int fmt)
{
    return (fmt == F_RR || fmt == F_BR || fmt == F_SVC) ? 2 : (fmt == F_SS) ? 6 : 4;
}

/* Re-encode what we decoded and compare it with what we read.  A decoder that
 * cannot reproduce its own input has misread it, and the honest answer is DC.
 * This is what makes the round trip pass by construction; running it anyway is
 * how we learn that the construction is right. */
static int reencode_ok(const struct opc *o, const unsigned char *b, int len)
{
    unsigned char t[6];
    int i;
    memcpy(t, b, (size_t)len);
    if (o->opw == 2) { t[0] = (unsigned char)((o->op >> 8) & 0xff); t[1] = (unsigned char)(o->op & 0xff); }
    else if (o->fmt == F_S || o->fmt == F_S0) {
        /* BOTH bytes.  The encoder writes `op' as a big-endian halfword, so a
         * one-byte S opcode is spelled <op>00 and the 00 is emitted -- byte 1 is
         * part of the instruction and not a field.  Checking only byte 0 let
         * IEAVTCR1's `80 16 41 70' come back as `SSM 368(4)', which re-encodes
         * to `80 00 41 70': one byte lost, silently, and the round trip saw a
         * text difference rather than the decode that caused it. */
        t[0] = (unsigned char)((o->op >> 8) & 0xff);
        t[1] = (unsigned char)(o->op & 0xff);
    }
    else t[0] = (unsigned char)(o->op & 0xff);
    /* AN F_S0 HAS NO OPERAND, so bytes 2-3 are not a field either: what this
     * pass emits is the bare mnemonic, and as370 assembles that to <op>0000.
     * Leaving the bytes as read made the check compare the input with itself and
     * pass on any tail at all.
     *
     * IFOX51's IFNX5M00 carries `B20D 28B2' at 000A1A -- a PTLB whose
     * hardware-ignored halfword is not zero.  It came back as `PTLB', which
     * reassembles to `B20D 0000': two bytes lost silently, and that module was
     * the ONE of 599 whose round trip caught anything at all.
     *
     * The same defect as the note above, two bytes further out: THE COMPARISON
     * MUST BE AGAINST WHAT THE STATEMENT ASSEMBLES TO and never against the
     * bytes it was read from.  Written outside the branches above because an
     * F_S0's opcode is two bytes wide, so `opw == 2' claims it first and a guard
     * inside the F_S/F_S0 arm never runs -- which is how the first version of
     * this fix changed nothing and said nothing. */
    if (o->fmt == F_S0 && len >= 4) { t[2] = 0; t[3] = 0; }
    if (o->fmt == F_BC) t[1] = (unsigned char)((o->m1 << 4) | (b[1] & 0x0f));
    if (o->fmt == F_BR) t[1] = (unsigned char)((o->m1 << 4) | (b[1] & 0x0f));
    for (i = 0; i < len; i++) if (t[i] != b[i]) return 0;
    return 1;
}

/* Operand text for one instruction.  Returns 0 when the shape is one this pass
 * does not write, which sends the bytes to DC rather than to a guess.
 *
 * `a' is the instruction's offset, and it is here for one reason: a hint USING
 * has a LIFETIME, so whether D(B) may be written as a symbol depends on WHERE
 * the instruction is and not only on what it says. */
static int operands(const struct opc *o, const unsigned char *b, long a, char *out, size_t n)
{
    int r1 = (b[1] >> 4) & 0xf, r2 = b[1] & 0xf;
    int x2, b2, d2, b1, d1, l1, l2;
    char t1[ADRBUF], t2[ADRBUF];
    switch (o->fmt) {
    case F_RR:
        snprintf(out, n, "%d,%d", r1, r2);
        return 1;
    case F_BR:
        snprintf(out, n, "%d", r2);
        return 1;
    case F_SVC:
        snprintf(out, n, "%d", b[1]);
        return 1;
    case F_RX:
        x2 = r2; b2 = (b[2] >> 4) & 0xf; d2 = ((b[2] & 0xf) << 8) | b[3];
        addr_x(a, d2, x2, b2, t1, sizeof t1);
        snprintf(out, n, "%d,%s", r1, t1);
        return 1;
    case F_BC:
        x2 = r2; b2 = (b[2] >> 4) & 0xf; d2 = ((b[2] & 0xf) << 8) | b[3];
        addr_x(a, d2, x2, b2, t1, sizeof t1);
        snprintf(out, n, "%s", t1);
        return 1;
    case F_RS:
        b2 = (b[2] >> 4) & 0xf; d2 = ((b[2] & 0xf) << 8) | b[3];
        addr_b(a, d2, b2, t1, sizeof t1);
        /* R3 == 0 is the shift shape, `R1,D2(B2)'.  Writing the three-operand
         * form there would depend on as370 accepting an explicit zero where the
         * language expects two operands; the two-operand form is what the source
         * was and re-encodes to the same nibble either way. */
        if (r2 == 0) snprintf(out, n, "%d,%s", r1, t1);
        else         snprintf(out, n, "%d,%d,%s", r1, r2, t1);
        return 1;
    case F_SI:
        b1 = (b[2] >> 4) & 0xf; d1 = ((b[2] & 0xf) << 8) | b[3];
        addr_b(a, d1, b1, t1, sizeof t1);
        snprintf(out, n, "%s,%d", t1, b[1]);
        return 1;
    case F_S:
        b2 = (b[2] >> 4) & 0xf; d2 = ((b[2] & 0xf) << 8) | b[3];
        addr_b(a, d2, b2, t1, sizeof t1);
        snprintf(out, n, "%s", t1);
        return 1;
    case F_S0:
        out[0] = 0;
        return 1;
    case F_SS:
        b1 = (b[2] >> 4) & 0xf; d1 = ((b[2] & 0xf) << 8) | b[3];
        b2 = (b[4] >> 4) & 0xf; d2 = ((b[4] & 0xf) << 8) | b[5];
        if (opc_ss_srp(o->op)) {
            /* The rounding digit is a DECIMAL digit and the assembler says so.
             * A byte pair whose low nibble is X'A'..X'F' is not an SRP however
             * well it re-encodes -- BLSRENQK has one at X'A8C' and it came back
             * as `SRP 198(5,4),1753(13),11', which as370 flags.  Re-encoding is
             * necessary and not sufficient: the operand has to be writable. */
            if ((b[1] & 0xf) > 9) return 0;
            /* One length in the HIGH nibble and the rounding digit in the low
             * one.  Reading this as a single-length SS is cc370#64 in the other
             * direction: the length would come back as the rounding digit. */
            l1 = ((b[1] >> 4) & 0xf) + 1;
            addr_l(a, d1, l1, b1, t1, sizeof t1);
            addr_b(a, d2, b2, t2, sizeof t2);
            snprintf(out, n, "%s,%s,%d", t1, t2, b[1] & 0xf);
        } else if (opc_ss_two_length(o->op)) {
            l1 = ((b[1] >> 4) & 0xf) + 1;
            l2 = (b[1] & 0xf) + 1;
            addr_l(a, d1, l1, b1, t1, sizeof t1);
            addr_l(a, d2, l2, b2, t2, sizeof t2);
            snprintf(out, n, "%s,%s", t1, t2);
        } else {
            l1 = b[1] + 1;
            addr_l(a, d1, l1, b1, t1, sizeof t1);
            addr_b(a, d2, b2, t2, sizeof t2);
            snprintf(out, n, "%s,%s", t1, t2);
        }
        return 1;
    default:
        return 0;
    }
}

/* ---------------------------------------------------------------- input -- */

static const struct rlditem *rld_at(long a)
{
    int i;
    for (i = 0; i < nrld; i++) if (rld[i].addr == a) return &rld[i];
    return NULL;
}

/* Does any relocatable field overlap [a, a+len)?  A byte the RLD names is data,
 * and this is asked BEFORE the decoder runs rather than checked after it: a
 * decoder that decodes first and relocates afterwards has already produced a
 * plausible instruction for every address constant in the module, and neither
 * the round trip nor the bytes will object to it. */
static int rld_overlaps(long a, int len)
{
    int i;
    for (i = 0; i < nrld; i++) {
        long s = rld[i].addr, e = s + rld[i].len;
        if (a < e && s < a + len) return 1;
    }
    return 0;
}

static void hexbytes(const unsigned char *p, int n, char *out)
{
    int i;
    for (i = 0; i < n; i++) sprintf(out + 2 * i, "%02X", p[i]);
    out[2 * n] = 0;
}

/* ------------------------------------------------------- binding to the --
 * ------------------------------------------------------------- section -- */

static int hrange_ok(long at, long len, int line, const char *what)
{
    if (at < 0 || len <= 0 || at + len > sect_len) {
        snprintf(hmsg, sizeof hmsg,
                 "%s at X'%lX' for %ld byte(s) is outside %s, which is X'%lX' bytes",
                 what, (unsigned long)at, len, sect_name, (unsigned long)sect_len);
        return herr(line, hmsg);
    }
    return 0;
}

static int hcovered(long at, long len)
{
    long k;
    for (k = at; k < at + len; k++) if (!cov[k]) return 0;
    return 1;
}

static int hver_len(const struct hbytes *v)
{
    return v->kind == 0 ? v->n : (v->kind == 1 ? 8 : 6);
}

/* VERIFY, then REPLACE, and in that order on the ORIGINAL bytes.  #112 puts the
 * whole safety of REPLACE on VERIFY in one clause, and it only holds this way
 * round: a patch applied to bytes nobody asserted is a patch applied to whatever
 * the module happens to hold, and the disassembly then describes neither the
 * module nor the intent.  Run before the labels are derived, so the derivation
 * sees the image the decoder will. */
static int hints_verify_patch(void)
{
    int i, j, rc;
    for (i = 0; i < nhver; i++) {
        struct hbytes *v = &hver[i];
        int L = hver_len(v);
        /* An anchor past the end of a SHORTER module, or over bytes it never
         * defined, says the module is shorter -- which under report is the
         * measurement and not an error.  Same argument as the clamped base: the
         * population is defined by its sections not matching ours. */
        if (v->at < 0 || L <= 0 || v->at + L > sect_len) {
            snprintf(hmsg, sizeof hmsg,
                     "anchor at X'%lX' is past the end of %s (X'%lX' bytes) -- the module is "
                     "SHORTER than the source these hints came from",
                     (unsigned long)v->at, sect_name, (unsigned long)sect_len);
            if ((rc = hrefuse(v->line, hmsg, 0, 0)) != 0) return rc;
            continue;
        }
        if (!hcovered(v->at, L)) {
            snprintf(hmsg, sizeof hmsg,
                     "anchor at X'%lX' covers bytes no TXT card defined -- there is nothing "
                     "there to assert", (unsigned long)v->at);
            if ((rc = hrefuse(v->line, hmsg, 0, 0)) != 0) return rc;
            continue;
        }
        if (v->kind == 0) {
            if (memcmp(img + v->at, v->b, (size_t)L)) {
                char got[2 * MAXHB + 1], wnt[2 * MAXHB + 1];
                if (anchor_report) {
                    /* Recorded at its offset and the disassembly written anyway.
                     * The FIRST failure bounds the divergence: everything before
                     * it held, so the hint set is good up to there. */
                    if (nafail < MAXHVR) {
                        afails[nafail].at = v->at; afails[nafail].n = L;
                        memcpy(afails[nafail].want, v->b, (size_t)L);
                        nafail++;
                    }
                    continue;
                }
                hexbytes(img + v->at, L, got);
                hexbytes(v->b, L, wnt);
                snprintf(hmsg, sizeof hmsg, "verify failed at X'%lX': the module holds %s, not %s",
                         (unsigned long)v->at, got, wnt);
                return herr(v->line, hmsg);
            }
        } else {
            static const char *const shape[3] = { "", "dd/dd/dd", "dd.ddd" };
            char t[16];
            int k, bad = 0;
            for (k = 0; k < L; k++) t[k] = (char)mvs_e2a_tab[img[v->at + k]];
            t[L] = 0;
            for (k = 0; k < L; k++) {
                char w = shape[v->kind][k];
                if (w == 'd') { if (!isdigit((unsigned char)t[k])) bad = 1; }
                else if (t[k] != w) bad = 1;
            }
            if (bad) {
                char got[2 * MAXHB + 1];
                hexbytes(img + v->at, L, got);
                snprintf(hmsg, sizeof hmsg,
                         "verify failed at X'%lX': `%s' (%s) is not a %s date",
                         (unsigned long)v->at, t, got, v->kind == 1 ? "mm/dd/yy" : "yy.ddd");
                return herr(v->line, hmsg);
            }
        }
    }
    for (i = 0; i < nhrep; i++) {
        struct hbytes *r = &hrep[i];
        if ((rc = hrange_ok(r->at, r->n, r->line, "replace")) != 0) return rc;
        if (!hcovered(r->at, r->n))
            return herr(r->line, "replace covers bytes no TXT card defined -- patching a hole would invent text");
        for (j = 0; j < nhver; j++)
            if (hver[j].at <= r->at && r->at + r->n <= hver[j].at + hver_len(&hver[j])) break;
        if (j == nhver)
            return herr(r->line, "no [[verify]] covers this replace -- an unasserted patch is what makes REPLACE unsafe (#112)");
    }
    for (i = 0; i < nhrep; i++) memcpy(img + hrep[i].at, hrep[i].b, (size_t)hrep[i].n);
    return 0;
}





/* The rest of the file, once lab[] exists: ranges checked against the section,
 * hint labels folded in, the USING bases resolved and their statement
 * boundaries marked. */
static int hints_bind(void)
{
    int i, j, rc;

    for (i = 0; i < nhlab; i++) {
        int skip = 0;
        if (hlab[i].at < 0 || hlab[i].at >= sect_len) {
            snprintf(hmsg, sizeof hmsg,
                     "label `%s' at X'%lX' is past the end of %s (X'%lX' bytes) -- the module "
                     "is SHORTER than the source these hints came from",
                     hlab[i].name, (unsigned long)hlab[i].at, sect_name, (unsigned long)sect_len);
            if ((rc = hrefuse(hlab[i].line, hmsg, 0, 0)) != 0) return rc;
            hlab[i].dropped = 1;
            continue;
        }
        for (j = 0; j < i; j++) {
            if (hlab[j].at == hlab[i].at) return herr(hlab[i].line, "two [[label]] entries name one offset");
            if (!strcmp(hlab[j].name, hlab[i].name)) return herr(hlab[i].line, "two [[label]] entries share a name");
        }
        /* THE MODULE'S OWN NAMES OUTRANK A DERIVED ONE, and disagreeing with
         * them is a finding rather than a nuisance.  An ENTRY in the ESD is
         * IBM's statement about where something IS; a derived [[label]] is our
         * source's statement about where it WAS.  When they name one symbol at
         * two offsets the module has diverged, and that is worth reporting at
         * its offset -- where without this check the two names would both be
         * emitted and as370 would report a duplicate symbol a long way from the
         * cause.
         *
         * Measured by the caller: 409 of the 2,292 length-differing modules
         * carry named offsets at all, about three apiece, so this fires on 18 %
         * of the target population and is silent on the rest.  A complement to
         * the anchors and not a substitute -- but where it does fire it is the
         * better instrument, because an ENTRY name is the module's own. */
        for (j = 0; j < nld; j++)
            if (ld[j].owner == sect_esdid && !strcmp(ld[j].name, hlab[i].name)
                && ld[j].addr != hlab[i].at) {
                snprintf(hmsg, sizeof hmsg,
                         "`%s' is at X'%lX' in this module and X'%lX' in the hint file "
                         "-- the module has diverged from the source these hints came from",
                         hlab[i].name, (unsigned long)ld[j].addr, (unsigned long)hlab[i].at);
                /* Under report this is one of the most useful things the tool
                 * says: the module's own ENTRY names an offset our source does
                 * not, with both numbers.  The hint label is then DROPPED rather
                 * than applied -- the module's own name outranks it, and
                 * emitting both would put one symbol at two offsets. */
                if ((rc = hrefuse(hlab[i].line, hmsg, ld[j].addr, 1)) != 0) return rc;
                skip = 1;
                break;
            }
        if (skip) { hlab[i].dropped = 1; continue; }
        lab[hlab[i].at] = 1;
        stbrk[hlab[i].at] = 1;
    }
    for (i = 0; i < nhdata; i++) {
        if ((rc = hrange_ok(hdata[i].at, hdata[i].len, hdata[i].line, "data")) != 0) return rc;
        stbrk[hdata[i].at] = 1;
        if (hdata[i].at + hdata[i].len < sect_len) stbrk[hdata[i].at + hdata[i].len] = 1;
    }
    for (i = 0; i < nhfill; i++) {
        long at = hfill[i].at, n = hfill[i].len, k;
        if ((rc = hrange_ok(at, n, hfill[i].line, "fill")) != 0) return rc;
        /* Three things make a fill writable, and each is arithmetic rather than
         * a judgement, because a fill that is wrong moves bytes: the run must be
         * covered (a DC over a hole invents text a deck does not carry), it must
         * be uniform (that is what a duplication factor says), and nothing else
         * may claim a byte inside it. */
        if (!hcovered(at, n))
            return herr(hfill[i].line, "fill covers bytes no TXT card defined -- that run is a DS, not a DC");
        for (k = 1; k < n; k++)
            if (img[at + k] != img[at]) {
                snprintf(hmsg, sizeof hmsg, "fill is not uniform: X'%02X' at X'%lX' but X'%02X' at X'%lX'",
                         img[at], (unsigned long)at, img[at + k], (unsigned long)(at + k));
                return herr(hfill[i].line, hmsg);
            }
        if (rld_overlaps(at, n))
            return herr(hfill[i].line, "fill overlaps a relocatable field -- the RLD is ground truth and outranks it");
        for (k = 1; k < n; k++)
            if (lab[at + k]) {
                snprintf(hmsg, sizeof hmsg, "fill would swallow the label at X'%lX'", (unsigned long)(at + k));
                return herr(hfill[i].line, hmsg);
            }
        stbrk[at] = 1;
        if (at + n < sect_len) stbrk[at + n] = 1;
    }
    for (i = 0; i < nhbas; i++) {
        struct hbase *u = &hbas[i];
        /* An omitted `to' becomes from + 4096 -- one base register's reach --
         * and is then clamped to the section, because a computed default that
         * ran off the end would refuse a file nobody wrote wrong. */
        if (u->to < 0) {
            u->to = u->from + 4096;
            if (u->to > sect_len) u->to = sect_len;
        }
        /* A derived base's `to' comes from OUR section; IBM's is a different
         * length, which is what "length-differing" means -- so an overflowing
         * range is the population's defining property and not an error.  It is
         * 404 of the caller's 634 refused applications.  Under report the range
         * is clamped to the section and the clamp is stated; under refuse it
         * stays an error, which is right for a hand-written file. */
        if (u->from < 0 || u->from >= sect_len || u->to > sect_len) {
            snprintf(hmsg, sizeof hmsg, "base from X'%lX' to X'%lX' is outside %s (X'%lX' bytes)",
                     (unsigned long)u->from, (unsigned long)u->to, sect_name, (unsigned long)sect_len);
            if (u->from < 0 || u->from >= sect_len) {
                if ((rc = hrefuse(u->line, hmsg, 0, 0)) != 0) return rc;
                continue;                       /* nothing to clamp to: it begins outside */
            }
            if (!anchor_report) return herr(u->line, hmsg);
            snprintf(hmsg, sizeof hmsg,
                     "base reg %d runs to X'%lX' but %s is X'%lX' bytes -- clamped, and the "
                     "section is SHORTER than the source these hints came from",
                     u->reg, (unsigned long)u->to, sect_name, (unsigned long)sect_len);
            hnote_add(0, 0, hmsg);
            u->to = sect_len;
        }
        if (u->by_name) {
            /* A name has to resolve to an OFFSET or nothing below can be
             * arithmetic.  The section itself and any ENTRY it declares are
             * offsets we hold; anything else is a symbol this stage cannot
             * place, and saying so beats resolving it to zero. */
            int found = 0;
            if (!strcmp(u->basename, sect_name)) { u->baseval = 0; found = 1; }
            for (j = 0; !found && j < nld; j++)
                if (ld[j].owner == sect_esdid && !strcmp(ld[j].name, u->basename)) {
                    u->baseval = ld[j].addr; found = 1;
                }
            for (j = 0; !found && j < nhlab; j++)
                if (!strcmp(hlab[j].name, u->basename)) { u->baseval = hlab[j].at; found = 1; }
            if (!found) {
                snprintf(hmsg, sizeof hmsg,
                         "value = \"%s\" is not %s, an ENTRY of it, or a [[label]] in this file",
                         u->basename, sect_name);
                return herr(u->line, hmsg);
            }
        }
        if (u->baseval < 0 || u->baseval >= sect_len) {
            snprintf(hmsg, sizeof hmsg, "value X'%lX' is outside %s (X'%lX' bytes)",
                     (unsigned long)u->baseval, sect_name, (unsigned long)sect_len);
            return herr(u->line, hmsg);
        }
        /* as370 keeps ONE entry per register (as370.c:5020 reuses the slot), so
         * two live bases on one register is a state the assembler cannot be in
         * and a state this file must not describe. */
        for (j = 0; j < i; j++)
            if (hbas[j].reg == u->reg && u->from < hbas[j].to && hbas[j].from < u->to) {
                snprintf(hmsg, sizeof hmsg, "register %d already has a base over this range (line %d)",
                         u->reg, hbas[j].line);
                return herr(u->line, hmsg);
            }
        /* The USING and DROP this emits are statements, so they need statement
         * boundaries.
         * An offset inside a relocatable field or inside a fill run has none --
         * both come out as one statement -- and the event would be emitted late
         * and silently.  Refuse instead. */
        {
            long ends[2]; int e;
            ends[0] = u->from; ends[1] = u->to;
            for (e = 0; e < 2; e++) {
                int k;
                if (ends[e] >= sect_len) continue;
                for (k = 0; k < nrld; k++)
                    if (ends[e] > rld[k].addr && ends[e] < rld[k].addr + rld[k].len) {
                        snprintf(hmsg, sizeof hmsg, "X'%lX' is inside a relocatable field and cannot begin a statement",
                                 (unsigned long)ends[e]);
                        return herr(u->line, hmsg);
                    }
                for (k = 0; k < nhfill; k++)
                    if (ends[e] > hfill[k].at && ends[e] < hfill[k].at + hfill[k].len) {
                        snprintf(hmsg, sizeof hmsg, "X'%lX' is inside the fill at X'%lX' and cannot begin a statement",
                                 (unsigned long)ends[e], (unsigned long)hfill[k].at);
                        return herr(u->line, hmsg);
                    }
                stbrk[ends[e]] = 1;
            }
        }
        lab[u->baseval] = 1;
        stbrk[u->baseval] = 1;
        uevs[nuev].at = u->from; uevs[nuev].open = 1; uevs[nuev].u = i; nuev++;
        uevs[nuev].at = u->to;   uevs[nuev].open = 0; uevs[nuev].u = i; nuev++;
    }
    qsort(uevs, (size_t)nuev, sizeof uevs[0], uev_cmp);
    return 0;
}

/* ----------------------------------------------------------------- emit -- */

static void emit_dc_hex(long a, int n)
{
    char l[LABBUF], opnd[128], rem[32];
    int take;
    while (n > 0) {
        take = n > 16 ? 16 : n;
        l[0] = 0;
        if (lab[a]) label_name(a, l);
        {
            char hx[40];
            hexbytes(img + a, take, hx);
            snprintf(opnd, sizeof opnd, "X'%s'", hx);
        }
        sprintf(rem, "%06lX", (unsigned long)a);
        emit(l, "DC", opnd, rem);
        a += take; n -= take;
    }
}

static void emit_ds_hole(long a, long n)
{
    char l[LABBUF], opnd[64], rem[32];
    if (lab[a]) label_name(a, l); else l[0] = 0;
    snprintf(opnd, sizeof opnd, "XL%ld", n);
    sprintf(rem, "%06lX not covered by TXT", (unsigned long)a);
    emit(l, "DS", opnd, rem);
}

/* A run of one repeated byte, written with a duplication factor.  The hint said
 * so and hints_bind proved it: covered, uniform, no relocation and no label
 * inside.  184 bytes of X'00' as one card is the difference between a work area
 * a reader recognises and twelve cards of hex they have to add up. */
static void emit_fill(long a, long n)
{
    char l[LABBUF], opnd[64], rem[48];
    if (lab[a]) label_name(a, l); else l[0] = 0;
    snprintf(opnd, sizeof opnd, "%ldX'%02X'", n, img[a]);
    sprintf(rem, "%06lX fill", (unsigned long)a);
    emit(l, "DC", opnd, rem);
}

/* An address constant, from the RLD and not from the bytes.  The RLD is the one
 * place an object-deck disassembler has ground truth, and this is the only
 * statement here that rests on it. */
static void emit_adcon(long a, const struct rlditem *r)
{
    char l[LABBUF], opnd[96], rem[48];
    long v = 0;
    int i;
    for (i = 0; i < r->len; i++) v = (v << 8) | img[a + i];
    /* A target IN THIS SECTION is an ADDRESS in whatever space the input numbers
     * in, and BOTH inputs number module-absolute: a member's value has been
     * relocated by the binder, a deck's is the assembled address.  So the
     * section's origin comes off either way -- it was 0 for a deck only because
     * nothing set it, which is cc370#415.
     *
     * AN EXTERNAL TARGET IS NOT THE SAME QUANTITY and the subtraction must not
     * reach it.  In a deck the text holds the ADDEND against another symbol, and
     * taking this section's origin off that is arithmetic between two different
     * symbols; in a member it has been resolved to wherever the binder put it,
     * and that address is not an addend -- reassembling it as one would write a
     * number where a deck holds a relocatable zero, which is why the branch
     * below prints V(...) for a member whatever the value. */
    if (r->r == sect_esdid) v -= sect_org;
    if (lab[a]) label_name(a, l); else l[0] = 0;
    /* A(...) and V(...) ALIGN to a fullword; the length-modified forms do not.
     * An adcon that does not sit on a fullword boundary is ordinary -- IECVERPL
     * has one at X'1F5' -- and writing it as A(...) moves it three bytes on and
     * shifts every statement after it.  The length is the RLD's, which is where
     * a 3-byte AL3 in a channel program comes from as well. */
    int aligned = (r->len == 4 && (a % 4) == 0);
    if (r->r == sect_esdid) {
        char t[LABBUF];
        label_name(v, t);
        if (v >= 0 && v < sect_len && lab[v]) {
            if (aligned) snprintf(opnd, sizeof opnd, "A(%s)", t);
            else snprintf(opnd, sizeof opnd, "AL%d(%s)", r->len, t);
        } else {
            if (aligned) snprintf(opnd, sizeof opnd, "A(%s+X'%lX')", sect_name, (unsigned long)v);
            else snprintf(opnd, sizeof opnd, "AL%d(%s+X'%lX')", r->len, sect_name, (unsigned long)v);
        }
        sprintf(rem, "%06lX", (unsigned long)a);
    } else if (r->r > 0 && r->r < MAXESD && esdname[r->r][0]) {
        /* The TEXT of an adcon against an external reference is the ADDEND, and
         * it is not always zero: BLSRLSYM holds X'00000A70' at X'7B8' under an
         * RLD item naming PC, which is `A(PC+X'A70')' and not `V(PC)'.  Writing
         * V(...) there loses the addend -- two bytes, in the middle of a field
         * nothing else reports on. */
        if (v == 0 || from_member) {
            if (aligned) snprintf(opnd, sizeof opnd, "V(%s)", esdname[r->r]);
            else snprintf(opnd, sizeof opnd, "VL%d(%s)", r->len, esdname[r->r]);
        } else {
            if (aligned) snprintf(opnd, sizeof opnd, "A(%s+X'%lX')", esdname[r->r], (unsigned long)v);
            else snprintf(opnd, sizeof opnd, "AL%d(%s+X'%lX')", r->len, esdname[r->r], (unsigned long)v);
        }
        sprintf(rem, "%06lX", (unsigned long)a);
    } else {
        char hx[16];
        hexbytes(img + a, r->len, hx);
        snprintf(opnd, sizeof opnd, "X'%s'", hx);
        sprintf(rem, "%06lX RLD id %d unknown", (unsigned long)a, r->r);
    }
    emit(l, "DC", opnd, rem);
}

/* ------------------------------------------------------- a bound member -- */

/* The 772 CSECTs with an object and no source are mostly reachable ONLY from a
 * bound member: there is no deck to read.  So this path exists to REACH them,
 * and not to measure the decoder -- a deck round trip has one reader on each
 * side and nothing in between, and that is what the acceptance runs on.  Here
 * the binder sits in the middle, so a failure could be its slicing or our
 * decode, and two instruments in one number is what a week of this taught us
 * not to build.
 *
 * Three things differ from a deck and each one moves bytes if it is missed:
 *
 *  - Addresses are MODULE-absolute.  A section's bytes are img[org, org+len)
 *    and an RLD item's address is absolute too; both come back section-relative.
 *  - An address constant has been RELOCATED.  Its value is an address, not the
 *    offset a deck carries, so a target in this section is `value - org'.
 *  - Segments deliberately SHARE addresses, so the image is built per segment
 *    and the section sliced from its OWN -- the defect cc370#372 fixed in
 *    cmplmd370, arriving here as a requirement rather than as a bug.
 */
struct cesd_ctx { const char *want; int pos; };

static int cesd_cb(const struct lmod_esd *e, void *ctx)
{
    struct cesd_ctx *c = ctx;
    char nm[9];
    name_of(e->name, nm);
    if (e->esdid > 0 && e->esdid < MAXESD) {
        memcpy(esdname[e->esdid], nm, 9);
        esdtype[e->esdid] = e->type;
    }
    if (e->type == LMOD_LR && nld < 256) {          /* an LD becomes an LR when bound */
        ld[nld].addr = e->addr;
        ld[nld].owner = (int)e->len;                /* the owning entry's id */
        memcpy(ld[nld].name, nm, 9);
        nld++;
    }
    if (!sect_esdid && obj_is_section(e->type)
        && (!c->want || !strcmp(nm, c->want))) {
        sect_esdid = e->esdid;
        sect_org = e->addr;
        sect_len = e->len;
        c->pos = e->seg;
        memcpy(sect_name, nm, 9);
    }
    return 1;
}

static int mrld_cb(const struct obj_rld *r, void *ctx)
{
    (void)ctx;
    if (nrld >= MAXRLD || r->p != sect_esdid) return 1;
    rld[nrld].addr = r->addr - sect_org;
    rld[nrld].len = obj_rld_len(r->flag);
    rld[nrld].r = r->r;
    if (rld[nrld].addr >= 0 && rld[nrld].addr < sect_len) nrld++;
    return 1;
}

static int load_member(const unsigned char *m, long n, const char *want, int allow_incomplete)
{
    struct cesd_ctx cc;
    struct lmod_info info;
    struct lmod_iter it;
    struct lmod_item r;
    long pend = -1;
    int cs = 1, segend = 0, want_seg;

    lmod_scan(m, n, &info);
    if ((info.anomalies & LMOD_IMAGE_INCOMPLETE) && !allow_incomplete) {
        fprintf(stderr, "dasm370: the image is incomplete (%s); --allow-incomplete to read it anyway\n",
                lmod_anom_name(info.anomalies & LMOD_IMAGE_INCOMPLETE));
        return 2;
    }
    cc.want = want; cc.pos = 0;
    lmod_cesd_walk(m, n, cesd_cb, &cc);
    if (!sect_esdid) return 0;
    if (sect_len > MAXSECT_BYTES) {
        fprintf(stderr, "dasm370: %s is %ld bytes, over the %ld this build holds\n",
                sect_name, sect_len, MAXSECT_BYTES);
        return 16;
    }
    want_seg = info.nseg ? (cc.pos ? cc.pos : 1) : 0;

    lmod_iter_init(&it, m, n);
    while (lmod_iter_next(&it, &r) == 1) {
        if (r.kind == LMOD_CTL) {
            pend = (r.flags & LMOD_CTL_TEXT) ? mvs_be24(m + r.off + 9) : -1;
            segend = (r.flags & LMOD_CTL_SEGEND) && !(r.flags & LMOD_CTL_END);
            if (pend < 0 && segend) { cs++; segend = 0; }
            if (r.flags & LMOD_CTL_RLD) {
                /* THE RLD INFO COMES FIRST, and the ID/length list after it.
                 * docs/load-module-format.md puts the list at off 16, which is
                 * right only when there is no RLD info to precede it -- and the
                 * two orders are indistinguishable in exactly that case.
                 * Reading the list first made the RLD parse start 4 bytes late,
                 * so the first item's flag+address was read as an R/P pair and
                 * the whole record desynchronised: HMASMADD's member came back
                 * with 85 items where its deck has 100, and the lost ones
                 * carried P values of 1660 and 2956, which are X'67C' and
                 * X'B8C' -- the ADDRESSES of the items being misread.
                 * Measured over 13,102 DLIB and target members: 2,488 control
                 * records carry both lists, and the sum of the ID/length list's
                 * lengths equals the CCW text count for 2,488 of them with the
                 * list AFTER the RLD and 0 of them with it first. */
                long rl = mvs_be16(m + r.off + 6);
                long dat = r.off + 16;
                if (rl > 0 && dat + rl <= n) obj_rld_items(m + dat, rl, mrld_cb, NULL);
            }
        } else if (r.kind == LMOD_TEXT) {
            if ((!info.nseg || cs == want_seg) && pend >= 0) {
                long lo = pend, hi = pend + r.len, j;
                for (j = lo; j < hi; j++)
                    if (j >= sect_org && j < sect_org + sect_len) {
                        img[j - sect_org] = m[r.off + (j - lo)];
                        cov[j - sect_org] = 1;
                    }
            }
            pend = -1;
            if (segend) { cs++; segend = 0; }
        }
    }
    from_member = 1;
    return 1;
}

/* ------------------------------------------------------ a section, once -- */

/* Everything the two loaders write, cleared.  --align-diff reads two sections
 * through this state one after the other, so "what does a load leave behind"
 * stops being a question nobody had to ask.  Miss one of these and the second
 * section inherits it -- which reads as a difference between the two modules,
 * with nothing in either module to explain it. */
static void section_reset(void)
{
    memset(img, 0, sizeof img);
    memset(cov, 0, sizeof cov);
    memset(lab, 0, sizeof lab);
    memset(stbrk, 0, sizeof stbrk);
    memset(rld, 0, sizeof rld);          nrld = 0;
    memset(esdname, 0, sizeof esdname);
    memset(esdtype, 0, sizeof esdtype);
    memset(ld, 0, sizeof ld);            nld = 0;
    sect_org = 0; sect_len = 0; sect_esdid = 0; sect_name[0] = 0;
    from_member = 0; end_has_entry = 0; end_entry = 0;
    seq = 100; nline = 0;
}

/* The file, the deck-or-member sniff, and whichever of the two readers it
 * picks.  Lifted out of main so a SECOND section can be read after the first,
 * and the `goto emit_source' went with it rather than surviving the move: the
 * bound-member path used to jump from the sniff straight to the emitter, over
 * everything in between, which is how --infer came to produce nothing at all
 * for the one input format it exists for (#401).  A function that RETURNS
 * cannot skip what follows it, so that trap is gone rather than documented.
 *
 * 0 = loaded, 2 = no such section, 16 = could not read it. */
/* A REFUSAL THAT NAMES WHAT IT DID FIND.  By the time this runs the CESD walk
 * has already stored every LD/LR entry and every ESD name, so at the moment the
 * tool said "no section named AHLDMPMD" it knew that AHLDMPMD is an ENTRY POINT
 * owned by the section AHLWTO in that very member -- and said none of it.
 *
 * THE REFUSAL ASSERTED LESS THAN THE TOOL KNEW, and that is not a cosmetic
 * complaint: the caller read it as "wrong member", went looking for a lookup
 * failure, and wrote up 124 modules as an unresolved corpus.  Measured over
 * their no-source population, of 124 refusals: 0 are a section this reader
 * missed, 91 name an ENTRY POINT whose owning section is in the same member, 31
 * name a deleted (null) CESD entry, and 2 are genuinely absent.  One message
 * would have separated them at the first run.
 *
 * A refusal that names what it found is the difference between a caller who
 * investigates and a caller who guesses. */
static void no_section(const char *want, const char *src)
{
    int i, n = 0;

    if (want) {
        for (i = 0; i < nld; i++)
            if (!strcmp(ld[i].name, want)) {
                const char *ow = (ld[i].owner > 0 && ld[i].owner < MAXESD
                                  && esdname[ld[i].owner][0]) ? esdname[ld[i].owner] : NULL;
                fprintf(stderr, "dasm370: %s is an ENTRY POINT in %s, not a control section",
                        want, src);
                if (ow) fprintf(stderr, "; its section is %s -- try --csect %s", ow, ow);
                fputc('\n', stderr);
                return;
            }
        for (i = 1; i < MAXESD; i++)
            if (esdname[i][0] && !strcmp(esdname[i], want)) {
                /* obj_type_name() answers "??" for the load-module types it has
                 * no object-deck counterpart for, and "??" tells a reader
                 * nothing.  X'03' is LR and X'07' is the deleted/null entry
                 * (docs/load-module-format.md section 7), and a name surviving
                 * as a tombstone is a different finding from a name that is
                 * absent -- 31 of the caller's 124 are exactly this. */
                const char *t = obj_type_name(esdtype[i]);
                if ((esdtype[i] & 0x0f) == 0x07)
                    fprintf(stderr, "dasm370: %s is in %s only as a DELETED (null) CESD "
                                    "entry, not a control section\n", want, src);
                else if ((esdtype[i] & 0x0f) == 0x03)
                    fprintf(stderr, "dasm370: %s is an ENTRY POINT (LR) in %s, not a control "
                                    "section\n", want, src);
                else
                    fprintf(stderr, "dasm370: %s is in %s as a %s entry, not a control "
                                    "section\n", want, src, t);
                return;
            }
    }
    fprintf(stderr, "dasm370: no section named %s in %s", want ? want : "(any)", src);
    for (i = 1; i < MAXESD; i++)
        if (esdname[i][0] && obj_is_section(esdtype[i])) {
            fprintf(stderr, "%s%s", n++ ? ", " : "; it holds ", esdname[i]);
            if (n == 6) { fputs(", ...", stderr); break; }
        }
    if (!n) fputs("; it holds no section at all", stderr);
    fputc('\n', stderr);
}

static int load_section(const char *src, const char *want, int allow_incomplete)
{
    unsigned char *deck;
    long dn, ncards, c, maxaddr = 0;

    section_reset();
    {
        FILE *f = fopen(src, "rb");
        long got;
        if (!f) { perror(src); return 16; }
        fseek(f, 0, SEEK_END); dn = ftell(f); fseek(f, 0, SEEK_SET);
        deck = malloc((size_t)dn ? (size_t)dn : 1);
        if (!deck) { fprintf(stderr, "dasm370: %s: out of memory\n", src); fclose(f); return 16; }
        got = (long)fread(deck, 1, (size_t)dn, f);
        fclose(f);
        if (got != dn) { fprintf(stderr, "dasm370: %s: short read\n", src); free(deck); return 16; }
    }
    /* An object deck is a multiple of 80 bytes whose cards begin X'02'; anything
     * else is read as a bound member.  Both sniffs are the ones cmplmd370 uses
     * and neither is a guess about the content. */
    if (dn % 80 || dn == 0 || deck[0] != 0x02) {
        int k = load_member(deck, dn, want, allow_incomplete);
        free(deck);
        if (k == 0) {
            no_section(want, src);
            return 2;
        }
        return k == 1 ? 0 : k;
    }
    ncards = dn / 80;

    /* Pass 1: the ESD.  Sections first, because the RLD and the TXT are keyed
     * on the ESDIDs it assigns. */
    for (c = 0; c < ncards; c++) {
        struct esd_collect cc;
        int k;
        cc.n = 0;
        obj_esd_walk(deck + c * 80, dasm_esd_cb, &cc);
        for (k = 0; k < cc.n; k++) {
            struct esd_item *e = &cc.it[k];
            if (e->id > 0 && e->id < MAXESD) {
                memcpy(esdname[e->id], e->name, 9);
                esdtype[e->id] = e->type;
            }
            if (e->type == OBJ_LD && nld < 256) {
                ld[nld].addr = e->addr;
                memcpy(ld[nld].name, e->name, 9);
                ld[nld].owner = (int)e->len;
                nld++;
            }
            if (obj_is_section(e->type) && !sect_esdid
                && (!want || !strcmp(e->name, want))) {
                sect_esdid = e->id;
                sect_org = e->addr;          /* cc370#415: a deck has one too */
                sect_len = e->len;
                memcpy(sect_name, e->name, 9);
            }
        }
    }
    if (!sect_esdid) {
        no_section(want, src);
        free(deck);
        return 2;
    }
    if (sect_len > MAXSECT_BYTES) {
        fprintf(stderr, "dasm370: %s is %ld bytes, over the %ld this build holds\n",
                sect_name, sect_len, MAXSECT_BYTES);
        free(deck);
        return 16;
    }

    /* Pass 2: TXT for our section, and the RLD items filed under it. */
    for (c = 0; c < ncards; c++) {
        const unsigned char *card = deck + c * 80;
        struct obj_txt t;
        if (obj_txt_get(card, &t) && t.esdid == sect_esdid) {
            /* A TXT card's address is MODULE-ABSOLUTE, the same space as the
             * section's ESD address -- so the offset into this section is the
             * difference.  Reading it raw put every byte of a section at origin
             * A at offset A: past the declared length, leaving the image zero
             * and the disassembly a `DS' that round-trips (cc370#415). */
            long off = t.addr - sect_org;
            if (off >= 0 && off + t.len <= MAXSECT_BYTES) {
                memcpy(img + off, t.data, (size_t)t.len);
                memset(cov + off, 1, (size_t)t.len);
                if (off + t.len > maxaddr) maxaddr = off + t.len;
            }
        }
    }
    for (c = 0; c < ncards; c++) obj_rld_walk(deck + c * 80, dasm_rld_cb, NULL);

    /* The END card's entry point.  It is neither text nor a relocation, so
     * neither half of the acceptance sees it -- and it is what the linkage
     * editor resolves a module's entry from, so a disassembly that drops it
     * produces a deck that is byte-equal in everything measured and is not an
     * equivalent.  Found by the caller against 23 of 30 modules.
     * An entry in ANOTHER section is not ours to name: IEHPROG1's END points
     * into IEHPROG6, id 11, and a bare END is right there. */
    for (c = 0; c < ncards; c++) {
        struct obj_end e;
        if (obj_end_get(deck + c * 80, &e) && e.has_entry && e.entry_esdid == sect_esdid) {
            end_has_entry = 1;
            end_entry = e.entry_addr - sect_org;   /* cc370#415: module-absolute too */
        }
    }
    free(deck);
    /* The ESD's length is the section's length, and the issue says so: a section
     * is padded to what the ESD declares.  TXT reaching past it is not a longer
     * section, it is a deck to report on -- extending the section to the text
     * instead made `rldlen' come back 0x0C where the ESD says 0x07, and the
     * whole ESD card then differed for a reason that had nothing to do with the
     * decode. */
    if (maxaddr > sect_len)
        fprintf(stderr, "dasm370: %s: TXT reaches %06lX, past the ESD length %06lX\n",
                sect_name, (unsigned long)maxaddr, (unsigned long)sect_len);
    return 0;
}

/* The offsets the disassembly NAMES: the section's start, the END entry point,
 * every ENTRY, and every A-con target that lands inside the section.  Lifted
 * out of main for --align-diff, which must collect the statements dasm370 would
 * print -- and a statement is cut at a label, so a collector carrying a
 * different label set is a second reader of the section rather than the same
 * one.  The LD addresses are made section-relative here, once: a bound member's
 * ESD carries module-absolute ones. */
static void derive_labels(void)
{
    long off = sect_org;
    int i;

    lab[0] = 1;
    if (end_has_entry && end_entry >= 0 && end_entry < sect_len) lab[end_entry] = 1;
    for (i = 0; i < nld; i++)
        if (ld[i].owner == sect_esdid && ld[i].addr - off >= 0
            && ld[i].addr - off < sect_len) {
            ld[i].addr -= off;
            lab[ld[i].addr] = 1;
        }
    for (i = 0; i < nrld; i++) {
        if (rld[i].r == sect_esdid && rld[i].len == 4) {
            long v = 0; int k;
            for (k = 0; k < 4; k++) v = (v << 8) | img[rld[i].addr + k];
            v -= sect_org;
            if (v >= 0 && v < sect_len) lab[v] = 1;
        }
    }
}

/* --------------------------------------------------------------- derive -- */

/* --derive-hints SRC: assemble the outdated source with as370 and write out what
 * it found, as a hint file.
 *
 * IT IS A TRANSLATOR, NOT AN ANALYSIS, and that is only true because two exports
 * landed first.  #373's --sym carries the symbol table with its sections and
 * DSECT membership; #393's --usings carries every USING/DROP/PUSH/POP with its
 * own (sect, loc) and each register's own base.  Nothing here infers anything:
 * it reads two files and writes a third.  Before those existed the only route
 * was scraping the printed listing -- which is what mvs38dasm does for its DSECT
 * labels, and which cannot answer the USING question at all: a listing shows a
 * USING's resolved base and no location counter, and DROP, PUSH and POP carry no
 * address column whatever.
 *
 * WHAT THE OFFSETS ARE, because everything about using this depends on it.  They
 * are OUR offsets, from OUR outdated source, and they are then applied to IBM's
 * object.  That is the point -- reading IBM's bytes against our structure is how
 * "which statement is missing here" stops being a day of hand work per module --
 * and it is also where it goes wrong: past the first divergence a derived label
 * names the wrong bytes.  Symbolic, consistent, false, and the round trip cannot
 * object, because the bytes do not move.
 *
 * SO THE ANCHORS EXIST TO FIND THAT OFFSET, NOT TO GUARD AGAINST IT.  Measured
 * by the caller over the 909 length-differing modules their runs place: a median
 * of 9 divergence points per module, the first at median offset X'14' and at
 * 2.1 % of the section, with 65 % diverging inside the first tenth.  Two schemes
 * fail on those numbers and both were proposed here first:
 *
 *   - one anchor per derived base checks the one place that never moves.  A base
 *     is established at the CSECT entry, typically offset 2 after a BALR, and
 *     the first divergence is at X'14'.  The anchor sits BEFORE it, passes, and
 *     every label after it is still wrong.
 *   - one anchor per label block refuses essentially everything, since almost
 *     every block head sits after some shift.
 *
 * What is worth having is neither a pass nor a refusal but a LOCATION: this hint
 * set is good up to offset X, and X is where our source and IBM's object part
 * company.  So anchors are written densely, at derived label offsets, and the
 * report is the interval between the last one that held and the first that did
 * not.  --anchors=report disassembles anyway and writes the failures in place;
 * --anchors=refuse stops at the first, which is right for a hand-written file
 * where a failed assertion really is an error and wrong for a run over 2,292
 * modules whose whole purpose is to collect those offsets.
 *
 * WHAT IS NOT WRITTEN AS A TABLE.  A DSECT domain is dasm370's [[using]], which
 * --hints refuses; an absolute domain has no representation here; and a domain
 * whose value or establishing event is in another section has no meaning in this
 * one.  All three are still worth recording, so they are written as `#' comments
 * in a fixed, greppable shape.  A comment cannot be applied by accident, needs no
 * grammar, and leaves the round trip exact -- and promoting one is a human's
 * deliberate edit, which is what #112 means by written and never applied.
 */

#define MAXDSYM 8192
#define MAXDEV  8192

struct dsym { char name[16]; long value; int isrel; };
struct dev  { long seq, loc, value; int isusing, isdrop, reg, valdsect, isabs, ours, valours; char valsect[16]; };

static struct dsym dsyms[MAXDSYM]; static int ndsym;
static struct dev  devs[MAXDEV];   static int ndev;

/* The two exports are read BY COLUMN NAME and never by position.  A column added
 * to either one in the middle would otherwise shift every field after it in
 * silence, and this side would carry on reading plausible numbers out of the
 * wrong columns -- which is the failure this whole file is written against, with
 * a TSV in place of a listing. */
struct tsv { char col[32][24]; int ncol; };

static int tsv_idx(const struct tsv *t, const char *name)
{
    int i;
    for (i = 0; i < t->ncol; i++) if (!strcmp(t->col[i], name)) return i;
    return -1;
}

/* Returns a pointer into `line', which it modifies: the caller owns the line and
 * the fields stay valid until the next line is read.  Deliberately NOT a static
 * buffer -- two calls in one expression is the obvious use and a static one
 * would quietly return the same text twice. */
static char *tsv_get(char *line, int idx)
{
    char *p = line;
    int i = 0;
    if (idx < 0) return NULL;
    for (;;) {
        char *e = strchr(p, '\t');
        if (i == idx) { if (e) *e = 0; return p; }
        if (!e) return NULL;
        p = e + 1; i++;
    }
}

/* Read one export.  `want' is the section NAME and not its id: both exports
 * carry as370's internal section number, which is not the ESDID and means
 * nothing outside the run that produced it. */
static int read_tsv(const char *fn, struct tsv *t, FILE **fp)
{
    char line[1024];
    *fp = fopen(fn, "r");
    if (!*fp) { perror(fn); return 16; }
    t->ncol = 0;
    while (fgets(line, sizeof line, *fp)) {
        char *p;
        if ((p = strchr(line, '\n'))) *p = 0;
        if (strncmp(line, "#columns\t", 9)) continue;
        p = line + 9;
        while (p && t->ncol < 32) {
            char *e = strchr(p, '\t');
            if (e) *e = 0;
            snprintf(t->col[t->ncol], sizeof t->col[0], "%.23s", p);   /* a column NAME, and gcc cannot bound a line */
            t->ncol++;
            p = e ? e + 1 : NULL;
        }
        return 0;
    }
    fprintf(stderr, "dasm370: %s: no #columns header -- not an as370 export\n", fn);
    fclose(*fp); *fp = NULL;
    return 16;
}

static int load_sym(const char *fn, const char *want)
{
    struct tsv t;
    FILE *f;
    char line[1024], b[1024];
    int i_name, i_val, i_type, i_sn, i_def, rc;
    if ((rc = read_tsv(fn, &t, &f)) != 0) return rc;
    i_name = tsv_idx(&t, "name");  i_val = tsv_idx(&t, "value");
    i_type = tsv_idx(&t, "type");  i_sn  = tsv_idx(&t, "sectname");
    i_def  = tsv_idx(&t, "defined");
    if (i_name < 0 || i_val < 0 || i_type < 0 || i_sn < 0 || i_def < 0) {
        fprintf(stderr, "dasm370: %s: the export is missing a column this needs\n", fn);
        fclose(f); return 16;
    }
#define FLD(ix) (snprintf(b, sizeof b, "%s", line), tsv_get(b, ix))
    while (fgets(line, sizeof line, f)) {
        char *p, nm[16];
        long value;
        if ((p = strchr(line, '\n'))) *p = 0;
        if (line[0] == '#' || !line[0]) continue;
        { char *v = FLD(i_def); if (!v || strcmp(v, "1")) continue; }   /* referenced, never defined */
        { char *v = FLD(i_sn);  if (!v || strcmp(v, want)) continue; }  /* another section */
        /* REL and LD only.  SD is the section itself and offset 0 already carries
         * its name.  ABS is excluded for as370's own reason: an absolute EQU keeps
         * the section its card was written in while holding no address in it, and
         * every module writes R0 EQU 0 .. R15 EQU 15 inside a CSECT -- take those
         * for labels and the disassembly names a register at every small offset. */
        { char *v = FLD(i_type); if (!v || (strcmp(v, "REL") && strcmp(v, "LD"))) continue; }
        { char *v = FLD(i_name); if (!v || !*v) continue;
          snprintf(nm, sizeof nm, "%s", v); }
        { char *v = FLD(i_val);  value = v ? strtol(v, NULL, 10) : 0; }
        if (ndsym >= MAXDSYM) break;
        snprintf(dsyms[ndsym].name, sizeof dsyms[0].name, "%s", nm);
        dsyms[ndsym].value = value;
        dsyms[ndsym].isrel = 1;
        ndsym++;
    }
#undef FLD
    fclose(f);
    return 0;
}

static int load_usings(const char *fn, const char *want)
{
    struct tsv t;
    FILE *f;
    char line[1024];
    int i_seq, i_kind, i_sn, i_loc, i_reg, i_val, i_vsn, i_vd, i_abs, i_by, rc;
    if ((rc = read_tsv(fn, &t, &f)) != 0) return rc;
    i_seq = tsv_idx(&t, "seq");   i_kind = tsv_idx(&t, "kind");
    i_sn  = tsv_idx(&t, "sectname"); i_loc = tsv_idx(&t, "loc");
    i_reg = tsv_idx(&t, "reg");   i_val  = tsv_idx(&t, "value");
    i_vsn = tsv_idx(&t, "valsectname"); i_vd = tsv_idx(&t, "valdsect");
    i_abs = tsv_idx(&t, "abs");   i_by   = tsv_idx(&t, "by");
    if (i_seq < 0 || i_kind < 0 || i_sn < 0 || i_loc < 0 || i_reg < 0
        || i_val < 0 || i_vsn < 0 || i_vd < 0 || i_abs < 0 || i_by < 0) {
        fprintf(stderr, "dasm370: %s: the export is missing a column this needs\n", fn);
        fclose(f); return 16;
    }
    while (fgets(line, sizeof line, f)) {
        char b[1024], *p;
        struct dev d;
        if ((p = strchr(line, '\n'))) *p = 0;
        if (line[0] == '#' || !line[0]) continue;
        memset(&d, 0, sizeof d);
#define FLD(ix) (snprintf(b, sizeof b, "%s", line), tsv_get(b, ix))
        { char *v = FLD(i_by);   if (!v) continue;
          /* by=noop changed nothing, so it opens and closes nothing.  by=pop is
           * treated exactly like by=stmt -- that the export states what a POP
           * did is the whole reason this side needs no stack of its own. */
          if (!strcmp(v, "noop")) continue; }
        { char *v = FLD(i_kind); if (!v) continue;
          d.isusing = !strcmp(v, "USING"); d.isdrop = !strcmp(v, "DROP");
          if (!d.isusing && !d.isdrop) continue; }       /* PUSH and POP move no domain themselves */
        { char *v = FLD(i_seq);  d.seq = v ? strtol(v, NULL, 10) : 0; }
        { char *v = FLD(i_loc);  d.loc = v ? strtol(v, NULL, 10) : 0; }
        { char *v = FLD(i_reg);  d.reg = v ? (int)strtol(v, NULL, 10) : -1; }
        { char *v = FLD(i_val);  d.value = v ? strtol(v, NULL, 10) : 0; }
        { char *v = FLD(i_vd);   d.valdsect = v && !strcmp(v, "1"); }
        { char *v = FLD(i_abs);  d.isabs = v && !strcmp(v, "1"); }
        { char *v = FLD(i_sn);   d.ours = v && !strcmp(v, want); }
        { char *v = FLD(i_vsn);  snprintf(d.valsect, sizeof d.valsect, "%s", v ? v : "");
          d.valours = v && !strcmp(v, want); }
#undef FLD
        if (ndev >= MAXDEV) break;
        devs[ndev++] = d;
    }
    fclose(f);
    return 0;
}

/* Run as370 over the source with both exports and a deck.  A host tool, so
 * exec is ordinary here -- the no-fork rule in the root CLAUDE.md is about what
 * runs ON MVS.  The deck is asked for because the section's declared length is
 * needed and as370 is already running; it costs one more -o. */
static int run_as370(const char *as, const char *src, char *const *incs, int ninc,
                     const char *symf, const char *usef, const char *objf)
{
    char cmd[4096];
    int n = 0, i, rc;
    n += snprintf(cmd + n, sizeof cmd - (size_t)n, "'%s'", as);
    for (i = 0; i < ninc; i++)
        n += snprintf(cmd + n, sizeof cmd - (size_t)n, " -I '%s'", incs[i]);
    n += snprintf(cmd + n, sizeof cmd - (size_t)n,
                  " '%s' -o '%s' --sym='%s' --usings='%s' >/dev/null 2>&1",
                  src, objf, symf, usef);
    if (n >= (int)sizeof cmd) {
        fprintf(stderr, "dasm370: the as370 command line is too long for this build\n");
        return 16;
    }
    rc = system(cmd);
    if (rc == -1) { fprintf(stderr, "dasm370: could not run %s\n", as); return 16; }
    rc = WIFEXITED(rc) ? WEXITSTATUS(rc) : 16;
    /* Severity 8 and above means the assembly did not produce a trustworthy
     * deck, and a hint set derived from a failed assembly is worse than none:
     * every symbol it did resolve looks exactly like one from a clean run. */
    if (rc >= 8) {
        fprintf(stderr, "dasm370: as370 ended rc %d on %s -- a hint set from a failed "
                        "assembly cannot be told from one from a clean run\n", rc, src);
        return 16;
    }
    return 0;
}

static int dsym_cmp(const void *a, const void *b)
{
    const struct dsym *x = a, *y = b;
    if (x->value != y->value) return x->value < y->value ? -1 : 1;
    return strcmp(x->name, y->name);
}

/* Write the hint file.
 *
 * The header records WHAT PRODUCED IT, and the `-I' list is the part that earns
 * its place: a hint set derived against the wrong macro library is a wrong hint
 * set that looks right, and here it says so in its own first lines instead of
 * being visible only to someone who happens to diff two runs.
 *
 * Nothing in the header varies between two runs of the same inputs -- no
 * timestamp, no temporary path -- because the round trip that accepts this file
 * compares it byte for byte. */
static int derive_emit(FILE *o, const char *as, const char *asver, long assize,
                       const char *src, char *const *incs, int ninc,
                       const char *sect, long seclen, int anchors)
{
    int i, j, nlab = 0, nbase = 0, nnote = 0, nanch = 0;

    fprintf(o, "# derived by dasm370 --derive-hints\n");
    fprintf(o, "#   source   %s\n", src);
    fprintf(o, "#   section  %s  (X'%lX' bytes)\n", sect, (unsigned long)seclen);
    fprintf(o, "#   as370    %s\n", as);
    fprintf(o, "#   version  %s\n", asver);
    fprintf(o, "#   size     %ld bytes\n", assize);
    if (ninc == 0)
        fprintf(o, "#   -I       (none)\n");
    for (i = 0; i < ninc; i++)
        fprintf(o, "#   -I       %s\n", incs[i]);
    fprintf(o,
"#\n"
"# The as370 line identifies the INVOCATION, not the binary's content: a path, a\n"
"# version string and a byte count are not a hash. Pin the binary externally if\n"
"# that matters. The -I list is the one that catches the ordinary mistake --\n"
"# a hint set derived against the wrong macro library is a wrong hint set that\n"
"# looks right.\n"
"#\n"
"# THE OFFSETS BELOW ARE THIS SOURCE'S, applied to whatever module you point\n"
"# dasm370 at. Past the first point where the two diverge, a label names the\n"
"# wrong bytes and a base's range covers the wrong span -- symbolically,\n"
"# consistently, and without moving a byte, so no round trip objects. The\n"
"# [[verify]] anchors exist to FIND that offset rather than to guard against it:\n"
"# with --anchors=report the disassembly is written anyway and each failed anchor\n"
"# is a comment at its offset, so the first one bounds the divergence.\n"
"#\n");

    qsort(dsyms, (size_t)ndsym, sizeof dsyms[0], dsym_cmp);

    for (i = 0; i < ndsym; i++) {
        if (dsyms[i].value < 0 || dsyms[i].value >= seclen) {
            fprintf(o, "# derived: kind=label name=%s value=0x%lX reason=outside-section\n",
                    dsyms[i].name, (unsigned long)dsyms[i].value);
            nnote++;
            continue;
        }
        /* Several symbols can name one offset -- `A EQU *' beside `B DS 0F' is
         * ordinary -- and two [[label]] entries on one offset is a file this
         * tool's own parser refuses.  The first by name wins and the rest are
         * recorded, because dropping them silently would make the file look
         * complete and be short. */
        if (i > 0 && dsyms[i - 1].value == dsyms[i].value) {
            fprintf(o, "# derived: kind=label name=%s value=0x%lX reason=offset-already-named-by-%s\n",
                    dsyms[i].name, (unsigned long)dsyms[i].value, dsyms[i - 1].name);
            nnote++;
            continue;
        }
        fprintf(o, "\n[[label]]\nat   = 0x%lX\nname = \"%s\"\n",
                (unsigned long)dsyms[i].value, dsyms[i].name);
        nlab++;
    }

    /* A base opens at a USING on a register and ends at the next USING or DROP
     * on the SAME register -- a linear replay, which is possible only because
     * the export already resolved what every POP did.  A stack kept here would
     * be a second copy of the assembler's, free to disagree in silence. */
    for (i = 0; i < ndev; i++) {
        struct dev *u = &devs[i];
        long to = seclen;
        if (!u->isusing) continue;
        /* A base whose VALUE lies outside this section covers nothing in it, and
         * is ordinary rather than exotic: `USING D,11,10' on a section shorter
         * than 4096 bytes bases 10 at D+4096, past the end.  It must not become
         * a [[base]] -- this tool's own parser refuses one, so the file would be
         * rejected by its own consumer, which the round trip is what catches. */
        if (u->value < 0 || u->value >= seclen || u->loc < 0 || u->loc >= seclen) {
            fprintf(o, "# derived: kind=using reg=%d value=0x%lX from=0x%lX"
                       " evidence=assembly reason=outside-section\n",
                    u->reg, (unsigned long)u->value, (unsigned long)u->loc);
            nnote++;
            continue;
        }
        if (u->valdsect || u->isabs || !u->ours || !u->valours) {
            /* Three kinds this file cannot express, recorded rather than
             * dropped: a DSECT domain is [[using]], which --hints refuses; an
             * absolute domain is not an address at all; and one whose value or
             * establishing statement is in another section has no meaning in
             * this one. */
            fprintf(o, "# derived: kind=using reg=%d value=0x%lX valsect=%s from=0x%lX"
                       " dsect=%d abs=%d evidence=assembly reason=%s\n",
                    u->reg, (unsigned long)u->value, u->valsect[0] ? u->valsect : "(none)",
                    (unsigned long)u->loc, u->valdsect, u->isabs,
                    u->valdsect ? "dsect-domain" : u->isabs ? "absolute-domain" : "other-section");
            nnote++;
            continue;
        }
        for (j = i + 1; j < ndev; j++)
            if (devs[j].reg == u->reg) {
                /* A DROP written in ANOTHER section has a loc in the wrong
                 * coordinate system, so the range simply runs to the end here. */
                to = devs[j].ours ? devs[j].loc : seclen;
                break;
            }
        if (to > seclen) to = seclen;
        if (to <= u->loc) {
            fprintf(o, "# derived: kind=using reg=%d value=0x%lX from=0x%lX to=0x%lX"
                       " evidence=assembly reason=empty-range\n",
                    u->reg, (unsigned long)u->value, (unsigned long)u->loc, (unsigned long)to);
            nnote++;
            continue;
        }
        fprintf(o, "\n[[base]]\nreg   = %d\nvalue = 0x%lX\nfrom  = 0x%lX\nto    = 0x%lX\n",
                u->reg, (unsigned long)u->value, (unsigned long)u->loc, (unsigned long)to);
        nbase++;
    }

    /* The anchors, and their BYTES come from the deck this same as370 run
     * produced -- read back through dasm370's own deck reader, so there is one
     * reader on each side and nothing in between.  Four bytes: enough to
     * discriminate, short enough that an anchor asserts the statement AT the
     * label and not the one after it.  Only where all four are covered by a TXT
     * card, because --hints refuses a verify over bytes no card defined and a
     * file this tool writes must be one it accepts. */
    if (anchors) {
        fprintf(o, "\n# Anchors, dense, at derived label offsets. Anything sparser checks the\n"
                   "# one place that never moves: a base is established at the CSECT entry,\n"
                   "# typically offset 2 after a BALR, and the first divergence is at a\n"
                   "# median offset of X'14' -- so a per-base anchor sits BEFORE the\n"
                   "# divergence, passes, and leaves every later label wrong. Measured over\n"
                   "# 909 modules: median 9 divergence points, the first at 2.1%% of the\n"
                   "# section, 65%% inside the first tenth.\n");
        for (i = 0; i < ndsym; i++) {
            char hx[16];
            long at = dsyms[i].value;
            if (at < 0 || at + 4 > seclen) continue;
            if (i > 0 && dsyms[i - 1].value == at) continue;
            if (!cov[at] || !cov[at + 1] || !cov[at + 2] || !cov[at + 3]) continue;
            hexbytes(img + at, 4, hx);
            fprintf(o, "\n[[verify]]\nat    = 0x%lX\nbytes = \"%s\"\n",
                    (unsigned long)at, hx);
            nanch++;
        }
    }

    fprintf(o, "\n# %d label(s), %d base(s), %d anchor(s), %d note(s)\n",
            nlab, nbase, nanch, nnote);
    return 0;
}


/* ---------------------------------------------------------------- infer -- */

/* --infer: candidates from the code itself, for the CSECT that has no source at
 * all -- the 772 of #112, mostly reachable only from a bound member.
 *
 * EVERY CANDIDATE IS WRITTEN AS A COMMENT AND NONE IS APPLIED, and that is the
 * issue's instruction rather than caution.  A base register is not "R12 holds X"
 * but "from here until it is dropped, resolve D(12) against X".  The POINT is
 * sometimes ground truth; the RANGE never is, because there are no DROPs in a
 * module and no block structure to read one from.  Get the range wrong and every
 * displacement inside it resolves against the wrong section, producing symbols
 * that are plausible, consistent and false -- and the bytes do not move, so the
 * round trip is blind to it and so is everything downstream.  Promoting a
 * candidate into a [[base]] is a human's deliberate edit, with the lifetime
 * supplied by a person who looked.
 *
 * THE EVIDENCE KIND IS RECORDED SEPARATELY FROM ANY CONFIDENCE, because the two
 * are re-judgeable by different means and only one of them is re-judgeable at
 * all:
 *
 *   prologue   `BALR Rn,0' -- the base is the next instruction's offset.  Exact
 *              about WHERE, and says nothing about for how long.  It detects the
 *              IDIOM and not the DECLARATION, which is the whole of what it can
 *              and cannot mean: `BALR Rn,0' is a run-time fact and `USING' is an
 *              assembly-time one, and an object records the first and cannot
 *              record the second.  Three consequences, all measured:
 *              IGG08113 writes `BALR R15,0' and then `B 32(,R15)' by hand with
 *              no USING at all -- the idiom is there and the addressability is
 *              not, and from the object those are the same bytes; IECVERPL
 *              establishes R10 a second time at X'246' with no USING beside it,
 *              so the assembly resolved everything against R10 = 0 throughout
 *              and applying X'246' would resolve displacements against an origin
 *              the assembly never used -- a true statement about the code and a
 *              false one as a hint; and a data area holding X'0510' is `BALR 1,0'
 *              to any byte-level reader, which is #383's reachability and not
 *              something an opcode gate can decide.
 *   rld        a register loaded from an address constant whose RLD resolves
 *              into this section, and afterwards used as a base.  The RLD is the
 *              one place an object-deck reader has ground truth, so a later
 *              reader can re-check this against the object itself.
 *   pattern    a register used as a base with no origin found.  Re-judgeable
 *              against nothing -- it records a question, not an answer.
 */

#define MAXCAND 256

struct cand { int reg; long at, value; int kind; int used_at; int used; };
                                       /* kind 0 prologue, 1 rld, 2 pattern */
static struct cand cands[MAXCAND]; static int ncand;
static long balr_base[16];             /* a prologue base per register, or -1 */
static long used_base_at[16];          /* first offset the register is used as a base */

/* The base registers an instruction addresses through: at most two, and zero is
 * never one of them -- D(0) is an absolute address and names no base. */
static int base_regs(const struct opc *o, const unsigned char *b, int *r)
{
    int n = 0;
    switch (o->fmt) {
    case F_RX: case F_BC: case F_RS: case F_S:
        r[n] = (b[2] >> 4) & 0xf; if (r[n]) n++;
        break;
    case F_SI:
        r[n] = (b[2] >> 4) & 0xf; if (r[n]) n++;
        break;
    case F_SS:
        r[n] = (b[2] >> 4) & 0xf; if (r[n]) n++;
        r[n] = (b[4] >> 4) & 0xf; if (r[n]) n++;
        break;
    default:
        break;
    }
    return n;
}

static void cand_add(int reg, long at, long value, int kind)
{
    int i;
    for (i = 0; i < ncand; i++)
        if (cands[i].reg == reg && cands[i].value == value && cands[i].kind == kind) return;
    if (ncand >= MAXCAND) return;
    cands[ncand].reg = reg; cands[ncand].at = at; cands[ncand].value = value;
    cands[ncand].kind = kind; cands[ncand].used = 0; cands[ncand].used_at = 0;
    ncand++;
}

/* One linear decode of the section, twice: the first pass finds the prologue
 * bases, and the second uses them to resolve an `L Rn,D(B)' far enough to ask
 * the RLD what sits at the target.  Two passes because the second question
 * cannot be asked before the first is answered, and one pass answering both
 * would be answering it with whatever it had found so far. */
static void infer_scan(int pass)
{
    long a = 0;
    while (a < sect_len) {
        const struct opc *o;
        int mask, ismask = 0, len, br[2], nbr, k;
        if (!cov[a] || (a % 2) || a + 1 >= sect_len) { a += 2 - (a % 2); continue; }
        if (rld_at(a)) { a += rld_at(a)->len; continue; }
        mask = (img[a + 1] >> 4) & 0xf;
        o = find_op(img[a], img[a + 1], mask, &ismask);
        len = o ? ins_len_of(o->fmt) : 0;
        if (!o || a + len > sect_len || rld_overlaps(a, len) || !reencode_ok(o, img + a, len)) {
            a += 2;
            continue;
        }
        if (pass == 0) {
            /* `BALR Rn,0' loads the address of the NEXT instruction.  R2 zero is
             * what makes it an addressability idiom rather than a call. */
            /* R2 == 0 is what separates the addressability idiom from a call,
             * and it is CORRECT here -- `BALR R1,R15' is X'051F' and never
             * reaches this.  What it cannot separate is an instruction from data
             * that looks like one: X'0510' in a table is `BALR 1,0' to any reader
             * working from bytes, and only reachability (#383) can say that
             * nothing branches there. */
            if (o->fmt == F_RR && (img[a + 1] & 0xf) == 0
                && (!strcmp(o->name, "BALR") || !strcmp(o->name, "BASR"))) {
                int r1 = (img[a + 1] >> 4) & 0xf;
                if (r1) { balr_base[r1] = a + 2; cand_add(r1, a, a + 2, 0); }
            }
            nbr = base_regs(o, img + a, br);
            for (k = 0; k < nbr; k++)
                if (used_base_at[br[k]] < 0) used_base_at[br[k]] = a;
        } else {
            /* `L Rn,D(B)' where B already has a base: resolve the operand far
             * enough to ask what is AT it.  An address constant there, relocated
             * into this section, is the register's origin -- and the RLD saying
             * so is why this is evidence and the BALR above is a pattern. */
            if (o->fmt == F_RX && !strcmp(o->name, "L")) {
                int r1 = (img[a + 1] >> 4) & 0xf;
                int b2 = (img[a + 2] >> 4) & 0xf;
                long d2 = ((img[a + 2] & 0xf) << 8) | img[a + 3];
                if (b2 && balr_base[b2] >= 0) {
                    long tgt = balr_base[b2] + d2;
                    const struct rlditem *r = (tgt >= 0 && tgt + 4 <= sect_len) ? rld_at(tgt) : NULL;
                    if (r && r->r == sect_esdid && r->len == 4) {
                        long v = 0; int q;
                        for (q = 0; q < 4; q++) v = (v << 8) | img[tgt + q];
                        v -= sect_org;
                        if (v >= 0 && v < sect_len) cand_add(r1, a, v, 1);
                    }
                }
            }
        }
        a += len;
    }
}

static const char *cand_kind(int k)
{
    return k == 0 ? "prologue" : k == 1 ? "rld" : "pattern";
}

static int infer_emit(FILE *o, const char *src)
{
    int i, r, n = 0;

    fprintf(o, "# derived by dasm370 --infer\n");
    fprintf(o, "#   module   %s\n", src);
    fprintf(o, "#   section  %s  (X'%lX' bytes)\n", sect_name, (unsigned long)sect_len);
    fprintf(o,
"#\n"
"# EVERY LINE BELOW IS A CANDIDATE AND NONE IS APPLIED. They are comments, so\n"
"# feeding this file back to --hints changes nothing: promoting one into a\n"
"# [[base]] is a deliberate edit, and the thing a person has to supply is the\n"
"# LIFETIME. A base register is not \"R12 holds X\" but \"from here until it is\n"
"# dropped, resolve D(12) against X\", and a module has no DROPs and no block\n"
"# structure to read a range from. Get the range wrong and every displacement\n"
"# inside it resolves against the wrong section -- plausibly, consistently and\n"
"# falsely, without moving a byte, so nothing downstream can object.\n"
"#\n"
"# evidence= says what the claim rests on, separately from how much to believe\n"
"# it, because only some of them can be re-judged at all:\n"
"#   prologue  BALR Rn,0 -- exact about WHERE, silent about for how long, and\n"
"#             detecting the IDIOM rather than the DECLARATION. A module that\n"
"#             loads a base at run time without telling the assembler produces\n"
"#             a candidate that is true about the bytes and wrong as a hint;\n"
"#             and until reachability lands (#383) a data area holding X'0510'\n"
"#             is BALR 1,0 to anything reading bytes.\n"
"#   rld       loaded from an address constant the RLD relocates into this\n"
"#             section: re-checkable against the object itself\n"
"#   pattern   used as a base with no origin found: a question, not an answer\n"
"#\n");

    for (i = 0; i < ncand; i++) {
        struct cand *c = &cands[i];
        char nm[LABBUF];
        long L;
        for (L = c->value; L > 0 && !lab[L]; L--) ;
        label_name(L, nm);
        /* A BALR Rn,0 whose register is NEVER USED AS A BASE is not an
         * addressability idiom, and calling it `prologue' claims more than the
         * bytes support.  Measured by the caller against the real USING events
         * of the same modules' source: of 28 prologue candidates, 3 disagreed,
         * and two of those -- IGG08113 R15, ICKTR02 R1 -- are registers the
         * source bases nothing on at all.  The BALR is still reported, because
         * it happened; what changes is the claim made about it. */
        int unused = used_base_at[c->reg] < 0;
        fprintf(o, "# infer: kind=base reg=%d value=0x%lX at=0x%lX evidence=%s used=%s",
                c->reg, (unsigned long)c->value, (unsigned long)c->at,
                (c->kind == 0 && unused) ? "pattern" : cand_kind(c->kind),
                unused ? "no" : "yes");
        if (!unused) fprintf(o, " first-use=0x%lX", (unsigned long)used_base_at[c->reg]);
        if (L == c->value) fprintf(o, " near=%s", nm);
        if (c->kind == 0 && unused) fprintf(o, " note=balr-not-used-as-base");
        fprintf(o, "\n");
        n++;
    }
    /* A register the code addresses through and whose origin nothing here
     * explains.  Recording the question is the point: an unresolved D(R7) under
     * a note costs a reader one lookup, and a confident wrong symbol is believed
     * and propagates (#112).  This is the half that says which registers a
     * reader still has to account for. */
    for (r = 1; r < 16; r++) {
        int have = 0;
        if (used_base_at[r] < 0) continue;
        for (i = 0; i < ncand; i++) if (cands[i].reg == r) have = 1;
        if (have) continue;
        fprintf(o, "# infer: kind=base reg=%d value=? at=? evidence=pattern used=yes"
                   " first-use=0x%lX note=no-origin-found\n",
                r, (unsigned long)used_base_at[r]);
        n++;
    }
    fprintf(o, "\n# %d candidate(s), 0 applied\n", n);
    return 0;
}

/* ------------------------------------------------------------- the walk -- */

/* One pass over the section.  It runs TWICE when the hint file carries a USING:
 * once with `scanning' set, which emits nothing and only records the branch
 * targets a USING makes readable, and then once for real.  Two modes of one
 * function rather than two functions, for the same reason the opcode table is
 * included and not copied -- a second copy of this loop would drift from it and
 * the drift would be invisible, because both halves would still round-trip.
 *
 * The order inside is the order of authority: a USING or DROP is a statement
 * boundary the file asked for; a hole is a hole; the RLD is ground truth; a fill
 * was proved uniform; a [[data]] run was declared not to be code; and only then
 * is a decode attempted. */
/* ----------------------------------------------------------- reachability -- */

/* #383, MEASUREMENT FIRST.  The rule's own coverage decides its shape, so this
 * runs before the re-specification is final rather than after it.
 *
 * WHAT A CODE ROOT IS, and the issue is explicit where a day of design was not:
 * "RLD targets are LABEL roots, not code roots -- an RLD entry says where an
 * address constant points, which is data at least as often as code; treating a
 * DC A(BUFFER) table as code reintroduces exactly what reachability exists to
 * remove."  So the roots here are the SD (the section origin), the LD/LR entries
 * the section OWNS, and the END entry ON A DECK ONLY -- a member does not carry
 * an entry point at all, which two ld370 links differing in nothing else proved
 * by coming out byte-identical (2026-06-22).  The fourth kind, an adcon target
 * whose register is branched through, is a TRAVERSAL DISCOVERY over the whole
 * module and is not in this cut; it is reported as absent rather than silently
 * omitted.
 *
 * WHY SD IS NOT NEGOTIABLE: without it 11 of the 30 control CSECTs -- real code
 * with real source -- come out entirely DC, byte-safe and invisible to every
 * instrument either session has.  A CSECT entered at its origin by V(name) from
 * another load module is the ordinary MVS shape, and no test applied inside the
 * member can see that call.
 *
 * WHAT THE TRAVERSAL CAN FOLLOW WITHOUT A BASE is the whole question.  Fall-
 * through, yes.  `BC D(X,B)' needs a resolved base, which is #382's problem
 * entire.  Two assumptions are therefore SWITCHES and not defaults, so the
 * measurement can say what each one buys:
 *
 *   r15   R15 holds the entry point on entry, so it is the section origin.
 *         MVS linkage convention, and what the branch over a PL/S eyecatcher
 *         at offset 0 relies on -- without it the traversal dies at byte 0 of
 *         most modules.  Wrong the moment R15 is reloaded, which is not tracked.
 *   balr  a prologue BALR Rn,0 sets Rn = offset + 2, assumed live for the whole
 *         section.  That is --infer's `prologue' evidence and carries its limit:
 *         the IDIOM is a run-time fact and USING is not in the object at all.
 *
 * Both can mark data as reached where they are wrong, which is the D -> I
 * direction; having neither marks code dark, which is I -> D and the one the
 * gate calls discriminating. */

#define RCH_R15  1
#define RCH_BALR 2
#define RCH_RLD  4
#define RCH_LR   8
#define RCH_ACON 16

static unsigned char rch[MAXSECT_BYTES];      /* 1 = the traversal reached this byte */
static unsigned char rseen[MAXSECT_BYTES];    /* 1 = already walked from this offset */
static long rq[MAXSECT_BYTES / 2];
static long nrq;
static long rbase[16];                        /* a base register's section offset, or -1 */
static long rload[16];                        /* where a register was last LOADED from, or -1 */
static int  reach_mode = -1;                  /* -1 = off, else RCH_* bits */
static int  reach_only;                       /* the measurement report, no disassembly */
static int  nr_sd, nr_ld, nr_end;
/* How often the RLD base rule actually SET a register.  A zero in the reach
 * figures is otherwise consistent with both `it fired and changed nothing'
 * and `it never fired', and those are not the same measurement. */
static int  nr_rldbase, nr_rldnew, nr_lrbase, nr_balrbase;
static int  nr_acon, nr_acontab;              /* promoted code roots, and tables promoted */

static void rq_push(long a)
{
    if (a < 0 || a >= sect_len || (a % 2)) return;
    if (rseen[a]) return;
    if (nrq >= (long)(sizeof rq / sizeof rq[0])) return;
    rq[nrq++] = a;
}

/* The same decode decision walk_section makes, and deliberately the same: a
 * traversal that accepts bytes the emitter would refuse would report coverage
 * the disassembly does not have. */
static const struct opc *reach_decode(long a, int *len)
{
    const struct opc *o;
    int mask, ismask = 0;
    char opnd[OPNDBUF];
    if (a < 0 || a + 1 >= sect_len || (a % 2) || !cov[a]) return NULL;
    mask = (img[a + 1] >> 4) & 0xf;
    o = find_op(img[a], img[a + 1], mask, &ismask);
    if (!o) return NULL;
    *len = ins_len_of(o->fmt);
    if (a + *len > sect_len || rld_overlaps(a, *len)) return NULL;
    if (!reencode_ok(o, img + a, *len)) return NULL;
    if (!operands(o, img + a, a, opnd, sizeof opnd)) return NULL;
    return o;
}

/* THE PROMOTION RULE -- #383's fourth bullet, and it is the COMPLEMENT of its
 * first rather than a refinement of it.  An RLD target is a LABEL root on its
 * own, because an address constant points at data at least as often as code.
 * The same word becomes a CODE root when a register loaded from it is BRANCHED
 * THROUGH: the discriminator is the BR, not the adcon.  That is also why an
 * `rld' base pass fires and adds nothing -- it has the targets and lacks the
 * gate, and a base is not a gate.
 *
 * THE INDEX IS NEVER RESOLVED and does not need to be.  BLSCAMER's
 * `SLA 9,2' / `L 9,1744(9,12)' / `BR 9' selects one entry of a table this pass
 * cannot know; what it recognises is that the load's target region is relocated,
 * and then EVERY relocated word of that table is a code root.
 *
 * WHAT DELIMITS THE TABLE is the whole risk, because too wide a rule promotes
 * the `DC A(BUFFER)' case the first bullet forbids.  The run is taken from the
 * load's target OR from the word immediately after it, and the one word of slack
 * is measured rather than chosen: BLSCAMER's load targets 000006EC, which is the
 * table's INDEX-0 SLOT, holds zero, and therefore carries no relocation at all --
 * a zero address needs none to stay zero.  A rule anchored strictly on the
 * target promotes nothing on the very module it was derived from. */
static void reach_promote(long src)
{
    long w;
    int any = 0;
    if (src < 0 || src >= sect_len) return;
    if (!(rld_at(src) && rld_at(src)->r == sect_esdid && rld_at(src)->len == 4)) src += 4;
    for (w = src; w + 4 <= sect_len; w += 4) {
        const struct rlditem *ri = rld_at(w);
        long v = 0; int q;
        if (!ri || ri->r != sect_esdid || ri->len != 4) break;
        for (q = 0; q < 4; q++) v = (v << 8) | img[w + q];
        v -= sect_org;
        if (v > 0 && v < sect_len) { rq_push(v); nr_acon++; any = 1; }
    }
    if (any) nr_acontab++;
}

static void reach_walk(void)
{
    while (nrq > 0) {
        long a = rq[--nrq];
        int going = 1;
        while (going && a >= 0 && a < sect_len) {
            const struct opc *o;
            int len = 0, k;
            if (rseen[a]) break;
            rseen[a] = 1;
            if ((o = reach_decode(a, &len)) == NULL) break;
            for (k = 0; k < len; k++) rch[a + k] = 1;
            if (o->op == 0x47) {                       /* BC and its extended mnemonics */
                int m = (img[a + 1] >> 4) & 0xf;
                int x = img[a + 1] & 0xf, b = (img[a + 2] >> 4) & 0xf;
                int d = ((img[a + 2] & 0xf) << 8) | img[a + 3];
                if (x == 0 && b > 0 && rbase[b] >= 0) rq_push(rbase[b] + d);
                if (m == 15) going = 0;                /* B: no fall-through */
                else a += len;
            } else if (o->op == 0x07) {                /* BCR: the target is a register */
                int m = (img[a + 1] >> 4) & 0xf, r2 = img[a + 1] & 0xf;
                if ((reach_mode & RCH_ACON) && rload[r2] >= 0) reach_promote(rload[r2]);
                if (m == 15) going = 0;                /* BR: unconditional, target unknown */
                else a += len;
            } else if (o->op == 0x45 || o->op == 0x4D) {  /* BAL, BAS: call, then return */
                int x = img[a + 1] & 0xf, b = (img[a + 2] >> 4) & 0xf;
                int d = ((img[a + 2] & 0xf) << 8) | img[a + 3];
                if (x == 0 && b > 0 && rbase[b] >= 0) rq_push(rbase[b] + d);
                a += len;
            } else if ((reach_mode & RCH_BALR) && o->op == 0x05
                       && (img[a + 1] & 0xf) == 0) {
                /* BALR Rn,0 -- the prologue idiom, and here only where the walk
                 * actually arrived at it.  It OVERRIDES an existing base for
                 * that register, because it is the later fact about it:
                 * IGG08113 opens `BALR 15,0' / `B 32(0,15)', so R15 is 2 and the
                 * target is 000022, which is where the witness says the code
                 * starts.  Left at the entry-time R15 = 0 the target came out
                 * 000020 and the module reached 6 of 3,032 bytes. */
                int rn = (img[a + 1] >> 4) & 0xf;
                if (rn) { rbase[rn] = a + 2; nr_balrbase++; }
                a += len;
            } else if ((reach_mode & RCH_LR) && o->op == 0x18) {
                /* LR Rx,Ry COPIES A BASE, and three of the nine modules that
                 * reached almost nothing need exactly this and nothing else.
                 * IGCFR10D, IKJEGSTA and IECVERPL open `LR Rn,15' and carry NO
                 * `BALR Rn,0' anywhere in the section -- not a lost base, but a
                 * module that never needed one, because R15 holds the entry
                 * address by MVS linkage convention and the code copies it.
                 * Invisible to a prologue scanner by construction, and exact
                 * rather than heuristic: one instruction, one register. */
                int r1 = (img[a + 1] >> 4) & 0xf, r2 = img[a + 1] & 0xf;
                if (r1 && rbase[r2] >= 0) { rbase[r1] = rbase[r2]; nr_lrbase++; }
                a += len;
            } else {
                /* A REGISTER LOADED FROM AN ADDRESS CONSTANT the RLD resolves
                 * into this section is a base with ground truth -- it is
                 * --infer's `rld' evidence kind, the one a later reader can
                 * re-judge against the object.  Discovered here during the walk
                 * rather than pre-scanned, because it needs a resolved base of
                 * its own to find the adcon at all. */
                if (o->op == 0x58) {                             /* L R1,D2(X2,B2) */
                    int r1 = (img[a + 1] >> 4) & 0xf, x = img[a + 1] & 0xf;
                    int b = (img[a + 2] >> 4) & 0xf;
                    int d = ((img[a + 2] & 0xf) << 8) | img[a + 3];
                    /* Remembered whatever the index says, because the TABLE's
                     * origin is base+displacement and the index only chooses
                     * within it.  Cleared nowhere else, which is the honest
                     * limit: a register written by something other than L keeps
                     * a stale load address until the next L overwrites it. */
                    if (r1) rload[r1] = (b > 0 && rbase[b] >= 0) ? rbase[b] + d : -1;
                    if (!(reach_mode & RCH_RLD)) { a += len; continue; }
                    if (r1 && x == 0 && b > 0 && rbase[b] >= 0) {
                        long src = rbase[b] + d;
                        int had = rbase[r1] >= 0;
                        const struct rlditem *ri = rld_at(src);
                        if (ri && ri->r == sect_esdid && ri->len == 4) {
                            long v = 0; int q;
                            for (q = 0; q < 4; q++) v = (v << 8) | img[src + q];
                            v -= sect_org;    /* ri->r == sect_esdid above */
                            /* Counted apart, because "fired and added
                             * nothing" has TWO mechanisms a byte count cannot
                             * separate: the register may already have had a base
                             * -- redundancy, which need not hold where the walk
                             * reaches less, as it will on the 772 -- or the
                             * target may be data, which is the deliverable's own
                             * reasoning and does transfer. */
                            if (v >= 0 && v < sect_len) {
                                rbase[r1] = v; nr_rldbase++;
                                if (!had) nr_rldnew++;
                            }
                        }
                    }
                }
                a += len;                              /* everything else falls through */
            }
        }
    }
}

/* Reported per module, and the coverage line is the point: with SD a root every
 * section HAS one, so "has a root" stops discriminating and only `dark' carries
 * meaning.  A pass that found one root and stopped otherwise reads exactly like
 * a module that is mostly data. */
static long reach_reached, reach_runs;

static void reach_compute(void)
{
    long i;
    int r;

    memset(rch, 0, (size_t)sect_len);
    memset(rseen, 0, (size_t)sect_len);
    nrq = 0;
    for (r = 0; r < 16; r++) rbase[r] = -1;
    /* R15 is the only base SEEDED.  Every other base is discovered by the walk,
     * and that is not a refinement -- a pre-scan for `BALR Rn,0' reads the whole
     * section including its data, and IECVERPL carries X'05A0' at 000244 inside
     * a table.  Pre-scanned, that phantom claimed R10, and the REAL `LR 10,15'
     * at offset 0 was then refused because the register already had a base: the
     * module reached 232 of 1,064 bytes for a reason that is not in the module.
     * It is --infer's measured phantom-prologue limit arriving in the traversal,
     * and the traversal has an answer --infer does not: a BALR that is never
     * REACHED never sets anything.  Evidence that had to be walked to is
     * evidence about code.
     *
     * THE CASE THAT PROVOKED THIS WAS NOT A PHANTOM, and the peer corrected it
     * from the listing: IECVERPL's X'05A0' at 000244 is a REAL `BALR R10,0' at
     * a SECOND ENTRY POINT -- an ESTAE exit establishing its own base for the
     * register the front end loads with `LR 10,15'.  So the defect was a
     * pre-scan adopting a base belonging to a DIFFERENT ENTRY PATH and applying
     * it from offset 0: a per-path base case, not a phantom.  The rule stands
     * and its evidence changed.  BLSCAMER carries six halfwords in bytes the
     * witness calls DATA that decode as prologues -- X'0590' at 052A, 0536 and
     * 0542, X'05D0' at 0552 and 0586, X'05E0' at 0566 -- and those are what a
     * pre-scan adopts and a walk never reaches. */
    if (reach_mode & RCH_R15) rbase[15] = 0;

    nr_sd = nr_ld = nr_end = nr_rldbase = nr_rldnew = nr_lrbase = nr_balrbase = 0;
    nr_acon = nr_acontab = 0;
    for (r = 0; r < 16; r++) rload[r] = -1;
    rq_push(0); nr_sd = 1;                             /* SD: the section origin */
    for (i = 0; i < nld; i++)
        if (ld[i].owner == sect_esdid && ld[i].addr >= 0 && ld[i].addr < sect_len) {
            rq_push(ld[i].addr); nr_ld++;
        }
    if (!from_member && end_has_entry && end_entry >= 0 && end_entry < sect_len) {
        rq_push(end_entry); nr_end = 1;
    }

    reach_walk();

    reach_reached = reach_runs = 0;
    for (i = 0; i < sect_len; i++) {
        if (!rch[i]) continue;
        reach_reached++;
        if (i == 0 || !rch[i - 1]) reach_runs++;
    }
}

static int reach_report(FILE *o)
{
    long i;

    reach_compute();
    fprintf(o, "REACH %s len=%ld roots=%d sd=%d ld=%d end=%d "
               "reached=%ld dark=%ld runs=%ld acon=%d acontab=%d balrbase=%d rldbase=%d "
               "rldnew=%d lrbase=%d base=%s%s\n",
            sect_name, sect_len, nr_sd + nr_ld + nr_end, nr_sd, nr_ld, nr_end,
            reach_reached, sect_len - reach_reached, reach_runs, nr_acon, nr_acontab,
            nr_balrbase, nr_rldbase, nr_rldnew, nr_lrbase,
            (reach_mode & RCH_R15) ? "r15" : "-",
            (reach_mode & RCH_BALR) ? "+balr" : "");
    for (i = 0; i < sect_len; i++)
        if (rch[i] && (i == 0 || !rch[i - 1])) {
            long j = i;
            while (j < sect_len && rch[j]) j++;
            fprintf(o, "REACHRUN %06lX %ld\n", (unsigned long)i, j - i);
        }
    return 0;
}

/* ------------------------------------------------------------ align-diff -- */

/* #384.  Two objects of the same CSECT at different maintenance levels, BOTH
 * DISASSEMBLED, aligned statement by statement so that a shift is reported as a
 * consequence of a length change and not as a change of its own.
 *
 * THE KEY IS THE STATEMENT WITH ITS DISPLACEMENTS MASKED, and everything rests
 * on that: a statement's identity has to survive a shift, or every statement
 * after an insertion reads as a change and a one-insertion pair reports six
 * differences instead of one.
 *
 * It is built from the BYTES and not from the text this tool prints.  Our own
 * output embeds the offset in a manufactured label -- `A(L000410)' -- so a
 * shifted internal adcon would change its own key, and a second reader of our
 * format has cost this project twice in one day (a comment card read as an
 * instruction, and a predicate error of the same family).  The walk has the
 * structure; it is taken from there.
 *
 * WHAT A DELTA IS COMPARED AGAINST is the CUMULATIVE SHIFT FUNCTION, computed
 * from the alignment itself: for a matched pair, shift = cand.at - ref.at.  The
 * offsets already contain everything, including the ALIGNMENT PADDING that no
 * list of detected insertions carries -- two insertions of 2 and 4 bytes move
 * every displacement by 8, because the 2-byte one pushed the data area off its
 * fullword boundary.  A prefix sum over detected code insertions gives 6 there,
 * and every displacement in the module would be reported as a constant change:
 * a whole module of findings where there are none.
 *
 * So a displacement delta is a CONSEQUENCE exactly when it is in the shift
 * function's value set, which has at most one value per length change -- about
 * ten for a median module and 266 for the worst in the caller's corpus.  The
 * test never asks where a shift sits relative to an insertion, because it
 * cannot: measured on the first constructed case, the shift at 000002 PRECEDES
 * its cause at 000006, the instruction addressing data past the insertion point.
 * Position relative to the change is not evidence.
 *
 * THE LIMIT, stated per module rather than assumed away: the exact rule is
 * delta == shift(T) - shift(B), and without a USING the disassembly has no B.
 * Where the base is established before every change shift(B) is 0 and the rule
 * is exact; where a change precedes the prologue the base moves too and the test
 * is weaker.  On the caller's list that is not exotic -- 30-odd modules diverge
 * at offset 0, where nothing precedes the prologue at all -- so the report says
 * which case each module is in. */

/* The alignment's edit-distance bound.  The trace is (D+1)(D+2)/2 ints, so
 * 20000 is a 800 MB worst case and a measured 160 MB on the largest module in
 * the caller's list (ICBMSG56, 6,942 statements against 32,578 bytes, D 316).
 * Eight of the 140 eyecatcher modules exceeded 3000 and all eight complete
 * here; the bound exists so that a pathological pair is ABANDONED rather than
 * approximated, because an alignment that had to guess produces findings
 * indistinguishable from the real ones. */
#define ALIGN_MAXD 20000
#define FNV_INIT 1469598103934665603ULL

enum { AS_INSN = 0, AS_ADCON, AS_DATA };

struct astmt {
    long at;                    /* offset in its own section */
    long len;
    int  kind;
    unsigned long long kh;      /* the key: what makes two statements the same one */
    char op[8];                 /* mnemonic, or DC / DS -- for the report */
    char tgt[9];                /* an adcon's target section */
    int  fmt;
    int  external;              /* an adcon against another section */
    int  nd;                    /* displacement fields carried, 0..2 */
    int  db[2], dd[2];
    long val;                   /* an internal adcon's target offset */
    char opnd[OPNDBUF];         /* operand text, for the report only */
};

struct aside {
    struct astmt *st;
    int n, cap;
    unsigned char *img, *cov;   /* the section's own bytes, kept past the reset */
    long len;
    char name[9];
    const char *path;
    int  member;
    long first_balr;            /* the first BALR Rn,0, or -1 */
};

static struct aside *acoll;     /* non-NULL exactly while walk_section collects */

static unsigned long long fnv(const void *p, size_t n, unsigned long long h)
{
    const unsigned char *b = p;
    while (n--) { h ^= *b++; h *= 1099511628211ULL; }
    return h;
}

static struct astmt *acoll_new(void)
{
    struct aside *s = acoll;
    if (s->n == s->cap) {
        int nc = s->cap ? s->cap * 2 : 256;
        struct astmt *t = realloc(s->st, (size_t)nc * sizeof *t);
        if (!t) { fprintf(stderr, "dasm370: out of memory collecting statements\n"); exit(16); }
        s->st = t; s->cap = nc;
    }
    memset(&s->st[s->n], 0, sizeof s->st[0]);
    return &s->st[s->n++];
}

/* Where the displacement fields sit, by format.  The base nibble STAYS in the
 * key -- a different base register is a different statement -- and only the 12
 * bits that move are cleared. */
static void mask_disp(unsigned char *t, int fmt)
{
    switch (fmt) {
    case F_RX: case F_BC: case F_RS: case F_SI: case F_S:
        t[2] &= 0xf0; t[3] = 0; break;
    case F_SS:
        t[2] &= 0xf0; t[3] = 0; t[4] &= 0xf0; t[5] = 0; break;
    default: break;
    }
}

static int disp_of(const unsigned char *b, int fmt, int *bs, int *ds)
{
    switch (fmt) {
    case F_RX: case F_BC: case F_RS: case F_SI: case F_S:
        bs[0] = (b[2] >> 4) & 0xf; ds[0] = ((b[2] & 0xf) << 8) | b[3];
        return 1;
    case F_SS:
        bs[0] = (b[2] >> 4) & 0xf; ds[0] = ((b[2] & 0xf) << 8) | b[3];
        bs[1] = (b[4] >> 4) & 0xf; ds[1] = ((b[4] & 0xf) << 8) | b[5];
        return 2;
    default:
        return 0;
    }
}

static void collect_insn(long a, const struct opc *o, int len, const char *opnd)
{
    struct astmt *s = acoll_new();
    unsigned char t[6];
    s->at = a; s->len = len; s->kind = AS_INSN; s->fmt = o->fmt;
    snprintf(s->op, sizeof s->op, "%s", o->name);
    snprintf(s->opnd, sizeof s->opnd, "%s", opnd);
    s->nd = disp_of(img + a, o->fmt, s->db, s->dd);
    memcpy(t, img + a, (size_t)len);
    mask_disp(t, o->fmt);
    s->kh = fnv(t, (size_t)len, FNV_INIT);
    /* The prologue base, for the per-module statement about shift(B).  BALR
     * Rn,0 is the IDIOM and not the declaration -- #382 measured that and it is
     * a limit, not a defect -- so this is used to say the test is WEAK, never to
     * resolve an address. */
    if (o->fmt == F_RR && !strcmp(o->name, "BALR") && (img[a + 1] & 0xf) == 0
        && acoll->first_balr < 0)
        acoll->first_balr = a;
}

static void collect_adcon(long a, const struct rlditem *r)
{
    struct astmt *s = acoll_new();
    char k[24];
    long v = 0;
    int i;
    s->at = a; s->len = r->len; s->kind = AS_ADCON;
    snprintf(s->op, sizeof s->op, "DC");
    for (i = 0; i < r->len; i++) v = (v << 8) | img[a + i];
    s->external = (r->r != sect_esdid);
    /* Own-section only: an external adcon's text is an addend against another
     * symbol and this section's origin is not part of it (cc370#415). */
    if (!s->external) v -= sect_org;
    s->val = v;
    if (!s->external) snprintf(s->tgt, sizeof s->tgt, "*");
    else if (r->r > 0 && r->r < MAXESD && esdname[r->r][0])
        snprintf(s->tgt, sizeof s->tgt, "%s", esdname[r->r]);
    else snprintf(s->tgt, sizeof s->tgt, "?%d", r->r);
    /* The key names the TARGET and the width and never the value.  An internal
     * adcon's value is precisely the thing that shifts; an external one's is an
     * addend in a deck and a binder-resolved address in a bound member, which
     * are two different quantities and not comparable across the pair. */
    snprintf(k, sizeof k, "A:%s:%d", s->tgt, (int)r->len);
    s->kh = fnv(k, strlen(k), FNV_INIT);
    snprintf(s->opnd, sizeof s->opnd, "%s(%s)", s->external ? "V" : "A", s->tgt);
}

static void collect_data(long a, long n)
{
    struct astmt *s = acoll_new();
    s->at = a; s->len = n; s->kind = AS_DATA;
    snprintf(s->op, sizeof s->op, "%s", cov[a] ? "DC" : "DS");
}

/* Adjacent data statements are ONE run, and the key is the run's bytes.
 *
 * Without this the report is manufactured: walk_section cuts a DC at 16 bytes
 * from the run's start, so shifting a data area by two bytes gives every card in
 * it different content while the data is identical -- and the 218 eyecatcher
 * modules would each report dozens of constant changes, failing the acceptance
 * on a classifier that is working correctly.  A run carries its coverage too: a
 * hole is not a run of zeroes, and merging the two would lose that. */
static void coalesce_data(struct aside *s)
{
    int i = 0, o = 0;
    while (i < s->n) {
        if (s->st[i].kind != AS_DATA) { s->st[o++] = s->st[i++]; continue; }
        {
            struct astmt r = s->st[i];
            long j;
            i++;
            while (i < s->n && s->st[i].kind == AS_DATA && s->st[i].at == r.at + r.len)
                r.len += s->st[i++].len;
            r.kh = FNV_INIT;
            for (j = r.at; j < r.at + r.len; j++) {
                unsigned char tok[2];
                tok[0] = s->cov[j];
                tok[1] = s->cov[j] ? s->img[j] : 0;
                r.kh = fnv(tok, 2, r.kh);
            }
            snprintf(r.opnd, sizeof r.opnd, "%ld byte%s", r.len, r.len == 1 ? "" : "s");
            s->st[o++] = r;
        }
    }
    s->n = o;
}

static void walk_section(void)
{
    long a = 0;
    int ev = 0, af = 0, nt = 0;

    while (a < sect_len) {
        const struct rlditem *r;
        long fl;
        /* A failed anchor, written where it failed.  The disassembly continues:
         * the point of --anchors=report is to say WHERE the module and the
         * source derived from part company, and stopping at the first one
         * answers that with a return code instead of with an offset. */
        /* A note that names an offset is written at it, beside the anchor
         * failures, because a divergence report is only useful where it happened. */
        while (nt < nhnote && hnotes[nt].has_at && hnotes[nt].at <= a) {
            emit_comment(hnotes[nt].text);
            nt++;
        }
        while (af < nafail && afails[af].at <= a) {
            char t[320], got[2 * MAXHB + 1], wnt[2 * MAXHB + 1];   /* two 128-char hex strings fit; emit() trims to 69 */
            hexbytes(img + afails[af].at, afails[af].n, got);
            hexbytes(afails[af].want, afails[af].n, wnt);
            snprintf(t, sizeof t, "ANCHOR FAILED %06lX module %s derived %s",
                     (unsigned long)afails[af].at, got, wnt);
            emit_comment(t);
            af++;
        }
        /* `<= a' and not `== a': every offset an event sits on was marked in
         * stbrk[] and refused where it could not begin a statement, so this should
         * always land exactly.  Late is still better than lost. */
        while (ev < nuev && uevs[ev].at <= a) {
            const struct hbase *u = &hbas[uevs[ev].u];
            char t[LABBUF + 8];
            if (uevs[ev].open) {
                char nm[LABBUF];
                label_name(u->baseval, nm);
                snprintf(t, sizeof t, "%s,%d", nm, u->reg);
                emit("", "USING", t, "");
            } else {
                snprintf(t, sizeof t, "%d", u->reg);
                emit("", "DROP", t, "");
            }
            ev++;
        }
        if (!cov[a]) {                             /* a hole is a hole, not a zero */
            long n = 1;
            while (a + n < sect_len && !cov[a + n] && !lab[a + n] && !stbrk[a + n]) n++;
            if (collecting) collect_data(a, n);
            emit_ds_hole(a, n);
            a += n;
            continue;
        }
        if ((r = rld_at(a)) != NULL) {
            if (collecting) collect_adcon(a, r);
            emit_adcon(a, r); a += r->len; continue;
        }
        if ((fl = hfill_at(a)) > 0) {
            if (collecting) collect_data(a, fl);
            emit_fill(a, fl); a += fl; continue;
        }
        if (!hin_data(a)) {
            const struct opc *o;
            int mask = (img[a + 1] >> 4) & 0xf, ismask = 0, len;
            char opnd[OPNDBUF];
            /* An instruction is halfword-aligned: the hardware requires it
             * and the assembler enforces it, so a decode at an ODD offset
             * is not an instruction however well it re-encodes.  ICKTR02
             * holds `4040 4040' -- four blanks -- at X'1287', which came
             * back as `STH 4,64(0,4)' and which as370 then moved to X'1288',
             * shifting the section by one byte from there on. */
            o = (a + 1 < sect_len && (a % 2) == 0)
                ? find_op(img[a], img[a + 1], mask, &ismask) : NULL;
            len = o ? ins_len_of(o->fmt) : 0;
            if (o && a + len <= sect_len && !rld_overlaps(a, len)
                && reencode_ok(o, img + a, len)
                && operands(o, img + a, a, opnd, sizeof opnd)) {
                int k, split = 0;
                for (k = 1; k < len; k++) if (lab[a + k] || stbrk[a + k]) split = 1;
                for (k = 0; k < len; k++) if (!cov[a + k]) split = 1;
                if (!split) {
                    char l[LABBUF], rem[32];
                    /* A BC is a branch by its FORMAT, so its second operand is a
                     * target and not data -- which is exactly what cannot be
                     * said of an RX instruction without a per-mnemonic column
                     * opc_table.h does not carry, and inventing one here is the
                     * second copy #374 exists to prevent.  So BC alone plants a
                     * label, and it plants it only where a hint USING already
                     * gave the register a lifetime. */
                    if (scanning && o->fmt == F_BC && nhbas) {
                        int b2 = (img[a + 2] >> 4) & 0xf;
                        const struct hbase *u = base_at(a, b2);
                        if (u) {
                            long tgt = u->baseval + (((img[a + 2] & 0xf) << 8) | img[a + 3]);
                            if (tgt >= 0 && tgt < sect_len && (tgt % 2) == 0
                                && cov[tgt] && !lab[tgt]) { lab[tgt] = 1; lab_changed = 1; }
                        }
                    }
                    if (lab[a]) label_name(a, l); else l[0] = 0;
                    sprintf(rem, "%06lX", (unsigned long)a);
                    if (collecting) collect_insn(a, o, len, opnd);
                    emit(l, o->name, opnd, rem);
                    a += len;
                    continue;
                }
            }
        }
        {                                          /* nothing else fits: DC */
            long n = 1;
            while (a + n < sect_len && cov[a + n] && !lab[a + n] && !stbrk[a + n]
                   && !rld_at(a + n) && !hfill_at(a + n) && n < 16) n++;
            if (collecting) collect_data(a, n);
            emit_dc_hex(a, (int)n);
            a += n;
        }
    }
    while (nt < nhnote) { if (hnotes[nt].has_at) emit_comment(hnotes[nt].text); nt++; }
    /* A DROP whose `to' is the section's end has no statement to precede. */
    while (ev < nuev) {
        if (!uevs[ev].open) {
            char t[16];
            sprintf(t, "%d", hbas[uevs[ev].u].reg);
            emit("", "DROP", t, "");
        }
        ev++;
    }
}

/* ----------------------------------------------------- align-diff, run -- */

/* One side: load it, keep its bytes past the reset, and collect the statements
 * the disassembler would PRINT -- same loader, same labels, same walk.  Nothing
 * downstream may read img[] or esdname[], because the next load clears both. */
static int align_load(struct aside *s, const char *path, const char *want)
{
    int rc;
    memset(s, 0, sizeof *s);
    s->first_balr = -1;
    s->path = path;
    if ((rc = load_section(path, want, 1)) != 0) return rc;
    /* A HOLE IS ZERO HERE, and that is the difference between comparing two
     * modules and comparing two input formats.  A deck says which bytes no TXT
     * card covered; a bound member cannot say it, because the binder filled them
     * before it wrote the member.  So against a member every such hole is a
     * difference that belongs to the transport.
     *
     * Measured on the 30 control CSECTs, all of which the caller has as
     * `identical': BLSRENQK's deck holds `DS XL2' at 000942 where the member
     * holds X'0000', and 23 of the 30 reported findings on byte-equal sections
     * because of it.  It is worse than one statement each, because the hole also
     * RESETS THE PHASE of the 16-byte DC run -- and walk_section attempts an
     * instruction decode at every chunk start.  In the member 000974 sat inside
     * a chunk; in the deck the hole made it a chunk start and X'7FFFFFFF' came
     * back as `SU 15,4095(15,15)'.  One transport artifact, an invented
     * instruction in a data area.
     *
     * Filling to zero is what the binder does, so the deck is read as the member
     * form of itself.  A member whose hole is NOT zero still differs, and says
     * so, which is the case worth keeping. */
    {
        long z;
        for (z = 0; z < sect_len; z++) if (!cov[z]) { img[z] = 0; cov[z] = 1; }
    }
    s->len = sect_len;
    s->member = from_member;
    memcpy(s->name, sect_name, sizeof s->name);
    s->img = malloc((size_t)(sect_len ? sect_len : 1));
    s->cov = malloc((size_t)(sect_len ? sect_len : 1));
    if (!s->img || !s->cov) { fprintf(stderr, "dasm370: out of memory reading %s\n", path); return 16; }
    memcpy(s->img, img, (size_t)sect_len);
    memcpy(s->cov, cov, (size_t)sect_len);
    derive_labels();
    acoll = s;
    collecting = 1;
    walk_section();
    collecting = 0;
    acoll = NULL;
    coalesce_data(s);
    return 0;
}

struct apair { int i, j; };

/* Myers' O(ND) diff over the keys.  D is the number of insertions plus
 * deletions, which is small by construction here -- these are two maintenance
 * levels of one module, and the displacements are masked out of the key -- so
 * the trace is d+1 ints per step and not a copy of the whole V array.
 *
 * ABANDONED rather than approximated past ALIGN_MAXD: an alignment that had to
 * guess would produce findings that look exactly like the real ones. */
static int align_lcs(const struct astmt *A, int n, const struct astmt *B, int m,
                     struct apair **out, int *nout)
{
    int max = n + m, off = max, d, k, x, y, D = -1;
    int *V = malloc((size_t)(2 * max + 1) * sizeof *V);
    int **tr = calloc((size_t)ALIGN_MAXD + 2, sizeof *tr);
    struct apair *pr = NULL;
    int np = 0, cap = 0;

    *out = NULL; *nout = 0;
    if (!V || !tr) { free(V); free(tr); return -2; }
    V[off + 1] = 0;
    for (d = 0; d <= max && d <= ALIGN_MAXD; d++) {
        if ((tr[d] = malloc((size_t)(d + 1) * sizeof **tr)) == NULL) { D = -2; break; }
        memset(tr[d], 0, (size_t)(d + 1) * sizeof **tr);
        for (k = -d; k <= d; k += 2) {
            if (k == -d || (k != d && V[off + k - 1] < V[off + k + 1])) x = V[off + k + 1];
            else x = V[off + k - 1] + 1;
            y = x - k;
            while (x < n && y < m && A[x].kh == B[y].kh) { x++; y++; }
            V[off + k] = x;
            tr[d][(k + d) / 2] = x;
            if (x >= n && y >= m) { D = d; break; }
        }
        if (D >= 0) break;
    }
    if (D >= 0) {
        x = n; y = m;
        for (d = D; d > 0; d--) {
            int pk, px, py;
            k = x - y;
            if (k - 1 < -(d - 1))      pk = k + 1;
            else if (k + 1 > (d - 1))  pk = k - 1;
            else pk = (tr[d - 1][(k - 1 + d - 1) / 2] < tr[d - 1][(k + 1 + d - 1) / 2]) ? k + 1 : k - 1;
            px = tr[d - 1][(pk + d - 1) / 2];
            py = px - pk;
            while (x > px && y > py) {
                if (np == cap) {
                    int nc = cap ? cap * 2 : 256;
                    struct apair *t = realloc(pr, (size_t)nc * sizeof *t);
                    if (!t) { free(pr); pr = NULL; D = -2; break; }
                    pr = t; cap = nc;
                }
                x--; y--;
                pr[np].i = x; pr[np].j = y; np++;
            }
            if (D < 0) break;
            x = px; y = py;
        }
        while (D >= 0 && x > 0 && y > 0) {
            if (np == cap) {
                int nc = cap ? cap * 2 : 256;
                struct apair *t = realloc(pr, (size_t)nc * sizeof *t);
                if (!t) { free(pr); pr = NULL; D = -2; break; }
                pr = t; cap = nc;
            }
            x--; y--;
            pr[np].i = x; pr[np].j = y; np++;
        }
    }
    for (d = 0; d <= ALIGN_MAXD + 1; d++) free(tr[d]);
    free(tr); free(V);
    if (D < 0) { free(pr); return D == -2 ? -2 : -1; }
    /* the walk above runs backwards */
    for (k = 0; k < np / 2; k++) {
        struct apair t = pr[k]; pr[k] = pr[np - 1 - k]; pr[np - 1 - k] = t;
    }
    *out = pr; *nout = np;
    return D;
}

static int shift_known(const long *v, int n, long q)
{
    int i;
    for (i = 0; i < n; i++) if (v[i] == q) return 1;
    return 0;
}

static void align_hex(FILE *o, const struct aside *s, long at, long n)
{
    long i, lim = n > 12 ? 12 : n;
    for (i = 0; i < lim; i++) {
        if (s->cov[at + i]) fprintf(o, "%02X", s->img[at + i]);
        else fputs("..", o);
    }
    if (n > lim) fputs("...", o);
}

/* Declared here because the gap reporter below is written before the JSON
 * primitives, which need `struct aside' complete. */
static void jfinding(const char *kind, const struct aside *R, long ra, long rl,
                     const char *rop, const char *ropnd,
                     const struct aside *C, long ca, long cl,
                     const char *cop, const char *copnd, const char *detail);

/* One gap in the alignment: statements in the reference that the candidate does
 * not have, statements the candidate has that the reference does not, or both.
 * Reported as ONE finding, because that is what it is -- a 17-byte eyecatcher
 * against a 25-byte one is one change and not two. */
static void align_gap(FILE *o, const struct aside *R, int i0, int i1,
                      const struct aside *C, int j0, int j1, int *ins, int *del,
                      int *dchg, int *chg)
{
    long rl = 0, cl = 0;
    int k, alldata = 1;
    const char *what;
    for (k = i0; k < i1; k++) { rl += R->st[k].len; if (R->st[k].kind != AS_DATA) alldata = 0; }
    for (k = j0; k < j1; k++) { cl += C->st[k].len; if (C->st[k].kind != AS_DATA) alldata = 0; }
    if (i0 == i1)      { what = "insert"; (*ins)++; }
    else if (j0 == j1) { what = "delete"; (*del)++; }
    else if (alldata)  { what = "data";   (*dchg)++; }
    else               { what = "change"; (*chg)++; }
    jfinding(what,
             R, i0 < i1 ? R->st[i0].at : (i0 < R->n ? R->st[i0].at : R->len), rl,
             i0 < i1 ? R->st[i0].op : NULL, i0 < i1 ? R->st[i0].opnd : NULL,
             C, j0 < j1 ? C->st[j0].at : (j0 < C->n ? C->st[j0].at : C->len), cl,
             j0 < j1 ? C->st[j0].op : NULL, j0 < j1 ? C->st[j0].opnd : NULL,
             NULL);
    fprintf(o, "FINDING %-6s ref %06lX %ld byte%s (%d stmt)  cand %06lX %ld byte%s (%d stmt)  %+ld\n",
            what,
            (unsigned long)(i0 < i1 ? R->st[i0].at : (i0 < R->n ? R->st[i0].at : R->len)), rl,
            rl == 1 ? "" : "s", i1 - i0,
            (unsigned long)(j0 < j1 ? C->st[j0].at : (j0 < C->n ? C->st[j0].at : C->len)), cl,
            cl == 1 ? "" : "s", j1 - j0,
            cl - rl);
    for (k = i0; k < i1; k++)
        fprintf(o, "    ref  %06lX %-5s %-24s  ",
                (unsigned long)R->st[k].at, R->st[k].op, R->st[k].opnd),
        align_hex(o, R, R->st[k].at, R->st[k].len), fputc('\n', o);
    for (k = j0; k < j1; k++)
        fprintf(o, "    cand %06lX %-5s %-24s  ",
                (unsigned long)C->st[k].at, C->st[k].op, C->st[k].opnd),
        align_hex(o, C, C->st[k].at, C->st[k].len), fputc('\n', o);
}

/* ------------------------------------------------- the repair contract -- */

/* #385 asks for JSON per divergence: the offset and length, both sides' bytes,
 * the owning statement's line and text, whether it is macro-generated and which
 * call owns it, and whether that statement RESERVES bytes (DS CL1) or only
 * ALIGNS (DS 0F).
 *
 * THE OBJECT CANNOT ANSWER THE LAST THREE AND THAT IS MEASURED, not assumed.  In
 * an object a DS 0F pad and a DS CL1 reservation are both bytes no TXT card
 * covers; two reasonable object-side rules over the 30 control CSECTs, against
 * 13,161 bytes with no object code, give 89 bytes and 1,788 for the same
 * population -- ONE PER CENT AGAINST FOURTEEN.  Two defensible methods that
 * cannot agree on the SIZE of a population is what "a source fact" means once it
 * is measured instead of asserted.
 *
 * So #385 became a TRANSLATOR rather than a second guess: as370 --stmts
 * (cc370#411) exports the statement the assembly generated, and --ref-stmts /
 * --cand-stmts read it back in.  Without one, `source' is null with
 * `source_absent' naming WHICH absence it is -- a schema that omitted the key
 * would read as though the question had not come up.
 *
 * THE ONE THING THAT DECIDED THIS FILE'S SHAPE: an offset is not a function.
 * Measured over 5,528 module sources and 7,671,248 export records -- ORG moves
 * the location counter backwards in 59,443 records across 3,758 modules, so
 * 5.97 % of claimed bytes are claimed by MORE THAN ONE statement, in 3,559 of
 * the 5,528.  A lookup that takes the first match is wrong on two thirds of the
 * corpus.
 *
 * AND "THE LAST CLAIMANT" IS NOT THE RULE EITHER -- it is the last that
 * RESERVES, and the difference was found in the control corpus rather than
 * reasoned about.  IEHPROG1's second section winds the counter back with
 * `ORG *-18', overwrites six statements and winds it forward again with a bare
 * `ORG'.  That forward ORG has an advance of +10, so it CLAIMS 4476..4485 and is
 * last in listing order -- but the deck there holds 50210000 92801000 0A14, the
 * ST, the MVI and the SVC, and the TXT cards agree from the other side: the
 * rewritten run is one card of 8 bytes at 4468 that stops short of 4476.  An ORG
 * moves over bytes and never writes them.  Measured by mvs38src over both
 * populations:
 *
 *                             the 30      the 832
 *   modules with an overlap       12          378
 *   overlapped offsets         3,266      189,227
 *   the plain rule is WRONG        45       53,328   (28.2 % of overlaps)
 *   the reserves rule is wrong      0            0
 *
 * KEYED ON `reserves' AND NOT ON THE OPERATION, and the five offsets that settle
 * that are in the 832: of the 53,328 last claimants that emit nothing, 53,323 are
 * ORG -- and FIVE ARE NOT.  HMASMREC's 13865 is claimed by `DC 0F'0'' and
 * IGE0704B's 170 by `ASCTAB DS 0F', both zero-duplication storage statements
 * sitting on bytes an earlier statement emitted.  "An ORG never outranks an
 * emitter" leaves those five standing; "the last claimant that reserves" catches
 * all 53,328.
 *
 * WHICH IS WHY cc370#414 HAD TO COME FIRST: before it every one of those ORGs
 * reported reserves=1, and nothing in the export could have told them apart. */

/* One exported statement.  `at' is SECTION-RELATIVE (loc - secorg): as370's loc
 * is module-absolute as the counter is, and a deck carries section-relative
 * offsets.  `len' is the counter's ADVANCE and not the bytes emitted -- it
 * includes alignment the statement forced, so a BR at an odd offset is 3 with
 * the pad as its first byte, and it is NEGATIVE at an ORG that moves back. */
struct sstmt {
    long at, len, org, stmt, mcall_stmt;
    int  cards, gen, mdepth, reserves, has_mcall;
    char mcall[16];
    char *text;
};

struct sside {
    const char *path;          /* the export file, as given */
    char  src[520];            /* its #source: the file a repair edits */
    struct sstmt *st;
    int   n;                   /* records kept for this section */
    int   total;               /* records in the file */
    int   loaded;
    long  bytes;               /* the export's own extent for this section */
    long  objbytes;            /* what the object says, for the comparison */
};

static struct sside sref, scand;   /* --ref-stmts / --cand-stmts */

static char *sdup(const char *s, size_t n)
{
    char *p = malloc(n + 1);
    if (!p) return NULL;
    memcpy(p, s, n); p[n] = 0;
    return p;
}

/* Split one tab-separated record IN PLACE.  The delimiter has to be read BEFORE
 * it is overwritten -- testing the byte after the NUL that replaced it reports
 * every field as the last one, which is how this first read a fourteen-column
 * header as one column called `sect'. */
static int ssplit(char *line, char **fld, int max)
{
    int n = 0;
    char *p = line, *q;
    while (n < max) {
        char d;
        q = strpbrk(p, "\t\r\n");
        if (!q) { fld[n++] = p; break; }
        d = *q; *q = 0; fld[n++] = p;
        if (d != '\t') break;
        p = q + 1;
    }
    return n;
}

/* Column indices are resolved BY NAME from the header row and never by
 * position.  Two columns were inserted into this export in one day and every
 * positional reader silently re-pointed; the fixture that caught it had been
 * keyed on names for exactly that reason. */
static int scol(char **name, int ncol, const char *want)
{
    int i;
    for (i = 0; i < ncol; i++) if (!strcmp(name[i], want)) return i;
    return -1;
}

/* A REFUSAL NAMES WHAT IT FOUND.  An export of the wrong module is the likely
 * mistake -- the file parses, the header is right, and every offset simply
 * misses -- so an empty section is reported with the names the file does carry
 * rather than as "no records". */
static int stmts_load(struct sside *s, const char *fn, const char *sect)
{
    FILE *f;
    char line[4096];
    char *name[64];
    int ncol = 0, cap = 0;
    int c_sn, c_so, c_org, c_cards, c_loc, c_len, c_stmt, c_gen, c_md, c_ms, c_mn, c_res, c_txt;
    char seen[16][9];
    int nseen = 0, i;

    if ((f = fopen(fn, "r")) == NULL) { perror(fn); return 16; }
    if (!fgets(line, sizeof line, f) || strncmp(line, "#as370-stmts\t", 13)) {
        fprintf(stderr, "dasm370: %s is not an as370 --stmts export -- its first line is\n"
                        "  %.70s%s", fn, line, strchr(line, '\n') ? "" : "\n");
        fclose(f); return 16;
    }
    if (strcmp(line + 13, "1\n")) {
        fprintf(stderr, "dasm370: %s is as370-stmts version %.20s; this build reads 1\n",
                fn, line + 13);
        fclose(f); return 16;
    }
    s->path = fn; s->src[0] = 0;
    while (fgets(line, sizeof line, f)) {
        if (!strncmp(line, "#source\t", 8)) {
            size_t n = strcspn(line + 8, "\r\n");
            if (n >= sizeof s->src) n = sizeof s->src - 1;
            memcpy(s->src, line + 8, n); s->src[n] = 0;
            continue;
        }
        if (line[0] == '#') continue;
        /* the first non-comment line is the column header */
        if (!ncol) {
            char *raw[64];
            int nr = ssplit(line, raw, 64), k;
            /* line[] is reused by the next fgets, so the header's names are
             * copied; the data fields below are consumed before that happens. */
            for (k = 0; k < nr; k++)
                if ((name[ncol++] = sdup(raw[k], strlen(raw[k]))) == NULL)
                    { fprintf(stderr, "dasm370: out of memory reading %s\n", fn); fclose(f); return 16; }
            c_sn = scol(name, ncol, "sectname"); c_so = scol(name, ncol, "secorg");
            c_org = scol(name, ncol, "org");     c_cards = scol(name, ncol, "cards");
            c_loc = scol(name, ncol, "loc");     c_len = scol(name, ncol, "len");
            c_stmt = scol(name, ncol, "stmt");   c_gen = scol(name, ncol, "gen");
            c_md = scol(name, ncol, "mdepth");   c_ms = scol(name, ncol, "mcall_stmt");
            c_mn = scol(name, ncol, "mcall_name"); c_res = scol(name, ncol, "reserves");
            c_txt = scol(name, ncol, "text");
            if (c_sn < 0 || c_so < 0 || c_org < 0 || c_cards < 0 || c_loc < 0 ||
                c_len < 0 || c_stmt < 0 || c_gen < 0 || c_md < 0 || c_ms < 0 ||
                c_mn < 0 || c_res < 0 || c_txt < 0) {
                fprintf(stderr, "dasm370: %s is missing a column this needs -- it has\n  ", fn);
                for (i = 0; i < ncol; i++) fprintf(stderr, "%s%s", i ? " " : "", name[i]);
                fputc('\n', stderr);
                fclose(f); return 16;
            }
            continue;
        }
        {
            char *fld[64];
            int nf;
            struct sstmt *e;
            nf = ssplit(line, fld, 64);
            if (nf <= c_txt) continue;              /* a short record is not a statement */
            s->total++;
            if (strcmp(fld[c_sn], sect)) {
                for (i = 0; i < nseen; i++) if (!strcmp(seen[i], fld[c_sn])) break;
                if (i == nseen && nseen < 16 && fld[c_sn][0])
                    { strncpy(seen[nseen], fld[c_sn], 8); seen[nseen][8] = 0; nseen++; }
                continue;
            }
            if (s->n == cap) {
                struct sstmt *g;
                cap = cap ? cap * 2 : 256;
                if ((g = realloc(s->st, (size_t)cap * sizeof *g)) == NULL) {
                    fprintf(stderr, "dasm370: out of memory reading %s\n", fn);
                    fclose(f); return 16;
                }
                s->st = g;
            }
            e = &s->st[s->n++];
            e->at   = strtol(fld[c_loc], NULL, 10) - strtol(fld[c_so], NULL, 10);
            e->len  = strtol(fld[c_len], NULL, 10);
            e->org  = strtol(fld[c_org], NULL, 10);
            e->cards = (int)strtol(fld[c_cards], NULL, 10);
            e->stmt = strtol(fld[c_stmt], NULL, 10);
            e->gen  = (int)strtol(fld[c_gen], NULL, 10);
            e->mdepth = (int)strtol(fld[c_md], NULL, 10);
            e->reserves = (int)strtol(fld[c_res], NULL, 10);
            e->has_mcall = fld[c_ms][0] != 0;
            e->mcall_stmt = e->has_mcall ? strtol(fld[c_ms], NULL, 10) : 0;
            strncpy(e->mcall, fld[c_mn], sizeof e->mcall - 1);
            e->mcall[sizeof e->mcall - 1] = 0;
            e->text = sdup(fld[c_txt], strlen(fld[c_txt]));
            if (!e->text) { fprintf(stderr, "dasm370: out of memory reading %s\n", fn); fclose(f); return 16; }
        }
    }
    fclose(f);
    for (i = 0; i < ncol; i++) free(name[i]);
    if (!s->n) {
        fprintf(stderr, "dasm370: %s has no statement in section %s.\n", fn, sect);
        if (nseen) {
            fprintf(stderr, "  It carries %d record%s in: ", s->total, s->total == 1 ? "" : "s");
            for (i = 0; i < nseen; i++) fprintf(stderr, "%s%s", i ? " " : "", seen[i]);
            fprintf(stderr, "%s\n", nseen == 16 ? " ..." : "");
            fprintf(stderr, "  An export of the wrong module parses cleanly and misses every offset.\n");
        } else fprintf(stderr, "  It carries %d record%s and names no section at all.\n",
                       s->total, s->total == 1 ? "" : "s");
        return 16;
    }
    /* THE EXPORT'S OWN EXTENT, against the object's.  A STALE export is the
     * mistake this cannot otherwise see: it parses, the header is right, the
     * section name matches and every offset looks plausible, because it belongs
     * to a different build of the same source.  The section's length is the one
     * scalar both sides state independently, so it is compared and reported --
     * not refused, because a caller may know better, but never in silence. */
    {
        int k;
        for (k = 0; k < s->n; k++) {
            long end = s->st[k].len > 0 ? s->st[k].at + s->st[k].len : s->st[k].at;
            if (end > s->bytes) s->bytes = end;
        }
    }
    s->loaded = 1;
    return 0;
}

/* The statement a repair edits, for one side and one range.
 *
 * `len' > 0 is a range of bytes: the owner is the last claimant of its FIRST
 * byte, because an ORG overlay means the deck holds what the last statement in
 * listing order wrote.  `covers' counts the distinct statements the whole range
 * touches, so a consumer knows when one finding spans several cards.
 *
 * `len' == 0 is an INSERTION POINT and not a range -- a delete populates
 * cand.offset with a zero length.  Nothing occupies it, so the statement
 * reported is the one that BEGINS there: the card an insertion goes before.
 *
 * AN INSERTION POINT NEED NOT FALL ON A SOURCE BOUNDARY.  A disassembly's
 * statement boundaries are the DECODER's, not the assembler's, so the offset can
 * land INSIDE a statement -- reported as that statement with
 * `chosen: "encloses"', which tells a repair the card has to be SPLIT.  A bare
 * absence would have said only that nothing was found.
 *
 * THE PROPERTY IS length == 0 AND NOT "inside", which is measured rather than
 * reasoned and is why three attempts at the fixture failed by pinning "inside".
 * Over the 832 (mvs38src, against this binary): 119,744 findings -- 119,035
 * reserving, 504 unreserved, 170 encloses in 63 modules, 31 zero-advance, 4 with
 * no owner at all.  EVERY encloses is length 0, and 2,168 findings of NON-zero
 * length also START inside their chosen statement while being correctly
 * reserving or unreserved.  The separation is exact in both directions.  The
 * real-material witness is ICBVUT01: a delete at 22030 inside `GROUPKY DS CL8'
 * at 22027.
 *
 * A STATEMENT WITH NO ADVANCE CANNOT OUTRANK ONE THAT HAS ONE, whatever the
 * listing order.  A USING, an EQU or a DROP sits at the same offset as the
 * statement after it and occupies nothing, so `last in listing order' would hand
 * an insertion point to a USING and report its `reserves' -- which is vacuous
 * where len is 0 and would read as "this statement occupies the bytes".  Over
 * the corpus 3,085,535 records are len 0 with reserves 1, so this is the common
 * case rather than a corner.  A zero-advance claimant is therefore only ever a
 * fallback, taken when nothing with an advance begins there. */
static const struct sstmt *stmts_owner(const struct sside *s, long at, long len,
                                       int *claimants, int *covers, int *encloses,
                                       int *unreserved)
{
    const struct sstmt *own = NULL, *any = NULL, *empty = NULL, *encl = NULL;
    int i, cl = 0, cv = 0;
    long last = -1;

    *claimants = 0; *covers = 0; *encloses = 0; *unreserved = 0;
    if (!s->loaded) return NULL;
    for (i = 0; i < s->n; i++) {
        const struct sstmt *e = &s->st[i];
        /* A NEGATIVE advance is an ORG moving the counter back.  It occupies
         * nothing and begins nothing: 59,443 such records over the corpus. */
        if (e->len < 0) continue;
        if (e->len == 0) {
            if (!len && e->at == at) empty = e;      /* fallback only */
            continue;
        }
        if (len) {
            if (at >= e->at && at < e->at + e->len) {
                any = e; if (e->reserves) own = e;
                cl++;
            }
            if (e->at < at + len && at < e->at + e->len) {
                if (e->at != last) { cv++; last = e->at; }
            }
        } else if (e->at == at) {
            any = e; if (e->reserves) own = e;
            cl++;
        }
        else if (at > e->at && at < e->at + e->len && e->reserves) encl = e;
    }
    if (!own) own = any;                      /* nothing reserves: say so below */
    if (!own && encl)  own = encl;
    if (!own && empty) { own = empty; cl = 1; }
    *claimants = cl;
    *covers = len ? cv : cl;
    *encloses = (own && own == encl);
    *unreserved = (own && own == any && !own->reserves);
    return own;
}

static FILE *jout;            /* #385: the repair contract, or NULL */
static int   jfirst = 1;

static void jstr(FILE *o, const char *s)
{
    fputc('"', o);
    for (; *s; s++) {
        unsigned char c = (unsigned char)*s;
        if (c == '"' || c == '\\') fprintf(o, "\\%c", c);
        else if (c < 0x20) fprintf(o, "\\u%04X", c);
        else fputc(c, o);
    }
    fputc('"', o);
}

/* NO "uncovered" MARKER, and that is measured rather than omitted.  align_load()
 * fills every byte no TXT card covered with zero before collecting -- a deck
 * records its holes and a bound member cannot, so against a member every hole is
 * a difference belonging to the transport.  By the time a finding is emitted
 * there are none left: 0 of 240,326 byte fields over the caller's 832 modules.
 * A branch for them here would be dead code that reads as a guarantee. */
static void jbytes(FILE *o, const unsigned char *img8, long at, long n)
{
    long i;
    fputc('"', o);
    for (i = 0; i < n && i < 64; i++) fprintf(o, "%02X", img8[at + i]);
    fputc('"', o);
}

/* `source' is this side's OWN half of the contract and lives beside the bytes it
 * describes, not at the document level: the two sides are two different modules
 * at two maintenance levels, so they have two different sources and a repair
 * edits one of them.  Null with `source_absent' where the side has no export or
 * no statement claims the offset -- naming WHICH absence it is, because "no
 * export was given" and "the export has a hole here" call for different actions
 * and a bare null cannot tell them apart. */
static void jsource(FILE *o, const struct sside *S, long at, long len)
{
    const struct sstmt *e;
    int claimants, covers, encloses, unreserved;

    if (!S->loaded) { fputs(",\"source\":null,\"source_absent\":\"no-statement-export\"", o); return; }
    e = stmts_owner(S, at, len, &claimants, &covers, &encloses, &unreserved);
    if (!e) { fputs(",\"source\":null,\"source_absent\":\"no-owning-statement\"", o); return; }
    fputs(",\"source\":{\"file\":", o); jstr(o, S->src);
    fprintf(o, ",\"org\":%ld,\"cards\":%d,\"stmt\":%ld", e->org, e->cards, e->stmt);
    fprintf(o, ",\"gen\":%s,\"mdepth\":%d", e->gen ? "true" : "false", e->mdepth);
    if (e->has_mcall) {
        fprintf(o, ",\"mcall_stmt\":%ld,\"mcall_name\":", e->mcall_stmt);
        jstr(o, e->mcall);
    } else fputs(",\"mcall_stmt\":null,\"mcall_name\":null", o);
    /* VACUOUS WHERE THE STATEMENT HAS NO ADVANCE, and null rather than false,
     * because false reads as "these bytes are alignment" and there are no bytes.
     * 3,085,535 records over the corpus are in that state -- a USING, an EQU, a
     * DROP, an already-aligned DS 0F -- so it is the common case. */
    if (e->len == 0) fputs(",\"reserves\":null", o);
    else fprintf(o, ",\"reserves\":%s", e->reserves ? "true" : "false");
    fputs(",\"text\":", o); jstr(o, e->text);
    /* THE STATEMENT'S OWN SPAN, and not the finding's.  They differ whenever a
     * finding starts inside a statement or runs across several, and a consumer
     * that assumes they agree edits the wrong number of bytes. */
    fprintf(o, ",\"stmt_offset\":%ld,\"stmt_length\":%ld", e->at, e->len);
    /* claimants > 1 means an ORG overlay put several statements on this offset
     * and the LAST in listing order was taken, because that is what the deck
     * holds.  5.97 % of claimed bytes over the corpus are in that state. */
    fprintf(o, ",\"claimants\":%d,\"chosen\":\"%s\",\"covers\":%d}", claimants,
            encloses    ? "encloses"
            : unreserved ? "unreserved"
            : e->len > 0 ? "reserving" : "zero-advance", covers);
}

static void jside(FILE *o, const char *tag, const struct aside *s,
                  long at, long len, const char *op, const char *opnd,
                  const struct sside *S)
{
    fprintf(o, "\"%s\":{\"offset\":%ld,\"length\":%ld,\"bytes\":", tag, at, len);
    if (len > 0) jbytes(o, s->img, at, len); else fputs("\"\"", o);
    if (op) {
        fputs(",\"statement\":{\"op\":", o); jstr(o, op);
        fputs(",\"operands\":", o); jstr(o, opnd ? opnd : "");
        fputs(",\"from\":\"disassembly\"}", o);
    } else fputs(",\"statement\":null", o);
    jsource(o, S, at, len);
    fputc('}', o);
}

static void jfinding(const char *kind, const struct aside *R, long ra, long rl,
                     const char *rop, const char *ropnd,
                     const struct aside *C, long ca, long cl,
                     const char *cop, const char *copnd,
                     const char *detail)
{
    if (!jout) return;
    fprintf(jout, "%s\n    {\"kind\":", jfirst ? "" : ",");
    jfirst = 0;
    jstr(jout, kind);
    fputc(',', jout); jside(jout, "ref", R, ra, rl, rop, ropnd, &sref);
    fputc(',', jout); jside(jout, "cand", C, ca, cl, cop, copnd, &scand);
    fprintf(jout, ",\"delta\":%ld", cl - rl);
    if (detail) { fputs(",\"detail\":", jout); jstr(jout, detail); }
    /* The REASON an export is absent is a property of the build and not of the
     * finding, so it is stated once at the document level; each side carries the
     * per-finding fact and a key naming which absence it is.  The caller measured
     * the cost of repeating the reason: 265 characters on each of 120,163
     * findings is 31.8 MB of 77.5, two fifths of the corpus output, identical in
     * every record. */
    fputc('}', jout);
}

static const char *json_fn;   /* #385: --json FILE */
static const char *ref_stmts_fn, *cand_stmts_fn;   /* #385: --ref-stmts / --cand-stmts */

/* What each side was given, so a consumer can tell "no export" from "an export
 * that matched nothing" without re-reading the file.  `records' is what the file
 * held and `section' what survived the section filter: the two apart are the
 * only warning that an export of the right module was read for the wrong
 * section, which parses cleanly and misses every offset. */
static void jstmts_side(const char *tag, const struct sside *S)
{
    fprintf(jout, "\"%s\": ", tag);
    if (!S->loaded) { fputs("null", jout); return; }
    fputs("{\"export\": ", jout); jstr(jout, S->path);
    fputs(", \"source\": ", jout); jstr(jout, S->src);
    fprintf(jout, ", \"records\": %d, \"section\": %d", S->total, S->n);
    fprintf(jout, ", \"section_bytes\": %ld, \"object_bytes\": %ld, \"matches_object\": %s}",
            S->bytes, S->objbytes, S->bytes == S->objbytes ? "true" : "false");
}

static int align_run(const char *refp, const char *candp, const char *want, const char *outfn)
{
    struct aside R, C;
    struct apair *pr = NULL;
    long *sv = NULL;
    int nsv = 0, np = 0, D, rc = 0, i, j, k, pi, pj;
    int ins = 0, del = 0, dchg = 0, chg = 0, cons = 0, same = 0, weak = 0;
    long firstchange = -1;
    /* 24, and the arithmetic closes: an unsigned long is at most 16 hex digits,
     * so "%06lX" writes at most 16 characters plus the NUL.  16 did not close it
     * and gcc said so with _FORTIFY_SOURCE on -- a warning this project's Macs
     * cannot see, because neither clang nor gcc-16 here defines it. */
    char firstbuf[24];
    FILE *o;

    if ((rc = align_load(&R, refp, want)) != 0) return rc;
    if ((rc = align_load(&C, candp, want)) != 0) { free(R.st); free(R.img); free(R.cov); return rc; }

    /* The exports are read HERE and not at option time, because the section
     * filter needs the name the object actually carries.  A refusal here is a
     * refusal of the whole run: an export that names no statement in this
     * section would silently make every finding read `no-owning-statement',
     * which is the one wrong answer that looks like a measurement. */
    if (ref_stmts_fn  && (rc = stmts_load(&sref,  ref_stmts_fn,  R.name)) != 0) return rc;
    if (cand_stmts_fn && (rc = stmts_load(&scand, cand_stmts_fn, C.name)) != 0) return rc;
    sref.objbytes = R.len; scand.objbytes = C.len;
    if (sref.loaded && sref.bytes != R.len)
        fprintf(stderr, "dasm370: %s covers %ld bytes of %s, the object %ld -- a STALE export\n"
                        "  parses, matches the section name and misses every offset\n",
                ref_stmts_fn, sref.bytes, R.name, R.len);
    if (scand.loaded && scand.bytes != C.len)
        fprintf(stderr, "dasm370: %s covers %ld bytes of %s, the object %ld -- a STALE export\n"
                        "  parses, matches the section name and misses every offset\n",
                cand_stmts_fn, scand.bytes, C.name, C.len);

    D = align_lcs(R.st, R.n, C.st, C.n, &pr, &np);

    o = outfn ? fopen(outfn, "w") : stdout;
    if (!o) { perror(outfn); return 16; }

    fprintf(o, "ALIGN-DIFF %s\n", R.name);
    fprintf(o, "  ref  %-8s %6ld bytes %5d stmt  %-6s %s\n",
            R.name, R.len, R.n, R.member ? "member" : "deck", R.path);
    fprintf(o, "  cand %-8s %6ld bytes %5d stmt  %-6s %s\n",
            C.name, C.len, C.n, C.member ? "member" : "deck", C.path);
    if (strcmp(R.name, C.name))
        fprintf(o, "  NOTE the two sections are not the same name\n");

    if (json_fn) {
        if ((jout = fopen(json_fn, "w")) == NULL) { perror(json_fn); return 16; }
        /* /2 AND NOT /1: `source' moved from the finding to each SIDE of it, and
         * a moved key is a breaking change however empty it used to be.  A
         * finding has two sides, they are two maintenance levels of one section,
         * and they have two different sources -- one document-level `source'
         * would have to pick one silently. */
        fputs("{\n  \"schema\": \"dasm370-repair/2\",\n", jout);
        fputs("  \"note\": \"Offsets and lengths are section-relative BYTES as "
              "integers; `bytes' is uppercase hex, truncated at 64 bytes. A byte "
              "no TXT card covered was read as zero before comparison, because a "
              "deck records its holes and a bound member cannot. EACH SIDE CARRIES ITS "
              "OWN `source\' -- in dasm370-repair/1 it sat on the FINDING and was always "
              "null -- because the two objects are two maintenance levels of one section "
              "and have two different sources; where it is null, `source_absent\' names "
              "which absence it is. A reader of /1 that asks a finding for `source\' and "
              "tolerates its absence will silently see none where there is one.\",\n", jout);
        if (!sref.loaded || !scand.loaded)
            fputs("  \"source_absent_because\": \"a side with no as370 --stmts export "
                  "(cc370#411) carries source:null there: line number, text, macro origin "
                  "and reserve-vs-align are SOURCE facts. In an object a DS 0F pad and a "
                  "DS CL1 reservation are both uncovered bytes; two object-side rules "
                  "measured over the 30 control CSECTs disagree 1% against 14%. Pass "
                  "--ref-stmts and --cand-stmts to fill them.\",\n", jout);
        fputs("  \"source_note\": \"A source record names the card at `org\', and THE "
              "CONSUMER MUST CHECK IT: test that `text\' is a PREFIX of the statement at "
              "org, folding continuations. A statement from a COPY\'d member keeps the "
              "COPY card\'s origin and carries nothing that marks it -- gen false, mdepth "
              "0, mcall_* null, exactly like open code -- so org names the COPY card and "
              "the prefix test is what says so. Measured over 490 COPY-derived records: "
              "490 of 490 both ways, and org is never a line inside the member; control "
              "over 47,534 open-code records gives 0 false positives on prefix and 5 on "
              "equality. `claimants\' above 1 means an ORG overlay put several statements "
              "on the offset. THE ONE TAKEN IS THE LAST IN LISTING ORDER THAT RESERVES, "
              "and `the last\' alone is wrong: a forward ORG claims the bytes it moved "
              "over and is last, while the deck holds what the statements under it wrote "
              "-- 53,328 of 189,227 overlapped offsets over the 832-module population, in "
              "121 of its 378 modules with an overlap, and 45 of 3,266 over the 30. The "
              "rule is keyed on `reserves\' and NOT on the operation: 53,323 of those "
              "53,328 last claimants are ORG and five are a zero-duplication DC 0F or "
              "DS 0F. Under the reserves rule the count is 0 in both populations. `chosen\' is \\\"reserving\\\" for that statement, "
              "\\\"unreserved\\\" where no claimant reserves at all, "
              "\\\"encloses\\\" for one an INSERTION POINT falls inside -- a disassembly\'s "
              "boundaries are the decoder\'s and not the assembler\'s, so that card has to "
              "be SPLIT -- and \\\"zero-advance\\\" for one that occupies nothing, whose "
              "`reserves\' is null.\",\n", jout);
        fputs("  \"csect\": ", jout); jstr(jout, R.name);
        fprintf(jout, ",\n  \"ref\": {\"path\": ");
        jstr(jout, R.path);
        fprintf(jout, ", \"form\": \"%s\", \"bytes\": %ld, \"statements\": %d}",
                R.member ? "member" : "deck", R.len, R.n);
        fprintf(jout, ",\n  \"cand\": {\"path\": ");
        jstr(jout, C.path);
        fprintf(jout, ", \"form\": \"%s\", \"bytes\": %ld, \"statements\": %d}",
                C.member ? "member" : "deck", C.len, C.n);
        fputs(",\n  \"stmts\": {", jout);
        jstmts_side("ref", &sref);
        fputc(',', jout);
        jstmts_side("cand", &scand);
        fputc('}', jout);
        fputs(",\n  \"findings\": [", jout);
    }

    if (D < 0 && jout) {
        fputs("\n  ],\n  \"align\": \"abandoned\"\n}\n", jout);
        fclose(jout); jout = NULL;
    }
    if (D < 0) {
        fprintf(o, "  ALIGNMENT ABANDONED: more than %d insertions and deletions%s\n",
                ALIGN_MAXD, D == -2 ? " (or out of memory)" : "");
        fprintf(o, "SUMMARY %s refstmt=%d candstmt=%d reflen=%ld candlen=%ld align=abandoned\n",
                R.name, R.n, C.n, R.len, C.len);
        if (o != stdout) fclose(o);
        free(R.st); free(R.img); free(R.cov); free(C.st); free(C.img); free(C.cov);
        return 4;
    }

    /* The shift function's value set, taken from the alignment itself. */
    sv = malloc((size_t)(np + 2) * sizeof *sv);   /* the matched pairs, plus the section end */
    if (!sv) { fprintf(stderr, "dasm370: out of memory\n"); return 16; }
    for (k = 0; k < np; k++) {
        long q = C.st[pr[k].j].at - R.st[pr[k].i].at;
        if (!shift_known(sv, nsv, q)) sv[nsv++] = q;
    }
    /* THE END OF THE SECTION IS AN ALIGNMENT POINT TOO, and leaving it out cost
     * the second constructed case its whole answer.  A matched pair has the same
     * length on both sides -- the key carries the bytes, so it must -- which
     * makes a statement's end shift equal to its start shift, and every gap's
     * end coincide with the next matched statement's start.  Every boundary is
     * therefore a matched start, EXCEPT the last one, which no statement
     * follows.
     *
     * Case 2 lands exactly there: insertions of 2 and 4 bytes move every
     * displacement by 8, the missing 2 being alignment padding the assembler
     * added when the first insertion pushed the data area off its fullword
     * boundary.  That padding sits INSIDE the trailing data run, which does not
     * match, so no matched pair carries +8 and the shift set came back
     * {+0,+2,+6} -- and all four displacements were reported as constant
     * changes.  A whole module of findings where there are none, which is the
     * failure the cumulative-shift design exists to avoid, arriving through the
     * one boundary the implementation had not counted. */
    {
        long q = C.len - R.len;
        if (!shift_known(sv, nsv, q)) sv[nsv++] = q;
    }

    pi = pj = 0;
    for (k = 0; k <= np; k++) {
        int i1 = (k < np) ? pr[k].i : R.n, j1 = (k < np) ? pr[k].j : C.n;
        if (i1 > pi || j1 > pj) {
            if (firstchange < 0) firstchange = (i1 > pi) ? R.st[pi].at : (pi < R.n ? R.st[pi].at : R.len);
            align_gap(o, &R, pi, i1, &C, pj, j1, &ins, &del, &dchg, &chg);
        }
        if (k == np) break;
        i = pr[k].i; j = pr[k].j;
        {
            const struct astmt *a = &R.st[i], *b = &C.st[j];
            long sh = b->at - a->at;
            int said = 0, f;
            for (f = 0; f < a->nd && f < b->nd; f++) {
                long dl = (long)b->dd[f] - (long)a->dd[f];
                if (dl == 0) continue;
                if (shift_known(sv, nsv, dl)) {
                    cons++;
                    fprintf(o, "CONSEQ  shift  %06lX -> %06lX  %-5s %-24s  D%d %d -> %d  %+ld\n",
                            (unsigned long)a->at, (unsigned long)b->at, a->op, a->opnd,
                            f + 1, a->dd[f], b->dd[f], dl);
                } else {
                    char det[80];
                    chg++;
                    if (firstchange < 0) firstchange = a->at;
                    snprintf(det, sizeof det, "displacement %d: %d -> %d, delta %+ld, "
                             "not in the shift set", f + 1, a->dd[f], b->dd[f], dl);
                    jfinding("const", &R, a->at, a->len, a->op, a->opnd,
                             &C, b->at, b->len, b->op, b->opnd, det);
                    fprintf(o, "FINDING const  %06lX -> %06lX  %-5s %-24s  D%d %d -> %d  %+ld"
                               "  not a shift\n",
                            (unsigned long)a->at, (unsigned long)b->at, a->op, a->opnd,
                            f + 1, a->dd[f], b->dd[f], dl);
                }
                said = 1;
            }
            if (a->kind == AS_ADCON && !a->external && !b->external) {
                long dl = b->val - a->val;
                if (dl != 0) {
                    if (shift_known(sv, nsv, dl)) {
                        cons++;
                        fprintf(o, "CONSEQ  adcon  %06lX -> %06lX  DC    A(%06lX -> %06lX) %+ld\n",
                                (unsigned long)a->at, (unsigned long)b->at,
                                (unsigned long)a->val, (unsigned long)b->val, dl);
                    } else {
                        char det[80];
                        chg++;
                        if (firstchange < 0) firstchange = a->at;
                        snprintf(det, sizeof det, "internal adcon: %06lX -> %06lX, delta %+ld, "
                                 "not in the shift set", (unsigned long)a->val,
                                 (unsigned long)b->val, dl);
                        jfinding("const", &R, a->at, a->len, a->op, a->opnd,
                                 &C, b->at, b->len, b->op, b->opnd, det);
                        fprintf(o, "FINDING const  %06lX -> %06lX  DC    A(%06lX -> %06lX) %+ld"
                                   "  not a shift\n",
                                (unsigned long)a->at, (unsigned long)b->at,
                                (unsigned long)a->val, (unsigned long)b->val, dl);
                    }
                    said = 1;
                }
            }
            if (!said) { if (sh == 0) same++; else cons++; }
        }
        pi = i1 + 1; pj = j1 + 1;
    }

    /* Which case shift(B) is in, per module and never assumed.  The exact rule
     * is delta == shift(T) - shift(B); with the base established before every
     * change shift(B) is 0 and the membership test is exact.  A change that
     * PRECEDES the prologue moves the base too, and then the same test is
     * weaker -- so it is stated rather than quietly relied on. */
    if (R.first_balr < 0) weak = 2;
    else if (firstchange >= 0 && firstchange <= R.first_balr) weak = 1;

    fprintf(o, "  shift set (%d):", nsv);
    for (k = 0; k < nsv && k < 24; k++) fprintf(o, " %+ld", sv[k]);
    if (nsv > 24) fprintf(o, " ... (%d more)", nsv - 24);
    fputc('\n', o);
    fprintf(o, "  base: %s", R.first_balr >= 0 ? "first BALR Rn,0 at " : "no BALR Rn,0 in the reference");
    if (R.first_balr >= 0) fprintf(o, "%06lX", (unsigned long)R.first_balr);
    if (firstchange >= 0) fprintf(o, ", first change at %06lX", (unsigned long)firstchange);
    fprintf(o, " -> %s\n", weak == 0 ? "EXACT" : weak == 1 ? "WEAK (a change precedes the base)"
                                               : "WEAK (no prologue base found)");
    /* ONE MACHINE-READABLE LINE PER MODULE, and it carries its own denominator.
     * A finding count over a population cannot be normalised without a size, and
     * `first' is the scalar a triage run ranks on -- it is what the caller's
     * first-divergence table is built from.  Both live here rather than in the
     * header lines above, which are for a reader and are not greppable. */
    if (firstchange >= 0) snprintf(firstbuf, sizeof firstbuf, "%06lX", (unsigned long)firstchange);
    else                  snprintf(firstbuf, sizeof firstbuf, "-");
    fprintf(o, "SUMMARY %s findings=%d ins=%d del=%d data=%d const=%d conseq=%d unchanged=%d "
               "shifts=%d edits=%d first=%s refstmt=%d candstmt=%d reflen=%ld candlen=%ld "
               "base=%s align=ok\n",
            R.name, ins + del + dchg + chg, ins, del, dchg, chg, cons, same, nsv, D,
            firstbuf, R.n, C.n, R.len, C.len,
            /* THREE STATES, NOT TWO, and the difference is not cosmetic: a
             * module with no prologue idiom at all is a different thing from
             * one whose base is established after the first change, and a
             * population run greps this line.  Most of #112's corpus is PL/S,
             * which largely does not write BALR Rn,0 -- so folding the two into
             * `weak' reports a shifted base for modules that simply have no
             * base to shift. */
            weak == 0 ? "exact" : weak == 1 ? "weak" : "none");

    if (jout) {
        /* The shift set and the base case belong in the document, because a
         * consumer deciding what to repair needs to know how strong the
         * consequence test was on this module -- membership in a 317-value set
         * is close to no test at all. */
        fputs("\n  ],\n  \"shift_set\": [", jout);
        for (k = 0; k < nsv; k++) fprintf(jout, "%s%ld", k ? ", " : "", sv[k]);
        fprintf(jout, "],\n  \"base\": \"%s\",\n",
                weak == 0 ? "exact" : weak == 1 ? "weak" : "none");
        fprintf(jout, "  \"counts\": {\"findings\": %d, \"insert\": %d, \"delete\": %d, "
                      "\"data\": %d, \"const\": %d, \"consequences\": %d, "
                      "\"unchanged\": %d, \"edits\": %d},\n",
                ins + del + dchg + chg, ins, del, dchg, chg, cons, same, D);
        fputs("  \"align\": \"ok\"\n}\n", jout);
        if (fclose(jout)) { perror(json_fn); rc = 16; }
        jout = NULL;
    }
    if (o != stdout && fclose(o)) { perror(outfn); rc = 16; }
    free(sv); free(pr);
    free(R.st); free(R.img); free(R.cov);
    free(C.st); free(C.img); free(C.cov);
    return rc;
}

/* ------------------------------------------------------------------ run -- */

static void usage(FILE *o)
{
    fputs(
"Usage: dasm370 [options...] deck.obj\n"
" Options:\n"
"  --csect NAME       disassemble this control section (default: the only one)\n"
"  --derive-hints SRC assemble SRC with as370 and write out what it found as a\n"
"                     hint file: its labels, and its base registers with the\n"
"                     lifetimes the assembly gave them.  Takes -I, and records\n"
"                     the list in the file -- a hint set derived against the\n"
"                     wrong macro library is a wrong one that looks right\n"
"  --reach[=SET]      #383: traverse from the CODE roots (the SD, the LD/LR\n"
"                     entries this section owns, the END entry on a deck, and a\n"
"                     table of address constants a branched-through register was\n"
"                     loaded from) and emit what nothing reaches as DC.  A\n"
"                     REACHABILITY comment card reports the coverage, which is\n"
"                     the point: unreached CODE also becomes DC, and that is\n"
"                     byte-safe and so invisible to a round trip.  SET is\n"
"                     none|r15|balr|rld|lr|both|bothlr|acon|all (default all)\n"
"  --reach-report[=SET] the traversal's coverage as data, without a disassembly\n"
"  --reach-OLD[=SET]  #383 measurement: traverse from the CODE roots (the SD,\n"
"                     the LD/LR entries this section owns, and the END entry on\n"
"                     a deck) and report what the traversal reaches.  SET is\n"
"                     none|r15|balr|both (default both) and says which base\n"
"                     assumptions are allowed: r15 = R15 holds the entry point,\n"
"                     balr = a prologue BALR Rn,0 is live for the section.  RLD\n"
"                     targets are LABEL roots and are never code roots here\n"
"  --infer            candidates from the code itself, for a section with no\n"
"                     source: base registers with their evidence kind\n"
"                     (prologue/rld/pattern).  Every candidate is a COMMENT and\n"
"                     none is applied -- the point is sometimes ground truth,\n"
"                     the lifetime never is\n"
"  --align-diff R C   disassemble BOTH objects of one CSECT and align them\n"
"                     statement by statement, with the displacements masked out\n"
"                     of the key so a statement survives a shift.  A\n"
"                     displacement delta is a CONSEQUENCE when it is in the\n"
"                     shift function's value set and a FINDING when it is not.\n"
"                     Reads no hint file and writes no disassembly\n"
"  --json FILE        with --align-diff, the repair contract: one record per\n"
"                     divergence, schema dasm370-repair/2 (cc370#385)\n"
"  --ref-stmts FILE   the as370 --stmts export of each side's SOURCE, which\n"
"  --cand-stmts FILE  fills that side's `source\' in --json.  Two flags because\n"
"                     the two objects have two different sources, and a single\n"
"                     one would have to pick a side silently\n"
"  -I DIR             macro library for --derive-hints (repeatable)\n"
"  --as370 PATH       which as370 to run (default: beside this binary, then PATH)\n"
"  --anchors=MODE     refuse (default) stops at the first failed check; report\n"
"                     disassembles anyway and writes EVERY finding as a comment\n"
"                     at its offset -- a failed anchor, a base range clamped to\n"
"                     a shorter section, a label the module names elsewhere --\n"
"                     so the first failed anchor bounds the divergence\n"
"  --hints FILE       read a hint file: labels, data and fill runs, base\n"
"                     registers with a lifetime, and the VERIFY/REPLACE pair.\n"
"                     A TOML subset, parsed here; anything outside the grammar\n"
"                     is refused, not skipped.  dasm370(1) has it in full\n"
"  --allow-incomplete read a bound member whose record stream the reader could\n"
"                     not finish (by default that is refused, not guessed at)\n"
"  --labels MODE      displacement (the default) names a generated label after\n"
"                     the offset it sits at; sequential numbers them instead.\n"
"                     A displacement-derived name is WRONG the moment a\n"
"                     statement is inserted above it -- and it still assembles,\n"
"                     so no round trip, no comparison and no gate objects.  Use\n"
"                     sequential for source that will be edited (cc370#396)\n"
"  --isa SET          app|s370|s360|full -- accepted; only `full' is implemented\n"
"  --format card|free card (the default) writes 80-column records with sequence\n"
"                     numbers in 73-80 and column 72 left blank\n"
"  -o FILE            write to FILE instead of standard output\n"
"  --help             show this message and exit\n"
"  -v                 print the version\n"
"\n"
"The decoder is as370's own opcode table, inverted (cc370#374): one table, and\n"
"the disassembler agrees with the assembler by construction.  Every instruction\n"
"is re-encoded from what was decoded and compared against the bytes it came\n"
"from; anything that does not reproduce itself is written as DC X'..'.\n"
"\n"
"A base register given in a hint file is APPLIED, because it carries the\n"
"lifetime its writer asserted.  One that dasm370 infers will be written to the\n"
"file and never applied (#382): get a base register's range wrong and every\n"
"displacement in it resolves against the wrong section, producing symbols that\n"
"are plausible, consistent and false -- and the bytes do not move, so no round\n"
"trip objects.  A hint [[base]] covers this section; a USING points a register\n"
"at a DSECT and is not implemented yet.\n", o);
}

int main(int argc, char **argv)
{
    const char *src = NULL, *want = NULL, *outfn = NULL, *hints_file = NULL, *isa_cli = NULL;
    const char *derive_src = NULL, *as370_path = NULL;
    const char *align_ref = NULL, *align_cand = NULL;
    int infer = 0;
    char *incs[64]; int ninc = 0;
    char tsym[512], tuse[512], tobj[512], asver[128];
    long assize = 0;
    int ai, i, rc, allow_incomplete = 0;

    if (argc == 1) { usage(stdout); return 0; }
    for (ai = 1; ai < argc; ai++) {
        if (!strcmp(argv[ai], "--help")) { usage(stdout); return 0; }
        else if (!strcmp(argv[ai], "-v")) { printf("%s %s - %s\n", DASM_NAME, DASM_VER, __DATE__); return 0; }
        else if (!strcmp(argv[ai], "--csect") && ai + 1 < argc) want = argv[++ai];
        else if (!strcmp(argv[ai], "--allow-incomplete")) allow_incomplete = 1;
        else if (!strcmp(argv[ai], "--hints") && ai + 1 < argc) hints_file = argv[++ai];
        else if (!strcmp(argv[ai], "--derive-hints") && ai + 1 < argc) derive_src = argv[++ai];
        else if (!strcmp(argv[ai], "--infer")) infer = 1;
        else if (!strcmp(argv[ai], "--json") && ai + 1 < argc) json_fn = argv[++ai];
        /* TWO FLAGS AND NOT ONE, because the two sides are two different modules
         * at two maintenance levels and each has its own source.  A single
         * --stmts would have to pick a side silently, and picking the wrong one
         * produces a plausible `org' on every finding with nothing to object. */
        else if (!strcmp(argv[ai], "--ref-stmts") && ai + 1 < argc) ref_stmts_fn = argv[++ai];
        else if (!strcmp(argv[ai], "--cand-stmts") && ai + 1 < argc) cand_stmts_fn = argv[++ai];
        else if (!strcmp(argv[ai], "--stmts") || !strncmp(argv[ai], "--stmts=", 8)) {
            fprintf(stderr, "dasm370: --stmts is as370's option for WRITING the export; "
                            "dasm370 reads one\n"
                            "  per side, because the two objects have two different sources:\n"
                            "  --ref-stmts FILE and --cand-stmts FILE\n");
            return 16;
        }
        else if (!strcmp(argv[ai], "--labels") && ai + 1 < argc) {
            const char *v = argv[++ai];
            if (!strcmp(v, "sequential")) label_seq = 1;
            else if (!strcmp(v, "displacement")) label_seq = 0;
            else { fprintf(stderr, "dasm370: --labels %s is not displacement or sequential\n", v); return 16; }
        }
        else if (!strncmp(argv[ai], "--reach-report", 14) || !strncmp(argv[ai], "--reach", 7)) {
            const char *v;
            if (!strncmp(argv[ai], "--reach-report", 14)) { reach_only = 1; v = argv[ai] + 14; }
            else {
                /* THE APPLIED FORM IS HELD BACK, and the measurement is why.
                 * Over the 30 control CSECTs it darkens 12,558 bytes the source
                 * listing calls CODE against 2,300 bytes of genuine table it
                 * correctly silences, and the best threshold on its own coverage
                 * is break-even.  Byte-safe is not harmless: a module whose real
                 * code becomes DC round-trips identically and every gate reports
                 * success.  cc370#383 carries the ledger. */
                fprintf(stderr, "dasm370: --reach is not implemented; --reach-report measures it.\n"
                                "  Applied, it darkens more real code than it silences data --\n"
                                "  12,558 bytes against 2,300 over the 30 control CSECTs.\n"
                                "  cc370#383 has the measurement.\n");
                return 16;
            }
            if (!*v) reach_mode = RCH_R15 | RCH_BALR | RCH_RLD | RCH_LR | RCH_ACON;
            else if (*v == '=') {
                v++;
                if (!strcmp(v, "none")) reach_mode = 0;
                else if (!strcmp(v, "r15")) reach_mode = RCH_R15;
                else if (!strcmp(v, "balr")) reach_mode = RCH_BALR;
                else if (!strcmp(v, "both")) reach_mode = RCH_R15 | RCH_BALR;
                else if (!strcmp(v, "rld")) reach_mode = RCH_RLD;
                else if (!strcmp(v, "lr")) reach_mode = RCH_LR;
                else if (!strcmp(v, "bothlr")) reach_mode = RCH_R15 | RCH_BALR | RCH_LR;
                else if (!strcmp(v, "acon")) reach_mode = RCH_R15 | RCH_BALR | RCH_LR | RCH_ACON;
                else if (!strcmp(v, "all")) reach_mode = RCH_R15 | RCH_BALR | RCH_RLD | RCH_LR | RCH_ACON;
                else { fprintf(stderr, "dasm370: --reach=%s is not none|r15|balr|rld|lr|both|bothlr|acon|all\n", v); return 16; }
            } else { fprintf(stderr, "dasm370: invalid option '%s'\n", argv[ai]); return 16; }
        }
        else if (!strcmp(argv[ai], "--align-diff")) {
            if (ai + 2 >= argc) {
                fprintf(stderr, "dasm370: --align-diff takes two objects, a reference and a candidate\n");
                return 16;
            }
            align_ref = argv[++ai];
            align_cand = argv[++ai];
        }
        else if (!strcmp(argv[ai], "--as370") && ai + 1 < argc) as370_path = argv[++ai];
        else if (!strcmp(argv[ai], "-I") && ai + 1 < argc) {
            if (ninc >= 64) { fprintf(stderr, "dasm370: too many -I directories for this build\n"); return 16; }
            incs[ninc++] = argv[++ai];
        }
        else if (!strncmp(argv[ai], "--anchors=", 10)) {
            const char *v = argv[ai] + 10;
            if (!strcmp(v, "report")) anchor_report = 1;
            else if (!strcmp(v, "refuse")) anchor_report = 0;
            else { fprintf(stderr, "dasm370: --anchors=%s is not report or refuse\n", v); return 16; }
        }
        else if (!strcmp(argv[ai], "-o") && ai + 1 < argc) outfn = argv[++ai];
        else if (!strcmp(argv[ai], "--isa") && ai + 1 < argc) {
            isa_cli = argv[++ai];
            if (strcmp(isa_cli, "app") && strcmp(isa_cli, "s370")
                && strcmp(isa_cli, "s360") && strcmp(isa_cli, "full")) {
                fprintf(stderr, "dasm370: --isa %s is not one of app|s370|s360|full\n", isa_cli);
                return 16;
            }
        }
        else if (!strcmp(argv[ai], "--format") && ai + 1 < argc) {
            const char *v = argv[++ai];
            if (!strcmp(v, "card")) card_format = 1;
            else if (!strcmp(v, "free")) card_format = 0;
            else { fprintf(stderr, "dasm370: --format %s is not card or free\n", v); return 16; }
        }
        else if (argv[ai][0] == '-' && argv[ai][1]) {
            fprintf(stderr, "dasm370: invalid option '%s'\n", argv[ai]);
            return 16;
        }
        else if (src) { fprintf(stderr, "dasm370: more than one input file\n"); return 16; }
        else src = argv[ai];
    }
    /* --derive-hints reads a SOURCE and writes a hint file; it takes no deck of
     * its own, because it assembles one.  Mixing the two would be two tools in
     * one invocation with one -o between them. */
    if (derive_src && src) {
        fprintf(stderr, "dasm370: --derive-hints takes a source and assembles its own deck; "
                        "do not also give one\n");
        return 16;
    }
    if (infer && derive_src) {
        fprintf(stderr, "dasm370: --infer reads a module and --derive-hints a source; "
                        "they are two ways to produce one file, not two halves of one\n");
        return 16;
    }
    if (derive_src && hints_file) {
        fprintf(stderr, "dasm370: --derive-hints writes a hint file; it does not read one\n");
        return 16;
    }
    /* --align-diff reads TWO objects of its own and writes a report, so it
     * takes no third one and produces no disassembly.  The hint modes are
     * refused with it rather than combined: a hint set supplies the base this
     * mode says it does not have, which is a real refinement and a later one --
     * combining them now would mean reporting two different shift(B) cases from
     * one run without saying which applied where. */
    if (align_ref) {
        if (src) {
            fprintf(stderr, "dasm370: --align-diff already names both objects; do not give a third\n");
            return 16;
        }
        if (derive_src || infer || hints_file) {
            fprintf(stderr, "dasm370: --align-diff compares two objects; it neither reads nor writes "
                            "a hint file\n");
            return 16;
        }
        if ((ref_stmts_fn || cand_stmts_fn) && !json_fn) {
            fprintf(stderr, "dasm370: a statement export fills the `source' field of --json "
                            "(cc370#385);\n"
                            "  the text report has no field for it, so it would be read and "
                            "discarded\n");
            return 16;
        }
        return align_run(align_ref, align_cand, want, outfn);
    }
    if ((ref_stmts_fn || cand_stmts_fn) && !align_ref) {
        fprintf(stderr, "dasm370: --ref-stmts/--cand-stmts name the sources of the two objects "
                        "--align-diff compares;\n"
                        "  there are no two objects without it\n");
        return 16;
    }
    if (json_fn && !align_ref) {
        fprintf(stderr, "dasm370: --json is the repair contract for --align-diff (cc370#385); "
                        "it has nothing to describe without one\n");
        return 16;
    }
    if (!src && !derive_src) { usage(stderr); return 16; }

    if (derive_src) {
        const char *tmp = getenv("TMPDIR"); char asbuf[512];
        struct stat st;
        FILE *vp;
        if (!tmp || !*tmp) tmp = "/tmp";
        snprintf(tsym, sizeof tsym, "%s/dasm370-%d.sym", tmp, (int)getpid());
        snprintf(tuse, sizeof tuse, "%s/dasm370-%d.use", tmp, (int)getpid());
        snprintf(tobj, sizeof tobj, "%s/dasm370-%d.obj", tmp, (int)getpid());
        /* Which as370: the one named, else the one beside this binary -- the
         * install layout puts them in one directory -- else whatever PATH finds.
         * In the BUILD tree they are siblings and neither of the last two is
         * right, which is why --as370 exists and why the header records what
         * actually resolved rather than what was intended. */
        if (!as370_path) {
            const char *sl = strrchr(argv[0], '/');
            if (sl) {
                snprintf(asbuf, sizeof asbuf, "%.*sas370", (int)(sl - argv[0] + 1), argv[0]);
                if (!access(asbuf, X_OK)) as370_path = asbuf;
            }
        }
        if (!as370_path) as370_path = "as370";
        asver[0] = 0;
        {
            char vc[600];
            snprintf(vc, sizeof vc, "'%s' -v 2>/dev/null", as370_path);
            if ((vp = popen(vc, "r")) != NULL) {
                if (fgets(asver, sizeof asver, vp)) {
                    char *nl = strchr(asver, '\n'); if (nl) *nl = 0;
                }
                pclose(vp);
            }
        }
        if (!asver[0]) snprintf(asver, sizeof asver, "(could not run %.90s -v)", as370_path);
        if (!stat(as370_path, &st)) assize = (long)st.st_size;
        if ((rc = run_as370(as370_path, derive_src, incs, ninc, tsym, tuse, tobj)) != 0) return rc;
        src = tobj;                      /* read it back through our own deck reader */
    }


    /* The file is read before the module, so a malformed hint file is refused
     * before anything else has happened -- and before the output is opened, so a
     * refusal leaves no half-written disassembly behind. */
    if (hints_file && (rc = hints_load(hints_file)) != 0) return rc;
    {
        /* The command line wins over the file: a file is a decision saved
         * earlier and the option is the one being made now. */
        const char *isa = isa_cli ? isa_cli : (hisa[0] ? hisa : NULL);
        /* Accepted and not yet acted on.  Problem-state against privileged is a
         * per-mnemonic attribute opc_table.h does not carry, and inventing it
         * here would be the second copy #374 exists to prevent.  It is an
         * additive table field, gated by as370/tests/opcinv.c, when the decoder
         * has a reason to want it. */
        if (isa && strcmp(isa, "full"))
            fprintf(stderr, "dasm370: --isa %s not implemented, using full\n", isa);
    }

    if ((rc = load_section(src, want, allow_incomplete)) != 0) return rc;

    /* THE TWO FILE-WRITING MODES COME AFTER THE LOAD, and that ordering is the
     * fix for the bound-member defect rather than a tidy-up.  The load used to
     * be inline here, and the member path reached the emitter by `goto
     * emit_source' -- jumping over everything in between, which is where --infer
     * sat.  A deck fell through and produced candidates; a member jumped past
     * and produced an ordinary disassembly with no candidates in it, which reads
     * exactly like a module that has none.  Measured by the caller: 374
     * candidates from the 30 control CSECTs' decks and 0 from the same CSECTs'
     * members, with IEAVTCR1 identical so the bytes were the same either way --
     * and 648 of 648 no-source CSECTs silent, which is every module the mode
     * exists for.  load_section() RETURNS rather than jumps, so there is no
     * label left to sit in front of and no way to sit before it. */
    if (derive_src) {
        FILE *o;
        if ((rc = load_sym(tsym, sect_name)) != 0) return rc;
        if ((rc = load_usings(tuse, sect_name)) != 0) return rc;
        o = outfn ? fopen(outfn, "w") : stdout;
        if (!o) { perror(outfn); return 16; }
        rc = derive_emit(o, as370_path, asver, assize, derive_src, incs, ninc,
                         sect_name, sect_len, 1);
        if (o != stdout && fclose(o)) { perror(outfn); rc = 16; }
        remove(tsym); remove(tuse); remove(tobj);
        return rc;
    }

    /* #383 measurement mode.  AFTER the load and the labels, like every other
     * mode that reads a module -- the bound-member path used to reach the
     * emitter by a goto and anything before it was unreachable from a member,
     * which is the population this mode exists to measure. */
    if (reach_only) {
        FILE *o;
        derive_labels();
        o = outfn ? fopen(outfn, "w") : stdout;
        if (!o) { perror(outfn); return 16; }
        rc = reach_report(o);
        if (o != stdout && fclose(o)) { perror(outfn); rc = 16; }
        return rc;
    }

    if (infer) {
        FILE *o;
        int r;
        for (r = 0; r < 16; r++) { balr_base[r] = -1; used_base_at[r] = -1; }
        lab[0] = 1;
        for (i = 0; i < nld; i++)
            if (ld[i].owner == sect_esdid) {
                long at = ld[i].addr - sect_org;
                if (at >= 0 && at < sect_len) { ld[i].addr = at; lab[at] = 1; }
            }
        infer_scan(0);
        infer_scan(1);
        o = outfn ? fopen(outfn, "w") : stdout;
        if (!o) { perror(outfn); return 16; }
        rc = infer_emit(o, src);
        if (o != stdout && fclose(o)) { perror(outfn); rc = 16; }
        return rc;
    }

    /* VERIFY, then REPLACE, and both before a single label is derived: the
     * derivation reads the image (an A-con's target comes out of the bytes), so
     * it has to read the image the decoder will read. */
    if (hints_file && (rc = hints_verify_patch()) != 0) return rc;

    /* Labels: the section's start, an ENTRY, and an A-con target inside it.
     * Branch targets need a USING to resolve D(B) at all, and an inferred one is
     * #382's problem precisely because a wrong one produces symbols that are
     * plausible, consistent and false while the bytes stay put. */
    derive_labels();

    /* Now that lab[] exists: the file's own labels join it, its ranges are
     * checked against the section, and each USING's base is resolved to an
     * offset so everything downstream of it is arithmetic. */
    if (hints_file && (rc = hints_bind()) != 0) return rc;
    if (nafail) qsort(afails, (size_t)nafail, sizeof afails[0], afail_cmp);
    if (nhnote) qsort(hnotes, (size_t)nhnote, sizeof hnotes[0], hnote_cmp);

    /* Pass one, and only when a USING gives a branch target a meaning: decode
     * the section without writing it and label every BC target the USING
     * resolves.  A target landing mid-instruction makes that instruction a DC on
     * the next pass, which is right -- the branch says those bytes are entered
     * there, so the boundary we had was the wrong one.  Iterated because a newly
     * labelled target can re-cut the statements around it, and bounded because
     * "until it settles" is not a termination argument. */
    if (nhbas) {
        int pass;
        for (pass = 0; pass < 8; pass++) {
            lab_changed = 0;
            scanning = 1;
            walk_section();
            scanning = 0;
            if (!lab_changed) break;
        }
    }

    /* AFTER the scanning passes, because a hint USING plants branch targets over
     * up to eight iterations and numbering earlier would renumber under the
     * caller -- two names for one offset in one run. */
    label_order();

    /* Opened LAST, so every refusal above leaves no file behind. */
    outf = outfn ? fopen(outfn, "w") : stdout;
    if (!outf) { perror(outfn); return 16; }

    {
        char rem[64];
        /* %.40s: the remark is trimmed to the card anyway, and since --derive-hints
         * makes `src' a bounded array gcc can now see the arithmetic and says so. */
        snprintf(rem, sizeof rem, "%ld bytes, from %.40s", sect_len, src);
        emit(sect_name, "CSECT", "", rem);
    }
    /* One line first, because a run over a whole population is read by the
     * hundred: the detail below is what a script greps, this is what a person
     * sees.  The counts are of findings, not of failures -- under report a
     * finding IS the output. */
    if (anchor_report && (nhnote || nafail)) {
        char t[200];
        snprintf(t, sizeof t, "HINTS REPORT: %d anchor(s) failed, %d note(s)", nafail, nhnote);
        emit_comment(t);
        if (nafail) {
            snprintf(t, sizeof t, "HINTS REPORT: first failed anchor at %06lX -- the hints "
                                  "hold below it, so that bounds the divergence",
                     (unsigned long)afails[0].at);
            emit_comment(t);
        }
    }
    for (i = 0; i < nhnote; i++)
        if (!hnotes[i].has_at) emit_comment(hnotes[i].text);
    for (i = 0; i < nld; i++)
        if (ld[i].owner == sect_esdid) emit("", "ENTRY", ld[i].name, "");
    /* Anything our relocations point at that is not this section is external to
     * it, and the ESD type does not decide that: BLSRLSYM's deck holds a SECOND
     * CSECT called PC, and an A-con into it is an ordinary adcon here and an
     * external one in a per-section disassembly.  Declaring only the entries
     * typed ER left `A(PC+X'A70')' undefined and the whole module would not
     * assemble.  A V-con declares its own external, so the EXTRN beside it is
     * redundant and harmless; an A-con does not, which is the case that needed
     * it. */
    for (i = 1; i < MAXESD; i++) {
        int used = 0, k;
        if (!esdname[i][0] || i == sect_esdid) continue;
        for (k = 0; k < nrld; k++) if (rld[k].r == i) used = 1;
        if (used) emit("", "EXTRN", esdname[i], "");
    }

    walk_section();
    if (end_has_entry && end_entry >= 0 && end_entry < sect_len) {
        char t[LABBUF];
        label_name(end_entry, t);
        emit("", "END", t, "");
    } else {
        emit("", "END", "", "");
    }
    if (outf != stdout) fclose(outf);
    return 0;
}

/* Collected, not acted on: the run above decides what a section is. */
static int dasm_esd_cb(const struct obj_esd *e, void *ctx)
{
    struct esd_collect *c = ctx;
    struct esd_item *it;
    if (c->n >= 8) return 0;
    it = &c->it[c->n++];
    it->id = e->esdid;
    it->addr = e->addr;
    it->len = e->len;
    it->type = e->type;
    name_of(e->name, it->name);
    return 1;
}

/* Only the items filed under OUR section, because only those describe bytes
 * this run is going to write. */
static int dasm_rld_cb(const struct obj_rld *r, void *ctx)
{
    (void)ctx;
    if (nrld >= MAXRLD) return 0;
    if (r->p != sect_esdid) return 1;
    /* The P-position is module-absolute like everything else a deck files under
     * a section, and the range guard is the member path's (cc370#415): without
     * the subtraction an item of a section at origin A indexed img[] past the
     * section and emit_adcon read bytes that were never loaded. */
    rld[nrld].addr = r->addr - sect_org;
    rld[nrld].len = obj_rld_len(r->flag);
    rld[nrld].r = r->r;
    if (rld[nrld].addr >= 0 && rld[nrld].addr < sect_len) nrld++;
    return 1;
}
