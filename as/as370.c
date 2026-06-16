/* as370 - host-native MVS assembler for c2asm370 (WP-2 skeleton).
 *
 * Goal of this first cut: a two-pass core that assembles the WP-1 macro-free
 * mini-CSECT (as/tests/sample1.s) and reproduces IFOX00's TXT bytes:
 *
 *     05C0 58F0 C00E 4110 C00A 07FE 00000000 00000000
 *
 * Scope here is deliberately small (the instructions/directives sample1 needs):
 *   formats RR, RX; directives CSECT, USING, DROP, DC A, LTORG, EQU, DS, END;
 *   literals =V/=A/=F; base+displacement resolution via USING.
 * The OS/360 OBJ writer (ESD/TXT/RLD/END cards) is WP-3; here we just emit the
 * TXT image plus a per-statement listing for validation against IFOX.
 *
 * No EBCDIC yet (sample1 has no character data); CP037+NEL tables come with DC C.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define MAXSYM 256
#define MAXLIT 256
#define TEXTMAX 65536

enum fmt { F_NONE, F_RR, F_RX, F_BR /* pseudo: BCR 15,r2 */ };

struct opc { const char *name; int fmt; int op; };
static const struct opc optab[] = {
    { "BALR", F_RR, 0x05 },
    { "BCR",  F_RR, 0x07 },   /* operands m1,r2 */
    { "BR",   F_BR, 0x07 },   /* pseudo: BCR 15,r2 */
    { "L",    F_RX, 0x58 },
    { "LA",   F_RX, 0x41 },
    { "ST",   F_RX, 0x50 },
    { "A",    F_RX, 0x5A },
    { NULL, 0, 0 }
};

enum stype { S_REL, S_SD, S_ER, S_ABS };
struct sym { char name[9]; long val; int type; int defined; };
static struct sym syms[MAXSYM];
static int nsym;

struct lit { char text[32]; long loc; long val; int placed; int isV; char ext[9]; };
static struct lit lits[MAXLIT];
static int nlit;

static unsigned char text[TEXTMAX];
static long lc;          /* location counter */
static long modlen;      /* high-water mark */
static int  using_reg = -1;
static long using_base;
static int  errors;

static void err(int line, const char *m, const char *a) {
    fprintf(stderr, "as370: line %d: %s%s%s\n", line, m, a ? " " : "", a ? a : "");
    errors++;
}

static struct sym *sym_find(const char *n) {
    int i;
    for (i = 0; i < nsym; i++) if (!strcmp(syms[i].name, n)) return &syms[i];
    return NULL;
}
static struct sym *sym_get(const char *n) {
    struct sym *s = sym_find(n);
    if (s) return s;
    if (nsym >= MAXSYM) { fprintf(stderr, "as370: symbol table full\n"); exit(2); }
    s = &syms[nsym++];
    memset(s, 0, sizeof *s);
    strncpy(s->name, n, 8);
    s->type = S_REL;
    return s;
}

static struct lit *lit_get(const char *t) {
    int i;
    for (i = 0; i < nlit; i++) if (!strcmp(lits[i].text, t)) return &lits[i];
    if (nlit >= MAXLIT) { fprintf(stderr, "as370: literal table full\n"); exit(2); }
    memset(&lits[nlit], 0, sizeof lits[0]);
    strncpy(lits[nlit].text, t, sizeof lits[0].text - 1);
    return &lits[nlit++];
}

/* resolve an expression operand to a value; *reloc set if relocatable label */
static long expr_val(const char *e, int *reloc) {
    if (reloc) *reloc = 0;
    if (*e == '*') return lc;
    if (isdigit((unsigned char)*e) || *e == '-') return strtol(e, NULL, 10);
    struct sym *s = sym_find(e);
    if (s) { if (reloc && s->type == S_REL) *reloc = 1; return s->val; }
    return 0;
}

/* emit n bytes of value v (big-endian) at location at, advancing nothing */
static void put(long at, long v, int n) {
    int i;
    for (i = n - 1; i >= 0; i--) { text[at + i] = (unsigned char)(v & 0xff); v >>= 8; }
    if (at + n > modlen) modlen = at + n;
}

/* split "field" by first comma into a,b (b may be empty) */
static void split2(const char *s, char *a, char *b) {
    const char *c = strchr(s, ',');
    if (c) { size_t n = c - s; memcpy(a, s, n); a[n] = 0; strcpy(b, c + 1); }
    else   { strcpy(a, s); b[0] = 0; }
}

static long align4(long x) { return (x + 3) & ~3L; }

/* parse one source line into label/op/operand (blank-delimited, * = comment) */
static int parse(char *line, char *lbl, char *op, char *opnd) {
    char *p = line, *t;
    lbl[0] = op[0] = opnd[0] = 0;
    if (line[0] == '*') return 0;
    if (line[0] != ' ' && line[0] != '\t' && line[0] != '\0' && line[0] != '\n') {
        t = strtok(p, " \t\n"); if (!t) return 0; strncpy(lbl, t, 8); lbl[8] = 0;
        t = strtok(NULL, " \t\n");
    } else {
        t = strtok(p, " \t\n");
    }
    if (!t) return 0; strncpy(op, t, 8); op[8] = 0;
    t = strtok(NULL, " \t\n");
    if (t) { strncpy(opnd, t, 63); opnd[63] = 0; }
    return 1;
}

static const struct opc *op_find(const char *n) {
    int i;
    for (i = 0; optab[i].name; i++) if (!strcmp(optab[i].name, n)) return &optab[i];
    return NULL;
}

/* pass: 1 = define symbols/literals + assign locations; 2 = encode */
static void do_pass(int pass, char **lines, int nlines) {
    int i;
    lc = 0;
    if (pass == 2) { using_reg = -1; }
    for (i = 0; i < nlines; i++) {
        char buf[256], lbl[16], op[16], opnd[64];
        strncpy(buf, lines[i], sizeof buf - 1); buf[sizeof buf - 1] = 0;
        if (!parse(buf, lbl, op, opnd)) continue;
        if (!op[0]) continue;

        const struct opc *o = op_find(op);
        if (o) {
            long start = lc;
            if (pass == 1) {
                if (lbl[0]) sym_get(lbl)->val = lc, sym_get(lbl)->defined = 1;
                /* note literal use */
                if (opnd[0]) {
                    char a[64], b[64]; split2(opnd, a, b);
                    if (b[0] == '=') { lit_get(b); }
                }
                lc += (o->fmt == F_RR || o->fmt == F_BR) ? 2 : 4;
            } else {
                char a[64], b[64]; split2(opnd, a, b);
                if (o->fmt == F_RR) {
                    int r1 = (int)expr_val(a, NULL), r2 = (int)expr_val(b, NULL);
                    put(lc, (o->op << 8) | (r1 << 4) | r2, 2); lc += 2;
                } else if (o->fmt == F_BR) {
                    int r2 = (int)expr_val(a, NULL);
                    put(lc, (o->op << 8) | (15 << 4) | r2, 2); lc += 2;
                } else { /* F_RX: r1, mem  (mem = symbol or =literal) */
                    int r1 = (int)expr_val(a, NULL), x2 = 0, b2 = 0; long disp = 0, tgt;
                    if (b[0] == '=') { struct lit *l = lit_get(b); tgt = l->loc; }
                    else            { struct sym *s = sym_find(b); tgt = s ? s->val : 0; }
                    if (using_reg < 0) err(i + 1, "no active USING for", b);
                    b2 = using_reg; disp = tgt - using_base;
                    put(lc, ((long)o->op << 24) | ((long)r1 << 20) | ((long)x2 << 16)
                            | ((long)b2 << 12) | (disp & 0xfff), 4);
                    lc += 4;
                }
            }
            (void)start;
            continue;
        }

        /* directives */
        if (!strcmp(op, "CSECT")) {
            lc = 0;
            if (pass == 1 && lbl[0]) { struct sym *s = sym_get(lbl); s->val = 0; s->type = S_SD; s->defined = 1; }
        } else if (!strcmp(op, "USING")) {
            char a[64], b[64]; split2(opnd, a, b);
            if (pass == 2) { using_reg = (int)expr_val(b, NULL); using_base = (a[0] == '*') ? lc : expr_val(a, NULL); }
        } else if (!strcmp(op, "DROP")) {
            if (pass == 2) using_reg = -1;
        } else if (!strcmp(op, "DS") || !strcmp(op, "DC")) {
            /* minimal: A(expr) and 0F alignment */
            if (opnd[0] == '0' && (opnd[1] == 'F' || opnd[1] == 'f')) { lc = align4(lc); }
            else if ((opnd[0] == 'A' || opnd[0] == 'a') && opnd[1] == '(') {
                lc = align4(lc);
                if (pass == 1) { if (lbl[0]) { struct sym *s = sym_get(lbl); s->val = lc; s->defined = 1; } }
                if (pass == 2 && !strcmp(op, "DC")) {
                    char e[64]; strncpy(e, opnd + 2, sizeof e - 1); e[sizeof e - 1] = 0;
                    char *rp = strchr(e, ')'); if (rp) *rp = 0;
                    put(lc, expr_val(e, NULL), 4);
                }
                lc += 4;
            } else {
                if (pass == 1 && lbl[0]) { struct sym *s = sym_get(lbl); s->val = lc; s->defined = 1; }
            }
        } else if (!strcmp(op, "EQU")) {
            if (pass == 1 && lbl[0]) { struct sym *s = sym_get(lbl); s->val = (opnd[0] == '*') ? lc : expr_val(opnd, NULL); s->defined = 1; }
        } else if (!strcmp(op, "LTORG") || !strcmp(op, "END")) {
            /* place pending literals (fullword) */
            int k;
            for (k = 0; k < nlit; k++) {
                if (lits[k].placed) continue;
                lc = align4(lc);
                if (pass == 1) {
                    lits[k].loc = lc;
                    if (lits[k].text[1] == 'V' || lits[k].text[1] == 'v') {
                        char tmp[32]; strncpy(tmp, lits[k].text, sizeof tmp - 1); tmp[sizeof tmp - 1] = 0;
                        char *lp = strchr(tmp, '('); char *rp = strchr(tmp, ')');
                        if (lp && rp) { *rp = 0; strncpy(lits[k].ext, lp + 1, 8); }
                        lits[k].isV = 1; lits[k].val = 0;
                        struct sym *s = sym_get(lits[k].ext); s->type = S_ER;
                    } else if (lits[k].text[1] == 'A' || lits[k].text[1] == 'a') {
                        char e[64]; char *lp = strchr(lits[k].text, '('); char *rp = strchr(lits[k].text, ')');
                        if (lp && rp) { size_t n = rp - lp - 1; memcpy(e, lp + 1, n); e[n] = 0; lits[k].val = expr_val(e, NULL); }
                    } else if (lits[k].text[1] == 'F' || lits[k].text[1] == 'f') {
                        char *q = strchr(lits[k].text, '\''); lits[k].val = q ? strtol(q + 1, NULL, 10) : 0;
                    }
                } else { /* pass 2: emit literal bytes */
                    put(lits[k].loc, lits[k].val, 4);
                }
                lc += 4;
                if (pass == 2) lits[k].placed = 1;  /* avoid re-emit across LTORG+END */
            }
            if (pass == 1) { for (k = 0; k < nlit; k++) lits[k].placed = 1; }
        }
    }
}

int main(int argc, char **argv) {
    if (argc < 2) { fprintf(stderr, "usage: as370 file.s\n"); return 2; }
    FILE *f = fopen(argv[1], "r");
    if (!f) { perror(argv[1]); return 2; }
    static char *lines[4096]; int n = 0; char lb[256];
    while (fgets(lb, sizeof lb, f) && n < 4096) lines[n++] = strdup(lb);
    fclose(f);

    do_pass(1, lines, n);
    /* reset literal placement flags for pass 2 emission */
    { int k; for (k = 0; k < nlit; k++) lits[k].placed = 0; }
    do_pass(2, lines, n);

    /* TXT image */
    long i;
    printf("module length: 0x%lX (%ld bytes)\n", modlen, modlen);
    printf("TXT: ");
    for (i = 0; i < modlen; i++) printf("%02X", text[i]);
    printf("\n");
    printf("symbols:\n");
    { int k; for (k = 0; k < nsym; k++)
        printf("  %-8s = 0x%04lX  %s\n", syms[k].name, syms[k].val,
               syms[k].type == S_SD ? "SD" : syms[k].type == S_ER ? "ER" : "REL"); }
    { int k; for (k = 0; k < nlit; k++)
        printf("  lit %-12s @ 0x%04lX\n", lits[k].text, lits[k].loc); }
    return errors ? 1 : 0;
}
