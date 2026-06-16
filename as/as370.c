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

#define MAXSYM 256
#define MAXLIT 256
#define MAXREL 256
#define TEXTMAX 65536

enum fmt { F_NONE, F_RR, F_RX, F_RS, F_SI, F_SS, F_BR, F_BC };

struct opc { const char *name; int fmt; int op; int m1; };  /* m1 = implied mask for branch pseudos */
static const struct opc optab[] = {
#include "opc_table.h"
    /* extended branches: BC (RX, op 0x47) / BCR (RR-ish, op 0x07) with implied mask */
    { "B",  F_BC, 0x47, 15 }, { "NOP", F_BC, 0x47, 0 },
    { "BE", F_BC, 0x47, 8 }, { "BNE", F_BC, 0x47, 7 }, { "BH", F_BC, 0x47, 2 }, { "BL", F_BC, 0x47, 4 },
    { "BNH", F_BC, 0x47, 13 }, { "BNL", F_BC, 0x47, 11 }, { "BZ", F_BC, 0x47, 8 }, { "BNZ", F_BC, 0x47, 7 },
    { "BP", F_BC, 0x47, 2 }, { "BM", F_BC, 0x47, 4 }, { "BO", F_BC, 0x47, 1 }, { "BNO", F_BC, 0x47, 14 },
    { "BCT", F_RX, 0x46, 0 },
    { "BR",  F_BR, 0x07, 15 }, { "BER", F_BR, 0x07, 8 }, { "BNER", F_BR, 0x07, 7 }, { "NOPR", F_BR, 0x07, 0 },
    { NULL, 0, 0, 0 }
};

enum stype { S_REL, S_SD, S_PC, S_ER, S_LD, S_ABS };
struct sym { char name[9]; long val; int type; int defined; int esdid; int is_entry; };
static struct sym syms[MAXSYM];
static int nsym;
static struct sym *esdord[MAXSYM]; static int nesdord;   /* ESD entries in declaration order */

struct lit { char text[32]; long loc; long val; int placed; int isV; int isA; int ltseq; char ext[9]; };
static struct lit lits[MAXLIT];
static int nlit;

struct reloc { long addr; int pos, rel, isV; };
static struct reloc rels[MAXREL];
static int nrel;

static unsigned char text[TEXTMAX];
static unsigned char defn[TEXTMAX];   /* 1 = byte has content (for TXT segmentation) */
static long lc, modlen;
static int  using_reg = -1;
static long using_base;
static int  cur_sect_esdid, main_sect_esdid;
static int  end_esdid; static long end_addr; static int end_has;
static int  errors;

static unsigned char a2e(int c);   /* fwd */

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
static void esd_add(struct sym *s) {
    int i; for (i = 0; i < nesdord; i++) if (esdord[i] == s) return;
    if (nesdord < MAXSYM) esdord[nesdord++] = s;
}
static struct lit *lit_get(const char *t) {
    int i; for (i = 0; i < nlit; i++) if (!strcmp(lits[i].text, t)) return &lits[i];
    if (nlit >= MAXLIT) { fprintf(stderr, "as370: literal table full\n"); exit(2); }
    memset(&lits[nlit], 0, sizeof lits[0]); strncpy(lits[nlit].text, t, sizeof lits[0].text - 1);
    return &lits[nlit++];
}

static long expr_val(const char *e, int *reloc) {
    if (reloc) *reloc = 0;
    if (*e == '*') return lc;
    if (isdigit((unsigned char)*e) || *e == '-') return strtol(e, NULL, 10);
    struct sym *s = sym_find(e);
    if (s) { if (reloc && s->type == S_REL) *reloc = 1; return s->val; }
    return 0;
}
static void put(long at, long v, int n) {
    int i; for (i = n - 1; i >= 0; i--) { text[at + i] = (unsigned char)(v & 0xff); defn[at + i] = 1; v >>= 8; }
    if (at + n > modlen) modlen = at + n;
}
static long align4(long x) { return (x + 3) & ~3L; }
static long align8(long x) { return (x + 7) & ~7L; }
static int hexv(int c) { if (c >= '0' && c <= '9') return c - '0'; c = toupper((unsigned char)c); if (c >= 'A' && c <= 'F') return c - 'A' + 10; return 0; }

/* split operand into fields at top-level (depth-0) commas */
static int split_fields(const char *s, char f[][64], int max) {
    int n = 0, depth = 0; const char *start = s, *p = s;
    for (;; p++) {
        if (*p == '(') depth++;
        else if (*p == ')') depth--;
        if ((*p == ',' && depth == 0) || *p == 0) {
            int len = (int)(p - start); if (len > 63) len = 63;
            if (n < max) { memcpy(f[n], start, len); f[n][len] = 0; n++; }
            if (*p == 0) break; start = p + 1;
        }
    }
    return n;
}
static long imm_val(const char *s) {
    if (s[0] == 'C' && s[1] == '\'') return a2e((unsigned char)s[2]);
    if (s[0] == 'X' && s[1] == '\'') return strtol(s + 2, NULL, 16);
    return strtol(s, NULL, 10);
}
/* resolve a memory operand into displacement d, index/length a, base b */
/* parse a memory operand: displacement *d, explicit subscripts sub[0..*nsub),
 * *sym=1 for a symbol/literal resolved through USING (then sub[0]=base reg).
 * Subscript->field mapping is format-specific (RX: sub0=index; RS/SI/SS: base). */
static void resolve(const char *f, long *d, long sub[4], int *nsub, int *sym) {
    *nsub = 0; *sym = 0; *d = 0;
    if (f[0] == '=') { struct lit *l = lit_get(f); *d = l->loc - using_base; *sym = 1; sub[0] = using_reg; return; }
    const char *lp = strchr(f, '(');
    if (lp) {
        *d = strtol(f, NULL, 10);
        const char *rp = strchr(lp, ')');
        int n = rp ? (int)(rp - lp - 1) : (int)strlen(lp + 1);
        char inside[64]; if (n > 63) n = 63; memcpy(inside, lp + 1, n); inside[n] = 0;
        char *tok = inside;
        while (1) { char *cm = strchr(tok, ','); int len = cm ? (int)(cm - tok) : (int)strlen(tok);
            char t[32]; if (len > 31) len = 31; memcpy(t, tok, len); t[len] = 0;
            if (*nsub < 4) sub[(*nsub)++] = t[0] ? atol(t) : 0;
            if (!cm) break; tok = cm + 1; }
    } else {
        struct sym *s = sym_find(f); long tgt = s ? s->val : 0;
        *d = tgt - using_base; *sym = 1; sub[0] = using_reg;
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
        i = 0; while (*p && !isspace((unsigned char)*p)) { if (i < 8) lbl[i++] = *p; p++; } lbl[i < 8 ? i : 8] = 0;
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
        if (i < 127) opnd[i++] = *p; p++;
    } }
    opnd[i] = 0;
    return 1;
}
static const struct opc *op_find(const char *n) {
    int i; for (i = 0; optab[i].name; i++) if (!strcmp(optab[i].name, n)) return &optab[i];
    return NULL;
}
static void add_reloc(long at, const char *target, int isV) {
    struct sym *s = sym_find(target);
    int rel = (s && s->esdid) ? s->esdid : cur_sect_esdid;
    if (nrel >= MAXREL) { fprintf(stderr, "as370: reloc table full\n"); exit(2); }
    rels[nrel].addr = at; rels[nrel].pos = cur_sect_esdid; rels[nrel].rel = rel; rels[nrel].isV = isV; nrel++;
}
static int ins_len(int fmt) { return (fmt == F_RR || fmt == F_BR) ? 2 : (fmt == F_SS) ? 6 : 4; }

/* ---- WP-4 macro preprocessor --------------------------------------------- */
#define MAXLINES 8192
struct macro {
    char namep[20], name[16];
    char pname[24][20], pdef[24][40]; int pkey[24]; int nparm;
    char *body[256]; int nbody;
    char endlbl[20];               /* sequence symbol on the MEND line, if any */
};
static struct macro macros[64];
static int nmac;
static struct macro *mac_find(const char *n) {
    int i; for (i = 0; i < nmac; i++) if (!strcmp(macros[i].name, n)) return &macros[i];
    return NULL;
}
/* ---- macro expansion context + conditional assembly --------------------- */
struct ctx {
    struct macro *m;
    char pv[24][96];                       /* parameter values (may be sublists) */
    const char *namepval;
    char sn[64][20], sv[64][96]; int nset;  /* local SET symbols */
};
static char *set_find(struct ctx *c, const char *n) {
    int i; for (i = 0; i < c->nset; i++) if (!strcmp(c->sn[i], n)) return c->sv[i];
    return NULL;
}
static void set_put(struct ctx *c, const char *n, const char *v) {
    char *e = set_find(c, n);
    if (e) { strncpy(e, v, 95); e[95] = 0; return; }
    if (c->nset < 64) { strncpy(c->sn[c->nset], n, 19); c->sn[c->nset][19] = 0;
                        strncpy(c->sv[c->nset], v, 95); c->sv[c->nset][95] = 0; c->nset++; }
}
/* sublist value "(a,b,c)" -> element count / 1-based element */
static int sub_count(const char *v) {
    if (!v[0]) return 0; if (v[0] != '(') return 1;
    int n = 1; const char *p; for (p = v + 1; *p && *p != ')'; p++) if (*p == ',') n++; return n;
}
static void sub_elem(const char *v, int idx, char *out) {
    out[0] = 0;
    if (v[0] != '(') { if (idx == 1) { strncpy(out, v, 95); out[95] = 0; } return; }
    const char *s = v + 1; int n = 1; const char *p = s;
    for (;; p++) if (*p == ',' || *p == ')' || !*p) {
        if (n == idx) { int L = (int)(p - s); if (L > 95) L = 95; memcpy(out, s, L); out[L] = 0; return; }
        n++; s = p + 1; if (*p == ')' || !*p) return;
    }
}
/* value of a "&name" / "&name(idx)" reference (param, then SET symbol) */
static void vref(struct ctx *c, const char *ref, char *out) {
    out[0] = 0;
    const char *p = ref + 1; char nm[24]; int i = 0;
    while (*p && (isalnum((unsigned char)*p) || *p=='@'||*p=='#'||*p=='$'||*p=='_') && i < 22) nm[i++] = *p++;
    nm[i] = 0;
    char amp[26]; snprintf(amp, sizeof amp, "&%s", nm);
    const char *base = NULL; int k;
    if (c->m->namep[0] && !strcmp(amp, c->m->namep)) base = c->namepval ? c->namepval : "";
    else for (k = 0; k < c->m->nparm; k++) if (!strcmp(amp, c->m->pname[k])) { base = c->pv[k]; break; }
    if (!base) base = set_find(c, amp);
    if (!base) base = "";
    if (*p == '(') { sub_elem(base, atoi(p + 1), out); }
    else { strncpy(out, base, 95); out[95] = 0; }
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
static long e_prim(void) {
    e_sp();
    if (*ep_ == '(') { ep_++; long v = e_expr(); e_sp(); if (*ep_ == ')') ep_++; return v; }
    if ((*ep_ == 'N' || *ep_ == 'K' || *ep_ == 'L') && ep_[1] == '\'') {
        int kind = *ep_; ep_ += 2; char ref[44], v[96];
        if (*ep_ == '&') { e_readref(ref); vref(ec_, ref, v); } else v[0] = 0;
        return (kind == 'N') ? sub_count(v) : (long)strlen(v);
    }
    if (*ep_ == '&') { char ref[44], v[96]; e_readref(ref); vref(ec_, ref, v); return atol(v); }
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
/* SETC: 'string'(with subst, optional substring (s,l)) or a bare &ref */
static void eval_setc(struct ctx *c, const char *s, char *out) {
    out[0] = 0;
    if (s[0] == '\'') {
        const char *q = strchr(s + 1, '\''); int L = q ? (int)(q - s - 1) : (int)strlen(s + 1);
        char inner[128]; if (L > 127) L = 127; memcpy(inner, s + 1, L); inner[L] = 0;
        char sub[128]; msub(c, inner, sub);
        if (q && q[1] == '(') {           /* substring (start,len) */
            ec_ = c; ep_ = q + 2; long st = e_expr(); e_sp(); long ln = 0;
            if (*ep_ == ',') { ep_++; ln = e_expr(); }
            int n = (int)strlen(sub), a = (int)st - 1; if (a < 0) a = 0; if (a > n) a = n;
            int take = (int)ln; if (take > n - a) take = n - a; if (take < 0) take = 0;
            memcpy(out, sub + a, take); out[take] = 0;
        } else { strncpy(out, sub, 95); out[95] = 0; }
    } else msub(c, s, out);
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
    if (!strcmp(rel, "EQ")) return cmp == 0; if (!strcmp(rel, "NE")) return cmp != 0;
    if (!strcmp(rel, "GT")) return cmp > 0;  if (!strcmp(rel, "LT")) return cmp < 0;
    if (!strcmp(rel, "GE")) return cmp >= 0; if (!strcmp(rel, "LE")) return cmp <= 0;
    return 0;
}
static int eval_comp(struct ctx *c, const char *L, const char *rel, const char *R) {
    int cmp;
    if (term_is_str(L) || term_is_str(R)) { char ls[128], rs[128]; term_str(c, L, ls); term_str(c, R, rs); cmp = strcmp(ls, rs); }
    else { long lv = eval_seta(c, L), rv = eval_seta(c, R); cmp = (lv < rv) ? -1 : (lv > rv) ? 1 : 0; }
    return rel_apply(rel, cmp);
}
/* evaluate an AIF condition: comparisons joined by AND/OR (left to right) */
static int eval_cond(struct ctx *c, const char *cond) {
    char toks[24][96]; int nt = 0; const char *p = cond;
    while (*p) {
        while (*p == ' ') p++; if (!*p) break;
        char *o = toks[nt]; int q = 0, d = 0, oi = 0;
        while (*p && (q || d || *p != ' ')) { if (*p == '\'') q = !q; else if (!q && *p == '(') d++; else if (!q && *p == ')') d--; if (oi < 95) o[oi++] = *p; p++; }
        o[oi] = 0; if (nt < 23) nt++;
    }
    if (nt < 3) return 0;
    int res = eval_comp(c, toks[0], toks[1], toks[2]); int i = 3;
    while (i + 2 < nt) {
        const char *conn = toks[i]; int r = eval_comp(c, toks[i + 1], toks[i + 2], toks[i + 3]);
        if (!strcmp(conn, "OR")) res = res || r; else if (!strcmp(conn, "AND")) res = res && r;
        i += 4;
    }
    return res;
}
/* split "(cond)seqsym" -> cond (no outer parens), seqsym */
static void aif_split(const char *opnd, char *cond, char *seq) {
    cond[0] = seq[0] = 0; const char *p = opnd; if (*p != '(') return;
    int d = 0, q = 0; const char *cs = p + 1;
    for (; *p; p++) { if (*p == '\'') q = !q;
        else if (!q && *p == '(') { d++; if (d == 1) cs = p + 1; }
        else if (!q && *p == ')') { if (--d == 0) { int L = (int)(p - cs); memcpy(cond, cs, L); cond[L] = 0; strcpy(seq, p + 1); return; } } }
}

/* ---- macro library (-I dirs): COPY members + macro lookup by name -------- */
static char *maclib_dirs[8]; static int nmaclib;
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
static int lib_readlines(const char *name, char *buf[], int max) {
    char path[256]; if (!lib_path(name, path)) return -1;
    FILE *f = fopen(path, "r"); if (!f) return -1;
    char lb[256]; int n = 0; while (fgets(lb, sizeof lb, f) && n < max) buf[n++] = strdup(lb);
    fclose(f); return n;
}
static struct macro *capture_macro(char **in, int nin, int *ip) {
    int i = *ip + 1; if (i >= nin) { *ip = i; return NULL; }
    char pb[256], pl[16], po[16], pp[128]; strncpy(pb, in[i], 255); pb[255] = 0; parse(pb, pl, po, pp);
    struct macro *m = &macros[nmac++]; memset(m, 0, sizeof *m);
    strncpy(m->namep, pl, sizeof m->namep - 1); strncpy(m->name, po, sizeof m->name - 1);
    if (pp[0]) { char flds[24][64]; int nf = split_fields(pp, flds, 24), k;
        for (k = 0; k < nf && k < 24; k++) { char *eq = strchr(flds[k], '=');
            if (eq) { *eq = 0; strncpy(m->pname[k], flds[k], 19); strncpy(m->pdef[k], eq + 1, 39); m->pkey[k] = 1; }
            else strncpy(m->pname[k], flds[k], 19); m->nparm++; } }
    while (++i < nin) { char bb[256], bl[16], bo[16], bd[128]; strncpy(bb, in[i], 255); bb[255] = 0; parse(bb, bl, bo, bd);
        if (!strcmp(bo, "MEND")) { if (bl[0] == '.') strncpy(m->endlbl, bl, 19); break; }
        if (m->nbody < 256) m->body[m->nbody++] = strdup(in[i]); }
    *ip = i; return m;
}
static struct macro *lib_load(const char *name) {
    struct macro *m = mac_find(name); if (m) return m;
    static char *buf[1024]; int n = lib_readlines(name, buf, 1024); if (n < 0) return NULL;
    int i = 0; for (; i < n; i++) { char b[256], l[16], o[16], od[128]; strncpy(b, buf[i], 255); b[255] = 0;
        if (!parse(b, l, o, od) || !o[0]) continue; if (strcmp(o, "MACRO")) return NULL; break; }
    if (i >= n) return NULL;
    return capture_macro(buf, n, &i);
}
static int known_op(const char *o) {
    if (op_find(o)) return 1;
    const char *d[] = { "CSECT", "ENTRY", "EXTRN", "WXTRN", "USING", "DROP", "DS", "DC", "EQU", "LTORG", "END",
                        "COPY", "MACRO", "MEND", "DSECT", "ORG", "TITLE", "PRINT", "SPACE", "EJECT", NULL };
    int i; for (i = 0; d[i]; i++) if (!strcmp(o, d[i])) return 1; return 0;
}

static void mexp_line(const char *line, char **out, int *nout, int depth);
static int g_sysndx;
/* expand a macro invocation, interpreting conditional assembly */
static void mexp_macro(struct macro *m, const char *lbl, const char *opnd, char **out, int *nout, int depth) {
    struct ctx c; memset(&c, 0, sizeof c); c.m = m; c.namepval = lbl; g_sysndx++;
    int k;
    for (k = 0; k < m->nparm; k++) { strncpy(c.pv[k], m->pkey[k] ? m->pdef[k] : "", 95); c.pv[k][95] = 0; }
    if (opnd[0]) { char args[24][64]; int na = split_fields(opnd, args, 24), pos = 0;
        for (k = 0; k < na; k++) {
            char *eq = strchr(args[k], '='); int iskw = eq && eq != args[k];
            if (iskw) { char *cc; for (cc = args[k]; cc < eq; cc++) if (!isalnum((unsigned char)*cc) && *cc!='@'&&*cc!='#'&&*cc!='$'&&*cc!='_') { iskw = 0; break; } }
            if (iskw) { *eq = 0; int j; char nm[26]; snprintf(nm, sizeof nm, "&%s", args[k]);
                for (j = 0; j < m->nparm; j++) if (!strcmp(nm, m->pname[j])) { strncpy(c.pv[j], eq + 1, 95); c.pv[j][95] = 0; break; } }
            else { int j, cc2 = 0; for (j = 0; j < m->nparm; j++) if (!m->pkey[j]) { if (cc2 == pos) { strncpy(c.pv[j], args[k], 95); c.pv[j][95] = 0; break; } cc2++; } pos++; }
        }
    }
    /* prescan sequence-symbol labels */
    char seqn[128][20]; int seqi[128], nseq = 0;
    for (k = 0; k < m->nbody; k++) if (m->body[k][0] == '.' && m->body[k][1] != '*') {
        char sl[20]; int j = 0; const char *q = m->body[k]; while (*q && !isspace((unsigned char)*q) && j < 19) sl[j++] = *q++; sl[j] = 0;
        if (nseq < 128) { strcpy(seqn[nseq], sl); seqi[nseq] = k; nseq++; }
    }
    if (m->endlbl[0] && nseq < 128) { strcpy(seqn[nseq], m->endlbl); seqi[nseq] = m->nbody; nseq++; }
    int pc = 0, guard = 0;
    while (pc < m->nbody && guard++ < 100000) {
        char bb[256], bl[16], bo[16], bod[128];
        strncpy(bb, m->body[pc], 255); bb[255] = 0; parse(bb, bl, bo, bod);
        if (!bo[0]) { pc++; continue; }
        if (!strcmp(bo, "MEND") || !strcmp(bo, "MEXIT")) break;
        if (!strcmp(bo, "ANOP") || !strcmp(bo, "PRINT") || !strcmp(bo, "SPACE") || !strcmp(bo, "EJECT") || !strcmp(bo, "MNOTE")) { pc++; continue; }
        if (!strncmp(bo, "GBL", 3) || !strncmp(bo, "LCL", 3)) { char fl[8][64]; int nf = split_fields(bod, fl, 8), j; for (j = 0; j < nf; j++) set_put(&c, fl[j], bo[3] == 'C' ? "" : "0"); pc++; continue; }
        if (!strcmp(bo, "SETA")) { long v = eval_seta(&c, bod); char nb[24]; sprintf(nb, "%ld", v); set_put(&c, bl, nb); pc++; continue; }
        if (!strcmp(bo, "SETB")) { int v = bod[0] == '(' ? eval_cond(&c, bod + 1) : (int)eval_seta(&c, bod); set_put(&c, bl, v ? "1" : "0"); pc++; continue; }
        if (!strcmp(bo, "SETC")) { char v[128]; eval_setc(&c, bod, v); set_put(&c, bl, v); pc++; continue; }
        if (!strcmp(bo, "AIF")) { char cond[128], seq[20]; aif_split(bod, cond, seq);
            if (eval_cond(&c, cond)) { int j, t = -1; for (j = 0; j < nseq; j++) if (!strcmp(seqn[j], seq)) { t = seqi[j]; break; } if (t >= 0) { pc = t; continue; } }
            pc++; continue; }
        if (!strcmp(bo, "AGO")) { int j, t = -1; for (j = 0; j < nseq; j++) if (!strcmp(seqn[j], bod)) { t = seqi[j]; break; } if (t >= 0) { pc = t; continue; } pc++; continue; }
        /* model statement (or nested macro call) */
        char ex[300]; msub(&c, m->body[pc], ex);
        mexp_line(ex, out, nout, depth + 1);
        pc++;
    }
}
/* expand one statement: macro call -> interpret; else emit (stripping any
 * leading sequence-symbol label so it never reaches the core). */
static void mexp_line(const char *line, char **out, int *nout, int depth) {
    char buf[256], lbl[16], op[16], opnd[128];
    strncpy(buf, line, 255); buf[255] = 0; parse(buf, lbl, op, opnd);
    if (op[0] && !strcmp(op, "COPY") && opnd[0] && depth <= 40) {
        char *cb[512]; int n = lib_readlines(opnd, cb, 512);
        if (n >= 0) { int j; for (j = 0; j < n; j++) mexp_line(cb[j], out, nout, depth + 1); return; }
    }
    struct macro *m = NULL;
    if (op[0] && !known_op(op) && depth <= 40) { m = mac_find(op); if (!m) m = lib_load(op); }
    if (m) { mexp_macro(m, lbl[0] == '.' ? "" : lbl, opnd, out, nout, depth); return; }
    if (*nout >= MAXLINES) return;
    if (lbl[0] == '.') { char r[300]; snprintf(r, sizeof r, "         %s %s", op, opnd); out[(*nout)++] = strdup(r); }
    else out[(*nout)++] = strdup(line);
}
/* macro pass: capture MACRO/MEND defs, expand calls -> flat open code */
static int macro_pass(char **in, int nin, char **out) {
    int nout = 0, i;
    for (i = 0; i < nin; i++) {
        char buf[256], lbl[16], op[16], opnd[128];
        strncpy(buf, in[i], 255); buf[255] = 0; parse(buf, lbl, op, opnd);
        if (!strcmp(op, "MACRO")) { capture_macro(in, nin, &i); continue; }
        mexp_line(in[i], out, &nout, 0);
    }
    return nout;
}

static char unkops[128][12]; static int nunk;
static void note_unknown(const char *o) {
    static const char *skip[] = { "SETA","SETB","SETC","GBLA","GBLB","GBLC","LCLA","LCLB","LCLC",
        "AIF","AGO","ANOP","MNOTE","MEXIT","PRINT","SPACE","EJECT","TITLE","DSECT","ORG","CXD","COPY","MACRO","MEND",
        "EXTRN","WXTRN", NULL };
    int i; for (i = 0; skip[i]; i++) if (!strcmp(o, skip[i])) return;
    for (i = 0; i < nunk; i++) if (!strcmp(unkops[i], o)) return;
    if (nunk < 128) { strncpy(unkops[nunk], o, 11); unkops[nunk][11] = 0; nunk++; }
}
static void do_pass(int pass, char **lines, int nlines) {
    int i, ltidx = 0;
    lc = 0;
    if (pass == 2) { using_reg = -1; nrel = 0; }
    for (i = 0; i < nlines; i++) {
        char buf[256], lbl[16], op[16], opnd[128];
        strncpy(buf, lines[i], sizeof buf - 1); buf[sizeof buf - 1] = 0;
        if (!parse(buf, lbl, op, opnd)) continue;
        if (!op[0]) continue;

        const struct opc *o = op_find(op);
        if (o) {
            while (lc & 1) { if (pass == 2) put(lc, 0, 1); lc++; }   /* instructions are halfword-aligned */
            char F[4][64]; int nf = split_fields(opnd, F, 4); (void)nf;
            if (pass == 1) {
                if (lbl[0]) { struct sym *s = sym_get(lbl); s->val = lc; s->defined = 1; }
                int k; for (k = 0; k < nf; k++) if (F[k][0] == '=') lit_get(F[k]);
                lc += ins_len(o->fmt);
            } else {
                long d, d2, sub[4], sub2[4]; int ns, ns2, sy, sy2;
                switch (o->fmt) {
                case F_RR:
                    put(lc, (o->op << 8) | ((int)expr_val(F[0], 0) << 4) | (int)expr_val(F[1], 0), 2); lc += 2; break;
                case F_BR:
                    put(lc, (o->op << 8) | (o->m1 << 4) | (int)expr_val(F[0], 0), 2); lc += 2; break;
                case F_RX: case F_BC: {
                    int r1 = (o->fmt == F_BC) ? o->m1 : (int)expr_val(F[0], 0);
                    resolve((o->fmt == F_BC) ? F[0] : F[1], &d, sub, &ns, &sy);
                    int x = sy ? 0 : (int)sub[0], b = sy ? (int)sub[0] : (ns >= 2 ? (int)sub[1] : 0);
                    put(lc, ((long)o->op << 24) | ((long)r1 << 20) | ((long)x << 16) | ((long)b << 12) | (d & 0xfff), 4); lc += 4; break; }
                case F_RS: { int r1 = (int)expr_val(F[0], 0), r3 = (int)expr_val(F[1], 0); resolve(F[2], &d, sub, &ns, &sy);
                    int b = (int)sub[0];
                    put(lc, ((long)o->op << 24) | ((long)r1 << 20) | ((long)r3 << 16) | ((long)b << 12) | (d & 0xfff), 4); lc += 4; break; }
                case F_SI: { resolve(F[0], &d, sub, &ns, &sy); int b = (int)sub[0]; long im = imm_val(F[1]);
                    put(lc, ((long)o->op << 24) | ((long)(im & 0xff) << 16) | ((long)b << 12) | (d & 0xfff), 4); lc += 4; break; }
                case F_SS: { resolve(F[0], &d, sub, &ns, &sy); resolve(F[1], &d2, sub2, &ns2, &sy2);
                    int len = (int)sub[0], b1 = (ns >= 2 ? (int)sub[1] : (int)sub[0]), b2 = (int)sub2[0];
                    put(lc, o->op, 1); put(lc + 1, (len - 1) & 0xff, 1);
                    put(lc + 2, ((long)b1 << 12) | (d & 0xfff), 2); put(lc + 4, ((long)b2 << 12) | (d2 & 0xfff), 2); lc += 6; break; }
                default: break;
                }
            }
            continue;
        }

        if (!strcmp(op, "CSECT")) {
            lc = 0;
            if (pass == 1) { struct sym *s = lbl[0] ? sym_get(lbl) : sym_get("");
                s->type = lbl[0] ? S_SD : S_PC; s->val = 0; s->defined = 1; esd_add(s); }
            if (pass == 2) { struct sym *s = sym_find(lbl[0] ? lbl : ""); if (s) cur_sect_esdid = s->esdid; }
        } else if (!strcmp(op, "ENTRY")) {
            if (pass == 1 && opnd[0]) { struct sym *s = sym_get(opnd); s->is_entry = 1; esd_add(s); }
        } else if (!strcmp(op, "EXTRN") || !strcmp(op, "WXTRN")) {
            if (pass == 1 && opnd[0]) { char f[8][64]; int nf = split_fields(opnd, f, 8), j;
                for (j = 0; j < nf; j++) { struct sym *s = sym_get(f[j]); s->type = S_ER; esd_add(s); } }
        } else if (!strcmp(op, "USING")) {
            char F[4][64]; split_fields(opnd, F, 4);
            if (pass == 2) { using_reg = (int)expr_val(F[1], 0); using_base = (F[0][0] == '*') ? lc : expr_val(F[0], 0); }
        } else if (!strcmp(op, "DROP")) {
            if (pass == 2) using_reg = -1;
        } else if (!strcmp(op, "DS") || !strcmp(op, "DC")) {
            const char *p = opnd; int cnt = 0, hascnt = 0;
            while (isdigit((unsigned char)*p)) { cnt = cnt * 10 + (*p - '0'); hascnt = 1; p++; }
            if (!hascnt) cnt = 1;
            int ty = *p ? toupper((unsigned char)*p++) : 0, k;
            int blen = 0, haslen = 0;            /* explicit length modifier Ln */
            if (*p == 'L') { p++; haslen = 1; while (isdigit((unsigned char)*p)) blen = blen * 10 + (*p++ - '0'); }
            if (ty == 'F' || ty == 'A' || ty == 'H' || ty == 'D' || ty == 'Y') {
                int base = (ty == 'D') ? 8 : (ty == 'H' || ty == 'Y') ? 2 : 4;
                if (!haslen) { blen = base; lc = (base == 8) ? align8(lc) : (base == 2) ? ((lc + 1) & ~1L) : align4(lc); }
                if (pass == 1 && lbl[0]) { struct sym *s = sym_get(lbl); s->val = lc; s->defined = 1; }
                long val = 0; char ename[64] = ""; int isrel = 0, isaddr = (ty == 'A' || ty == 'Y');
                if (isaddr) { const char *lp = strchr(p, '('), *rp = strrchr(p, ')');
                    if (lp && rp && rp > lp) { size_t n = rp - lp - 1; if (n > 63) n = 63; memcpy(ename, lp + 1, n); ename[n] = 0; }
                    struct sym *es = sym_find(ename);
                    isrel = es && (es->type == S_SD || es->type == S_PC || es->type == S_REL || es->type == S_ER); }
                else { const char *q = strchr(p, '\''); if (q) val = strtol(q + 1, NULL, 10); }
                for (k = 0; k < cnt; k++) {
                    if (pass == 2 && !strcmp(op, "DC")) {
                        if (isaddr) { put(lc, expr_val(ename, NULL), blen); if (isrel) add_reloc(lc, ename, 0); }
                        else put(lc, val, blen);
                    }
                    lc += blen;
                }
            } else if (ty == 'C') {                     /* EBCDIC characters; '' -> one quote */
                if (pass == 1 && lbl[0]) { struct sym *s = sym_get(lbl); s->val = lc; s->defined = 1; }
                const char *q = strchr(p, '\''); char body[256]; int slen = 0;
                if (q) { const char *e = q + 1;
                    while (*e && slen < 255) {
                        if (*e == '\'') { if (e[1] == '\'') { body[slen++] = '\''; e += 2; continue; } break; }
                        body[slen++] = *e++;
                    } }
                int emit = haslen ? blen : slen;
                for (k = 0; k < cnt; k++) { int j; for (j = 0; j < emit; j++) { if (pass == 2 && !strcmp(op, "DC")) put(lc, j < slen ? a2e((unsigned char)body[j]) : 0x40, 1); lc++; } }
            } else if (ty == 'X') {                     /* hex bytes, byte-aligned */
                if (pass == 1 && lbl[0]) { struct sym *s = sym_get(lbl); s->val = lc; s->defined = 1; }
                const char *q = strchr(p, '\''); unsigned char by[256]; int nb = 0;
                if (q) { char h[520]; int hl = 0, s0 = 0; const char *e = q + 1;
                    while (*e && *e != '\'' && hl < 519) { if (isxdigit((unsigned char)*e)) h[hl++] = *e; e++; }
                    if (hl & 1) { by[nb++] = (unsigned char)hexv(h[0]); s0 = 1; }
                    for (; s0 + 1 < hl; s0 += 2) by[nb++] = (unsigned char)((hexv(h[s0]) << 4) | hexv(h[s0 + 1]));
                }
                int emit = haslen ? blen : nb, pad = emit - nb;
                for (k = 0; k < cnt; k++) { int j; for (j = 0; j < emit; j++) { if (pass == 2 && !strcmp(op, "DC")) put(lc, (j >= pad && j - pad < nb) ? by[j - pad] : 0, 1); lc++; } }
            } else if (pass == 1 && lbl[0]) { struct sym *s = sym_get(lbl); s->val = lc; s->defined = 1; }
        } else if (!strcmp(op, "EQU")) {
            if (pass == 1 && lbl[0]) { struct sym *s = sym_get(lbl); s->val = (opnd[0] == '*') ? lc : expr_val(opnd, NULL); s->defined = 1; }
        } else if (!strcmp(op, "LTORG") || !strcmp(op, "END")) {
            int k;
            if (!strcmp(op, "END") && opnd[0]) {
                end_has = 1;
                if (pass == 2) { struct sym *s = sym_find(opnd); if (s) { end_addr = s->val; end_esdid = s->esdid ? s->esdid : main_sect_esdid; } }
            }
            int first = 1;
            for (k = 0; k < nlit; k++) {
                if (lits[k].placed) continue;
                if (pass == 2 && lits[k].ltseq != ltidx) continue;
                lc = first ? align8(lc) : align4(lc); first = 0;   /* literal pool starts on a doubleword */
                if (pass == 1) {
                    lits[k].loc = lc; lits[k].ltseq = ltidx;
                    char tmp[32]; strncpy(tmp, lits[k].text, sizeof tmp - 1); tmp[sizeof tmp - 1] = 0;
                    if (tmp[1] == 'V' || tmp[1] == 'v') {
                        char *lp = strchr(tmp, '('), *rp = strchr(tmp, ')');
                        if (lp && rp) { *rp = 0; strncpy(lits[k].ext, lp + 1, 8); }
                        lits[k].isV = 1; lits[k].val = 0;
                        struct sym *s = sym_get(lits[k].ext); s->type = S_ER; esd_add(s);
                    } else if (tmp[1] == 'A' || tmp[1] == 'a') {
                        char *lp = strchr(tmp, '('), *rp = strrchr(tmp, ')');
                        if (lp && rp && rp > lp) { *rp = 0; strncpy(lits[k].ext, lp + 1, 8); }
                        lits[k].isA = 1;
                    } else if (tmp[1] == 'F' || tmp[1] == 'f') {
                        char *q = strchr(tmp, '\''); lits[k].val = q ? strtol(q + 1, NULL, 10) : 0;
                    }
                    lits[k].placed = 1;
                } else {
                    long v = lits[k].isA ? expr_val(lits[k].ext, NULL) : lits[k].val;
                    put(lits[k].loc, v, 4);
                    if (lits[k].isV) add_reloc(lits[k].loc, lits[k].ext, 1);
                    else if (lits[k].isA) { struct sym *es = sym_find(lits[k].ext);
                        if (es && (es->type == S_SD || es->type == S_PC || es->type == S_REL || es->type == S_ER)) add_reloc(lits[k].loc, lits[k].ext, 0); }
                    lits[k].placed = 1;
                }
                lc += 4;
            }
            ltidx++;
        } else if (pass == 1) note_unknown(op);
    }
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
static void cseq(unsigned char *c, int seq) { char b[16]; int i; sprintf(b, "%08d", seq); for (i = 0; i < 8; i++) c[72 + i] = a2e(b[i]); }
static void esd_ent(unsigned char *c, int slot, const char *name, int type, long addr, long sizeOrId, int blankSize) {
    cebc(c, slot, name, 8); c[slot + 8] = (unsigned char)type; cbe(c, slot + 9, addr, 3); c[slot + 12] = 0x40;
    if (blankSize) { c[slot + 13] = c[slot + 14] = c[slot + 15] = 0x40; } else cbe(c, slot + 13, sizeOrId, 3);
}

static void emit_obj(FILE *f) {
    unsigned char c[80]; int seq = 0, k;

    /* ESD: declaration order, 3 entries per card */
    { int e = 0; while (e < nesdord) {
        cinit(c); cname(c, "ESD");
        int n = 0, cardfirst = 0;
        while (n < 3 && e < nesdord) {
            struct sym *s = esdord[e++]; int slot = 16 + n * 16;
            if (s->type == S_PC || s->type == S_SD) { esd_ent(c, slot, s->name, s->type == S_PC ? 0x04 : 0x00, s->val, modlen, 0); if (!cardfirst) cardfirst = s->esdid; }
            else if (s->type == S_ER) { esd_ent(c, slot, s->name, 0x02, 0, 0, 1); if (!cardfirst) cardfirst = s->esdid; }
            else { esd_ent(c, slot, s->name, 0x01, s->val, main_sect_esdid, 0); }   /* LD entry */
            n++;
        }
        cbe(c, 10, n * 16, 2); cbe(c, 14, cardfirst, 2);
        cseq(c, ++seq); fwrite(c, 1, 80, f);
    } }

    { long off = 0; while (off < modlen) {
        if (!defn[off]) { off++; continue; }           /* skip alignment/DS gaps */
        long rstart = off; while (off < modlen && defn[off]) off++;
        while (rstart < off) {
            long len = off - rstart; if (len > 56) len = 56;
            cinit(c); cname(c, "TXT"); cbe(c, 5, rstart, 3); cbe(c, 10, len, 2); cbe(c, 14, main_sect_esdid, 2);
            { long i; for (i = 0; i < len; i++) c[16 + i] = text[rstart + i]; }
            cseq(c, ++seq); fwrite(c, 1, 80, f); rstart += len;
        }
    } }

    /* group relocations by (pos, rel) so same-target entries are adjacent (packing), like IFOX */
    { int a, b; for (a = 1; a < nrel; a++) { struct reloc t = rels[a]; b = a - 1;
        while (b >= 0 && (rels[b].pos > t.pos || (rels[b].pos == t.pos && rels[b].rel > t.rel))) { rels[b + 1] = rels[b]; b--; }
        rels[b + 1] = t; } }
    { k = 0; while (k < nrel) {
        cinit(c); cname(c, "RLD"); int off = 16;
        while (k < nrel) {
            int run = k + 1; while (run < nrel && rels[run].rel == rels[k].rel && rels[run].pos == rels[k].pos) run++;
            int gbytes = 8 + (run - k - 1) * 4;
            if (off > 16 && off + gbytes > 72) break;          /* group won't fit -> flush card */
            cbe(c, off, rels[k].rel, 2); cbe(c, off + 2, rels[k].pos, 2);
            c[off + 4] = (rels[k].isV ? 0x1C : 0x0C) | (run - k > 1 ? 0x01 : 0); cbe(c, off + 5, rels[k].addr, 3); off += 8;
            int m; for (m = k + 1; m < run; m++) {
                c[off] = (rels[m].isV ? 0x1C : 0x0C) | (m < run - 1 ? 0x01 : 0); cbe(c, off + 1, rels[m].addr, 3); off += 4;
            }
            k = run;
            if (off + 8 > 72) break;
        }
        cbe(c, 10, off - 16, 2); cseq(c, ++seq); fwrite(c, 1, 80, f);
    } }

    cinit(c); cname(c, "END"); if (end_has) { cbe(c, 5, end_addr, 3); cbe(c, 14, end_esdid, 2); }
    cseq(c, ++seq); fwrite(c, 1, 80, f);
}

int main(int argc, char **argv) {
    const char *src = NULL, *objfn = NULL; int ai, eonly = 0;
    for (ai = 1; ai < argc; ai++) {
        if (!strcmp(argv[ai], "-o") && ai + 1 < argc) objfn = argv[++ai];
        else if (!strcmp(argv[ai], "-I") && ai + 1 < argc) { if (nmaclib < 8) maclib_dirs[nmaclib++] = argv[++ai]; }
        else if (!strcmp(argv[ai], "-E")) eonly = 1;
        else src = argv[ai];
    }
    if (!src) { fprintf(stderr, "usage: as370 [-I maclib]... [-o obj] file.s\n"); return 2; }
    FILE *f = fopen(src, "r"); if (!f) { perror(src); return 2; }
    static char *raw[4096]; int n = 0; char lb[256];
    while (fgets(lb, sizeof lb, f) && n < 4096) raw[n++] = strdup(lb);
    fclose(f);

    static char *lines[MAXLINES];
    int nl = macro_pass(raw, n, lines);
    if (eonly) { int j; for (j = 0; j < nl; j++) { fputs(lines[j], stdout); if (lines[j][0] && lines[j][strlen(lines[j]) - 1] != '\n') putchar('\n'); } return 0; }

    do_pass(1, lines, nl);
    { int k, id = 0; for (k = 0; k < nesdord; k++)
        if (esdord[k]->type == S_SD || esdord[k]->type == S_PC || esdord[k]->type == S_ER) esdord[k]->esdid = ++id; }
    { int k; for (k = 0; k < nesdord; k++) if (esdord[k]->type == S_SD || esdord[k]->type == S_PC) { main_sect_esdid = esdord[k]->esdid; break; } }
    { int k; for (k = 0; k < nlit; k++) lits[k].placed = 0; }
    do_pass(2, lines, nl);
    if (nunk) { int j; fprintf(stderr, "as370: unknown op(s):"); for (j = 0; j < nunk; j++) fprintf(stderr, " %s", unkops[j]); fprintf(stderr, "\n"); }

    long i;
    printf("module length: 0x%lX (%ld bytes)\n", modlen, modlen);
    printf("TXT: "); for (i = 0; i < modlen; i++) printf("%02X", text[i]); printf("\n");
    if (objfn) {
        FILE *of = fopen(objfn, "wb"); if (!of) { perror(objfn); return 2; }
        emit_obj(of); fclose(of); printf("wrote object deck: %s\n", objfn);
    }
    return errors ? 1 : 0;
}
