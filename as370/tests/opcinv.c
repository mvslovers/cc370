/* The opcode table inverts: every encoding a decoder can meet names exactly one
 * mnemonic (cc370#374).
 *
 * This file is the SECOND consumer of opc_table.h, which is the property under
 * test as much as anything it asserts: if the header stops being includable on
 * its own, this stops compiling.  as370 only ever encodes, so nothing in the
 * assembler would notice.
 *
 * Scored against two mutants of the header, built for this and not committed:
 *
 *   every entry OPD_PRIMARY -- the information the table carried before #374:
 *     52 failures.  The twelve mask-alias pairs are one each; WRD/RDD against
 *     BRXH/BRXLE are sixteen each, because an entry that carries no mask is a
 *     candidate for all sixteen, which is exactly what a decoder faces.
 *   the duplicate BCT put back:
 *     17 failures -- the name reported twice, and the encoding once per mask.
 */
#include <stdio.h>
#include <string.h>
#include "opc_table.h"

static int fails;

static void bad(const char *fmt, ...);
#include <stdarg.h>
static void bad(const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    fputs("opcinv: ", stdout);
    vprintf(fmt, ap);
    fputc('\n', stdout);
    va_end(ap);
    fails++;
}

/* A branch pseudo carries its mask in the table; every other entry takes the
 * mask from nowhere -- the decoder is not looking at one. */
static int has_mask(const struct opc *o) { return o->fmt == F_BC || o->fmt == F_BR; }

/* The opcode a decoder actually reads: one byte, or two.  A one-byte S-format
 * opcode is spelled <op>00 in the table, so it has to come back down. */
static int opcode_of(const struct opc *o)
{
    if (o->opw == 1 && (o->fmt == F_S || o->fmt == F_S0)) return (o->op >> 8) & 0xff;
    return o->op;
}

/* The generic BC/BCR cover every mask, so they are candidates for all 16. */
static int covers(const struct opc *o, int op, int mask)
{
    if (opcode_of(o) != op) return 0;
    return has_mask(o) ? o->m1 == mask : 1;
}

int main(void)
{
    int i, j, n = 0, op, mask;

    for (i = 0; optab[i].name; i++) n++;

    for (i = 0; i < n; i++) {
        const struct opc *o = &optab[i];
        if (o->opw != 1 && o->opw != 2)
            bad("%s: opcode width is %d, not 1 or 2", o->name, o->opw);
        if (o->dec != OPD_PRIMARY && o->dec != OPD_ALIAS && o->dec != OPD_NEVER)
            bad("%s: decode preference %d is not one of the three", o->name, o->dec);
        /* Only the S space is two bytes wide, and a one-byte S opcode has to be
         * spelled with a zero low half or the encoder writes a byte nobody
         * asked for. */
        if (o->opw == 2 && o->fmt != F_S && o->fmt != F_S0)
            bad("%s: two-byte opcode outside the S formats", o->name);
        if (o->opw == 1 && (o->fmt == F_S || o->fmt == F_S0) && (o->op & 0xff))
            bad("%s: one byte wide but spelled 0x%04X, low half not zero", o->name, o->op);
        for (j = i + 1; j < n; j++)
            if (!strcmp(o->name, optab[j].name))
                bad("%s appears twice, at %d and %d", o->name, i, j);
    }

    /* No one-byte opcode may be the first byte of a two-byte one: a decoder
     * reading that byte could not know whether to consume the second. */
    for (i = 0; i < n; i++) {
        if (optab[i].opw != 2 || optab[i].dec == OPD_NEVER) continue;
        for (j = 0; j < n; j++)
            if (optab[j].opw == 1 && optab[j].dec != OPD_NEVER
                && opcode_of(&optab[j]) == ((optab[i].op >> 8) & 0xff))
                bad("%s (one byte, X'%02X') is the first byte of %s (X'%04X')",
                    optab[j].name, opcode_of(&optab[j]), optab[i].name, optab[i].op);
    }

    /* The inversion itself: for every encoding, at most one PRIMARY, and an
     * encoding any entry claims must be decodable as something. */
    for (op = 0; op <= 0xffff; op++)
        for (mask = 0; mask < 16; mask++) {
            const char *prim = NULL;
            int nprim = 0, nalias = 0, nany = 0;
            for (i = 0; i < n; i++) {
                const struct opc *o = &optab[i];
                if (!covers(o, op, mask)) continue;
                nany++;
                if (o->dec == OPD_PRIMARY) { nprim++; prim = o->name; }
                else if (o->dec == OPD_ALIAS) nalias++;
            }
            if (nprim > 1) {
                bad("X'%04X' mask %d: %d mnemonics claim it as PRIMARY", op, mask, nprim);
                for (i = 0; i < n; i++)
                    if (covers(&optab[i], op, mask) && optab[i].dec == OPD_PRIMARY)
                        printf("opcinv:     %s\n", optab[i].name);
            }
            if (nany && !nprim && !nalias)
                bad("X'%04X' mask %d: every entry is OPD_NEVER", op, mask);
            (void)prim;
        }

    if (fails) { printf("opcinv: %d FAILURE(S) over %d entries\n", fails, n); return 1; }
    printf("opcinv: OK (%d entries, every encoding inverts to one mnemonic)\n", n);
    return 0;
}
