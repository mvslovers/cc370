/* as370 - host-native MVS assembler for c2asm370 (WP-2/WP-3 skeleton).
 *
 * Reproduces IFOX00 object decks for the WP-1/WP-3 references:
 *   - tests/sample1.s : named CSECT (SD) + ER, single TXT card.
 *   - tests/sample3.s : unnamed CSECT (PC) + ENTRY (LD) + ER, multi-card TXT,
 *                       RLD bit-7 continuation packing.
 * Validation oracle = the IFOX00 PRINT GEN listing + object deck (cards 1..n-1
 * byte-identical; the END card matches except the optional IDR field).
 *
 * Scope: formats RR/RX, extended mnemonic BR; directives CSECT (named=SD /
 * unnamed=PC), ENTRY, USING, DROP, DC A/F, DS, EQU, LTORG, END; literals
 * =V/=A/=F; base+disp via USING. Full opcode-table lift, RS/SI/SS, EBCDIC DC C,
 * and the macro processor are the next steps.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define MAXSYM 256
#define MAXLIT 256
#define MAXREL 256
#define TEXTMAX 65536

enum fmt { F_NONE, F_RR, F_RX, F_BR /* pseudo: BCR 15,r2 */ };

struct opc { const char *name; int fmt; int op; };
static const struct opc optab[] = {
    { "BALR", F_RR, 0x05 }, { "BCR",  F_RR, 0x07 }, { "BR",   F_BR, 0x07 },
    { "LR",   F_RR, 0x18 }, { "LTR",  F_RR, 0x12 }, { "AR",   F_RR, 0x1A },
    { "L",    F_RX, 0x58 }, { "LA",   F_RX, 0x41 }, { "ST",   F_RX, 0x50 },
    { "A",    F_RX, 0x5A }, { "C",    F_RX, 0x59 },
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
static long lc, modlen;
static int  using_reg = -1;
static long using_base;
static int  cur_sect_esdid, main_sect_esdid;
static int  end_esdid; static long end_addr;
static int  errors;

static void err(int line, const char *m, const char *a) {
    fprintf(stderr, "as370: line %d: %s%s%s\n", line, m, a ? " " : "", a ? a : "");
    errors++;
}

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
    int i; for (i = n - 1; i >= 0; i--) { text[at + i] = (unsigned char)(v & 0xff); v >>= 8; }
    if (at + n > modlen) modlen = at + n;
}
static void split2(const char *s, char *a, char *b) {
    const char *c = strchr(s, ',');
    if (c) { size_t n = c - s; memcpy(a, s, n); a[n] = 0; strcpy(b, c + 1); }
    else   { strcpy(a, s); b[0] = 0; }
}
static long align4(long x) { return (x + 3) & ~3L; }

static int parse(char *line, char *lbl, char *op, char *opnd) {
    char *p = line, *t;
    lbl[0] = op[0] = opnd[0] = 0;
    if (line[0] == '*') return 0;
    if (line[0] != ' ' && line[0] != '\t' && line[0] != '\0' && line[0] != '\n') {
        t = strtok(p, " \t\n"); if (!t) return 0; strncpy(lbl, t, 8); lbl[8] = 0;
        t = strtok(NULL, " \t\n");
    } else t = strtok(p, " \t\n");
    if (!t) return 0; strncpy(op, t, 8); op[8] = 0;
    t = strtok(NULL, " \t\n"); if (t) { strncpy(opnd, t, 63); opnd[63] = 0; }
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

static void do_pass(int pass, char **lines, int nlines) {
    int i;
    lc = 0;
    if (pass == 2) { using_reg = -1; nrel = 0; }
    for (i = 0; i < nlines; i++) {
        char buf[256], lbl[16], op[16], opnd[64];
        strncpy(buf, lines[i], sizeof buf - 1); buf[sizeof buf - 1] = 0;
        if (!parse(buf, lbl, op, opnd)) continue;
        if (!op[0]) continue;

        const struct opc *o = op_find(op);
        if (o) {
            if (pass == 1) {
                if (lbl[0]) { struct sym *s = sym_get(lbl); s->val = lc; s->defined = 1; }
                if (opnd[0]) { char a[64], b[64]; split2(opnd, a, b); if (b[0] == '=') lit_get(b); }
                lc += (o->fmt == F_RR || o->fmt == F_BR) ? 2 : 4;
            } else {
                char a[64], b[64]; split2(opnd, a, b);
                if (o->fmt == F_RR) {
                    int r1 = (int)expr_val(a, NULL), r2 = (int)expr_val(b, NULL);
                    put(lc, (o->op << 8) | (r1 << 4) | r2, 2); lc += 2;
                } else if (o->fmt == F_BR) {
                    int r2 = (int)expr_val(a, NULL);
                    put(lc, (o->op << 8) | (15 << 4) | r2, 2); lc += 2;
                } else {
                    int r1 = (int)expr_val(a, NULL), x2 = 0, b2; long disp, tgt;
                    if (b[0] == '=') { struct lit *l = lit_get(b); tgt = l->loc; }
                    else            { struct sym *s = sym_find(b); tgt = s ? s->val : 0; }
                    if (using_reg < 0) err(i + 1, "no active USING for", b);
                    b2 = using_reg; disp = tgt - using_base;
                    put(lc, ((long)o->op << 24) | ((long)r1 << 20) | ((long)x2 << 16)
                            | ((long)b2 << 12) | (disp & 0xfff), 4);
                    lc += 4;
                }
            }
            continue;
        }

        if (!strcmp(op, "CSECT")) {
            lc = 0;
            if (pass == 1) {
                struct sym *s = lbl[0] ? sym_get(lbl) : sym_get("");
                s->type = lbl[0] ? S_SD : S_PC; s->val = 0; s->defined = 1;
            }
            if (pass == 2) { struct sym *s = sym_find(lbl[0] ? lbl : ""); if (s) cur_sect_esdid = s->esdid; }
        } else if (!strcmp(op, "ENTRY")) {
            if (pass == 1 && opnd[0]) { struct sym *s = sym_get(opnd); s->is_entry = 1; }
        } else if (!strcmp(op, "USING")) {
            char a[64], b[64]; split2(opnd, a, b);
            if (pass == 2) { using_reg = (int)expr_val(b, NULL); using_base = (a[0] == '*') ? lc : expr_val(a, NULL); }
        } else if (!strcmp(op, "DROP")) {
            if (pass == 2) using_reg = -1;
        } else if (!strcmp(op, "DS") || !strcmp(op, "DC")) {
            const char *p = opnd; int cnt = 0, hascnt = 0;
            while (isdigit((unsigned char)*p)) { cnt = cnt * 10 + (*p - '0'); hascnt = 1; p++; }
            if (!hascnt) cnt = 1;
            int ty = *p ? *p++ : 0;
            if (ty == 'F' || ty == 'f' || ty == 'A' || ty == 'a') {
                lc = align4(lc);
                if (pass == 1 && lbl[0]) { struct sym *s = sym_get(lbl); s->val = lc; s->defined = 1; }
                long val = 0; char ename[64] = "";
                if (ty == 'A' || ty == 'a') { const char *lp = strchr(p, '('), *rp = strchr(p, ')');
                    if (lp && rp) { size_t n = rp - lp - 1; memcpy(ename, lp + 1, n); ename[n] = 0; } }
                else { const char *q = strchr(p, '\''); if (q) val = strtol(q + 1, NULL, 10); }
                int k;
                for (k = 0; k < cnt; k++) {
                    if (pass == 2 && !strcmp(op, "DC")) {
                        if (ty == 'A' || ty == 'a') { put(lc, expr_val(ename, NULL), 4); add_reloc(lc, ename, 0); }
                        else put(lc, val, 4);
                    }
                    lc += 4;
                }
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

/* emit a 16-byte ESD symbol entry into card slot */
static void esd_ent(unsigned char *c, int slot, const char *name, int type, long addr, long sizeOrId, int blankSize) {
    cebc(c, slot, name, 8); c[slot + 8] = (unsigned char)type; cbe(c, slot + 9, addr, 3); c[slot + 12] = 0x40;
    if (blankSize) { c[slot + 13] = c[slot + 14] = c[slot + 15] = 0x40; } else cbe(c, slot + 13, sizeOrId, 3);
}

static void emit_obj(FILE *f) {
    unsigned char c[80]; int seq = 0, k, slot, first = 0, nesd = 0;
    for (k = 0; k < nsym; k++) if (syms[k].esdid) { nesd++; if (!first) first = syms[k].esdid; }
    nesd += 0; /* LDs counted below */
    int nld = 0; for (k = 0; k < nsym; k++) if (syms[k].is_entry) nld++;
    int total = nesd + nld;

    /* ESD: sections (PC/SD) -> LD entries -> ERs, matching IFOX order */
    cinit(c); cname(c, "ESD"); cbe(c, 10, total * 16, 2); cbe(c, 14, first, 2); slot = 16;
    for (k = 0; k < nsym; k++) if (syms[k].type == S_PC || syms[k].type == S_SD) {
        esd_ent(c, slot, syms[k].name, syms[k].type == S_PC ? 0x04 : 0x00, syms[k].val, modlen, 0); slot += 16;
    }
    for (k = 0; k < nsym; k++) if (syms[k].is_entry) {
        esd_ent(c, slot, syms[k].name, 0x01, syms[k].val, main_sect_esdid, 0); slot += 16;
    }
    for (k = 0; k < nsym; k++) if (syms[k].type == S_ER) {
        esd_ent(c, slot, syms[k].name, 0x02, 0, 0, 1); slot += 16;
    }
    cseq(c, ++seq); fwrite(c, 1, 80, f);

    /* TXT: 56-byte chunks */
    { long off = 0; while (off < modlen) {
        long len = modlen - off; if (len > 56) len = 56;
        cinit(c); cname(c, "TXT"); cbe(c, 5, off, 3); cbe(c, 10, len, 2); cbe(c, 14, main_sect_esdid, 2);
        { long i; for (i = 0; i < len; i++) c[16 + i] = text[off + i]; }
        cseq(c, ++seq); fwrite(c, 1, 80, f); off += len;
    } }

    /* RLD with bit-7 continuation packing (consecutive same Reloc+Pos) */
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

    /* END: Type-1 (entry addr + ESDID); IDR left blank */
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
    static char *lines[4096]; int n = 0; char lb[256];
    while (fgets(lb, sizeof lb, f) && n < 4096) lines[n++] = strdup(lb);
    fclose(f);

    do_pass(1, lines, n);
    { int k, id = 0; for (k = 0; k < nsym; k++)
        if (syms[k].type == S_SD || syms[k].type == S_PC || syms[k].type == S_ER) syms[k].esdid = ++id; }
    { int k; for (k = 0; k < nsym; k++) if (syms[k].type == S_SD || syms[k].type == S_PC) { main_sect_esdid = syms[k].esdid; break; } }
    { int k; for (k = 0; k < nlit; k++) lits[k].placed = 0; }
    do_pass(2, lines, n);

    long i;
    printf("module length: 0x%lX (%ld bytes)\n", modlen, modlen);
    printf("TXT: "); for (i = 0; i < modlen; i++) printf("%02X", text[i]); printf("\n");
    { int k; for (k = 0; k < nsym; k++) printf("  %-8s = 0x%04lX  type=%d esdid=%d%s\n",
        syms[k].name[0] ? syms[k].name : "(PC)", syms[k].val, syms[k].type, syms[k].esdid, syms[k].is_entry ? " ENTRY" : ""); }
    { int k; for (k = 0; k < nrel; k++) printf("  RLD %s @0x%04lX rel=%d pos=%d\n", rels[k].isV ? "V" : "A", rels[k].addr, rels[k].rel, rels[k].pos); }

    if (objfn) {
        FILE *of = fopen(objfn, "wb"); if (!of) { perror(objfn); return 2; }
        emit_obj(of); fclose(of); printf("wrote object deck: %s\n", objfn);
    }
    return errors ? 1 : 0;
}
