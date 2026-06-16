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

struct opc { const char *name; int fmt; int op; };
static const struct opc optab[] = {
    { "BALR", F_RR, 0x05 }, { "BCR",  F_RR, 0x07 }, { "BR",   F_BR, 0x07 },
    { "LR",   F_RR, 0x18 }, { "LTR",  F_RR, 0x12 }, { "AR",   F_RR, 0x1A },
    { "L",    F_RX, 0x58 }, { "LA",   F_RX, 0x41 }, { "ST",   F_RX, 0x50 },
    { "A",    F_RX, 0x5A }, { "C",    F_RX, 0x59 },
    { "STM",  F_RS, 0x90 }, { "LM",   F_RS, 0x98 },
    { "MVI",  F_SI, 0x92 }, { "CLI",  F_SI, 0x95 },
    { "MVC",  F_SS, 0xD2 },
    { "B",    F_BC, 0x47 },
    { NULL, 0, 0 }
};

enum stype { S_REL, S_SD, S_PC, S_ER, S_LD, S_ABS };
struct sym { char name[9]; long val; int type; int defined; int esdid; int is_entry; };
static struct sym syms[MAXSYM];
static int nsym;

struct lit { char text[32]; long loc; long val; int placed; int isV; char ext[9]; };
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
static int  end_esdid; static long end_addr;
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
/* evaluate an AIF condition (single comparison, arithmetic or character) */
static int eval_cond(struct ctx *c, const char *cond) {
    char toks[12][96]; int nt = 0; const char *p = cond;
    while (*p) {
        while (*p == ' ') p++; if (!*p) break;
        char *o = toks[nt]; int q = 0, d = 0, oi = 0;
        while (*p && (q || d || *p != ' ')) { if (*p == '\'') q = !q; else if (*p == '(') d++; else if (*p == ')') d--; if (oi < 95) o[oi++] = *p; p++; }
        o[oi] = 0; if (nt < 11) nt++;
    }
    if (nt >= 3) {
        const char *L = toks[0], *rel = toks[1], *R = toks[2]; int cmp;
        if (L[0] == '\'' || R[0] == '\'') {
            char ls[128], rs[128]; eval_setc(c, L, ls); eval_setc(c, R, rs); cmp = strcmp(ls, rs);
        } else { long lv = eval_seta(c, L), rv = eval_seta(c, R); cmp = (lv < rv) ? -1 : (lv > rv) ? 1 : 0; }
        if (!strcmp(rel, "EQ")) return cmp == 0; if (!strcmp(rel, "NE")) return cmp != 0;
        if (!strcmp(rel, "GT")) return cmp > 0;  if (!strcmp(rel, "LT")) return cmp < 0;
        if (!strcmp(rel, "GE")) return cmp >= 0; if (!strcmp(rel, "LE")) return cmp <= 0;
    }
    return 0;
}
/* split "(cond)seqsym" -> cond (no outer parens), seqsym */
static void aif_split(const char *opnd, char *cond, char *seq) {
    cond[0] = seq[0] = 0; const char *p = opnd; if (*p != '(') return;
    int d = 0; const char *cs = p + 1;
    for (; *p; p++) { if (*p == '(') { d++; if (d == 1) cs = p + 1; }
        else if (*p == ')') { if (--d == 0) { int L = (int)(p - cs); memcpy(cond, cs, L); cond[L] = 0; strcpy(seq, p + 1); return; } } }
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
    struct macro *m = (op[0] && depth <= 40) ? mac_find(op) : NULL;
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
        if (!strcmp(op, "MACRO")) {
            if (++i >= nin) break;
            char pb[256], pl[16], po[16], pp[128];
            strncpy(pb, in[i], 255); pb[255] = 0; parse(pb, pl, po, pp);
            struct macro *m = &macros[nmac++]; memset(m, 0, sizeof *m);
            strncpy(m->namep, pl, sizeof m->namep - 1); strncpy(m->name, po, sizeof m->name - 1);
            if (pp[0]) { char flds[24][64]; int nf = split_fields(pp, flds, 24), k;
                for (k = 0; k < nf && k < 24; k++) { char *eq = strchr(flds[k], '=');
                    if (eq) { *eq = 0; strncpy(m->pname[k], flds[k], 19); strncpy(m->pdef[k], eq + 1, 39); m->pkey[k] = 1; }
                    else strncpy(m->pname[k], flds[k], 19);
                    m->nparm++; } }
            while (++i < nin) { char bb[256], bl[16], bo[16], bd[128];
                strncpy(bb, in[i], 255); bb[255] = 0; parse(bb, bl, bo, bd);
                if (!strcmp(bo, "MEND")) break;
                if (m->nbody < 256) m->body[m->nbody++] = strdup(in[i]); }
            continue;
        }
        mexp_line(in[i], out, &nout, 0);
    }
    return nout;
}

static void do_pass(int pass, char **lines, int nlines) {
    int i;
    lc = 0;
    if (pass == 2) { using_reg = -1; nrel = 0; }
    for (i = 0; i < nlines; i++) {
        char buf[256], lbl[16], op[16], opnd[128];
        strncpy(buf, lines[i], sizeof buf - 1); buf[sizeof buf - 1] = 0;
        if (!parse(buf, lbl, op, opnd)) continue;
        if (!op[0]) continue;

        const struct opc *o = op_find(op);
        if (o) {
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
                    put(lc, (o->op << 8) | (15 << 4) | (int)expr_val(F[0], 0), 2); lc += 2; break;
                case F_RX: case F_BC: {
                    int r1 = (o->fmt == F_BC) ? 15 : (int)expr_val(F[0], 0);
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
                s->type = lbl[0] ? S_SD : S_PC; s->val = 0; s->defined = 1; }
            if (pass == 2) { struct sym *s = sym_find(lbl[0] ? lbl : ""); if (s) cur_sect_esdid = s->esdid; }
        } else if (!strcmp(op, "ENTRY")) {
            if (pass == 1 && opnd[0]) { struct sym *s = sym_get(opnd); s->is_entry = 1; }
        } else if (!strcmp(op, "USING")) {
            char F[4][64]; split_fields(opnd, F, 4);
            if (pass == 2) { using_reg = (int)expr_val(F[1], 0); using_base = (F[0][0] == '*') ? lc : expr_val(F[0], 0); }
        } else if (!strcmp(op, "DROP")) {
            if (pass == 2) using_reg = -1;
        } else if (!strcmp(op, "DS") || !strcmp(op, "DC")) {
            const char *p = opnd; int cnt = 0, hascnt = 0;
            while (isdigit((unsigned char)*p)) { cnt = cnt * 10 + (*p - '0'); hascnt = 1; p++; }
            if (!hascnt) cnt = 1;
            int ty = *p ? *p++ : 0, k;
            if (ty == 'F' || ty == 'f' || ty == 'A' || ty == 'a') {
                lc = align4(lc);
                if (pass == 1 && lbl[0]) { struct sym *s = sym_get(lbl); s->val = lc; s->defined = 1; }
                long val = 0; char ename[64] = "";
                if (ty == 'A' || ty == 'a') { const char *lp = strchr(p, '('), *rp = strchr(p, ')');
                    if (lp && rp) { size_t n = rp - lp - 1; memcpy(ename, lp + 1, n); ename[n] = 0; } }
                else { const char *q = strchr(p, '\''); if (q) val = strtol(q + 1, NULL, 10); }
                for (k = 0; k < cnt; k++) {
                    if (pass == 2 && !strcmp(op, "DC")) {
                        if (ty == 'A' || ty == 'a') { put(lc, expr_val(ename, NULL), 4); add_reloc(lc, ename, 0); }
                        else put(lc, val, 4);
                    }
                    lc += 4;
                }
            } else if (ty == 'C' || ty == 'c') {       /* byte-aligned EBCDIC characters */
                if (pass == 1 && lbl[0]) { struct sym *s = sym_get(lbl); s->val = lc; s->defined = 1; }
                const char *q = strchr(p, '\''); char body[128] = "";
                if (q) { const char *e = q + 1; int bn = 0; while (*e && *e != '\'' && bn < 127) body[bn++] = *e++; body[bn] = 0; }
                for (k = 0; k < cnt; k++) { const char *e = body; while (*e) { if (pass == 2 && !strcmp(op, "DC")) put(lc, a2e((unsigned char)*e), 1); lc++; e++; } }
            } else if (pass == 1 && lbl[0]) { struct sym *s = sym_get(lbl); s->val = lc; s->defined = 1; }
        } else if (!strcmp(op, "EQU")) {
            if (pass == 1 && lbl[0]) { struct sym *s = sym_get(lbl); s->val = (opnd[0] == '*') ? lc : expr_val(opnd, NULL); s->defined = 1; }
        } else if (!strcmp(op, "LTORG") || !strcmp(op, "END")) {
            int k;
            if (pass == 2 && !strcmp(op, "END") && opnd[0]) {
                struct sym *s = sym_find(opnd);
                if (s) { end_addr = s->val; end_esdid = s->esdid ? s->esdid : main_sect_esdid; }
            }
            for (k = 0; k < nlit; k++) {
                if (lits[k].placed) continue;
                lc = align4(lc);
                if (pass == 1) {
                    lits[k].loc = lc;
                    if (lits[k].text[1] == 'V' || lits[k].text[1] == 'v') {
                        char tmp[32]; strncpy(tmp, lits[k].text, sizeof tmp - 1); tmp[sizeof tmp - 1] = 0;
                        char *lp = strchr(tmp, '('), *rp = strchr(tmp, ')');
                        if (lp && rp) { *rp = 0; strncpy(lits[k].ext, lp + 1, 8); }
                        lits[k].isV = 1; lits[k].val = 0;
                        struct sym *s = sym_get(lits[k].ext); s->type = S_ER;
                    } else if (lits[k].text[1] == 'A' || lits[k].text[1] == 'a') {
                        char e[64]; char *lp = strchr(lits[k].text, '('), *rp = strchr(lits[k].text, ')');
                        if (lp && rp) { size_t n = rp - lp - 1; memcpy(e, lp + 1, n); e[n] = 0; lits[k].val = expr_val(e, NULL); }
                    } else if (lits[k].text[1] == 'F' || lits[k].text[1] == 'f') {
                        char *q = strchr(lits[k].text, '\''); lits[k].val = q ? strtol(q + 1, NULL, 10) : 0;
                    }
                } else {
                    put(lits[k].loc, lits[k].val, 4);
                    if (lits[k].isV) add_reloc(lits[k].loc, lits[k].ext, 1);
                    lits[k].placed = 1;
                }
                lc += 4;
            }
            if (pass == 1) { for (k = 0; k < nlit; k++) lits[k].placed = 1; }
        }
    }
}

/* ---- OS/360 OBJ writer ---------------------------------------------------- */
static unsigned char a2e(int c) {
    if (c >= 'A' && c <= 'I') return 0xC1 + (c - 'A');
    if (c >= 'J' && c <= 'R') return 0xD1 + (c - 'J');
    if (c >= 'S' && c <= 'Z') return 0xE2 + (c - 'S');
    if (c >= 'a' && c <= 'i') return 0x81 + (c - 'a');
    if (c >= 'j' && c <= 'r') return 0x91 + (c - 'j');
    if (c >= 's' && c <= 'z') return 0xA2 + (c - 's');
    if (c >= '0' && c <= '9') return 0xF0 + (c - '0');
    switch (c) { case ' ': return 0x40; case '@': return 0x7C; case '#': return 0x7B;
                 case '$': return 0x5B; case '_': return 0x6D; }
    return 0x40;
}
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
    unsigned char c[80]; int seq = 0, k, slot, first = 0, nesd = 0, nld = 0;
    for (k = 0; k < nsym; k++) if (syms[k].esdid) { nesd++; if (!first) first = syms[k].esdid; }
    for (k = 0; k < nsym; k++) if (syms[k].is_entry) nld++;

    cinit(c); cname(c, "ESD"); cbe(c, 10, (nesd + nld) * 16, 2); cbe(c, 14, first, 2); slot = 16;
    for (k = 0; k < nsym; k++) if (syms[k].type == S_PC || syms[k].type == S_SD)
        { esd_ent(c, slot, syms[k].name, syms[k].type == S_PC ? 0x04 : 0x00, syms[k].val, modlen, 0); slot += 16; }
    for (k = 0; k < nsym; k++) if (syms[k].is_entry)
        { esd_ent(c, slot, syms[k].name, 0x01, syms[k].val, main_sect_esdid, 0); slot += 16; }
    for (k = 0; k < nsym; k++) if (syms[k].type == S_ER)
        { esd_ent(c, slot, syms[k].name, 0x02, 0, 0, 1); slot += 16; }
    cseq(c, ++seq); fwrite(c, 1, 80, f);

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

    if (nrel > 0) {
        cinit(c); cname(c, "RLD");
        { int off = 16; k = 0; while (k < nrel) {
            int run = k + 1; while (run < nrel && rels[run].rel == rels[k].rel && rels[run].pos == rels[k].pos) run++;
            cbe(c, off, rels[k].rel, 2); cbe(c, off + 2, rels[k].pos, 2);
            c[off + 4] = (rels[k].isV ? 0x1C : 0x0C) | (run - k > 1 ? 0x01 : 0); cbe(c, off + 5, rels[k].addr, 3); off += 8;
            int m; for (m = k + 1; m < run; m++) {
                c[off] = (rels[m].isV ? 0x1C : 0x0C) | (m < run - 1 ? 0x01 : 0); cbe(c, off + 1, rels[m].addr, 3); off += 4;
            }
            k = run;
        } cbe(c, 10, off - 16, 2); }
        cseq(c, ++seq); fwrite(c, 1, 80, f);
    }

    cinit(c); cname(c, "END"); cbe(c, 5, end_addr, 3); cbe(c, 14, end_esdid, 2);
    cseq(c, ++seq); fwrite(c, 1, 80, f);
}

int main(int argc, char **argv) {
    const char *src = NULL, *objfn = NULL; int ai;
    for (ai = 1; ai < argc; ai++) {
        if (!strcmp(argv[ai], "-o") && ai + 1 < argc) objfn = argv[++ai]; else src = argv[ai];
    }
    if (!src) { fprintf(stderr, "usage: as370 [-o obj] file.s\n"); return 2; }
    FILE *f = fopen(src, "r"); if (!f) { perror(src); return 2; }
    static char *raw[4096]; int n = 0; char lb[256];
    while (fgets(lb, sizeof lb, f) && n < 4096) raw[n++] = strdup(lb);
    fclose(f);

    static char *lines[MAXLINES];
    int nl = macro_pass(raw, n, lines);

    do_pass(1, lines, nl);
    { int k, id = 0; for (k = 0; k < nsym; k++)
        if (syms[k].type == S_SD || syms[k].type == S_PC || syms[k].type == S_ER) syms[k].esdid = ++id; }
    { int k; for (k = 0; k < nsym; k++) if (syms[k].type == S_SD || syms[k].type == S_PC) { main_sect_esdid = syms[k].esdid; break; } }
    { int k; for (k = 0; k < nlit; k++) lits[k].placed = 0; }
    do_pass(2, lines, nl);

    long i;
    printf("module length: 0x%lX (%ld bytes)\n", modlen, modlen);
    printf("TXT: "); for (i = 0; i < modlen; i++) printf("%02X", text[i]); printf("\n");
    if (objfn) {
        FILE *of = fopen(objfn, "wb"); if (!of) { perror(objfn); return 2; }
        emit_obj(of); fclose(of); printf("wrote object deck: %s\n", objfn);
    }
    return errors ? 1 : 0;
}
