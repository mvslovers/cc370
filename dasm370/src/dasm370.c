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

static unsigned char img[MAXSECT_BYTES];      /* the section's text */
static unsigned char cov[MAXSECT_BYTES];      /* 1 = a TXT card covered it */
static unsigned char lab[MAXSECT_BYTES];      /* 1 = something names this offset */
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
 * recovered rather than manufactured. */
static void label_name(long a, char *out)
{
    int i;
    for (i = 0; i < nld; i++)
        if (ld[i].addr == a) { strcpy(out, ld[i].name); return; }
    sprintf(out, "L%06lX", (unsigned long)a);
}

/* ------------------------------------------------------------- decoding -- */

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

static void fmt_d(char *out, int d, int b) { sprintf(out, "%d(%d)", d, b); }

/* Operand text for one instruction.  Returns 0 when the shape is one this pass
 * does not write, which sends the bytes to DC rather than to a guess. */
static int operands(const struct opc *o, const unsigned char *b, char *out, size_t n)
{
    int r1 = (b[1] >> 4) & 0xf, r2 = b[1] & 0xf;
    int x2, b2, d2, b1, d1, l1, l2;
    char t1[32], t2[32];
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
        snprintf(out, n, "%d,%d(%d,%d)", r1, d2, x2, b2);
        return 1;
    case F_BC:
        x2 = r2; b2 = (b[2] >> 4) & 0xf; d2 = ((b[2] & 0xf) << 8) | b[3];
        snprintf(out, n, "%d(%d,%d)", d2, x2, b2);
        return 1;
    case F_RS:
        b2 = (b[2] >> 4) & 0xf; d2 = ((b[2] & 0xf) << 8) | b[3];
        /* R3 == 0 is the shift shape, `R1,D2(B2)'.  Writing the three-operand
         * form there would depend on as370 accepting an explicit zero where the
         * language expects two operands; the two-operand form is what the source
         * was and re-encodes to the same nibble either way. */
        if (r2 == 0) snprintf(out, n, "%d,%d(%d)", r1, d2, b2);
        else         snprintf(out, n, "%d,%d,%d(%d)", r1, r2, d2, b2);
        return 1;
    case F_SI:
        b1 = (b[2] >> 4) & 0xf; d1 = ((b[2] & 0xf) << 8) | b[3];
        snprintf(out, n, "%d(%d),%d", d1, b1, b[1]);
        return 1;
    case F_S:
        b2 = (b[2] >> 4) & 0xf; d2 = ((b[2] & 0xf) << 8) | b[3];
        fmt_d(t1, d2, b2);
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
            snprintf(out, n, "%d(%d,%d),%d(%d),%d", d1, l1, b1, d2, b2, b[1] & 0xf);
        } else if (opc_ss_two_length(o->op)) {
            l1 = ((b[1] >> 4) & 0xf) + 1;
            l2 = (b[1] & 0xf) + 1;
            snprintf(out, n, "%d(%d,%d),%d(%d,%d)", d1, l1, b1, d2, l2, b2);
        } else {
            l1 = b[1] + 1;
            snprintf(out, n, "%d(%d,%d),%d(%d)", d1, l1, b1, d2, b2);
        }
        return 1;
    default:
        (void)t2;
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

/* ----------------------------------------------------------------- emit -- */

static void emit_dc_hex(long a, int n)
{
    char l[16], opnd[128], rem[32];
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
    char l[16], opnd[64], rem[32];
    if (lab[a]) label_name(a, l); else l[0] = 0;
    snprintf(opnd, sizeof opnd, "XL%ld", n);
    sprintf(rem, "%06lX not covered by TXT", (unsigned long)a);
    emit(l, "DS", opnd, rem);
}

/* An address constant, from the RLD and not from the bytes.  The RLD is the one
 * place an object-deck disassembler has ground truth, and this is the only
 * statement here that rests on it. */
static void emit_adcon(long a, const struct rlditem *r)
{
    char l[16], opnd[64], rem[48];
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
        char t[16];
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

/* ------------------------------------------------------------------ run -- */

static void usage(FILE *o)
{
    fputs(
"Usage: dasm370 [options...] deck.obj\n"
" Options:\n"
"  --csect NAME       disassemble this control section (default: the only one)\n"
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
"from; anything that does not reproduce itself is written as DC X'..'.\n", o);
}

int main(int argc, char **argv)
{
    const char *src = NULL, *want = NULL, *outfn = NULL;
    int ai, i, allow_incomplete = 0;
    unsigned char *deck;
    long dn, ncards, c;
    long maxaddr = 0;

    if (argc == 1) { usage(stdout); return 0; }
    for (ai = 1; ai < argc; ai++) {
        if (!strcmp(argv[ai], "--help")) { usage(stdout); return 0; }
        else if (!strcmp(argv[ai], "-v")) { printf("%s %s - %s\n", DASM_NAME, DASM_VER, __DATE__); return 0; }
        else if (!strcmp(argv[ai], "--csect") && ai + 1 < argc) want = argv[++ai];
        else if (!strcmp(argv[ai], "--allow-incomplete")) allow_incomplete = 1;
        else if (!strcmp(argv[ai], "-o") && ai + 1 < argc) outfn = argv[++ai];
        else if (!strcmp(argv[ai], "--isa") && ai + 1 < argc) {
            const char *v = argv[++ai];
            if (strcmp(v, "app") && strcmp(v, "s370") && strcmp(v, "s360") && strcmp(v, "full")) {
                fprintf(stderr, "dasm370: --isa %s is not one of app|s370|s360|full\n", v);
                return 16;
            }
            /* Accepted and not yet acted on.  Problem-state against privileged is
             * a per-mnemonic attribute opc_table.h does not carry, and inventing
             * it here would be the second copy #374 exists to prevent.  It is an
             * additive table field, gated by as370/tests/opcinv.c, when the
             * decoder has a reason to want it. */
            if (strcmp(v, "full")) fprintf(stderr, "dasm370: --isa %s not implemented, using full\n", v);
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

    {
        long a = 0;
        while (a < sect_len) {
            const struct rlditem *r;
            if (!cov[a]) {                         /* a hole is a hole, not a zero */
                long n = 1;
                while (a + n < sect_len && !cov[a + n] && !lab[a + n]) n++;
                emit_ds_hole(a, n);
                a += n;
                continue;
            }
            if ((r = rld_at(a)) != NULL) { emit_adcon(a, r); a += r->len; continue; }
            {
                const struct opc *o;
                int mask = (img[a + 1] >> 4) & 0xf, ismask = 0, len;
                char opnd[128];
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
                    && operands(o, img + a, opnd, sizeof opnd)) {
                    int k, split = 0;
                    for (k = 1; k < len; k++) if (lab[a + k]) split = 1;
                    for (k = 0; k < len; k++) if (!cov[a + k]) split = 1;
                    if (!split) {
                        char l[16], rem[32];
                        if (lab[a]) label_name(a, l); else l[0] = 0;
                        sprintf(rem, "%06lX", (unsigned long)a);
                        emit(l, o->name, opnd, rem);
                        a += len;
                        continue;
                    }
                }
            }
            {                                      /* nothing else fits: DC */
                long n = 1;
                while (a + n < sect_len && cov[a + n] && !lab[a + n] && !rld_at(a + n) && n < 16) n++;
                emit_dc_hex(a, (int)n);
                a += n;
            }
        }
    }
    if (end_has_entry && end_entry >= 0 && end_entry < sect_len) {
        char t[16];
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
