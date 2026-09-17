/* The opcode table -- one file, and the only place either direction reads it.
 *
 * It used to be a bare initializer body: 200 brace pairs with no guard, no
 * struct and no sentinel, legal only inside the array in as370.c, with a
 * further 35 entries and the sentinel written after the #include.  That is
 * fine while as370 is the only consumer, because as370 only ever ENCODES --
 * op_find() keys on the mnemonic and never asks what a byte means.
 *
 * #112's disassembler asks exactly that, and a decoder built from a second
 * copy of this data can drift from the assembler silently: it would still
 * assemble, still compare, and disagree about an instruction neither tool
 * reports on.  So the table carries what inversion needs, and both tools
 * include this file (cc370#374).
 *
 * Two fields exist for the decoder and the encoder ignores both.
 *
 * `opw' is the opcode WIDTH IN BYTES, and it is here because the data cannot
 * be asked.  The encoder writes o->op as a big-endian halfword, so a ONE-byte
 * S-format opcode is spelled <op>00 -- TS is 0x9300 -- while SIO really is the
 * two bytes 0x9C00 and SIOF really is 0x9C01.  Both have a zero low byte and
 * they are not the same thing.  Exactly three entries are one-byte spelled as
 * a halfword: SSM, LPSW and TS.
 *
 * `dec' says which mnemonic a decoder should print for a byte pattern that
 * several entries claim.  OPD_PRIMARY is the one to print; OPD_ALIAS is a
 * legal spelling of the same encoding that loses; OPD_NEVER must not be
 * produced at all.
 *
 * WHICH SPELLING WINS IS MEASURED, NOT PREFERRED.  Counted over the operation
 * field of the 5,528 MVSBLD modules -- comment cards and continuations
 * excluded -- IBM's own source uses the compare spelling more often in every
 * one of the twelve pairs:
 *
 *   BE    34446 : BZ    32011      BER    203 : BZR    196
 *   BNE   44853 : BNZ   25651      BNER    86 : BNZR    47
 *   BH     4895 : BP     1066      BHR     17 : BPR      4
 *   BL     4777 : BM     1062      BLR     12 : BMR      6
 *   BNH   10897 : BNP    1324      BNHR     9 : BNPR     2
 *   BNL    6569 : BNM     447      BNLR     4 : BNMR     2
 *
 * Two margins are thin -- BE/BZ is 52 %, BER/BZR is 51 % -- and they are thin
 * because the choice is genuinely contextual: BZ after an arithmetic
 * instruction says what the programmer meant and BE says what the mask is.
 * A decoder cannot know which; it can know what the corpus writes.
 *
 * #112's own text illustrates the rule with `47 8 -> BZ'.  The point it makes
 * -- an extended mnemonic rather than BC 8 -- is what `dec' implements; which
 * of BE and BZ comes out is the measurement above, and it is BE.
 *
 * BC and BCR are ALIAS for the same reason and not because they are rare:
 * they cover all sixteen masks, so for a mask a pseudo names, the pseudo
 * wins, and for masks 3, 5, 6, 9, 10 and 12 -- which no pseudo names -- they
 * are the only entry left and the decoder falls through to them.
 *
 * BRXH and BRXLE are NEVER.  X'84' and X'85' are WRD and RDD on System/370
 * and BRXH/BRXLE on ESA/390; the target is MVS 3.8j, and the corpus contains
 * zero of either ESA mnemonic against zero WRD/RDD as well -- neither is
 * written in this source, but only one pair can be right for a module a
 * System/370 ran.  Decoding X'84' as BRXH would be an instruction from an
 * architecture the module predates.
 *
 * The deliberate gaps stay gaps: some IFOX00 mnemonics are absent rather than
 * guessed (cc370#51 has the delta).
 */
#ifndef AS370_OPC_TABLE_H
#define AS370_OPC_TABLE_H

/* F_S0: the S opcode space with NO operand.  IFOX00's own table is the
 * authority -- ifnx5m.asm describes every operand-bearing mnemonic with an
 * OPND card ahead of its OPCD (206 of them), and exactly two entries carry an
 * OPCD alone: IPK X'B20B' and PTLB X'B20D' (ifnx5m.asm:1562-1563).  With no
 * operand the rest of the card is a remark, so the operand field must not be
 * read at all. */
enum fmt { F_NONE, F_RR, F_RX, F_RS, F_SI, F_SS, F_BR, F_BC, F_SVC, F_S, F_S0 };

/* What a decoder should do with an entry when several claim one encoding. */
enum opc_dec { OPD_PRIMARY, OPD_ALIAS, OPD_NEVER };

/* THE ISA CLASS, for cc370#395's `--isa app'.  A disassembler decides at every
 * byte whether an instruction is there, and the larger the table the more
 * nonsense is representable -- data decodes as a rare instruction and NOTHING
 * DOWNSTREAM OBJECTS, because the round trip re-encodes the wrong reading to the
 * same bytes.  Narrowing the table is the only mechanism that removes the
 * reading rather than reporting it.
 *
 * THIS CUT IS OURS AND IS NOT RECOVERED FROM ANYWHERE.  #395 names Pospischil's
 * DISOPAPP as the precedent and quotes his purpose -- "to reduce false
 * instruction" -- but neither this session nor mvs38src has his table, so what
 * follows is a classification we DEFINED, argued entry by entry, and it should
 * be read as that.  Two independent passes over these 236 entries agreed on
 * floating point to the entry and differed elsewhere; the counts below are the
 * reconciliation, and the entries that were argued are named.  The union of the
 * two cuts was 106 entries and the intersection 95, so the disagreement was
 * eleven entries wide -- and the corpus writes most of them 0 or 3 times, which
 * means the two cuts differ measurably almost not at all.  What the boundary
 * changes is what a later reader believes about where it came from.
 *
 *   OPC_FP    52  opcode 20-3F and 60-7F, the whole short/long/extended set
 *   OPC_PRIV  30  problem-state programs cannot execute them
 *   OPC_IO    10  the channel instructions
 *   OPC_DEC   16  packed decimal, and the two zone/numeric moves with it
 *   OPC_APP  128  everything else, and what `--isa app' keeps
 *
 * MVCK, MVCP AND MVCS ARE OPC_PRIV ON THE CLASS RULE AND NOT ON THEIR RARITY.
 * They are semi-privileged -- MVCK moves under a source key and MVCP/MVCS across
 * address spaces -- so a problem-state program cannot use them, which is the
 * definition this column carries.  The measurement that sent us looking is
 * separate and worth recording: over 5,538 module sources, IBM writes MVCK,
 * MVCP, MVCS and MVCIN exactly ZERO times, and the disassembly of those same
 * modules' own objects decodes them 1,800 times over 1,200 sections -- 1,526
 * MVCK, 257 MVCIN, 14 MVCP, 3 MVCS.  BOTH SIDES OF THE SAME MODULES, so for
 * these every one is a false decode, which is a stronger statement than the
 * corpus can make about the no-source population it was found for.
 *
 * Moving the three leaves 205 under `app', all of them MVCIN, against 1,652 for
 * the same cut before it.  A count under `full' and a count under `app' are NOT
 * comparable -- cutting anything re-phases the walk and every remaining mnemonic
 * lands differently -- so both figures above are one deck set at one setting.
 *
 * MVCIN STAYS OPC_APP and those 205 stay with it.  It is problem-state, so the
 * only argument against it is that it is rare -- and rarity is not what this
 * column encodes.  Adding it would make the class mean "class, or too unusual to
 * risk", which is a second rule wearing the first one's name.  A frequency
 * column is a different instrument and would need its own measurement on the
 * no-source population, where "our sources never write it" does not hold:
 * that population exists BECAUSE IBM shipped objects whose sources we lack.
 *
 * FLOATING POINT AGREED TO THE ENTRY BECAUSE IT IS A RULE AND NOT A LIST -- both
 * passes derived it from the opcode ranges.  The other three were recollections,
 * and all three of the disagreements were omissions rather than judgements: one
 * pass had MVN and MVZ under decimal and the other had seven privileged entries
 * the first had simply not thought of.  Where a boundary is argued the entry says
 * so below.
 *
 * MVN and MVZ are OPC_DEC by USE and not by format -- they are SS moves, and
 * they are here because IDCLC02 is what an application cut is for: at X'4228'
 * the full table reads `SRP' and three `MVZ's over "08LC09LC02LCLOLC...", a table
 * of four-character names, and the cut turns them back into the DC they are.
 * The corpus writes MVN 120 times and MVZ 324 over 5,528 modules, so the cut
 * costs little where they are real.
 *
 * SVC IS OPC_APP AND THAT IS DELIBERATE.  "No privileged" reads as "no
 * supervisor" to somebody, and SVC is problem-state -- it is how a problem-state
 * program ASKS for supervisor work.  IBM's own source writes it 21,577 times
 * with a non-zero length over the 5,528-module corpus, so cutting it would break
 * the instrument on the corpus it is measured against.
 *
 * STCK IS OPC_APP AND STCKC IS NOT.  Store Clock is problem-state on System/370;
 * only the comparator and the CPU timer -- STCKC, SPT, STPT -- are privileged.
 * The corpus writes STCK 146 times.
 *
 * WRD AND RDD ARE OPC_PRIV AND ARE REACHABLE.  Both sessions wrote down that they
 * are OPD_NEVER and both were wrong: the NEVER pair is BRXH/BRXLE, the ESA/390
 * reading of the same two opcodes X'84' and X'85'.  WRD and RDD are the
 * System/370 reading, they are OPD_PRIMARY, and the ISA cut is exactly what
 * excludes them.  The error was stated in one session and echoed back by the
 * other, which is why it is written here rather than left as a shared belief.
 *
 * THERE IS NO ARCHITECTURE COLUMN, and `--isa s360' is refused rather than
 * approximated.  It would need a second classification with no better evidence
 * than this one, and the corpus says what it would cost: of the S/370 additions
 * this table carries, IBM's own MVS 3.8j source writes ICM 9,824 times, STCM
 * 6,720, MVCL 738, CLM 416, STCK 146 and CLCL 41 -- 17,885 real instructions an
 * S/360 cut would turn into DC.  It writes BAS, BASR, BASSM, BSM, MVCIN, IAC and
 * TB exactly ZERO times, so the cut would remove nothing anyone wrote.  A
 * measurement that harmful and that unhelpful is not worth a column. */
enum opc_cls { OPC_APP, OPC_FP, OPC_DEC, OPC_IO, OPC_PRIV };

struct opc {
    const char *name;
    int fmt;
    int op;     /* opcode; a one-byte S-format opcode is spelled <op>00 */
    int m1;     /* implied mask for the branch pseudos, else 0 */
    int opw;    /* opcode width in BYTES: 1 or 2 */
    int dec;    /* enum opc_dec */
    int cls;    /* enum opc_cls -- what `--isa app' keeps (cc370#395) */
};

/* The SS operand shape is a property of the OPCODE, not a list.
 *
 * Three shapes share F_SS and the table cannot tell them apart, because it does
 * not have to -- the opcode decides:
 *
 *   D1(L,B1),D2(B2)          one length, the whole byte      MVC, CLC, TR, ...
 *   D1(L1,B1),D2(L2,B2)      two 4-bit lengths               X'Fx' except X'F0'
 *   D1(L1,B1),D2(B2),I3      one length and an immediate     SRP, X'F0'
 *
 * SRP is the one that punishes a guess: its length sits in the HIGH nibble and
 * the rounding digit I3 -- a third operand -- in the low one. Reading it as a
 * single-length SS writes the length across the whole byte, so `SRP P1(8),1,0'
 * comes out F0 07 where IFOX00 emits F0 70: the length reaches the machine as
 * the rounding digit and vice versa (cc370#64).
 *
 * These live here rather than in either tool because a decoder has to apply the
 * same predicate the encoder does, and a second copy of a rule this small is the
 * drift #374 moved the table here to prevent.
 *
 * `static inline' and not plain `static': a translation unit that includes the
 * header without assembling or disassembling SS -- tests/opcinv.c is one --
 * draws -Wunused-function on a plain static, and CI is -Werror. The test found
 * that on the first build, which is the third-consumer property doing its job. */
static inline int opc_ss_two_length(int op) { return (op & 0xF0) == 0xF0 && op != 0xF0; }
static inline int opc_ss_srp(int op)        { return op == 0xF0; }

static const struct opc optab[] = {
    { "AR", F_RR, 0x1A, 0, 1, OPD_PRIMARY, OPC_APP },
    { "ADR", F_RR, 0x2A, 0, 1, OPD_PRIMARY, OPC_FP },
    { "AER", F_RR, 0x3A, 0, 1, OPD_PRIMARY, OPC_FP },
    { "ALR", F_RR, 0x1E, 0, 1, OPD_PRIMARY, OPC_APP },
    { "AUR", F_RR, 0x3E, 0, 1, OPD_PRIMARY, OPC_FP },
    { "AWR", F_RR, 0x2E, 0, 1, OPD_PRIMARY, OPC_FP },
    { "AXR", F_RR, 0x36, 0, 1, OPD_PRIMARY, OPC_FP },
    { "BALR", F_RR, 0x05, 0, 1, OPD_PRIMARY, OPC_APP },
    { "BASR", F_RR, 0x0D, 0, 1, OPD_PRIMARY, OPC_APP },
    { "BASSM", F_RR, 0x0C, 0, 1, OPD_PRIMARY, OPC_APP },
    { "BSM", F_RR, 0x0B, 0, 1, OPD_PRIMARY, OPC_APP },
    { "BCR", F_RR, 0x07, 0, 1, OPD_ALIAS, OPC_APP },
    { "BCTR", F_RR, 0x06, 0, 1, OPD_PRIMARY, OPC_APP },
    { "CDR", F_RR, 0x29, 0, 1, OPD_PRIMARY, OPC_FP },
    { "CER", F_RR, 0x39, 0, 1, OPD_PRIMARY, OPC_FP },
    { "CLR", F_RR, 0x15, 0, 1, OPD_PRIMARY, OPC_APP },
    { "CLCL", F_RR, 0x0F, 0, 1, OPD_PRIMARY, OPC_APP },
    { "CR", F_RR, 0x19, 0, 1, OPD_PRIMARY, OPC_APP },
    { "DDR", F_RR, 0x2D, 0, 1, OPD_PRIMARY, OPC_FP },
    { "DER", F_RR, 0x3D, 0, 1, OPD_PRIMARY, OPC_FP },
    { "DR", F_RR, 0x1D, 0, 1, OPD_PRIMARY, OPC_APP },
    { "HDR", F_RR, 0x24, 0, 1, OPD_PRIMARY, OPC_FP },
    { "HER", F_RR, 0x34, 0, 1, OPD_PRIMARY, OPC_FP },
    { "LCDR", F_RR, 0x23, 0, 1, OPD_PRIMARY, OPC_FP },
    { "LCER", F_RR, 0x33, 0, 1, OPD_PRIMARY, OPC_FP },
    { "LCR", F_RR, 0x13, 0, 1, OPD_PRIMARY, OPC_APP },
    { "LDR", F_RR, 0x28, 0, 1, OPD_PRIMARY, OPC_FP },
    { "LER", F_RR, 0x38, 0, 1, OPD_PRIMARY, OPC_FP },
    { "LNDR", F_RR, 0x21, 0, 1, OPD_PRIMARY, OPC_FP },
    { "LNER", F_RR, 0x31, 0, 1, OPD_PRIMARY, OPC_FP },
    { "LNR", F_RR, 0x11, 0, 1, OPD_PRIMARY, OPC_APP },
    { "LPDR", F_RR, 0x20, 0, 1, OPD_PRIMARY, OPC_FP },
    { "LPER", F_RR, 0x30, 0, 1, OPD_PRIMARY, OPC_FP },
    { "LPR", F_RR, 0x10, 0, 1, OPD_PRIMARY, OPC_APP },
    { "LR", F_RR, 0x18, 0, 1, OPD_PRIMARY, OPC_APP },
    { "LRDR", F_RR, 0x25, 0, 1, OPD_PRIMARY, OPC_FP },
    { "LRER", F_RR, 0x35, 0, 1, OPD_PRIMARY, OPC_FP },
    { "LTDR", F_RR, 0x22, 0, 1, OPD_PRIMARY, OPC_FP },
    { "LTER", F_RR, 0x32, 0, 1, OPD_PRIMARY, OPC_FP },
    { "LTR", F_RR, 0x12, 0, 1, OPD_PRIMARY, OPC_APP },
    { "MDR", F_RR, 0x2C, 0, 1, OPD_PRIMARY, OPC_FP },
    { "MER", F_RR, 0x3C, 0, 1, OPD_PRIMARY, OPC_FP },
    { "MR", F_RR, 0x1C, 0, 1, OPD_PRIMARY, OPC_APP },
    { "MVCL", F_RR, 0x0E, 0, 1, OPD_PRIMARY, OPC_APP },
    { "MXDR", F_RR, 0x27, 0, 1, OPD_PRIMARY, OPC_FP },
    { "MXR", F_RR, 0x26, 0, 1, OPD_PRIMARY, OPC_FP },
    { "NR", F_RR, 0x14, 0, 1, OPD_PRIMARY, OPC_APP },
    { "OR", F_RR, 0x16, 0, 1, OPD_PRIMARY, OPC_APP },
    { "SDR", F_RR, 0x2B, 0, 1, OPD_PRIMARY, OPC_FP },
    { "SER", F_RR, 0x3B, 0, 1, OPD_PRIMARY, OPC_FP },
    { "SLR", F_RR, 0x1F, 0, 1, OPD_PRIMARY, OPC_APP },
    { "SPM", F_RR, 0x04, 0, 1, OPD_PRIMARY, OPC_APP },
    { "SR", F_RR, 0x1B, 0, 1, OPD_PRIMARY, OPC_APP },
    { "SUR", F_RR, 0x3F, 0, 1, OPD_PRIMARY, OPC_FP },
    { "SWR", F_RR, 0x2F, 0, 1, OPD_PRIMARY, OPC_FP },
    { "SXR", F_RR, 0x37, 0, 1, OPD_PRIMARY, OPC_FP },
    { "XR", F_RR, 0x17, 0, 1, OPD_PRIMARY, OPC_APP },
    { "A", F_RX, 0x5A, 0, 1, OPD_PRIMARY, OPC_APP },
    { "AD", F_RX, 0x6A, 0, 1, OPD_PRIMARY, OPC_FP },
    { "AE", F_RX, 0x7A, 0, 1, OPD_PRIMARY, OPC_FP },
    { "AH", F_RX, 0x4A, 0, 1, OPD_PRIMARY, OPC_APP },
    { "AL", F_RX, 0x5E, 0, 1, OPD_PRIMARY, OPC_APP },
    { "AU", F_RX, 0x7E, 0, 1, OPD_PRIMARY, OPC_FP },
    { "AW", F_RX, 0x6E, 0, 1, OPD_PRIMARY, OPC_FP },
    { "BAL", F_RX, 0x45, 0, 1, OPD_PRIMARY, OPC_APP },
    { "BAS", F_RX, 0x4D, 0, 1, OPD_PRIMARY, OPC_APP },
    { "BC", F_RX, 0x47, 0, 1, OPD_ALIAS, OPC_APP },
    { "BCT", F_RX, 0x46, 0, 1, OPD_PRIMARY, OPC_APP },
    { "C", F_RX, 0x59, 0, 1, OPD_PRIMARY, OPC_APP },
    { "CD", F_RX, 0x69, 0, 1, OPD_PRIMARY, OPC_FP },
    { "CE", F_RX, 0x79, 0, 1, OPD_PRIMARY, OPC_FP },
    { "CH", F_RX, 0x49, 0, 1, OPD_PRIMARY, OPC_APP },
    { "CL", F_RX, 0x55, 0, 1, OPD_PRIMARY, OPC_APP },
    { "CVB", F_RX, 0x4F, 0, 1, OPD_PRIMARY, OPC_DEC },
    { "CVD", F_RX, 0x4E, 0, 1, OPD_PRIMARY, OPC_DEC },
    { "D", F_RX, 0x5D, 0, 1, OPD_PRIMARY, OPC_APP },
    { "DD", F_RX, 0x6D, 0, 1, OPD_PRIMARY, OPC_FP },
    { "DE", F_RX, 0x7D, 0, 1, OPD_PRIMARY, OPC_FP },
    { "EX", F_RX, 0x44, 0, 1, OPD_PRIMARY, OPC_APP },
    { "IC", F_RX, 0x43, 0, 1, OPD_PRIMARY, OPC_APP },
    { "L", F_RX, 0x58, 0, 1, OPD_PRIMARY, OPC_APP },
    { "LA", F_RX, 0x41, 0, 1, OPD_PRIMARY, OPC_APP },
    { "LAE", F_RX, 0x51, 0, 1, OPD_PRIMARY, OPC_APP },
    { "LD", F_RX, 0x68, 0, 1, OPD_PRIMARY, OPC_FP },
    { "LE", F_RX, 0x78, 0, 1, OPD_PRIMARY, OPC_FP },
    { "LH", F_RX, 0x48, 0, 1, OPD_PRIMARY, OPC_APP },
    { "LRA", F_RX, 0xB1, 0, 1, OPD_PRIMARY, OPC_PRIV },
    { "M", F_RX, 0x5C, 0, 1, OPD_PRIMARY, OPC_APP },
    { "MD", F_RX, 0x6C, 0, 1, OPD_PRIMARY, OPC_FP },
    { "ME", F_RX, 0x7C, 0, 1, OPD_PRIMARY, OPC_FP },
    { "MH", F_RX, 0x4C, 0, 1, OPD_PRIMARY, OPC_APP },
    { "MS", F_RX, 0x71, 0, 1, OPD_PRIMARY, OPC_FP },
    { "MXD", F_RX, 0x67, 0, 1, OPD_PRIMARY, OPC_FP },
    { "N", F_RX, 0x54, 0, 1, OPD_PRIMARY, OPC_APP },
    { "O", F_RX, 0x56, 0, 1, OPD_PRIMARY, OPC_APP },
    { "S", F_RX, 0x5B, 0, 1, OPD_PRIMARY, OPC_APP },
    { "SD", F_RX, 0x6B, 0, 1, OPD_PRIMARY, OPC_FP },
    { "SE", F_RX, 0x7B, 0, 1, OPD_PRIMARY, OPC_FP },
    { "SH", F_RX, 0x4B, 0, 1, OPD_PRIMARY, OPC_APP },
    { "SL", F_RX, 0x5F, 0, 1, OPD_PRIMARY, OPC_APP },
    { "ST", F_RX, 0x50, 0, 1, OPD_PRIMARY, OPC_APP },
    { "STC", F_RX, 0x42, 0, 1, OPD_PRIMARY, OPC_APP },
    { "STD", F_RX, 0x60, 0, 1, OPD_PRIMARY, OPC_FP },
    { "STE", F_RX, 0x70, 0, 1, OPD_PRIMARY, OPC_FP },
    { "STH", F_RX, 0x40, 0, 1, OPD_PRIMARY, OPC_APP },
    { "SU", F_RX, 0x7F, 0, 1, OPD_PRIMARY, OPC_FP },
    { "SW", F_RX, 0x6F, 0, 1, OPD_PRIMARY, OPC_FP },
    { "X", F_RX, 0x57, 0, 1, OPD_PRIMARY, OPC_APP },
    { "BXH", F_RS, 0x86, 0, 1, OPD_PRIMARY, OPC_APP },
    { "BXLE", F_RS, 0x87, 0, 1, OPD_PRIMARY, OPC_APP },
    { "CDS", F_RS, 0xBB, 0, 1, OPD_PRIMARY, OPC_APP },
    { "CLCLE", F_RS, 0xA9, 0, 1, OPD_PRIMARY, OPC_APP },
    { "CLM", F_RS, 0xBD, 0, 1, OPD_PRIMARY, OPC_APP },
    { "CS", F_RS, 0xBA, 0, 1, OPD_PRIMARY, OPC_APP },
    { "ICM", F_RS, 0xBF, 0, 1, OPD_PRIMARY, OPC_APP },
    { "LAM", F_RS, 0x9A, 0, 1, OPD_PRIMARY, OPC_APP },
    { "LCTL", F_RS, 0xB7, 0, 1, OPD_PRIMARY, OPC_PRIV },
    { "LM", F_RS, 0x98, 0, 1, OPD_PRIMARY, OPC_APP },
    { "MVCLE", F_RS, 0xA8, 0, 1, OPD_PRIMARY, OPC_APP },
    { "SIGP", F_RS, 0xAE, 0, 1, OPD_PRIMARY, OPC_PRIV },
    { "STAM", F_RS, 0x9B, 0, 1, OPD_PRIMARY, OPC_APP },
    { "STCM", F_RS, 0xBE, 0, 1, OPD_PRIMARY, OPC_APP },
    { "STCTL", F_RS, 0xB6, 0, 1, OPD_PRIMARY, OPC_PRIV },
    { "STM", F_RS, 0x90, 0, 1, OPD_PRIMARY, OPC_APP },
    { "TRACE", F_RS, 0x99, 0, 1, OPD_PRIMARY, OPC_APP },
    { "SLA", F_RS, 0x8B, 0, 1, OPD_PRIMARY, OPC_APP },
    { "SLDA", F_RS, 0x8F, 0, 1, OPD_PRIMARY, OPC_APP },
    { "SLDL", F_RS, 0x8D, 0, 1, OPD_PRIMARY, OPC_APP },
    { "SLL", F_RS, 0x89, 0, 1, OPD_PRIMARY, OPC_APP },
    { "SRA", F_RS, 0x8A, 0, 1, OPD_PRIMARY, OPC_APP },
    { "SRDA", F_RS, 0x8E, 0, 1, OPD_PRIMARY, OPC_APP },
    { "SRDL", F_RS, 0x8C, 0, 1, OPD_PRIMARY, OPC_APP },
    { "SRL", F_RS, 0x88, 0, 1, OPD_PRIMARY, OPC_APP },
    { "BRXH", F_SI, 0x84, 0, 1, OPD_NEVER, OPC_APP },
    { "BRXLE", F_SI, 0x85, 0, 1, OPD_NEVER, OPC_APP },
    { "CLI", F_SI, 0x95, 0, 1, OPD_PRIMARY, OPC_APP },
    { "MC", F_SI, 0xAF, 0, 1, OPD_PRIMARY, OPC_PRIV },
    { "MVI", F_SI, 0x92, 0, 1, OPD_PRIMARY, OPC_APP },
    { "NI", F_SI, 0x94, 0, 1, OPD_PRIMARY, OPC_APP },
    { "OI", F_SI, 0x96, 0, 1, OPD_PRIMARY, OPC_APP },
    { "STNSM", F_SI, 0xAC, 0, 1, OPD_PRIMARY, OPC_PRIV },
    { "STOSM", F_SI, 0xAD, 0, 1, OPD_PRIMARY, OPC_PRIV },
    { "TM", F_SI, 0x91, 0, 1, OPD_PRIMARY, OPC_APP },
    { "XI", F_SI, 0x97, 0, 1, OPD_PRIMARY, OPC_APP },
    { "AP", F_SS, 0xFA, 0, 1, OPD_PRIMARY, OPC_DEC },
    { "CLC", F_SS, 0xD5, 0, 1, OPD_PRIMARY, OPC_APP },
    { "CP", F_SS, 0xF9, 0, 1, OPD_PRIMARY, OPC_DEC },
    { "DP", F_SS, 0xFD, 0, 1, OPD_PRIMARY, OPC_DEC },
    { "ED", F_SS, 0xDE, 0, 1, OPD_PRIMARY, OPC_DEC },
    { "EDMK", F_SS, 0xDF, 0, 1, OPD_PRIMARY, OPC_DEC },
    { "LMD", F_SS, 0xEF, 0, 1, OPD_PRIMARY, OPC_APP },
    { "MVC", F_SS, 0xD2, 0, 1, OPD_PRIMARY, OPC_APP },
    { "MVCIN", F_SS, 0xE8, 0, 1, OPD_PRIMARY, OPC_APP },
    { "MVCK", F_SS, 0xD9, 0, 1, OPD_PRIMARY, OPC_PRIV },
    { "MVCP", F_SS, 0xDA, 0, 1, OPD_PRIMARY, OPC_PRIV },
    { "MVCS", F_SS, 0xDB, 0, 1, OPD_PRIMARY, OPC_PRIV },
    { "MVN", F_SS, 0xD1, 0, 1, OPD_PRIMARY, OPC_DEC },
    { "MVO", F_SS, 0xF1, 0, 1, OPD_PRIMARY, OPC_DEC },
    { "MVZ", F_SS, 0xD3, 0, 1, OPD_PRIMARY, OPC_DEC },
    { "NC", F_SS, 0xD4, 0, 1, OPD_PRIMARY, OPC_APP },
    { "OC", F_SS, 0xD6, 0, 1, OPD_PRIMARY, OPC_APP },
    { "PACK", F_SS, 0xF2, 0, 1, OPD_PRIMARY, OPC_DEC },
    { "PLO", F_SS, 0xEE, 0, 1, OPD_PRIMARY, OPC_APP },
    { "SP", F_SS, 0xFB, 0, 1, OPD_PRIMARY, OPC_DEC },
    { "SRP", F_SS, 0xF0, 0, 1, OPD_PRIMARY, OPC_DEC },
    { "TR", F_SS, 0xDC, 0, 1, OPD_PRIMARY, OPC_APP },
    { "TRT", F_SS, 0xDD, 0, 1, OPD_PRIMARY, OPC_APP },
    { "UNPK", F_SS, 0xF3, 0, 1, OPD_PRIMARY, OPC_DEC },
    { "XC", F_SS, 0xD7, 0, 1, OPD_PRIMARY, OPC_APP },
    { "ZAP", F_SS, 0xF8, 0, 1, OPD_PRIMARY, OPC_DEC },

    /* ---- S/370 instructions absent from this table until #51 ----------------
     * The table above was built from what the ecosystem corpus happened to use.
     * Checked against IFOX00's own machine-op table (ifox-src/all/genop.asm,
     * 220 machine opcodes against this table's 170), the following were simply
     * missing -- `MP` is the one the #51 reporter hit, assembling COBOL output.
     *
     * Every entry below encodes through a path the corpus already pins to
     * IFOX00 byte-for-byte: SS via DP/AP/ZAP, RR via the whole RR block, SI via
     * NI/CLI/MVI, S via IPK/SPKA/STCK (which sit in optab[] in as370.c, beside
     * the extended branches).
     *
     * NOT added, deliberately: TPROT (X'E501', SSE) and IPTE (X'B221', RRE).
     * as370 has neither format, so an entry for them would have to invent an
     * encoding -- turning a clean "undefined operation code" RC 8 into silently
     * wrong bytes, which is the failure mode this table exists to avoid. They
     * stay documented gaps -- see #51, which lists the full IFOX00 delta. */
    { "MP", F_SS, 0xFC, 0, 1, OPD_PRIMARY, OPC_DEC },               /* multiply decimal -- same shape as DP X'FD' */
    { "SSK", F_RR, 0x08, 0, 1, OPD_PRIMARY, OPC_PRIV },
    { "ISK", F_RR, 0x09, 0, 1, OPD_PRIMARY, OPC_PRIV },
    /* Write/Read Direct. X'84'/X'85' are also claimed by the ESA/390 BRXH/BRXLE
     * entries above -- a genuine architecture reuse of the opcode, not a typo.
     * op_find() keys on the mnemonic and as370 only ever encodes, never decodes,
     * so the two coexist without ambiguity. */
    { "WRD", F_SI, 0x84, 0, 1, OPD_PRIMARY, OPC_PRIV },
    { "RDD", F_SI, 0x85, 0, 1, OPD_PRIMARY, OPC_PRIV },
    /* S format, 4 bytes. A ONE-byte opcode is written here as <op>00: the
     * encoder emits o->op as a big-endian halfword, so 0x9300 produces the
     * 93 00 B2 D2D2 that TS wants. The X'B2xx' group is already two bytes. */
    { "SSM", F_S, 0x8000, 0, 1, OPD_PRIMARY, OPC_PRIV },
    { "LPSW", F_S, 0x8200, 0, 1, OPD_PRIMARY, OPC_PRIV },
    { "TS", F_S, 0x9300, 0, 1, OPD_PRIMARY, OPC_APP },
    { "SIO", F_S, 0x9C00, 0, 2, OPD_PRIMARY, OPC_IO },
    { "SIOF", F_S, 0x9C01, 0, 2, OPD_PRIMARY, OPC_IO },
    { "TIO", F_S, 0x9D00, 0, 2, OPD_PRIMARY, OPC_IO },
    { "CLRIO", F_S, 0x9D01, 0, 2, OPD_PRIMARY, OPC_IO },
    { "HIO", F_S, 0x9E00, 0, 2, OPD_PRIMARY, OPC_IO },
    { "HDV", F_S, 0x9E01, 0, 2, OPD_PRIMARY, OPC_IO },
    { "TCH", F_S, 0x9F00, 0, 2, OPD_PRIMARY, OPC_IO },
    { "CLRCH", F_S, 0x9F01, 0, 2, OPD_PRIMARY, OPC_IO },
    { "CONCS", F_S, 0xB200, 0, 2, OPD_PRIMARY, OPC_PRIV },
    { "DISCS", F_S, 0xB201, 0, 2, OPD_PRIMARY, OPC_PRIV },
    { "STIDP", F_S, 0xB202, 0, 2, OPD_PRIMARY, OPC_PRIV },
    { "STIDC", F_S, 0xB203, 0, 2, OPD_PRIMARY, OPC_IO },
    { "SCK", F_S, 0xB204, 0, 2, OPD_PRIMARY, OPC_PRIV },
    { "SCKC", F_S, 0xB206, 0, 2, OPD_PRIMARY, OPC_PRIV },
    { "STCKC", F_S, 0xB207, 0, 2, OPD_PRIMARY, OPC_PRIV },
    { "SPT", F_S, 0xB208, 0, 2, OPD_PRIMARY, OPC_PRIV },
    { "STPT", F_S, 0xB209, 0, 2, OPD_PRIMARY, OPC_PRIV },
    { "PTLB", F_S0, 0xB20D, 0, 2, OPD_PRIMARY, OPC_PRIV },   /* no operand -- see F_S0 in as370.c */
    { "SPX", F_S, 0xB210, 0, 2, OPD_PRIMARY, OPC_PRIV },
    { "STPX", F_S, 0xB211, 0, 2, OPD_PRIMARY, OPC_PRIV },
    { "STAP", F_S, 0xB212, 0, 2, OPD_PRIMARY, OPC_PRIV },
    { "RRB", F_S, 0xB213, 0, 2, OPD_PRIMARY, OPC_IO },
    /* extended branches: BC (RX, op 0x47) / BCR (RR-ish, op 0x07) with implied mask */
    { "B", F_BC, 0x47, 15, 1, OPD_PRIMARY, OPC_APP }, { "NOP", F_BC, 0x47, 0, 1, OPD_PRIMARY, OPC_APP },
    { "BE", F_BC, 0x47, 8, 1, OPD_PRIMARY, OPC_APP }, { "BNE", F_BC, 0x47, 7, 1, OPD_PRIMARY, OPC_APP },
    { "BH", F_BC, 0x47, 2, 1, OPD_PRIMARY, OPC_APP }, { "BL", F_BC, 0x47, 4, 1, OPD_PRIMARY, OPC_APP },
    { "BNH", F_BC, 0x47, 13, 1, OPD_PRIMARY, OPC_APP }, { "BNL", F_BC, 0x47, 11, 1, OPD_PRIMARY, OPC_APP },
    { "BZ", F_BC, 0x47, 8, 1, OPD_ALIAS, OPC_APP }, { "BNZ", F_BC, 0x47, 7, 1, OPD_ALIAS, OPC_APP },
    { "BP", F_BC, 0x47, 2, 1, OPD_ALIAS, OPC_APP }, { "BM", F_BC, 0x47, 4, 1, OPD_ALIAS, OPC_APP },
    { "BO", F_BC, 0x47, 1, 1, OPD_PRIMARY, OPC_APP }, { "BNO", F_BC, 0x47, 14, 1, OPD_PRIMARY, OPC_APP },
    { "BNP", F_BC, 0x47, 13, 1, OPD_ALIAS, OPC_APP }, { "BNM", F_BC, 0x47, 11, 1, OPD_ALIAS, OPC_APP },
    { "IPK", F_S0, 0xB20B, 0, 2, OPD_PRIMARY, OPC_PRIV }, { "SPKA", F_S, 0xB20A, 0, 2, OPD_PRIMARY, OPC_PRIV },
    { "STCK", F_S, 0xB205, 0, 2, OPD_PRIMARY, OPC_APP },
    { "SVC", F_SVC, 0x0A, 0, 1, OPD_PRIMARY, OPC_APP },
    { "BR", F_BR, 0x07, 15, 1, OPD_PRIMARY, OPC_APP }, { "NOPR", F_BR, 0x07, 0, 1, OPD_PRIMARY, OPC_APP },
    { "BER", F_BR, 0x07, 8, 1, OPD_PRIMARY, OPC_APP }, { "BNER", F_BR, 0x07, 7, 1, OPD_PRIMARY, OPC_APP },
    { "BHR", F_BR, 0x07, 2, 1, OPD_PRIMARY, OPC_APP }, { "BLR", F_BR, 0x07, 4, 1, OPD_PRIMARY, OPC_APP },
    { "BNHR", F_BR, 0x07, 13, 1, OPD_PRIMARY, OPC_APP }, { "BNLR", F_BR, 0x07, 11, 1, OPD_PRIMARY, OPC_APP },
    { "BZR", F_BR, 0x07, 8, 1, OPD_ALIAS, OPC_APP }, { "BNZR", F_BR, 0x07, 7, 1, OPD_ALIAS, OPC_APP },
    { "BPR", F_BR, 0x07, 2, 1, OPD_ALIAS, OPC_APP }, { "BMR", F_BR, 0x07, 4, 1, OPD_ALIAS, OPC_APP },
    { "BOR", F_BR, 0x07, 1, 1, OPD_PRIMARY, OPC_APP }, { "BNOR", F_BR, 0x07, 14, 1, OPD_PRIMARY, OPC_APP },
    /* BNP and BNM had their BC forms above and not their BR ones. The pair is
     * the same masks -- 13 and 11 -- and IGG0203A and IGC0009D use them
     * (cc370#298). */
    { "BNPR", F_BR, 0x07, 13, 1, OPD_ALIAS, OPC_APP }, { "BNMR", F_BR, 0x07, 11, 1, OPD_ALIAS, OPC_APP },
    { NULL, 0, 0, 0, 0, OPD_NEVER, OPC_APP }
};

#endif /* AS370_OPC_TABLE_H */
