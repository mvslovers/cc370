/* as370 - host-native MVS assembler for c2asm370 (WP-2/WP-3 skeleton).
 *
 * Reproduces IFOX00 object decks for the reference tests (cards before END
 * byte-identical; END matches except the optional IDR):
 *   sample1.s  named CSECT (SD) + ER, single TXT card
 *   sample3.s  unnamed CSECT (PC) + ENTRY (LD), multi-card TXT, RLD packing
 *   sample4.s  RS (STM/LM), SS (MVC), SI (MVI), B (RX branch), DC C (EBCDIC)
 *
 * Scope: formats RR/RX/RS/SI/SS + extended branches BR/B; directives CSECT
 * (named=SD / unnamed=PC), ENTRY, USING, DROP, DC A/F/C, DS, EQU, LTORG, END;
 * literals =V/=A/=F; explicit d(x,b)/d(len,b)/d(b) operands and symbolic
 * operands via USING. Next: full opcode-table lift, more DC types, the macro
 * processor (WP-4).
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <time.h>

/* bounded string copy that always NUL-terminates (dst must hold n+1 bytes). A
 * plain loop, not strncpy/strncat, so it is free of the (false-positive here)
 * -Wstringop-truncation those builtins draw for a deliberate truncating copy. */
static void scopy(char *d, const char *s, size_t n) { size_t i = 0; while (i < n && s[i]) { d[i] = s[i]; i++; } d[i] = 0; }

/* as370 runs on the host (not MVS), so these limits are sized for real
 * modules, not the 24-bit target. Largest rexx370 CSECT is well under these. */
#define MAXSYM 65536
#define MAXLIT 8192
#define MAXREL 131072
#define TEXTMAX (1024 * 1024)

enum fmt { F_NONE, F_RR, F_RX, F_RS, F_SI, F_SS, F_BR, F_BC, F_SVC, F_S };

struct opc { const char *name; int fmt; int op; int m1; };  /* m1 = implied mask for branch pseudos */
static const struct opc optab[] = {
#include "opc_table.h"
    /* extended branches: BC (RX, op 0x47) / BCR (RR-ish, op 0x07) with implied mask */
    { "B",  F_BC, 0x47, 15 }, { "NOP", F_BC, 0x47, 0 },
    { "BE", F_BC, 0x47, 8 }, { "BNE", F_BC, 0x47, 7 }, { "BH", F_BC, 0x47, 2 }, { "BL", F_BC, 0x47, 4 },
    { "BNH", F_BC, 0x47, 13 }, { "BNL", F_BC, 0x47, 11 }, { "BZ", F_BC, 0x47, 8 }, { "BNZ", F_BC, 0x47, 7 },
    { "BP", F_BC, 0x47, 2 }, { "BM", F_BC, 0x47, 4 }, { "BO", F_BC, 0x47, 1 }, { "BNO", F_BC, 0x47, 14 },
    { "BNP", F_BC, 0x47, 13 }, { "BNM", F_BC, 0x47, 11 },
    { "IPK", F_S, 0xB20B, 0 }, { "SPKA", F_S, 0xB20A, 0 }, { "STCK", F_S, 0xB205, 0 },
    { "BCT", F_RX, 0x46, 0 }, { "SVC", F_SVC, 0x0A, 0 },
    { "BR",  F_BR, 0x07, 15 }, { "BER", F_BR, 0x07, 8 }, { "BNER", F_BR, 0x07, 7 }, { "NOPR", F_BR, 0x07, 0 },
    { "BHR", F_BR, 0x07, 2 }, { "BLR", F_BR, 0x07, 4 }, { "BNHR", F_BR, 0x07, 13 }, { "BNLR", F_BR, 0x07, 11 },
    { "BZR", F_BR, 0x07, 8 }, { "BNZR", F_BR, 0x07, 7 }, { "BPR", F_BR, 0x07, 2 }, { "BMR", F_BR, 0x07, 4 },
    { "BOR", F_BR, 0x07, 1 }, { "BNOR", F_BR, 0x07, 14 },
    { NULL, 0, 0, 0 }
};

enum stype { S_REL, S_SD, S_PC, S_ER, S_LD, S_ABS };
struct sym { char name[9]; long val; int type; int defined; int esdid; int is_entry; int sect; int len; int is_weak; };
static struct sym syms[MAXSYM];
static int nsym;
/* ESD is a list of (symbol, role) events in source order. A name can appear as
 * BOTH an LD (locally defined entry) and an ER (referenced via =V/EXTRN) — IFOX
 * emits two ESD entries in that case, so roles are tracked separately. */
enum esdrole { ESD_SECT, ESD_LD, ESD_ER };
struct esdent { struct sym *s; int role; };
static struct esdent esdord[MAXSYM]; static int nesdord;

struct lit { char text[64]; long loc; long val; int placed; int isV; int isA; int ltseq; char ext[64]; int size; int algn; int sect; };
static struct lit lits[MAXLIT];
static int nlit;
static int litpool = 0;   /* current literal pool (LTORG/END index); literals dedup only within a pool */

struct reloc { long addr; int pos, rel, isV, len; };
static struct reloc rels[MAXREL];
static int nrel;

static unsigned char text[TEXTMAX];
static unsigned char defn[TEXTMAX];   /* 1 = byte has content (for TXT segmentation) */
/* Pass-2 TXT emission log: every put(), in emission order, with the bytes AS
 * WRITTEN -- so an ORG overlay's pre-overwrite bytes survive (the final image
 * keeps only the last write). IFOX punches TXT in this order and cuts a card
 * whenever the next byte's address is not the running card address (IFNX5P
 * PUNRTN: CRDVAL != LOCATN). Contiguous writes are merged into one event so the
 * common (strictly address-increasing) module yields just a few events. */
#define TXL_EV  131072
#define TXL_BUF (TEXTMAX * 2)
static long txl_addr[TXL_EV]; static int txl_len[TXL_EV]; static long txl_boff[TXL_EV];
static int  txl_esdid[TXL_EV];   /* ESDID of the section that emitted each event (for the TXT card's ID, since overlaid sections share an address) */
static unsigned char txl_bytes[TXL_BUF];
static int  ntxl; static long txl_blen, txl_maxend;
static int  txl_on;        /* logging active (pass 2 only) */
static int  txl_revisit;   /* a put() wrote below the high-water mark -> overlap (ORG overlay etc.) */
static long lc, modlen;
static long org_hwm;          /* highest lc reached in the current section (for ORG with no operand) */
static int  in_dsect; static long main_lc; static int main_sect_id;   /* DSECT: dummy section, own counter, no TXT; main_* save the control section on first DSECT entry */
struct uent { int reg; long base; int sect; };   /* active USING ranges */
static struct uent usings[32]; static int nusing;
static int  cur_sect_id, g_sectid;            /* section identity for USING resolution */
static char dsect_sect[256];                  /* dsect_sect[id]=1 if section id is a DSECT (its symbols are absolute) */
static int  cur_sect_esdid, main_sect_esdid;
static int  end_esdid; static long end_addr; static int end_has;
static int  errors;
static char deck_id[9];        /* name field of the first named TITLE -> deck identifier in cols 73-80 */
static char g_sysdate[9];       /* &SYSDATE  -> "MM/DD/YY" (assembly date) */
static char g_systime[6];       /* &SYSTIME  -> "HH.MM"    (assembly time) */
/* as370's own translator identity (working title V2.0; product rename to as370
 * is planned). Stamped into the object's END-record IDR and the -a listing
 * header so the deck identifies itself rather than masquerading as IFOX. */
/* ---- translator identity (single source of truth) -------------------------
 * The CLI tool is "as370" (the cc370/as370/ld370 family); the stamped assembler
 * product is "ASM370". Used in three places: -v, the listing header, and the
 * END-record IDR. */
#define AS370_NAME     "as370"          /* CLI tool name (-v) */
#define AS370_VER_H    "V1.0"           /* human-readable version (-v) */
#define AS370_IDR_PROD "ASM370"         /* 10-char EBCDIC product id, left-justified (listing header + END-record IDR) */
#define AS370_IDR_VER  "0100"           /* 4-char version = 01.00 (listing header + IDR) */
/* "MM/DD/YY" -> Julian "YYDDD" for the END-record IDR date. */
static void julian5(const char *mmddyy, char *out) {
    int mm = 0, dd = 0, yy = 0;
    if (sscanf(mmddyy, "%d/%d/%d", &mm, &dd, &yy) == 3 && mm >= 1 && mm <= 12) {
        static const int cum[] = { 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334 };
        int doy = cum[mm - 1] + dd;
        if (mm > 2 && (yy % 4) == 0) doy++;     /* 20yy leap years (00 is leap) */
        snprintf(out, 8, "%02d%03d", yy % 100, doy);
    } else { scopy(out, "00000", 5); }
}
/* Set &SYSDATE/&SYSTIME from the host clock, or from ASMDATE/ASMTIME in the
 * environment for reproducible builds (verification against a fixed object). */
static void init_sysvars(void) {
    const char *ed = getenv("ASMDATE"), *et = getenv("ASMTIME");
    if (ed && *ed) scopy(g_sysdate, ed, 8);
    if (et && *et) scopy(g_systime, et, 5);
    if (!g_sysdate[0] || !g_systime[0]) {
        time_t t = time(NULL); struct tm *lt = localtime(&t);
        if (lt) {
            if (!g_sysdate[0]) snprintf(g_sysdate, sizeof g_sysdate, "%02u/%02u/%02u",
                                        (unsigned)(lt->tm_mon + 1) % 100u, (unsigned)lt->tm_mday % 100u, (unsigned)lt->tm_year % 100u);
            if (!g_systime[0]) snprintf(g_systime, sizeof g_systime, "%02u.%02u",
                                        (unsigned)lt->tm_hour % 100u, (unsigned)lt->tm_min % 100u);
        }
    }
}

static unsigned char a2e(int c);   /* fwd */
static int hexv(int c);            /* fwd */
static int hex_to_bytes(const char *s, unsigned char *out, int max);   /* fwd */
static int split_fields(const char *s, char f[][64], int max);   /* fwd */

static struct sym *sym_find(const char *n) {
    int i; for (i = 0; i < nsym; i++) if (!strcmp(syms[i].name, n)) return &syms[i];
    return NULL;
}
static struct sym *sym_get(const char *n) {
    struct sym *s = sym_find(n);
    if (s) return s;
    if (nsym >= MAXSYM) { fprintf(stderr, "as370: symbol table full\n"); exit(2); }
    s = &syms[nsym++]; memset(s, 0, sizeof *s); strncpy(s->name, n, 8); s->type = S_REL;
    return s;
}
static void esd_add(struct sym *s, int role) {
    int i; for (i = 0; i < nesdord; i++) if (esdord[i].s == s && esdord[i].role == role) return;
    if (nesdord < MAXSYM) { esdord[nesdord].s = s; esdord[nesdord].role = role; nesdord++; }
}
/* literal-pool segment key: the boundary alignment implied by a length (8/4/2/1). */
static int lenalgn(int len) { return (len % 8 == 0) ? 8 : (len % 4 == 0) ? 4 : (len % 2 == 0) ? 2 : 1; }
/* classify a literal (=A/V/F/H/D/Y/X/C, optional Ln) into byte size + alignment;
 * record the address symbol (A/V/Y) or the numeric value (F/H/D) */
static void lit_classify(struct lit *l) {
    const char *p = l->text + 1;                 /* past '=' */
    while (isdigit((unsigned char)*p)) p++;       /* duplication factor (rare) */
    char ty = toupper((unsigned char)*p++);
    int len = 0, haslen = 0;
    if (*p == 'L') { p++; haslen = 1; while (isdigit((unsigned char)*p)) len = len * 10 + (*p++ - '0'); }
    l->isV = (ty == 'V'); l->isA = (ty == 'A' || ty == 'V' || ty == 'Y');
    if (ty == 'A' || ty == 'V' || ty == 'Y') {
        const char *lp = strchr(p, '('), *rp = strrchr(p, ')');
        if (lp && rp && rp > lp) { int n = (int)(rp - lp - 1); if (n > 63) n = 63; memcpy(l->ext, lp + 1, n); l->ext[n] = 0; }
        int per = haslen ? len : (ty == 'Y' ? 2 : 4);
        char vv[64][64]; int nv = split_fields(l->ext, vv, 64); if (nv < 1) nv = 1;   /* =AL1(a,b,c): one constant per value */
        l->size = per * nv; l->algn = haslen ? 1 : (ty == 'Y' ? 2 : 4);
    } else if (ty == 'F') { const char *q = strchr(p, '\''); l->val = q ? strtol(q + 1, NULL, 10) : 0; l->size = haslen ? len : 4; l->algn = haslen ? 1 : 4;
    } else if (ty == 'H') { const char *q = strchr(p, '\''); l->val = q ? strtol(q + 1, NULL, 10) : 0; l->size = haslen ? len : 2; l->algn = haslen ? 1 : 2;
    } else if (ty == 'D') { const char *q = strchr(p, '\''); l->val = q ? strtol(q + 1, NULL, 10) : 0; l->size = haslen ? len : 8; l->algn = 8;
    } else if (ty == 'X') { const char *q = strchr(p, '\''); unsigned char tmp[260]; int nb = q ? hex_to_bytes(q + 1, tmp, 260) : 0; l->size = haslen ? len : nb; l->algn = 1;
    } else if (ty == 'C') { const char *q = strchr(p, '\''); int sl = 0; if (q) { const char *e = q + 1; while (*e) { if (*e == '\'') { if (e[1] == '\'') { sl++; e += 2; continue; } break; } sl++; e++; } } l->size = haslen ? len : sl; l->algn = 1;
    } else { l->size = 4; l->algn = 4; }
    if (l->size < 1) l->size = 1;
}
static struct lit *lit_get(const char *t) {
    int i; for (i = 0; i < nlit; i++) if (lits[i].ltseq == litpool && !strcmp(lits[i].text, t)) return &lits[i];
    if (nlit >= MAXLIT) { fprintf(stderr, "as370: literal table full\n"); exit(2); }
    memset(&lits[nlit], 0, sizeof lits[0]); strncpy(lits[nlit].text, t, sizeof lits[0].text - 1);
    lits[nlit].ltseq = litpool;          /* literal belongs to the current (not-yet-flushed) pool */
    lits[nlit].sect = cur_sect_id;
    lit_classify(&lits[nlit]);
    if (lits[nlit].isV) {                /* =V: define the external symbol now; its ESD entry is */
        struct sym *s = sym_get(lits[nlit].ext); if (!s->defined) s->type = S_ER;   /* registered when the pool is flushed (LTORG/END), like IFOX */
    }
    return &lits[nlit++];
}

/* evaluate an operand expression: numbers, the location counter '*', symbols,
 * with + - * / (a '*' at the start of a factor is the location counter, a '*'
 * between factors is multiplication). Sets *reloc if any term is relocatable.
 * Stops at a top-level '(' (a subscript), ',' or end — so it also evaluates a
 * displacement like 4+120(13). Not re-entrant (uses parse globals). */
static const char *xp_; static int xrl_;   /* xrl_ = net relocation count of the last expr_val (0 = absolute) */
static long x_add(void);   /* fwd: additive expression (term +/- term ...) */
static long x_factor(int sign) {
    while (*xp_ == ' ') xp_++;
    if (*xp_ == '(') {                                     /* grouping paren in factor position (e.g. 8+(64-1)); a '(' after a term is a subscript and is left to the caller */
        xp_++; int before = xrl_; xrl_ = 0; long v = x_add(); int delta = xrl_;
        xrl_ = before + (sign < 0 ? -delta : delta);
        while (*xp_ == ' ') { xp_++; } if (*xp_ == ')') xp_++;
        return v;
    }
    if (*xp_ == '*') { xp_++; xrl_ += sign; return lc; }   /* location counter (relocatable for USING resolution) */
    if (*xp_ == '-') { xp_++; return -x_factor(-sign); }
    if (*xp_ == '+') { xp_++; return x_factor(sign); }
    if (isdigit((unsigned char)*xp_)) { char *end; long v = strtol(xp_, (char **)&end, 10); xp_ = end; return v; }
    if (*xp_ == 'L' && xp_[1] == '\'') {                  /* L' length attribute in a machine-instruction operand */
        xp_ += 2;
        if (*xp_ == '*') { xp_++; return 1; }
        char nm[64]; int n = 0; while (*xp_ && !strchr("+-*/(), ", *xp_) && n < 63) nm[n++] = *xp_++; nm[n] = 0;
        struct sym *s = sym_find(nm); return s ? (s->len ? s->len : 1) : 1;
    }
    if ((*xp_ == 'X' || *xp_ == 'B' || *xp_ == 'C') && xp_[1] == '\'') {   /* self-defining term */
        char kind = *xp_; xp_ += 2; long v = 0;
        if (kind == 'C') { while (*xp_ && *xp_ != '\'') { v = (v << 8) | a2e((unsigned char)*xp_); xp_++; } }
        else { int base = (kind == 'X') ? 16 : 2; while (*xp_ && *xp_ != '\'') {
                   int c = toupper((unsigned char)*xp_), dv = (c >= '0' && c <= '9') ? c - '0' : (c >= 'A' && c <= 'F') ? c - 'A' + 10 : 0;
                   v = v * base + dv; xp_++; } }
        if (*xp_ == '\'') xp_++;
        return v;
    }
    char nm[64]; int n = 0;
    while (*xp_ && !strchr("+-*/(), ", *xp_) && n < 63) nm[n++] = *xp_++;
    nm[n] = 0;
    struct sym *s = sym_find(nm);
    if (s) { if (s->type == S_SD || s->type == S_PC || s->type == S_REL || s->type == S_ER) xrl_ += sign; return s->val; }
    return 0;
}
static long x_term(int sign) {
    long v = x_factor(sign);
    for (;;) { while (*xp_ == ' ') xp_++;
        if (*xp_ == '*') { xp_++; v *= x_factor(0); }       /* a product is absolute */
        else if (*xp_ == '/') { xp_++; long r = x_factor(0); v = r ? v / r : 0; }
        else break; }
    return v;
}
static long x_add(void) {
    long v = x_term(1);
    for (;;) { while (*xp_ == ' ') xp_++;
        if (*xp_ == '+') { xp_++; v += x_term(1); }
        else if (*xp_ == '-') { xp_++; v -= x_term(-1); }
        else break; }
    return v;
}
static long expr_val(const char *e, int *reloc) {
    xp_ = e; xrl_ = 0;
    while (*xp_ == ' ') xp_++;
    if (!*xp_ || *xp_ == '(' || *xp_ == ',') { if (reloc) *reloc = 0; return 0; }   /* leading '(' = subscript with no displacement prefix */
    long v = x_add();
    if (reloc) *reloc = xrl_;
    return v;
}
/* evaluate a register operand, accepting the (r) parenthesised form (common in
 * macro-expanded model statements, e.g. `LR 0,(3)`); expr_val itself treats a
 * leading '(' as a subscript and returns 0, so strip a fully-enclosing pair. */
static long eval_reg(const char *s) {
    while (*s == ' ') s++;
    if (*s == '(') { int d = 0; const char *p = s;
        for (; *p; p++) { if (*p == '(') d++; else if (*p == ')') { if (--d == 0) break; } }
        if (d == 0 && *p == ')') { const char *q = p + 1; while (*q == ' ') q++;
            if (!*q) { char in[64]; int n = (int)(p - s - 1); if (n > 63) n = 63; memcpy(in, s + 1, n); in[n] = 0; return expr_val(in, NULL); } } }
    return expr_val(s, NULL);
}
static void put(long at, long v, int n) {
    if (in_dsect) return;                       /* a DSECT generates no object text */
    int i; for (i = n - 1; i >= 0; i--) { text[at + i] = (unsigned char)(v & 0xff); defn[at + i] = 1; v >>= 8; }
    if (txl_on) {                               /* record the emission for the TXT writer (emission-order replay) */
        if (at < txl_maxend) txl_revisit = 1;   /* writing below the high-water mark = an overlay */
        if (ntxl > 0 && at == txl_addr[ntxl - 1] + txl_len[ntxl - 1] && cur_sect_esdid == txl_esdid[ntxl - 1]) {   /* contiguous AND same section -> extend the previous event */
            if (txl_blen + n > TXL_BUF) { fprintf(stderr, "as370: TXT log buffer overflow\n"); exit(2); }
            memcpy(txl_bytes + txl_blen, text + at, (size_t)n); txl_len[ntxl - 1] += n; txl_blen += n;
        } else {
            if (ntxl >= TXL_EV || txl_blen + n > TXL_BUF) { fprintf(stderr, "as370: TXT log overflow\n"); exit(2); }
            txl_addr[ntxl] = at; txl_len[ntxl] = n; txl_boff[ntxl] = txl_blen; txl_esdid[ntxl] = cur_sect_esdid;
            memcpy(txl_bytes + txl_blen, text + at, (size_t)n); txl_blen += n; ntxl++;
        }
        if (at + n > txl_maxend) txl_maxend = at + n;
    }
    if (at + n > modlen) modlen = at + n;
}
static long align4(long x) { return (x + 3) & ~3L; }
static long align8(long x) { return (x + 7) & ~7L; }
static int hexv(int c) { if (c >= '0' && c <= '9') return c - '0'; c = toupper((unsigned char)c); if (c >= 'A' && c <= 'F') return c - 'A' + 10; return 0; }
/* parse a hex-constant body (the text between the quotes, stops at the closing
 * quote) into bytes, honouring commas as byte-group separators: X'80,8F,0,0'
 * yields 4 bytes (each group is taken on its own and left-zero-padded to its
 * byte width, so a single-digit group '0' becomes one 0x00 byte). Returns the
 * byte count. A plain X'808F84' (no commas) packs as one even-padded group. */
static int hex_to_bytes(const char *s, unsigned char *out, int max) {
    int nb = 0;
    while (*s && *s != '\'') {
        char g[64]; int gn = 0;
        while (*s && *s != '\'' && *s != ',') { if (isxdigit((unsigned char)*s) && gn < 63) g[gn++] = (char)*s; s++; }
        int s0 = 0;
        if (gn & 1) { if (nb < max) out[nb++] = (unsigned char)hexv(g[0]); s0 = 1; }
        for (; s0 + 1 < gn && nb < max; s0 += 2) out[nb++] = (unsigned char)((hexv(g[s0]) << 4) | hexv(g[s0 + 1]));
        if (*s == ',') s++; else break;
    }
    return nb;
}

/* split operand into fields at top-level (depth-0, unquoted) commas. A comma
 * inside parens or a 'quoted' string is not a separator, so =X'80,8F' and
 * C'a,b' stay intact; the K'/N'/L'/T' attribute apostrophe is not a quote. */
static int split_fields(const char *s, char f[][64], int max) {
    int n = 0, depth = 0, q = 0; const char *start = s, *p = s;
    for (;; p++) {
        if (*p == '\'') { if (q || !(p > s && strchr("KNLT", p[-1]))) q = !q; }
        else if (!q && *p == '(') depth++;
        else if (!q && *p == ')') depth--;
        if ((!q && *p == ',' && depth == 0) || *p == 0) {
            int len = (int)(p - start); if (len > 63) len = 63;
            if (n < max) { memcpy(f[n], start, len); f[n][len] = 0; n++; }
            if (*p == 0) break;
            start = p + 1;
        }
    }
    return n;
}
/* split a DC/DS operand list at top-level commas, respecting 'quoted' strings
 * ('' is an embedded quote) and (parenthesised) sub-expressions */
static int dc_split(const char *s, char f[][1024], int max) {
    int n = 0, depth = 0, inq = 0; const char *start = s, *p = s;
    for (;; p++) {
        char c = *p;
        if (inq) { if (c == '\'') { if (p[1] == '\'') { p++; continue; } inq = 0; } }
        else if (c == '\'') inq = 1;
        else if (c == '(') depth++;
        else if (c == ')') depth--;
        if ((c == ',' && depth == 0 && !inq) || c == 0) {
            int len = (int)(p - start); if (len > 1023) len = 1023;
            if (n < max) { memcpy(f[n], start, len); f[n][len] = 0; n++; }
            if (c == 0) break;
            start = p + 1;
        }
    }
    return n;
}
static long imm_val(const char *s) {
    if (s[0] == 'C' && s[1] == '\'') return a2e((unsigned char)s[2]);
    return expr_val(s, NULL);   /* X'..'/B'..'/decimal/symbol AND arithmetic on them (X'FF'-FLAG) */
}
/* pick the USING covering address val in section sect; returns base reg and
 * displacement. Prefers a same-section USING in range, else any USING in range
 * (so single-USING modules are unaffected), else base 0 / absolute. */
static int using_for(long val, int sect, long *disp) {
    int i, best = -1; long bd = 0;
    for (i = 0; i < nusing; i++) { if (usings[i].sect != sect) continue; long dd = val - usings[i].base; if (dd >= 0 && dd < 4096 && (best < 0 || dd < bd)) { best = i; bd = dd; } }
    if (best < 0) for (i = 0; i < nusing; i++) { long dd = val - usings[i].base; if (dd >= 0 && dd < 4096 && (best < 0 || dd < bd)) { best = i; bd = dd; } }
    if (best >= 0) { *disp = bd; return usings[best].reg; }
    *disp = val; return 0;
}
/* base address that register reg currently addresses via USING (0 if none); used
 * to recover the listing's effective address ADDR = displacement + base. Returns
 * the first matching USING -- which is what using_for picked for a symbolic
 * operand; the two diverge only if a register sits in two USING domains. */
static long using_base_of(int reg) {
    int i; for (i = 0; i < nusing; i++) if (usings[i].reg == reg) return usings[i].base;
    return 0;
}
/* section of a relocatable expression = section of its NET-relocatable term.
 * e.g. IOBSENS0-IOBSTDRD+TAPEIOB: the two IOB fields cancel (same section), so
 * the result is in TAPEIOB's section, not IOBSENS0's. Falls back to cur_sect_id.
 * Sums the sign of each relocatable (non-absolute) symbol term per section and
 * returns the section with a net positive count. */
static int expr_sect(const char *f) {
    int tsect[8]; long tsign[8]; int nt = 0, k;
    const char *p = f; int sign = 1, expect = 1;
    while (*p) {
        if (*p == ' ') { p++; continue; }
        if (*p == '+') { if (!expect) sign = 1; expect = 1; p++; continue; }
        if (*p == '-') { if (!expect) sign = -1; expect = 1; p++; continue; }
        if (*p == '/') { p++; expect = 1; continue; }
        if (*p == '*' && !expect) { p++; expect = 1; continue; }   /* binary multiply */
        if (*p == '(') { int d = 1; p++; while (*p && d) { if (*p == '(') d++; else if (*p == ')') d--; p++; } continue; }
        if (*p == ')') { p++; continue; }
        int csect = -1;
        if (*p == '*') { csect = cur_sect_id; p++; }               /* location counter term */
        else { char nm[64]; int n = 0; while (*p && !strchr("+-*/(), ", *p) && n < 63) nm[n++] = *p++; nm[n] = 0;
            if (nm[0] && !isdigit((unsigned char)nm[0])) { struct sym *s = sym_find(nm); if (s && s->type != S_ABS) csect = s->sect; } }
        if (csect >= 0) { int f2 = -1; for (k = 0; k < nt; k++) if (tsect[k] == csect) { f2 = k; break; }
            if (f2 < 0 && nt < 8) { f2 = nt; tsect[nt] = csect; tsign[nt] = 0; nt++; }
            if (f2 >= 0) tsign[f2] += sign; }
        sign = 1; expect = 0;
    }
    for (k = 0; k < nt; k++) if (tsign[k] > 0) return tsect[k];     /* net +relocatable term */
    for (k = 0; k < nt; k++) if (tsign[k] != 0) return tsect[k];
    return cur_sect_id;
}
/* the relocatable symbol term of an address expression — the RLD target. The
 * first net-positive relocatable symbol (or '*'), skipping self-defining terms
 * and pure numbers, so A(X'80000000'+SYM) targets SYM, not the leading X'..'. */
static void reloc_sym(const char *expr, char *out, int outsz) {
    out[0] = 0;
    const char *p = expr; int sign = 1, expect = 1;
    while (*p) {
        if (*p == ' ') { p++; continue; }
        if (*p == '+') { if (!expect) sign = 1; expect = 1; p++; continue; }
        if (*p == '-') { if (!expect) sign = -1; expect = 1; p++; continue; }
        if (*p == '/') { p++; expect = 1; continue; }
        if (*p == ',') { p++; sign = 1; expect = 1; continue; }     /* multi-value DC A(a,b): term separator */
        if (*p == '*' && !expect) { p++; expect = 1; continue; }    /* binary multiply */
        if (*p == '(') { int d = 1; p++; while (*p && d) { if (*p == '(') d++; else if (*p == ')') d--; p++; } continue; }
        if (*p == ')') { p++; continue; }
        if (*p == '*') { if (sign > 0 && !out[0] && outsz > 1) { out[0] = '*'; out[1] = 0; } p++; sign = 1; expect = 0; continue; }   /* location counter */
        if ((*p == 'X' || *p == 'B' || *p == 'C') && p[1] == '\'') { p += 2; while (*p && *p != '\'') p++; if (*p == '\'') p++; sign = 1; expect = 0; continue; }   /* self-defining term */
        { char nm[64]; int n = 0; while (*p && !strchr("+-*/(), ", *p) && n < 63) nm[n++] = *p++; nm[n] = 0;
          if (!n) { p++; continue; }                                /* unhandled char: advance to guarantee progress */
          if (nm[0] && !isdigit((unsigned char)nm[0])) { struct sym *s = sym_find(nm);
              if (s && (s->type == S_SD || s->type == S_PC || s->type == S_REL || s->type == S_ER) && sign > 0 && !out[0]) {
                  int i = 0; while (nm[i] && i < outsz - 1) { out[i] = nm[i]; i++; } out[i] = 0; } } }
        sign = 1; expect = 0;
    }
}
/* resolve a memory operand into displacement d, index/length a, base b */
/* parse a memory operand: displacement *d, explicit subscripts sub[0..*nsub),
 * *sym=1 for a symbol/literal resolved through USING (then sub[0]=base reg).
 * Subscript->field mapping is format-specific (RX: sub0=index; RS/SI/SS: base). */
static int r_ibase;   /* implied base reg from USING when a paren operand's prefix is relocatable, else -1 */
static int r_len;     /* length attribute L' of the symbol resolved by the last resolve() call (for SS implicit length) */
static void resolve(const char *f, long *d, long sub[4], int *nsub, int *sym) {
    *nsub = 0; *sym = 0; *d = 0; r_ibase = -1; r_len = 0;
    if (f[0] == '=') { struct lit *l = lit_get(f); *sym = 1; r_len = l->size; sub[0] = using_for(l->loc, l->sect, d); return; }
    const char *lp = strchr(f, '(');
    if (lp) {
        int reloc = 0; long v = expr_val(f, &reloc);   /* prefix before '(' (expr_val stops there) */
        if (reloc) {                                   /* SYM(len)/SYM(index): base from the symbol's USING */
            char nm[64]; int nn = 0; const char *e = f; while (*e && !strchr("+-*/(), ", *e) && nn < 63) nm[nn++] = *e++; nm[nn] = 0;
            struct sym *s = sym_find(nm); int ssect = expr_sect(f);
            r_len = s ? s->len : 0;
            r_ibase = using_for(v, ssect, d);
        } else *d = v;                                 /* numeric displacement, e.g. 4+120(13) */
        const char *rp = strchr(lp, ')');
        int n = rp ? (int)(rp - lp - 1) : (int)strlen(lp + 1);
        char inside[64]; if (n > 63) n = 63; memcpy(inside, lp + 1, n); inside[n] = 0;
        char *tok = inside;
        while (1) { char *cm = strchr(tok, ','); int len = cm ? (int)(cm - tok) : (int)strlen(tok);
            char t[32]; if (len > 31) len = 31; memcpy(t, tok, len); t[len] = 0;
            if (*nsub < 4) sub[(*nsub)++] = t[0] ? expr_val(t, NULL) : 0;   /* base/index may be a symbol (R13 EQU 13) */
            if (!cm) break;
            tok = cm + 1; }
    } else {
        int reloc = 0; long v = expr_val(f, &reloc);
        if (reloc) {                                   /* relocatable: address via USING (of the symbol's section) */
            char nm[64]; int n = 0; const char *e = f; while (*e && !strchr("+-*/(), ", *e) && n < 63) nm[n++] = *e++; nm[n] = 0;
            struct sym *s = sym_find(nm); int ssect = expr_sect(f);
            r_len = s ? s->len : 0;
            *sym = 1; sub[0] = using_for(v, ssect, d);
        } else { *d = v; *sym = 0; sub[0] = 0; }       /* absolute: displacement value, base 0 */
    }
}

/* parse a statement into label / opcode / operand. The operand field ends at
 * the first blank that is NOT inside a quoted string (so DC C'A B' works); the
 * trailing comment is dropped. */
static int parse(const char *line, char *lbl, char *op, char *opnd) {
    const char *p = line; int i;
    lbl[0] = op[0] = opnd[0] = 0;
    if (*p == '*') return 0;
    if (*p != ' ' && *p != '\t' && *p != '\n' && *p != 0) {
        /* ordinary symbol labels cap at 8; a variable-symbol label may carry a
         * subscript (&ARR(&IDX)) and run longer, so allow the full token there. */
        int cap = (*p == '&') ? 30 : 8;
        i = 0; while (*p && !isspace((unsigned char)*p)) { if (i < cap) lbl[i++] = *p; p++; } lbl[i < cap ? i : cap] = 0;
    }
    while (*p == ' ' || *p == '\t') p++;
    if (!*p || *p == '\n') return op[0] != 0;
    i = 0; while (*p && !isspace((unsigned char)*p)) { if (i < 8) op[i++] = *p; p++; } op[i < 8 ? i : 8] = 0;
    while (*p == ' ' || *p == '\t') p++;
    if (!*p || *p == '\n') return 1;
    i = 0; { int q = 0, d = 0; while (*p && *p != '\n') {
        if (*p == '\'') q = !q;
        else if (!q && *p == '(') d++;
        else if (!q && *p == ')') { if (d) d--; }
        if (!q && d == 0 && (*p == ' ' || *p == '\t')) break;
        if (i < 1023) opnd[i++] = *p;
        p++;
    } }
    opnd[i] = 0;
    return 1;
}
static const struct opc *op_find(const char *n) {
    int i; for (i = 0; optab[i].name; i++) if (!strcmp(optab[i].name, n)) return &optab[i];
    return NULL;
}
static void add_reloc(long at, const char *target, int isV) {
    if (in_dsect) return;                       /* a dummy section generates no relocations */
    struct sym *s = sym_find(target);
    int rel = (s && s->esdid) ? s->esdid : cur_sect_esdid;
    if (nrel >= MAXREL) { fprintf(stderr, "as370: reloc table full\n"); exit(2); }
    rels[nrel].addr = at; rels[nrel].pos = cur_sect_esdid; rels[nrel].rel = rel; rels[nrel].isV = isV; rels[nrel].len = 4; nrel++;
}
static int ins_len(int fmt) { return (fmt == F_RR || fmt == F_BR || fmt == F_SVC) ? 2 : (fmt == F_SS) ? 6 : 4; }

/* ---- WP-4 macro preprocessor --------------------------------------------- */
#define MAXLINES 131072
/* per-expanded-line listing flags, parallel to the flattened lines[] array */
#define LF_GEN   1     /* macro-generated statement (listed with '+') */
#define LF_NOASM 2     /* listing-only (e.g. the macro call line): shown, not assembled */
static unsigned char lflags[MAXLINES];
static int g_genlevel;  /* >0 while inside a macro expansion (distinguishes generated lines from COPY'd source) */
/* per-statement listing data captured in pass 2 (LOC + emitted bytes + effective operand addresses) */
struct lrec { long loc; int len; long a1, a2; unsigned char hasa1, hasa2; };
static struct lrec lrecs[MAXLINES];
/* The verbatim 80-column source image for the listing's SOURCE column. For a
 * macro-generated line this is the model card with variable symbols substituted
 * IN PLACE (field start-columns preserved, cols 73-80 carried through) -- which
 * is what IFOX prints; the normalised lines[] text would lose that layout. NULL
 * for an ordinary source line, where lines[] is already the verbatim card. */
static char *gcard[MAXLINES];
static const char *g_genimg;   /* image for the single line the next mexp_line emits */
/* source-file line number each expanded line derives from (for diagnostics): an
 * open-code statement -> its own line; a macro/COPY-generated line -> the line of
 * the call/COPY in the input file. g_curorg is the line currently being expanded. */
static int line_org[MAXLINES];
static int g_curorg;
struct macro {
    char namep[20], name[16];
    char pname[100][20], pdef[100][40]; int pkey[100]; int nparm;   /* DCB has ~96 keyword params */
    char *body[4096]; int nbody;
    char *bodyseq[4096];           /* cols 73-80 of each body card, for the listing's SOURCE column (NULL if unknown) */
    char endlbl[20];               /* sequence symbol on the MEND line, if any */
};
static struct macro macros[256];
static int nmac;
static struct macro *mac_find(const char *n) {
    int i; for (i = 0; i < nmac; i++) if (!strcmp(macros[i].name, n)) return &macros[i];
    return NULL;
}
/* ---- macro expansion context + conditional assembly --------------------- */
struct ctx {
    struct macro *m;
    char pv[100][96];                      /* parameter values (may be sublists) */
    const char *namepval;
    char sn[256][20], sv[256][96]; int nset;  /* local SET symbols */
    int sysndx;                            /* &SYSNDX for this macro invocation */
    char syslist[32][128]; int nsyslist;   /* &SYSLIST: positional operands in order */
    char arrb[48][20]; char arrnum[48]; int narr;   /* declared SET arrays: base name + 1 if numeric (A/B) */
};
/* Global SET symbols (GBLA/GBLB/GBLC) are shared between open code and every
 * macro expansion. A name declared global anywhere routes through the global
 * store; everything else is local to the macro (or open-code) context. */
static char g_gbl[64][20]; static int g_ngbl;
static char g_sn[512][20], g_sv[512][96]; static int g_nset;
static void base_of(const char *n, char *b) { int i = 0; while (n[i] && n[i] != '(' && i < 19) { b[i] = n[i]; i++; } b[i] = 0; }
static int is_global(const char *n) { char b[20]; base_of(n, b); int i; for (i = 0; i < g_ngbl; i++) if (!strcmp(g_gbl[i], b)) return 1; return 0; }
static void mark_global(const char *n) { char b[20]; base_of(n, b); if (is_global(b)) return; if (g_ngbl < 64) { scopy(g_gbl[g_ngbl], b, 19); g_ngbl++; } }
static char *set_find(struct ctx *c, const char *n) {
    if (is_global(n)) { int i; for (i = 0; i < g_nset; i++) if (!strcmp(g_sn[i], n)) return g_sv[i]; return NULL; }
    int i; for (i = 0; i < c->nset; i++) if (!strcmp(c->sn[i], n)) return c->sv[i];
    return NULL;
}
static void set_put(struct ctx *c, const char *n, const char *v) {
    if (is_global(n)) {
        int i; for (i = 0; i < g_nset; i++) if (!strcmp(g_sn[i], n)) { strncpy(g_sv[i], v, 95); g_sv[i][95] = 0; return; }
        if (g_nset < 512) { strncpy(g_sn[g_nset], n, 19); g_sn[g_nset][19] = 0; strncpy(g_sv[g_nset], v, 95); g_sv[g_nset][95] = 0; g_nset++; }
        return;
    }
    char *e = set_find(c, n);
    if (e) { strncpy(e, v, 95); e[95] = 0; return; }
    if (c->nset < 256) { strncpy(c->sn[c->nset], n, 19); c->sn[c->nset][19] = 0;
                        strncpy(c->sv[c->nset], v, 95); c->sv[c->nset][95] = 0; c->nset++; }
}
/* sublist value "(a,b,c)" -> element count / 1-based element. Commas and the
 * closing paren are recognised only at top level, outside 'quotes' (so a
 * quoted element containing (), commas is kept whole). */
static int sub_count(const char *v) {
    if (!v[0]) return 0;
    if (v[0] != '(') return 1;
    int n = 1, d = 0, q = 0; const char *p;
    for (p = v + 1; *p; p++) {
        if (*p == '\'') q = !q;
        else if (q) ;
        else if (*p == '(') d++;
        else if (*p == ')') { if (d == 0) break; d--; }
        else if (*p == ',' && d == 0) n++;
    }
    return n;
}
static void sub_elem(const char *v, int idx, char *out) {
    out[0] = 0;
    if (v[0] != '(') { if (idx == 1) { strncpy(out, v, 95); out[95] = 0; } return; }
    const char *s = v + 1, *p = s; int n = 1, d = 0, q = 0;
    for (;; p++) {
        if (*p == '\'') { q = !q; continue; }
        if (!q && *p == '(') { d++; continue; }
        if ((!q && *p == ',' && d == 0) || (!q && *p == ')' && d == 0) || !*p) {
            if (n == idx) { int L = (int)(p - s); if (L > 95) L = 95; memcpy(out, s, L); out[L] = 0; return; }
            n++; s = p + 1; if ((*p == ')' && d == 0) || !*p) return;
        } else if (!q && *p == ')') d--;
    }
}
static long eval_seta(struct ctx *c, const char *s);   /* fwd: vref evaluates subscripts */
static const char *ep_; static struct ctx *ec_;        /* SETA parser state (tentative) */
/* value of a "&name" / "&name(idx)" reference. For a macro parameter the
 * subscript selects a sublist element; for a SET symbol it selects an array
 * element &name(idx), stored under the flat name "&name(N)". */
static void vref(struct ctx *c, const char *ref, char *out) {
    out[0] = 0;
    const char *p = ref + 1; char nm[24]; int i = 0;
    while (*p && (isalnum((unsigned char)*p) || *p=='@'||*p=='#'||*p=='$'||*p=='_') && i < 22) nm[i++] = *p++;
    nm[i] = 0;
    if (!strcmp(nm, "SYSNDX")) { snprintf(out, 96, "%04d", c->sysndx); return; }   /* unique per macro invocation */
    if (!strcmp(nm, "SYSDATE")) { scopy(out, g_sysdate, 8); return; }   /* assembly date "MM/DD/YY" */
    if (!strcmp(nm, "SYSTIME")) { scopy(out, g_systime, 5); return; }   /* assembly time "HH.MM" */
    char amp[26]; snprintf(amp, sizeof amp, "&%s", nm);
    const char *base = NULL; int k, is_param = 0;
    char slbuf[1024];
    if (!strcmp(nm, "SYSLIST")) {                 /* positional operands as a synthetic sublist */
        int o = 0; slbuf[o++] = '(';
        for (k = 0; k < c->nsyslist; k++) { if (k) slbuf[o++] = ','; const char *v = c->syslist[k]; while (*v && o < 1022) slbuf[o++] = *v++; }
        slbuf[o++] = ')'; slbuf[o] = 0; base = slbuf; is_param = 1;
    }
    else if (c->m && c->m->namep[0] && !strcmp(amp, c->m->namep)) { base = c->namepval ? c->namepval : ""; is_param = 1; }
    else if (c->m) for (k = 0; k < c->m->nparm; k++) if (!strcmp(amp, c->m->pname[k])) { base = c->pv[k]; is_param = 1; break; }   /* open code: c->m is NULL -> resolve via the SET/global store below */
    if (*p == '(') {
        char idxs[64]; const char *rp = strchr(p, ')'); int L = rp ? (int)(rp - p - 1) : (int)strlen(p + 1); if (L > 63) L = 63; memcpy(idxs, p + 1, L); idxs[L] = 0;
        const char *sep = ep_; struct ctx *sec = ec_; long idx = eval_seta(c, idxs); ep_ = sep; ec_ = sec;   /* save/restore parser state */
        if (is_param) sub_elem(base ? base : "", (int)idx, out);
        else { char cn[40]; snprintf(cn, sizeof cn, "%s(%ld)", amp, idx); char *v = set_find(c, cn);
            if (v) { strncpy(out, v, 95); out[95] = 0; }
            else { int a; const char *def = ""; for (a = 0; a < c->narr; a++) if (!strcmp(c->arrb[a], amp)) { def = c->arrnum[a] ? "0" : ""; break; } strncpy(out, def, 95); out[95] = 0; } }   /* unset array element -> default */
    } else {
        if (!is_param) base = set_find(c, amp);
        if (!base) base = "";
        strncpy(out, base, 95); out[95] = 0;
    }
}
/* substitute all & references in a model statement (with &x. concatenation) */
static void msub(struct ctx *c, const char *src, char *dst) {
    int di = 0; const char *s = src;
    while (*s) {
        if (*s == '&' && (s[1] == '&')) { dst[di++] = '&'; s += 2; continue; }
        if (*s == '&') {
            char ref[44]; int ri = 0; ref[ri++] = *s; const char *p = s + 1;
            while (*p && (isalnum((unsigned char)*p) || *p=='@'||*p=='#'||*p=='$'||*p=='_') && ri < 30) ref[ri++] = *p++;
            if (*p == '(') { ref[ri++] = '('; p++; int d = 1; while (*p && d && ri < 42) { if (*p=='(')d++; else if(*p==')'){d--; if(!d){p++;break;}} ref[ri++]=*p++; } ref[ri++] = ')'; }
            ref[ri] = 0;
            char v[96]; vref(c, ref, v); int r; for (r = 0; v[r]; r++) dst[di++] = v[r];
            s = p; if (*s == '.') s++;
        } else dst[di++] = *s++;
    }
    dst[di] = 0;
}
/* SETA arithmetic evaluator: numbers, &refs, N'/K'/L' attributes, + - * / ( ) */
static const char *ep_; static struct ctx *ec_;
static long e_expr(void);
static void e_sp(void) { while (*ep_ == ' ') ep_++; }
static void e_readref(char *ref) {
    int i = 0; ref[i++] = *ep_++;
    while (*ep_ && (isalnum((unsigned char)*ep_) || *ep_=='@'||*ep_=='#'||*ep_=='$'||*ep_=='_')) ref[i++] = *ep_++;
    if (*ep_ == '(') { ref[i++] = *ep_++; int d = 1; while (*ep_ && d) { if (*ep_=='(')d++; else if(*ep_==')')d--; ref[i++]=*ep_++; } }
    ref[i] = 0;
}
/* value of a self-defining term or decimal held in a string (e.g. a SETC value
 * referenced in arithmetic context): X'..' hex, B'..' binary, C'..' EBCDIC, or
 * an optionally signed decimal. Used where a &var's stored text is a number. */
static long selfdef(const char *s) {
    while (*s == ' ') s++;
    int neg = 0; if (*s == '+') s++; else if (*s == '-') { neg = 1; s++; }
    long v = 0;
    if ((*s == 'X' || *s == 'B' || *s == 'C') && s[1] == '\'') {
        int kind = *s; s += 2;
        if (kind == 'X') { while (*s && *s != '\'') v = v * 16 + hexv(*s++); }
        else if (kind == 'B') { while (*s && *s != '\'') v = v * 2 + (*s++ == '1' ? 1 : 0); }
        else { while (*s && *s != '\'') { if (*s == '\'' && s[1] == '\'') s++; v = (v << 8) | a2e((unsigned char)*s++); } }
    } else v = atol(s);
    return neg ? -v : v;
}
static long e_prim(void) {
    e_sp();
    if (*ep_ == '(') { ep_++; long v = e_expr(); e_sp(); if (*ep_ == ')') ep_++; return v; }
    if ((*ep_ == 'N' || *ep_ == 'K' || *ep_ == 'L') && ep_[1] == '\'') {
        int kind = *ep_; ep_ += 2; char ref[44], v[96];
        if (*ep_ == '&') { e_readref(ref); vref(ec_, ref, v); } else v[0] = 0;
        return (kind == 'N') ? sub_count(v) : (long)strlen(v);
    }
    if ((*ep_ == 'X' || *ep_ == 'B' || *ep_ == 'C') && ep_[1] == '\'') {   /* self-defining term */
        int kind = *ep_; long v = 0; ep_ += 2;
        if (kind == 'X') { while (*ep_ && *ep_ != '\'') v = v * 16 + hexv(*ep_++); }
        else if (kind == 'B') { while (*ep_ && *ep_ != '\'') v = v * 2 + (*ep_++ == '1' ? 1 : 0); }
        else { while (*ep_ && *ep_ != '\'') { if (*ep_ == '\'' && ep_[1] == '\'') ep_++; v = (v << 8) | a2e((unsigned char)*ep_++); } }   /* C': EBCDIC byte values */
        if (*ep_ == '\'') ep_++;
        return v;
    }
    if (*ep_ == '&') { char ref[44], v[96]; e_readref(ref); vref(ec_, ref, v); return selfdef(v); }
    return strtol(ep_, (char **)&ep_, 10);
}
static long e_term(void) {
    long v = e_prim();
    for (;;) { e_sp(); if (*ep_ == '*') { ep_++; v *= e_prim(); } else if (*ep_ == '/') { ep_++; long r = e_prim(); v = r ? v / r : 0; } else break; }
    return v;
}
static long e_expr(void) {
    e_sp(); int neg = 0; if (*ep_ == '+') ep_++; else if (*ep_ == '-') { neg = 1; ep_++; }
    long v = e_term(); if (neg) v = -v;
    for (;;) { e_sp(); if (*ep_ == '+') { ep_++; v += e_term(); } else if (*ep_ == '-') { ep_++; v -= e_term(); } else break; }
    return v;
}
static long eval_seta(struct ctx *c, const char *s) { ec_ = c; ep_ = s; return e_expr(); }
/* canonicalise a SET symbol name: a subscripted array label &B(&I2) becomes the
 * flat name &B(N) with the index evaluated; a scalar name is returned as-is. */
static void set_canon(struct ctx *c, const char *name, char *out) {
    const char *lp = strchr(name, '(');
    if (!lp) { strncpy(out, name, 39); out[39] = 0; return; }
    int b = (int)(lp - name); if (b > 32) b = 32; memcpy(out, name, b);
    char idxs[64]; const char *rp = strchr(lp, ')'); int L = rp ? (int)(rp - lp - 1) : (int)strlen(lp + 1); if (L > 63) L = 63; memcpy(idxs, lp + 1, L); idxs[L] = 0;
    const char *sep = ep_; struct ctx *sec = ec_; long v = eval_seta(c, idxs); ep_ = sep; ec_ = sec;
    snprintf(out + b, 40 - b, "(%ld)", v);
}
/* SETC: 'string'(with subst, optional substring (s,l)) or a bare &ref */
static void eval_setc(struct ctx *c, const char *s, char *out) {
    out[0] = 0; int olen = 0; const char *p = s;
    /* a SETC operand is one or more terms joined by '.' (concatenation); each
     * term is a 'quoted' string (optionally msub'd, optional (start,len)
     * substring) or a &variable. */
    while (*p) {
        while (*p == ' ') p++;
        if (!*p) break;
        char piece[256]; piece[0] = 0;
        if (*p == '\'') {
            char inner[256]; int il = 0; const char *q = p + 1;   /* scan to the closing quote, de-escaping doubled '' to a single ' */
            while (*q) { if (*q == '\'') { if (q[1] == '\'') { if (il < 255) inner[il++] = '\''; q += 2; continue; } break; }
                if (il < 255) { inner[il++] = *q; } q++; }
            inner[il] = 0;
            char sub[256]; msub(c, inner, sub);
            p = (*q == '\'') ? q + 1 : q;
            if (*p == '(') {                       /* substring (start,len) */
                ec_ = c; ep_ = p + 1; long st = e_expr(); e_sp(); long ln = 0;
                if (*ep_ == ',') { ep_++; ln = e_expr(); }
                if (*ep_ == ')') ep_++;
                p = ep_;
                int n = (int)strlen(sub), a = (int)st - 1; if (a < 0) a = 0; if (a > n) a = n;
                int take = (int)ln; if (take > n - a) take = n - a; if (take < 0) take = 0;
                memcpy(piece, sub + a, take); piece[take] = 0;
            } else { strncpy(piece, sub, 255); piece[255] = 0; }
        } else if (*p == '&') {
            char ref[64]; int i = 0; ref[i++] = *p++;
            while (*p && (isalnum((unsigned char)*p) || *p=='@'||*p=='#'||*p=='$'||*p=='_') && i < 62) ref[i++] = *p++;
            if (*p == '(') { ref[i++] = *p++; int d = 1; while (*p && d && i < 62) { if (*p=='(')d++; else if(*p==')')d--; ref[i++]=*p++; } }
            ref[i] = 0; vref(c, ref, piece);
        } else {                                   /* bare text up to a '.' */
            int i = 0; while (*p && *p != '.' && *p != ' ' && i < 255) piece[i++] = *p++; piece[i] = 0;
        }
        int pl = (int)strlen(piece); if (olen + pl > 95) pl = 95 - olen; if (pl < 0) pl = 0;
        memcpy(out + olen, piece, pl); olen += pl; out[olen] = 0;
        if (*p == '.') p++;                        /* concatenation */
        else break;
    }
}
/* a comparison term is character if quoted or a T' (type) attribute */
static int term_is_str(const char *t) { return t[0] == '\'' || (t[0] == 'T' && t[1] == '\''); }
static void term_str(struct ctx *c, const char *t, char *out) {
    if (t[0] == 'T' && t[1] == '\'') {
        char ref[44], v[96]; const char *p = t + 2; int i = 0;
        if (*p == '&') { ref[i++] = *p++; while (*p && (isalnum((unsigned char)*p) || *p=='@'||*p=='#'||*p=='$'||*p=='_')) ref[i++] = *p++;
            if (*p == '(') { ref[i++] = *p++; int d = 1; while (*p && d) { if (*p=='(')d++; else if(*p==')')d--; ref[i++]=*p++; } } ref[i] = 0; vref(c, ref, v); }
        else v[0] = 0;
        if (!v[0]) strcpy(out, "O");
        else { int alln = 1, j; for (j = 0; v[j]; j++) if (!isdigit((unsigned char)v[j])) { alln = 0; break; } strcpy(out, alln ? "N" : "U"); }
    } else eval_setc(c, t, out);
}
static int rel_apply(const char *rel, int cmp) {
    if (!strcmp(rel, "EQ")) return cmp == 0;
    if (!strcmp(rel, "NE")) return cmp != 0;
    if (!strcmp(rel, "GT")) return cmp > 0;
    if (!strcmp(rel, "LT")) return cmp < 0;
    if (!strcmp(rel, "GE")) return cmp >= 0;
    if (!strcmp(rel, "LE")) return cmp <= 0;
    return 0;
}
static int eval_comp(struct ctx *c, const char *L, const char *rel, const char *R) {
    int cmp;
    if (term_is_str(L) || term_is_str(R)) { char ls[128], rs[128]; term_str(c, L, ls); term_str(c, R, rs); cmp = strcmp(ls, rs); }
    else { long lv = eval_seta(c, L), rv = eval_seta(c, R); cmp = (lv < rv) ? -1 : (lv > rv) ? 1 : 0; }
    return rel_apply(rel, cmp);
}
/* evaluate an AIF condition: comparisons joined by AND/OR (left to right) */
static int eval_cond(struct ctx *c, const char *cond);
static int is_relop(const char *s) {
    return !strcmp(s, "EQ") || !strcmp(s, "NE") || !strcmp(s, "LT") || !strcmp(s, "GT") || !strcmp(s, "LE") || !strcmp(s, "GE");
}
static int cnd_bool(struct ctx *c, const char *t) {           /* a single boolean factor */
    if (t[0] == '(') { int L = (int)strlen(t); if (L >= 2 && t[L - 1] == ')') { char in[128]; int n = L - 2 > 127 ? 127 : L - 2; memcpy(in, t + 1, n); in[n] = 0; return eval_cond(c, in); } }
    return eval_seta(c, t) != 0;                               /* SETB var / arithmetic: nonzero = true */
}
static int eval_cond(struct ctx *c, const char *cond) {
    char toks[32][96]; int nt = 0; const char *p = cond;
    while (*p) {
        while (*p == ' ') p++;
        if (!*p) break;
        char *o = toks[nt]; int q = 0, d = 0, oi = 0, closed = 0;
        while (*p && (q || d || *p != ' ')) {
            if (!q && d == 0 && closed && isalpha((unsigned char)*p)) break;  /* a relop/keyword abutting a closing quote ('A'NE'B', after a col-72 join) is its own token */
            closed = 0;
            if (*p == '\'') { if (q || !(oi > 0 && strchr("KNLT", o[oi - 1]))) { int wq = q; q = !q; if (wq && !q) closed = 1; } }  /* K'/N'/L'/T' apostrophe is an attribute, not a string quote */
            else if (!q && *p == '(') {
                if (d == 0 && oi > 0) { o[oi] = 0;                       /* a logical operator abutting '(' (NOT(..)/AND(..)/OR(..)) is its own token, not a subscript */
                    if (!strcmp(o, "NOT") || !strcmp(o, "AND") || !strcmp(o, "OR")) break; }
                d++;
            } else if (!q && *p == ')') d--;
            if (oi < 95) o[oi++] = *p;
            p++; }
        o[oi] = 0; if (nt < 31) nt++;
    }
    /* factors joined by AND/OR, left to right; a factor is [NOT] (comparison | bool) */
    int i = 0, acc = 0, first = 1; char conn[4] = "";
    while (i < nt) {
        if (!first) { if (!strcmp(toks[i], "AND") || !strcmp(toks[i], "OR")) { strcpy(conn, toks[i]); i++; } else break; }
        int neg = 0; while (i < nt && !strcmp(toks[i], "NOT")) { neg = !neg; i++; }
        int v;
        if (i + 2 < nt && is_relop(toks[i + 1])) { v = eval_comp(c, toks[i], toks[i + 1], toks[i + 2]); i += 3; }
        else if (i < nt) { v = cnd_bool(c, toks[i]); i++; }
        else break;
        if (neg) v = !v;
        if (first) { acc = v; first = 0; }
        else if (!strcmp(conn, "AND")) acc = acc && v;
        else if (!strcmp(conn, "OR")) acc = acc || v;
    }
    return acc;
}
/* split "(cond)seqsym" -> cond (no outer parens), seqsym */
static void aif_split(const char *opnd, char *cond, char *seq) {
    cond[0] = seq[0] = 0; const char *p = opnd; if (*p != '(') return;
    int d = 0, q = 0; const char *cs = p + 1;
    for (; *p; p++) { if (*p == '\'') { if (q || p == opnd || !strchr("KNLT", p[-1])) q = !q; }  /* K'/N'/L'/T' attribute apostrophe */
        else if (!q && *p == '(') { d++; if (d == 1) cs = p + 1; }
        else if (!q && *p == ')') { if (--d == 0) {
            int L = (int)(p - cs); if (L > 126) L = 126; memcpy(cond, cs, L); cond[L] = 0;
            const char *s = p + 1; int si = 0; while (*s && !isspace((unsigned char)*s) && si < 18) seq[si++] = *s++;  /* sequence symbol only */
            seq[si] = 0; return; } } }
}

/* ---- macro library (-I dirs): COPY members + macro lookup by name -------- */
#define MAXMACLIB 16
static char *maclib_dirs[MAXMACLIB]; static int nmaclib;
static int lib_path(const char *name, char *path) {
    const char *exts[] = { ".macro", ".copy", ".mac", ".asm", "", NULL };
    char low[40]; int i; for (i = 0; name[i] && i < 39; i++) low[i] = (char)tolower((unsigned char)name[i]); low[i] = 0;
    int di, e;
    for (di = 0; di < nmaclib; di++) for (e = 0; exts[e]; e++) {
        snprintf(path, 256, "%s/%s%s", maclib_dirs[di], low, exts[e]);
        FILE *f = fopen(path, "r"); if (f) { fclose(f); return 1; }
    }
    return 0;
}
/* join assembler continuation lines: a non-blank in column 72 continues the
 * statement on the next line starting at column 16. Comment lines (* / .*) are
 * never continued. Operates on raw[] and on every macro/COPY library read. */
static int rawlen(const char *l) { int n = (int)strlen(l); while (n > 0 && (l[n-1] == '\n' || l[n-1] == '\r')) n--; return n; }
/* seqout (optional) receives cols 73-80 of each output line's primary card --
 * the library sequence number the listing's SOURCE column carries through. */
static int join_cont(char **in, int n, char **out, int maxout, char (*seqout)[12], int *org) {
    int i = 0, no = 0;
    while (i < n && no < maxout) {
        const char *l = in[i];
        if (org) org[no] = i + 1;   /* 1-based input line of this statement's first card */
        if (seqout) { int k, sl = rawlen(l); for (k = 0; k < 8; k++) seqout[no][k] = (72 + k < sl) ? l[72 + k] : ' '; seqout[no][8] = 0; }
        if (l[0] == '*' || (l[0] == '.' && l[1] == '*')) { out[no++] = strdup(l); i++; continue; }
        char acc[8192]; int a = 0, len = rawlen(l), copy = len > 71 ? 71 : len;
        acc[0] = 0; memcpy(acc, l, copy); a = copy;
        int cont = (len > 71 && l[71] != ' ');
        i++;
        /* operand field starts after the label (col 1) and the opcode */
        int os = 0;
        if (acc[0] != ' ' && acc[0] != '\t') while (os < a && acc[os] != ' ' && acc[os] != '\t') os++;
        while (os < a && (acc[os] == ' ' || acc[os] == '\t')) os++;
        while (os < a && acc[os] != ' ' && acc[os] != '\t') os++;
        while (os < a && (acc[os] == ' ' || acc[os] == '\t')) os++;
        while (cont && i < n) {
            /* a continued line's operands end at the first top-level blank (outside
             * quotes/parens); drop the trailing comment before joining the next line
             * so e.g. `DCB &MACRF=,  FOUNDATION BLOCK` + continuation keeps the comma */
            int j, q = 0, d = 0;
            for (j = os; j < a; j++) { char ch = acc[j];
                if (ch == '\'') q = !q;
                else if (!q && ch == '(') d++;
                else if (!q && ch == ')') { if (d) d--; }
                else if (!q && d == 0 && (ch == ' ' || ch == '\t')) { a = j; break; }
            }
            const char *c = in[i]; int cl = rawlen(c), s = 15, e = cl > 71 ? 71 : cl;
            for (; s < e && a < 8190; s++) acc[a++] = c[s];
            cont = (cl > 71 && c[71] != ' ');
            i++;
        }
        acc[a++] = '\n'; acc[a] = 0;
        out[no++] = strdup(acc);
    }
    return no;
}
static int lib_readlines(const char *name, char *buf[], int max, char (*seqbuf)[12]) {
    char path[256]; if (!lib_path(name, path)) return -1;
    FILE *f = fopen(path, "r"); if (!f) return -1;
    static char *tmp[16384]; char lb[256]; int n = 0;
    while (fgets(lb, sizeof lb, f) && n < 16384) tmp[n++] = strdup(lb);
    fclose(f);
    return join_cont(tmp, n, buf, max, seqbuf, NULL);
}
static struct macro *capture_macro(char **in, int nin, int *ip, char (*inseq)[12]) {
    int i = *ip + 1; if (i >= nin) { *ip = i; return NULL; }
    char pb[4096], pl[32], po[16], pp[4096]; strncpy(pb, in[i], 4095); pb[4095] = 0; parse(pb, pl, po, pp);
    { const char *p = pb;                 /* re-extract the full prototype operand (parse caps at 1023; DCB's list is longer) */
        if (*p && !isspace((unsigned char)*p)) while (*p && !isspace((unsigned char)*p)) p++;   /* skip label */
        while (*p == ' ' || *p == '\t') p++;
        while (*p && !isspace((unsigned char)*p)) p++;                                          /* skip opcode */
        while (*p == ' ' || *p == '\t') p++;
        int oi = 0, q = 0, d = 0; while (*p && *p != '\n') {
            if (*p == '\'') q = !q; else if (!q && *p == '(') d++; else if (!q && *p == ')') { if (d) d--; }
            if (!q && d == 0 && (*p == ' ' || *p == '\t')) break;
            if (oi < 4095) { pp[oi++] = *p; } p++; }
        pp[oi] = 0; }
    struct macro *m = &macros[nmac++]; memset(m, 0, sizeof *m);
    scopy(m->namep, pl, sizeof m->namep - 1); scopy(m->name, po, sizeof m->name - 1);
    if (pp[0]) { char flds[100][64]; int nf = split_fields(pp, flds, 100), k;
        for (k = 0; k < nf && k < 100; k++) { char *eq = strchr(flds[k], '=');
            if (eq) { *eq = 0; scopy(m->pname[k], flds[k], 19); scopy(m->pdef[k], eq + 1, 39); m->pkey[k] = 1; }
            else scopy(m->pname[k], flds[k], 19);
            m->nparm++; } }
    while (++i < nin) { char bb[256], bl[32], bo[16], bd[128]; strncpy(bb, in[i], 255); bb[255] = 0; parse(bb, bl, bo, bd);
        if (!strcmp(bo, "MEND")) { if (bl[0] == '.') scopy(m->endlbl, bl, sizeof m->endlbl - 1); break; }
        if (m->nbody < 4096) { m->bodyseq[m->nbody] = (inseq ? strdup(inseq[i]) : NULL); m->body[m->nbody++] = strdup(in[i]); } }
    *ip = i; return m;
}
static struct macro *lib_load(const char *name) {
    struct macro *m = mac_find(name); if (m) return m;
    static char *buf[4096]; static char seqbuf[4096][12];
    int n = lib_readlines(name, buf, 4096, seqbuf); if (n < 0) return NULL;
    int i = 0; for (; i < n; i++) { char b[256], l[16], o[16], od[128]; strncpy(b, buf[i], 255); b[255] = 0;
        if (!parse(b, l, o, od) || !o[0]) continue;
        if (strcmp(o, "MACRO")) return NULL;
        break; }
    if (i >= n) return NULL;
    return capture_macro(buf, n, &i, seqbuf);
}
static int known_op(const char *o) {
    if (op_find(o)) return 1;
    const char *d[] = { "CSECT", "ENTRY", "EXTRN", "WXTRN", "USING", "DROP", "DS", "DC", "EQU", "LTORG", "END",
                        "COPY", "MACRO", "MEND", "DSECT", "ORG", "TITLE", "PRINT", "SPACE", "EJECT", "CNOP", "PUSH", "POP", "CCW", NULL };
    int i; for (i = 0; d[i]; i++) if (!strcmp(o, d[i])) return 1; return 0;
}

static void mexp_line(const char *line, char **out, int *nout, int depth);
static int g_sysndx;
/* interpret a conditional-assembly definition statement (GBLx/LCLx/SETx/ANOP)
 * against context c. Returns 1 if it was such a statement. GBLx declarations mark
 * the symbol global (shared via the global store) without clobbering a value the
 * symbol already holds; LCLx (re)initialises a local. Used by both the macro
 * expander and open-code processing so &FUNC set in open code reaches the macros. */
static int set_stmt(struct ctx *c, const char *lbl, const char *op, const char *opnd) {
    if (!strncmp(op, "GBL", 3) || !strncmp(op, "LCL", 3)) {
        int isg = (op[0] == 'G'); char fl[24][64]; int nf = split_fields(opnd, fl, 24), j;
        for (j = 0; j < nf; j++) { char *lp = strchr(fl[j], '(');
            if (lp) { if (c->narr < 48) { int b2 = (int)(lp - fl[j]); if (b2 > 19) b2 = 19; memcpy(c->arrb[c->narr], fl[j], b2); c->arrb[c->narr][b2] = 0; c->arrnum[c->narr] = (op[3] != 'C'); c->narr++; }
                       if (isg) mark_global(fl[j]); }  /* array */
            else if (isg) { mark_global(fl[j]); if (!set_find(c, fl[j])) set_put(c, fl[j], op[3] == 'C' ? "" : "0"); }
            else set_put(c, fl[j], op[3] == 'C' ? "" : "0"); }
        return 1;
    }
    if (!strcmp(op, "SETA")) { long v = eval_seta(c, opnd); char nb[24]; sprintf(nb, "%ld", v); char sn[40]; set_canon(c, lbl, sn); set_put(c, sn, nb); return 1; }
    if (!strcmp(op, "SETB")) { int v = opnd[0] == '(' ? eval_cond(c, opnd + 1) : (int)eval_seta(c, opnd); char sn[40]; set_canon(c, lbl, sn); set_put(c, sn, v ? "1" : "0"); return 1; }
    if (!strcmp(op, "SETC")) { char v[128]; eval_setc(c, opnd, v); char sn[40]; set_canon(c, lbl, sn); set_put(c, sn, v); return 1; }
    if (!strcmp(op, "ANOP")) return 1;
    return 0;
}
/* Render a macro model statement for the listing's SOURCE column, the way IFOX
 * does it: each field (name / operation / operand / comment) is substituted in
 * place but keeps the *start column it had in the model card*, and cols 73-80
 * (the library sequence number) are carried through verbatim. So `&NAME B ...`
 * with &NAME empty still prints `B` in its model column, and an operand that
 * grows/shrinks under substitution leaves the comment anchored where the model
 * put it. The substituted operand may overflow its model width; a following
 * field is then pushed right by one blank rather than overwritten. */
static void render_model(struct ctx *c, const char *model, const char *seq, char *out) {
    char ln[256]; int i; for (i = 0; i < 255; i++) { ln[i] = ' '; } ln[255] = 0;
    int seqcol = 72;                                  /* a card is 80 cols; the sequence number sits at 73-80 (index 72-79) */
    int mlen = (int)strlen(model); while (mlen > 0 && (model[mlen-1]=='\n'||model[mlen-1]=='\r')) mlen--;
    /* split the model card (cols 1-72) into name / operation / operand / comment,
     * remembering each field's start column. The operand stops at the first blank
     * that is not inside quotes or parentheses (like parse()); the comment is
     * then everything up to col 72, internal blanks included. */
    int fcol[4]; char fld[4][128]; int p = 0, k;
    for (k = 0; k < 4; k++) { fcol[k] = 0; fld[k][0] = 0; }
    /* name (only if col 1 is non-blank); a sequence-symbol label (.NAME) is dropped */
    if (p < mlen && model[0] != ' ') {
        int q = 0; while (p < mlen && p < seqcol && model[p] != ' ') { if (q < 127) fld[0][q++] = model[p]; p++; }
        fld[0][q] = 0; if (fld[0][0] == '.') fld[0][0] = 0;   /* sequence symbol -> no generated name */
    }
    while (p < mlen && p < seqcol && model[p] == ' ') p++;
    /* operation */
    if (p < mlen && p < seqcol) { fcol[1] = p; int q = 0; while (p < mlen && p < seqcol && model[p] != ' ') { if (q < 127) fld[1][q++] = model[p]; p++; } fld[1][q] = 0; }
    while (p < mlen && p < seqcol && model[p] == ' ') p++;
    /* operand (quote/paren aware) */
    if (p < mlen && p < seqcol) { fcol[2] = p; int q = 0, inq = 0, dep = 0;
        while (p < mlen && p < seqcol) { char ch = model[p];
            if (ch == '\'') inq = !inq; else if (!inq && ch == '(') dep++; else if (!inq && ch == ')') { if (dep) dep--; }
            if (ch == ' ' && !inq && dep == 0) break;
            if (q < 127) { fld[2][q++] = ch; } p++; }
        fld[2][q] = 0; }
    while (p < mlen && p < seqcol && model[p] == ' ') p++;
    /* comment: the remainder up to col 72, verbatim (internal blanks kept) */
    if (p < mlen && p < seqcol) { fcol[3] = p; int q = 0; while (p < mlen && p < seqcol) { if (q < 127) fld[3][q++] = model[p]; p++; } fld[3][q] = 0; }
    /* place each field's substituted text at its model start column, shifting a
     * field right only when the previous one overran it */
    int cur = 0;
    for (i = 0; i < 4; i++) {
        if (!fld[i][0]) continue;
        char sub[256]; msub(c, fld[i], sub);
        int col = fcol[i]; if (col < cur) col = cur;   /* never overwrite the previous field */
        int sl = (int)strlen(sub), j; for (j = 0; j < sl && col + j < 255; j++) ln[col + j] = sub[j];
        cur = col + sl + 1;                            /* at least one blank before the next field */
    }
    /* carry the library sequence number (cols 73-80) through verbatim */
    if (seq) { int j; for (j = 0; j < 8 && seq[j]; j++) ln[seqcol + j] = seq[j]; }
    int n = 255; while (n > 0 && ln[n-1] == ' ') n--; ln[n] = 0;   /* trim trailing blanks */
    strcpy(out, ln);
}
/* expand a macro invocation, interpreting conditional assembly */
static void mexp_macro(struct macro *m, const char *lbl, const char *opnd, char **out, int *nout, int depth) {
    g_genlevel++;   /* lines emitted during this expansion are macro-generated */
    struct ctx c; memset(&c, 0, sizeof c); c.m = m; c.namepval = lbl; c.sysndx = ++g_sysndx;
    int k;
    for (k = 0; k < m->nparm; k++) { strncpy(c.pv[k], m->pkey[k] ? m->pdef[k] : "", 95); c.pv[k][95] = 0; }
    if (opnd[0]) { char args[100][64]; int na = split_fields(opnd, args, 100), pos = 0;
        for (k = 0; k < na; k++) {
            char *eq = strchr(args[k], '='); int iskw = eq && eq != args[k];
            if (iskw) { char *cc; for (cc = args[k]; cc < eq; cc++) if (!isalnum((unsigned char)*cc) && *cc!='@'&&*cc!='#'&&*cc!='$'&&*cc!='_') { iskw = 0; break; } }
            if (iskw) { *eq = 0; int j; char nm[66]; snprintf(nm, sizeof nm, "&%.63s", args[k]);
                for (j = 0; j < m->nparm; j++) if (!strcmp(nm, m->pname[j])) { strncpy(c.pv[j], eq + 1, 95); c.pv[j][95] = 0; break; } }
            else { int j, cc2 = 0; for (j = 0; j < m->nparm; j++) if (!m->pkey[j]) { if (cc2 == pos) { scopy(c.pv[j], args[k], 95); break; } cc2++; }
                if (pos < 32) { scopy(c.syslist[pos], args[k], 127); } pos++; c.nsyslist = pos; }
        }
    }
    /* prescan sequence-symbol labels */
    char seqn[2048][20]; int seqi[2048], nseq = 0;   /* stack-local (mexp_macro recurses for nested macros); big enough for DCBD/CVT/IKJTCB */
    for (k = 0; k < m->nbody; k++) if (m->body[k][0] == '.' && m->body[k][1] != '*') {
        char sl[20]; int j = 0; const char *q = m->body[k]; while (*q && !isspace((unsigned char)*q) && j < 19) sl[j++] = *q++; sl[j] = 0;
        if (nseq < 2048) { strcpy(seqn[nseq], sl); seqi[nseq] = k; nseq++; }
    }
    if (m->endlbl[0] && nseq < 2048) { strcpy(seqn[nseq], m->endlbl); seqi[nseq] = m->nbody; nseq++; }
    int pc = 0, guard = 0;
    while (pc < m->nbody && guard++ < 100000) {
        char bb[1024], bl[32], bo[16], bod[1024];
        if (m->body[pc][0] == '*' || (m->body[pc][0] == '.' && m->body[pc][1] == '*')) { pc++; continue; }  /* macro comment */
        strncpy(bb, m->body[pc], 1023); bb[1023] = 0; parse(bb, bl, bo, bod);
        if (!bo[0]) { pc++; continue; }
        if (!strcmp(bo, "MEND") || !strcmp(bo, "MEXIT")) break;
        if (!strcmp(bo, "PRINT") || !strcmp(bo, "SPACE") || !strcmp(bo, "EJECT") || !strcmp(bo, "MNOTE") || !strcmp(bo, "ACTR")) { pc++; continue; }
        if (set_stmt(&c, bl, bo, bod)) { pc++; continue; }   /* GBLx/LCLx/SETA/SETB/SETC/ANOP */
        if (!strcmp(bo, "AIF")) { char cond[512], seq[20]; aif_split(bod, cond, seq);
            if (eval_cond(&c, cond)) { int j, t = -1; for (j = 0; j < nseq; j++) if (!strcmp(seqn[j], seq)) { t = seqi[j]; break; } if (t >= 0) { pc = t; continue; } }
            pc++; continue; }
        if (!strcmp(bo, "AGO")) { int j, t = -1; for (j = 0; j < nseq; j++) if (!strcmp(seqn[j], bod)) { t = seqi[j]; break; } if (t >= 0) { pc = t; continue; } pc++; continue; }
        /* model statement (or nested macro call) */
        char ex[1024]; msub(&c, m->body[pc], ex);
        char gimg[256]; render_model(&c, m->body[pc], m->bodyseq[pc], gimg); g_genimg = gimg;   /* column-preserved image for the SOURCE column */
        mexp_line(ex, out, nout, depth + 1);
        pc++;
    }
    g_genlevel--;
}
/* persistent open-code conditional-assembly context (shared by the top-level
 * pass and every COPY'd block, so a GBLC/SETC in PDPTOP reaches an AIF in
 * CLIBSUPA); globals route to the shared store. */
static struct ctx g_opc;
static void mexp_block(char **arr, int n, char **out, int *nout, int depth, int *org);   /* fwd */
/* expand one statement: macro call -> interpret; else emit (stripping any
 * leading sequence-symbol label so it never reaches the core). */
/* Resolve the global system variables &SYSDATE/&SYSTIME in open code, before a
 * macro call binds them as parameter values (so the SAVE macro's K'&ID sees the
 * substituted length) or a bare DC emits them. Only these two context-free
 * globals are touched; all other & references pass through for the normal macro
 * machinery. Idempotent: an already-expanded line has no &SYS* left to match. */
static void sysvar_sub(const char *src, char *dst) {
    int di = 0; const char *s = src;
    while (*s && di < 1022) {
        if (*s == '&' && s[1] == '&') { dst[di++] = '&'; if (di < 1022) dst[di++] = '&'; s += 2; continue; }
        if (*s == '&') {
            const char *p = s + 1; char nm[12]; int i = 0;
            while (*p && isalpha((unsigned char)*p) && i < 10) nm[i++] = *p++;
            nm[i] = 0;
            if (!strcmp(nm, "SYSDATE") || !strcmp(nm, "SYSTIME")) {
                const char *v = nm[3] == 'D' ? g_sysdate : g_systime;
                while (*v && di < 1022) dst[di++] = *v++;
                s = p; if (*s == '.') s++;   /* swallow the concatenation dot */
                continue;
            }
            dst[di++] = '&'; s++; continue;
        }
        dst[di++] = *s++;
    }
    dst[di] = 0;
}
static void mexp_line(const char *line, char **out, int *nout, int depth) {
    struct ctx *opc = &g_opc;   /* shared open-code context */
    const char *img = g_genimg; g_genimg = NULL;   /* the SOURCE-column image for the one line this call emits (cleared so recursion does not inherit it) */
    char sysbuf[1024]; sysvar_sub(line, sysbuf);   /* resolve &SYSDATE/&SYSTIME up front */
    char buf[1024], lbl[32], op[16], opnd[1024];
    strncpy(buf, sysbuf, 1023); buf[1023] = 0; parse(buf, lbl, op, opnd);
    /* open-code (and COPY'd) conditional assembly: GBLx/LCLx/SETx/ANOP are
     * interpreted here (never reach the core, which would ignore them) so that
     * e.g. open-code `&FUNC SETC '...'` reaches a macro's `GBLC &FUNC`. */
    if (op[0] && (set_stmt(opc, lbl, op, opnd))) return;
    if (op[0] && !strcmp(op, "COPY") && opnd[0] && depth <= 40) {
        char *cb[2048]; int n = lib_readlines(opnd, cb, 2048, NULL);
        if (n >= 0) { mexp_block(cb, n, out, nout, depth + 1, NULL); return; }   /* COPY'd block keeps the COPY statement's origin (g_curorg) */
    }
    struct macro *m = NULL;
    if (op[0] && !known_op(op) && depth <= 40) { m = mac_find(op); if (!m) m = lib_load(op); }
    if (m) {   /* keep the macro call line itself for the listing (not assembled); its expansion is flagged generated */
        if (*nout < MAXLINES) { lflags[*nout] = (unsigned char)(g_genlevel > 0 ? LF_GEN | LF_NOASM : LF_NOASM); gcard[*nout] = img ? strdup(img) : NULL; line_org[*nout] = g_curorg; out[*nout] = strdup(sysbuf); (*nout)++; }
        /* HLASM substitutes the caller's variable symbols in a macro's arguments
         * in the caller's context. At open-code level resolve them from g_opc, so
         * e.g. `DCB MACRF=P&OUTM.M` binds &MACRF='PMM' (not the literal 'P&OUTM.M',
         * which the called macro -- not knowing &OUTM -- would mis-parse). Inside a
         * macro the enclosing expansion has already substituted them. */
        char aopnd[1024];
        if (g_genlevel == 0) msub(opc, opnd, aopnd); else { strncpy(aopnd, opnd, sizeof aopnd - 1); aopnd[sizeof aopnd - 1] = 0; }
        mexp_macro(m, lbl[0] == '.' ? "" : lbl, aopnd, out, nout, depth); return;
    }
    if (*nout >= MAXLINES) return;
    lflags[*nout] = (unsigned char)(g_genlevel > 0 ? LF_GEN : 0);
    gcard[*nout] = img ? strdup(img) : NULL;
    line_org[*nout] = g_curorg;
    if (lbl[0] == '.') { char r[1100]; snprintf(r, sizeof r, "         %s %s", op, opnd); out[(*nout)++] = strdup(r); }
    else out[(*nout)++] = strdup(sysbuf);
}
/* expand a line array as open code, honoring AIF/AGO/sequence-symbol branching.
 * Used for the whole module and for each COPY'd block; MACRO defs are captured,
 * everything else flows through mexp_line. The conditional context is the shared
 * g_opc (via mexp_line's set_stmt and the AIF eval below). */
static void mexp_block(char **arr, int n, char **out, int *nout, int depth, int *org) {
    char (*seqn)[20] = malloc((size_t)(n + 1) * 20); int *seqi = malloc((size_t)(n + 1) * sizeof(int));
    int nseq = 0, k, mdef = 0;
    if (!seqn || !seqi) { free(seqn); free(seqi); return; }
    for (k = 0; k < n; k++) {                          /* prescan sequence-symbol labels (skip MACRO..MEND bodies) */
        char sb[1024], sl[32], so[16], sd[1024]; strncpy(sb, arr[k], 1023); sb[1023] = 0; parse(sb, sl, so, sd);
        if (!strcmp(so, "MACRO")) { mdef++; continue; }
        if (!strcmp(so, "MEND")) { if (mdef) mdef--; continue; }
        if (mdef) continue;
        if (arr[k][0] == '.' && arr[k][1] != '*') {
            int j = 0; const char *q = arr[k]; while (*q && !isspace((unsigned char)*q) && j < 15) sl[j++] = *q++; sl[j] = 0;
            if (nseq <= n) { strcpy(seqn[nseq], sl); seqi[nseq] = k; nseq++; }
        }
    }
    int pc = 0, guard = 0;
    while (pc < n && guard++ < 4000000) {
        if (org) g_curorg = org[pc];   /* track the input-file line of the statement being expanded (inherited by macro/COPY output) */
        char buf[1024], lbl[32], op[16], opnd[1024]; strncpy(buf, arr[pc], 1023); buf[1023] = 0; parse(buf, lbl, op, opnd);
        if (!strcmp(op, "MACRO")) { capture_macro(arr, n, &pc, NULL); pc++; continue; }   /* COPY'd / inline macro definition */
        if (!strcmp(op, "AIF")) { char cond[512], seq[20]; aif_split(opnd, cond, seq);
            if (eval_cond(&g_opc, cond)) { int j, t = -1; for (j = 0; j < nseq; j++) if (!strcmp(seqn[j], seq)) { t = seqi[j]; break; } if (t >= 0) { pc = t; continue; } }
            pc++; continue; }
        if (!strcmp(op, "AGO")) { int j, t = -1; for (j = 0; j < nseq; j++) if (!strcmp(seqn[j], opnd)) { t = seqi[j]; break; } if (t >= 0) { pc = t; continue; } pc++; continue; }
        mexp_line(arr[pc], out, nout, depth);
        pc++;
    }
    free(seqn); free(seqi);
}
/* macro pass: capture MACRO/MEND defs, expand calls -> flat open code */
static int macro_pass(char **in, int nin, char **out, int *raw_org) {
    int nout = 0;
    mexp_block(in, nin, out, &nout, 0, raw_org);
    return nout;
}

static char unkops[128][12]; static int unkln[128]; static int nunk;   /* each undefined-op occurrence: the op and its lines[] index */
static void note_unknown(const char *o, int line) {
    static const char *skip[] = { "SETA","SETB","SETC","GBLA","GBLB","GBLC","LCLA","LCLB","LCLC",
        "AIF","AGO","ANOP","MNOTE","MEXIT","PRINT","SPACE","EJECT","TITLE","DSECT","ORG","CXD","COPY","MACRO","MEND","ACTR",
        "EXTRN","WXTRN", NULL };
    int i; for (i = 0; skip[i]; i++) if (!strcmp(o, skip[i])) return;
    if (nunk < 128) { scopy(unkops[nunk], o, 11); unkln[nunk] = line; nunk++; }   /* one record per flagged statement */
}
/* emit one literal's bytes at its assigned location (pass 2) */
/* IBM hex floating point: value = fraction * 16^(exp-64), 1/16 <= fraction < 1.
 * byte 0 = sign(1) | exponent(7, excess-64); remaining bytes = fraction. */
/* --- minimal big unsigned integer (base 2^32) for exact decimal->HFP --------
 * IFOX converts the decimal value exactly and rounds the HFP fraction to
 * nearest; matching it byte-for-byte needs integer/rational arithmetic, not the
 * host float type (which is platform-dependent: long double is 53-bit on arm64
 * macOS, 64-bit on x86 Linux). This keeps the conversion portable and exact. */
#define BN_LIMBS 64
struct bn { unsigned int v[BN_LIMBS]; int n; };
static void bn_set(struct bn *a, unsigned long long x) { a->n = 0; while (x) { a->v[a->n++] = (unsigned)(x & 0xffffffffu); x >>= 32; } }
static void bn_norm(struct bn *a) { while (a->n > 0 && a->v[a->n - 1] == 0) a->n--; }
static void bn_mul_small(struct bn *a, unsigned int m) {
    unsigned long long carry = 0; int i;
    for (i = 0; i < a->n; i++) { unsigned long long p = (unsigned long long)a->v[i] * m + carry; a->v[i] = (unsigned)(p & 0xffffffffu); carry = p >> 32; }
    while (carry && a->n < BN_LIMBS) { a->v[a->n++] = (unsigned)(carry & 0xffffffffu); carry >>= 32; }
}
static void bn_add_small(struct bn *a, unsigned int x) {
    unsigned long long carry = x; int i;
    for (i = 0; carry && i < BN_LIMBS; i++) { unsigned long long s = (unsigned long long)(i < a->n ? a->v[i] : 0) + carry; a->v[i] = (unsigned)(s & 0xffffffffu); carry = s >> 32; if (i >= a->n) a->n = i + 1; }
}
static int bn_cmp(const struct bn *a, const struct bn *b) {
    if (a->n != b->n) return a->n < b->n ? -1 : 1;
    int i; for (i = a->n - 1; i >= 0; i--) if (a->v[i] != b->v[i]) return a->v[i] < b->v[i] ? -1 : 1;
    return 0;
}
static void bn_sub(struct bn *a, const struct bn *b) {   /* a -= b, requires a >= b */
    long long borrow = 0; int i;
    for (i = 0; i < a->n; i++) { long long d = (long long)a->v[i] - (i < b->n ? b->v[i] : 0) - borrow; if (d < 0) { d += 0x100000000LL; borrow = 1; } else borrow = 0; a->v[i] = (unsigned)d; }
    bn_norm(a);
}
static void bn_shl(struct bn *a, int bits) {
    int limbs = bits / 32, rem = bits % 32, i;
    if (limbs) { for (i = a->n - 1; i >= 0; i--) if (i + limbs < BN_LIMBS) a->v[i + limbs] = a->v[i]; for (i = 0; i < limbs; i++) a->v[i] = 0; a->n += limbs; if (a->n > BN_LIMBS) a->n = BN_LIMBS; }
    if (rem) { unsigned long long carry = 0; for (i = 0; i < a->n; i++) { unsigned long long p = ((unsigned long long)a->v[i] << rem) | carry; a->v[i] = (unsigned)(p & 0xffffffffu); carry = p >> 32; } if (carry && a->n < BN_LIMBS) a->v[a->n++] = (unsigned)carry; }
    bn_norm(a);
}
/* floor(N/D) (assumed < 2^64 after normalisation) via binary long division; *Rr = remainder */
static unsigned long long bn_divmod(const struct bn *N, const struct bn *D, struct bn *Rr) {
    struct bn R; bn_set(&R, 0); unsigned long long Q = 0; int i;
    for (i = N->n * 32 - 1; i >= 0; i--) {
        bn_shl(&R, 1);
        if ((N->v[i / 32] >> (i % 32)) & 1) bn_add_small(&R, 1);
        Q <<= 1;
        if (bn_cmp(&R, D) >= 0) { bn_sub(&R, D); Q |= 1; }
    }
    *Rr = R; return Q;
}
static void emit_float(long at, const char *vstr, int bytes) {
    const char *p = vstr; int sign = 0;
    if (*p == '+') p++; else if (*p == '-') { sign = 1; p++; }
    struct bn M; bn_set(&M, 0); int nfrac = 0, seenpoint = 0;
    for (; *p && *p != '\'' && *p != ' '; p++) {
        if (*p == '.') { seenpoint = 1; continue; }
        if (*p == 'e' || *p == 'E') break;
        if (*p >= '0' && *p <= '9') { bn_mul_small(&M, 10); bn_add_small(&M, *p - '0'); if (seenpoint) nfrac++; }
    }
    int eexp = 0;
    if (*p == 'e' || *p == 'E') { p++; int es = 1; if (*p == '+') p++; else if (*p == '-') { es = -1; p++; } while (*p >= '0' && *p <= '9') { eexp = eexp * 10 + (*p++ - '0'); } eexp *= es; }
    if (M.n == 0) { int j; for (j = 0; j < bytes; j++) put(at + j, 0, 1); return; }   /* true zero */
    int fracbits = bytes * 8 - 8; if (fracbits > 56) fracbits = 56;
    int P = eexp - nfrac, k;                 /* value = M * 10^P */
    struct bn num = M, den; bn_set(&den, 1);
    if (P >= 0) for (k = 0; k < P; k++) bn_mul_small(&num, 10);
    else for (k = 0; k < -P; k++) bn_mul_small(&den, 10);
    int exp = 64;                            /* normalise num/den into [1/16, 1) */
    while (bn_cmp(&num, &den) >= 0) { bn_mul_small(&den, 16); exp++; }
    for (;;) { struct bn t = num; bn_mul_small(&t, 16); if (bn_cmp(&t, &den) < 0) { num = t; exp--; } else break; }
    struct bn N = num; bn_shl(&N, fracbits);  /* F = round(num * 2^fracbits / den) */
    struct bn R; unsigned long long F = bn_divmod(&N, &den, &R);
    bn_mul_small(&R, 2); if (bn_cmp(&R, &den) >= 0) F++;        /* round half up */
    if (F >> fracbits) { F >>= 4; exp++; }                     /* rounded up to 1.0 -> renormalise */
    put(at, (long)((sign ? 0x80 : 0) | (exp & 0x7f)), 1);
    int i; for (i = 1; i < bytes; i++) put(at + i, (long)((F >> (8 * (bytes - 1 - i))) & 0xff), 1);   /* ascending byte order: same values, but the TXT emission log stays address-monotonic */
}
static void emit_lit(struct lit *l) {
    const char *p = l->text + 1;
    while (isdigit((unsigned char)*p)) p++;
    char ty = toupper((unsigned char)*p++);
    if (*p == 'L') { p++; while (isdigit((unsigned char)*p)) p++; }
    if (ty == 'V' || ty == 'A' || ty == 'Y') {            /* address constant, possibly a value list =AL1(a,b,c) */
        char vv[64][64]; int nv = split_fields(l->ext, vv, 64); if (nv < 1) nv = 1;
        int per = l->size / nv, vj;
        for (vj = 0; vj < nv; vj++) { long loc = l->loc + (long)vj * per;
            if (ty == 'V') { char r[64]; int sn = 0; const char *se = vv[vj]; while (*se && !strchr("+-(), ", *se) && sn < 63) r[sn++] = *se++; r[sn] = 0;
                put(loc, 0, per); add_reloc(loc, r, 1); rels[nrel - 1].len = per; }
            else { int rc = 0; long v = vv[vj][0] ? expr_val(vv[vj], &rc) : 0; put(loc, v, per);
                char sym[64]; reloc_sym(vv[vj], sym, sizeof sym);   /* relocation target symbol (e.g. @V1-192, X'80000000'+SYM) */
                struct sym *es = (sym[0] && sym[0] != '*') ? sym_find(sym) : NULL;
                int tgtreal = (sym[0] == '*') ? !dsect_sect[cur_sect_id & 255] : (es && !dsect_sect[es->sect & 255]);
                if (rc != 0 && tgtreal) { add_reloc(loc, sym, 0); rels[nrel - 1].len = per; } } }   /* relocate only if net-relocatable; RLD length matches AL3/AL2 width */
    } else if (ty == 'E' || ty == 'D' || ty == 'L') {     /* floating point */
        const char *q = strchr(p, '\'');
        if (q && strpbrk(q + 1, ".eE")) emit_float(l->loc, q + 1, l->size);
        else put(l->loc, l->val, l->size);
    } else if (ty == 'F' || ty == 'H') {
        put(l->loc, l->val, l->size);
    } else if (ty == 'X') {
        const char *q = strchr(p, '\''); unsigned char by[256]; int nb = q ? hex_to_bytes(q + 1, by, 256) : 0;
        int pad = l->size - nb, j; for (j = 0; j < l->size; j++) put(l->loc + j, (j >= pad && j - pad < nb) ? by[j - pad] : 0, 1);
    } else if (ty == 'C') {
        const char *q = strchr(p, '\''); char body[256]; int slen = 0;
        if (q) { const char *e = q + 1; while (*e && slen < 255) { if (*e == '\'') { if (e[1] == '\'') { body[slen++] = '\''; e += 2; continue; } break; } body[slen++] = *e++; } }
        int j; for (j = 0; j < l->size; j++) put(l->loc + j, j < slen ? a2e((unsigned char)body[j]) : 0x40, 1);
    } else put(l->loc, l->val, l->size);
}
static int listing = 0;                 /* -L: print a LOC/object/source listing in pass 2 */
static void emit_listing(long a, long b, const char *src) {
    char hex[20]; int hn = 0; long i;
    for (i = a; i < b && i < a + 8; i++) hn += snprintf(hex + hn, sizeof hex - hn, "%02X", defn[i] ? text[i] : 0);
    hex[hn] = 0;
    char ln[90]; int j = 0; const char *p = src;
    while (*p && *p != '\n' && j < 88) ln[j++] = *p++;
    ln[j] = 0;
    fprintf(stderr, "%06lX %-16s %s\n", a, hex, ln);
}
static void do_pass(int pass, char **lines, int nlines) {
    int i; litpool = 0;
    long prev_lc = 0; const char *prev_src = NULL; int have_prev = 0;
    lc = 0; in_dsect = 0; nusing = 0; cur_sect_id = 0; org_hwm = 0;
    int pre_csect = 0;                  /* a content statement appeared before the first CSECT */
    int prev_li = -1;                   /* previous statement captured for the -a listing (byte count is deferred) */
    if (pass == 2) nrel = 0;
    txl_on = (pass == 2); if (pass == 2) { ntxl = 0; txl_blen = 0; txl_maxend = 0; txl_revisit = 0; }   /* (re)start the TXT emission log */
    for (i = 0; i < nlines; i++) {
        if (lflags[i] & LF_NOASM) continue;   /* a macro call line kept only for the listing -- never assembled */
        if (listing && pass == 2 && have_prev) emit_listing(prev_lc, lc, prev_src);
        if (pass == 2) { if (prev_li >= 0) lrecs[prev_li].len = (int)(lc - lrecs[prev_li].loc); lrecs[i].loc = lc; lrecs[i].len = 0; lrecs[i].hasa1 = lrecs[i].hasa2 = 0; prev_li = i; }
        char buf[1024], lbl[32], op[16], opnd[1024];
        strncpy(buf, lines[i], sizeof buf - 1); buf[sizeof buf - 1] = 0;
        if (listing && pass == 2) { prev_lc = lc; prev_src = lines[i]; have_prev = 1; }
        if (!parse(buf, lbl, op, opnd)) continue;
        if (!op[0]) continue;

        const struct opc *o = op_find(op);
        if (cur_sect_id == 0 && (o || !strcmp(op, "EQU") || !strcmp(op, "DS") || !strcmp(op, "DC") || !strcmp(op, "LTORG")))
            pre_csect = 1;   /* statement before the first CSECT opens the implicit unnamed PC */
        if (cur_sect_id == 0 && !in_dsect && (o || !strcmp(op, "EQU") || !strcmp(op, "DS") || !strcmp(op, "DC") || !strcmp(op, "LTORG"))) {
            struct sym *pc = sym_get(""); pc->type = S_PC; pc->defined = 1;   /* code (or a leading EQU) with no CSECT: open the implicit private-code section so its ESD precedes a later ENTRY's LD */
            if (!pc->sect) { pc->sect = ++g_sectid; } esd_add(pc, ESD_SECT);
            cur_sect_id = pc->sect; if (pass == 2) cur_sect_esdid = pc->esdid;
        }
        if (o) {
            while (lc & 1) { if (pass == 2) put(lc, 0, 1); lc++; }   /* instructions are halfword-aligned */
            char F[4][64]; int nf = split_fields(opnd, F, 4); (void)nf;
            if (pass == 1) {
                if (lbl[0]) { struct sym *s = sym_get(lbl); s->val = lc; s->defined = 1; s->sect = cur_sect_id; s->len = ins_len(o->fmt); }
                int k; for (k = 0; k < nf; k++) if (F[k][0] == '=') lit_get(F[k]);
                lc += ins_len(o->fmt);
            } else {
                long d, d2, sub[4], sub2[4]; int ns, ns2, sy, sy2;
                switch (o->fmt) {
                case F_RR:
                    put(lc, (o->op << 8) | ((int)eval_reg(F[0]) << 4) | (int)eval_reg(F[1]), 2); lc += 2; break;
                case F_BR:
                    put(lc, (o->op << 8) | (o->m1 << 4) | (int)eval_reg(F[0]), 2); lc += 2; break;
                case F_SVC:
                    put(lc, (o->op << 8) | ((int)expr_val(F[0], 0) & 0xff), 2); lc += 2; break;
                case F_RX: case F_BC: {
                    int r1 = (o->fmt == F_BC) ? o->m1 : (int)eval_reg(F[0]);
                    resolve((o->fmt == F_BC) ? F[0] : F[1], &d, sub, &ns, &sy);
                    int x = sy ? 0 : (int)sub[0], b = sy ? (int)sub[0] : (ns >= 2 ? (int)sub[1] : (r_ibase >= 0 ? r_ibase : 0));
                    put(lc, ((long)o->op << 24) | ((long)r1 << 20) | ((long)x << 16) | ((long)b << 12) | (d & 0xfff), 4); lc += 4;
                    lrecs[i].a1 = (d & 0xfffL) + using_base_of(b); lrecs[i].hasa1 = 1; break; }
                case F_RS: { int r1 = (int)eval_reg(F[0]), r3, b;
                    if (nf >= 3) { r3 = (int)eval_reg(F[1]); resolve(F[2], &d, sub, &ns, &sy); }
                    else { r3 = 0; resolve(F[1], &d, sub, &ns, &sy); }  /* shift form R1,D2(B2): R3 field unused */
                    b = (!sy && ns == 0 && r_ibase >= 0) ? r_ibase : (int)sub[0];
                    put(lc, ((long)o->op << 24) | ((long)r1 << 20) | ((long)r3 << 16) | ((long)b << 12) | (d & 0xfff), 4); lc += 4;
                    lrecs[i].a1 = (d & 0xfffL) + using_base_of(b); lrecs[i].hasa1 = 1; break; }
                case F_SI: { resolve(F[0], &d, sub, &ns, &sy); int b = (!sy && ns == 0 && r_ibase >= 0) ? r_ibase : (int)sub[0]; long im = imm_val(F[1]);
                    put(lc, ((long)o->op << 24) | ((long)(im & 0xff) << 16) | ((long)b << 12) | (d & 0xfff), 4); lc += 4;
                    lrecs[i].a1 = (d & 0xfffL) + using_base_of(b); lrecs[i].hasa1 = 1; break; }
                case F_S: { resolve(F[0], &d, sub, &ns, &sy); int b = (!sy && ns == 0 && r_ibase >= 0) ? r_ibase : (int)sub[0];   /* 2-byte opcode + S operand D2(B2) */
                    put(lc, o->op, 2); put(lc + 2, ((long)b << 12) | (d & 0xfff), 2); lc += 4;
                    lrecs[i].a1 = (d & 0xfffL) + using_base_of(b); lrecs[i].hasa1 = 1; break; }
                case F_SS: { resolve(F[0], &d, sub, &ns, &sy); int ib1 = r_ibase, l1 = r_len; resolve(F[1], &d2, sub2, &ns2, &sy2); int ib2 = r_ibase, l2 = r_len;
                    int twol = (o->op & 0xF0) == 0xF0 && o->op != 0xF0;   /* PACK/UNPK/MVO/AP/SP/MP/DP/ZAP/CP carry two 4-bit lengths */
                    int len1 = (ns  >= 1 ? (int)sub[0]  : (l1 ? l1 : 1));
                    int len2 = (ns2 >= 1 ? (int)sub2[0] : (l2 ? l2 : 1));
                    int b1 = (ns  >= 2 ? (int)sub[1]  : (ib1 >= 0 ? ib1 : (int)sub[0]));
                    int b2 = (ns2 >= 2 ? (int)sub2[1] : (ib2 >= 0 ? ib2 : (int)sub2[0]));
                    /* the machine length field is (length-1); an explicitly-coded length of 0
                     * (the `*-*` self-modify idiom) is emitted as field 0, not 0xFF */
                    int lenb = twol ? (((len1 ? (len1 - 1) & 0xf : 0) << 4) | (len2 ? (len2 - 1) & 0xf : 0))
                                    : (len1 ? (len1 - 1) & 0xff : 0);
                    put(lc, o->op, 1); put(lc + 1, lenb, 1);
                    put(lc + 2, ((long)b1 << 12) | (d & 0xfff), 2); put(lc + 4, ((long)b2 << 12) | (d2 & 0xfff), 2); lc += 6;
                    lrecs[i].a1 = (d & 0xfffL) + using_base_of(b1); lrecs[i].hasa1 = 1;
                    lrecs[i].a2 = (d2 & 0xfffL) + using_base_of(b2); lrecs[i].hasa2 = 1; break; }
                default: break;
                }
            }
            continue;
        }

        if (!strcmp(op, "CSECT")) {
            if (in_dsect) { in_dsect = 0; lc = main_lc; }   /* DSECT: resume the saved control-section counter */
            else { org_hwm = 0; }   /* a new/continued CSECT keeps the continuous location counter: distinct sections stack within one assembly, as IFOX does */
            if (pass == 1 && lbl[0] && pre_csect) {    /* statements preceded this named CSECT -> implicit unnamed PC is esdid1 */
                int k, hassect = 0; for (k = 0; k < nesdord; k++) if (esdord[k].role == ESD_SECT) hassect = 1;
                if (!hassect) { struct sym *pc = sym_get(""); pc->type = S_PC; pc->defined = 1; if (!pc->sect) pc->sect = ++g_sectid; esd_add(pc, ESD_SECT); }
            }
            struct sym *s = sym_get(lbl[0] ? lbl : "");
            if (!s->sect) s->sect = ++g_sectid;
            cur_sect_id = s->sect;
            if (pass == 1 && !s->defined) { s->type = lbl[0] ? S_SD : S_PC; s->val = lc; s->defined = 1; esd_add(s, ESD_SECT); }   /* first definition: origin = current (continuous) lc; a reopen keeps its origin */
            if (pass == 2) cur_sect_esdid = s->esdid;
        } else if (!strcmp(op, "DSECT")) {          /* dummy section: own counter from 0, no object text */
            if (!in_dsect) { main_lc = lc; main_sect_id = cur_sect_id; }
            lc = 0; in_dsect = 1; org_hwm = 0;
            struct sym *s = sym_get(lbl[0] ? lbl : "");
            if (!s->sect) s->sect = ++g_sectid;
            cur_sect_id = s->sect;
            if (cur_sect_id < 256) dsect_sect[cur_sect_id] = 1;   /* symbols here are absolute offsets */
            if (pass == 1) { s->val = 0; s->defined = 1; }
        } else if (!strcmp(op, "TITLE")) {
            if (pass == 1 && lbl[0] && !deck_id[0]) scopy(deck_id, lbl, 8);   /* first named TITLE -> deck id */
        } else if (!strcmp(op, "ENTRY")) {
            if (pass == 1 && opnd[0]) { struct sym *s = sym_get(opnd); s->is_entry = 1; esd_add(s, ESD_LD); }
        } else if (!strcmp(op, "EXTRN") || !strcmp(op, "WXTRN")) {
            int weak = (op[0] == 'W');
            if (pass == 1 && opnd[0]) { char f[8][64]; int nf = split_fields(opnd, f, 8), j;
                for (j = 0; j < nf; j++) { struct sym *s = sym_get(f[j]); if (!s->defined) s->type = S_ER; if (weak) s->is_weak = 1; esd_add(s, ESD_ER); } }
        } else if (!strcmp(op, "USING")) {
            char F[4][64]; split_fields(opnd, F, 4);
            if (pass == 2 && nusing < 32) {
                int reg = (int)expr_val(F[1], 0);
                long base = (F[0][0] == '*') ? lc : expr_val(F[0], 0);
                int bsect = cur_sect_id;
                if (F[0][0] != '*') { char nm[64]; int n = 0; const char *e = F[0]; while (*e && !strchr("+-*/(), ", *e) && n < 63) nm[n++] = *e++; nm[n] = 0; struct sym *bs = sym_find(nm); if (bs) bsect = bs->sect; }
                usings[nusing].reg = reg; usings[nusing].base = base; usings[nusing].sect = bsect; nusing++;
                lrecs[i].a2 = base; lrecs[i].hasa2 = 1;   /* IFOX shows the USING's first-operand value in the ADDR2 column */
            }
        } else if (!strcmp(op, "DROP")) {
            if (pass == 2) { char F[4][64]; int nf = split_fields(opnd, F, 4), j, k;
                if (!nf) nusing = 0;                       /* DROP with no operand drops all */
                else for (j = 0; j < nf; j++) { int r = (int)expr_val(F[j], 0);
                    for (k = 0; k < nusing; ) { if (usings[k].reg == r) { usings[k] = usings[--nusing]; } else k++; } } }
        } else if (!strcmp(op, "PUSH") || !strcmp(op, "POP")) {   /* PUSH/POP USING: save/restore the active USING table (PRINT etc. ignored) */
            if (pass == 2 && strstr(opnd, "USING")) {
                static struct uent ustk[16][32]; static int ustkn[16], usp;
                if (op[1] == 'U') { if (usp < 16) { memcpy(ustk[usp], usings, sizeof usings); ustkn[usp] = nusing; usp++; } }   /* PUSH */
                else if (usp > 0) { usp--; memcpy(usings, ustk[usp], sizeof usings); nusing = ustkn[usp]; }                      /* POP */
            }
        } else if (!strcmp(op, "CNOP")) {                      /* align with NOPR (0x0700) fill */
            char F[2][64]; split_fields(opnd, F, 2);
            int b = (int)expr_val(F[0], 0), nn = (int)expr_val(F[1], 0), g = 0;
            if (nn > 0) while ((lc % nn) != b && g++ < 64) { if (pass == 2) put(lc, 0x0700, 2); lc += 2; }
        } else if (!strcmp(op, "ORG")) {                       /* set the location counter (ORG expr) or reset to the high-water mark (bare ORG) */
            if (lc > org_hwm) org_hwm = lc;
            lc = (!opnd[0] || opnd[0] == ',') ? org_hwm : expr_val(opnd, NULL);   /* bare ORG or `ORG ,` resets to the high-water mark */
            if (!in_dsect && org_hwm > modlen) modlen = org_hwm;
        } else if (!strcmp(op, "CCW")) {                       /* channel command word: cmd, AL3 address, flags, AL2 count (doubleword aligned) */
            { long old = lc; while (lc & 7) lc++; if (pass == 2) while (old < lc) put(old++, 0, 1); }
            if (pass == 1 && lbl[0]) { struct sym *s = sym_get(lbl); s->val = lc; s->defined = 1; s->sect = cur_sect_id; s->len = 8; }
            if (pass == 2) { char F[4][64]; int nf = split_fields(opnd, F, 4);
                put(lc, expr_val(F[0], 0) & 0xff, 1);
                int rc = 0; long av = nf >= 2 ? expr_val(F[1], &rc) : 0; put(lc + 1, av, 3);
                if (rc != 0) { char rsym[64]; reloc_sym(F[1], rsym, sizeof rsym);
                    struct sym *es = sym_find(rsym); if (es && !dsect_sect[es->sect & 255]) { add_reloc(lc + 1, rsym, 0); rels[nrel - 1].len = 3; } }
                put(lc + 4, nf >= 3 ? expr_val(F[2], 0) & 0xff : 0, 1); put(lc + 5, 0, 1);
                put(lc + 6, nf >= 4 ? expr_val(F[3], 0) & 0xffff : 0, 2); }
            lc += 8;
        } else if (!strcmp(op, "DS") || !strcmp(op, "DC")) {
            static char ops[256][1024]; int nops = dc_split(opnd, ops, 256), oi;
            int emit_dc = (pass == 2 && !strcmp(op, "DC"));
            for (oi = 0; oi < nops; oi++) {
                const char *p = ops[oi]; int cnt = 0, hascnt = 0, k;
                while (isdigit((unsigned char)*p)) { cnt = cnt * 10 + (*p - '0'); hascnt = 1; p++; }
                if (!hascnt) cnt = 1;
                int ty = *p ? toupper((unsigned char)*p++) : 0;
                int blen = 0, haslen = 0;            /* explicit length modifier Ln or L(expr) */
                if (*p == 'L') { p++; haslen = 1;
                    if (*p == '(') { const char *rp = strchr(p, ')'); char ex[64]; int en = rp ? (int)(rp - p - 1) : 0; if (en > 63) en = 63; memcpy(ex, p + 1, en); ex[en] = 0; blen = (int)expr_val(ex, NULL); p = rp ? rp + 1 : p + strlen(p); }
                    else while (isdigit((unsigned char)*p)) blen = blen * 10 + (*p++ - '0'); }
                int setlbl = (pass == 1 && oi == 0 && lbl[0]);   /* the symbol addresses the first operand */
                if (ty == 'F' || ty == 'A' || ty == 'H' || ty == 'D' || ty == 'Y' || ty == 'V') {
                    int base = (ty == 'D') ? 8 : (ty == 'H' || ty == 'Y') ? 2 : 4;
                    if (!haslen) { blen = base; long oldlc = lc; lc = (base == 8) ? align8(lc) : (base == 2) ? ((lc + 1) & ~1L) : align4(lc);
                        if (emit_dc) while (oldlc < lc) put(oldlc++, 0, 1); }   /* DC alignment padding is emitted as zero TXT (IFOX-compatible) */
                    if (setlbl) { struct sym *s = sym_get(lbl); s->val = lc; s->defined = 1; s->sect = cur_sect_id; s->len = blen ? blen : 1; }
                    long val = 0; int isvcon = (ty == 'V'), isaddr = (ty == 'A' || ty == 'Y' || isvcon);
                    if (isaddr) {                                  /* address constant, possibly a value list A(v1,v2,..) */
                        const char *lp = strchr(p, '('), *rp = strrchr(p, ')');
                        char inside[256] = "";
                        if (lp && rp && rp > lp) { size_t n = (size_t)(rp - lp - 1); if (n > 255) n = 255; memcpy(inside, lp + 1, n); inside[n] = 0; }
                        char vals[32][80]; int nv = 0;             /* split the operand list on top-level commas */
                        { const char *s = inside, *st = inside; int q = 0, d = 0;
                          for (;; s++) {
                              if (*s == '\'') { if (q || !(s > inside && strchr("KNLT", s[-1]))) q = !q; }  /* K'/N'/L'/T' apostrophe (e.g. AL2(L'SYM,0)) is an attribute, not a string quote */
                              else if (!q && *s == '(') d++;
                              else if (!q && *s == ')') { if (d) d--; }
                              if ((!q && d == 0 && *s == ',') || !*s) {
                                  if (nv < 32) { int L = (int)(s - st); if (L > 79) L = 79; memcpy(vals[nv], st, L); vals[nv][L] = 0; nv++; }
                                  if (!*s) { break; } st = s + 1; } } }
                        if (nv == 0) { vals[0][0] = 0; nv = 1; }   /* A() -> a single zero constant */
                        if (isvcon && pass == 1 && !in_dsect) { int vj; for (vj = 0; vj < nv; vj++) {   /* register each V-con ER */
                            char r[64]; int sn = 0; const char *se = vals[vj]; while (*se && !strchr("+-(), ", *se) && sn < 63) r[sn++] = *se++; r[sn] = 0;
                            if (r[0]) { struct sym *s = sym_get(r); if (!s->defined) s->type = S_ER; esd_add(s, ESD_ER); } } }
                        for (k = 0; k < cnt; k++) { int vj; for (vj = 0; vj < nv; vj++) {
                            if (emit_dc) {
                                if (isvcon) { char r[64]; int sn = 0; const char *se = vals[vj]; while (*se && !strchr("+-(), ", *se) && sn < 63) r[sn++] = *se++; r[sn] = 0;
                                    put(lc, 0, blen); add_reloc(lc, r, 1); rels[nrel - 1].len = blen; }
                                else { char rsym[64]; reloc_sym(vals[vj], rsym, sizeof rsym); int rc = 0; long v = vals[vj][0] ? expr_val(vals[vj], &rc) : 0;
                                    struct sym *es = (rsym[0] && rsym[0] != '*') ? sym_find(rsym) : NULL;
                                    int tgtreal = (rsym[0] == '*') ? !dsect_sect[cur_sect_id & 255] : (es && !dsect_sect[es->sect & 255]);
                                    put(lc, v, blen); if ((rc != 0) && tgtreal) { add_reloc(lc, rsym, 0); rels[nrel - 1].len = blen; } }   /* AL3 address -> 3-byte relocation, etc. */
                            }
                            lc += blen;
                        } }
                    } else {
                        const char *q = strchr(p, '\''); if (q) val = strtol(q + 1, NULL, 10);
                        for (k = 0; k < cnt; k++) { if (emit_dc) put(lc, val, blen); lc += blen; }
                    }
                } else if (ty == 'C') {                     /* EBCDIC characters; '' -> one quote */
                    if (setlbl) { struct sym *s = sym_get(lbl); s->val = lc; s->defined = 1; s->sect = cur_sect_id; s->len = blen ? blen : 1; }
                    const char *q = strchr(p, '\''); char body[1024]; int slen = 0;
                    if (q) { const char *e = q + 1;
                        while (*e && slen < 1023) {
                            if (*e == '\'') { if (e[1] == '\'') { body[slen++] = '\''; e += 2; continue; } break; }
                            body[slen++] = *e++;
                        } }
                    int emit = haslen ? blen : (q ? slen : 1);   /* valueless DS nC reserves cnt*1 bytes (default C length 1) */
                    for (k = 0; k < cnt; k++) { int j; for (j = 0; j < emit; j++) { if (emit_dc) put(lc, j < slen ? a2e((unsigned char)body[j]) : 0x40, 1); lc++; } }
                } else if (ty == 'X') {                     /* hex bytes, byte-aligned */
                    if (setlbl) { struct sym *s = sym_get(lbl); s->val = lc; s->defined = 1; s->sect = cur_sect_id; s->len = blen ? blen : 1; }
                    const char *q = strchr(p, '\''); unsigned char by[1024]; int nb = 0;
                    if (q) { char h[2056]; int hl = 0, s0 = 0; const char *e = q + 1;
                        while (*e && *e != '\'' && hl < 2055) { if (isxdigit((unsigned char)*e)) h[hl++] = *e; e++; }
                        if (hl & 1) { by[nb++] = (unsigned char)hexv(h[0]); s0 = 1; }
                        for (; s0 + 1 < hl && nb < 1024; s0 += 2) by[nb++] = (unsigned char)((hexv(h[s0]) << 4) | hexv(h[s0 + 1]));
                    }
                    int emit = haslen ? blen : (q ? nb : 1), pad = emit - nb;   /* valueless DS nX reserves cnt*1 */
                    for (k = 0; k < cnt; k++) { int j; for (j = 0; j < emit; j++) { if (emit_dc) put(lc, (j >= pad && j - pad < nb) ? by[j - pad] : 0, 1); lc++; } }
                } else if (ty == 'B') {                     /* binary, byte-aligned, MSB-first */
                    if (setlbl) { struct sym *s = sym_get(lbl); s->val = lc; s->defined = 1; s->sect = cur_sect_id; s->len = blen ? blen : 1; }
                    const char *q = strchr(p, '\''); unsigned char by[256]; int nb = 0;
                    if (q) { char bits[2056]; int bl2 = 0; const char *e = q + 1;
                        while (*e && *e != '\'' && bl2 < 2048) { if (*e == '0' || *e == '1') bits[bl2++] = *e; e++; }
                        int pos = 0, rem = bl2 % 8, first = rem ? rem : (bl2 ? 8 : 0);
                        while (pos < bl2 && nb < 256) { int take = (nb == 0) ? first : 8, v = 0, j; for (j = 0; j < take; j++) v = (v << 1) | (bits[pos++] - '0'); by[nb++] = (unsigned char)v; }
                    }
                    int emit = haslen ? blen : (q ? nb : 1), pad = emit - nb;   /* valueless DS nB reserves cnt*1 */
                    for (k = 0; k < cnt; k++) { int j; for (j = 0; j < emit; j++) { if (emit_dc) put(lc, (j >= pad && j - pad < nb) ? by[j - pad] : 0, 1); lc++; } }
                } else if (setlbl) { struct sym *s = sym_get(lbl); s->val = lc; s->defined = 1; s->sect = cur_sect_id; s->len = blen ? blen : 1; }
            }
            if (!in_dsect && lc > modlen) modlen = lc;   /* a DS reserves space that extends the section length even though it writes no TXT */
        } else if (!strcmp(op, "EQU")) {
            if (pass == 1 && lbl[0]) { struct sym *s = sym_get(lbl); int rc = 0;
                char F[4][64]; int nf = split_fields(opnd, F, 4);
                s->val = expr_val(F[0], &rc); s->defined = 1; s->sect = cur_sect_id;
                s->len = (nf >= 2 && F[1][0]) ? (int)expr_val(F[1], NULL) : 1;   /* EQU value,length: 2nd operand sets the length attribute (L') */
                s->type = (rc == 0) ? S_ABS : S_REL; }   /* an absolute expression (e.g. SYM-SYM, length, *-DSECT) yields a non-relocatable equate */
        } else if (!strcmp(op, "LTORG") || !strcmp(op, "END")) {
            int k;
            if (!strcmp(op, "END") && opnd[0]) {
                end_has = 1;
                if (pass == 2) { struct sym *s = sym_find(opnd); if (s) { end_addr = s->val; end_esdid = s->esdid ? s->esdid : main_sect_esdid; } }
            }
            if (!strcmp(op, "END") && in_dsect) {   /* a trailing DSECT must not capture the pending literal pool: flush it into the control section */
                in_dsect = 0; lc = main_lc; cur_sect_id = main_sect_id; cur_sect_esdid = main_sect_esdid;
            }
            /* gather this pool's literals (ltseq is assigned at creation = the pool
             * that was open when the literal was first referenced) */
            static int mem[4096]; int nmem = 0;
            for (k = 0; k < nlit; k++) {
                if (lits[k].placed) continue;
                if (lits[k].ltseq != litpool) continue;
                if (nmem < 4096) mem[nmem++] = k;
            }
            /* Register each =V literal's external reference in the ESD now, when the
             * pool is FLUSHED (not at first use), in first-reference order -- this is
             * IFOX's ESD timing, so an ENTRY (LD) declared between the reference and
             * the flush sorts ahead of these ERs (e.g. @@crtm's @@EXITA). */
            if (pass == 1) { int mi; for (mi = 0; mi < nmem; mi++) { struct lit *l = &lits[mem[mi]];
                if (l->isV) { struct sym *s = sym_get(l->ext); if (!s->defined) s->type = S_ER; esd_add(s, ESD_ER); } } }
            /* IFOX groups a pool into doubleword/fullword/halfword/byte segments to
             * minimise padding, each segment in order of first reference. A literal's
             * segment is the alignment implied by its LENGTH (len div by 8/4/2 else
             * byte), not its type: so =CL8 sits with the doublewords but =CL11 (odd)
             * goes in the byte segment, after the fullwords. Sort by that key,
             * descending, stable (preserving appearance order within a segment). */
            { int a, b;
              for (a = 1; a < nmem; a++) { int t = mem[a]; b = a - 1;
                while (b >= 0 && lenalgn(lits[mem[b]].size) < lenalgn(lits[t].size)) { mem[b + 1] = mem[b]; b--; }
                mem[b + 1] = t; } }
            if (!strcmp(op, "LTORG") || nmem > 0) lc = align8(lc);  /* pool starts on a doubleword */
            { int mi; for (mi = 0; mi < nmem; mi++) {
                struct lit *l = &lits[mem[mi]];
                lc = (lc + l->algn - 1) & ~(long)(l->algn - 1);
                if (pass == 1) l->loc = lc;   /* =V external refs are registered at first use in lit_get */
                else emit_lit(l);
                l->placed = 1;
                lc += l->size;
            } }
            if (!in_dsect && lc > modlen) modlen = lc;   /* the pool's doubleword alignment extends the section length (no TXT for the pad) */
            litpool++;
        } else if (pass == 1) note_unknown(op, i);
    }
    if (listing && pass == 2 && have_prev) emit_listing(prev_lc, lc, prev_src);
    if (pass == 2 && prev_li >= 0) lrecs[prev_li].len = (int)(lc - lrecs[prev_li].loc);   /* close the byte count of the last assembled statement (no later statement triggers the flush) */
}

/* ---- OS/360 OBJ writer ---------------------------------------------------- */
/* ASCII -> EBCDIC, CP037 + ecosystem NEL (\n -> 0x15). Verbatim from the
 * c2asm370 compiler's i370_ascii_to_ebcdic, so DC C output is byte-identical to
 * the mvsMF upload (which uses the same table) and hence to what IFOX assembled. */
static const unsigned char a2e_tab[256] = {
  0x00,0x01,0x02,0x03,0x37,0x2D,0x2E,0x2F, 0x16,0x05,0x15,0x0B,0x0C,0x0D,0x0E,0x0F,
  0x10,0x11,0x12,0x13,0x3C,0x3D,0x32,0x26, 0x18,0x19,0x3F,0x27,0x1C,0x1D,0x1E,0x1F,
  0x40,0x5A,0x7F,0x7B,0x5B,0x6C,0x50,0x7D, 0x4D,0x5D,0x5C,0x4E,0x6B,0x60,0x4B,0x61,
  0xF0,0xF1,0xF2,0xF3,0xF4,0xF5,0xF6,0xF7, 0xF8,0xF9,0x7A,0x5E,0x4C,0x7E,0x6E,0x6F,
  0x7C,0xC1,0xC2,0xC3,0xC4,0xC5,0xC6,0xC7, 0xC8,0xC9,0xD1,0xD2,0xD3,0xD4,0xD5,0xD6,
  0xD7,0xD8,0xD9,0xE2,0xE3,0xE4,0xE5,0xE6, 0xE7,0xE8,0xE9,0xBA,0xE0,0xBB,0xB0,0x6D,
  0x79,0x81,0x82,0x83,0x84,0x85,0x86,0x87, 0x88,0x89,0x91,0x92,0x93,0x94,0x95,0x96,
  0x97,0x98,0x99,0xA2,0xA3,0xA4,0xA5,0xA6, 0xA7,0xA8,0xA9,0xC0,0x4F,0xD0,0xA1,0x07,
  0x20,0x21,0x22,0x23,0x24,0x15,0x06,0x17, 0x28,0x29,0x2A,0x2B,0x2C,0x09,0x0A,0x1B,
  0x30,0x31,0x1A,0x33,0x34,0x35,0x36,0x08, 0x38,0x39,0x3A,0x3B,0x04,0x14,0x3E,0xFF,
  0x41,0xAA,0x4A,0xB1,0x9F,0xB2,0x6A,0xB5, 0xBD,0xB4,0x9A,0x8A,0x5F,0xCA,0xAF,0xBC,
  0x90,0x8F,0xEA,0xFA,0xBE,0xA0,0xB6,0xB3, 0x9D,0xDA,0x9B,0x8B,0xB7,0xB8,0xB9,0xAB,
  0x64,0x65,0x62,0x66,0x63,0x67,0x9E,0x68, 0x74,0x71,0x72,0x73,0x78,0x75,0x76,0x77,
  0xAC,0x69,0xED,0xEE,0xEB,0xEF,0xEC,0xBF, 0x80,0xFD,0xFE,0xFB,0xFC,0xAD,0xAE,0x59,
  0x44,0x45,0x42,0x46,0x43,0x47,0x9C,0x48, 0x54,0x51,0x52,0x53,0x58,0x55,0x56,0x57,
  0x8C,0x49,0xCD,0xCE,0xCB,0xCF,0xCC,0xE1, 0x70,0xDD,0xDE,0xDB,0xDC,0x8D,0x8E,0xDF,
};
static unsigned char a2e(int c) { return a2e_tab[c & 0xff]; }
static void cinit(unsigned char *c) { int i; for (i = 0; i < 80; i++) c[i] = 0x40; }
static void cname(unsigned char *c, const char *n) { c[0] = 0x02; c[1] = a2e(n[0]); c[2] = a2e(n[1]); c[3] = a2e(n[2]); }
static void cbe(unsigned char *c, int off, long v, int n) { int i; for (i = n - 1; i >= 0; i--) { c[off + i] = (unsigned char)(v & 0xff); v >>= 8; } }
static void cebc(unsigned char *c, int off, const char *s, int w) {
    int i, done = 0; for (i = 0; i < w; i++) { if (!done && (!s || !s[i])) done = 1; c[off + i] = done ? 0x40 : a2e((unsigned char)s[i]); }
}
static void cseq(unsigned char *c, int seq) {
    char b[16]; int i;
    if (deck_id[0]) {                              /* deck id left-justified, sequence right-justified in the leftover cols */
        int nl = (int)strlen(deck_id); if (nl > 8) nl = 8;
        int nd = 8 - nl;                           /* digits available for the sequence */
        for (i = 0; i < nl; i++) c[72 + i] = a2e((unsigned char)deck_id[i]);
        if (nd > 0) { char fmt[8], d[16]; long m = 1; int k; for (k = 0; k < nd; k++) m *= 10;
            sprintf(fmt, "%%0%dld", nd); sprintf(d, fmt, (long)(seq % m));
            for (i = 0; i < nd; i++) c[72 + nl + i] = a2e(d[i]); }
        return;
    }
    sprintf(b, "%08d", seq); for (i = 0; i < 8; i++) c[72 + i] = a2e(b[i]);
}
static void esd_ent(unsigned char *c, int slot, const char *name, int type, long addr, long sizeOrId, int blankSize) {
    cebc(c, slot, name, 8); c[slot + 8] = (unsigned char)type; cbe(c, slot + 9, addr, 3); c[slot + 12] = 0x40;
    if (blankSize) { c[slot + 13] = c[slot + 14] = c[slot + 15] = 0x40; } else cbe(c, slot + 13, sizeOrId, 3);
}

/* length of the control section at esdord index e: the distance to the NEXT
 * section declared in this assembly (declaration order is non-decreasing in
 * origin, since the location counter is continuous across CSECTs), or to the
 * module end for the last section. An empty section that shares an origin with
 * the next (e.g. an implicit private-code section ahead of a named CSECT) thus
 * gets length 0. */
static long sect_length(int e) {
    long org = esdord[e].s->val; int k;
    for (k = e + 1; k < nesdord; k++)
        if (esdord[k].role == ESD_SECT) return esdord[k].s->val - org;
    return modlen - org;
}

static void emit_obj(FILE *f) {
    unsigned char c[80]; int seq = 0, k;

    /* ESD: declaration order, 3 entries per card */
    { int e = 0; while (e < nesdord) {
        cinit(c); cname(c, "ESD");
        int n = 0, cardfirst = 0;
        while (n < 3 && e < nesdord) {
            int ei = e; struct sym *s = esdord[e].s; int role = esdord[e].role, slot = 16 + n * 16; e++;
            if (role == ESD_SECT) { esd_ent(c, slot, s->name, s->type == S_PC ? 0x04 : 0x00, s->val, sect_length(ei), 0); if (!cardfirst) cardfirst = s->esdid; }
            else if (role == ESD_ER) { esd_ent(c, slot, s->name, s->is_weak ? 0x0a : 0x02, 0, 0, 1); if (!cardfirst) cardfirst = s->esdid; }
            else { esd_ent(c, slot, s->name, 0x01, s->val, main_sect_esdid, 0); }   /* LD entry */
            n++;
        }
        cbe(c, 10, n * 16, 2);
        if (cardfirst) cbe(c, 14, cardfirst, 2);   /* LD-only card: ESDID field stays blank */
        cseq(c, ++seq); fwrite(c, 1, 80, f);
    } }

    /* TXT cards: replay the pass-2 emission log the way IFOX's PUNRTN does --
     * accumulate bytes into a 56-byte card and start a new card whenever the next
     * byte's address is not the running card address (a gap or an ORG overlay) or
     * the card fills. A backward ORG therefore re-punches its overlaid bytes as a
     * fresh (overlapping) card with the pre-overwrite content, exactly like IFOX. */
    { int e, cesdid = 0; long cstart = 0, running = -1; int cn = 0, open = 0; unsigned char cbuf[56];
      for (e = 0; e <= ntxl; e++) {
        long ea; int el, eid; const unsigned char *eb;
        if (e < ntxl) { ea = txl_addr[e]; el = txl_len[e]; eb = txl_bytes + txl_boff[e]; eid = txl_esdid[e]; }
        else { ea = -1; el = 0; eb = NULL; eid = -1; }   /* sentinel: flush the open card */
        int pos = 0;
        do {
            if (open && (e == ntxl || ea + pos != running || cn == 56 || eid != cesdid)) {   /* flush: gap, full card, or a section change */
                cinit(c); cname(c, "TXT"); cbe(c, 5, cstart, 3); cbe(c, 10, cn, 2); cbe(c, 14, cesdid, 2);
                { int i; for (i = 0; i < cn; i++) c[16 + i] = cbuf[i]; }
                cseq(c, ++seq); fwrite(c, 1, 80, f); open = 0;
            }
            if (e == ntxl) break;
            if (!open) { cstart = ea + pos; running = cstart; cn = 0; open = 1; cesdid = eid; }
            int take = 56 - cn; if (take > el - pos) take = el - pos;
            memcpy(cbuf + cn, eb + pos, (size_t)take); cn += take; pos += take; running += take;
        } while (pos < el);
      } }

    /* group relocations by (pos, rel) so same-target entries are adjacent (packing), like IFOX */
    { int a, b; for (a = 1; a < nrel; a++) { struct reloc t = rels[a]; b = a - 1;
        while (b >= 0 && (rels[b].pos > t.pos || (rels[b].pos == t.pos && rels[b].rel > t.rel))) { rels[b + 1] = rels[b]; b--; }
        rels[b + 1] = t; } }
    { k = 0; while (k < nrel) {
        cinit(c); cname(c, "RLD"); int off = 16, prevflag = -1; long pr = -1, pp = -1;
        while (k < nrel) {
            /* An item reuses the previous R/P pointers (4-byte continuation) only
             * when it sits on the same card as an identical-(rel,pos) predecessor.
             * The first item on a card is always a full 8-byte leader, so a group
             * spanning a card boundary re-emits R/P automatically. */
            int reuse = (off > 16 && rels[k].rel == pr && rels[k].pos == pp);
            int need = reuse ? 4 : 8;
            if (off + need > 72) break;                        /* card full -> flush */
            if (reuse) {
                c[prevflag] |= 0x01;                           /* predecessor: next omits R/P */
                c[off] = (rels[k].isV ? 0x10 : 0) | (((rels[k].len - 1) & 3) << 2); cbe(c, off + 1, rels[k].addr, 3);
                prevflag = off; off += 4;
            } else {
                cbe(c, off, rels[k].rel, 2); cbe(c, off + 2, rels[k].pos, 2);
                c[off + 4] = (rels[k].isV ? 0x10 : 0) | (((rels[k].len - 1) & 3) << 2); cbe(c, off + 5, rels[k].addr, 3);
                prevflag = off + 4; off += 8; pr = rels[k].rel; pp = rels[k].pos;
            }
            k++;
        }
        cbe(c, 10, off - 16, 2); cseq(c, ++seq); fwrite(c, 1, 80, f);
    } }

    cinit(c); cname(c, "END"); if (end_has) { cbe(c, 5, end_addr, 3); cbe(c, 14, end_esdid, 2); }
    { char jul[8], idr[24]; julian5(g_sysdate, jul);   /* IDR (cols 33-52): product(10) + space + version(4) + Julian date(5) */
      snprintf(idr, sizeof idr, "%-10.10s %-4.4s%5.5s", AS370_IDR_PROD, AS370_IDR_VER, jul);
      cebc(c, 32, idr, 20); }
    cseq(c, ++seq); fwrite(c, 1, 80, f);
}

/* ---- -a assembler listing (ASCII, columns matching IFOX00 SYSPRINT) -------
 * Each section is a 120-column page: a centred title line with PAGE n at col
 * 112, then a column-header line with the translator-id/time/date block right-
 * justified at col 120. Page eject = ASCII form-feed. Source listing is TODO. */
static FILE *alst; static const char *alst_fn;
static int a_on, a_esd, a_rld, a_xref, a_src, a_page;
static void a_line(const char *s) {                 /* write a print line, trailing blanks trimmed */
    int n = (int)strlen(s); while (n > 0 && s[n - 1] == ' ') n--;
    fwrite(s, 1, (size_t)n, alst); fputc('\n', alst);
}
static void a_newpage(const char *title, const char *colhdr) {
    char ln[128]; int t = (int)strlen(title);
    if (a_page++) fputc('\f', alst);                /* page eject before every page but the first */
    memset(ln, ' ', 120); ln[120] = 0;
    { int lead = (121 - t) / 2; if (lead < 0) lead = 0; memcpy(ln + lead, title, (size_t)t); }
    { char pg[16]; snprintf(pg, sizeof pg, "PAGE%5d", a_page); memcpy(ln + 111, pg, strlen(pg)); }   /* PAGE at col 112 */
    a_line(ln);
    memset(ln, ' ', 120); ln[120] = 0;
    memcpy(ln, colhdr, strlen(colhdr));
    { char id[48]; int bl; snprintf(id, sizeof id, "%s %s %s %s", AS370_IDR_PROD, AS370_IDR_VER, g_systime, g_sysdate);
      bl = (int)strlen(id); if (bl > 120) bl = 120; memcpy(ln + 120 - bl, id, (size_t)bl); }   /* level/time/date right-justified at col 120 */
    a_line(ln);
}
static int sect_esdid(int sect) {                   /* ESDID of the control section with this internal id (for an LD's owning section) */
    int k; for (k = 0; k < nesdord; k++) if (esdord[k].role == ESD_SECT && esdord[k].s->sect == sect) return esdord[k].s->esdid;
    return main_sect_esdid;
}
static void a_esd_section(void) {
    int k; char ln[128], b[16];
    a_newpage("EXTERNAL SYMBOL DICTIONARY", "SYMBOL   TYPE  ID   ADDR  LENGTH LDID");
    for (k = 0; k < nesdord; k++) {
        struct sym *s = esdord[k].s; int role = esdord[k].role, nl = (int)strlen(s->name);
        memset(ln, ' ', 120); ln[120] = 0;
        if (nl > 8) { nl = 8; } memcpy(ln, s->name, (size_t)nl);                 /* SYMBOL col 1 */
        if (role == ESD_SECT) {
            memcpy(ln + 10, s->type == S_PC ? "PC" : "SD", 2);              /* TYPE col 11 */
            snprintf(b, sizeof b, "%04X", s->esdid); memcpy(ln + 14, b, 4); /* ID col 15 */
            snprintf(b, sizeof b, "%06lX", s->val & 0xffffffL); memcpy(ln + 19, b, 6);                         /* ADDR col 20 */
            snprintf(b, sizeof b, "%06lX", (s->esdid == main_sect_esdid ? modlen : 0) & 0xffffffL); memcpy(ln + 26, b, 6);  /* LENGTH col 27 */
        } else if (role == ESD_LD) {
            memcpy(ln + 10, "LD", 2);
            snprintf(b, sizeof b, "%06lX", s->val & 0xffffffL); memcpy(ln + 19, b, 6);
            snprintf(b, sizeof b, "%04X", sect_esdid(s->sect)); memcpy(ln + 33, b, 4);   /* LDID col 34 */
        } else {
            memcpy(ln + 10, s->is_weak ? "WX" : "ER", 2);
            snprintf(b, sizeof b, "%04X", s->esdid); memcpy(ln + 14, b, 4);
        }
        a_line(ln);
    }
}
static void a_rld_section(void) {
    int k; char ln[128], b[16];
    if (nrel == 0) return;
    { int a2, b2; for (a2 = 1; a2 < nrel; a2++) { struct reloc t = rels[a2]; b2 = a2 - 1;   /* group by (pos,rel) like the object RLD */
        while (b2 >= 0 && (rels[b2].pos > t.pos || (rels[b2].pos == t.pos && rels[b2].rel > t.rel))) { rels[b2 + 1] = rels[b2]; b2--; }
        rels[b2 + 1] = t; } }
    a_newpage("RELOCATION DICTIONARY", "POS.ID   REL.ID   FLAGS   ADDRESS");
    for (k = 0; k < nrel; k++) {
        int flag = (rels[k].isV ? 0x10 : 0) | (((rels[k].len - 1) & 3) << 2);
        memset(ln, ' ', 120); ln[120] = 0;
        snprintf(b, sizeof b, "%04X", rels[k].pos); memcpy(ln + 1, b, 4);     /* POS.ID col 2 */
        snprintf(b, sizeof b, "%04X", rels[k].rel); memcpy(ln + 10, b, 4);    /* REL.ID col 11 */
        snprintf(b, sizeof b, "%02X", flag); memcpy(ln + 20, b, 2);           /* FLAGS col 21 */
        snprintf(b, sizeof b, "%06lX", rels[k].addr & 0xffffffL); memcpy(ln + 27, b, 6);  /* ADDRESS col 28 */
        a_line(ln);
    }
}
/* object-code field: machine instructions in halfword groups (XXXX XXXX),
 * constants/data contiguous; both capped at the 8 bytes IFOX prints. A range
 * with no emitted bytes (a DS reservation) prints blank. */
static void a_objcode(long loc, int len, int instr, char *out) {
    int n = len; if (n > 8) n = 8; if (n < 0) n = 0;
    if (!instr && (n == 0 || !defn[loc])) { out[0] = 0; return; }   /* DS / nothing emitted */
    int o = 0, i;
    for (i = 0; i < n; i++) {
        if (instr && i && (i % 2) == 0) out[o++] = ' ';
        o += sprintf(out + o, "%02X", defn[loc + i] ? text[loc + i] : 0);
    }
    out[o] = 0;
}
#define A_SRC_LINECOUNT 55
static int a_srcrows;
static void a_src_newpage(void) {
    a_newpage("", "  LOC  OBJECT CODE    ADDR1 ADDR2  STMT   SOURCE STATEMENT");   /* the source page has no centred title, only the column header */
    a_srcrows = 0;
}
static void a_src_emit(const char *ln) {
    if (a_srcrows >= A_SRC_LINECOUNT) a_src_newpage();
    a_line(ln); a_srcrows++;
}
/* place 6-hex LOC at col 1 and the object code at col 8 in a blank 256-col line */
static void a_locobj(char *ln, long loc, const char *hex) {
    int j; for (j = 0; j < 255; j++) { ln[j] = ' '; } ln[255] = 0;
    char b[16]; sprintf(b, "%06lX", loc & 0xffffffL); memcpy(ln, b, 6);
    if (hex && hex[0]) memcpy(ln + 7, hex, strlen(hex));
}
/* the SOURCE STATEMENT listing: one row per expanded line (macro-generated rows
 * carry a '+'), then the literal pool numbered after the last source statement.
 * Columns: LOC@1 OBJECT@8 ADDR1@23 ADDR2@29 STMT(right-justified to 39)
 * '+'@40 SOURCE@41 -- the SOURCE image keeps the model card's column layout
 * (see gcard / render_model). */
static void a_src_section(char **lines, int nl) {
    char ln[256]; int i, j;
    a_srcrows = A_SRC_LINECOUNT;   /* force the header before the first row */
    int stmt = 0;
    for (i = 0; i < nl; i++) {
        stmt++;
        char buf[1024], lbl[32], op[16], opnd[1024];
        strncpy(buf, lines[i], sizeof buf - 1); buf[sizeof buf - 1] = 0;
        parse(buf, lbl, op, opnd);
        int gen   = (lflags[i] & LF_GEN) != 0;
        int noasm = (lflags[i] & LF_NOASM) != 0;
        const struct opc *o = noasm ? NULL : op_find(op);
        int is_instr = (o != NULL);
        int show_loc = 0, show_obj = 0;
        if (!noasm) {
            if (is_instr) { show_loc = show_obj = 1; }
            else if (!strcmp(op, "DC") || !strcmp(op, "DS") || !strcmp(op, "CCW") || !strcmp(op, "CNOP")) { show_loc = show_obj = 1; }
            else if (!strcmp(op, "CSECT") || !strcmp(op, "DSECT") || !strcmp(op, "COM")) { show_loc = 1; }
            else if (!strcmp(op, "EQU") || !strcmp(op, "ORG") || !strcmp(op, "LTORG")) { show_loc = 1; }
        }
        long loc = lrecs[i].loc; int len = lrecs[i].len;
        if (is_instr) {                                /* a halfword-alignment pad prints as its own object line */
            int pad = (int)(loc & 1);
            if (pad) { char hex[40]; a_objcode(loc, pad, 0, hex); a_locobj(ln, loc, hex); a_src_emit(ln); loc += pad; len -= pad; }
        }
        for (j = 0; j < 255; j++) { ln[j] = ' '; } ln[255] = 0;
        if (show_loc) { char b[16]; sprintf(b, "%06lX", loc & 0xffffffL); memcpy(ln, b, 6); }
        if (show_obj) { char hex[40]; a_objcode(loc, len, is_instr, hex); if (hex[0]) memcpy(ln + 7, hex, strlen(hex)); }
        if (!noasm && lrecs[i].hasa1) { char b[16]; sprintf(b, "%05lX", lrecs[i].a1 & 0xfffffL); memcpy(ln + 22, b, 5); }
        if (!noasm && lrecs[i].hasa2) { char b[16]; sprintf(b, "%05lX", lrecs[i].a2 & 0xfffffL); memcpy(ln + 28, b, 5); }
        { char sn[12]; int dl = sprintf(sn, "%d", stmt); if (dl > 6) dl = 6; memcpy(ln + 39 - dl, sn, (size_t)dl); if (gen) ln[39] = '+'; }
        { const char *s = gcard[i] ? gcard[i] : lines[i]; int sl = (int)strlen(s);
          while (sl > 0 && (s[sl-1] == '\n' || s[sl-1] == '\r')) sl--;
          for (j = 0; j < sl && 40 + j < 255; j++) ln[40 + j] = s[j]; }
        a_src_emit(ln);
    }
    /* literal pool: continue the statement numbers, in placement (address) order.
     * NB: this dumps ALL literals after the last source line -- correct for a
     * single trailing END pool, but a mid-stream LTORG would print its literals
     * here instead of at the LTORG, with out-of-sequence statement numbers. */
    { int order[4096], no = 0, k;
      for (k = 0; k < nlit && no < 4096; k++) if (lits[k].placed) order[no++] = k;
      for (k = 1; k < no; k++) { int t = order[k], m = k - 1;     /* insertion sort by location */
          while (m >= 0 && lits[order[m]].loc > lits[t].loc) { order[m + 1] = order[m]; m--; }
          order[m + 1] = t; }
      for (k = 0; k < no; k++) { struct lit *l = &lits[order[k]];
          char hex[40]; a_objcode(l->loc, l->size, 0, hex);
          a_locobj(ln, l->loc, hex);
          stmt++;
          { char sn[12]; int dl = sprintf(sn, "%d", stmt); if (dl > 6) dl = 6; memcpy(ln + 39 - dl, sn, (size_t)dl); }
          { int sl = (int)strlen(l->text), x; for (x = 0; x < sl && 55 + x < 255; x++) ln[55 + x] = l->text[x]; }   /* literal text at the operand column (listing col 56) */
          a_src_emit(ln); } }
}
static void emit_listing_a(char **lines, int nl) {
    if (!a_on) return;
    alst = alst_fn ? fopen(alst_fn, "w") : stdout;
    if (!alst) { perror(alst_fn); alst = stdout; }
    a_page = 0;
    if (a_esd) a_esd_section();
    if (a_src) a_src_section(lines, nl);
    if (a_rld) a_rld_section();
    if (alst && alst != stdout) fclose(alst);
}

static void usage(FILE *o) {
    fputs(
"Usage: as370 [options...] file\n"
" Options:\n"
"  -- -m              accept any valid HLASM option (not yet implemented)\n"
"  -a[sub-option...]  turn on listings\n"
"                     Sub-options:\n"
"                     e     produce external symbol dictionary\n"
"                     g     produce general purpose register cross-reference (not yet implemented)\n"
"                     i     produce product information (not yet implemented)\n"
"                     m     produce macro and copy code source summary (not yet implemented)\n"
"                     r     produce relocation dictionary\n"
"                     s     produce ordinary symbol and literal cross-reference (not yet implemented)\n"
"                     x     produce DSECT cross-reference (not yet implemented)\n"
"                     =FILE list to FILE (must be last sub-option)\n"
"  --help             show this message and exit\n"
"  -I dir             add PDS or HFS directory name to the search list for assembler macros\n"
"  -o OBJFILE         name object-file output OBJFILE in binary mode\n"
"  -v                 print as utility version\n"
"\n"
"environment:\n"
"  AS370_MACLIB       colon-separated default macro dirs (e.g. the installed\n"
"                     sysroot macro library), searched after any -I\n", o);
}
int main(int argc, char **argv) {
    const char *src = NULL, *objfn = NULL; int ai, eonly = 0;
    if (argc == 1) { usage(stdout); return 0; }            /* bare invocation: show usage, RC 0 */
    for (ai = 1; ai < argc; ai++) {
        if (!strcmp(argv[ai], "--help")) { usage(stdout); return 0; }
        else if (!strcmp(argv[ai], "-v")) { printf("%s %s - %s\n", AS370_NAME, AS370_VER_H, __DATE__); return 0; }
        else if (!strcmp(argv[ai], "-o") && ai + 1 < argc) objfn = argv[++ai];
        else if (!strcmp(argv[ai], "-d") && ai + 1 < argc) ++ai;   /* text-mode object: not yet implemented */
        else if (!strcmp(argv[ai], "-I") && ai + 1 < argc) { if (nmaclib < MAXMACLIB) maclib_dirs[nmaclib++] = argv[++ai]; }
        else if (!strcmp(argv[ai], "-m") && ai + 1 < argc) ++ai;   /* -m HLASM-option: accepted, not yet implemented */
        else if (!strcmp(argv[ai], "--")) { /* end of options: recognised, no-op */ }
        else if (!strcmp(argv[ai], "-E")) eonly = 1;       /* (internal) dump macro-expanded source */
        else if (!strcmp(argv[ai], "-L")) listing = 1;     /* (internal) terse stderr listing */
        else if (!strncmp(argv[ai], "-a", 2)) {            /* -a[ergsmix...][=FILE]: turn on listings */
            const char *p = argv[ai] + 2; a_on = 1; a_src = 1; int sel = 0;   /* the source listing is the base of -a; sub-letters add/select sections */
            for (; *p && *p != '='; p++) { switch (*p) {
                case 'e': a_esd = 1; sel = 1; break;   /* external symbol dictionary */
                case 'r': a_rld = 1; sel = 1; break;   /* relocation dictionary */
                case 's': a_xref = 1; sel = 1; break;  /* ordinary symbol + literal cross-reference (not yet produced) */
                case 'g': case 'i': case 'm': case 'x': sel = 1; break;   /* GPR xref / product info / macro summary / DSECT xref (not yet produced) */
                default: break;
            } }
            if (*p == '=' && p[1]) alst_fn = p + 1;        /* =FILE (must be the last sub-option) */
            if (!sel) { a_esd = a_rld = 1; }               /* bare -a -> LIST(MAX): every section we produce */
        }
        else src = argv[ai];
    }
    /* AS370_MACLIB: colon-separated default macro dirs (the installed sysroot
     * macro library), appended AFTER explicit -I so -I still wins.  Lets the
     * cc370 driver / a shell profile point at the sysroot macros without a
     * per-call -I -- the assembler equivalent of C_INCLUDE_PATH. */
    {
        const char *env = getenv("AS370_MACLIB");
        const char *s = env;
        while (s && *s && nmaclib < MAXMACLIB) {
            const char *e = s; while (*e && *e != ':') e++;
            if (e > s) {
                char *d = malloc((size_t)(e - s) + 1);
                memcpy(d, s, (size_t)(e - s)); d[e - s] = 0;
                maclib_dirs[nmaclib++] = d;
            }
            s = (*e == ':') ? e + 1 : e;
        }
    }
    if (!src) { usage(stderr); return 16; }                /* options given but no input file */
    init_sysvars();
    FILE *f = fopen(src, "r"); if (!f) { perror(src); return 16; }
    static char *raw0[MAXLINES], *raw[MAXLINES]; int nr = 0; char lb[256];
    while (fgets(lb, sizeof lb, f) && nr < MAXLINES) raw0[nr++] = strdup(lb);
    fclose(f);
    static int raw_org[MAXLINES];
    int n = join_cont(raw0, nr, raw, MAXLINES, NULL, raw_org);   /* fold column-72 continuations; raw_org = input line per statement */

    static char *lines[MAXLINES];
    int nl = macro_pass(raw, n, lines, raw_org);
    if (eonly) { int j; for (j = 0; j < nl; j++) { fputs(lines[j], stdout); if (lines[j][0] && lines[j][strlen(lines[j]) - 1] != '\n') putchar('\n'); } return 0; }

    do_pass(1, lines, nl);
    { int k, id = 0; for (k = 0; k < nesdord; k++)            /* SD/PC sections and ER refs get an ESDID; LD entries do not */
        if (esdord[k].role == ESD_SECT || esdord[k].role == ESD_ER) esdord[k].s->esdid = ++id; }
    { int k; main_sect_esdid = 0;            /* the content section: first named SD, else first section */
      for (k = 0; k < nesdord; k++) if (esdord[k].role == ESD_SECT && esdord[k].s->type == S_SD) { main_sect_esdid = esdord[k].s->esdid; break; }
      if (!main_sect_esdid) for (k = 0; k < nesdord; k++) if (esdord[k].role == ESD_SECT) { main_sect_esdid = esdord[k].s->esdid; break; } }
    { int k; for (k = 0; k < nlit; k++) lits[k].placed = 0; }
    do_pass(2, lines, nl);
    if (nunk) {   /* op that is neither a machine instruction, an assembler directive, conditional assembly, nor a resolvable macro */
        int j; for (j = 0; j < nunk; j++) {
            const char *s = lines[unkln[j]]; int sl = (int)strlen(s);
            while (sl > 0 && (s[sl-1] == '\n' || s[sl-1] == '\r')) sl--;
            fprintf(stderr, "%.*s\n", sl, s);                               /* the flagged source statement */
            fprintf(stderr, " ERROR: Undefined operation code in line %d - %s\n", line_org[unkln[j]], unkops[j]);
        }
        errors += nunk;   /* RC 8: the build pipeline must catch a missing macro */
    }

    if (objfn) {
        FILE *of = fopen(objfn, "wb"); if (!of) { perror(objfn); return 16; }
        emit_obj(of); fclose(of);
    }
    emit_listing_a(lines, nl);
    if (errors)   /* highest severity is 8 (our only diagnostic class today) */
        fprintf(stderr, " Assembler Done   %d Statement%s Flagged /   8 was Highest Severity\n", errors, errors == 1 ? "" : "s");
    return errors ? 8 : 0;   /* RC: 0 = clean (silent), 8 = error(s). Finer 4/12/16 once we classify warnings/severe/terminal. */
}
