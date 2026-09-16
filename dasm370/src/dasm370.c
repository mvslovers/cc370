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
static unsigned char brk[MAXSECT_BYTES];      /* 1 = a statement must start here */
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
static long sect_org;                         /* a bound member's section origin; 0 for a deck */
static int  from_member;
static int  scanning;                         /* pass one: decode, record, write nothing */
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

#define MAXHLABEL 4096
#define MAXHRANGE 1024
#define MAXHBASE 64
#define MAXHB     64
#define MAXHVR    512
#define MAXKV     12

struct hlabel { long at; char name[9]; int line; };
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


static const char *hlab_name(long a)
{
    int i;
    for (i = 0; i < nhlab; i++) if (hlab[i].at == a) return hlab[i].name;
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
    if (scanning) return;
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
static void label_name(long a, char *out)
{
    const char *h;
    int i;
    if ((h = hlab_name(a)) != NULL) { strcpy(out, h); return; }
    for (i = 0; i < nld; i++)
        if (ld[i].addr == a) { strcpy(out, ld[i].name); return; }
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
        if ((rc = hrange_ok(v->at, L, v->line, "verify")) != 0) return rc;
        if (!hcovered(v->at, L))
            return herr(v->line, "verify covers bytes no TXT card defined -- there is nothing there to assert");
        if (v->kind == 0) {
            if (memcmp(img + v->at, v->b, (size_t)L)) {
                char got[2 * MAXHB + 1], wnt[2 * MAXHB + 1];
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
        if (hlab[i].at < 0 || hlab[i].at >= sect_len) {
            snprintf(hmsg, sizeof hmsg, "label at X'%lX' is outside %s (X'%lX' bytes)",
                     (unsigned long)hlab[i].at, sect_name, (unsigned long)sect_len);
            return herr(hlab[i].line, hmsg);
        }
        for (j = 0; j < i; j++) {
            if (hlab[j].at == hlab[i].at) return herr(hlab[i].line, "two [[label]] entries name one offset");
            if (!strcmp(hlab[j].name, hlab[i].name)) return herr(hlab[i].line, "two [[label]] entries share a name");
        }
        lab[hlab[i].at] = 1;
        brk[hlab[i].at] = 1;
    }
    for (i = 0; i < nhdata; i++) {
        if ((rc = hrange_ok(hdata[i].at, hdata[i].len, hdata[i].line, "data")) != 0) return rc;
        brk[hdata[i].at] = 1;
        if (hdata[i].at + hdata[i].len < sect_len) brk[hdata[i].at + hdata[i].len] = 1;
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
        brk[at] = 1;
        if (at + n < sect_len) brk[at + n] = 1;
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
        if (u->from < 0 || u->to > sect_len || u->from >= sect_len) {
            snprintf(hmsg, sizeof hmsg, "base from X'%lX' to X'%lX' is outside %s (X'%lX' bytes)",
                     (unsigned long)u->from, (unsigned long)u->to, sect_name, (unsigned long)sect_len);
            return herr(u->line, hmsg);
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
                brk[ends[e]] = 1;
            }
        }
        lab[u->baseval] = 1;
        brk[u->baseval] = 1;
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
    /* In a bound member the adcon has been RELOCATED: its value is the final
     * address and not the offset a deck carries.  A target in this section is
     * therefore `value - origin'; an EXTERNAL one has been resolved to wherever
     * the binder put it, and that address is not an addend -- reassembling it
     * as one would write a number where a deck holds a relocatable zero. */
    if (from_member) v -= sect_org;
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
                long idl = mvs_be16(m + r.off + 4), rl = mvs_be16(m + r.off + 6);
                long dat = r.off + 16 + idl;
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
static void walk_section(void)
{
    long a = 0;
    int ev = 0;

    while (a < sect_len) {
        const struct rlditem *r;
        long fl;
        /* `<= a' and not `== a': every offset an event sits on was marked in
         * brk[] and refused where it could not begin a statement, so this should
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
            while (a + n < sect_len && !cov[a + n] && !lab[a + n] && !brk[a + n]) n++;
            emit_ds_hole(a, n);
            a += n;
            continue;
        }
        if ((r = rld_at(a)) != NULL) { emit_adcon(a, r); a += r->len; continue; }
        if ((fl = hfill_at(a)) > 0) { emit_fill(a, fl); a += fl; continue; }
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
                for (k = 1; k < len; k++) if (lab[a + k] || brk[a + k]) split = 1;
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
                    emit(l, o->name, opnd, rem);
                    a += len;
                    continue;
                }
            }
        }
        {                                          /* nothing else fits: DC */
            long n = 1;
            while (a + n < sect_len && cov[a + n] && !lab[a + n] && !brk[a + n]
                   && !rld_at(a + n) && !hfill_at(a + n) && n < 16) n++;
            emit_dc_hex(a, (int)n);
            a += n;
        }
    }
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

/* ------------------------------------------------------------------ run -- */

static void usage(FILE *o)
{
    fputs(
"Usage: dasm370 [options...] deck.obj\n"
" Options:\n"
"  --csect NAME       disassemble this control section (default: the only one)\n"
"  --hints FILE       read a hint file: labels, data and fill runs, USINGs with\n"
"                     a lifetime, and the VERIFY/REPLACE pair.  A TOML subset,\n"
"                     parsed here; anything outside the grammar is refused, not\n"
"                     skipped.  dasm370(1) has the grammar in full\n"
"  --allow-incomplete read a bound member whose record stream the reader could\n"
"                     not finish (by default that is refused, not guessed at)\n"
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
"A USING given in a hint file is APPLIED, because it carries the lifetime its\n"
"writer asserted.  One that dasm370 infers will be written to the file and\n"
"never applied (#382): get a base register's range wrong and every displacement\n"
"in it resolves against the wrong section, producing symbols that are plausible,\n"
"consistent and false -- and the bytes do not move, so no round trip objects.\n", o);
}

int main(int argc, char **argv)
{
    const char *src = NULL, *want = NULL, *outfn = NULL, *hints_file = NULL, *isa_cli = NULL;
    int ai, i, rc, allow_incomplete = 0;
    unsigned char *deck;
    long dn, ncards, c;
    long maxaddr = 0;

    if (argc == 1) { usage(stdout); return 0; }
    for (ai = 1; ai < argc; ai++) {
        if (!strcmp(argv[ai], "--help")) { usage(stdout); return 0; }
        else if (!strcmp(argv[ai], "-v")) { printf("%s %s - %s\n", DASM_NAME, DASM_VER, __DATE__); return 0; }
        else if (!strcmp(argv[ai], "--csect") && ai + 1 < argc) want = argv[++ai];
        else if (!strcmp(argv[ai], "--allow-incomplete")) allow_incomplete = 1;
        else if (!strcmp(argv[ai], "--hints") && ai + 1 < argc) hints_file = argv[++ai];
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
    if (!src) { usage(stderr); return 16; }

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

    {
        FILE *f = fopen(src, "rb");
        long got;
        if (!f) { perror(src); return 16; }
        fseek(f, 0, SEEK_END); dn = ftell(f); fseek(f, 0, SEEK_SET);
        deck = malloc((size_t)dn ? (size_t)dn : 1);
        got = (long)fread(deck, 1, (size_t)dn, f);
        fclose(f);
        if (got != dn) { fprintf(stderr, "dasm370: %s: short read\n", src); return 16; }
    }
    /* An object deck is a multiple of 80 bytes whose cards begin X'02'; anything
     * else is read as a bound member.  Both sniffs are the ones cmplmd370 uses
     * and neither is a guess about the content. */
    if (dn % 80 || dn == 0 || deck[0] != 0x02) {
        int k = load_member(deck, dn, want, allow_incomplete);
        if (k == 0) {
            fprintf(stderr, "dasm370: no section named %s in %s\n", want ? want : "(any)", src);
            return 2;
        }
        if (k != 1) return k;
        goto emit_source;
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
                sect_len = e->len;
                memcpy(sect_name, e->name, 9);
            }
        }
    }
    if (!sect_esdid) {
        fprintf(stderr, "dasm370: no section named %s in %s\n", want ? want : "(any)", src);
        return 2;
    }
    if (sect_len > MAXSECT_BYTES) {
        fprintf(stderr, "dasm370: %s is %ld bytes, over the %ld this build holds\n",
                sect_name, sect_len, MAXSECT_BYTES);
        return 16;
    }

    /* Pass 2: TXT for our section, and the RLD items filed under it. */
    for (c = 0; c < ncards; c++) {
        const unsigned char *card = deck + c * 80;
        struct obj_txt t;
        if (obj_txt_get(card, &t) && t.esdid == sect_esdid) {
            if (t.addr >= 0 && t.addr + t.len <= MAXSECT_BYTES) {
                memcpy(img + t.addr, t.data, (size_t)t.len);
                memset(cov + t.addr, 1, (size_t)t.len);
                if (t.addr + t.len > maxaddr) maxaddr = t.addr + t.len;
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
            end_entry = e.entry_addr;
        }
    }
    /* The ESD's length is the section's length, and the issue says so: a section
     * is padded to what the ESD declares.  TXT reaching past it is not a longer
     * section, it is a deck to report on -- extending the section to the text
     * instead made `rldlen' come back 0x0C where the ESD says 0x07, and the
     * whole ESD card then differed for a reason that had nothing to do with the
     * decode. */
    if (maxaddr > sect_len)
        fprintf(stderr, "dasm370: %s: TXT reaches %06lX, past the ESD length %06lX\n",
                sect_name, (unsigned long)maxaddr, (unsigned long)sect_len);

emit_source:
    /* VERIFY, then REPLACE, and both before a single label is derived: the
     * derivation reads the image (an A-con's target comes out of the bytes), so
     * it has to read the image the decoder will read. */
    if (hints_file && (rc = hints_verify_patch()) != 0) return rc;

    /* Labels: the section's start, an ENTRY, and an A-con target inside it.
     * Branch targets need a USING to resolve D(B) at all, and an inferred one is
     * #382's problem precisely because a wrong one produces symbols that are
     * plausible, consistent and false while the bytes stay put. */
    lab[0] = 1;
    if (end_has_entry && end_entry >= 0 && end_entry < sect_len) lab[end_entry] = 1;
    for (i = 0; i < nld; i++)
        if (ld[i].owner == sect_esdid && ld[i].addr - (from_member ? sect_org : 0) >= 0
            && ld[i].addr - (from_member ? sect_org : 0) < sect_len) {
            ld[i].addr -= (from_member ? sect_org : 0);
            lab[ld[i].addr] = 1;
        }
    for (i = 0; i < nrld; i++) {
        if (rld[i].r == sect_esdid && rld[i].len == 4) {
            long v = 0; int k;
            for (k = 0; k < 4; k++) v = (v << 8) | img[rld[i].addr + k];
            if (from_member) v -= sect_org;
            if (v >= 0 && v < sect_len) lab[v] = 1;
        }
    }

    /* Now that lab[] exists: the file's own labels join it, its ranges are
     * checked against the section, and each USING's base is resolved to an
     * offset so everything downstream of it is arithmetic. */
    if (hints_file && (rc = hints_bind()) != 0) return rc;

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

    /* Opened LAST, so every refusal above leaves no file behind. */
    outf = outfn ? fopen(outfn, "w") : stdout;
    if (!outf) { perror(outfn); return 16; }

    {
        char rem[64];
        snprintf(rem, sizeof rem, "%ld bytes, from %s", sect_len, src);
        emit(sect_name, "CSECT", "", rem);
    }
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
    rld[nrld].addr = r->addr;
    rld[nrld].len = obj_rld_len(r->flag);
    rld[nrld].r = r->r;
    nrld++;
    return 1;
}
