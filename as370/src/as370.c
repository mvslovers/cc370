/* as370 - host-native MVS assembler for the cc370 cross-toolchain.
 *
 * A single-file clone of IBM's Assembler-XF (IFOX00): macro preprocessor +
 * two-pass core + OS/360 object writer (80-byte EBCDIC ESD/TXT/RLD/END cards).
 * Runs on macOS/Linux and produces object decks byte-identical to IFOX00 —
 * validated over 950 ecosystem modules (crent370/libc370, rexx370, UFSD, HTTPD,
 * samples). The END-card translator IDR is IFOX-specific and intentionally not
 * reproduced; "byte-identical" means ESD/TXT/RLD content.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <time.h>
#include <unistd.h>
#include <libgen.h>
#include <limits.h>

#include "mvs370.h"
#ifdef __APPLE__
#include <stdint.h>
#include <mach-o/dyld.h>
#endif

/* bounded string copy that always NUL-terminates (dst must hold n+1 bytes). A
 * plain loop, not strncpy/strncat, so it is free of the (false-positive here)
 * -Wstringop-truncation those builtins draw for a deliberate truncating copy. */
static void scopy(char *d, const char *s, size_t n) { size_t i = 0; while (i < n && s[i]) { d[i] = s[i]; i++; } d[i] = 0; }
/* Append S to D at offset AT, never writing past DSZ-1, and return the new
 * offset. Used where a card is assembled from fields whose sizes sum to more
 * than the destination: an snprintf("%s %s %s") there is a format whose output
 * the compiler cannot bound, and glibc's fortify headers reject it under
 * -Werror=format-truncation -- a diagnostic macOS cannot produce, so it fails
 * only in CI. Building the card explicitly makes the bound visible instead. */
static size_t bcat(char *d, size_t dsz, size_t at, const char *s) {
    if (at + 1 >= dsz) return at;
    while (*s && at + 1 < dsz) d[at++] = *s++;
    d[at] = 0; return at;
}

/* as370 runs on the host (not MVS), so these limits are sized for real
 * modules, not the 24-bit target. Largest rexx370 CSECT is well under these. */
#define MAXSYM 65536
#define MAXLIT 8192
#define MAXREL 131072
#define TEXTMAX (1024 * 1024)
/* Sizes the expanded-statement arrays of the macro preprocessor below, and the
 * flagged-statement bitmaps right after this -- which the recorders start
 * marking at note_overlong, long before the preprocessor is declared. */
#define MAXLINES 131072

/* F_S0: the S opcode space with NO operand.  IFOX00's own table is the
 * authority -- ifnx5m.asm describes every operand-bearing mnemonic with an
 * OPND card ahead of its OPCD (206 of them), and exactly two entries carry an
 * OPCD alone: IPK X'B20B' and PTLB X'B20D' (ifnx5m.asm:1562-1563).  With no
 * operand the rest of the card is a remark, so the operand field must not be
 * read at all. */
enum fmt { F_NONE, F_RR, F_RX, F_RS, F_SI, F_SS, F_BR, F_BC, F_SVC, F_S, F_S0 };

struct opc { const char *name; int fmt; int op; int m1; };  /* m1 = implied mask for branch pseudos */
static const struct opc optab[] = {
#include "opc_table.h"
    /* extended branches: BC (RX, op 0x47) / BCR (RR-ish, op 0x07) with implied mask */
    { "B",  F_BC, 0x47, 15 }, { "NOP", F_BC, 0x47, 0 },
    { "BE", F_BC, 0x47, 8 }, { "BNE", F_BC, 0x47, 7 }, { "BH", F_BC, 0x47, 2 }, { "BL", F_BC, 0x47, 4 },
    { "BNH", F_BC, 0x47, 13 }, { "BNL", F_BC, 0x47, 11 }, { "BZ", F_BC, 0x47, 8 }, { "BNZ", F_BC, 0x47, 7 },
    { "BP", F_BC, 0x47, 2 }, { "BM", F_BC, 0x47, 4 }, { "BO", F_BC, 0x47, 1 }, { "BNO", F_BC, 0x47, 14 },
    { "BNP", F_BC, 0x47, 13 }, { "BNM", F_BC, 0x47, 11 },
    { "IPK", F_S0, 0xB20B, 0 }, { "SPKA", F_S, 0xB20A, 0 }, { "STCK", F_S, 0xB205, 0 },
    { "BCT", F_RX, 0x46, 0 }, { "SVC", F_SVC, 0x0A, 0 },
    { "BR",  F_BR, 0x07, 15 }, { "BER", F_BR, 0x07, 8 }, { "BNER", F_BR, 0x07, 7 }, { "NOPR", F_BR, 0x07, 0 },
    { "BHR", F_BR, 0x07, 2 }, { "BLR", F_BR, 0x07, 4 }, { "BNHR", F_BR, 0x07, 13 }, { "BNLR", F_BR, 0x07, 11 },
    { "BZR", F_BR, 0x07, 8 }, { "BNZR", F_BR, 0x07, 7 }, { "BPR", F_BR, 0x07, 2 }, { "BMR", F_BR, 0x07, 4 },
    { "BOR", F_BR, 0x07, 1 }, { "BNOR", F_BR, 0x07, 14 },
    /* BNP and BNM had their BC forms above and not their BR ones. The pair is
     * the same masks -- 13 and 11 -- and IGG0203A and IGC0009D use them
     * (cc370#298). */
    { "BNPR", F_BR, 0x07, 13 }, { "BNMR", F_BR, 0x07, 11 },
    { NULL, 0, 0, 0 }
};

enum stype { S_REL, S_SD, S_PC, S_ER, S_LD, S_ABS };
struct sym { char name[9]; long val; int type; int defined; int esdid; int is_entry; int sect; int len; int is_weak; int opened; };
/* `opened` counts the CSECT/DSECT statements naming this symbol WITHIN the
 * current pass, so both passes can tell a section that BEGINS here from one
 * that is merely resumed. `defined` cannot serve: pass 1 sets it, so by pass 2
 * every section looks resumed -- and the two passes must round the location
 * counter identically or they disagree about every address after it. */
static struct sym syms[MAXSYM];
static int nsym;
/* ESD is a list of (symbol, role) events in source order. A name can appear as
 * BOTH an LD (locally defined entry) and an ER (referenced via =V/EXTRN) — IFOX
 * emits two ESD entries in that case, so roles are tracked separately. */
/* Operand-field width. IFOX00's ceiling is 255 characters and it says so when a
 * field passes it: ifnx1a.asm:4565 `BAL TLINK,WRNERR` / `DC AL1(SEV42)` /
 * ERR42 'EXCEEDS 255 CHARACTERS' / `AH INPTR,H255 CHOP OFF FIRST 255`, and
 * erms.asm:114 ERR105 for a generated field. as370 clamped every field at 63
 * regardless of the caller's array, silently, and then evaluated the truncated
 * text as if it were the whole operand. */
/* A statement buffer. join_cont builds a joined statement into acc[8192], so
 * anything that later holds one has to be that big: every smaller bound on
 * this path is a silent truncation of a statement the joiner assembled
 * correctly (cc370#153). */
/* A macro parameter value.  IFOX00's limit is exactly 255 characters and it
 * says so past it -- IFO042 PARAMETER IN MACRO PROTOTYPE OR MACRO INSTRUCTION
 * EXCEEDS 255 CHARACTERS, severity 8, measured on the guest at 255 (clean),
 * 256, 300 and 400 (flagged).  as370 kept parameter values in 96 bytes,
 * prototype defaults in 40 and &SYSLIST elements in 128, and cut to fit
 * without a word (cc370#153). */
#define MAXPARM 256   /* macro prototype parameters; IDACB2 declares 127 */
#define VALSZ 256
/* A DC address-constant value list: the text inside the parentheses, and the
 * values split out of it.  The two are DERIVED from one another -- the
 * shortest possible value is one character plus its comma, so DCINSIDE/2 is
 * the arithmetic maximum and the pair cannot drift apart.  They used to be 256
 * and 32, and 32 was reachable in valid source: a DC is an assembler operation
 * and gets two continuations, so its operand runs to about 168 characters --
 * room for some 55 short values.  Past the 32nd the value was dropped, the
 * location counter carried on early, and every later address in the section
 * was wrong, all of it silent (cc370#270). */
#define DCINSIDE 256
#define DCVALS (DCINSIDE / 2)
#define STMTSZ 8192
#define FLDW 256

enum esdrole { ESD_SECT, ESD_LD, ESD_ER };
struct esdent { struct sym *s; int role;  int esdid; };
static struct esdent esdord[MAXSYM]; static int nesdord;
/* An ESDID belongs to the ESD ENTRY, not to the symbol. One name can hold two
 * entries -- a control section that is also V-conned by name has both an SD and
 * an ER -- and IFOX00 numbers them separately: HMASMDC2 is SD id 1 and ER id
 * 0x74 in the same deck. as370 kept the id on struct sym, so the ER assignment
 * overwrote the SD's. That is invisible in the RLD's R field, which wants the ER
 * anyway and was right by accident, and wrong in P, which names the section the
 * adcon SITS IN: every RLD entry in the module said P=0x74 where IFOX00 says
 * P=0x0001. And because an ESD card carries ONE starting id with its entries
 * following by position, the clobbered value shifted the whole first card
 * (cc370#199). */

struct lit { char text[FLDW]; long loc; long val; int placed; int isV; int isA; int ltseq; char ext[FLDW]; int size; int algn; int dup; int sect; int defln; int psect; };
/* `sect` is where the literal was first REFERENCED -- it drives USING
 * resolution, and an END pool that moves sections re-stamps it so the
 * reference resolves through a USING covering the section it landed in.
 * `psect` is where the pool actually PLACED it, which is not the same
 * section when an LTORG in a later control section flushes a literal that
 * was used in an earlier one. Only psect may convert loc from its section's
 * own counter to a module address (#136): sect would add the wrong origin. */
static struct lit lits[MAXLIT];
static int nlit;
static int litpool = 0;   /* current literal pool (LTORG/END index); literals dedup only within a pool */

struct reloc { long addr; int pos, rel, isV, len, neg; };
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
/* REPRO: the card AFTER the statement is punched into the object deck exactly as
 * it stands and is not assembled. Measured against IFOX00 (tests/repro.s): the
 * card lands where it was written -- before the ESD block if the REPRO precedes
 * the first control section, otherwise between TXT cards, ending the one that is
 * open -- and it carries NO sequence number of its own, nor does it advance the
 * deck's. ICAPRTBL puts three of them at the top, which is the documented use:
 * IPL text that has to precede the module. */
#define MAXREPRO 64
/* The card is captured from the FILE BYTES and not from the line array: it may
 * hold binary -- ICAPRTBL's is IPL text -- and the line array is C strings, so
 * a card beginning x'00' arrives there empty. Cards holding x'0A' would still
 * be split by the reader; none in the corpus does, and saying so is better than
 * a silent limit. */
static unsigned char repro_raw[MAXREPRO][80];   /* the punched card as it stands in the file */
static int repro_raw_line[MAXREPRO];            /* its 0-based input-line index */
static int nrepro_raw;
static unsigned char repro_img[MAXREPRO][80];   /* the card image, already EBCDIC */
static int repro_line[MAXREPRO];                /* lines[] index of the REPRO statement that captured it */
static int nrepro;
struct punchev { int ridx, before_esd; long at_bytes; };
static struct punchev punches[MAXREPRO]; static int npunch;
static int g_sect_seen;                         /* pass 2: a control section has been established */
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
struct uent { int reg; long base; int sect; int isabs; };   /* active USING ranges; isabs = the base operand was ABSOLUTE */
static struct uent usings[32]; static int nusing;
static int  cur_sect_id, g_sectid;            /* section identity for USING resolution */
/* Per-section content high-water mark.
 *
 * A control section's LENGTH is the extent of what it actually contains. as370
 * used to derive it as "the next section's origin minus this one's", which is
 * the same number only while sections abut exactly -- and they do not, because
 * IFOX00 rounds each new section's origin up to a doubleword (see the CSECT
 * handler) while leaving the length alone. Deriving the length from the next
 * origin would charge that padding to the section before it: in the reporter's
 * module COBWS would come out 16 where IFOX00 says 13 (#61).
 *
 * So each section tracks its own end, updated wherever modlen is -- put(), ORG,
 * DS/DC and the literal pool. Keying on cur_sect_id also keeps a DSECT's
 * contents out of the enclosing control section's total on its own. */
#define MAXSECT 1024
static long sect_hwm[MAXSECT];
static void sect_lc_of(int sect, long end) {
    if (sect > 0 && sect < MAXSECT && end > sect_hwm[sect]) sect_hwm[sect] = end;
}
static void note_sect_lc(long end) { sect_lc_of(cur_sect_id, end); }
/* Per-section location counters, and the origins chained from them.
 *
 * IFOX00 gives each control section its own counter from zero (BLDESD,
 * xdict.asm:85, stores a zero XLCTR) and chains the sections into the module
 * afterwards. as370 used to run ONE continuous counter for the whole assembly,
 * which is the same thing exactly as long as no section is ever RESUMED -- and
 * nothing in the ecosystem corpus resumes one, so the byte-identity gate could
 * not see the difference (#136).
 *
 * Two oracles settle the model. A resumed section continues its own counter
 * (`csect_resume.s`: A comes back at 000004, not after B). And a section's
 * ORIGIN comes from the FINAL lengths, not from the counter as it stood when
 * the section was opened (`csect_resume2.s`: the resumed A grows to 16 and B
 * lands at 000010 = align8(16)) -- which is why origins cannot be assigned
 * during pass 1 at all, and are chained between the passes instead.
 *
 * THE INVARIANT THE TWO-SPACE SCHEME RESTS ON: every origin is align8, and no
 * alignment in the language is coarser than a doubleword. So pass 1's relative
 * lc and pass 2's absolute lc agree in the low three bits, and every alignment
 * decision -- `while (lc & 1)`, DC/DS boundary rounding, the literal pool --
 * pads identically in both passes. Without it the passes would disagree about
 * every address after the first odd-length section, which is precisely what
 * `opened` exists to prevent for the section origins themselves. */
static long sect_org[MAXSECT];    /* absolute origin; 0 until assign_origins() runs between the passes */
static long sect_rel[MAXSECT];    /* the section's OWN counter, always relative to its origin, in both passes */
static long sect_len1[MAXSECT];   /* pass 1 length, captured before pass 2 clears sect_hwm */
static int  sect_ord[MAXSECT], nsect_ord;   /* control sections in order of first definition -- the chaining order */
static long start_base;           /* START operand: where the chain begins (rounded, like any origin) */
/* The END literal pool belongs to the FIRST control section (#68).
 *
 * IFOX00 (xfour.asm, ENDING): "THE FIRST CONTROL SECTION, IF ANY, IS RESUMED AT
 * ITS HIGHEST ADDRESS WHEN END OF FILE IS DETECTED IN PASS 1 ASSIGNMENT MODE AND
 * THE LITERAL POOL IS NOT EMPTY." It saves the location counter and ESDID
 * (LCSAVE), assembles the pool there, and restores them (LCRESTOR) -- so the
 * pool's bytes are PUNCHED last, after every other TXT card, but carry the first
 * section's ESDID and an address inside it, and every section behind the first
 * moves up by what the pool took. "First control section" is FSTCSECT
 * (xdict.asm:113): the first section that is neither DSECT nor COM, private code
 * included; a section RESUMED later does not change it.
 *
 * as370 used to place the pool at whatever `lc` had reached when END was seen,
 * which lands it in the LAST section -- the same place only while the module has
 * one section, which is the whole of the ecosystem corpus. */
static int  first_ctl_sect;   /* internal id of the first control section, 0 = none opened yet */
static int  end_pool_seq;     /* pool index END flushes (= the LTORG count), from the literal pre-scan */
static int  pool_defer;       /* this pass reserved the END pool inside the first control section */
static long pool_org;         /* address the reserved pool starts at */
static char dsect_sect[256];                  /* dsect_sect[id]=1 if section id is a DSECT (its symbols are absolute) */
static int  cur_sect_esdid, main_sect_esdid;
static int  end_esdid; static long end_addr; static int end_has;
static int  errors;
/* The statement being parsed came from a macro expansion (or from open-code
 * substitution). A BLANK in it does not end the operand field: IFOX00 fixes the
 * field boundaries on the MODEL card and substitutes into them, so a variable
 * whose value is a blank stays inside the operand. as370 re-parses the
 * substituted text and stopped at that blank -- `IFDPF1 DS,C,&Z,&S' with &Z a
 * single blank lost BOTH remaining operands, so IFDPF1's &S was empty, an AIF on
 * it took the wrong branch, and PARTITEM was never defined (cc370#302).
 *
 * The mirror of #295: there an operand that substituted to NOTHING had to stay
 * empty, here one that substitutes to a BLANK has to stay in the field. Same
 * root -- the boundaries belong to the model card, not to the result. The remark
 * is already gone by then (#295 cuts it), so the operand is the remainder.
 *
 * It is set from LF_SUBST and NOT from LF_GEN, and the difference is the whole
 * of cc370#305. A card a COPY brings into a macro expansion is generated -- it
 * carries the '+' in the listing -- but nothing is substituted into it and no
 * model card cut its remark off, so its blank ends the operand exactly as an
 * open-code card's does. Reading LF_GEN here made every such card keep its
 * remark: JCOMMON's `JLVTMDT DS 0CL24   ASM LEVEL, TIME, DATE' became four
 * operands, two of them a bare blank, and three IFNX modules IFOX00 assembles
 * clean went to RC 8. Only a remark holding a COMMA shows it, which is why it
 * reached three modules and not three hundred. */
static int  g_genstmt;
static int  g_curln;           /* lines[] index of the statement being assembled -- line context for diagnostics raised from helpers (e.g. sym_get) */
static int  g_pass;            /* the pass do_pass is running, 0 outside it -- x_factor's undefined-symbol diagnostic
                                * must stay silent in pass 1, where a forward reference is not yet defined and legal */
static int  is_dsect_id(int id) { return id > 0 && id < 256 && dsect_sect[id]; }
/* A DSECT owns no address space, so its origin stays 0 and its symbols are
 * never relocated. In pass 1 every counter is relative, so the base is 0
 * there too; only pass 2 adds the origin that was chained in between. */
static long sect_base(int id) {
    if (g_pass != 2 || id <= 0 || id >= MAXSECT) return 0;
    return sect_org[id];
}
static char g_ovl_name[64];     /* set by parse() to the full over-length ORDINARY name-field token (>8, non-&); the assembly loop abandons it (IFO016). Empty when the name field is <=8 or absent. */
static char deck_id[9];        /* name field of the first named TITLE -> deck identifier in cols 73-80 */
static char g_sysdate[9];       /* &SYSDATE  -> "MM/DD/YY" (assembly date) */
static char g_systime[6];       /* &SYSTIME  -> "HH.MM"    (assembly time) */
/* &SYSPARM: the assembly's PARM=SYSPARM() string, and the NULL string when
 * none is given -- which is the case the fixtures and the ecosystem run under,
 * and the one that makes '&SYSPARM'(1,4) an IFO117 rather than four blanks. */
static char g_sysparm[VALSZ] = "";
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

static int hexv(int c);            /* fwd */
static int hex_to_bytes(const char *s, unsigned char *out, int max);   /* fwd */
static int split_fields(const char *s, char f[][FLDW], int max);   /* fwd */

/* An EXTERNAL symbol longer than 8 characters.  MVS object-deck (ESD) names are
 * limited to 8 bytes; Assembler XF (IFOX00) rejects an over-length symbol --
 * ERR187 "SYMBOL LONGER THAN 8 CHARACTERS", severity 8 -- rather than silently
 * truncating it.  as370 used to strncpy the name to 8 on insert while sym_find
 * compared the full name, so a >8 name never matched an existing entry: two
 * distinct names sharing their first 8 characters (PREFIXAB1/PREFIXAB2) both
 * landed under "PREFIXAB" with no diagnostic, silently colliding at link.  We
 * flag each distinct over-length symbol once (severity 8) at its introduction,
 * catching the collision at assemble time where it belongs.
 *
 * This fires only for names that reach sym_get UNtruncated: external symbols
 * named in an ENTRY/EXTRN/WXTRN operand or a =V/=A address constant.  An
 * over-length ordinary symbol in the NAME FIELD (a local label or an EQU name)
 * is capped to 8 earlier, by parse(), so it never reaches this guard -- that
 * separate truncation site is not yet diagnosed (see #32). */
static char ovl_sym[128][64]; static int ovl_ln[128]; static int novl;
/* IFOX00 counts STATEMENTS flagged, not messages.  ERRORTN (ifnx6b.asm:443)
 * holds LSTMTNO, a SINGLE fullword initialised to -1, and increments ERRQTY only
 * when the statement number differs from the immediately preceding one:
 *
 *      C     COUNT,LSTMTNO            IF SAME STATEMENT NUMBER
 *      BE    NOCOUNT                     DON'T COUNT IT AGAIN
 *
 * So the count is adjacent-dedup over the emission order, and because IFOX emits
 * in statement order that comes to "distinct statements".  as370 prints per
 * RECORDER, which is not statement order, so a SET is the faithful reading: it
 * gives the number IFOX would give for the same set of flagged statements.
 *
 * as370 used to sum the per-recorder totals, which counted messages -- five
 * IFO188 over four statements read as "5 Statements Flagged" against the
 * oracle's 4 (#88) -- and counted a statement twice when two different recorders
 * flagged it.
 *
 * Marked in the recorders BEFORE their print caps, so the count survives them.
 * That matters: every one of the ten lists still stops at 128 entries, and a
 * count taken over what was KEPT would be wrong exactly in the modules with the
 * most diagnostics.  cont_stmts(), which counted distinct statements correctly
 * but only over contd[]'s kept entries, had that defect for real.
 *
 * Two key spaces, because continuation diagnostics are raised while cards are
 * being JOINED, before lines[] exists:
 *   stmt_flagged  lines[] index -- as370's own statement identity, so a macro
 *                 expansion's statements count individually, the way IFOX
 *                 numbers them.  (line_org would fold all of them onto the call.)
 *   cont_mark     the raw card number, bit 1 primary source, bit 2 a library
 *                 member.
 * The two are reconciled at report time; see count_flagged_stmts(). */
static unsigned char stmt_flagged[MAXLINES];   /* lines[] index of a flagged statement */
static int nstmt_flagged;
static void mark_flagged(int line) {
    if (line < 0 || line >= MAXLINES || stmt_flagged[line]) return;
    stmt_flagged[line] = 1; nstmt_flagged++;
}
#define CM_PRI 1
#define CM_LIB 2
static unsigned char cont_mark[MAXLINES];      /* card number of a statement with a continuation diagnostic */
static int ncont_pri, ncont_lib;
static void mark_cont_stmt(int card, int inlib) {
    if (card < 0 || card >= MAXLINES) return;
    int bit = inlib ? CM_LIB : CM_PRI;
    if (cont_mark[card] & bit) return;
    cont_mark[card] |= (unsigned char)bit;
    if (inlib) ncont_lib++; else ncont_pri++;
}
static void note_overlong(const char *n) {
    mark_flagged(g_curln);
    int i; for (i = 0; i < novl; i++) if (!strcmp(ovl_sym[i], n)) return;   /* one report per distinct symbol -- an over-length name re-creates on every lookup (never matches sym_find) and again in pass 2 */
    if (novl < 128) { scopy(ovl_sym[novl], n, 63); ovl_ln[novl] = g_curln; novl++; }
}
/* A symbol term that names nothing: not defined in this module and not declared
 * external.  IFOX00 rejects it with IFO188 <symbol> IS AN UNDEFINED SYMBOL
 * (severity 8, erms.asm:193 / jermsgcd.asm SEV188) and assembles the whole
 * machine instruction as ZERO -- an invalid opcode, which S0C1s the moment it is
 * reached.  as370 used to substitute 0 for the term and KEEP the opcode, so the
 * instruction ran: a branch to address 0, a load from base+0, an MVC into offset
 * 0 of whatever the base register happened to hold.  Silent corruption where the
 * guest gives a program check.
 *
 * That silence is how nsf370's two modules lost a DCBD, two EQUs and a whole
 * instruction to the #72 continuation rule without one diagnostic between them:
 * the swallowed cards DEFINED symbols, and every reference to them went quiet
 * (#82).
 *
 * "Undefined" is neither `!sym_find` nor `!defined`.  sym_get enters symbols that
 * are only REFERENCED -- EXTRN/WXTRN, a V-con, a =V literal -- and those keep
 * defined == 0 for the whole assembly, so `!defined` alone would flag every
 * external in the corpus.  They carry S_ER; nothing else undefined does.
 *
 * The pass-2 gate costs one case, in the quiet direction: IFOX resolves EQU in
 * pass 1, so `A EQU B` with B defined further down is IFO188 there and silent
 * here (as370 gives A the pass-1 value 0 and says nothing -- its own defect,
 * adjacent to this one and not fixed by it).
 *
 * The printed list is bounded, the counts are not (the lesson of #72's contd[]:
 * a silent cap let the two diagnostics that mattered fall off the end and took
 * the severity with them).  Dedupe is per (statement, symbol) over the KEPT
 * entries, so past the cap a repeat can be counted twice -- 512 distinct reports
 * in one module is a source file nobody is still reading. */
#define MAXUNDEF 512
static struct { char sym[64]; int line; } undefs[MAXUNDEF];
static int nundef;          /* entries kept for printing */
static int nundef_seen;     /* every one raised */
static void note_undefsym(const char *n, int line) {
    mark_flagged(line);
    int i; for (i = 0; i < nundef; i++) if (undefs[i].line == line && !strcmp(undefs[i].sym, n)) return;
    nundef_seen++;
    if (nundef >= MAXUNDEF) return;
    scopy(undefs[nundef].sym, n, sizeof undefs[0].sym - 1); undefs[nundef].line = line; nundef++;
}
static struct sym *sym_find(const char *n) {
    int i; for (i = 0; i < nsym; i++) if (!strcmp(syms[i].name, n)) return &syms[i];
    return NULL;
}
static struct sym *sym_get(const char *n) {
    struct sym *s = sym_find(n);
    if (s) return s;
    if (nsym >= MAXSYM) { fprintf(stderr, "as370: symbol table full\n"); exit(2); }
    if (strlen(n) > 8) note_overlong(n);   /* flag (IFOX ERR187) rather than silently truncate to 8 */
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
    /* The duplication factor was SKIPPED here and never applied, so `=8X'0F''
     * was one byte rather than eight. That is not only a short literal: the
     * pool is segmented by lenalgn(size), so a literal of the wrong length also
     * lands in the wrong segment, and every literal behind it moves. Sixteen
     * modules came out N bytes short with every later displacement N lower, and
     * seven more had the right length with the wrong order (cc370#317). */
    int dup = 0; while (isdigit((unsigned char)*p)) dup = dup * 10 + (*p++ - '0');
    l->dup = dup > 0 ? dup : 1;
    char ty = toupper((unsigned char)*p++);
    int len = 0, haslen = 0;
    if (*p == 'L') { p++; haslen = 1; while (isdigit((unsigned char)*p)) len = len * 10 + (*p++ - '0'); }
    l->isV = (ty == 'V'); l->isA = (ty == 'A' || ty == 'V' || ty == 'Y');
    if (ty == 'A' || ty == 'V' || ty == 'Y') {
        const char *lp = strchr(p, '('), *rp = strrchr(p, ')');
        if (lp && rp && rp > lp) { int n = (int)(rp - lp - 1); if (n > FLDW - 1) n = FLDW - 1; memcpy(l->ext, lp + 1, n); l->ext[n] = 0; }
        int per = haslen ? len : (ty == 'Y' ? 2 : 4);
        char vv[64][FLDW]; int nv = split_fields(l->ext, vv, 64); if (nv < 1) nv = 1;   /* =AL1(a,b,c): one constant per value */
        l->size = per * nv; l->algn = haslen ? 1 : (ty == 'Y' ? 2 : 4);
    } else if (ty == 'F') { const char *q = strchr(p, '\''); l->val = q ? strtol(q + 1, NULL, 10) : 0; l->size = haslen ? len : 4; l->algn = haslen ? 1 : 4;
    } else if (ty == 'H') { const char *q = strchr(p, '\''); l->val = q ? strtol(q + 1, NULL, 10) : 0; l->size = haslen ? len : 2; l->algn = haslen ? 1 : 2;
    /* Floating point carries no integer value: emit_lit converts the nominal
     * value itself. DCTABLE's default lengths are E 4 / D 8 / L 16, L doubleword
     * like D -- as370 used to have no arm for E or L at all, so both fell into
     * the default below and =L reserved four bytes instead of sixteen, twelve
     * short and in the wrong pool segment (#53). */
    } else if (ty == 'E' || ty == 'D' || ty == 'L') {
        int base = (ty == 'E') ? 4 : (ty == 'D') ? 8 : 16;
        l->size = haslen ? len : base; l->algn = haslen ? 1 : (base == 16 ? 8 : base);
    } else if (ty == 'X') { const char *q = strchr(p, '\''); unsigned char tmp[260]; int nb = q ? hex_to_bytes(q + 1, tmp, 260) : 0; l->size = haslen ? len : nb; l->algn = 1;
    } else if (ty == 'C') { const char *q = strchr(p, '\''); int sl = 0; if (q) { const char *e = q + 1; while (*e) { if (*e == '\'') { if (e[1] == '\'') { sl++; e += 2; continue; } break; }
        if (*e == '&' && e[1] == '&') { sl++; e += 2; continue; }
        sl++; e++; } } l->size = haslen ? len : sl; l->algn = 1;
    } else { l->size = 4; l->algn = 4; }
    if (l->size < 1) l->size = 1;
    l->size *= l->dup;
}
static struct lit *lit_get(const char *t) {
    int i; for (i = 0; i < nlit; i++) if (lits[i].ltseq == litpool && !strcmp(lits[i].text, t)) {
        if (!lits[i].sect) lits[i].sect = cur_sect_id;   /* the pre-scan creates entries with no section; the first real reference stamps it */
        return &lits[i]; }
    if (nlit >= MAXLIT) { fprintf(stderr, "as370: literal table full\n"); exit(2); }
    memset(&lits[nlit], 0, sizeof lits[0]); strncpy(lits[nlit].text, t, sizeof lits[0].text - 1);
    lits[nlit].ltseq = litpool;          /* literal belongs to the current (not-yet-flushed) pool */
    lits[nlit].sect = cur_sect_id;
    lits[nlit].defln = g_curln;          /* the FIRST referencing statement: a literal is assembled at the pool, but a
                                          * diagnostic about its nominal value belongs to the statement that wrote it */
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
/* The body of a C'..' self-defining term: EBCDIC byte values, where `&&' is one
 * `&' and a DOUBLED apostrophe is one apostrophe. Leaves *pp on the closing quote.
 *
 * One function because there were THREE copies of this loop -- the operand
 * evaluator, the SETA reader and the conditional-assembly evaluator -- and every
 * one of them collapsed `&&' while none of them collapsed the doubled
 * apostrophe. So `QUOTE EQU C''''' stopped at the first apostrophe of the pair
 * and evaluated to ZERO, while `DC C''''' was right all along: the DC path has
 * its own scanner and that one knew (cc370#238). Nine modules differed in
 * nothing else at all.
 *
 * The doubling rule is one rule and it now lives in one place, which is the
 * point -- the defect was not the missing branch, it was having three readers
 * of one syntax to keep in step. */
/* Append the low N bits of V, most significant first, to a bit string.
 *
 * A length modifier may be given in BITS -- `DC AL.12(1)' is a twelve-bit
 * field. as370's length parse read `L' and then expected digits, so `.' ended
 * it with a length of ZERO: the constant emitted nothing and moved the location
 * counter by nothing, silently at rc 0, and every symbol after it was early by
 * what was never reserved. That is the mechanism behind cc370#205 -- one
 * control section per module short, both assemblers quiet (cc370#240).
 *
 * The rules, measured on IFOX00 rather than assumed:
 *   consecutive bit operands in one statement PACK contiguously, duplication
 *   factor included; the run is padded ON THE RIGHT to a byte boundary when a
 *   non-bit operand interrupts it or the statement ends; every statement starts
 *   on a byte boundary. `DC AL.3(5)' is A0, `DC AL.12(1),AL2(3)' is 0010 0003,
 *   and `DC 3AL.4(1)' is 1110. */
/* A nominal fixed-point value with a SCALE modifier: the value multiplied by
 * two to the power of the scale, rounded to nearest.
 *
 * `DC FS3'1.25'' is 1.25 x 8 = 10, and `DC FS28'6.2832'' -- the FORTRAN-syntax
 * scientific routines' definition of two pi -- is x'6487FCB9'. as370 read the
 * nominal value with strtol, which stops at the decimal point and knows nothing
 * of the modifier, so it stored 1 and 6 (cc370#217).
 *
 * Rounding is to NEAREST and away from zero, measured on ten values chosen to
 * separate it from truncation: `FS2'1.2'' is 4.8 and IFOX00 writes 5.
 *
 * Only reached when a scale modifier is present. Without one the integer path
 * is untouched, which is the property the tree gate should show and does. */
static long scaled_fixed(const char *t, int scale) {
    /* No <math.h>: pow() and floor() would want -lm on the CI's Linux leg while
     * linking silently on this host, which is the portability trap this project
     * keeps meeting from the other side. Doubling in a loop and truncating
     * toward zero after a half-step gives the same answer for every value the
     * oracle was asked. */
    double f = 1.0; int k;
    while (*t == ' ') t++;
    if (scale >= 0) { for (k = 0; k < scale && k < 64; k++) f *= 2.0; }
    else            { for (k = 0; k < -scale && k < 64; k++) f /= 2.0; }
    double d = strtod(t, NULL) * f;
    return (long)(d >= 0 ? d + 0.5 : d - 0.5);
}
static void bits_put(unsigned char *buf, int bufsz, int *nbits, unsigned long v, int n) {
    int k;
    for (k = n - 1; k >= 0; k--) {
        int idx = *nbits >> 3, off = 7 - (*nbits & 7);
        if (idx < bufsz) {
            if (off == 7) buf[idx] = 0;
            if ((v >> k) & 1UL) buf[idx] |= (unsigned char)(1 << off);
            (*nbits)++;
        }
    }
}
static long selfdef_cbody(const char **pp) {
    const char *p = *pp; long v = 0;
    while (*p) {
        if (*p == '\'') { if (p[1] == '\'') p++; else break; }
        else if (*p == '&' && p[1] == '&') p++;
        v = (v << 8) | mvs_a2e((unsigned char)*p); p++;
    }
    *pp = p; return v;
}
static const char *xp_; static int xrl_;   /* xrl_ = net relocation count of the last expr_val (0 = absolute) */
/* Per-section tally of the same terms.  xrl_ alone cannot tell (A-B) inside one
 * section, which is absolute, from (OTHER-TESTQ) across two, which is not: both
 * net to zero.  IFOX00 accepts the first and rejects the second with IFO206
 * (cc370#133); as370 accepted both silently at RC 0. */
static int xsect_[64], xscnt_[64], xnsect_, xovf_;
/* 1 if every section's relocatable terms cancelled -- i.e. genuinely absolute
 * rather than merely net-zero across different sections. */
static void xsect_tally(int sect, int sign) {
    int k;
    for (k = 0; k < xnsect_; k++) if (xsect_[k] == sect) { xscnt_[k] += sign; return; }
    if (xnsect_ < 64) { xsect_[xnsect_] = sect; xscnt_[xnsect_] = sign; xnsect_++; }
    else xovf_ = 1;                      /* >64 distinct sections: prove nothing */
}
static int xrl_paired(void) {
    int k;
    if (xovf_) return 1;                 /* could not track: do not invent an error */
    for (k = 0; k < xnsect_; k++) if (xscnt_[k]) return 0;
    return 1;
}
static long x_add(void);   /* fwd: additive expression (term +/- term ...) */
static long x_factor(int sign) {
    while (*xp_ == ' ') xp_++;
    if (*xp_ == '(') {                                     /* grouping paren in factor position (e.g. 8+(64-1)); a '(' after a term is a subscript and is left to the caller */
        xp_++; int before = xrl_; xrl_ = 0; long v = x_add(); int delta = xrl_;
        xrl_ = before + (sign < 0 ? -delta : delta);
        while (*xp_ == ' ') { xp_++; } if (*xp_ == ')') xp_++;
        return v;
    }
    if (*xp_ == '*') { xp_++; xrl_ += sign; xsect_tally(cur_sect_id, sign); return lc; }   /* location counter: relocatable, and it belongs to the CURRENT section -- without that (*-HERE) would not pair and the valid case would be rejected */
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
        if (kind == 'C') v = selfdef_cbody(&xp_);
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
    /* IFO188.  Diagnostic only -- the value and the relocation count below are
     * deliberately left as they were, so no deck moves over this: an undefined
     * term still contributes 0, and a table entry that is undefined but present
     * still counts as relocatable exactly as it used to.  The empty name guard
     * matters: the implicit private-code section is entered under "" (sym_get("")
     * in do_pass), and a factor position holding no symbol at all yields "". */
    if (g_pass == 2 && nm[0] && (!s || (!s->defined && s->type != S_ER))) note_undefsym(nm, g_curln);
    if (s) { if (s->type == S_SD || s->type == S_PC || s->type == S_REL || s->type == S_ER) {
                 xrl_ += sign;
                 /* Tally the relocatable terms PER SECTION as well as in total.
                  * xrl_ alone cannot tell (A-B) within one section, which is
                  * absolute, from (OTHER-TESTQ) across two, which is not: both
                  * net to zero.  IFOX00 accepts the first and rejects the second
                  * with IFO206 (cc370#133), and as370 accepted both silently at
                  * RC 0.  An ER has no section and is bucketed under 0 with the
                  * rest, so two DIFFERENT ERs still cancel here -- narrower than
                  * IFOX, and deliberately left that way rather than guessed. */
                 xsect_tally(s->sect, sign);
             }
             return s->val; }
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
    long v = 0;
    xp_ = e; xrl_ = 0; xnsect_ = 0; xovf_ = 0;
    while (*xp_ == ' ') xp_++;
    if (!*xp_ || *xp_ == '(' || *xp_ == ',') { if (reloc) *reloc = 0; }   /* leading '(' = subscript with no displacement prefix */
    else { v = x_add(); if (reloc) *reloc = xrl_; }
    /* Drop the cursor before returning.  Callers hand us stack buffers, so
     * leaving this file-static pointing at one that has just gone out of scope
     * is a dangling store -- harmless today because nothing outside this
     * evaluator reads xp_, but gcc rightly rejects it under -Werror
     * (-Wdangling-pointer, issue #11).  Clearing it costs nothing and makes the
     * lifetime obvious. */
    xp_ = NULL;
    return v;
}
/* expr_val for text that IS an expression, leading parenthesis and all.
 * expr_val's guard reads a leading '(' as a subscript -- correct for a machine
 * operand like (R1), and wrong for a DC duplication factor such as (A-B)/8,
 * which it would silently value at 0.  Same evaluator, without that guard. */
static long expr_val_full(const char *e, int *reloc) {
    long v = 0;
    xp_ = e; xrl_ = 0; xnsect_ = 0; xovf_ = 0;
    while (*xp_ == ' ') xp_++;
    if (*xp_) { v = x_add(); if (reloc) *reloc = xrl_; }
    else if (reloc) *reloc = 0;
    xp_ = NULL;   /* see expr_val: never leave this pointing at a caller's stack buffer */
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
    note_sect_lc(at + n);
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
/* Set when the last split_fields() had to clip a field to FLDW-1.  FLDW-1 is
 * 255, which is exactly IFOX00's limit on a macro parameter, so on the macro
 * paths this flag IS the IFO042 condition -- see mexp_macro and capture_macro.
 * Read it immediately after the call; the next call overwrites it. */
static int g_fld_clipped;
static int split_fields(const char *s, char f[][FLDW], int max) {
    int n = 0, depth = 0, q = 0; const char *start = s, *p = s;
    g_fld_clipped = 0;
    for (;; p++) {
        if (*p == '\'') { if (q || !(p > s && strchr("KNLT", p[-1]))) q = !q; }
        else if (!q && *p == '(') depth++;
        else if (!q && *p == ')') depth--;
        if ((!q && *p == ',' && depth == 0) || *p == 0) {
            int len = (int)(p - start); if (len > FLDW - 1) { len = FLDW - 1; g_fld_clipped = 1; }
            if (n < max) { memcpy(f[n], start, len); f[n][len] = 0; n++; }
            if (*p == 0) break;
            start = p + 1;
        }
    }
    /* Empty every field the operand did not fill.
     *
     * The destination is a stack array reused by the next statement, so an
     * unwritten slot holds the PREVIOUS statement's text at the same address --
     * and a caller that reads a field without checking the count gets it. `SPM
     * R8' is one operand and the RR emitter reads two, so it took its R2 field
     * from whatever RR instruction came before: `SR GR8,GR8' then `SPM GR8'
     * emitted 0488 instead of 0480, and that pair is the standard idiom for
     * clearing the program mask, so real code always supplies the leak.
     *
     * Fixed here rather than at the call site because every consumer of a
     * shorter-than-expected operand list has the same exposure, and only this
     * one was ever going to be noticed -- SPM alone encodes correctly, which is
     * why nothing found it for a year (cc370#252). */
    { int k; for (k = n; k < max; k++) f[k][0] = 0; }
    return n;
}

/* ENTRY/EXTRN/WXTRN operand buffer: a comma-separated external-symbol list.
 * The bound cannot be reached, but NOT for the reason this comment used to
 * give.  It said parse() caps the operand at 1023 characters so 512 fields is
 * the arithmetic maximum; cc370#153 raised that cap to STMTSZ-1 and the
 * arithmetic stopped holding the moment it did.  What holds instead is the
 * SOURCE: ENTRY/EXTRN are assembler operations and get two continuations, so
 * the operand runs to about 168 characters and cannot carry 512 symbols. EXTRN/WXTRN used to pass a
 * local f[8][64], and split_fields drops everything past its maximum without a
 * diagnostic, so the 9th and later symbols of a long EXTRN went missing
 * silently. Shared (and static) because both call sites want the same size and
 * do_pass is not recursive. */
#define MAXEXTSYM 512
static char extsym[MAXEXTSYM][FLDW];
/* split a DC/DS operand list at top-level commas, respecting 'quoted' strings
 * ('' is an embedded quote) and (parenthesised) sub-expressions */
static int dc_split(const char *s, char f[][1024], int max) {
    int n = 0, depth = 0, inq = 0; const char *start = s, *p = s;
    for (;; p++) {
        char c = *p;
        if (inq) { if (c == '\'') { if (p[1] == '\'') { p++; continue; } inq = 0; } }
        /* The apostrophe of L'/K'/N'/T' is an attribute, not a string quote, and
         * this splitter took every one of them for a quote. After an odd number
         * the walk believes it is inside a string, so the next top-level comma
         * stops separating: `DC AL1(L'FLD),X'FF'' lost the X'FF' entirely, at
         * rc 0 with no message. split_fields and the DC value splitter have both
         * carried this test since they were written; dc_split, the third reader
         * of the same syntax, never got it (cc370#218).
         *
         * The test belongs to the OPENING quote only -- inside a string an
         * apostrophe always closes, which is why the `inq' arm runs first. A
         * genuine string ending in one of the letters (`DC C'L'') would
         * otherwise never close. And the set is KNLT, not attr_apos's LTKNISE:
         * IFOX00 reads `S'' and `I'' in an ordinary expression as a quote and
         * says IFO035, so the wider set is right for a card scan and wrong
         * here. */
        else if (c == '\'') { if (!(p > s && strchr("KNLT", p[-1]))) inq = 1; }
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
    if (s[0] == 'C' && s[1] == '\'') return mvs_a2e((unsigned char)s[2]);
    /* expr_val_full: an SI immediate has no subscript, so expr_val's leading-'('
     * guard protects nothing here and only turns MVI DEBLNGTH,(DEBSIZE+7)/8 into
     * X'00'.  IFOX hands the I field to the ordinary expression evaluator
     * (ifnx5m.asm, "X5V - EVALUATE EXPRESSIONS"). */
    return expr_val_full(s, NULL);   /* X'..'/B'..'/decimal/symbol AND arithmetic on them (X'FF'-FLAG) */
}
/* pick the USING covering address val in section sect; returns base reg and
 * displacement. Prefers a same-section USING in range, else any USING in range
 * (so single-USING modules are unaffected), else base 0 / absolute. */
static int r_addrok;  /* the last using_for found a SAME-SECTION USING in range (implicit base is addressable);
                       * 1 by default so an absolute operand -- which never calls using_for -- is never flagged */
static int using_for(long val, int sect, long *disp) {
    int i, best = -1; long bd = 0;
    for (i = 0; i < nusing; i++) { if (usings[i].sect != sect) continue; long dd = val - usings[i].base; if (dd >= 0 && dd < 4096 && (best < 0 || dd < bd || (dd == bd && usings[i].reg > usings[best].reg))) { best = i; bd = dd; } }
    /* r_addrok records whether the operand's OWN section has a covering USING (the
     * same-section pass above). IFOX resolves a relocatable implicit-base operand
     * only then; otherwise it is IFO209 (addressability error). The caller emits
     * IFO209 on !r_addrok. Two things the next person must not trip on:
     *  - Ordering: a future multi-base-register USING (USING X,r12,r11) must add
     *    ALL its base entries to the table BEFORE this runs, or a legitimate >4K
     *    reference (covered by the second register) would wrongly read as IFO209.
     *  - The USING side's section (usings[].sect) is the leading symbol's, not the
     *    net-relocatable term's, so a compound USING base (USING A-B+C,r) could
     *    mis-tag its section here -- a latent symmetric expr_sect gap, adjacent to
     *    the non-simply-relocatable handling in #26. Out of scope for #21. */
    /* Gleichstand: IFOX00 nimmt das HOECHSTNUMMERIERTE Register, nicht den
     * zuerst (oder zuletzt) registrierten Eintrag -- gemessen an zwei Orakeln,
     * tests/basereg.s und tests/basereg2.s (#138). Das zweite ist noetig, weil
     * bei aufsteigend deklarierten USING "hoechstnummeriert" und "zuletzt
     * registriert" dasselbe Register liefern und nichts entscheiden. */
    r_addrok = (best >= 0);
    if (best < 0) for (i = 0; i < nusing; i++) { long dd = val - usings[i].base; if (dd >= 0 && dd < 4096 && (best < 0 || dd < bd)) { best = i; bd = dd; } }
    if (best >= 0) { *disp = bd; return usings[best].reg; }
    *disp = val; return 0;
}
/* An ABSOLUTE operand is addressed through an ABSOLUTE USING, and only through
 * one.  `ISDACVT EQU 0' with its fields as absolute EQUs is how a dummy section
 * was written before DSECT, and `USING ISDACVT,2' then makes register 2 the base
 * for those offsets.  as370 registered such a USING and never consulted it, so
 * it emitted the bare displacement with base 0 -- one nibble, no diagnostic, and
 * a deck that assembles cleanly while addressing absolute storage where IFOX00
 * addresses R2+256 (cc370#190).
 *
 * The two kinds do not mix, which is measured and not assumed: in
 * tests/absusing.s a relocatable `USING *,15' is in force over the whole CSECT
 * and IFOX00 still does not use R15 for the absolute operand, before or after
 * the absolute USING is dropped. So this scans isabs entries only, and a
 * relocatable operand keeps using_for() untouched. Tie-break mirrors using_for:
 * smallest displacement, highest-numbered register (#138). */
static int using_for_abs(long val, long *disp) {
    int i, best = -1; long bd = 0;
    for (i = 0; i < nusing; i++) {
        if (!usings[i].isabs) continue;
        long dd = val - usings[i].base;
        if (dd >= 0 && dd < 4096 && (best < 0 || dd < bd || (dd == bd && usings[i].reg > usings[best].reg))) { best = i; bd = dd; }
    }
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
/* Length attribute an EQU takes from its VALUE when no second operand gives one.
 * It is the L' of the LEFTMOST TERM, and only when that term is a symbol --
 * everything else is 1.  Measured against IFOX00 (tests/equlen.s):
 *
 *   E EQU A     -> L'A      E EQU A+1  -> L'A     E EQU H-A -> L'H
 *   E EQU 4     -> 1        E EQU *    -> 1       E EQU 1+A -> 1
 *
 * `1+A' is the case that fixes the rule: it is the leftmost TERM, not the first
 * symbol anywhere in the expression, so an expression opening with a number
 * gets 1 even though a symbol follows.
 *
 * as370 defaulted the whole family to 1, which is invisible until something
 * reads L' -- and the SS instructions read it as their IMPLIED LENGTH. `MVC
 * @PC00031,0(R1)' assembled as D2 00 where IFOX00 has D2 03, one byte, no
 * diagnostic; the same module's `MVC @PC00031(4),0(R1)' four hundred cards
 * earlier was already right, because an explicit length never consults this
 * (cc370#194). */
static int equ_len_of(const char *e) {
    while (*e == ' ') e++;
    if (*e == '+' || *e == '-') e++;               /* a signed leading term is still that term */
    /* A grouping parenthesis does not hide the leftmost term: IFOX00 gives
     * `E EQU (A+4)' the length of A, and `E EQU ((A))' and `E EQU (A)+4' the
     * same, so the openers are skipped rather than treated as a term of their
     * own (cc370#221).  Only the parenthesis is skipped and not the blank
     * behind it -- `E EQU ( A+4)' is IFO234 PREMATURE END OF EXPRESSION on
     * IFOX00 and its length attribute is 1, which is what falling through to
     * the test below already produces. */
    while (*e == '(') e++;
    if (!(isalpha((unsigned char)*e) || *e=='@' || *e=='#' || *e=='$' || *e=='_')) return 1;
    char nm[64]; int n = 0;
    while (*e && !strchr("+-*/(), ", *e) && n < 63) nm[n++] = *e++;
    nm[n] = 0;
    if (*e == '\'') return 1;                      /* X'..'/C'..' -- a self-defining term, not a symbol */
    struct sym *s = sym_find(nm);
    return (s && s->defined) ? s->len : 1;
}
/* section of a relocatable expression = section of its NET-relocatable term.
 * e.g. IOBSENS0-IOBSTDRD+TAPEIOB: the two IOB fields cancel (same section), so
 * the result is in TAPEIOB's section, not IOBSENS0's. Falls back to cur_sect_id.
 * Sums the sign of each relocatable (non-absolute) symbol term per section and
 * returns the section with a net positive count. */
/* Every section the expression names, with its NET signed term count.
 *
 * `A-B' where A and B live in different control sections is not absolute: its
 * value depends on where the linkage editor puts each of them, and IFOX00 says
 * so with a SIGNED PAIR of relocation entries -- negative for the subtracted
 * section, positive for the added one (cc370#209). Measured: `A(B1+B2)' with
 * both terms in one section gets TWO positive entries, so the rule is one entry
 * per UNIT of the tally, not one per section; `A(A1-B1+B1)' gets one, because
 * B cancels; and a difference INSIDE one section gets none, which is the case
 * that makes the whole construct absolute.
 *
 * expr_sect() itself only ever wanted one section out of this, and threw the
 * tally away. It is the same walk, with the result kept. */
static int expr_sect_terms(const char *f, int *tsect, long *tsign, int max) {
    int nt = 0, k;
    const char *p = f; int sign = 1, expect = 1;
    while (*p) {
        if (*p == ' ') { p++; continue; }
        if (*p == '+') { if (!expect) sign = 1; expect = 1; p++; continue; }
        if (*p == '-') { if (!expect) sign = -1; expect = 1; p++; continue; }
        if (*p == '/') { p++; expect = 1; continue; }
        if (*p == ',') { p++; sign = 1; expect = 1; continue; }     /* multi-value term separator */
        if (*p == '*' && !expect) { p++; expect = 1; continue; }   /* binary multiply */
        if (*p == '(') { int d = 1; p++; while (*p && d) { if (*p == '(') d++; else if (*p == ')') d--; p++; } continue; }
        if (*p == ')') { p++; continue; }
        int csect = -1;
        if (*p == '*') { csect = cur_sect_id; p++; }               /* location counter term */
        else { char nm[64]; int n = 0; while (*p && !strchr("+-*/(), ", *p) && n < 63) nm[n++] = *p++; nm[n] = 0;
            /* A character this walk neither consumes above nor accepts into a
             * name leaves p where it was, and the loop never ends. `,' was
             * exactly that (cc370#215): HEWLDIOC reaches it through resolve() on
             * an ordinary machine operand and has never assembled. A DC nominal
             * value carries commas routinely, so the caller added below reaches
             * it far more often -- which is how a single-module curiosity turned
             * into an immediate hang and got found. reloc_sym walks the same
             * syntax and has carried this advance since it was written. */
            if (!n) { p++; continue; }                             /* unhandled char: advance to guarantee progress */
            if (nm[0] && !isdigit((unsigned char)nm[0])) { struct sym *s = sym_find(nm); if (s && s->type != S_ABS) csect = s->sect; } }
        if (csect >= 0) { int f2 = -1; for (k = 0; k < nt; k++) if (tsect[k] == csect) { f2 = k; break; }
            if (f2 < 0 && nt < max) { f2 = nt; tsect[nt] = csect; tsign[nt] = 0; nt++; }
            if (f2 >= 0) tsign[f2] += sign; }
        sign = 1; expect = 0;
    }
    return nt;
}
static int expr_sect(const char *f) {
    int tsect[8]; long tsign[8]; int k;
    int nt = expr_sect_terms(f, tsect, tsign, 8);
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
static int r_reloc;   /* the displacement prefix of the last resolve() was relocatable (a symbol) */
static int r_subempty;  /* bit k set when subscript k of the last resolve() was WRITTEN BUT EMPTY --
                         * `A(,5)' is not `A(0,5)', and an SS length field distinguishes them */
static long r_raw;    /* its un-reduced value (before USING subtraction); the displacement IFOX prints in ADDR1 */
/* The displacement prefix of a machine operand.
 *
 * expr_val's leading-'(' guard is right for a bare register operand `(R1)'
 * and wrong for a PARENTHESISED DISPLACEMENT, which IFOX00 reads as an
 * ordinary group: `LA 1,(4-1)' is displacement 3 and `L 15,(FIELD-BASE)(9)'
 * is displacement 16 with 9 as the index (cc370#247). By the time this is
 * called the subscript has already been located positionally, so there is
 * nothing left here for that guard to protect against -- and with it the
 * displacement came out ZERO, silently, at rc 0. */
static long disp_val(const char *e, int *reloc) {
    while (*e == ' ') e++;
    return (*e == '(') ? expr_val_full(e, reloc) : expr_val(e, reloc);
}
static void resolve(const char *f, long *d, long sub[4], int *nsub, int *sym) {
    *nsub = 0; *sym = 0; *d = 0; r_ibase = -1; r_len = 0; r_reloc = 0; r_raw = 0; r_addrok = 1; r_subempty = 0;
    if (f[0] == '=') { struct lit *l = lit_get(f); *sym = 1; r_len = l->size; sub[0] = using_for(l->loc, l->sect, d); return; }
    /* The subscript list, if there is one -- NOT merely the first '('.  A
     * displacement expression may be parenthesised for grouping:
     *   SLL R11,24-(8*((ASCBFLG1-ASCBAFFN)-(((ASCBFLG1-ASCBAFFN)/4)*4)))
     * has no subscript at all, and reading its grouping paren as one gave a
     * wrong base register at rc 0 (IEAVRTI1, four statements).  The rule is
     * positional, not lexical: a subscript follows a complete TERM, a group
     * follows an OPERATOR.  Skip a group's whole span and keep looking at depth
     * 0; if nothing is left the operand is one expression and takes the branch
     * below, where x_factor handles the grouping itself.
     *
     * A '(' at the very START is a GROUP, not a subscript -- the operand begins
     * where an operator would leave off, so the same positional rule already
     * decides it and the old exception for `q == f' was simply wrong. Measured
     * on IFOX00 (cc370#247):
     *
     *   LA 1,(2)                 4110 0002   displacement 2, NOT base 2
     *   LA 1,(4-1)               4110 0003
     *   L  15,(FIELD-BASE)(9)    58F9 0010   the SECOND group is the subscript
     *   L  15,(FIELD-BASE)(,9)   58F0 9010
     *
     * as370 read the leading group as the subscript list, so the displacement
     * was lost with it: `L 15,(FIELD-BASE)(9)' came out 58F0 0000 -- base 0,
     * displacement 0, at rc 0 and silent on both sides. `LA 1,(4-1)' was worse,
     * taking 3 for a BASE REGISTER. 68 modules, and most reach it through a
     * macro rather than writing it. */
    const char *lp = NULL;
    { int d0 = 0, expect = 1; const char *q = f;   /* expect: the next token would be a TERM, so an operator was the last thing seen */
      for (; *q; q++) {
          if (*q == ' ') continue;
          if (*q == '\'') {                       /* C'(' must not be read as a paren; an attribute apostrophe (L'SYM) has no closing one and belongs to the term */
              if (q > f && strchr("LTKNIS", q[-1])) continue;
              q++; while (*q && *q != '\'') q++;
              if (!*q) break;
              expect = 0; continue;
          }
          if (*q == '(') {
              /* A subscript follows a complete term; a group follows an
               * operator.  '*' decides by position, which is why a character
               * test is not enough: in `BC 15,*(RP)` it is the location counter
               * and (RP) IS the subscript, in `24-(8*X)` it is a multiply. */
              if (d0 == 0 && !expect) { lp = q; break; }
              d0++; continue;
          }
          if (*q == ')') { if (d0) d0--; expect = 0; continue; }
          if (*q == '+' || *q == '-' || *q == '/' || *q == ',') { expect = 1; continue; }
          if (*q == '*') { expect = !expect; continue; }   /* location counter in term position, multiply after one */
          expect = 0;
      } }
    if (lp) {
        int reloc = 0; long v = disp_val(f, &reloc);   /* prefix before '(' (the evaluator stops there) */
        if (reloc) {                                   /* SYM(len)/SYM(index): base from the symbol's USING */
            char nm[64]; int nn = 0; const char *e = f; while (*e && !strchr("+-*/(), ", *e) && nn < 63) nm[nn++] = *e++; nm[nn] = 0;
            struct sym *s = sym_find(nm); int ssect = expr_sect(f);
            r_len = s ? s->len : 0;
            r_reloc = 1; r_raw = v;
            r_ibase = using_for(v, ssect, d);
        } else {
            *d = v;                                    /* numeric displacement, e.g. 4+120(13) */
            /* An ABSOLUTE displacement still has a length attribute, and an SS
             * operand with an omitted length needs it. `PRFTIC-IEDQPRF(,R5)' is a
             * difference of two symbols in one dummy section, so the prefix is
             * absolute and this branch runs -- but IFOX00 takes L' of the leading
             * term exactly as it would for a relocatable one. Leaving r_len at 0
             * sent every such operand out with a length byte of 0 (cc370#201).
             * equ_len_of() is the same leftmost-term rule #194 measured, and it
             * answers 1 for a genuinely numeric prefix like `4+120(13)'. */
            r_len = equ_len_of(f);
        }
        /* The MATCHING close paren, not the first one.  A subscript may itself
         * be parenthesised -- `LA 2,4((3),5)`, the form a macro produces when a
         * register argument arrives as (3) -- and strchr() stopped at the inner
         * ')', so the list read as "(3" instead of "(3),5": the index evaluated
         * to 0 and the base was never seen at all, giving 41 20 0004 where
         * IFOX00 has 41 23 5004.  Silently, at rc 0 (cc370#169). */
        const char *rp = NULL;
        { int d2 = 0; const char *q2 = lp;
          for (; *q2; q2++) { if (*q2 == '(') d2++; else if (*q2 == ')') { if (--d2 == 0) { rp = q2; break; } } } }
        int n = rp ? (int)(rp - lp - 1) : (int)strlen(lp + 1);
        char inside[FLDW]; if (n > FLDW - 1) n = FLDW - 1; memcpy(inside, lp + 1, n); inside[n] = 0;   /* the subscript span, at the operand ceiling: a 43-character length expression was cut at 31 mid-symbol (IEDQAU) */
        char *tok = inside;
        while (1) {
            char *cm = NULL;                                       /* the separator is a TOP-LEVEL comma: (3),5 is two subscripts, not three */
            { int d3 = 0; char *q3 = tok;
              for (; *q3; q3++) { if (*q3 == '(') d3++; else if (*q3 == ')') { if (d3) d3--; } else if (*q3 == ',' && !d3) { cm = q3; break; } } }
            int len = cm ? (int)(cm - tok) : (int)strlen(tok);
            char t[FLDW]; if (len > FLDW - 1) len = FLDW - 1; memcpy(t, tok, len); t[len] = 0;
            /* eval_reg, not expr_val: a subscript may be written (3), and
             * expr_val reads a leading '(' as a subscript of its own and returns
             * 0.  eval_reg already strips a fully-enclosing pair for exactly this
             * -- it was written for `LR 0,(3)` and never reached from here.  A
             * token that merely STARTS with '(' without being enclosed by it
             * falls through to expr_val unchanged, so nothing else moves. */
            if (*nsub < 4) { if (!t[0]) r_subempty |= 1 << *nsub; sub[(*nsub)++] = t[0] ? eval_reg(t) : 0; }   /* base/index may be a symbol (R13 EQU 13) */
            if (!cm) break;
            tok = cm + 1; }
    } else {
        int reloc = 0; long v = disp_val(f, &reloc);
        if (reloc) {                                   /* relocatable: address via USING (of the symbol's section) */
            char nm[64]; int n = 0; const char *e = f; while (*e && !strchr("+-*/(), ", *e) && n < 63) nm[n++] = *e++; nm[n] = 0;
            struct sym *s = sym_find(nm); int ssect = expr_sect(f);
            r_len = s ? s->len : 0;
            r_reloc = 1; r_raw = v;
            *sym = 1; sub[0] = using_for(v, ssect, d);
        } else {   /* absolute: a base only if an ABSOLUTE USING covers it, else the bare displacement */
            /* Same as the subscripted case below: an absolute displacement still
             * has a length attribute, and an SS operand written with no subscript
             * at all reads it. `CLC PSAAOLD-PSA,...' in IGC121 is a difference in
             * one dummy section, so it lands here rather than in the relocatable
             * branch, and leaving r_len at 0 gave it a length byte of 0 where
             * IFOX00 has 3 (cc370#201). */
            r_len = equ_len_of(f);
            int ab = using_for_abs(v, d);
            /* *sym tells the caller how to read sub[0] -- base when set, INDEX
             * when clear.  Setting it only for ab != 0 keeps the ordinary
             * absolute operand on exactly its old path: with no absolute USING
             * in force the caller computed b = 0 already, so nothing moves. */
            *sym = (ab != 0); sub[0] = ab;
        }
    }
}

/* parse a statement into label / opcode / operand. The operand field ends at
 * the first blank that is NOT inside a quoted string (so DC C'A B' works); the
 * trailing comment is dropped.
 *
 * BUFFER CONTRACT -- the caller must provide lbl[32], op[16], opnd[STMTSZ].
 * parse writes up to 30 characters of label (a variable symbol with a subscript
 * runs past the ordinary 8), 8 of opcode, and STMTSZ-1 of operand. Two callers used
 * to pass opnd[128], which is fine for one 80-column card and NOT fine for a
 * continued statement: continuations are folded before a macro library is read,
 * so a macro body carrying a multi-card statement overflowed the stack.
 * SYS1.MACLIB's DCB has seven such statements, the longest 1376 characters, and
 * the corruption showed up as that macro silently taking the wrong conditional
 * branch and generating a DCB twelve bytes short (#63). */
/* An apostrophe that opens a quoted string, or one that merely introduces an
 * ATTRIBUTE -- the ' in L'A, T'&V, K'&SYSPARM. The card splitters used to
 * toggle quote state on every apostrophe alike, so an operand carrying an
 * attribute reference had an odd count, the state never closed, and the whole
 * remarks field was swallowed into the operand (mvslovers/cc370#149). That was
 * invisible while every field was substituted anyway; it stops being invisible
 * the moment the remarks field must be left alone.
 *
 * An attribute letter stands ALONE. The character before it must not be part of
 * a longer token, or two ordinary strings are misread: `DC C'L'` closes on its
 * own quote, and `DC CL&A'&E'` -- SAVE's identifier card, and the one that
 * caught this -- ends in the 'A' of the VARIABLE SYMBOL &A, where the quote
 * opens a string. So '&' bars the reading exactly as a letter does. */
static int attr_apos(const char *card, int i) {
    /* The set is IFOX00's own -- `T L I S N K' at ifnx1a.asm:4862 -- and it does
     * NOT contain E. Assembler XF has no E' attribute, but E IS a constant type,
     * so `DC E'1.0'' opened no string here: the closing quote then toggled the
     * state on instead of off, the operand never ended at a blank, and the
     * REMARK became part of it. A comma anywhere in that remark split it into a
     * second constant and the statement was rejected -- rc 8 and IFOX00 assembles
     * the same card at rc 0 with the same bytes, which is a false positive rather
     * than a missed error (cc370#223). */
    if (i < 1 || !strchr("LTKNIS", card[i-1])) return 0;
    if (i >= 2) { char b = card[i-2];
        if (isalnum((unsigned char)b) || b=='@' || b=='#' || b=='$' || b=='_' || b=='&') return 0; }
    return 1;
}
static int parse(const char *line, char *lbl, char *op, char *opnd) {
    const char *p = line; int i;
    lbl[0] = op[0] = opnd[0] = 0;
    g_ovl_name[0] = 0;
    /* Both comment forms, the way card_op_is() below already reads them: a card
     * with '*' in column 1, and the macro-language '.*', which is a comment
     * everywhere -- inside a macro definition as well as in open code (IFOX
     * ifnx1a.asm:589 routes both into the comment edit before any operation
     * field is scanned).  Missing '.*' here let capture_macro() take the word
     * MEND out of a '.* MEND' prose card as the operation field and end the
     * definition there: AMODGEN(IECDSECS) card 131 quotes a sample macro that
     * way, so 130 of its 1672 cards survived and FORCORE/WTG/UCB/IHADCB and the
     * whole IECDSECT tail were never generated. */
    if (*p == '*' || (*p == '.' && p[1] == '*')) return 0;
    if (*p != ' ' && *p != '\t' && *p != '\n' && *p != 0) {
        /* ordinary symbol labels cap at 8; a variable-symbol label may carry a
         * subscript (&ARR(&IDX)) and run longer, so allow the full token there. */
        int cap = (*p == '&') ? 30 : 8;
        const char *nb = p; int full = 0;
        i = 0; while (*p && !isspace((unsigned char)*p)) { if (i < cap) lbl[i++] = *p; p++; full++; } lbl[i < cap ? i : cap] = 0;
        /* An ordinary name field longer than 8 is illegal (IFOX IFO016); record the
         * FULL token so the assembly loop can abandon the name.  lbl still holds the
         * 8-char truncation for macro-time callers, which ignore g_ovl_name. */
        if (cap == 8 && full > 8) { int m = full < 63 ? full : 63, k; for (k = 0; k < m; k++) g_ovl_name[k] = nb[k]; g_ovl_name[m] = 0; }
    }
    while (*p == ' ' || *p == '\t') p++;
    if (!*p || *p == '\n') return op[0] != 0;
    i = 0; while (*p && !isspace((unsigned char)*p)) { if (i < 8) op[i++] = *p; p++; } op[i < 8 ? i : 8] = 0;
    while (*p == ' ' || *p == '\t') p++;
    if (!*p || *p == '\n') return 1;
    i = 0; { int q = 0, d = 0; while (*p && *p != '\n') {
        /* An ATTRIBUTE apostrophe is not a quote (#149).  Toggling on it left the
         * state inverted for the rest of the statement, so the first blank read
         * as "inside a string", the operand never ended, and the remarks field
         * was swallowed.  On a machine instruction that is invisible -- the
         * evaluator stops at the real operand end and ignores the tail -- but on
         * a MACRO CALL the tail becomes part of a parameter:
         *
         *   MYM   L'A,XX          BEMERKUNG
         *
         * passed `XX          BEMERKUNG' as &B, and `DC C'&B'' assembled 21
         * bytes where IFOX00 assembles 2 (tests/attrapos.s).  split_card() has
         * had attr_apos() since #141; parse(), which decides the operand that is
         * actually ASSEMBLED, was left on the bare toggle.
         *
         * The `q ||' is not decoration and attr_apos() does not imply it: the
         * predicate is purely lexical, so it reads the CLOSING quote of a string
         * whose last character is an attribute letter as an attribute apostrophe.
         * `READ MAPDECB,SF,(R3),(REG0),'S' READ RECORD INTO BUFFER' (AMDPREAD
         * card 327) ends in 'S' preceded by the opening quote, and without the
         * guard the string never closed, the remark joined the macro's operands,
         * and MAPDECB was never defined. Inside a string an apostrophe can only
         * ever close it -- 96 decks lost their identity to that omission before
         * the gate caught it. The same guard is already spelled out at the
         * other attribute-aware scans (`q || !(p > s && strchr("KNLT", ...))').
         * split_card() calls attr_apos() WITHOUT it and has the same latent
         * reading; it cannot move a deck, so it is left for #141's owner. */
        if (*p == '\'') { if (q || !attr_apos(line, (int)(p - line))) q = !q; }
        else if (!q && *p == '(') d++;
        else if (!q && *p == ')') { if (d) d--; }
        if (!q && d == 0 && !g_genstmt && (*p == ' ' || *p == '\t')) break;
        if (i < STMTSZ - 1) opnd[i++] = *p;
        p++;
    } }
    /* A generated statement's operand runs to the end of the text rather than to
     * the first blank, so the card's padding to column 71 comes with it. The
     * field ends where the text does; trailing blanks were never part of it. */
    if (g_genstmt) while (i > 0 && (opnd[i-1] == ' ' || opnd[i-1] == '\t')) i--;
    opnd[i] = 0;
    return 1;
}
static const struct opc *op_find(const char *n) {
    int i; for (i = 0; optab[i].name; i++) if (!strcmp(optab[i].name, n)) return &optab[i];
    return NULL;
}
/* ESDID of the control section a symbol's internal section id belongs to, or 0
 * when it does not name one (an id never assigned, or a DSECT -- dummy sections
 * get no ESD entry). Separate from sect_esdid() below, which substitutes the
 * module's first section: here the caller has to see "unresolved" so it can keep
 * its own fallback. */
static int sect_esdid_of(int sect) {
    int k; if (!sect) return 0;
    for (k = 0; k < nesdord; k++)
        if (esdord[k].role == ESD_SECT && esdord[k].s->sect == sect) return esdord[k].s->esdid;
    return 0;
}
static int sect_esdid(int sect) {                   /* ESDID of the control section with this internal id (for an LD's owning section), else the module's first */
    int e = sect_esdid_of(sect);
    return e ? e : main_sect_esdid;
}
/* `len' is the WIDTH of the address constant, and it is a parameter rather than
 * something the caller pokes in afterwards.  Every call site used to read
 *
 *     add_reloc(lc, r, 1); rels[nrel - 1].len = blen;
 *
 * which is wrong whenever add_reloc adds nothing: the write then lands on the
 * PREVIOUS entry.  It bails on `in_dsect', and an address constant inside a
 * DSECT is ordinary -- IEAVELCR calls it 24 times for real and 138 times from
 * dummy sections, so the last real relocation was overwritten 138 times and kept
 * whatever width the final DSECT constant happened to have.  That is one bit of
 * one flag byte (0x04, the low bit of length-1) in an otherwise byte-identical
 * deck, on 173 modules, and almost always the LAST entry because the clobber
 * target is always rels[nrel-1] (cc370#186). */
static void add_reloc(long at, const char *target, int isV, int len) {
    if (in_dsect) return;                       /* a dummy section generates no relocations */
    struct sym *s = sym_find(target);
    /* R, the relocation ESDID, names the section whose origin the linkage editor
     * adds to the stored value -- so it must be the section the TARGET lives in,
     * not the one the adcon sits in. A section (SD/PC) or an external reference
     * (ER) carries its own ESDID and is used directly. An ordinary label and an
     * ENTRY (LD) carry none, and used to fall straight through to the current
     * section: correct in a single-CSECT module, wrong the moment a DC A(...)
     * names a label in a sibling CSECT (#52). Resolve those through the owning
     * section, and keep the old fallback for a target whose section does not
     * resolve to an ESD entry at all -- an unset id, or a DSECT symbol reaching
     * a call site that does not filter them. */
    /* A V-con names an EXTERNAL, so it relocates against the ER entry even when
     * the symbol is also defined here as a control section. HMASMDC2 V-cons its
     * own CSECT name: IFOX00 puts the ER's id (0x74) in R and the SD's (1) in P,
     * and the two are different entries for one name. For an ordinary external
     * the symbol has only an ER, so this returns exactly what s->esdid holds and
     * nothing moves. */
    int rel = 0;
    if (s && isV) { int q; for (q = 0; q < nesdord; q++) if (esdord[q].s == s && esdord[q].role == ESD_ER) { rel = esdord[q].esdid; break; } }
    if (!rel) rel = (s && s->esdid) ? s->esdid : 0;
    if (!rel && s) rel = sect_esdid_of(s->sect);
    if (!rel) rel = cur_sect_esdid;
    if (nrel >= MAXREL) { fprintf(stderr, "as370: reloc table full\n"); exit(2); }
    rels[nrel].addr = at; rels[nrel].pos = cur_sect_esdid; rels[nrel].rel = rel; rels[nrel].isV = isV;
    rels[nrel].len = len; rels[nrel].neg = 0; nrel++;
}
/* One relocation against a SECTION rather than a symbol, with a direction.
 *
 * add_reloc() resolves R from the target's name, which is what an ordinary
 * address constant wants. A cross-section difference has no single target: each
 * section named in the expression is relocated in its own direction, so the
 * caller has section ids and a sign, not a name (cc370#209). */
static void add_reloc_sect(long at, int sect, int len, int neg) {
    if (in_dsect) return;                       /* a dummy section generates no relocations */
    if (dsect_sect[sect & 255]) return;         /* nor does a term that lives in one */
    int rel = sect_esdid_of(sect);
    if (!rel) rel = cur_sect_esdid;
    if (nrel >= MAXREL) { fprintf(stderr, "as370: reloc table full\n"); exit(2); }
    rels[nrel].addr = at; rels[nrel].pos = cur_sect_esdid; rels[nrel].rel = rel; rels[nrel].isV = 0;
    rels[nrel].len = len; rels[nrel].neg = neg; nrel++;
}
static int ins_len(int fmt) { return (fmt == F_RR || fmt == F_BR || fmt == F_SVC) ? 2 : (fmt == F_SS) ? 6 : 4; }

/* ---- WP-4 macro preprocessor --------------------------------------------- */
/* per-expanded-line listing flags, parallel to the flattened lines[] array */
#define LF_GEN   1     /* macro-generated statement (listed with '+') */
#define LF_NOASM 2     /* listing-only (e.g. the macro call line): shown, not assembled */
/* The operand text came out of a SUBSTITUTION, so its field boundaries were
 * fixed on the model card and a blank inside it is not a field end (see
 * g_genstmt). Not the same thing as LF_GEN: a card a COPY brings into a macro
 * expansion is generated -- it is listed with the '+' -- but nothing was
 * substituted into it, so its blank ends the operand like any other card's. */
#define LF_SUBST 4
static unsigned char lflags[MAXLINES];
static int g_genlevel;  /* >0 while inside a macro expansion (distinguishes generated lines from COPY'd source) */
static int g_copyraw;   /* >0 while expanding a COPY'd member: nothing has been substituted into its cards yet */
struct ctx;
static struct ctx *g_copyctx;   /* the enclosing expansion's variables, for a COPY'd card's substitution (see #307) */
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
/* The lines[] slot a conditional-assembly diagnostic attaches to, or -1 when no
 * statement is being evaluated. A SETC substring error has no statement of its
 * own to point at otherwise: eval_setc is three calls below the card, and the
 * recorders address a statement by its lines[] index. Armed by mexp_line for an
 * open-code CA statement and by mexp_macro for one in a macro body -- the macro
 * CALL line in that case, which is the card line_org already reports. */
static int g_ca_slot = -1;
static int g_mcall_slot = -1;  /* the macro CALL line's slot, for a diagnostic raised inside the body */
static void note_operr(const char *msg, int sev, int line);   /* fwd: eval_setc raises IFO115/116/117 */
static int prelen_of(const char *nm);                         /* fwd: L' in conditional assembly (#244) */
static void note_mnote(int sev, const char *text, int line);  /* fwd: the macro expander raises MNOTE */
static int mnote_split(const char *opnd, char *text, int textsz, char *image, int imagesz, int *comment);
/* source-file line number each expanded line derives from (for diagnostics): an
 * open-code statement -> its own line; a macro/COPY-generated line -> the line of
 * the call/COPY in the input file. g_curorg is the line currently being expanded. */
static int line_org[MAXLINES];
static int g_curorg;
struct macro {
    char namep[20], name[16];
    /* A macro prototype's parameters.  SYS1.MACLIB(IDACB2) declares 127 and
     * DCB 96, so 100 was reachable -- and reaching it is not quiet any more:
     * a parameter past the cap was dropped, so every CALL passing that
     * keyword then looked undeclared and raised IFO092 against a macro that
     * declares it perfectly well.  27 modules did exactly that the moment
     * #162's diagnostic went in (cc370#292). */
    char pname[MAXPARM][20], pdef[MAXPARM][VALSZ]; int pkey[MAXPARM]; int nparm;
    /* The body GROWS. It used to be two fixed 4,096-entry arrays and the append
     * was guarded by `if (m->nbody < 4096)' with nothing said, so a longer
     * definition was silently cut: NETSOL is 6,881 cards, and ISTNSC00 -- which
     * calls it -- lost two whole control sections, 24,909 bytes of object, at
     * rc 8 with the diagnostics pointing at symbols the cut had eaten
     * (cc370#287). Growing also SAVES memory: 256 slots x 8,192 pointers was
     * 16 MB of static array for bodies that are typically a few dozen cards. */
    char **body; char **bodyseq; int nbody, bodycap;
    char endlbl[20];               /* sequence symbol on the MEND line, if any */
};
static struct macro macros[256];
static int nmac;
static struct macro *mac_find(const char *n) {
    int i; for (i = 0; i < nmac; i++) if (!strcmp(macros[i].name, n)) return &macros[i];
    return NULL;
}
/* ---- macro expansion context + conditional assembly --------------------- */
/* &SYSECT is the control section in effect WHERE THE MACRO WAS CALLED, and it
 * does NOT follow a section change made inside the expansion.  Measured on
 * IFOX00 (cc370#132): a macro that opens INNER CSECT in its own body still gets
 * FOURTH -- the section it was called from -- on the line after.  So there are
 * two values: g_sysect runs with the emitted statements, and each invocation
 * freezes a copy of it at entry.  Looking the section up when the reference is
 * resolved is the obvious implementation and it is wrong, the same way resolving
 * an absolute S-con through USING was wrong in #108.
 *
 * A DSECT counts as the current section; an unnamed (private) one gives "". */
static char g_sysect[9] = "";

/* Positional operands storable per macro call. Chosen from the tree rather than
 * guessed: the most any MVSBLD module passes is 62 (the IFNX5 and IFNX6
 * families), and 32 modules of 5,046 pass more than the 32 this used to hold. Above the
 * bound the operand used to be dropped SILENTLY -- `pos++' ran outside the
 * guard, so the count stayed right while &SYSLIST(k) came back empty. It is a
 * diagnostic now, because a bound that is exceeded quietly is the defect this
 * one was. */
/* A subscripted SET symbol is ONE row holding a vector of elements, not one row
 * per assigned subscript. `GBLC &ITEM(3000)' used to cost up to 3,000 rows in a
 * linearly scanned table: measured on IFCE0155, 6,739 of its 6,757 global rows
 * were array elements and only 18 were plain symbols, and set_find walked that
 * table 91,000 times for 98 million string comparisons. The same storage is why
 * `LCLB &SW(4000)' filled a 512-row local table at the 513th assigned subscript
 * (cc370#173).
 *
 * Elements are allocated on ASSIGNMENT, never on declaration -- GBL/LCL of an
 * array records the base name and creates no row, which is what makes declaring
 * &SW(4000) free. `eset' distinguishes an element that was assigned the empty
 * string from one never assigned, which the declared default depends on. */
struct setrow { char name[20]; char val[VALSZ]; char (*elem)[VALSZ]; unsigned char *eset; int nelem; };
/* Local SET symbols per macro context. 256 was too small by a little: IFCEOAK1
 * needs 295, IFCEXXXF 303, IFCSXXXG 288 -- and the ones that reach these numbers
 * only reach them once N'&SYSLIST stops cutting their loops short, so the old
 * bound had been hidden behind that defect.
 *
 * The number is deliberately modest and the bound is now written ONCE. It was
 * written twice -- the array said 256 and the check said 256 independently --
 * which is how a capacity limit drifts: raising one and not the other changes
 * nothing and looks like it did.
 *
 * Be sparing here for a reason that is a PRODUCT, not an absence. Nesting IS
 * bounded -- mexp_line's macro lookup is guarded by `depth <= 40' (and COPY the
 * same) -- so this is not unguarded recursion; an earlier version of this
 * comment said it was, which came from grepping for `depth >' and concluding
 * from a miss. What matters is that `struct ctx' rides a stack frame of about
 * 124 KB together with mexp_macro's seqn/seqi pair, and 40 levels of that is
 * ~5 MB. So every per-context table here multiplies by 40, and the raise from
 * 256 to 512 alone spent about 1.2 MB of headroom. The next module that wants
 * 1,024 cannot be served by doubling again -- see cc370#196, which moves ctx and
 * the seq pair off the stack. */
#define MAXLSET 512
/* &SYSLIST positions a macro call can carry.  IFOX00 has no such limit -- a
 * macro call's operand field is bounded by the statement and nothing else --
 * and 64 was not enough for the corpus: JTEXT's `DBV' call carries 86
 * positional operands and AMACLIB(IDACB2) 82.  Past this the diagnostic
 * below still fires, so the bound stays visible rather than silent. */
#define MAXSYSLIST 255
struct ctx {
    struct macro *m;
    char pv[100][VALSZ];                      /* parameter values (may be sublists) */
    const char *namepval;
    struct setrow sr[MAXLSET]; int nset;   /* local SET symbols, arrays one row each */
    int sysndx;                            /* &SYSNDX for this macro invocation */
    char sysect[9];                        /* &SYSECT, frozen at the call (see g_sysect) */
    char syslist[MAXSYSLIST][VALSZ]; int nsyslist;   /* &SYSLIST: positional operands in order */
    char arrb[48][20]; char arrnum[48]; int narr;   /* declared SET arrays: base name + 1 if numeric (A/B) */
};
/* Global SET symbols (GBLA/GBLB/GBLC) are shared between open code and every
 * macro expansion. A name declared global anywhere routes through the global
 * store; everything else is local to the macro (or open-code) context. */
/* Table sizes. These used to be 64 and 512 and to overflow SILENTLY, which is
 * how a 12-byte-short DCB got assembled at RC 0 (#63): SYS1.MACLIB's VSAM
 * macros exhausted the 64-name global list, so IHB01's `&COMSW SETB 1` was no
 * longer recognised as global, went to IHB01's own local table, and DCB read
 * back an unset -- and therefore false -- switch. 138 names were dropped in one
 * module. The bound is now far out of reach AND fatal if it is ever reached: a
 * silently dropped variable symbol cannot be debugged from the object deck. */
#define MAXGBL  1024                   /* distinct names declared GBLA/GBLB/GBLC */
/* Global SET symbols actually assigned. 4,096 was too small: IFCE0155 needs
 * 6,757 and IFCEE155 5,646, and they reach those numbers only once the &SYSLIST
 * count stops cutting their macros short -- so this bound was concealed behind
 * that one and surfaced as fourteen modules losing their deck entirely
 * (cc370#173). This table is static rather than on the stack, so the margin
 * costs address space and nothing else; the lookup is a linear scan, but it
 * scales with what a module actually assigns, not with the bound. */
#define MAXGSET 32768
static char g_gbl[MAXGBL][20]; static int g_ngbl;
static struct setrow g_sr[MAXGSET]; static int g_nset;
static void base_of(const char *n, char *b) { int i = 0; while (n[i] && n[i] != '(' && i < 19) { b[i] = n[i]; i++; } b[i] = 0; }
static int is_global(const char *n) { char b[20]; base_of(n, b); int i; for (i = 0; i < g_ngbl; i++) if (!strcmp(g_gbl[i], b)) return 1; return 0; }
static void mark_global(const char *n) { char b[20]; base_of(n, b); if (is_global(b)) return;
    if (g_ngbl >= MAXGBL) { fprintf(stderr, "as370: global variable-symbol table full (%d)\n", MAXGBL); exit(2); }
    scopy(g_gbl[g_ngbl], b, 19); g_ngbl++; }
/* split a canonical name into base + 1-based subscript (-1 when unsubscripted) */
static long set_split(const char *n, char *base) {
    const char *lp = strchr(n, '(');
    int b = lp ? (int)(lp - n) : (int)strlen(n);
    if (b > 19) b = 19;
    memcpy(base, n, (size_t)b); base[b] = 0;
    return lp ? atol(lp + 1) : -1;
}
static struct setrow *row_find(struct setrow *rows, int n, const char *base) {
    int i; for (i = 0; i < n; i++) if (!strcmp(rows[i].name, base)) return &rows[i];
    return NULL;
}
/* element slot of a subscripted row; grows on assignment, NULL when never set */
static char *row_elem(struct setrow *r, long idx, int create) {
    if (idx < 1 || idx > 1000000L) return NULL;
    if (idx > r->nelem) {
        if (!create) return NULL;
        long cap = idx < 64 ? 64 : idx;
        /* sizeof *ne, not the element width written out: this said 96 while the
         * element was VALSZ, and every array SET symbol then wrote 256 bytes into
         * 96-byte slots -- 11 modules died in the gate. */
        char (*ne)[VALSZ] = realloc(r->elem, (size_t)cap * sizeof *ne);
        unsigned char *ns = realloc(r->eset, (size_t)cap);
        if (!ne || !ns) { fprintf(stderr, "as370: out of memory growing &%s to %ld elements\n", r->name, cap); exit(2); }
        memset(ne + r->nelem, 0, (size_t)(cap - r->nelem) * sizeof *ne);
        memset(ns + r->nelem, 0, (size_t)(cap - r->nelem));
        r->elem = ne; r->eset = ns; r->nelem = (int)cap;
    }
    if (!create && !r->eset[idx - 1]) return NULL;
    if (create) r->eset[idx - 1] = 1;
    return r->elem[idx - 1];
}
static char *set_find(struct ctx *c, const char *n) {
    char b[20]; long idx = set_split(n, b);
    int g = is_global(n);
    struct setrow *r = row_find(g ? g_sr : c->sr, g ? g_nset : c->nset, b);
    if (!r) return NULL;
    if (idx < 0) return r->elem ? NULL : r->val;
    return row_elem(r, idx, 0);
}
static void set_put(struct ctx *c, const char *n, const char *v) {
    char b[20]; long idx = set_split(n, b);
    int g = is_global(n);
    struct setrow *rows = g ? g_sr : c->sr;
    int *pn = g ? &g_nset : &c->nset, cap = g ? MAXGSET : MAXLSET;
    struct setrow *r = row_find(rows, *pn, b);
    if (!r) {
        if (*pn >= cap) { fprintf(stderr, "as370: %s SET-symbol table full (%d)\n", g ? "global" : "local", cap); exit(2); }
        r = &rows[*pn]; memset(r, 0, sizeof *r);
        scopy(r->name, b, 19); (*pn)++;
    }
    char *slot = (idx < 0) ? r->val : row_elem(r, idx, 1);
    if (!slot) return;
    scopy(slot, v, VALSZ - 1);
}
/* release a context's array element vectors (the rows themselves are inline) */
static void set_free(struct ctx *c) {
    int i; for (i = 0; i < c->nset; i++) { free(c->sr[i].elem); free(c->sr[i].eset); }
}
/* sublist value "(a,b,c)" -> element count / 1-based element. Commas and the
 * closing paren are recognised only at top level, outside 'quotes' (so a
 * quoted element containing (), commas is kept whole). */
static int sub_count(const char *v) {
    if (!v[0]) return 0;
    if (v[0] != '(') return 1;
    int n = 1, d = 0, q = 0; const char *p;
    for (p = v + 1; *p; p++) {
        /* An ATTRIBUTE apostrophe is not a quote, and inside a string an
         * apostrophe can only close one -- the same pair of rules parse() needed
         * in #182, split_card() in #183 and dc_split() in #218. The SUBLIST
         * readers are the fourth pair of eyes on this syntax and never got it:
         * `ENQ (SYSZPSWD,,E,L'JFCBDSNM,SYSTEM),MF=L' counted FOUR elements where
         * IFOX00 counts five, and element 4 came back as the single character `L'
         * with the rest of the list swallowed (cc370#300). */
        if (*p == '\'') { if (q || !attr_apos(v, (int)(p - v))) q = !q; }
        else if (q) ;
        else if (*p == '(') d++;
        else if (*p == ')') { if (d == 0) break; d--; }
        else if (*p == ',' && d == 0) n++;
    }
    return n;
}
static void sub_elem(const char *v, int idx, char *out) {
    out[0] = 0;
    /* scopy, not strncpy: OUT holds VALSZ bytes and V can be the whole &SYSLIST
     * buffer, so gcc rightly reads the pair as a truncating copy under -Werror.
     * The truncation is intended -- a value is bounded at 255 here as everywhere
     * in this evaluator -- and scopy says so and terminates. */
    if (v[0] != '(') { if (idx == 1) scopy(out, v, VALSZ - 1); return; }
    const char *s = v + 1, *p = s; int n = 1, d = 0, q = 0;
    for (;; p++) {
        if (*p == '\'') { if (q || !attr_apos(v, (int)(p - v))) q = !q; continue; }   /* see sub_count (#300) */
        if (!q && *p == '(') { d++; continue; }
        if ((!q && *p == ',' && d == 0) || (!q && *p == ')' && d == 0) || !*p) {
            if (n == idx) { int L = (int)(p - s); if (L > VALSZ - 1) L = VALSZ - 1; memcpy(out, s, L); out[L] = 0; return; }
            n++; s = p + 1; if ((*p == ')' && d == 0) || !*p) return;
        } else if (!q && *p == ')') d--;
    }
}
static long eval_seta(struct ctx *c, const char *s);   /* fwd: vref evaluates subscripts */
static const char *ep_; static struct ctx *ec_;        /* SETA parser state (tentative) */
/* value of a "&name" / "&name(idx)" reference. For a macro parameter the
 * subscript selects a sublist element; for a SET symbol it selects an array
 * element &name(idx), stored under the flat name "&name(N)". */
/* Set by vref for the reference it just evaluated: 0 when the name resolved to
 * nothing because it is not known at all -- no LCLx/GBLx declaration, no SET,
 * not a parameter, not a system variable. A DECLARED but unset symbol resolves,
 * to the empty string; the two are otherwise indistinguishable (both give ""),
 * and open-code substitution has to tell them apart to leave an unknown
 * reference alone rather than delete it. */
static int g_vref_res;
static void vref(struct ctx *c, const char *ref, char *out) {
    out[0] = 0; g_vref_res = 1;
    const char *p = ref + 1; char nm[24]; int i = 0;
    while (*p && (isalnum((unsigned char)*p) || *p=='@'||*p=='#'||*p=='$'||*p=='_') && i < 22) nm[i++] = *p++;
    nm[i] = 0;
    if (!strcmp(nm, "SYSNDX")) { snprintf(out, 96, "%04d", c->sysndx); return; }   /* unique per macro invocation */
    /* &SYSPARM is a system global, defined in open code as well as in a macro
     * (ifnx1j.asm:1358). With no PARM=SYSPARM() its value is the NULL string --
     * not blanks, and K' of it is 0 (ifnx3n.asm:395-406) -- which is what makes
     * IEDHJN's '&SYSPARM'(1,4) reach IFO117 rather than yielding four blanks.
     * It resolves, so R2 substitutes it away instead of leaving it verbatim. */
    if (!strcmp(nm, "SYSPARM")) { scopy(out, g_sysparm, VALSZ - 1); return; }
    /* Only inside a macro: IFOX00 rejects &SYSECT in open code with IFO006
     * (undefined variable symbol) rather than substituting anything, so open
     * code is left to the general undefined-symbol path -- that is #97, not
     * this. */
    if (c->m && !strcmp(nm, "SYSECT")) { scopy(out, c->sysect, 8); return; }
    if (!strcmp(nm, "SYSDATE")) { scopy(out, g_sysdate, 8); return; }   /* assembly date "MM/DD/YY" */
    if (!strcmp(nm, "SYSTIME")) { scopy(out, g_systime, 5); return; }   /* assembly time "HH.MM" */
    char amp[26]; snprintf(amp, sizeof amp, "&%s", nm);
    const char *base = NULL; int k, is_param = 0;
    /* &SYSLIST is materialised as one synthetic sublist string, so its buffer
     * bounds the whole operand list and not one element.  At 1024 it held about
     * 61 operands of ordinary width, and the 62nd onwards simply were not there:
     * `&SYSLIST(62)' read empty, K' of it was 0, and a macro looping over
     * N'&SYSLIST generated nothing for the tail while reporting no error at all.
     * JTEXT's `DBV' call carries 86 and lost 24 of them that way (cc370#153). */
    char slbuf[STMTSZ];
    if (!strcmp(nm, "SYSLIST")) {                 /* positional operands as a synthetic sublist */
        int o = 0, lim = STMTSZ - 3, cut = 0; slbuf[o++] = '(';
        for (k = 0; k < c->nsyslist; k++) { if (k) slbuf[o++] = ','; const char *v = c->syslist[k];
            while (*v && o < lim) slbuf[o++] = *v++;
            if (*v) { cut = 1; break; } }
        if (cut) note_operr("&SYSLIST is longer than the operand buffer - the tail is not addressable", 8, g_curln);
        slbuf[o++] = ')'; slbuf[o] = 0; base = slbuf; is_param = 1;
    }
    else if (c->m && c->m->namep[0] && !strcmp(amp, c->m->namep)) { base = c->namepval ? c->namepval : ""; is_param = 1; }
    else if (c->m) for (k = 0; k < c->m->nparm; k++) if (!strcmp(amp, c->m->pname[k])) { base = c->pv[k]; is_param = 1; break; }   /* open code: c->m is NULL -> resolve via the SET/global store below */
    if (*p == '(') {
        /* Balanced scan, not strchr(')'): a subscript may be an expression that
         * carries its own parentheses -- &SYSLIST((&I+1),1) -- and the first ')'
         * is then in the wrong place. */
        const char *st = p + 1, *q = st; int d = 1, qt = 0;
        for (; *q; q++) {
            if (*q == '\'') { qt = !qt; continue; }
            if (qt) continue;
            if (*q == '(') d++;
            else if (*q == ')' && --d == 0) break;
        }
        char idxs[128]; int L = (int)(q - st); if (L > 127) L = 127; memcpy(idxs, st, (size_t)L); idxs[L] = 0;
        if (is_param) {
            /* ONE SUBSCRIPT PER LEVEL.  &SYSLIST(n) is the n'th positional
             * operand; &SYSLIST(n,m) is the m'th element of that operand's
             * sublist.  as370 used to evaluate the whole subscript text as a
             * single expression -- eval_seta("1,1") stops at the comma and
             * yields 1 -- so the second subscript was dropped and the reference
             * returned the operand entire, parentheses and all (#94).  Where the
             * result was used as a name, the generated statement carried
             * `(ALPHA,8)` and the module died of an over-long name field, a
             * diagnostic correct about what it saw and pointing nowhere near the
             * cause.
             *
             * Measured on the guest (JOB02901, tests/listref/ifox-listing-syslist.txt):
             * on a NON-sublist operand, element 1 is the operand itself and
             * element 2 is null -- which is exactly what sub_elem already does
             * for a value with no leading '(' , so applying it per level needs no
             * special case.
             *
             * XF defines two levels for &SYSLIST and one for a named parameter;
             * the loop simply follows however many subscripts are written, which
             * degrades to the previous behaviour for a single one. */
            /* the subscripted value is copied here before each level is peeled,
             * so this bounds the WHOLE sublist too, not one element: at 1024 the
             * 86th operand of a &SYSLIST that had survived every earlier bound
             * was still cut to its first character (cc370#153). */
            char cur[STMTSZ]; scopy(cur, base ? base : "", sizeof cur - 1);
            const char *t = idxs;
            for (;;) {
                const char *e2 = t; int dd = 0, qq = 0;
                for (; *e2; e2++) {
                    if (*e2 == '\'') { qq = !qq; continue; }
                    if (qq) continue;
                    if (*e2 == '(') dd++;
                    else if (*e2 == ')') dd--;
                    else if (*e2 == ',' && dd == 0) break;
                }
                char one[128]; int L2 = (int)(e2 - t); if (L2 > 127) L2 = 127;
                memcpy(one, t, (size_t)L2); one[L2] = 0;
                const char *sep = ep_; struct ctx *sec = ec_;
                long idx = eval_seta(c, one); ep_ = sep; ec_ = sec;   /* save/restore parser state */
                char nxt[VALSZ]; sub_elem(cur, (int)idx, nxt);
                scopy(cur, nxt, sizeof cur - 1);
                if (!*e2) break;
                t = e2 + 1;
            }
            scopy(out, cur, VALSZ - 1);
        }
        else { long idx; { const char *sep = ep_; struct ctx *sec = ec_; idx = eval_seta(c, idxs); ep_ = sep; ec_ = sec; } char cn[40]; snprintf(cn, sizeof cn, "%s(%ld)", amp, idx); char *v = set_find(c, cn);
            if (v) { scopy(out, v, VALSZ - 1); }
            else { int a, decl = 0; const char *def = ""; for (a = 0; a < c->narr; a++) if (!strcmp(c->arrb[a], amp)) { def = c->arrnum[a] ? "0" : ""; decl = 1; break; } g_vref_res = decl; scopy(out, def, VALSZ - 1); } }   /* unset array element -> declared default, else unresolved */
    } else {
        if (!is_param) base = set_find(c, amp);
        if (!base) { base = ""; g_vref_res = 0; }
        scopy(out, base, VALSZ - 1);
    }
}
/* substitute all & references in a model statement (with &x. concatenation).
 *
 * DST is bounded by DSTSZ, and it has to be: substitution EXPANDS, and by a
 * factor no call site can bound from its own input. A reference costs two
 * characters to write and vref returns up to 95, so the worst case is 47.5x --
 * `&X` repeated into a 255-byte SETC operand yields 12065 bytes, and every call
 * site here hands over a 256- or 1024-byte automatic buffer.
 *
 * That was not theoretical. Ten cards of ordinary conditional assembly --
 * double a value four times, then concatenate it four times -- walked off
 * eval_setc's sub[256] and the assembler still exited 0; ASAN is the only
 * reason it is visible at all. mexp_macro's ex[1024] overflows with NO
 * expansion whatever, because a macro body card is a joined continuation and
 * can already exceed 1024 on its own.
 *
 * Truncation past DSTSZ is deliberate and is not this function's diagnostic to
 * raise: eval_setc clips a value at 95 immediately afterwards, render_model
 * builds a listing image, and mexp_macro's result is re-clamped to 1023 by
 * parse() one call later. Where XF puts a real limit on a generated field it is
 * 255, with IFO105 past it -- a separate question from not corrupting memory. */
static void msub_ex(struct ctx *c, const char *src, char *dst, size_t dstsz, int keepunres) {
    if (!dstsz) return;
    size_t di = 0, lim = dstsz - 1; const char *s = src;
    while (*s && di < lim) {
        if (*s == '&' && (s[1] == '&')) { if (di + 1 >= lim) break; dst[di++] = '&'; dst[di++] = '&'; s += 2; continue; }
        if (*s == '&') {
            const char *start = s;
            char ref[44]; int ri = 0; ref[ri++] = *s; const char *p = s + 1;
            while (*p && (isalnum((unsigned char)*p) || *p=='@'||*p=='#'||*p=='$'||*p=='_') && ri < 30) ref[ri++] = *p++;
            if (*p == '(') { ref[ri++] = '('; p++; int d = 1; while (*p && d && ri < 42) { if (*p=='(')d++; else if(*p==')'){d--; if(!d){p++;break;}} ref[ri++]=*p++; } ref[ri++] = ')'; }
            ref[ri] = 0;
            char v[VALSZ]; vref(c, ref, v);
            if (keepunres && !g_vref_res) {
                /* R2: a reference that names nothing is left EXACTLY as written,
                 * concatenation dot included, so the card is byte-identical to
                 * what it was before substitution ran. Deleting it -- which is
                 * what an empty value does -- would trade one class of wrong
                 * bytes for another, and IFOX00's own answer is neither: it
                 * raises IFO006 and generates no object code at all for the
                 * statement (tests/setc_undef.s). That is #97, and this leaves
                 * the door open for it rather than guessing at it. */
                while (start < p && di < lim) dst[di++] = *start++;
                s = p; continue;
            }
            int r; for (r = 0; v[r] && di < lim; r++) dst[di++] = v[r];
            s = p; if (*s == '.') s++;
        } else dst[di++] = *s++;
    }
    dst[di] = 0;
}
static void msub(struct ctx *c, const char *src, char *dst, size_t dstsz) { msub_ex(c, src, dst, dstsz, 0); }
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
        else v = selfdef_cbody(&s);
    } else v = atol(s);
    return neg ? -v : v;
}
static long e_prim(void) {
    e_sp();
    if (*ep_ == '(') { ep_++; long v = e_expr(); e_sp(); if (*ep_ == ')') ep_++; return v; }
    if ((*ep_ == 'N' || *ep_ == 'K' || *ep_ == 'L') && ep_[1] == '\'') {
        int kind = *ep_; ep_ += 2; char ref[44], v[VALSZ];
        if (*ep_ == '&') { e_readref(ref); vref(ec_, ref, v); }
        else if (kind == 'L') { int ln = 0;   /* L'SYM names the symbol directly, not through a variable */
            while (*ep_ && !strchr("+-*/(), ", *ep_) && ln < VALSZ - 1) v[ln++] = *ep_++;
            v[ln] = 0; }
        else v[0] = 0;
        /* N'&SYSLIST is the NUMBER OF POSITIONAL OPERANDS, and it must not be
         * counted by rendering them.  vref() materialises the whole list as
         * `(op1,op2,...)' and copies 95 bytes of it, so sub_count() was counting
         * the commas in a TRUNCATED string: the answer fell with the length of
         * the operands rather than their number.  Measured on a macro called with
         * 13 positional operands, N' answered 10 -- while &SYSLIST(11) through
         * (13) each returned the right text, so the elements were all there and
         * only the count was wrong.
         *
         * That is what stops IFNX1K, a three-card module whose whole content is
         * one GENOP call: JTEXT's DBV loop runs `AIF (&I LT N'&SYSLIST)' over 39
         * entries, saw 7, and defined six of the internal opcodes out of 39
         * (cc370#153).  Growing the buffer is not the fix -- at 39 operands the
         * rendered list is past 500 bytes, so any fixed bound is the same defect
         * with a larger constant. The count is held exactly, so answer from it. */
        if (kind == 'N' && ec_ && ec_->m && !strcmp(ref, "&SYSLIST")) return ec_->nsyslist;
        /* K' is the COUNT OF CHARACTERS in the value and strlen is right for it.
         * L' is the LENGTH ATTRIBUTE OF THE SYMBOL the value names, which is a
         * different question and needs the pre-scan above (#244). An unknown
         * symbol answers 1, as IFOX00 does for one it cannot resolve. */
        if (kind == 'L') { int pl = prelen_of(v); return pl ? pl : 1; }
        return (kind == 'N') ? sub_count(v) : (long)strlen(v);
    }
    if ((*ep_ == 'X' || *ep_ == 'B' || *ep_ == 'C') && ep_[1] == '\'') {   /* self-defining term */
        int kind = *ep_; long v = 0; ep_ += 2;
        if (kind == 'X') { while (*ep_ && *ep_ != '\'') v = v * 16 + hexv(*ep_++); }
        else if (kind == 'B') { while (*ep_ && *ep_ != '\'') v = v * 2 + (*ep_++ == '1' ? 1 : 0); }
        else v = selfdef_cbody(&ep_);
        if (*ep_ == '\'') ep_++;
        return v;
    }
    if (*ep_ == '&') { char ref[44], v[VALSZ]; e_readref(ref); vref(ec_, ref, v); return selfdef(v); }
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
static const char *type_attr(struct ctx *c, const char *p, char *out);   /* fwd: T' (#257) */
/* OUT is bounded by OUTSZ and always was in practice -- the clamp below used to
 * be a literal 95 that happened to fit every caller's buffer, so raising the
 * value limit to IFOX00's 255 turned an accidental agreement into a stack
 * overflow that only ASAN saw (tests/msub_overflow.s). The size is a parameter
 * now, the way msub_ex takes one, so the two cannot drift apart again. */
static void eval_setc(struct ctx *c, const char *s, char *out, size_t outsz) {
    out[0] = 0; int olen = 0, olim = (int)outsz - 1; const char *p = s;
    if (olim < 0) olim = 0;
    /* a SETC operand is one or more terms joined by '.' (concatenation); each
     * term is a 'quoted' string (optionally msub'd, optional (start,len)
     * substring) or a &variable. */
    while (*p) {
        while (*p == ' ') p++;
        if (!*p) break;
        char piece[256]; piece[0] = 0;
        int subterm = 0;   /* this term ended with a substring's ')' */
        if (*p == '\'') {
            char inner[256]; int il = 0; const char *q = p + 1;   /* scan to the closing quote, de-escaping doubled '' to a single ' */
            while (*q) { if (*q == '\'') { if (q[1] == '\'') { if (il < 255) inner[il++] = '\''; q += 2; continue; } break; }
                if (il < 255) { inner[il++] = *q; } q++; }
            inner[il] = 0;
            char sub[256]; msub(c, inner, sub, sizeof sub);
            p = (*q == '\'') ? q + 1 : q;
            if (*p == '(') {                       /* substring (start,len) */
                ec_ = c; ep_ = p + 1; long st = e_expr(); e_sp(); long ln = 0;
                if (*ep_ == ',') { ep_++; ln = e_expr(); }
                if (*ep_ == ')') ep_++;
                p = ep_;
                int n = (int)strlen(sub);
                /* IFOX00 checks the two expressions in this order and assigns the
                 * NULL string when either fails -- it does not clamp. Measured on
                 * all four boundaries at once, tests/setc_substr.s:
                 *   'AB'(0,2) / (-1,2)  IFO115, null    severity 8
                 *   'AB'(3,1)           IFO117, null    severity 8
                 *   'AB'(1,-1)          IFO116, null    severity 4  <- the only
                 *                                                      warning
                 *   'AB'(2,9)           'B', and NO diagnostic: a second
                 *                       expression running past the end simply
                 *                       truncates (the "ERROR IF EXPR 2 HIGH"
                 *                       label in the source is dead code).
                 * as370 clamped a low first expression to 1 and returned the whole
                 * string, so 'AB'(0,2) gave AB where IFOX gives nothing -- wrong
                 * bytes, silently, on the macro path as much as in open code.
                 * Severities are jermsgcd.asm SEV115/116/117 = 8 / 4 / 8. */
                int bad = 0;
                if (st <= 0) { note_operr("first expression in substring notation has zero or negative value (IFOX00 IFO115)", 8, g_ca_slot); bad = 1; }
                else if (n < (int)st) { note_operr("first expression in substring notation exceeds the length of the string (IFOX00 IFO117)", 8, g_ca_slot); bad = 1; }
                if (ln < 0) { note_operr("second expression in substring notation has negative value (IFOX00 IFO116)", 4, g_ca_slot); bad = 1; }
                if (bad) { piece[0] = 0; }
                else { int a = (int)st - 1;
                       int take = (int)ln; if (take > n - a) take = n - a; if (take < 0) take = 0;
                       memcpy(piece, sub + a, take); piece[take] = 0; }
                subterm = 1;
            } else { strncpy(piece, sub, 255); piece[255] = 0; }
        } else if (*p == '&') {
            char ref[64]; int i = 0; ref[i++] = *p++;
            while (*p && (isalnum((unsigned char)*p) || *p=='@'||*p=='#'||*p=='$'||*p=='_') && i < 62) ref[i++] = *p++;
            if (*p == '(') { ref[i++] = *p++; int d = 1; while (*p && d && i < 62) { if (*p=='(')d++; else if(*p==')')d--; ref[i++]=*p++; } }
            ref[i] = 0; vref(c, ref, piece);
        } else if (*p == 'T' && p[1] == '\'') {
            /* T' is a term of a SETC expression as much as of a comparison, and
             * only the comparison path had it -- so `&T SETC T'&P' assigned the
             * four literal characters T'&P and every macro that branches on the
             * assigned value took the wrong path. All the machinery was already
             * here; the character path simply never reached it (cc370#257). */
            p = type_attr(c, p + 2, piece);
        } else {                                   /* bare text up to a '.' */
            int i = 0; while (*p && *p != '.' && *p != ' ' && i < 255) piece[i++] = *p++; piece[i] = 0;
        }
        int pl = (int)strlen(piece); if (olen + pl > olim) pl = olim - olen; if (pl < 0) pl = 0;
        memcpy(out + olen, piece, pl); olen += pl; out[olen] = 0;
        /* A SUBSTRING ENDS ITS TERM, so a term following it is concatenated with
         * no period between them -- `'&F'(1,8-K'&P)'&P''.  The period is what
         * separates two terms that would otherwise run together; after a closing
         * parenthesis there is nothing to run together, and IFOX00 concatenates
         * (tests/substrcat.s: '0000000'(1,7) then '0' is '00000000', eight
         * characters).  as370 required the period and dropped everything after
         * the substring.
         *
         * IBM's USS macros pad a counter into a generated name exactly this way,
         * and the counter is the part that was dropped: every generated block got
         * the SAME name, so every A(...) pointing at one resolved to the same
         * place or to zero.  ISTINCDT and five others -- and neither assembler
         * says anything, which is why it took IBM's own shipped object to decide
         * which of the two was wrong (cc370#273). */
        if (*p == '.') p++;                        /* explicit concatenation */
        else if (!(subterm && (*p == '\'' || *p == '&'))) break;
    }
}
/* T' of a SELF-DEFINING TERM is 'N', whatever the notation (#142).
 *
 * Measured against IFOX00 (tests/tattr_selfdef.s and its listing reference):
 *
 *   4095 -> N    X'C0D' -> N    B'1010' -> N    C'AB' -> N
 *   C'&&' -> N   C'''' -> N     -1 -> U         SYM -> its DS/DC type letter
 *
 * as370 used to answer 'N' only when every character was a decimal digit, so
 * the X/B/C notations fell through to 'U' and every macro branching on
 * "AIF (T'&X NE 'N')" took the wrong path -- silently, at rc=0, with a longer
 * expansion that assembles and runs. SYS1.AMACLIB(ABEND) is one of 225 such
 * macros: it made "ABEND X'C0D',,,SYSTEM" 24 bytes instead of 8, which is the
 * whole of IEAVDSEG's section length difference.
 *
 * Two boundaries worth keeping, both counter-intuitive and both measured
 * rather than reasoned:
 *  - a SIGNED decimal is NOT a self-defining term. -1 is 'U', and the old
 *    all-digits test happened to get that right for the wrong reason.
 *  - C'&&' and C'''' ARE self-defining terms: the doubled ampersand and the
 *    doubled quote are one character each, so the run between the delimiters
 *    is not inspected for content, only delimited.
 *
 * A defined SYMBOL answers with its DS/DC type letter, which as370 does not
 * record per symbol yet -- filed separately. Anything that is neither a
 * self-defining term nor a known symbol stays 'U'.
 */
static int is_selfdef(const char *v) {
    int i, n;
    if (!v[0]) return 0;
    if (isdigit((unsigned char)v[0])) {          /* unsigned decimal; a sign makes it an expression */
        for (i = 0; v[i]; i++) if (!isdigit((unsigned char)v[i])) return 0;
        return 1;
    }
    if ((v[0] == 'X' || v[0] == 'B' || v[0] == 'C') && v[1] == '\'') {
        n = (int)strlen(v);
        return n >= 3 && v[n - 1] == '\'';       /* delimited only, content not inspected */
    }
    return 0;
}
static int card_op_is(const char *l, const char *op);   /* defined with the macro reader, below */
/* Look-ahead over OPEN CODE for symbol type attributes (#144).
 *
 * T'SYMBOL cannot be answered from the symbol table: macro_pass() expands
 * every macro before prescan_literals and do_pass(1) run, so an AIF over a
 * type attribute is decided while that table is still empty. Recording a type
 * letter per symbol does not help -- it is stamped in pass 1, long after the
 * branch was taken (verified by instrumenting the stamp: it fires with the
 * right letter and T' still reads 'U').
 *
 * IFOX00 answers it by LOOKING AHEAD, and the measurement that settles the
 * shape is that a symbol defined AFTER the macro call resolves too:
 *
 *     BEFORE   DS    F
 *              WHICH BEFORE      IFOX: F
 *              WHICH AFTER       IFOX: F
 *     AFTER    DS    F
 *
 * so interleaving the expansion with pass 1 would not have been enough either.
 * This walks the raw statements once, before any expansion, and records what
 * each open-code label defines. The phase order is untouched: the pass fills a
 * table, T' reads it, nothing else changes.
 *
 * Letters are the measured ones (tests/tattr_symbol.s and its listing):
 * the DS/DC type letter, 'I' for a machine instruction, 'J' for a section
 * name, 'T' for EXTRN/WXTRN, 'U' for EQU, and 'U' for anything unknown.
 *
 * BOUNDARY, and it is UNGEMESSEN: a symbol GENERATED by a macro is not in the
 * raw source and is invisible here. Whether IFOX resolves those is not
 * measured, and nothing in this file should be read as a claim that it does
 * not. For the 225 macros in the tree that branch on a type attribute, open
 * code is the ordinary case.
 *
 * A macro BODY is not open code: labels between MACRO and MEND belong to the
 * expansion, not to the assembly, so the depth counter skips them. */
struct symtype { char name[9]; char t; };
static struct symtype stypes[MAXSYM];
static int nstypes;
static void styp_add(const char *nm, char t) {
    int i;
    if (!nm[0] || !t) return;
    for (i = 0; i < nstypes; i++) if (!strcmp(stypes[i].name, nm)) return;   /* first definition wins, as a duplicate label would */
    if (nstypes >= MAXSYM) return;
    strncpy(stypes[nstypes].name, nm, 8); stypes[nstypes].name[8] = 0;
    stypes[nstypes].t = t; nstypes++;
}
static char styp_find(const char *nm) {
    int i; for (i = 0; i < nstypes; i++) if (!strcmp(stypes[i].name, nm)) return stypes[i].t;
    return 0;
}
/* The type letter of a DS/DC operand: skip the duplication factor -- digits, or
 * a parenthesised expression -- and take the character that follows. DS 0H is
 * still 'H', which is why the factor is skipped rather than rejected. */
static char ds_type_letter(const char *opnd) {
    const char *p = opnd;
    while (*p == ' ') p++;
    if (*p == '(') { int d = 1; p++; while (*p && d) { if (*p == '(') d++; else if (*p == ')') d--; p++; } }
    else while (isdigit((unsigned char)*p)) p++;
    return *p ? (char)toupper((unsigned char)*p) : 0;
}
static void prescan_symtypes(char **in, int n) {
    int i, depth = 0;
    nstypes = 0;
    for (i = 0; i < n; i++) {
        char lbl[32], op[16], opnd[STMTSZ];
        if (card_op_is(in[i], "MACRO")) { depth++; continue; }
        if (card_op_is(in[i], "MEND")) { if (depth) depth--; continue; }
        if (depth) continue;                       /* a macro body is not open code */
        if (!parse(in[i], lbl, op, opnd) || !op[0]) continue;
        if (!strcmp(op, "EXTRN") || !strcmp(op, "WXTRN")) {
            const char *s = opnd; char nm[16];
            while (*s) {
                int k = 0;
                while (*s == ' ' || *s == ',') s++;
                while (*s && *s != ',' && *s != ' ' && k < 15) nm[k++] = *s++;
                nm[k] = 0; if (k) styp_add(nm, 'T');
                while (*s && *s != ',') s++;
            }
            continue;
        }
        if (!lbl[0]) continue;
        if (!strcmp(op, "DS") || !strcmp(op, "DC")) styp_add(lbl, ds_type_letter(opnd));
        else if (!strcmp(op, "CSECT") || !strcmp(op, "DSECT") || !strcmp(op, "START") || !strcmp(op, "COM")) styp_add(lbl, 'J');
        else if (!strcmp(op, "EQU")) styp_add(lbl, 'U');
        else if (op_find(op)) styp_add(lbl, 'I');
    }
}
/* a comparison term is character if quoted or a T' (type) attribute */
static int term_is_str(const char *t) { return t[0] == '\'' || (t[0] == 'T' && t[1] == '\''); }
/* T' of a term: 'N' for a self-defining term, the symbol's type letter from the
 * look-ahead table otherwise, 'U' for anything unknown and 'O' for nothing at
 * all. Returns the position after the term so a SETC can carry on reading.
 *
 * One function because there were two callers and only one of them existed: the
 * comparison path had it and the character path did not (cc370#257). */
static const char *type_attr(struct ctx *c, const char *p, char *out) {
    char ref[44], v[VALSZ]; int i = 0;
    if (*p == '&') {
        ref[i++] = *p++;
        while (*p && (isalnum((unsigned char)*p) || *p=='@'||*p=='#'||*p=='$'||*p=='_') && i < 42) ref[i++] = *p++;
        if (*p == '(') { ref[i++] = *p++; int d = 1;
            while (*p && d && i < 42) { if (*p=='(') d++; else if (*p==')') d--; ref[i++] = *p++; } }
        ref[i] = 0; vref(c, ref, v);
    } else {
        int k = 0;
        if ((*p == 'X' || *p == 'B' || *p == 'C') && p[1] == '\'') {   /* a self-defining term keeps its quotes */
            v[k++] = *p++; v[k++] = *p++;
            while (*p && *p != '\'' && k < (int)sizeof v - 2) v[k++] = *p++;
            if (*p == '\'') v[k++] = *p++;
        } else {
            while (*p && *p != '.' && *p != ' ' && k < (int)sizeof v - 1) v[k++] = *p++;
        }
        v[k] = 0;
    }
    /* A SUBLIST answers with the type attribute of its FIRST ELEMENT, and does
     * not descend further: a first element that is itself a sublist gives 'U'.
     * Measured, because the boundary is not guessable (cc370#260):
     *
     *   (3) N   (3,4) N   (FLD) C   (FLD,3) C   (3,FLD) N
     *   (,3) O  (X'0A') N (NODEF) U ((1,2),3) U
     *
     * as370 answered 'U' for every sublist, so APVTMACS(HEXCNVT)'s
     * `AIF (T'&OUT NE 'N').ERROR4' took the error path on a call as ordinary as
     * `HEXCNVT (3),(2),4' -- six AMDPR* modules, and IFOX00 assembles all six
     * without a word. */
    if (v[0] == '(') {
        char el[VALSZ]; int d = 0, k = 0; const char *e = v + 1;
        while (*e && k < (int)sizeof el - 1) {
            if (*e == '(') d++;
            else if (*e == ')') { if (!d) break; d--; }
            else if (*e == ',' && !d) break;
            el[k++] = *e++;
        }
        el[k] = 0;
        if (el[0] == '(') { strcpy(out, "U"); return p; }   /* a nested sublist is not descended into */
        scopy(v, el, VALSZ - 1);
    }
    if (!v[0]) strcpy(out, "O");
    else if (is_selfdef(v)) strcpy(out, "N");
    else { char t = styp_find(v); out[0] = t ? t : 'U'; out[1] = 0; }
    return p;
}
/* a comparison term is character if quoted or a T' (type) attribute */
static void term_str(struct ctx *c, const char *t, char *out, size_t outsz) {
    if (t[0] == 'T' && t[1] == '\'') type_attr(c, t + 2, out);
    else eval_setc(c, t, out, outsz);
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
    if (term_is_str(L) || term_is_str(R)) { char ls[VALSZ], rs[VALSZ]; term_str(c, L, ls, sizeof ls); term_str(c, R, rs, sizeof rs);
        /* A CHARACTER comparison orders by LENGTH first and only then by
         * content: a shorter string is less than a longer one whatever the
         * characters are.  strcmp() instead reads them left to right, so it makes
         * '2' GREATER than '11' -- and a macro counting with SETA and testing
         * `AIF ('&AA' LE '&DD')' then stops after one iteration.
         *
         * That is IEECDCM building its screen control tables: as370 generated
         * DCMMSG1 and stopped, so DCMMSG8, DCMSEC9 and DCMMSG11 were undefined
         * symbols in every module that maps a console (cc370#153).  Measured
         * against IFOX00 -- '2' LE '11' true, '9' LE '10' true, '10' LE '9'
         * false, and the same by length for letters: 'B' LE 'AB' true,
         * 'AB' LE 'B' false (tests/cmprule.s).  Equivalent to padding the shorter
         * operand on the LEFT with blanks, which is how the manuals put it;
         * length-first is the same order and does not depend on blank being the
         * lowest character in the set. */
        /* Content is compared in the EBCDIC collating sequence, not the host's.
         * strcmp() orders by the ASCII values the source characters happen to
         * have here, and the two sequences disagree in exactly one place that
         * assembler source reaches: LETTERS SORT BEFORE DIGITS in EBCDIC and
         * after them in ASCII. Letter against letter and digit against digit
         * agree, which is why 'A' LT 'B' and '1' LT '2' were always right and
         * five instruments walked past this for two days (cc370#264).
         *
         * AMACLIB(DOM)'s register test is the standard IBM idiom --
         * `AIF ('&MSG(1)' GE '1' AND '&MSG(1)' LE '12')' -- and `DOM MSG=(R1)'
         * makes that 'R1' LE '12', true in EBCDIC and false here. 103 macros in
         * the libraries carry the shape. */
        size_t ll = strlen(ls), rl = strlen(rs), ci;
        cmp = (ll < rl) ? -1 : (ll > rl) ? 1 : 0;
        for (ci = 0; !cmp && ci < ll; ci++) {
            unsigned char le = mvs_a2e((unsigned char)ls[ci]), re = mvs_a2e((unsigned char)rs[ci]);
            if (le != re) cmp = (le < re) ? -1 : 1;
        } }
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
/* The relational operators, as a token. Named separately from is_relop()
 * below because the TOKENIZER needs it and that one is defined after. */
static int is_relop_tok(const char *t) {
    return !strcmp(t, "EQ") || !strcmp(t, "NE") || !strcmp(t, "LT")
        || !strcmp(t, "GT") || !strcmp(t, "LE") || !strcmp(t, "GE");
}
static int eval_cond(struct ctx *c, const char *cond) {
    /* Sized for a full 255-character operand rather than for the shortest
     * condition anyone happened to write: a six-term AND is 23 tokens and the
     * old 32 was within one comparison of silently dropping factors. Dropping is
     * what it did -- `if (nt < 31) nt++' kept overwriting the last slot, so a
     * long condition evaluated on its first thirty-one tokens and no one was
     * told (cc370#236, the same shape as the 126-character cut in aif_split). */
    char toks[VALSZ][256]; int nt = 0, tovf = 0; const char *p = cond;
    while (*p) {
        while (*p == ' ') p++;
        if (!*p) break;
        char *o = toks[nt]; int q = 0, d = 0, oi = 0, closed = 0;
        while (*p && (q || d || *p != ' ')) {
            if (!q && d == 0 && closed && isalpha((unsigned char)*p)) break;  /* a relop/keyword abutting a closing quote ('A'NE'B', after a col-72 join) is its own token */
            closed = 0;
            if (*p == '\'') {
                /* A relational or logical operator abutting the OPENING quote of
                 * its right operand ends the operator token, exactly as one
                 * abutting `(' already did. Blanks around a relop are optional and
                 * IBM's macros routinely omit them -- AMODGEN(SYSEVENT) maps its
                 * whole mnemonic table with `AIF ('&EVENT'EQ'USERRDY').EOK' --
                 * and without this the operator and the operand glued into one
                 * token `EQ'USERRDY'', which is no relop, so the comparison was
                 * never made and the AIF fell through. SYSEVENT then walked past
                 * its match to a later mnemonic AND ignored ENTRY=BRANCH: code 53
                 * and an SVC where IFOX00 has code 4 and a BALR (cc370#243).
                 *
                 * The mirror of the `closed' rule two lines down, which handles the
                 * operator abutting a CLOSING quote. Both halves are needed: one
                 * ends the left operand, this ends the operator. */
                if (!q && oi > 0) { o[oi] = 0;
                    if (is_relop_tok(o) || !strcmp(o, "AND") || !strcmp(o, "OR") || !strcmp(o, "NOT")) break; }
                if (q || !(oi > 0 && strchr("KNLT", o[oi - 1]))) { int wq = q; q = !q; if (wq && !q) closed = 1; }
            }  /* K'/N'/L'/T' apostrophe is an attribute, not a string quote */
            else if (!q && *p == '(') {
                if (d == 0 && oi > 0) { o[oi] = 0;                       /* a logical operator abutting '(' (NOT(..)/AND(..)/OR(..)) is its own token, not a subscript */
                    if (!strcmp(o, "NOT") || !strcmp(o, "AND") || !strcmp(o, "OR")) break; }
                d++;
            } else if (!q && *p == ')') {
                d--;
                /* A closing parenthesis ends a term the same way a closing quote
                 * does, so an operator abutting it is its own token. Blanks around
                 * a logical operator are optional and IBM's macros omit them:
                 * PVTMAC(GOIF1) writes `AIF (NOT(&B(1) AND &B(2) AND &B(3))OR
                 * '&ELSE' EQ '').C5', and without this the OR and everything after
                 * it glued onto the group, so the whole condition read as one
                 * factor and came out false. Eight IFNX* modules fall to .ERR3 and
                 * MNOTE over it (cc370#262).
                 *
                 * The mirror of the `closed' rule for quotes, which #243 needed on
                 * the other side of the operator. Three delimiters, one rule. */
                if (!d) closed = 1;
            }
            if (oi < 255) o[oi++] = *p; else tovf = 1;
            p++; }
        o[oi] = 0; if (nt < 95) nt++; else tovf = 1;
    }
    /* Loud, because the alternative is a branch taken on half a condition. */
    if (tovf) fprintf(stderr, "as370: conditional expression too complex (over 95 terms or a 255-character term) - %.60s\n", cond);
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
/* The condition is bounded by the CALLER's buffer, not by a number written here.
 * It used to be cut at 126 characters, silently, while both call sites passed a
 * 512-byte buffer -- so an AIF whose condition ran past 126 was evaluated on a
 * fragment ending mid-term, and branched on whatever that fragment happened to
 * mean. IKJIDENT's is 153: six `NE' terms over three cards, and the tail that
 * decides it was thrown away, so EVERY call took the error path, MNOTE'd and
 * MEXIT'ed. 612 of those MNOTEs across the corpus, and until #39 not one of them
 * was audible -- the macro simply generated nothing (cc370#236). */
static void aif_split(const char *opnd, char *cond, int condsz, char *seq, int seqsz) {
    cond[0] = seq[0] = 0; const char *p = opnd; if (*p != '(') return;
    int d = 0, q = 0; const char *cs = p + 1;
    for (; *p; p++) { if (*p == '\'') { if (q || p == opnd || !strchr("KNLT", p[-1])) q = !q; }  /* K'/N'/L'/T' attribute apostrophe */
        else if (!q && *p == '(') { d++; if (d == 1) cs = p + 1; }
        else if (!q && *p == ')') { if (--d == 0) {
            int L = (int)(p - cs); if (L > condsz - 1) L = condsz - 1; memcpy(cond, cs, L); cond[L] = 0;
            const char *s = p + 1; int si = 0; while (*s && !isspace((unsigned char)*s) && si < seqsz - 2) seq[si++] = *s++;  /* sequence symbol only */
            seq[si] = 0; return; } } }
}

/* ---- macro library (-I dirs): COPY members + macro lookup by name -------- */
#define MAXMACLIB 16
static char *maclib_dirs[MAXMACLIB]; static int nmaclib;

/* Resolve the real directory of this executable (symlinks included) so the
 * built-in default macro path can be derived RELATIVE to the install:
 * <exedir>/../macros == <sysroot>/macros when as370 lives in
 * <prefix>/<triple>/bin.  No triple is baked in -- renaming the target needs no
 * change here -- and it is relocatable (move the install, the path follows). */
static void self_exe_dir(const char *argv0, char *out, size_t outsz)
{
    char buf[PATH_MAX], real[PATH_MAX], tmp[PATH_MAX];
#ifdef __APPLE__
    uint32_t sz = sizeof buf;
    if (_NSGetExecutablePath(buf, &sz) != 0) snprintf(buf, sizeof buf, "%s", argv0);
#elif defined(__linux__)
    ssize_t n = readlink("/proc/self/exe", buf, sizeof buf - 1);
    if (n > 0) buf[n] = 0; else snprintf(buf, sizeof buf, "%s", argv0);
#else
    snprintf(buf, sizeof buf, "%s", argv0);
#endif
    if (!realpath(buf, real)) snprintf(real, sizeof real, "%s", buf);
    snprintf(tmp, sizeof tmp, "%s", real);          /* dirname() may modify its arg */
    snprintf(out, outsz, "%s", dirname(tmp));
}
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
static int rawlen(const char *l) { int n = (int)strlen(l); while (n > 0 && (l[n-1] == '\n' || l[n-1] == '\r')) n--; return n; }

/* ---- continuation-card diagnostics (IFO026 / IFO069) ---------------------
 * Raised by the joiner, which runs before the statement list exists and is
 * re-entered for every macro/COPY member read, so these carry their own card
 * number and the member they came from rather than a lines[] index.
 *
 * IFO026 CHARACTERS APPEAR BETWEEN THE BEGIN AND CONTINUE COLUMNS and IFO069
 * TOO MANY CONTINUATION CARDS are both severity 4 (jermsgcd.asm SEV26/SEV69) --
 * as370's first warnings, where every diagnostic before them was an error. */
/* The printed list is bounded; the COUNTS are not. A module whose comment block
 * is full of over-long cards can produce hundreds of these -- nsf370's
 * nsfvsvc.asm produces 130 -- and the two that mattered there were the LAST two.
 * At a silent cap of 128 they fell off the end, so a module that discarded four
 * statements reported two, which is the exact failure mode this diagnostic
 * exists to prevent. Overflow is now counted and said out loud, and the severity
 * comes from the counters rather than from what happened to fit. */
#define MAXCONTD 512
static struct { char src[24]; char card[80]; int line; int err; int stmt; int lost; } contd[MAXCONTD];
static int ncontd;          /* entries kept for printing */
static int ncontd_seen;     /* every one raised */
static int ncontd_lost;     /* of those, how many discarded a statement */
static int ncontd_ifox;     /* of those, how many IFOX00 itself flags (err 26 or 69) -- the ones that may raise the RC */
static const char *g_joinsrc;         /* library member being joined; NULL = the primary source */
static void note_cont(int err, int card, const char *text, int len, int stmt, int lost) {
    ncontd_seen++; if (lost) ncontd_lost++; if (err) ncontd_ifox++;
    mark_cont_stmt(stmt, g_joinsrc != NULL);   /* the STATEMENT's first card, not this continuation card */
    if (ncontd >= MAXCONTD) return;
    contd[ncontd].stmt = stmt; contd[ncontd].lost = lost;
    scopy(contd[ncontd].src, g_joinsrc ? g_joinsrc : "", sizeof contd[0].src - 1);
    if (len > 79) len = 79;
    memcpy(contd[ncontd].card, text, (size_t)len); contd[ncontd].card[len] = 0;
    contd[ncontd].line = card; contd[ncontd].err = err; ncontd++;
}
/* One continuation card, already read: check columns 1-15 (IFOX00's RFCCHK
 * checks BEGREG..CBGREG-1) and report the card's own line. as370 takes the
 * continuation text from column 16 either way -- IFOX00 does NOT, it pulls the
 * pre-continue-column characters into the operand (measured: `DC C'AB',` +
 * `BADCONT   C'CD'` gives IFO198 near operand column 7, so the operand it
 * scanned was `C'AB',BADCONT...`). No corpus statement continues that way --
 * 1030 continuation cards in libc370, the only three with text before column 16
 * are comment cards, whose text is discarded anyway -- so the recovery is left
 * alone and only the diagnosis is added. */
/* One continuation card, already read. Two questions about it, and they are not
 * the same question:
 *
 *   IFO026 -- do columns 1-15 (BEGREG..CBGREG-1, RFCCHK) hold anything? That is
 *   IFOX00's warning, severity 4, and as370 reports it as one.
 *
 *   Was a STATEMENT lost? A card consumed by a continued COMMENT is discarded
 *   whole; a card consumed by a continued STATEMENT keeps only columns 16-71, so
 *   a label or operation in 1-15 is thrown away. Either way the module is short
 *   of something its author wrote, and the deck is punched regardless.
 *
 * IFOX00 does not separate them: both are severity 4, which on MVS passed
 * COND=(8,LT) and let the linkage editor run. That blind spot is survivable in
 * JCL and is not survivable in a host build, where a tolerated RC 4 means silent
 * corruption sails through CI -- measured on mvslovers/nsf370, where a comment
 * card ate a DCBD, two EQUs and an instruction, and the modules kept building.
 * So as370 keeps IFOX00's number and severity for the harmless case and raises
 * the one that loses a statement to severity 8. The bytes are IFOX00's either
 * way; only the return code says "a build must not pass this".
 *
 * by_comment: the continued statement is a comment, so the card goes entirely. */
static void check_cont_card(const char *c, int cl, int card, int stmt, int by_comment, int itself_continues) {
    int k, nb = 0, iscmt = (c[0] == '*' || (c[0] == '.' && c[1] == '*'));
    for (k = 0; k < 15 && k < cl; k++) if (c[k] != ' ' && c[k] != '\t') { nb = 1; break; }
    /* A COMMENT card carries nothing to lose, whichever kind of statement ate it:
     * as a comment it generates no storage, and merged into an operand it only
     * spoils a TITLE string or the like. rexx370's tlnkterm.asm and trxldc.asm
     * are that shape -- a TITLE whose quoted text runs past column 71 eats the
     * comment card under it -- and they must stay warnings. */
    if (iscmt) { if (nb) note_cont(26, card, c, cl, stmt, 0); return; }
    if (by_comment) { note_cont(nb ? 26 : 0, card, c, cl, stmt, 1); return; }   /* err 0: IFOX00 does not even warn here */
    if (nb) { note_cont(26, card, c, cl, stmt, 1); return; }   /* its label and operation are discarded */
    /* A continuation card with NOTHING in the statement field draws IFO026 as
     * well, and as370 said nothing at all about it. Measured (tests/blankcont.s):
     * a card blank from the continue column to 71 is flagged at severity 4,
     * while one carrying text from column 16 is not -- so the message's own
     * wording, "characters appear between the begin and continue columns", is
     * narrower than the condition it is issued for.
     *
     * ONLY when the card does not itself continue. A blank card in the MIDDLE of
     * a continuation is not an empty continuation, it is a run of blanks inside
     * a character constant -- `WTO '<70 blanks>' spread over three cards is the
     * shape, and IER8CM, IFDOLT12, ILRPGEXP and four others write exactly that.
     * Flagging those cost seven modules against the three this gains, which is
     * how the condition was found: the rule without it is net negative.
     *
     * Nothing is lost here: the card carried nothing to lose, so it is recorded
     * with lost = 0 and --strict-cont leaves it at 4 (cc370#325). */
    if (!itself_continues) {
        int j, body = 0;
        for (j = 15; j < 71 && j < cl; j++) if (c[j] != ' ' && c[j] != '\t') { body = 1; break; }
        if (!body) note_cont(27, card, c, cl, stmt, 0);   /* 27: IFO026's number, our own wording */
    }
}

/* Conditional-assembly statements whose operand is an arithmetic or logical
 * EXPRESSION.  Their operators are written with blanks around them --
 * `AIF ('&A' EQ 'X' OR '&B' EQ 'Y').L` -- so a blank inside the parenthesised
 * expression does NOT end the operand, and a continued one must be joined
 * across it.  Every OTHER statement, machine instruction and macro call alike,
 * ends its operand at the first blank outside quotes, parentheses included.
 *
 * Measured over the 5,528 MVSBLD modules by computing both rules and recording
 * the operation wherever they disagree: AIF 3,200, SETB 1,597 and SETC 2 need
 * the expression rule, and every one of the other 27 operations that showed up
 * is a macro call that must cut at the blank -- XCTLTABL 57, SETLOCK 17, DEQ 8,
 * GETMAIN, OPEN, WTO, ENQ, CALL, ACB, RPL and the rest. AGO, SETA and ACTR are
 * here on grammar, not on measurement: same operand syntax, no instance in the
 * corpus that separates them. */
static int op_is_cond_expr(const char *s, int n) {
    static const char *const ops[] = { "AIF", "AGO", "SETA", "SETB", "SETC", "ACTR" };
    size_t k; int j;
    for (k = 0; k < sizeof ops / sizeof *ops; k++) {
        if ((int)strlen(ops[k]) != n) continue;
        for (j = 0; j < n; j++) if (toupper((unsigned char)s[j]) != ops[k][j]) break;
        if (j == n) return 1;
    }
    return 0;
}
/* join assembler continuation lines: a non-blank in column 72 continues the
 * statement on the next line starting at column 16. Operates on raw[] and on
 * every macro/COPY library read. */
/* seqout (optional) receives cols 73-80 of each output line's primary card --
 * the library sequence number the listing's SOURCE column carries through. */
static int join_cont(char **in, int n, char **out, int maxout, char (*seqout)[12], int *org) {
    int i = 0, no = 0;
    while (i < n && no < maxout) {
        const char *l = in[i];
        if (org) org[no] = i + 1;   /* 1-based input line of this statement's first card */
        if (seqout) { int k, sl = rawlen(l); for (k = 0; k < 8; k++) seqout[no][k] = (72 + k < sl) ? l[72 + k] : ' '; seqout[no][8] = 0; }
        if (l[0] == '*' || (l[0] == '.' && l[1] == '*')) {
            /* A comment statement is continued exactly like any other: IFOX00
             * reads it with RALLCNT (ifnx1a.asm:606, PNXT13 "READ ALL VALID
             * CONTINUATIONS"), so a comment reaching column 72 CONSUMES the next
             * card -- and if that card is a statement, the statement is gone.
             * Measured on the guest (#72): the card is listed without a number,
             * absent from the cross-reference, and the section is short by its
             * bytes, all at severity 4. as370 exempted comments and quietly
             * assembled the statement the guest had eaten.
             *
             * IFO069 is raised here and not for ordinary statements because a
             * comment IS decidable at this point: the two-card limit lives under
             * RALLCNT (REXCS, ifnx1a.asm:3778), which machine and assembler ops
             * and comments use, while macro calls read one continuation at a
             * time through RONECNT and are not bounded -- measured, a DCB call
             * with three continuation cards is not flagged. The joiner cannot
             * tell a macro call from a machine op, so that half is #78. */
            int len = rawlen(l), cont = (len > 71 && l[71] != ' '), ncont = 0, stmt = i + 1;
            out[no++] = strdup(l); i++;
            while (cont && i < n) {
                const char *c = in[i]; int cl = rawlen(c), nxt;
                nxt = (cl > 71 && c[71] != ' ');
                check_cont_card(c, cl, i + 1, stmt, 1, nxt);
                if (++ncont == 2 && nxt) note_cont(69, i + 1, c, cl, stmt, 0);   /* card 3 of 3 still continues */
                cont = nxt; i++;
            }
            continue;
        }
        int stmt_card = i + 1;                       /* this statement's first card, for the flagged-statement count */
        char acc[8192]; int a = 0, len = rawlen(l), copy = len > 71 ? 71 : len;
        if (copy < 0) copy = 0;   /* rawlen() is always >= 0; make it provable (glibc _FORTIFY_SOURCE) */
        acc[0] = 0; memcpy(acc, l, (size_t)copy); a = copy;
        int cont = (len > 71 && l[71] != ' ');
        i++;
        /* operand field starts after the label (col 1) and the opcode */
        int os = 0, ops_, ope_;
        if (acc[0] != ' ' && acc[0] != '\t') while (os < a && acc[os] != ' ' && acc[os] != '\t') os++;
        while (os < a && (acc[os] == ' ' || acc[os] == '\t')) os++;
        ops_ = os;
        while (os < a && acc[os] != ' ' && acc[os] != '\t') os++;
        ope_ = os;
        while (os < a && (acc[os] == ' ' || acc[os] == '\t')) os++;
        int condexpr = op_is_cond_expr(acc + ops_, ope_ - ops_);
        /* Once the operand has ENDED, the cards that follow continue the REMARK
         * and contribute nothing to the statement. IFOX00 consumes them and
         * discards their text: `DC C'XY' REMARK' with a continued remark
         * assembles to exactly `DC C'XY''.
         *
         * as370 truncated the accumulator at the operand end and then appended
         * the next card anyway. Harmless while the operand ended on a literal --
         * the text landed past it as a remark -- and destructive when it ended
         * on a VARIABLE SYMBOL, because the continuation extended the NAME:
         * AMACLIB(IKJIDENT) writes `...,C&TYPNAM PARAMETER TYPE MESSA' plus
         * `GE SEGMENT', which joined as `&TYPNAMGE' -- an undefined variable
         * that substituted to nothing. The length field still said 18 and the
         * data was one blank (cc370#250). */
        int opnd_ended = 0;
        while (cont && i < n) {
            /* A continued line's operand ends at the first blank outside QUOTES;
             * the rest of columns 1-71 is a remark and is dropped before the next
             * card is joined, so `DCB &MACRF=,  FOUNDATION BLOCK` + continuation
             * keeps the comma.  Parenthesis depth counts only for the conditional
             * expression statements (see op_is_cond_expr), whose operators are
             * blank-separated.
             *
             * The depth test used to apply to EVERY statement, so a macro call
             * whose operand broke inside an unclosed sublist swallowed its remark:
             *
             *   XCTLTABL ID=(NAME,SECLOADA,,IFG0195V,             Y02134X
             *          ,IGG03001,,IGG0290A,...
             *
             * joined as `...IFG0195V,   Y02134,IGG03001,...`, so the change-level
             * tag became a sublist element, the macro generated its DC under that
             * name, and every reference to the real one was an undefined symbol
             * addressed through no USING -- IFO209 on a module IFOX00 assembles
             * clean (cc370#154).  Dropping the test outright is not the fix: it
             * breaks AIF and SETB, whose expressions legitimately contain blanks,
             * and takes the DCB common-interface block with them (#63). */
            int j, q = 0, d = 0, broke = 0;
            for (j = os; j < a; j++) { char ch = acc[j];
                /* An ATTRIBUTE apostrophe is not a quote here either (#184), and
                 * inside a string an apostrophe can only close one -- the same
                 * pair of rules parse() needed in #182 and split_card() in #183.
                 * Without the first, `MYM L'A,BB,   REMARK' continued onto a
                 * second card folded the remark into the joined statement and the
                 * trailing parameter resolved to nothing: IFOX00 assembles
                 * DC C'CC', as370 assembled DC C'' (tests/contattr.s). Without
                 * the second, the closing quote of a string ending in an
                 * attribute letter reads as an attribute and the string never
                 * closes -- that is the omission that cost 96 decks in #182. */
                if (ch == '\'') { if (q || !attr_apos(acc, j)) q = !q; }
                else if (!q && ch == '(') d++;
                else if (!q && ch == ')') { if (d) d--; }
                else if (!q && (d == 0 || !condexpr) && (ch == ' ' || ch == '\t')) { a = j; broke = 1; break; }
            }
            /* A blank ends the operand FIELD; whether the STATEMENT continues is a
             * different question, and the answer is the last character before it.
             * An operand broken mid-list ends on a comma and the next card carries
             * the rest -- `DSORG=PS,MACRF=(GM),' + `DDNAME=SYSIN'. A complete one
             * does not, and then the next card continues the REMARK and belongs to
             * no statement. Conflating the two drops the continuation of every
             * DCB, GETMAIN and continued DC in the suite. */
            if (broke) { int t2 = a; while (t2 > os && (acc[t2-1] == ' ' || acc[t2-1] == '\t')) t2--;
              if (t2 > os && acc[t2-1] != ',') opnd_ended = 1; }
            const char *c = in[i]; int cl = rawlen(c), s = 15, e = cl > 71 ? 71 : cl;
            check_cont_card(c, cl, i + 1, stmt_card, 0, (cl > 71 && c[71] != ' '));   /* IFO026: RFCCHK checks every continuation card, not just a comment's */
            if (!opnd_ended) { for (; s < e && a < 8190; s++) acc[a++] = c[s]; }
            cont = (cl > 71 && c[71] != ' ');
            i++;
        }
        acc[a++] = '\n'; acc[a] = 0;
        out[no++] = strdup(acc);
    }
    return no;
}
/* the operation field of a raw card, compared case-insensitively (the joiner
 * runs before parse() has ever seen the statement) */
static int card_op_is(const char *l, const char *op) {
    int i = 0, len = rawlen(l), s, k, nt, ol = (int)strlen(op);
    if (len > 71) len = 71;
    if (l[0] == '*' || (l[0] == '.' && l[1] == '*')) return 0;      /* a comment card has no operation field */
    if (i < len && l[i] != ' ' && l[i] != '\t') while (i < len && l[i] != ' ' && l[i] != '\t') i++;   /* name field */
    while (i < len && (l[i] == ' ' || l[i] == '\t')) i++;
    s = i; while (i < len && l[i] != ' ' && l[i] != '\t') i++;
    nt = i - s;
    if (nt != ol) return 0;
    for (k = 0; k < nt; k++) if (toupper((unsigned char)l[s + k]) != op[k]) return 0;
    return 1;
}
/* IFOX00 reads a LIBRARY macro definition to its MEND and not one card further.
 * That matters because SYS1.MACLIB members routinely carry their PL/S source as
 * comment cards AFTER the MEND, and some of those cards reach column 72:
 * IEFJESCT's MEND is at record 57 and its two continued cards are at 81 and 112,
 * GETMAIN's MEND is at 416 and its card is at 419.
 *
 * Measured on the guest: `IEFJESCT ,` assembles RC 0 -- with LIBMAC too, so the
 * cards are not merely unlisted -- while the same shape INSIDE a definition
 * draws IFO026 and swallows the model statement behind it (JOB02869). The
 * trailing text is simply never read. as370 read the whole member into the
 * joiner and warned on cards IFOX never sees, which is where every one of the
 * 33 warnings the ecosystem suddenly had came from.
 *
 * COPY is the other half of the same measurement and is NOT this case: `COPY
 * IEFJESCT` reads the member entire and DOES flag both cards (JOB02866), so
 * only a macro read stops at MEND. */
static int macro_extent(char **in, int n) {
    int i, depth = 0;
    for (i = 0; i < n; i++) {
        if (card_op_is(in[i], "MACRO")) depth++;
        else if (card_op_is(in[i], "MEND") && depth && --depth == 0) return i + 1;
    }
    return n;
}
static int lib_readlines(const char *name, char *buf[], int max, char (*seqbuf)[12], int as_macro) {
    char path[256]; if (!lib_path(name, path)) return -1;
    FILE *f = fopen(path, "r"); if (!f) return -1;
    static char *tmp[16384]; char lb[256]; int n = 0;
    while (fgets(lb, sizeof lb, f) && n < 16384) tmp[n++] = strdup(lb);
    fclose(f);
    if (n >= 16384) fprintf(stderr, "as370: library member %s is longer than 16384 cards and was cut\n", name);
    if (as_macro) n = macro_extent(tmp, n);   /* a macro definition ends at MEND; what follows is not read */
    { int r; const char *sv = g_joinsrc;    /* a continuation diagnostic in here names the member, not a source line */
      g_joinsrc = name; r = join_cont(tmp, n, buf, max, seqbuf, NULL); g_joinsrc = sv; return r; }
}
static void mac_body_add(struct macro *m, const char *card, const char *seq) {
    if (m->nbody >= m->bodycap) {
        int nc = m->bodycap ? m->bodycap * 2 : 64;
        char **nb = realloc(m->body, (size_t)nc * sizeof *nb);
        char **ns = realloc(m->bodyseq, (size_t)nc * sizeof *ns);
        if (!nb || !ns) { free(nb); free(ns); fprintf(stderr, "as370: out of memory for a macro body\n"); exit(2); }
        m->body = nb; m->bodyseq = ns; m->bodycap = nc;
    }
    m->bodyseq[m->nbody] = seq ? strdup(seq) : NULL;
    m->body[m->nbody++] = strdup(card);
}
static struct macro *capture_macro(char **in, int nin, int *ip, char (*inseq)[12]) {
    int i = *ip + 1; if (i >= nin) { *ip = i; return NULL; }
    char pb[4096], pl[32], po[16], pp[4096]; strncpy(pb, in[i], 4095); pb[4095] = 0; parse(pb, pl, po, pp);
    { const char *p = pb;                 /* re-extract the full prototype operand (parse caps at STMTSZ-1; DCB's list is longer) */
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
    if (pp[0]) { static char flds[MAXPARM][FLDW]; int nf = split_fields(pp, flds, MAXPARM), k;
        if (g_fld_clipped) note_operr("parameter in macro prototype or macro instruction exceeds 255 characters (IFOX00 IFO042)", 8, g_curln);
        for (k = 0; k < nf && k < MAXPARM; k++) { char *eq = strchr(flds[k], '=');
            if (eq) { *eq = 0; scopy(m->pname[k], flds[k], 19); scopy(m->pdef[k], eq + 1, VALSZ - 1); m->pkey[k] = 1; }
            else scopy(m->pname[k], flds[k], 19);
            m->nparm++; } }
    while (++i < nin) { char bb[STMTSZ], bl[32], bo[16], bd[STMTSZ]; scopy(bb, in[i], STMTSZ - 1); parse(bb, bl, bo, bd);
        if (!strcmp(bo, "MEND")) { if (bl[0] == '.') scopy(m->endlbl, bl, sizeof m->endlbl - 1); break; }
        mac_body_add(m, in[i], inseq ? inseq[i] : NULL); }
    *ip = i; return m;
}
static struct macro *lib_load(const char *name) {
    struct macro *m = mac_find(name); if (m) return m;
    /* LIBMAX bounds the STATEMENTS a library macro may hold. At 4,096 it cut
     * NETSOL (6,881 cards) in the reader, before capture_macro ever saw it, so
     * raising only the body array would have moved the cut and not removed it.
     * Both are lifted; this one is loud if it is ever reached. */
    enum { LIBMAX = 65536 };
    static char **buf; static char (*seqbuf)[12];
    if (!buf) { buf = malloc(LIBMAX * sizeof *buf); seqbuf = malloc((size_t)LIBMAX * 12);
        if (!buf || !seqbuf) { fprintf(stderr, "as370: out of memory for the macro library buffer\n"); exit(2); } }
    int n = lib_readlines(name, buf, LIBMAX, seqbuf, 1); if (n < 0) return NULL;   /* a macro: stops at MEND */
    if (n >= LIBMAX) fprintf(stderr, "as370: macro %s is longer than %d statements and was cut\n", name, LIBMAX);
    int i = 0; for (; i < n; i++) { char b[STMTSZ], l[32], o[16], od[STMTSZ]; scopy(b, buf[i], STMTSZ - 1);
        if (!parse(b, l, o, od) || !o[0]) continue;
        if (strcmp(o, "MACRO")) return NULL;
        break; }
    if (i >= n) return NULL;
    return capture_macro(buf, n, &i, seqbuf);
}
static int known_op(const char *o) {
    if (op_find(o)) return 1;
    const char *d[] = { "CSECT", "START", "ENTRY", "EXTRN", "WXTRN", "USING", "DROP", "DS", "DC", "EQU", "LTORG", "END",
                        "COPY", "MACRO", "MEND", "DSECT", "ORG", "TITLE", "PRINT", "SPACE", "EJECT", "CNOP", "PUSH", "POP", "CCW", "ISEQ", "REPRO", NULL };
    int i; for (i = 0; d[i]; i++) if (!strcmp(o, d[i])) return 1; return 0;
}

/* IFO220 ALIGNMENT ERROR: the boundary a storage operand must lie on, or 0 for
 * an instruction that has no requirement. IFOX00 issues it at severity 4 and
 * assembles the instruction unchanged -- it is a warning about the ADDRESS, not
 * about the encoding, which is why all fourteen modules carrying it have a
 * byte-identical deck and disagree with us only on the return code.
 *
 * It is checked ONLY where the operand is a symbol the assembler resolved
 * itself. Written with an explicit base -- `C R8,350(,R3)' -- the runtime
 * address depends on the register and cannot be known here, and IFOX00 does not
 * check it: IGC017 has exactly that pair, one of each, and only the symbol is
 * flagged. That single module is what separates the rule from "the displacement
 * is odd"; without it the rule over-predicts and looks right on thirteen. */
static int op_align(const char *o) {
    static const struct { const char *n; int a; } t[] = {
        { "L", 4 }, { "ST", 4 }, { "A", 4 }, { "AL", 4 }, { "S", 4 }, { "SL", 4 },
        { "C", 4 }, { "CL", 4 }, { "N", 4 }, { "O", 4 }, { "X", 4 },
        { "M", 4 }, { "D", 4 }, { "LM", 4 }, { "STM", 4 }, { "CS", 4 },
        { "LCTL", 4 }, { "STCTL", 4 },
        /* NOT BXH/BXLE. Their storage operand is a BRANCH TARGET, not a data
         * reference: it needs only the halfword alignment every instruction
         * already has, and IFOX00 does not check it. Including them cost 95
         * false positives -- 188 diagnostics, and every single one of the 95
         * modules was one of these two mnemonics and nothing else, which is
         * what made the tally conclusive rather than suggestive. */
        { "LE", 4 }, { "STE", 4 }, { "AE", 4 }, { "SE", 4 }, { "ME", 4 },
        { "DE", 4 }, { "CE", 4 }, { "AU", 4 }, { "SU", 4 },
        { "LH", 2 }, { "STH", 2 }, { "AH", 2 }, { "SH", 2 }, { "CH", 2 }, { "MH", 2 },
        { "LD", 8 }, { "STD", 8 }, { "AD", 8 }, { "SD", 8 }, { "MD", 8 },
        { "DD", 8 }, { "CD", 8 }, { "AW", 8 }, { "SW", 8 }, { "MXD", 8 },
        { "CVB", 8 }, { "CVD", 8 }, { "CDS", 8 }, { "LPSW", 8 },
        { NULL, 0 } };
    int k; for (k = 0; t[k].n; k++) if (!strcmp(o, t[k].n)) return t[k].a;
    return 0;
}
static void note_align(const char *o, int sy, long ea, int line) {
    int a = sy ? op_align(o) : 0;
    if (a && (ea % a)) {
        char m[VALSZ];
        snprintf(m, sizeof m, "Alignment error - %s needs a %d-byte boundary and the operand resolves to x'%lX' (IFOX00 IFO220)", o, a, ea);
        note_operr(m, 4, line);
    }
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
        int isg = (op[0] == 'G'); char fl[24][FLDW]; int nf = split_fields(opnd, fl, 24), j;
        for (j = 0; j < nf; j++) { char *lp = strchr(fl[j], '(');
            if (lp) { if (c->narr < 48) { int b2 = (int)(lp - fl[j]); if (b2 > 19) b2 = 19; memcpy(c->arrb[c->narr], fl[j], b2); c->arrb[c->narr][b2] = 0; c->arrnum[c->narr] = (op[3] != 'C'); c->narr++; }
                       if (isg) mark_global(fl[j]); }  /* array */
            else if (isg) { mark_global(fl[j]); if (!set_find(c, fl[j])) set_put(c, fl[j], op[3] == 'C' ? "" : "0"); }
            else set_put(c, fl[j], op[3] == 'C' ? "" : "0"); }
        return 1;
    }
    if (!strcmp(op, "SETA")) { long v = eval_seta(c, opnd); char nb[24]; sprintf(nb, "%ld", v); char sn[40]; set_canon(c, lbl, sn); set_put(c, sn, nb); return 1; }
    if (!strcmp(op, "SETB")) { int v = opnd[0] == '(' ? eval_cond(c, opnd + 1) : (int)eval_seta(c, opnd); char sn[40]; set_canon(c, lbl, sn); set_put(c, sn, v ? "1" : "0"); return 1; }
    if (!strcmp(op, "SETC")) { char v[VALSZ]; eval_setc(c, opnd, v, sizeof v); char sn[40]; set_canon(c, lbl, sn); set_put(c, sn, v); return 1; }
    if (!strcmp(op, "ANOP")) return 1;
    return 0;
}
/* Split a card (cols 1-72) into name / operation / operand / remarks, keeping
 * each field's start column. The operand stops at the first blank that is
 * outside quotes and outside parentheses; the remarks field is then everything
 * up to col 72, internal blanks included. A sequence-symbol name (.NAME) is
 * dropped -- it is not a name field.
 *
 * SEQCOL is where the fields stop. For a LISTING IMAGE that is column 72, so
 * the library sequence number in 73-80 is not mistaken for text. For SPLITTING
 * A STATEMENT it must be the card's full length: mexp_line is handed JOINED
 * continuation cards, hundreds of characters long, and stopping at 72 silently
 * truncates the operand -- which is how BLSCAMOD lost 8 bytes off a constant
 * whose value continues onto a second card. */
#define FLDMAX 1024
static void split_card(const char *model, int mlen, int seqcol, int *fcol, char fld[4][FLDMAX]) {
    int p = 0, k;
    for (k = 0; k < 4; k++) { fcol[k] = 0; fld[k][0] = 0; }
    if (p < mlen && model[0] != ' ') {
        int q = 0; while (p < mlen && p < seqcol && model[p] != ' ') { if (q < FLDMAX-1) fld[0][q++] = model[p]; p++; }
        fld[0][q] = 0; if (fld[0][0] == '.') fld[0][0] = 0;
    }
    while (p < mlen && p < seqcol && model[p] == ' ') p++;
    if (p < mlen && p < seqcol) { fcol[1] = p; int q = 0; while (p < mlen && p < seqcol && model[p] != ' ') { if (q < FLDMAX-1) fld[1][q++] = model[p]; p++; } fld[1][q] = 0; }
    while (p < mlen && p < seqcol && model[p] == ' ') p++;
    if (p < mlen && p < seqcol) { fcol[2] = p; int q = 0, inq = 0, dep = 0;
        while (p < mlen && p < seqcol) { char ch = model[p];
            /* `inq ||' for the same reason parse() needs it (#149): attr_apos()
             * is purely lexical, so on its own it reads the CLOSING quote of a
             * string whose last character is an attribute letter -- 'S', 'L',
             * C'ADD 1 TO N' -- as an attribute apostrophe, and the string never
             * closes.  In parse() that cost 96 decks their identity.  Here it
             * cannot: split_card() feeds the listing image and the substitution
             * splitter, and every field is substituted anyway, so the operand
             * boundary it computes is not the one that gets assembled.  It is
             * fixed regardless, because "cannot move a deck" is a claim about
             * today's assembler and #141 is about to make substitution
             * field-aware -- at which point this misreading stops being latent
             * and starts deciding which field a remark belongs to. */
            if (ch == '\'' && (inq || !attr_apos(model, p))) inq = !inq;
            else if (!inq && ch == '(') dep++; else if (!inq && ch == ')') { if (dep) dep--; }
            if (ch == ' ' && !inq && dep == 0) break;
            if (q < FLDMAX-1) { fld[2][q++] = ch; } p++; }
        fld[2][q] = 0; }
    while (p < mlen && p < seqcol && model[p] == ' ') p++;
    if (p < mlen && p < seqcol) { fcol[3] = p; int q = 0; while (p < mlen && p < seqcol) { if (q < FLDMAX-1) fld[3][q++] = model[p]; p++; } fld[3][q] = 0; }
}
/* Render a model statement for the listing's SOURCE column, the way IFOX does
 * it: each field keeps the *start column it had in the model card*, and cols
 * 73-80 (the library sequence number) are carried through verbatim. So `&NAME
 * B ...` with &NAME empty still prints `B` in its model column, and an operand
 * that grows/shrinks under substitution leaves the comment anchored where the
 * model put it. The substituted operand may overflow its model width; a
 * following field is then pushed right by one blank rather than overwritten.
 *
 * KEEPUNRES leaves a reference that resolves to nothing verbatim, and FIELDS is
 * the set of fields to substitute -- 0xF for a macro model statement, 0x7 in
 * open code, where the remarks field is not substituted (remark_sub.s). */
static void render_model_ex(struct ctx *c, const char *model, const char *seq, char *out,
                            int fields, int keepunres) {
    char ln[256]; int i; for (i = 0; i < 255; i++) { ln[i] = ' '; } ln[255] = 0;
    int seqcol = 72;                                  /* a card is 80 cols; the sequence number sits at 73-80 (index 72-79) */
    int mlen = (int)strlen(model); while (mlen > 0 && (model[mlen-1]=='\n'||model[mlen-1]=='\r')) mlen--;
    int fcol[4]; char fld[4][FLDMAX];
    split_card(model, mlen, seqcol, fcol, fld);
    int cur = 0;
    for (i = 0; i < 4; i++) {
        if (!fld[i][0]) continue;
        char sub[FLDMAX * 2];
        if (fields & (1 << i)) msub_ex(c, fld[i], sub, sizeof sub, keepunres);
        else scopy(sub, fld[i], sizeof sub - 1);
        int col = fcol[i]; if (col < cur) col = cur;   /* never overwrite the previous field */
        int sl = (int)strlen(sub), j; for (j = 0; j < sl && col + j < 255; j++) ln[col + j] = sub[j];
        cur = col + sl + 1;                            /* at least one blank before the next field */
    }
    /* carry the library sequence number (cols 73-80) through verbatim */
    if (seq) { int j; for (j = 0; j < 8 && seq[j]; j++) ln[seqcol + j] = seq[j]; }
    int n = 255; while (n > 0 && ln[n-1] == ' ') n--; ln[n] = 0;   /* trim trailing blanks */
    strcpy(out, ln);
}
static void render_model(struct ctx *c, const char *model, const char *seq, char *out) {
    render_model_ex(c, model, seq, out, 0xF, 0);
}
/* expand a macro invocation, interpreting conditional assembly */
static void mexp_macro(struct macro *m, const char *lbl, const char *opnd, char **out, int *nout, int depth) {
    g_genlevel++;   /* lines emitted during this expansion are macro-generated */
    int savecopyraw = g_copyraw; g_copyraw = 0;   /* a macro body is model statements, whatever the call arrived on */
    struct ctx *savecopyctx = g_copyctx;   /* a COPY inside THIS body substitutes from THIS expansion's variables */
    /* ctx and the sequence-symbol table live on the HEAP, not on this frame.
     * Measured: sizeof(struct ctx) is 78,240 and seqn/seqi add 49,152, so a level
     * costs 127,392 bytes -- and mexp_macro is reached only through mexp_line's
     * `depth <= 40' guard, so the worst case was 4.86 MB of stack. That coupled
     * every per-context table to the nesting depth: #195 raised MAXLSET from 256
     * to 512 for a measured need of 303 and spent ~1.2 MB of headroom doing it,
     * and #173's three survivors need it past 512 and could not have it
     * (cc370#196). On the heap the two are independent again.
     *
     * There is exactly one exit path -- no return statement in this function --
     * so one free at the end covers it. The table-full paths call exit(2), where
     * leaking is the process ending. */
    struct ctx *c = calloc(1, sizeof *c);
    g_copyctx = c;
    char (*seqn)[20] = malloc(2048 * 20);
    int *seqi = malloc(2048 * sizeof *seqi);
    /* the split operand list: MAXSYSLIST x FLDW is 64 KB, too much for a frame
     * of a function that recurses once per nested macro, so it goes beside the
     * context and is freed on the same single exit path */
    char (*args)[FLDW] = malloc((size_t)MAXSYSLIST * FLDW);
    if (!c || !seqn || !seqi || !args) { fprintf(stderr, "as370: out of memory expanding macro %s\n", m->name); exit(2); }
    c->m = m; c->namepval = lbl; c->sysndx = ++g_sysndx;
    scopy(c->sysect, g_sysect, 8);          /* frozen here, for the whole expansion */
    int k;
    for (k = 0; k < m->nparm; k++) { scopy(c->pv[k], m->pkey[k] ? m->pdef[k] : "", VALSZ - 1); }
    if (opnd[0]) { int na = split_fields(opnd, args, MAXSYSLIST), pos = 0;
        /* IFOX00 IFO042, measured on the guest: 255 characters is clean, 256 and
         * up are flagged at severity 8.  A parameter that long is cut to fit
         * whatever we do -- what must not happen is cutting it in silence. */
        if (g_fld_clipped) note_operr("parameter in macro prototype or macro instruction exceeds 255 characters (IFOX00 IFO042)", 8, g_curln);
        for (k = 0; k < na; k++) {
            char *eq = strchr(args[k], '='); int iskw = eq && eq != args[k];
            if (iskw) { char *cc; for (cc = args[k]; cc < eq; cc++) if (!isalnum((unsigned char)*cc) && *cc!='@'&&*cc!='#'&&*cc!='$'&&*cc!='_') { iskw = 0; break; } }
            if (iskw) { *eq = 0; int j, kwhit = 0; char nm[66]; snprintf(nm, sizeof nm, "&%.63s", args[k]);
                for (j = 0; j < m->nparm; j++) if (!strcmp(nm, m->pname[j])) { scopy(c->pv[j], eq + 1, VALSZ - 1); kwhit = 1; break; }
                /* A keyword the prototype does not declare is IFOX00 IFO092
                 * KEYWORD PARAMETER <name> UNDEFINED IN MACRO DEFINITION, severity
                 * 8, ONE message per keyword -- and the expansion goes ahead
                 * anyway (tests/kwundef.s: all four calls generate their DC and
                 * IFOX00 counts two flagged STATEMENTS for three messages).
                 *
                 * Generating anyway is the whole point and not a leniency: the 118
                 * modules this reaches already have decks byte-identical to
                 * IFOX00's, because MODID emits nothing for an operand it does not
                 * know and neither do we. Refusing the call would turn 115
                 * identities into differences. The divergence is the RETURN CODE,
                 * which as370 could not see while it only compared bytes.
                 *
                 * The cause is not ours: SYS1.AMACLIB(MODID) on the target is an
                 * older maintenance level than the source that calls it, and its
                 * own comments name the PTF that added `PTF=' (cc370#162). */
                if (!kwhit) { char msg[128];
                    snprintf(msg, sizeof msg, "keyword parameter %.40s is not declared in the macro prototype (IFOX00 IFO092)", args[k]);
                    /* note_operr's third argument is a lines[] SLOT, not a source
                     * line, and g_curln is neither during an expansion. The call
                     * line is what IFOX00 attributes it to, and g_mcall_slot is
                     * kept for exactly that. */
                    note_operr(msg, 8, g_mcall_slot); } }
            else { int j, cc2 = 0; for (j = 0; j < m->nparm; j++) if (!m->pkey[j]) { if (cc2 == pos) { scopy(c->pv[j], args[k], VALSZ - 1); break; } cc2++; }
                if (pos < MAXSYSLIST) { scopy(c->syslist[pos], args[k], VALSZ - 1); }
                else if (pos == MAXSYSLIST) note_operr("More than 255 positional macro operands - the rest are not addressable through &SYSLIST", 8, g_curln);
                pos++; c->nsyslist = pos; }
        }
    }
    /* prescan sequence-symbol labels */
    int nseq = 0;   /* stack-local (mexp_macro recurses for nested macros); big enough for DCBD/CVT/IKJTCB */
    for (k = 0; k < m->nbody; k++) if (m->body[k][0] == '.' && m->body[k][1] != '*') {
        char sl[20]; int j = 0; const char *q = m->body[k]; while (*q && !isspace((unsigned char)*q) && j < 19) sl[j++] = *q++; sl[j] = 0;
        if (nseq < 2048) { strcpy(seqn[nseq], sl); seqi[nseq] = k; nseq++; }
    }
    if (m->endlbl[0] && nseq < 2048) { strcpy(seqn[nseq], m->endlbl); seqi[nseq] = m->nbody; nseq++; }
    int pc = 0, guard = 0;
    while (pc < m->nbody && guard++ < 100000) {
        char bb[STMTSZ], bl[32], bo[16], bod[STMTSZ];
        if (m->body[pc][0] == '*' || (m->body[pc][0] == '.' && m->body[pc][1] == '*')) { pc++; continue; }  /* macro comment */
        scopy(bb, m->body[pc], STMTSZ - 1); parse(bb, bl, bo, bod);
        if (!bo[0]) { pc++; continue; }
        if (!strcmp(bo, "MEND") || !strcmp(bo, "MEXIT")) break;
        if (!strcmp(bo, "MNOTE")) {
            /* Substitute first: the whole point of an MNOTE is to name the
             * caller's parameter, and `MNOTE 8,'BAD OPTION &OPT'' is the usual
             * shape. Then emit it as a generated listing line -- LF_NOASM so the
             * core never tries to assemble the rendered text, LF_GEN so it
             * carries the '+' every other generated card does. */
            char mex[STMTSZ]; msub(c, m->body[pc], mex, sizeof mex);
            char mb[STMTSZ], ml[32], mo[16], mod[STMTSZ];
            scopy(mb, mex, STMTSZ - 1); parse(mb, ml, mo, mod);
            char mtext[256], mimg[256]; int mcom = 0;
            int msev = mnote_split(mod, mtext, sizeof mtext, mimg, sizeof mimg, &mcom);
            if (*nout < MAXLINES) {
                /* lines[] keeps the SUBSTITUTED MNOTE statement so the stderr
                 * card print shows what the macro actually wrote; gcard carries
                 * the rendered image the listing column wants. */
                lflags[*nout] = LF_GEN | LF_NOASM; gcard[*nout] = strdup(mimg);
                line_org[*nout] = g_curorg; out[*nout] = strdup(mex);
                note_mnote(msev, mtext, *nout);
                (*nout)++;
            }
            pc++; continue;
        }
        if (!strcmp(bo, "PRINT") || !strcmp(bo, "SPACE") || !strcmp(bo, "EJECT") || !strcmp(bo, "ACTR")) { pc++; continue; }
        { g_ca_slot = g_mcall_slot;                          /* a substring error in the body points at the call */
          int isca = set_stmt(c, bl, bo, bod); g_ca_slot = -1;
          if (isca) { pc++; continue; } }                     /* GBLx/LCLx/SETA/SETB/SETC/ANOP */
        if (!strcmp(bo, "AIF")) { char cond[512], seq[20]; aif_split(bod, cond, sizeof cond, seq, sizeof seq);
            if (eval_cond(c, cond)) { int j, t = -1; for (j = 0; j < nseq; j++) if (!strcmp(seqn[j], seq)) { t = seqi[j]; break; } if (t >= 0) { pc = t; continue; } }
            pc++; continue; }
        if (!strcmp(bo, "AGO")) { int j, t = -1; for (j = 0; j < nseq; j++) if (!strcmp(seqn[j], bod)) { t = seqi[j]; break; } if (t >= 0) { pc = t; continue; } pc++; continue; }
        /* model statement (or nested macro call) */
        /* Substitute only as far as the REMARK.
         *
         * An operand that substitutes to NOTHING has to leave an EMPTY operand.
         * as370 substituted the whole card and re-parsed it, and parse() cannot
         * tell `INNER          REMARK HERE' -- an operand that vanished -- from a
         * card written that way, so it read the remark's first word as the
         * operand. BLSCAMMM calls `BLSCAMM1 &DYRB(2)         COUNT FLAGS1 ENTRIES'
         * with &DYRB not a sublist, so &DYRB(2) is null and the counting macro was
         * handed the string COUNT: one element instead of none, a loop that should
         * not run, and an MNOTE from a macro complaining about input we invented
         * (cc370#295).
         *
         * The remark is not lost: `ex' is the semantic text and the listing image
         * comes from render_model() below, which is column-preserved and reads the
         * body card whole. Cutting here costs nothing the listing needs. */
        char ex[STMTSZ];
        { const char *bc = m->body[pc]; int bl = rawlen(bc);
          int fcol[4]; static char fld[4][FLDMAX];
          split_card(bc, bl, bl, fcol, fld);
          int keep = (fcol[3] > 0 && fcol[3] < bl) ? fcol[3] : bl;
          char cut[STMTSZ]; if (keep > STMTSZ - 1) keep = STMTSZ - 1;
          memcpy(cut, bc, (size_t)keep); cut[keep] = 0;
          msub(c, cut, ex, sizeof ex); }
        char gimg[256]; render_model(c, m->body[pc], m->bodyseq[pc], gimg); g_genimg = gimg;   /* column-preserved image for the SOURCE column */
        mexp_line(ex, out, nout, depth + 1);
        pc++;
    }
    g_genlevel--; g_copyraw = savecopyraw; g_copyctx = savecopyctx;
    set_free(c); free(c); free(seqn); free(seqi); free(args);
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
static void sysvar_sub(const char *src, char *dst, size_t dstsz) {
    int di = 0, lim = (int)dstsz - 2; const char *s = src;
    if (lim < 0) lim = 0;
    while (*s && di < lim) {
        if (*s == '&' && s[1] == '&') { dst[di++] = '&'; if (di < lim) dst[di++] = '&'; s += 2; continue; }
        if (*s == '&') {
            const char *p = s + 1; char nm[12]; int i = 0;
            while (*p && isalpha((unsigned char)*p) && i < 10) nm[i++] = *p++;
            nm[i] = 0;
            if (!strcmp(nm, "SYSDATE") || !strcmp(nm, "SYSTIME")) {
                const char *v = nm[3] == 'D' ? g_sysdate : g_systime;
                while (*v && di < lim) dst[di++] = *v++;
                s = p; if (*s == '.') s++;   /* swallow the concatenation dot */
                continue;
            }
            dst[di++] = '&'; s++; continue;
        }
        dst[di++] = *s++;
    }
    dst[di] = 0;
}
/* Is this one of the conditional-assembly statements set_stmt interprets? Asked
 * BEFORE set_stmt runs, because the statement needs a lines[] slot to exist so a
 * diagnostic raised while evaluating it has something to attach to. */
static int is_ca_op(const char *op) {
    return !strncmp(op, "GBL", 3) || !strncmp(op, "LCL", 3) ||
           !strcmp(op, "SETA") || !strcmp(op, "SETB") || !strcmp(op, "SETC") ||
           !strcmp(op, "ANOP");
}
/* Does this card carry a variable symbol that substitution has to resolve?
 *
 * Only the name, operation and operand fields count. The REMARKS field is not
 * substituted -- IFOX00's FEVAL60 moves it with no preceding GOIF and jtext.asm
 * has no JSUBCMNT flag, and tests/remark_sub.s shows '&X' and a bare '&'
 * surviving verbatim onto the generated line. That is not a nicety: IBM ships
 * 2030 bare ampersands in open-code remarks across 716 MVSBLD modules, and a
 * whole-card substitution deletes every one of them.
 *
 * '&&' is a doubled ampersand, not a reference, and does not make a card a model
 * statement (tests/amp_fold.s assembles with no substitution at all). A lone '&'
 * that names nothing does not either.
 *
 * Tested on the card BEFORE sysvar_sub: &SYSDATE is a system global and pairs
 * like any other substitution (tests/remark_sub.s, statements 26 and 27+). */
static int has_varsym(const char *card) {
    int fcol[4]; char fld[4][FLDMAX]; int i;
    int ml = (int)strlen(card); while (ml > 0 && (card[ml-1] == '\n' || card[ml-1] == '\r')) ml--;
    split_card(card, ml, ml, fcol, fld);   /* a reference can sit past column 72 of a joined card */
    for (i = 0; i < 3; i++) {
        const char *q = fld[i];
        while (*q) {
            if (*q == '&' && q[1] == '&') { q += 2; continue; }
            if (*q == '&' && (isalpha((unsigned char)q[1]) || q[1]=='@' || q[1]=='#' || q[1]=='$' || q[1]=='_')) return 1;
            q++;
        }
    }
    return 0;
}
/* Which variables a statement's symbols resolve against. A COPY'd block inside
 * a macro expansion is part of that macro's body -- IFOX00 splices the member in
 * during its edit phase -- so its model statements AND its conditional assembly
 * see the enclosing expansion's variables, not open code's. Everywhere else this
 * is the shared open-code context, unchanged. */
static struct ctx *cur_ctx(void) { return (g_copyraw > 0 && g_copyctx) ? g_copyctx : &g_opc; }
static void mexp_line(const char *line, char **out, int *nout, int depth) {
    /* A card a COPY brings into a macro expansion is a MODEL statement of that
     * expansion: IFOX00 splices the member into the body in its edit phase, so
     * its variable symbols are the enclosing macro's, not open code's. as370
     * expands COPY lazily and substituted nothing into such a card at all --
     * ICOMMON's `&COMPNM.X4V01 CONTAINS ...' reached CONTAINS with the LITERAL
     * name, which a `(4,5)' substring three macros later turned into `MPNM.'
     * and an undefined symbol 900 statements after that (cc370#307). */
    struct ctx *opc = cur_ctx();
    const char *img = g_genimg; g_genimg = NULL;   /* the SOURCE-column image for the one line this call emits (cleared so recursion does not inherit it) */
    char sysbuf[STMTSZ]; sysvar_sub(line, sysbuf, sizeof sysbuf);   /* resolve &SYSDATE/&SYSTIME up front */
    char buf[STMTSZ], lbl[32], op[16], opnd[STMTSZ];
    scopy(buf, sysbuf, STMTSZ - 1);
    { int sv = g_genstmt; g_genstmt = (g_genlevel > 0 && !g_copyraw); parse(buf, lbl, op, opnd); g_genstmt = sv; }
    /* open-code (and COPY'd) conditional assembly: GBLx/LCLx/SETx/ANOP are
     * interpreted here (never reach the core, which would ignore them) so that
     * e.g. open-code `&FUNC SETC '...'` reaches a macro's `GBLC &FUNC`.
     *
     * The statement is LISTED, not swallowed. IFOX00 prints it under ALOGIC,
     * which is on by default (the fixtures' own OPTIONS line reads
     * `ALIGN, ALOGIC, ...`), and statement numbering counts it -- tests/
     * setc_open.s has the DC at statement 23 where as370 used to put it at 20.
     * It is listed only in OPEN CODE: NOMLOGIC is the default and IFOX00 lists
     * none of the 70 conditional statements inside tstlist's SAVE and RETURN. */
    /* MNOTE in open code: the same statement, listed without the '+' that marks
     * a generated card. IFOX00 numbers it and flags it exactly as it does one
     * from a macro body (cc370#39). */
    if (op[0] && !strcmp(op, "MNOTE")) {
        char mtext[256], mimg[256]; int mcom = 0;
        int msev = mnote_split(opnd, mtext, sizeof mtext, mimg, sizeof mimg, &mcom);
        if (*nout < MAXLINES) {
            lflags[*nout] = (unsigned char)(g_genlevel > 0 ? LF_GEN | LF_NOASM : LF_NOASM);
            gcard[*nout] = strdup(mimg); line_org[*nout] = g_curorg; out[*nout] = strdup(sysbuf);
            note_mnote(msev, mtext, *nout);
            (*nout)++;
        }
        return;
    }
    if (op[0] && is_ca_op(op)) {
        int slot = -1;
        if (g_genlevel == 0 && *nout < MAXLINES) {
            slot = *nout;
            lflags[slot] = LF_NOASM; gcard[slot] = img ? strdup(img) : NULL;
            line_org[slot] = g_curorg; out[slot] = strdup(sysbuf); (*nout)++;
        }
        g_ca_slot = slot;                  /* where a substring diagnostic attaches */
        int done = set_stmt(opc, lbl, op, opnd);
        g_ca_slot = -1;
        if (done) return;
        if (slot >= 0) { free(out[--(*nout)]); free((void *)gcard[*nout]); gcard[*nout] = NULL; }   /* not a CA statement after all */
    }
    if (op[0] && !strcmp(op, "COPY") && opnd[0] && depth <= 40) {
        /* COPY takes the member entire, and its members are as long as a macro's
         * -- LINEEND is 5,828 cards. The array is on the heap because mexp_line
         * recurses once per nesting level. */
        enum { COPYMAX = 65536 };
        char **cb = malloc(COPYMAX * sizeof *cb);
        if (!cb) { fprintf(stderr, "as370: out of memory for a COPY member\n"); exit(2); }
        int n = lib_readlines(opnd, cb, COPYMAX, NULL, 0);
        if (n >= COPYMAX) fprintf(stderr, "as370: COPY member %s is longer than %d statements and was cut\n", opnd, COPYMAX);
        /* g_copyraw: the member's cards are read from a library exactly as they
         * were written. Nothing is substituted into them here, so their fields
         * are delimited the ordinary way -- see LF_SUBST. */
        if (n >= 0) { g_copyraw++; mexp_block(cb, n, out, nout, depth + 1, NULL); g_copyraw--; free(cb); return; }   /* COPY'd block keeps the COPY statement's origin (g_curorg) */
        free(cb);
    }
    /* SUBSTITUTION IN OPEN CODE (#141). Everything above this point interprets
     * the statement; from here it is a MODEL statement, and its variable symbols
     * have to be resolved before anything looks at it.
     *
     * The order is forced, not chosen:
     *   - after set_stmt, because the name field of `&A SETC ...` IS the variable
     *     symbol. Substituting the whole card first leaves lbl empty and defines
     *     a symbol called "", and turns `LCLC &A,&B` into `LCLC ,`.
     *   - after COPY, because a member name is not a model field.
     *   - BEFORE the macro lookup, because IFOX00 substitutes the operation field
     *     and only then looks the op code up (ifnx3a.asm:576, then OPSC1 at 622).
     *   - before the CSECT tracking below, so `&N CSECT` records the substituted
     *     name as &SYSECT.
     * Only at generation level 0: text arriving from mexp_macro has been
     * substituted once already, and a second pass would resolve a reference the
     * first one deliberately left alone. */
    char genimg[256]; int subst = 0, opsubst = 0;
    /* A comment card is not a model statement. IFOX00 substitutes nothing in one
     * -- there is no field to substitute, the whole card is text -- and treating
     * it as one turns every '&' in a comment into a generated statement pair.
     * The fixture for this very issue has two such cards in its own header. */
    int iscmt = (line[0] == '*') || (line[0] == '.' && line[1] == '*');
    if ((g_genlevel == 0 || g_copyraw > 0) && !iscmt && op[0] && has_varsym(line)) {   /* the RAW card: &SYSDATE is a system global and pairs (remark_sub.s 26/27+) */
        int fcol[4]; char fld[4][FLDMAX];
        int ml = (int)strlen(sysbuf); while (ml > 0 && (sysbuf[ml-1] == '\n' || sysbuf[ml-1] == '\r')) ml--;
        split_card(sysbuf, ml, ml, fcol, fld);   /* the whole joined card, not 72 columns */
        char nmf[FLDMAX * 2], opf[FLDMAX * 2], odf[FLDMAX * 4];
        msub_ex(opc, fld[0], nmf, sizeof nmf, 1);
        msub_ex(opc, fld[1], opf, sizeof opf, 1);
        msub_ex(opc, fld[2], odf, sizeof odf, 1);
        opsubst = strcmp(fld[1], opf) != 0;
        render_model_ex(opc, sysbuf, NULL, genimg, 0x7, 1);   /* listing image: fields 0-2, remarks verbatim */
        /* The assembled card is built plainly rather than from the listing image:
         * the image is bounded by the 72-column card it is drawn on, and a
         * substituted operand can be far longer than the model it came from. */
        /* Name in column 1 padded to at least 8 -- an OVER-length name is kept
         * whole, not truncated, so it still reaches the IFO016 path -- then the
         * operation, then the operand. The remarks field is dropped: it is not
         * assembled, and the listing takes the column-preserved image above. */
        char ex[4096]; size_t k = 0;
        k = bcat(ex, sizeof ex, k, nmf);
        while (k < 8 && k + 1 < sizeof ex) ex[k++] = ' ';
        if (k + 1 < sizeof ex) ex[k++] = ' ';
        k = bcat(ex, sizeof ex, k, opf);
        if (k + 1 < sizeof ex) ex[k++] = ' ';
        k = bcat(ex, sizeof ex, k, odf);
        ex[k] = 0;
        scopy(sysbuf, ex, sizeof sysbuf - 1);
        scopy(buf, sysbuf, sizeof buf - 1); parse(buf, lbl, op, opnd);
        subst = 1;
    }
    struct macro *m = NULL;
    /* A SUBSTITUTED operation field cannot name a macro. IFOX00 resolves macro
     * calls in the edit phase, before substitution runs, so a generated op code
     * is looked up in the machine/assembler table alone: tests/var_opcode.s has
     * `&P SETC 'MYMAC'` generate `B MYMAC` and answers IFO101 GENERATED OP CODE
     * INVALID OR IS UNDEFINED rather than expanding it. as370's note_unknown
     * says the same thing in its own words, at the same severity. */
    if (op[0] && !known_op(op) && !opsubst && depth <= 40) { m = mac_find(op); if (!m) m = lib_load(op); }
    if (m) {   /* keep the macro call line itself for the listing (not assembled); its expansion is flagged generated */
        if (subst && *nout < MAXLINES) {   /* the model card, then the generated call */
            lflags[*nout] = LF_NOASM; gcard[*nout] = NULL; line_org[*nout] = g_curorg;
            out[*nout] = strdup(line); (*nout)++;
        }
        if (*nout < MAXLINES) { lflags[*nout] = (unsigned char)((g_genlevel > 0 || subst ? LF_GEN | LF_NOASM : LF_NOASM) | (subst || (g_genlevel > 0 && !g_copyraw) ? LF_SUBST : 0)); gcard[*nout] = subst ? strdup(genimg) : (img ? strdup(img) : NULL); line_org[*nout] = g_curorg; out[*nout] = strdup(sysbuf); (*nout)++; }
        /* HLASM substitutes the caller's variable symbols in a macro's arguments
         * in the caller's context. At open-code level resolve them from g_opc, so
         * e.g. `DCB MACRF=P&OUTM.M` binds &MACRF='PMM' (not the literal 'P&OUTM.M',
         * which the called macro -- not knowing &OUTM -- would mis-parse). Inside a
         * macro the enclosing expansion has already substituted them. The card-level
         * substitution above has already done it when it ran. */
        char aopnd[STMTSZ];
        if (subst || g_genlevel > 0) { strncpy(aopnd, opnd, sizeof aopnd - 1); aopnd[sizeof aopnd - 1] = 0; }
        else msub(opc, opnd, aopnd, sizeof aopnd);
        int savecall = g_mcall_slot; g_mcall_slot = *nout - 1;   /* the call line just appended */
        mexp_macro(m, lbl[0] == '.' ? "" : lbl, aopnd, out, nout, depth);
        g_mcall_slot = savecall; return;
    }
    /* A substituted model statement is listed TWICE, the way IFOX00 lists it:
     * the source card, print-only and with no location, then the generated card
     * carrying the object code and the '+'. tests/setc_open.s statements 23 and
     * 24+; tests/remark_sub.s 23/24+ and 26/27+. */
    if (subst && *nout + 1 < MAXLINES) {
        lflags[*nout] = LF_NOASM; gcard[*nout] = NULL; line_org[*nout] = g_curorg;
        out[*nout] = strdup(line); (*nout)++;
        img = genimg;
    }
    if (*nout >= MAXLINES) return;
    /* Track the section on EMISSION, not on input: a CSECT a macro generates is
     * open code by the time it lands here, so a later call sees it -- while the
     * expansion that produced it does not, because that one froze its copy at
     * entry.  Both halves of the measured behaviour fall out of that. */
    if (op[0] && (!strcmp(op, "CSECT") || !strcmp(op, "DSECT") ||
                  !strcmp(op, "START") || !strcmp(op, "COM")))
        scopy(g_sysect, (lbl[0] && lbl[0] != '.') ? lbl : "", 8);
    lflags[*nout] = (unsigned char)((g_genlevel > 0 || subst ? LF_GEN : 0) | (subst || (g_genlevel > 0 && !g_copyraw) ? LF_SUBST : 0));
    gcard[*nout] = img ? strdup(img) : NULL;
    line_org[*nout] = g_curorg;
    if (lbl[0] == '.') { char r[STMTSZ + 32]; snprintf(r, sizeof r, "         %s %s", op, opnd); out[(*nout)++] = strdup(r); }
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
        char sb[STMTSZ], sl[32], so[16], sd[STMTSZ]; scopy(sb, arr[k], STMTSZ - 1); parse(sb, sl, so, sd);
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
        char buf[STMTSZ], lbl[32], op[16], opnd[STMTSZ]; scopy(buf, arr[pc], STMTSZ - 1); parse(buf, lbl, op, opnd);
        if (!strcmp(op, "MACRO")) { capture_macro(arr, n, &pc, NULL); pc++; continue; }   /* COPY'd / inline macro definition */
        if (!strcmp(op, "AIF")) { char cond[512], seq[20]; aif_split(opnd, cond, sizeof cond, seq, sizeof seq);
            if (eval_cond(cur_ctx(), cond)) { int j, t = -1; for (j = 0; j < nseq; j++) if (!strcmp(seqn[j], seq)) { t = seqi[j]; break; } if (t >= 0) { pc = t; continue; } }
            pc++; continue; }
        if (!strcmp(op, "AGO")) { int j, t = -1; for (j = 0; j < nseq; j++) if (!strcmp(seqn[j], opnd)) { t = seqi[j]; break; } if (t >= 0) { pc = t; continue; } pc++; continue; }
        if (!strcmp(op, "REPRO") && pc + 1 < n) {
            /* The card is captured HERE and not in the assembly pass, because by
             * then it would have been through sysvar_sub and the model-statement
             * machinery: ICAPRTBL's IPL text holds bytes that read as `&' and as
             * `*' in the host charset, and one of them is a comment marker and
             * the other a variable symbol. It is punched as it stands, so it is
             * translated to EBCDIC and padded to 80 columns, nothing else. */
            int at = *nout;
            mexp_line(arr[pc], out, nout, depth);
            if (nrepro < MAXREPRO && *nout > at) {
                const unsigned char *card = NULL; int rl = 0, j;
                for (j = 0; j < nrepro_raw; j++)
                    if (repro_raw_line[j] == g_curorg) { card = repro_raw[j]; rl = 80; break; }
                if (!card) { card = (const unsigned char *)arr[pc + 1]; rl = rawlen(arr[pc + 1]); }
                for (j = 0; j < 80; j++)
                    repro_img[nrepro][j] = mvs_a2e(j < rl ? card[j] : ' ');
                repro_line[nrepro] = *nout - 1;
                nrepro++;
            }
            pc += 2; continue;                       /* the punched card is not a statement */
        }
        mexp_line(arr[pc], out, nout, depth);
        pc++;
    }
    free(seqn); free(seqi);
}
/* Length attributes read from the RAW source, before expansion.
 *
 * Conditional assembly runs while macros are expanded, and that is BEFORE
 * either assembly pass -- so when an `AIF' or `SETA' asks for L'SYM there is no
 * symbol table to ask. as370 answered with strlen of the variable's VALUE,
 * which is K' rather than L': `&LEN SETA L'&P(&RN)' in SYS1.AMACLIB(ENQ) gave 5
 * for an RNAME of MINOR where `MINOR DC CL8'..'' makes it 8, and line 170 puts
 * that straight into the object as `DC AL1(&LEN)'. Twelve modules differ in
 * nothing else (cc370#244).
 *
 * IFOX00 interleaves generation and assembly, so its answer simply exists.
 * Rather than reorder as370's phases, this walks the source cards once and
 * records what a length attribute would be for every label on a DC or DS. It
 * sees only open code -- a label generated inside an expansion is not here --
 * which is why an unknown symbol answers 1, the value IFOX00 gives for one it
 * cannot resolve either.
 *
 * Deliberately narrow: a length is recorded only where it is EXPLICIT or the
 * type fixes it, or where a quoted C/X body can be counted. Anything else is
 * left out so L' falls back to 1 instead of to a guess. */
struct prelen { char name[9]; int len; };
static struct prelen prelens[8192]; static int nprelen;
static int prelen_of(const char *nm) {
    int i; for (i = 0; i < nprelen; i++) if (!strcmp(prelens[i].name, nm)) return prelens[i].len;
    return 0;
}
/* the length attribute a DC/DS operand would carry, or 0 for "do not record" */
static int dc_len_attr(const char *opnd) {
    const char *p = opnd; int n = 0;
    while (*p == ' ') p++;
    while (isdigit((unsigned char)*p)) p++;                 /* duplication factor */
    if (*p == '(') { int d = 1; p++; while (*p && d) { if (*p == '(') d++; else if (*p == ')') d--; p++; } }
    int ty = *p ? toupper((unsigned char)*p++) : 0;
    if (!ty) return 0;
    if (*p == 'L') { p++;
        if (*p == '.' || *p == '(') return 0;               /* bits, or an expression: not resolved here */
        while (isdigit((unsigned char)*p)) n = n * 10 + (*p++ - '0');
        return n > 0 ? n : 0; }
    switch (ty) {
    case 'A': case 'V': case 'F': case 'E': return 4;
    case 'Y': case 'H': case 'S': return 2;
    case 'D': return 8;
    case 'C': case 'X': case 'B': {
        const char *q = strchr(p, '\'');
        if (!q) return 0;
        int cnt = 0; const char *e = q + 1;
        while (*e) {
            if (*e == '\'') { if (e[1] == '\'') { cnt++; e += 2; continue; } break; }
            if (*e == '&' && e[1] == '&') { cnt++; e += 2; continue; }
            cnt++; e++;
        }
        if (!*e) return 0;
        if (ty == 'C') return cnt ? cnt : 0;
        if (ty == 'X') return cnt ? (cnt + 1) / 2 : 0;
        return cnt ? (cnt + 7) / 8 : 0;
    }
    default: return 0;
    }
}
static void prescan_lengths(char **in, int nin) {
    int i; nprelen = 0;
    for (i = 0; i < nin && nprelen < 8192; i++) {
        char buf[STMTSZ], lbl[32], op[16], opnd[STMTSZ];
        scopy(buf, in[i], STMTSZ - 1);
        parse(buf, lbl, op, opnd);
        if (!lbl[0] || !op[0]) continue;
        if (strcmp(op, "DC") && strcmp(op, "DS") && strcmp(op, "DXD")) continue;
        if (strlen(lbl) > 8) continue;
        int L = dc_len_attr(opnd);
        if (L <= 0) continue;
        if (prelen_of(lbl)) continue;                       /* the FIRST definition wins, as the assembler's would */
        scopy(prelens[nprelen].name, lbl, 8); prelens[nprelen].len = L; nprelen++;
    }
}
/* macro pass: capture MACRO/MEND defs, expand calls -> flat open code */
static int macro_pass(char **in, int nin, char **out, int *raw_org) {
    int nout = 0;
    prescan_lengths(in, nin);   /* L' in conditional assembly has no symbol table otherwise (#244) */
    mexp_block(in, nin, out, &nout, 0, raw_org);
    return nout;
}

static char unkops[128][12]; static int unkln[128]; static int nunk;   /* each undefined-op occurrence: the op and its lines[] index */
static void note_unknown(const char *o, int line) {
    static const char *skip[] = { "SETA","SETB","SETC","GBLA","GBLB","GBLC","LCLA","LCLB","LCLC",
        "AIF","AGO","ANOP","MNOTE","MEXIT","PRINT","SPACE","EJECT","TITLE","DSECT","ORG","COPY","MACRO","MEND","ACTR",
        "EXTRN","WXTRN", NULL };
    int i; for (i = 0; skip[i]; i++) if (!strcmp(o, skip[i])) return;
    mark_flagged(line);
    if (nunk < 128) { scopy(unkops[nunk], o, 11); unkln[nunk] = line; nunk++; }   /* one record per flagged statement */
}
/* an RS/SI/S storage operand carrying an index/length subscript -- D2(,B2) or
 * D2(X2,B2) -- has two subscripts where only a base is allowed. IFOX00 rejects
 * this (ERR216 ILLEGAL OPERAND FORMAT, severity 12); we must too, rather than
 * silently taking the empty/index field as the base and emitting base 0 (an
 * absolute low-core reference). */
static char badfmt_op[128][12]; static int badfmt_ln[128]; static int nbadfmt;
static void note_badfmt(const char *o, int line) {
    mark_flagged(line);
    if (nbadfmt < 128) { scopy(badfmt_op[nbadfmt], o, 11); badfmt_ln[nbadfmt] = line; nbadfmt++; }
}

/* A DC/DS constant, or a directive, that reserves no storage.
 *
 * Two cases, and they must NOT share a message. Assembler XF has exactly
 * fifteen constant types -- C X B P Z L D E F H A Y V Q S, the letters ORGed to
 * a non-zero code in IFOX00's DCTBL (ifnx5d.asm:1164-1180). A letter outside
 * that set is what IFOX00 raises ERR198 for, "INVALID TYPE DECLARED ON DC/DS/
 * DXD CONSTANT" (ifnx5d.asm:202, text in erms.asm:203, severity 8 per
 * jermsgcd.asm SEV198). P Z E L S Q, by contrast, are perfectly valid types
 * that as370 has not implemented -- calling those "invalid" would be as
 * misleading as the silence it replaces.
 *
 * Both used to fall through the type chain into its label-only last arm: the
 * label was defined, no storage was reserved, the location counter did not
 * advance, and the return code stayed 0. So every symbol after them in the
 * section silently moved, and the ESD section length agreed with the short
 * figure -- an object deck internally consistent and wrong (#53). CXD was the
 * same shape one layer worse: it sat in note_unknown's skip[], deliberately
 * exempted from diagnosis, while its companion DXD was flagged. */
static char badty_ch[128]; static int badty_ln[128]; static int nbadty;
static void note_badtype(int ty, int line) {
    mark_flagged(line);
    if (nbadty < 128) { badty_ch[nbadty] = (char)(ty ? ty : '?'); badty_ln[nbadty] = line; nbadty++; }
}
static char nyi_what[128][24]; static int nyi_ln[128]; static int nnyi;
static void note_notimpl(const char *what, int line) {
    mark_flagged(line);
    if (nnyi < 128) { scopy(nyi_what[nnyi], what, 23); nyi_ln[nnyi] = line; nnyi++; }
}
/* An operand a statement's own rules reject -- a DC/DS nominal value, an SRP
 * rounding digit. The reason text is written at the call site and names the
 * IFOX00 error it corresponds to: ERR178 SYNTAX ERROR, ERR224 LENGTH ERROR,
 * ERR236 ILLEGAL CHARACTER IN EXPRESSION, ERR177 MISSING OPERAND. The severity
 * is passed with the message because they differ: 178, 224 and 236 are 8 while
 * 177 is 12 (jermsgcd.asm). */
static char operr_msg[128][VALSZ]; static int operr_ln[128]; static int operr_sev[128]; static int noperr;
static void note_operr(const char *msg, int sev, int line) {
    /* A diagnostic with no statement to attach to is dropped, not recorded: main
     * prints lines[operr_ln[j]] and line_org[operr_ln[j]], so a negative index
     * would read out of bounds. It happens where a conditional-assembly
     * statement is evaluated with no lines[] slot armed -- an AIF condition,
     * which mexp_block branches on without ever emitting the card. Stated in
     * #141 rather than papered over: a substring error inside an AIF cannot be
     * attributed in this design. */
    if (line < 0) return;
    mark_flagged(line);
    if (noperr < 128) { scopy(operr_msg[noperr], msg, 95); operr_sev[noperr] = sev; operr_ln[noperr] = line; noperr++; }
}
/* MNOTE: the macro writer's own diagnostic, and the only one a macro can raise
 * about its caller. as370 skipped the statement outright -- no listing line, no
 * message, no severity -- so the IBM convention `IHBERMAC -> MNOTE 8/12 ->
 * MEXIT' deleted the statement and reported nothing at all: a macro-argument
 * error assembled to silence at rc 0 (cc370#39).
 *
 * Three forms, and IFOX00 treats them differently -- measured, not assumed:
 *
 *   MNOTE 8,'text'    severity 8, FLAGGED, listed as "    8,text"
 *   MNOTE *,'text'    a comment: severity 0, NOT flagged, listed as "*,text"
 *   MNOTE 'text'      no severity: 0, NOT flagged, listed as "text"
 *
 * The severity-bearing form is the only one that reaches the diagnostics page
 * (IFO197) and the return code; the other two are printed and cost nothing. */
static char mnote_txt[128][80]; static int mnote_ln[128]; static int mnote_sev[128];
static int nmnote, nmnote_seen;
static void note_mnote(int sev, const char *text, int line) {
    if (line < 0) return;
    if (sev > 0) mark_flagged(line);          /* `*' and the bare form are not flagged */
    nmnote_seen++;
    if (nmnote < 128) { scopy(mnote_txt[nmnote], text, 79); mnote_sev[nmnote] = sev; mnote_ln[nmnote] = line; nmnote++; }
}
/* Split an MNOTE operand into severity and text, and render the listing image.
 * Returns the severity; *comment is set for the `*' form. The text loses its
 * surrounding apostrophes and a doubled '' becomes one, exactly as IFOX00
 * prints it. */
static int mnote_split(const char *opnd, char *text, int textsz, char *image, int imagesz, int *comment) {
    const char *p = opnd; int sev = 0, hassev = 0;
    *comment = 0;
    while (*p == ' ') p++;
    if (*p == '*' && (p[1] == ',' || p[1] == 0)) { *comment = 1; p += p[1] ? 2 : 1; }
    else if (isdigit((unsigned char)*p)) {
        while (isdigit((unsigned char)*p)) sev = sev * 10 + (*p++ - '0');
        hassev = 1;
        while (*p == ' ') p++;
        if (*p == ',') p++;
    }
    else if (*p == ',') p++;                  /* `MNOTE ,'text'' -- no severity */
    while (*p == ' ') p++;
    int n = 0;
    if (*p == '\'') { p++;
        while (*p && n < textsz - 1) {
            if (*p == '\'') { if (p[1] == '\'') { text[n++] = '\''; p += 2; continue; } break; }
            text[n++] = *p++;
        }
    } else while (*p && n < textsz - 1) text[n++] = *p++;
    text[n] = 0;
    if (*comment)      snprintf(image, (size_t)imagesz, "*,%s", text);
    else if (hassev)   snprintf(image, (size_t)imagesz, "    %d,%s", sev, text);
    else               snprintf(image, (size_t)imagesz, "%s", text);
    return *comment ? 0 : sev;
}
/* IFOX00 IFO158 (severity 8, jermsgcd.asm SEV158): a symbol defined in a DSECT
 * is an offset into a dummy section, and a dummy section has no ESDID -- there
 * is nothing for the loader to relocate the constant against. Both assemblers
 * emit the constant as zero and generate no RLD entry (the tgtreal test beside
 * each call site has always decided that); what was missing was the diagnosis,
 * so the guest warned where the host said nothing (#72).
 *
 * The call sites test dsect_sect[] EXPLICITLY rather than reusing !tgtreal: an
 * undefined symbol fails that test too and is a different error entirely. */
static void note_dsect_adcon(const char *sym, int line) {
    char m[VALSZ];
    /* The symbol is bounded so the whole message provably fits: the call sites
     * pass a char[64], and note_operr keeps 95 characters, so an unbounded %s
     * could cut the error number off the end -- and gcc's -Wformat-truncation
     * refuses the build over it. An over-length symbol is its own diagnostic. */
    snprintf(m, sizeof m, "DSECT symbol %.20s used in a relocatable address constant (IFOX00 IFO158)", sym);
    note_operr(m, 8, line);
}

/* ---- packed (P) and zoned (Z) decimal ------------------------------------
 * Built to IFOX00's PKON and ZKON (ifnx5d.asm:572-616 and :619-663).
 *
 * Nominal value: an optional sign, decimal digits, and AT MOST ONE decimal
 * point, which is skipped when forming the value (a second one is ERR178, not
 * something to ignore). The sign is a nibble, X'0C' for plus -- the default --
 * and X'0D' for minus; zoned carries it in the zone of the last byte, which
 * ZKON masks with X'CF' or X'DF'.
 *
 * Implicit length, in the bits the DCTABLE maxima are expressed in:
 *   P   (digits + 1) * 4   -- the digits plus the sign nibble
 *   Z    digits      * 8   -- one byte per digit
 * so P'123' is 2 bytes (12 3C) and Z'456' is 3 (F4 F5 C6). Neither type is
 * aligned (DCTABLE alignment mask 0) and neither may exceed 16 bytes.
 *
 * The value is right-justified into the target length: P pads with zero
 * nibbles, Z with X'F0', and both truncate on the LEFT, dropping high-order
 * digits. That is what makes P'1234' come out 01 23 4C rather than 12 34 C0 --
 * five nibbles right-justified into three bytes.
 *
 * `at` is the location counter position; bytes are written only when emit is
 * set (pass 2, and DC rather than DS), and diagnostics recorded only when diag
 * is set (pass 1), since both passes walk the same statements.
 * Returns the byte length of this one constant, or 0 if it was rejected. */
static int emit_decimal(const char *txt, int packed, long at, int want, int emit, int diag, int line) {
    unsigned char dig[64]; int nd = 0, sign = 0x0C, dot = 0, len;
    const char *q = txt;
    if (*q == '+') q++; else if (*q == '-') { sign = 0x0D; q++; }
    /* A blank is NOT skipped, leading or embedded. PKON tests the character
     * against J9 and lets everything that is not a digit, a period, a comma or
     * a quote fall through to XBERR1; JBLANK is X'2F' against J9's X'09'
     * (jcommon.asm), so it fails that test and IFOX raises ERR236. Skipping a
     * leading blank, or stopping at an embedded one, would silently accept
     * DC P' 123' and quietly truncate DC P'1 2' to 1C. */
    for (; *q; q++) {
        if (*q >= '0' && *q <= '9') { if (nd < 64) dig[nd] = (unsigned char)(*q - '0'); nd++; }
        else if (*q == '.') { if (dot) { if (diag) note_operr("Syntax error - more than one decimal point in a decimal constant (IFOX00 ERR178)", 8, line); return 0; } dot = 1; }
        else { if (diag) note_operr("Illegal character in a decimal constant (IFOX00 ERR236)", 8, line); return 0; }
    }
    if (!nd) { if (diag) note_operr("Syntax error - decimal constant has no nominal value (IFOX00 ERR178)", 8, line); return 0; }
    if (nd > (packed ? 31 : 16)) {   /* PKON/ZKON compare the digit count against the DCTABLE limit and branch to LENER */
        if (diag) note_operr(packed ? "Length error - a packed-decimal constant may have at most 31 digits (IFOX00 ERR224)"
                                    : "Length error - a zoned-decimal constant may have at most 16 digits (IFOX00 ERR224)", 8, line);
        return 0; }
    len = want ? want : (packed ? (nd + 2) / 2 : nd);
    if (len < 1 || len > 16) {   /* DCTABLE gives P and Z a maximum of 128 bits */
        if (diag) note_operr("Length error - a packed- or zoned-decimal constant may not exceed 16 bytes (IFOX00 ERR224)", 8, line);
        return 0; }
    if (!emit) return len;
    if (packed) {
        int nnib = nd + 1, tnib = len * 2, k;         /* digits + sign nibble, right-justified */
        unsigned char b[32]; memset(b, 0, sizeof b);
        for (k = 0; k < tnib; k++) {                  /* k counts nibbles from the RIGHT */
            int src = nnib - 1 - k, v;                /* the matching nibble of the value, or none */
            if (src < 0) break;
            v = (src == nnib - 1) ? sign : dig[src];
            { int bi = len - 1 - (k / 2); if (k & 1) b[bi] |= (unsigned char)(v << 4); else b[bi] |= (unsigned char)v; }
        }
        for (k = 0; k < len; k++) put(at + k, b[k], 1);
    } else {
        int k;
        for (k = 0; k < len; k++) {
            int src = nd - len + k;                   /* right-justified, left-padded/truncated */
            int v = (src >= 0) ? (0xF0 | dig[src]) : 0xF0;
            if (k == len - 1) v = (v & 0x0F) | (sign << 4);
            put(at + k, v, 1);
        }
    }
    return len;
}
/* A machine instruction whose displacement is a relocatable symbol while the
 * base register is given explicitly (SYM(Rn)).  IFOX00 rejects this with IFO228
 * (severity 8) and assembles the whole instruction as zero -- an explicit
 * address requires an absolute displacement; only the implicit form SYM(len),
 * which lets the assembler choose the base from a USING, may be relocatable. */
static char reld_op[128][12]; static int reld_ln[128]; static int nreld;
static void note_relocdisp(const char *o, int line) {
    mark_flagged(line);
    if (nreld < 128) { scopy(reld_op[nreld], o, 11); reld_ln[nreld] = line; nreld++; }
}
/* A relocatable operand addressed implicitly (base chosen from a USING) whose
 * OWN section has no USING in range.  IFOX00 rejects this with IFO209
 * (severity 8), assembles the instruction as zero, and sets ADDR to 0 -- there
 * is no addressability for the operand.  as370 used to resolve it through a
 * cross-section USING or emit base 0. */
static char addr_op[128][12]; static int addr_ln[128]; static int naddr;
static void note_addrerr(const char *o, int line) {
    mark_flagged(line);
    if (naddr < 128) { scopy(addr_op[naddr], o, 11); addr_ln[naddr] = line; naddr++; }
}
/* An over-length ordinary symbol in the NAME FIELD (a local label or EQU name,
 * >8 characters).  IFOX00 rejects the name field (IFO016 ILLEGAL OR INVALID
 * NAME FIELD, severity 8) and does NOT enter the symbol -- but a storage-
 * defining statement still reserves its space.  as370 used to truncate the name
 * to 8 and enter it silently.  Recorded once per statement (pass 1). */
static char ovldef_sym[128][64]; static int ovldef_ln[128]; static int novldef;
static void note_ovldef(const char *n, int line) {
    mark_flagged(line);
    if (novldef < 128) { scopy(ovldef_sym[novldef], n, 63); ovldef_ln[novldef] = line; novldef++; }
}
/* An over-length symbol TERM in an operand expression (>8 characters).  IFOX00
 * rejects it (IFO236 ILLEGAL CHARACTER IN EXPRESSION, severity 8) and zeroes the
 * whole instruction -- it does NOT truncate the term to make it resolve.  as370
 * used to leave the reference unresolved, emitting a valid opcode over a base/
 * displacement of 0 (a silent load from address 0). */
static char ovlref_op[128][12]; static int ovlref_ln[128]; static int novlref;
static void note_ovlref(const char *o, int line) {
    mark_flagged(line);
    if (novlref < 128) { scopy(ovlref_op[novlref], o, 11); ovlref_ln[novlref] = line; novlref++; }
}
/* True if OPND carries a symbol term longer than 8 characters (outside string
 * literals).  Purely LEXICAL -- fires on term length alone, before any symbol
 * lookup, because IFOX rejects an over-length term whether or not its first 8
 * characters name a defined symbol.  Symbol alphabet matches as370's scanners
 * (letter/@#$_ start, alnum/@#$_ body).
 *
 * An apostrophe toggles a skip region, the SAME way parse() tokenizes an
 * operand -- parse() treats every ' as a string quote (it has no K'/N'/L'/T'
 * attribute exception), so a term like =AL2(L'FIELD) leaves the operand's tail
 * (and the absorbed trailing comment) inside an unmatched quote.  Matching that
 * here keeps the scan on the same text parse() built and avoids flagging a
 * comment word; it also skips C'...'/X'...' literal content.  The trade-off is
 * that any >8 symbol AFTER an unmatched attribute apostrophe in the operand
 * (L'LONGSYMBOL, or L'FIELD+LONGLABEL9) is not caught -- a rare edge, and
 * corpus-safe.  The clean fix is making parse() attribute-aware so opnd stops
 * absorbing the comment; tracked as #35 -- whoever fixes parse() there must
 * update this scanner in lockstep. */
static int has_overlong_term(const char *s) {
    /* attr_apos, for the fourth time in this family (#149 parse, #184 join_cont,
     * #300 sublists, now here). `L\'' is an ATTRIBUTE and the text after it is a
     * symbol; `X\'' opens a quoted body. Toggling on both desynchronises the
     * state, and the first thing that reaches is the NEXT literal:
     * `CLC FLD(L\'FLD,3),=X\'FF00000000000000\'' left the hex digits outside any
     * quote, where 16 alphanumerics read as one symbol and drew IFO236 --
     * zeroing an instruction IFOX00 assembles (cc370#312). */
    const char *base = s;
    int q = 0;
    while (*s) {
        if (*s == '\'') { if (q || !attr_apos(base, (int)(s - base))) q = !q; s++; continue; }
        if (q) { s++; continue; }
        if (isalpha((unsigned char)*s) || *s == '@' || *s == '#' || *s == '$' || *s == '_') {
            int n = 0; while (*s && (isalnum((unsigned char)*s) || *s == '@' || *s == '#' || *s == '$' || *s == '_')) { s++; n++; }
            if (n > 8) return 1;
        } else s++;
    }
    return 0;
}
/* Record every ordinary-symbol term in a machine instruction's operand that
 * names nothing, in source order, and return how many there were -- so the
 * caller can zero the instruction the way IFOX00 does.  This is the machine-
 * instruction half of IFO188; x_factor raises the same diagnostic for every
 * other statement (DC/DS/EQU/ORG/USING/END), where IFOX zeroes the VALUE but
 * leaves the statement alone.
 *
 * Scanning the operand text rather than recording from inside the evaluator is
 * what keeps the two halves from reporting the same symbol twice: this runs in
 * the `else if` before the format switch, so a statement it flags never reaches
 * resolve()/expr_val() and never reaches x_factor at all.
 *
 * LEXICAL, like has_overlong_term above, and it skips the same regions for the
 * same reasons -- an apostrophe toggles a skip region, matching the text parse()
 * actually built, so an absorbed trailing comment behind an unmatched attribute
 * quote is not read as a list of symbols.  Two further skips this one needs:
 *
 *  - A token immediately followed by an apostrophe is a self-defining term or an
 *    attribute prefix (X'FF', C'A', B'1111', L'FIELD), not a symbol.  Without
 *    this, `MVI FLAG,X'40'` would report an undefined symbol X.  The symbol
 *    INSIDE an attribute (L'NOSUCH) is inside the skip region and is not
 *    reported -- x_factor's L' branch does not report it either, so the two
 *    agree; it is the same #35 edge has_overlong_term documents.
 *  - A LITERAL operand (=A(SYM)) is skipped entire.  IFOX00 assembles the
 *    REFERENCING instruction normally -- the literal resolves to its pool
 *    address, which is defined -- and flags the undefined symbol against the
 *    pool statement instead.  emit_lit raises that one. */
static int scan_undef_terms(const char *s, int line) {
    int q = 0, found = 0;
    while (*s) {
        if (*s == '\'') { q = !q; s++; continue; }
        if (q) { s++; continue; }
        if (*s == '=') {                                  /* a literal: skip to the next top-level comma */
            int d = 0; s++;
            while (*s) {
                if (*s == '\'') q = !q;
                else if (!q && *s == '(') d++;
                else if (!q && *s == ')') { if (d) d--; }
                else if (!q && !d && *s == ',') break;
                s++;
            }
            continue;
        }
        if (isalpha((unsigned char)*s) || *s == '@' || *s == '#' || *s == '$' || *s == '_') {
            char nm[64]; int n = 0;
            while (*s && (isalnum((unsigned char)*s) || *s == '@' || *s == '#' || *s == '$' || *s == '_')) {
                if (n < 63) nm[n] = *s;
                n++; s++;
            }
            nm[n < 63 ? n : 63] = 0;
            if (*s == '\'') continue;                     /* X'..'/C'..'/B'..'/L'..' prefix, not a symbol */
            struct sym *sy = sym_find(nm);
            if (!sy || (!sy->defined && sy->type != S_ER)) { note_undefsym(nm, line); found++; }
        } else s++;
    }
    return found;
}
/* The first symbol term of E that is not defined YET -- i.e. at this point in
 * pass 1, which is what "previously defined" means.  Returns 1 and copies the
 * name into OUT.  Same lexical skips as scan_undef_terms above, for the same
 * reasons: an apostrophe toggles a skip region, and a token followed by one is a
 * self-defining term or an attribute prefix (X'40', L'FIELD), not a symbol.
 * S_ER is not "defined" either -- an external reference is not absolute, so it
 * cannot be a duplication factor. */
static int undefined_term(const char *s, char *out) {
    int q = 0;
    while (*s) {
        if (*s == '\'') { q = !q; s++; continue; }
        if (q) { s++; continue; }
        if (isalpha((unsigned char)*s) || *s == '@' || *s == '#' || *s == '$' || *s == '_') {
            char nm[64]; int n = 0;
            while (*s && (isalnum((unsigned char)*s) || *s == '@' || *s == '#' || *s == '$' || *s == '_')) {
                if (n < 63) nm[n] = *s;
                n++; s++;
            }
            nm[n < 63 ? n : 63] = 0;
            if (*s == '\'') continue;                  /* X'..'/C'..'/B'..'/L'..' prefix */
            struct sym *sy = sym_find(nm);
            if (!sy || !sy->defined) { scopy(out, nm, 63); return 1; }
        } else s++;
    }
    return 0;
}
/* A DC/DS operand whose parenthesised duplication factor pass 1 REJECTED.
 *
 * The reject has to be remembered rather than re-derived, and that is the whole
 * difficulty of this construct.  IFOX00 requires every symbol in a duplication
 * factor to be previously defined (IFO231) precisely because the location
 * counter depends on it; the offending statement then reserves nothing.  By pass
 * 2 a forward symbol IS defined, so a pass-2 re-evaluation would allocate where
 * pass 1 allocated nothing -- the location counter would move between the passes
 * and every symbol after it would silently shift.  Measured on the guest
 * (JOB02900, tests/listref/ifox-listing-dupfac.txt): a forward reference draws
 * IFO231 + IFO217 + IFO206 and leaves LOC where it was. */
static int dupbad_ln[256], dupbad_op[256]; static int ndupbad;
static void note_dupbad(int line, int opidx) {
    if (ndupbad < 256) { dupbad_ln[ndupbad] = line; dupbad_op[ndupbad] = opidx; ndupbad++; }
}
static int dup_rejected(int line, int opidx) {
    int i; for (i = 0; i < ndupbad; i++) if (dupbad_ln[i] == line && dupbad_op[i] == opidx) return 1;
    return 0;
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
    if (M.n == 0) { int j; for (j = 0; j < bytes; j++) put(at + j, 0, 1); return; }   /* true zero -- and a signed zero is still all zeros (measured: D'-0') */
    /* Extended precision (L, 16 bytes) is two long floats: the high half is an
     * ordinary one, the low half repeats the sign with an exponent 14 LESS -- the
     * fourteen hex digits the high fraction holds -- and continues the same
     * fraction. So the 112-bit fraction is developed in one piece and rounded
     * once, at its end, not half by half. Measured against IFOX00:
     *   L'1.5'   4118000000000000 3300000000000000
     *   L'-1.5'  C118000000000000 B300000000000000   sign in both halves
     *   L'0.1'   4019999999999999 329999999999999A   rounded at bit 112 */
    int ext = (bytes > 8), hb = ext ? 8 : bytes, lb = ext ? bytes - 8 : 0;
    int fracbits = (hb - 1) * 8; if (fracbits > 56) fracbits = 56;
    int lofrac = ext ? (lb - 1) * 8 : 0; if (lofrac > 56) lofrac = 56;
    int P = eexp - nfrac, k;                 /* value = M * 10^P */
    struct bn num = M, den; bn_set(&den, 1);
    if (P >= 0) for (k = 0; k < P; k++) bn_mul_small(&num, 10);
    else for (k = 0; k < -P; k++) bn_mul_small(&den, 10);
    int exp = 64;                            /* normalise num/den into [1/16, 1) */
    while (bn_cmp(&num, &den) >= 0) { bn_mul_small(&den, 16); exp++; }
    for (;;) { struct bn t = num; bn_mul_small(&t, 16); if (bn_cmp(&t, &den) < 0) { num = t; exp--; } else break; }
    struct bn N = num; bn_shl(&N, fracbits);  /* F = round(num * 2^fracbits / den) */
    struct bn R; unsigned long long F = bn_divmod(&N, &den, &R);
    unsigned long long G = 0;
    if (ext) {                                /* the low half continues the fraction: G = round(R * 2^lofrac / den) */
        struct bn N2 = R; bn_shl(&N2, lofrac);
        struct bn R2; G = bn_divmod(&N2, &den, &R2);   /* R < den, so the quotient stays below 2^lofrac <= 2^56 */
        bn_mul_small(&R2, 2); if (bn_cmp(&R2, &den) >= 0) G++;   /* round half up, once, at bit 112 */
        if (lofrac < 64 && (G >> lofrac)) { G = 0; F++; }        /* the low half rounded up into the high one */
    } else {
        bn_mul_small(&R, 2); if (bn_cmp(&R, &den) >= 0) F++;    /* round half up */
    }
    if (fracbits < 64 && (F >> fracbits)) {                     /* rounded up to 1.0 -> renormalise */
        unsigned long long carry = F & 0xf;
        F >>= 4;
        if (ext && lofrac >= 4) G = (G >> 4) | (carry << (lofrac - 4));
        exp++;
    }
    /* The exponent is excess-64 in seven bits and is NOT range-checked: a value
     * needing an exponent outside 0..127 wraps silently, as it did before. IFOX00
     * flags it; as370 does not (see #53). */
    int i;
    put(at, (long)((sign ? 0x80 : 0) | (exp & 0x7f)), 1);
    for (i = 1; i < hb; i++) put(at + i, (long)((F >> (8 * (hb - 1 - i))) & 0xff), 1);   /* ascending byte order: same values, but the TXT emission log stays address-monotonic */
    if (ext) {
        put(at + hb, (long)((sign ? 0x80 : 0) | ((exp - 14) & 0x7f)), 1);   /* exp AFTER any renormalisation */
        for (i = 1; i < lb; i++) put(at + hb + i, (long)((G >> (8 * (lb - 1 - i))) & 0xff), 1);
    }
}
/* one copy's width: the size a single nominal value occupies, which is what the
 * per-type emitters below are written against. */
static int size_unit(const struct lit *l, int dup) { int u = l->size / (dup > 0 ? dup : 1); return u > 0 ? u : 1; }
static void emit_lit_one(struct lit *l, long loc, int size) {
    /* A literal is assembled at the pool, so g_curln here is the LTORG or the
     * END -- neither of which mentions the symbol.  IFOX00 flags the pool's own
     * generated statement; as370's listing renders that line but has no lines[]
     * entry for it, so the diagnostic goes to the statement that WROTE the
     * literal, which is the line a reader needs anyway.  Same choice defln
     * already makes for IFO158 below. */
    const char *p = l->text + 1;
    while (isdigit((unsigned char)*p)) p++;
    char ty = toupper((unsigned char)*p++);
    if (*p == 'L') { p++; while (isdigit((unsigned char)*p)) p++; }
    if (ty == 'V' || ty == 'A' || ty == 'Y') {            /* address constant, possibly a value list =AL1(a,b,c) */
        char vv[64][FLDW]; int nv = split_fields(l->ext, vv, 64); if (nv < 1) nv = 1;
        int per = size / nv, vj;
        for (vj = 0; vj < nv; vj++) { long vloc = loc + (long)vj * per;
            if (ty == 'V') { char r[64]; int sn = 0; const char *se = vv[vj]; while (*se && !strchr("+-(), ", *se) && sn < 63) r[sn++] = *se++; r[sn] = 0;
                put(vloc, 0, per); add_reloc(vloc, r, 1, per); }
            else { int rc = 0; long v = vv[vj][0] ? expr_val_full(vv[vj], &rc) : 0; put(vloc, v, per);   /* leading '(' -- see the DC arm and cc370#167 */
                char sym[64]; reloc_sym(vv[vj], sym, sizeof sym);   /* relocation target symbol (e.g. @V1-192, X'80000000'+SYM) */
                struct sym *es = (sym[0] && sym[0] != '*') ? sym_find(sym) : NULL;
                int tgtreal = (sym[0] == '*') ? !dsect_sect[cur_sect_id & 255] : (es && !dsect_sect[es->sect & 255]);
                if (rc != 0 && !in_dsect && es && dsect_sect[es->sect & 255]) note_dsect_adcon(sym, l->defln);   /* IFO158 */
                if (rc != 0 && tgtreal) { add_reloc(vloc, sym, 0, per); } } }   /* relocate only if net-relocatable; RLD length matches AL3/AL2 width */
    } else if (ty == 'E' || ty == 'D' || ty == 'L') {     /* floating point */
        /* Every nominal value goes through the converter. It used to be reached
         * only when the text contained a `.`, `e` or `E`, so =D'2' and =E'1' took
         * the integer route and assembled as 0000000000000002 and 00000000 where
         * IFOX00 says 4120000000000000 and 41100000 (#53). */
        const char *q = strchr(p, '\'');
        if (q) emit_float(loc, q + 1, size);
        else { int j; for (j = 0; j < size; j++) put(loc + j, 0, 1); }
    } else if (ty == 'F' || ty == 'H') {
        put(loc, l->val, size);
    } else if (ty == 'X') {
        const char *q = strchr(p, '\''); unsigned char by[256]; int nb = q ? hex_to_bytes(q + 1, by, 256) : 0;
        int pad = size - nb, j; for (j = 0; j < size; j++) put(loc + j, (j >= pad && j - pad < nb) ? by[j - pad] : 0, 1);
    } else if (ty == 'C') {
        const char *q = strchr(p, '\''); char body[256]; int slen = 0;
        if (q) { const char *e = q + 1; while (*e && slen < 255) { if (*e == '\'') { if (e[1] == '\'') { body[slen++] = '\''; e += 2; continue; } break; }
            if (*e == '&' && e[1] == '&') { body[slen++] = '&'; e += 2; continue; }
            body[slen++] = *e++; } }
        int j; for (j = 0; j < size; j++) put(loc + j, j < slen ? mvs_a2e((unsigned char)body[j]) : 0x40, 1);
    } else put(loc, l->val, size);
}
static void emit_lit(struct lit *l) {
    /* A literal is assembled at the pool, so g_curln here is the LTORG or the
     * END -- neither of which mentions the symbol.  IFOX00 flags the pool's own
     * generated statement; as370's listing renders that line but has no lines[]
     * entry for it, so the diagnostic goes to the statement that WROTE the
     * literal, which is the line a reader needs anyway.  Same choice defln
     * already makes for IFO158 below. */
    int svln = g_curln; g_curln = l->defln;
    int dup = l->dup > 0 ? l->dup : 1, unit = size_unit(l, dup), k;
    for (k = 0; k < dup; k++) emit_lit_one(l, l->loc + (long)k * unit, unit);
    g_curln = svln;
}

static int listing = 0;
/* --strict-cont: raise a DISCARDED statement from IFOX00's severity 4 to 8.
 * IFOX00 gives a harmless continued comment and a statement-losing continuation
 * the same severity 4, and as370 used to split them and return 8 unconditionally.
 * That is a deliberate divergence and it costs eight modules whose decks are
 * byte-identical, so the default is now IFOX00's 4 and the guard is opt-in.
 * The guard is worth keeping available: mbt fails a build at rc >= 8, and a
 * module assembled against a mangled macro library is exactly what #115 saw --
 * 150 modules compared in good faith against source the assembler had eaten. */
static int strict_cont = 0;                 /* -L: print a LOC/object/source listing in pass 2 */
static void emit_listing(long a, long b, const char *src) {
    char hex[20]; int hn = 0; long i;
    for (i = a; i < b && i < a + 8; i++) hn += snprintf(hex + hn, sizeof hex - hn, "%02X", defn[i] ? text[i] : 0);
    hex[hn] = 0;
    char ln[90]; int j = 0; const char *p = src;
    while (*p && *p != '\n' && j < 88) ln[j++] = *p++;
    ln[j] = 0;
    fprintf(stderr, "%06lX %-16s %s\n", a, hex, ln);
}
/* ---- literal pool placement (#68) ----------------------------------------- */
/* Collect the not-yet-placed literals of pool `seq` into mem[], in IFOX's pool
 * order: doubleword/fullword/halfword/byte segments, each in order of first
 * reference. A literal's segment is the alignment implied by its LENGTH (len
 * divisible by 8/4/2, else byte), not its type: =CL8 sits with the doublewords
 * but =CL11 (odd) goes in the byte segment, after the fullwords. */
static int pool_gather(int seq, int *mem, int max) {
    int k, n = 0;
    for (k = 0; k < nlit; k++) {
        if (lits[k].placed || lits[k].ltseq != seq) continue;
        if (n < max) mem[n++] = k;
    }
    { int a, b;
      for (a = 1; a < n; a++) { int t = mem[a]; b = a - 1;
        while (b >= 0 && lenalgn(lits[mem[b]].size) < lenalgn(lits[t].size)) { mem[b + 1] = mem[b]; b--; }
        mem[b + 1] = t; } }
    return n;
}
/* the address just past a gathered pool laid out from `base` */
static long pool_extent(const int *mem, int n, long base) {
    long p = align8(base); int i;
    for (i = 0; i < n; i++) { const struct lit *l = &lits[mem[i]];
        p = (p + l->algn - 1) & ~(long)(l->algn - 1); p += l->size; }
    return p;
}
/* Reserve the END pool's space at the end of the first control section, at the
 * point a LATER control section begins: from here on that section's extent is
 * fixed, and every section behind it has to sit above the pool. The literals
 * themselves are assigned and punched at END (see the LTORG/END handler), which
 * is where IFOX00 emits them too -- this only takes the room.
 *
 * The first control section is resumed at its HIGHEST address, so the base is
 * the section's high-water mark where a backward ORG left the counter below it.
 * A first section that is RESUMED after a later one (A, B, A) reserves at its
 * first close, and the room it takes still belongs to that section -- which is
 * why the reservation extends sect_hwm rather than the running counter. Since
 * origins are chained from the finished lengths (#136), a later section then
 * lands behind the pool automatically; csect_resume3.s is the oracle for that
 * composition (A len 00000C, B at 000010). */
static void pool_reserve(void) {
    static int mem[4096];
    if (pool_defer || first_ctl_sect <= 0) return;
    int n = pool_gather(end_pool_seq, mem, 4096);
    if (n <= 0) return;                                  /* nothing outstanding: END has no pool to place */
    long base = lc;
    if (first_ctl_sect < MAXSECT && sect_hwm[first_ctl_sect] > base) base = sect_hwm[first_ctl_sect];
    pool_org = align8(base);
    lc = pool_extent(mem, n, pool_org);
    sect_lc_of(first_ctl_sect, lc);                      /* the pool is part of THAT section, whatever is current here */
    if (lc > modlen) modlen = lc;
    pool_defer = 1;
}
/* register every literal operand of a machine instruction (pass 1 and the pre-scan) */
static void lit_scan_operands(const char *opnd) {
    char F[4][FLDW]; int nf = split_fields(opnd, F, 4), k;
    for (k = 0; k < nf; k++) if (F[k][0] == '=') lit_get(F[k]);
}
/* Walk the statement list for literals alone, before pass 1 (#68).
 *
 * Reserving the END pool's space inside the first control section means knowing
 * the pool while that section is still open -- before the statements that
 * reference the literals have been read. So the literal registration pass 1 does
 * (lit_get on every `=` operand field of a machine instruction) runs once up
 * front, plus the LTORG count, which says which pool number END will flush.
 *
 * Running pass 1 twice would look cheaper and is not: pass 1 has one-shot work.
 * EQU evaluates against the symbol table AS IT STANDS, so a forward-referencing
 * equate would resolve differently the second time round and could flip between
 * absolute and relocatable -- changing what gets an RLD entry.
 *
 * lit_get stamps a literal's section from cur_sect_id, which the pre-scan has no
 * business setting: it leaves it 0 and the first real reference in pass 1 fills
 * it in. */
static void prescan_literals(char **lines, int nlines) {
    int i, end_seen = 0; litpool = 0; cur_sect_id = 0;
    for (i = 0; i < nlines; i++) {
        if (lflags[i] & LF_NOASM) continue;
        g_curln = i;                        /* line context for a diagnostic raised inside sym_get (=V externals) */
        char buf[STMTSZ], lbl[32], op[16], opnd[STMTSZ];
        strncpy(buf, lines[i], sizeof buf - 1); buf[sizeof buf - 1] = 0;
        if (!parse(buf, lbl, op, opnd)) continue;
        if (!op[0]) continue;
        const struct opc *po = op_find(op);
        if (po) { if (po->fmt != F_S0) lit_scan_operands(opnd); }   /* the F_S0 skip has to match the assembly loop's, or the pre-scan registers a literal pass 1 never sees */
        else if (!strcmp(op, "LTORG")) litpool++;        /* every LTORG closes a pool, exactly as the assembly loop counts them */
        else if (!strcmp(op, "END")) { end_seen = 1; break; }
    }
    /* No END statement: nothing flushes a pool, so there is no pool to make room
     * for either. -1 matches no ltseq, which turns the reservation off without a
     * flag of its own. (IFOX forces an LTORG at end-of-file; as370 does not, and
     * that gap is its own defect -- reserving space it then never fills would
     * only add a second one.) */
    end_pool_seq = end_seen ? litpool : -1;
    litpool = 0;
}

/* Chain the control sections into the module, between the passes.
 *
 * This cannot happen during pass 1: a section's origin follows from the FINAL
 * length of everything in front of it, and a section's final length is not
 * known until the whole assembly has been seen. `csect_resume2.s` is the
 * measurement -- the resumed A grows past B's would-be origin, and IFOX still
 * puts B behind A's finished 16 bytes. `csect_resume3.s` adds the composition
 * that makes the ordering unavoidable: the END literal pool is placed in the
 * FIRST section long after the later ones were opened, and IFOX still moves
 * them behind it (A len 00000C, B at 000010).
 *
 * Pass 1 therefore leaves every address relative to its own section, and this
 * turns them absolute in one sweep -- symbols and literals alike, since a
 * literal referenced before the pool is flushed is read out of pass 1's
 * placement. Symbols that are not section-relative are left alone: an absolute
 * EQU has no origin to add, and neither has an external reference. */
static void assign_origins(void) {
    int k;
    long org = start_base;
    for (k = 0; k < MAXSECT; k++) sect_len1[k] = sect_hwm[k];   /* pass 2 clears sect_hwm; the lengths are needed after that */
    for (k = 0; k < nsect_ord; k++) {
        int id = sect_ord[k];
        if (id <= 0 || id >= MAXSECT || is_dsect_id(id)) continue;   /* a DSECT owns no address space and is never chained */
        sect_org[id] = org;
        org = align8(org + sect_len1[id]);   /* IFOX rounds each origin up (xfour.asm:313), and charges the padding to nobody */
    }
    for (k = 0; k < nsym; k++) {
        struct sym *s = &syms[k];
        if (!s->defined || s->sect <= 0 || s->sect >= MAXSECT) continue;
        /* A DEFINITION outranks a lingering ER type, the way a section outranks
         * an ER of the same name (#281).  Every S_ER assignment is guarded by
         * `if (!s->defined)', so the type is only ever set while the symbol is
         * still undefined -- and it is never taken back when the definition
         * arrives.  `DC V(B)' ahead of B's own label leaves B carrying S_ER for
         * good, so its LD entry was emitted with the section-relative value and
         * no origin: IKJEGCVT's IKJEGIST reads 000000 against IFOX00's 0017A8.
         * Every TXT card in those modules is already identical; one LD address
         * is the whole divergence (cc370#285). */
        if (is_dsect_id(s->sect) || s->type == S_ABS) continue;
        s->val += sect_org[s->sect];
    }
    for (k = 0; k < nlit; k++)
        if (lits[k].psect > 0 && lits[k].psect < MAXSECT && !is_dsect_id(lits[k].psect))
            lits[k].loc += sect_org[lits[k].psect];   /* the pool's section, not the reference's */
}

static void do_pass(int pass, char **lines, int nlines) {
    int i; litpool = 0; g_pass = pass;
    if (pass == 2) { npunch = 0; g_sect_seen = 0; }
    long prev_lc = 0; const char *prev_src = NULL; int have_prev = 0;
    lc = 0; in_dsect = 0; nusing = 0; cur_sect_id = 0; org_hwm = 0;
    /* Section extents are re-derived by each pass, not accumulated across them:
     * the END pool moves between sections between pass 1's placement and pass 2's,
     * so a carried-over high-water mark would place it twice (#68). */
    first_ctl_sect = 0; pool_defer = 0; pool_org = 0; modlen = 0; memset(sect_hwm, 0, sizeof sect_hwm);
    /* Each pass rebuilds every section's own counter from scratch; the ORIGINS
     * (sect_org) must survive, since pass 2 runs against the chain assigned
     * from pass 1's lengths. The chaining order is likewise built once. */
    memset(sect_rel, 0, sizeof sect_rel);
    if (pass == 1) { nsect_ord = 0; start_base = 0; memset(sect_org, 0, sizeof sect_org); }
    int pre_csect = 0;                  /* a content statement appeared before the first CSECT */
    int prev_li = -1;                   /* previous statement captured for the -a listing (byte count is deferred) */
    if (pass == 2) nrel = 0;
    txl_on = (pass == 2); if (pass == 2) { ntxl = 0; txl_blen = 0; txl_maxend = 0; txl_revisit = 0; }   /* (re)start the TXT emission log */
    for (i = 0; i < nlines; i++) {
        if (lflags[i] & LF_NOASM) continue;   /* a macro call line kept only for the listing -- never assembled */
        g_curln = i;                          /* line context for diagnostics raised inside sym_get/lit_get */
        g_genstmt = (lflags[i] & LF_SUBST) != 0;   /* see g_genstmt: a blank SUBSTITUTED into an operand is not a field end */
        if (listing && pass == 2 && have_prev) emit_listing(prev_lc, lc, prev_src);
        if (pass == 2) { if (prev_li >= 0) lrecs[prev_li].len = (int)(lc - lrecs[prev_li].loc); lrecs[i].loc = lc; lrecs[i].len = 0; lrecs[i].hasa1 = lrecs[i].hasa2 = 0; prev_li = i; }
        char buf[STMTSZ], lbl[32], op[16], opnd[STMTSZ];
        strncpy(buf, lines[i], sizeof buf - 1); buf[sizeof buf - 1] = 0;
        if (listing && pass == 2) { prev_lc = lc; prev_src = lines[i]; have_prev = 1; }
        if (!parse(buf, lbl, op, opnd)) continue;
        if (!op[0]) continue;
        if (g_ovl_name[0]) {   /* over-length ordinary name field -> IFOX IFO016: abandon the name */
            if (pass == 1) note_ovldef(g_ovl_name, i);
            lbl[0] = 0;        /* treat as unnamed: no symbol/ESD/listing entry, but DS/DC still reserve storage so the LC advances identically in both passes */
        }

        const struct opc *o = op_find(op);
        if (o && o->fmt == F_S0) opnd[0] = 0;   /* a zero-operand instruction's operand field is a remark: not a literal, not a symbol reference, not a length-attribute term */
        if (cur_sect_id == 0 && (o || !strcmp(op, "EQU") || !strcmp(op, "DS") || !strcmp(op, "DC") || !strcmp(op, "LTORG")))
            pre_csect = 1;   /* statement before the first CSECT opens the implicit unnamed PC */
        if (cur_sect_id == 0 && !in_dsect && (o || !strcmp(op, "EQU") || !strcmp(op, "DS") || !strcmp(op, "DC") || !strcmp(op, "LTORG"))) {
            struct sym *pc = sym_get(""); pc->type = S_PC; pc->defined = 1;   /* code (or a leading EQU) with no CSECT: open the implicit private-code section so its ESD precedes a later ENTRY's LD */
            if (!pc->sect) { pc->sect = ++g_sectid; } esd_add(pc, ESD_SECT);
            cur_sect_id = pc->sect; if (pass == 2) cur_sect_esdid = pc->esdid;
            if (!first_ctl_sect) first_ctl_sect = cur_sect_id;   /* private code counts as a control section (IFOX FSTCSECT) */
        }
        if (o) {
            while (lc & 1) { if (pass == 2) put(lc, 0, 1); lc++; }   /* instructions are halfword-aligned */
            char F[4][FLDW]; int nf = split_fields(opnd, F, 4);   /* nf: SRP needs its third operand */
            if (pass == 1) {
                if (lbl[0]) { struct sym *s = sym_get(lbl); s->val = lc; s->defined = 1; s->sect = cur_sect_id; s->len = ins_len(o->fmt); }
                lit_scan_operands(opnd);   /* same registration the pre-scan ran, so the two cannot drift */
                lc += ins_len(o->fmt);
                /* The section high-water mark has to be raised in PASS 1 too.  It
                 * was raised by DS/DC and by put(), and put() runs only in pass 2 --
                 * so a control section ending in machine instructions measured only
                 * to its last DS/DC when assign_origins() chained the next one, and
                 * the two sections OVERLAPPED.  AMASPZAP's AMASZDMP ends in
                 * instructions 332 bytes past its last DS: its own ESD length is
                 * right, because that comes from pass 2, and AMASZCON was placed
                 * 332 bytes INSIDE it.  Its image goes from 7,577 differing bytes
                 * to none; the deck still differs in how the text is FILED across
                 * ESD entries, which is a second defect in the same module
                 * (cc370#282). */
                if (!in_dsect) note_sect_lc(lc);
            } else if (has_overlong_term(opnd)) {   /* operand symbol term >8 -> IFOX IFO236: zero the whole instruction (as IFO228/IFO209 do) */
                note_ovlref(op, i); int L = ins_len(o->fmt); put(lc, 0, L); lc += L;
                lrecs[i].a1 = 0; lrecs[i].hasa1 = 1;
            } else if (scan_undef_terms(opnd, i)) {   /* undefined symbol term -> IFOX IFO188: zero the whole instruction */
                int L = ins_len(o->fmt); put(lc, 0, L); lc += L;
                /* Both ADDR columns, not just the first: the oracle renders an SS
                 * instruction's two operand addresses as 00000 00000 (the IFO209 SS
                 * path does the same). The 2/4-byte formats carry one. */
                lrecs[i].a1 = 0; lrecs[i].hasa1 = 1;
                if (L == 6) { lrecs[i].a2 = 0; lrecs[i].hasa2 = 1; }
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
                    if (!sy && ns >= 2 && r_reloc) {   /* explicit base D(X,B) + relocatable displacement -> IFO228 */
                        note_relocdisp(op, i); put(lc, 0, 4); lc += 4;
                        lrecs[i].a1 = r_raw; lrecs[i].hasa1 = 1; break; }
                    if (!r_addrok) {   /* relocatable implicit base, no covering USING -> IFO209 */
                        note_addrerr(op, i); put(lc, 0, 4); lc += 4;
                        lrecs[i].a1 = 0; lrecs[i].hasa1 = 1; break; }
                    put(lc, ((long)o->op << 24) | ((long)r1 << 20) | ((long)x << 16) | ((long)b << 12) | (d & 0xfff), 4); lc += 4;
                    lrecs[i].a1 = (d & 0xfffL) + using_base_of(b); lrecs[i].hasa1 = 1;
                    note_align(op, sy, lrecs[i].a1, i); break; }
                case F_RS: { int r1 = (int)eval_reg(F[0]), r3, b;
                    if (nf >= 3) { r3 = (int)eval_reg(F[1]); resolve(F[2], &d, sub, &ns, &sy); }
                    else { r3 = 0; resolve(F[1], &d, sub, &ns, &sy); }  /* shift form R1,D2(B2): R3 field unused */
                    if (ns >= 2) note_badfmt(op, i);   /* D2(,B2)/D2(X2,B2) on an RS operand: no index field exists here */
                    b = (!sy && ns == 0 && r_ibase >= 0) ? r_ibase : (int)sub[0];
                    if (!sy && ns == 1 && r_reloc) {   /* explicit base D(B) + relocatable displacement -> IFO228 */
                        note_relocdisp(op, i); put(lc, 0, 4); lc += 4;
                        lrecs[i].a1 = r_raw; lrecs[i].hasa1 = 1; break; }
                    if (!r_addrok) {   /* relocatable implicit base, no covering USING -> IFO209 */
                        note_addrerr(op, i); put(lc, 0, 4); lc += 4;
                        lrecs[i].a1 = 0; lrecs[i].hasa1 = 1; break; }
                    put(lc, ((long)o->op << 24) | ((long)r1 << 20) | ((long)r3 << 16) | ((long)b << 12) | (d & 0xfff), 4); lc += 4;
                    lrecs[i].a1 = (d & 0xfffL) + using_base_of(b); lrecs[i].hasa1 = 1;
                    note_align(op, sy, lrecs[i].a1, i); break; }
                case F_SI: { resolve(F[0], &d, sub, &ns, &sy); if (ns >= 2) note_badfmt(op, i); int b = (!sy && ns == 0 && r_ibase >= 0) ? r_ibase : (int)sub[0]; long im = imm_val(F[1]);
                    if (!sy && ns == 1 && r_reloc) {   /* explicit base D(B) + relocatable displacement -> IFO228 */
                        note_relocdisp(op, i); put(lc, 0, 4); lc += 4;
                        lrecs[i].a1 = r_raw; lrecs[i].hasa1 = 1; break; }
                    if (!r_addrok) {   /* relocatable implicit base, no covering USING -> IFO209 */
                        note_addrerr(op, i); put(lc, 0, 4); lc += 4;
                        lrecs[i].a1 = 0; lrecs[i].hasa1 = 1; break; }
                    put(lc, ((long)o->op << 24) | ((long)(im & 0xff) << 16) | ((long)b << 12) | (d & 0xfff), 4); lc += 4;
                    lrecs[i].a1 = (d & 0xfffL) + using_base_of(b); lrecs[i].hasa1 = 1; break; }
                case F_S0:   /* no operand: 2-byte opcode + a zero halfword, and the operand field was blanked above because it is a remark */
                    put(lc, o->op, 2); put(lc + 2, 0, 2); lc += 4; break;
                case F_S: { resolve(F[0], &d, sub, &ns, &sy); if (ns >= 2) note_badfmt(op, i); int b = (!sy && ns == 0 && r_ibase >= 0) ? r_ibase : (int)sub[0];   /* 2-byte opcode + S operand D2(B2) */
                    if (!sy && ns == 1 && r_reloc) {   /* explicit base D(B) + relocatable displacement -> IFO228 */
                        note_relocdisp(op, i); put(lc, 0, 4); lc += 4;
                        lrecs[i].a1 = r_raw; lrecs[i].hasa1 = 1; break; }
                    if (!r_addrok) {   /* relocatable implicit base, no covering USING -> IFO209 */
                        note_addrerr(op, i); put(lc, 0, 4); lc += 4;
                        lrecs[i].a1 = 0; lrecs[i].hasa1 = 1; break; }
                    put(lc, o->op, 2); put(lc + 2, ((long)b << 12) | (d & 0xfff), 2); lc += 4;
                    lrecs[i].a1 = (d & 0xfffL) + using_base_of(b); lrecs[i].hasa1 = 1; break; }
                case F_SS: { resolve(F[0], &d, sub, &ns, &sy); int ib1 = r_ibase, l1 = r_len, rl1 = r_reloc, ao1 = r_addrok, se1 = r_subempty; long raw1 = r_raw;
                    resolve(F[1], &d2, sub2, &ns2, &sy2); int ib2 = r_ibase, l2 = r_len, rl2 = r_reloc, ao2 = r_addrok, se2 = r_subempty; long raw2 = r_raw;
                    int twol = (o->op & 0xF0) == 0xF0 && o->op != 0xF0;   /* PACK/UNPK/MVO/AP/SP/MP/DP/ZAP/CP carry two 4-bit lengths */
                    /* SRP is the third shape in the X'Fx' group and neither predicate
                     * covers it: one length in the HIGH nibble, and an IMMEDIATE -- the
                     * rounding digit I3 -- in the low one, from a third operand. It used
                     * to fall through to the single-length path, which writes the length
                     * across the whole byte, so `SRP P1(8),1,0` came out F0 07 where
                     * IFOX00 emits F0 70: the length reaches the machine as the rounding
                     * digit and vice versa, and I3 was never parsed at all (#64). */
                    int srp = (o->op == 0xF0);
                    /* An OMITTED length is not a length of zero. `MVC A(,5),B' writes
                     * the subscript list for its base and leaves the length field
                     * empty, and IFOX00 then uses the IMPLIED length -- L' of the
                     * operand's leading symbol -- exactly as if no list were written.
                     * as370 read the empty field as sub[0] == 0 and emitted a length
                     * byte of 0, so `MVC PRFTIC-IEDQPRF(,R5),INVLDTIC' came out D2 00
                     * where IFOX00 has D2 03 (cc370#201). The form appears where the
                     * displacement is a DSECT-relative difference, which is absolute
                     * and so may carry an explicit base. */
                    int len1 = (ns  >= 1 && !(se1 & 1) ? (int)sub[0]  : (l1 ? l1 : 1));
                    int len2 = (ns2 >= 1 && !(se2 & 1) ? (int)sub2[0] : (l2 ? l2 : 1));
                    /* The base is NEVER the first subscript of an SS operand 1: the
                     * format is D1(L1,B1), so sub[0] is the LENGTH. Falling back to it
                     * handed the length to the machine as a base register --
                     * `CLC FLCPICOD(2),X' came out with B1=2 where IFOX00 writes B1=0,
                     * addressing R2+0x8E instead of absolute 0x8E, which in AHL* and
                     * AMD* is low storage (cc370#203). Same for operand 2 of a
                     * TWO-length SS, where the sole subscript is likewise a length:
                     * `AP LOW(3),LOW(3)' gave B1=B2=3.
                     *
                     * A one-length SS keeps sub2[0] as its base -- there the format IS
                     * D2(B2) -- which is why only that half of the fallback survives.
                     *
                     * sub[0] is OVERLOADED and the distinction is `ns', not its value:
                     * with no subscript list written, resolve() leaves the base it
                     * picked from a USING in sub[0], so suppressing the fallback
                     * outright loses it. `CLC B,B' went from B1=12 to B1=0 and the
                     * suite said so on the first run.
                     *
                     * #191 established that an absolute operand takes a base only from
                     * an absolute USING, and its fixture asserts exactly that with a
                     * relocatable `USING *,15' left unused. That control is written on
                     * an RX operand and never reached this path. */
                    int b1 = (ns  >= 2) ? (int)sub[1]
                           : (ns  == 1) ? (ib1 >= 0 ? ib1 : 0)          /* the sole subscript is the LENGTH */
                           : (ib1 >= 0 ? ib1 : (int)sub[0]);            /* no list: sub[0] IS the resolved base */
                    int b2 = (ns2 >= 2) ? (int)sub2[1]
                           : (twol && ns2 == 1) ? (ib2 >= 0 ? ib2 : 0)  /* two-length: the sole subscript is a LENGTH */
                           : (ib2 >= 0 ? ib2 : (int)sub2[0]);
                    /* explicit base + relocatable displacement on either operand -> IFO228.
                     * Operand 1 D1(L1,B1) always carries a length, so its explicit base is
                     * the 2nd subscript (ns>=2). Operand 2 is D2(B2) for a one-length SS
                     * (MVC/CLC: base is the sole subscript, ns2>=1) but D2(L2,B2) for a
                     * two-length SS (PACK/UNPK/AP...: the sole subscript is the LENGTH and
                     * the base comes from a USING, so an explicit base needs ns2>=2). */
                    int bad1 = (ns >= 2 && rl1), bad2 = (rl2 && (twol ? ns2 >= 2 : ns2 >= 1));
                    if (bad1 || bad2) {   /* IFOX zeroes the whole 6-byte instruction, opcode included */
                        note_relocdisp(op, i); put(lc, 0, 6); lc += 6;
                        lrecs[i].a1 = bad1 ? raw1 : ((d  & 0xfffL) + using_base_of(b1)); lrecs[i].hasa1 = 1;
                        lrecs[i].a2 = bad2 ? raw2 : ((d2 & 0xfffL) + using_base_of(b2)); lrecs[i].hasa2 = 1; break; }
                    if (!ao1 || !ao2) {   /* a relocatable implicit-base operand has no covering USING -> IFO209
                                           * (IFOX zeroes the whole instruction and sets both ADDR columns to 0) */
                        note_addrerr(op, i); put(lc, 0, 6); lc += 6;
                        lrecs[i].a1 = 0; lrecs[i].hasa1 = 1;
                        lrecs[i].a2 = 0; lrecs[i].hasa2 = 1; break; }
                    /* the machine length field is (length-1); an explicitly-coded length of 0
                     * (the `*-*` self-modify idiom) is emitted as field 0, not 0xFF */
                    int lenb;
                    if (srp) {
                        long i3 = 0;
                        /* No pass guard: this switch runs in pass 2 only, like the
                         * other diagnostics raised from it (note_badfmt, note_addrerr). */
                        if (nf >= 3 && F[2][0]) {
                            int rc3 = 0; i3 = expr_val(F[2], &rc3);
                            if (rc3 != 0) note_operr("SRP rounding digit must be absolute (IFOX00 ERR178)", 8, i);
                            else if (i3 < 0 || i3 > 9) note_operr("SRP rounding digit is outside 0-9 (IFOX00 ERR224)", 8, i);
                        } else {
                            /* Not defaulted: SRP takes three operands, and a silent 0 is a
                             * rounding decision made on the programmer's behalf. */
                            note_operr("SRP needs a third operand, the rounding digit (IFOX00 ERR177)", 12, i);
                        }
                        lenb = (int)((((len1 ? (len1 - 1) & 0xf : 0) << 4)) | (i3 & 0xf));
                    } else
                    lenb = twol ? (((len1 ? (len1 - 1) & 0xf : 0) << 4) | (len2 ? (len2 - 1) & 0xf : 0))
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

        if (!strcmp(op, "CSECT") || !strcmp(op, "START")) {
            g_sect_seen = 1;   /* a REPRO past this point is punched after the ESD block */
            /* START is CSECT that may set where the first control section begins.
             * Measured against IFOX00 on MVS/CE (cc370#127):
             *   START 0   -> SD ADDR 000000, byte for byte the CSECT entry
             *   START     -> SD ADDR 000000, the same
             *   START 256 -> SD ADDR 000100, decimal operand, and the LENGTH is
             *                measured from that origin
             *   START 5   -> SD ADDR 000008, so the value is ROUNDED UP to a
             *                doubleword like any section origin.  256 is already
             *                aligned and hides this; 5 is what shows it.
             * The rounding needs no code of its own -- the align8 below already
             * does it, which is why the operand is applied before it. */
            /* Leaving whatever is current: park its own counter, relative to
             * its origin, so resuming it later picks up exactly there. */
            if (cur_sect_id > 0 && cur_sect_id < MAXSECT) sect_rel[cur_sect_id] = lc - sect_base(cur_sect_id);
            in_dsect = 0; org_hwm = 0;
            if (!strcmp(op, "START") && !first_ctl_sect && opnd[0] && opnd[0] != ',')
                start_base = align8(expr_val(opnd, NULL));   /* only the FIRST section can be placed; the chain starts there */
            if (pass == 1 && lbl[0] && pre_csect) {    /* statements preceded this named CSECT -> implicit unnamed PC is esdid1 */
                int k, hassect = 0; for (k = 0; k < nesdord; k++) if (esdord[k].role == ESD_SECT) hassect = 1;
                if (!hassect) { struct sym *pc = sym_get(""); pc->type = S_PC; pc->defined = 1; if (!pc->sect) pc->sect = ++g_sectid; esd_add(pc, ESD_SECT); }
            }
            struct sym *s = sym_get(lbl[0] ? lbl : "");
            if (!s->sect) s->sect = ++g_sectid;
            /* Opening a control section other than the first closes the first
             * one: the END literal pool goes at its end (#68), so take the room
             * before this section's origin is fixed. */
            if (first_ctl_sect && s->sect != first_ctl_sect) pool_reserve();
            /* A control section BEGINS on a doubleword. IFOX00 gives each section
             * its own location counter from zero (BLDESD, xdict.asm:85, stores a
             * zero XLCTR) and rounds the origin up when the sections are chained
             * into the module -- the idiom is spelled out at xfour.asm:313,
             * "LA R11,D7(,R11)  ROUND TO DOUBLE WORD BOUNDARY". as370 runs one
             * continuous counter instead and took the origin unrounded, so a
             * section that followed one ending off a doubleword started early and
             * its own internal alignment then fell differently: the SAME runtime
             * source came out with sixteen different lengths across one corpus,
             * depending only on what preceded it in the file (#61).
             * A RESUMED section does not begin, so it is not rounded -- hence
             * `opened`, which counts occurrences within this pass rather than
             * across both. The padding belongs to no section: nothing writes it,
             * so it produces no TXT, and it is not charged to the section before
             * it either, because that one's length comes from its own high-water
             * mark rather than from this origin. */
            /* A section BEGINS at its own zero; a RESUMED one picks its own
             * counter back up. The doubleword rounding that used to happen here
             * has moved to the chaining between the passes, where the origins
             * are actually assigned. */
            if (++s->opened == 1 && s->sect < MAXSECT) {
                sect_rel[s->sect] = 0;
                if (pass == 1 && nsect_ord < MAXSECT) sect_ord[nsect_ord++] = s->sect;   /* definition order = chaining order */
            }
            cur_sect_id = s->sect;
            lc = sect_base(cur_sect_id) + (cur_sect_id < MAXSECT ? sect_rel[cur_sect_id] : 0);
            if (!first_ctl_sect) first_ctl_sect = cur_sect_id;   /* IFOX FSTCSECT: the first section that is not a DSECT (nor COM) */
            if (pass == 1 && !s->defined) { s->type = lbl[0] ? S_SD : S_PC; s->val = 0; s->defined = 1; esd_add(s, ESD_SECT); }   /* relative origin; assign_origins() makes it absolute */
            if (pass == 2) { cur_sect_esdid = s->esdid; lrecs[i].loc = lc; }   /* the listing shows the section's OWN counter, not the one it left (#227) */
        } else if (!strcmp(op, "DSECT")) {          /* dummy section: own counter from 0, no object text */
            /* A DSECT is just another section with its own counter -- the save
             * and restore this used to do by hand for the enclosing control
             * section is now what every section gets. main_lc/main_sect_id are
             * kept because the DSECT-to-END path still restores through them. */
            if (!in_dsect) { main_lc = lc; main_sect_id = cur_sect_id; }
            if (cur_sect_id > 0 && cur_sect_id < MAXSECT) sect_rel[cur_sect_id] = lc - sect_base(cur_sect_id);
            in_dsect = 1; org_hwm = 0;
            struct sym *s = sym_get(lbl[0] ? lbl : "");
            if (!s->sect) s->sect = ++g_sectid;
            cur_sect_id = s->sect;
            if (cur_sect_id < 256) dsect_sect[cur_sect_id] = 1;   /* symbols here are absolute offsets */
            if (++s->opened == 1 && cur_sect_id < MAXSECT) sect_rel[cur_sect_id] = 0;   /* a DSECT is never chained, so it takes no slot in sect_ord */
            lc = (cur_sect_id < MAXSECT) ? sect_rel[cur_sect_id] : 0;   /* sect_base is 0 for a DSECT in either pass */
            if (pass == 2) lrecs[i].loc = lc;                           /* its own counter, from zero on the first opening (#227) */
            if (pass == 1) { s->val = 0; s->defined = 1; }
        } else if (!strcmp(op, "ISEQ")) {
            /* Input sequence checking.  Measured against IFOX00 (cc370#128): it
             * emits no bytes and does not advance the location counter, and an
             * out-of-sequence statement is still ASSEMBLED -- IFO025 is a
             * diagnostic, not a rejection (the offending BR 14 appeared at
             * 000004 with the section two bytes longer).  So recognising the
             * statement is provably object-neutral, and what is not yet
             * reproduced is the IFO025 diagnostic itself. */
            /* nothing to do */
        } else if (!strcmp(op, "TITLE")) {
            if (pass == 1 && lbl[0] && !deck_id[0]) scopy(deck_id, lbl, 8);   /* first named TITLE -> deck id */
        } else if (!strcmp(op, "ENTRY")) {
            /* ENTRY takes a comma-separated symbol list, exactly like EXTRN/WXTRN
             * below -- IFOX00 accepts `ENTRY ALPHA,BETA` and emits one LD per
             * symbol. as370 used to sym_get() the whole operand as a single name,
             * so a list tripped the >8-character external-symbol check on
             * "ALPHA,BETA" instead of assembling (#50). */
            if (pass == 1 && opnd[0]) { int nf = split_fields(opnd, extsym, MAXEXTSYM), j;
                for (j = 0; j < nf; j++) { if (!extsym[j][0]) continue;   /* degenerate empty field (ENTRY A,,B): never sym_get("") -- that name is the unnamed private-code section */
                    struct sym *s = sym_get(extsym[j]); s->is_entry = 1; esd_add(s, ESD_LD); } }
        } else if (!strcmp(op, "EXTRN") || !strcmp(op, "WXTRN")) {
            int weak = (op[0] == 'W');
            if (pass == 1 && opnd[0]) { int nf = split_fields(opnd, extsym, MAXEXTSYM), j;
                for (j = 0; j < nf; j++) { if (!extsym[j][0]) continue;
                    struct sym *s = sym_get(extsym[j]); if (!s->defined) s->type = S_ER; if (weak) s->is_weak = 1; esd_add(s, ESD_ER); } }
        } else if (!strcmp(op, "USING")) {
            char F[17][FLDW]; int nf = split_fields(opnd, F, 17);   /* base + up to 16 base registers */
            if (pass == 2) {
                int brel = 0;
                /* `*' alone is the location counter; `*+8' is an EXPRESSION that
                 * begins with it.  Testing only the first character took the bare
                 * counter and threw the rest away, so `USING *+8,R15' -- the
                 * ordinary way to establish addressability just past a BALR and
                 * its save area -- set the base 8 bytes low and every displacement
                 * through that register came out 8 too high, silently.  IGG019GC
                 * and IGG019GD carry it; IBM's own shipped object agrees with
                 * IFOX00 against us there (cc370#275). */
                long base = (F[0][0] == '*' && !F[0][1]) ? lc : expr_val(F[0], &brel);
                int isabs = 0, bsect = cur_sect_id;
                if (!(F[0][0] == '*' && !F[0][1])) { char nm[64]; int n = 0; const char *e = F[0]; while (*e && !strchr("+-*/(), ", *e) && n < 63) nm[n++] = *e++; nm[n] = 0; struct sym *bs = sym_find(nm);
                    if (bs) bsect = bs->sect;
                    /* An ABSOLUTE domain -- `GSPCB EQU 0' with its fields as
                     * absolute EQUs, the pre-DSECT way of mapping a control
                     * block.  The base symbol must be DEFINED and absolute, not
                     * merely non-relocatable: an UNDEFINED symbol also evaluates
                     * to 0 and non-relocatable, and taking that for an absolute
                     * domain made every absolute operand in the module pick up a
                     * base.  IFFAAA01 maps GSPCB from a macro we do not have, so
                     * `USING GSPCB,R2WRK' names nothing at all -- and `L R4WRK,16'
                     * then addressed R2+16 where IFOX00 reads absolute 16, the
                     * CVT pointer. 52 decks lost their identity to that before
                     * the gate caught it. */
                    isabs = !brel && bs && bs->defined && bs->type == S_ABS; }
                /* USING is keyed by BASE REGISTER: a second USING naming a
                 * register that is already in a domain REPLACES it -- IFOX00
                 * does so quietly, with no diagnostic on the replacing card
                 * (tests/usingkey.s).  Appending left the dead entry live, and
                 * using_for() kept resolving against it: an operand below the
                 * new base assembled silently at rc 0 where IFOX00 gives IFO209
                 * and zeroes the instruction.  1,132 of the 5,528 MVSBLD
                 * modules re-USE a live register (cc370#177).
                 * This also retires the 32-entry cap above as a live hazard --
                 * 31 modules overflowed it and lost every further USING without
                 * a word, IDA019R4 alone 130.  Keyed by register the table can
                 * never exceed 16 entries, so the bound is now unreachable
                 * rather than merely generous. */
                /* ONE USING may name up to 16 base registers, and they are
                 * assigned BY POSITION, not by number: `USING D,11,12,10' makes
                 * 11 the base for D, 12 for D+4096 and 10 for D+8192.  as370
                 * read F[1] and dropped the rest, so everything past the first
                 * 4096 bytes of the domain had no base at all -- IFO209, and the
                 * instruction zeroed.  `USING BLSUPRAB,RB,RC' is the ordinary
                 * way to map a control block wider than a register reaches, and
                 * a module gets it in the middle: BLSUPUT addresses its fields at
                 * x'E38' and x'28A' correctly through RB and loses the one at
                 * x'1144'.  40 of the residual modules (cc370#154).
                 *
                 * Position, not number, is what tests/usingmul.s pins: its
                 * registers descend (11,12,10) so an assignment sorted by
                 * register number gives HIGH the 11, and EDGE at D+4092 gives 11
                 * only because the ranges ASCEND -- were they all based at D, the
                 * #138 tie-break would hand it the 12. */
                { int j;
                  for (j = 1; j < nf; j++) {
                      int reg, slot = -1, q;
                      if (!F[j][0]) continue;          /* an omitted register leaves ITS range uncovered, and the next one still advances */
                      reg = (int)expr_val(F[j], 0);
                      for (q = 0; q < nusing; q++) if (usings[q].reg == reg) { slot = q; break; }
                      if (slot < 0) { if (nusing >= 32) break; slot = nusing++; }
                      usings[slot].reg = reg; usings[slot].base = base + 4096L * (j - 1);
                      usings[slot].sect = bsect; usings[slot].isabs = isabs;
                  } }
                lrecs[i].a2 = base; lrecs[i].hasa2 = 1;   /* IFOX shows the USING's first-operand value in the ADDR2 column */
            }
        } else if (!strcmp(op, "DROP")) {
            if (pass == 2) { char F[4][FLDW]; int nf = split_fields(opnd, F, 4), j, k;
                if (!nf) nusing = 0;                       /* DROP with no operand drops all */
                else for (j = 0; j < nf; j++) { int r = (int)expr_val(F[j], 0);
                    for (k = 0; k < nusing; ) { if (usings[k].reg == r) { usings[k] = usings[--nusing]; } else k++; } } }
        } else if (!strcmp(op, "REPRO")) {
            /* Nothing is assembled and the location counter does not move. All
             * this records is WHERE the card falls in the punch stream. */
            if (pass == 2 && npunch < MAXREPRO) {
                int r; for (r = 0; r < nrepro; r++) if (repro_line[r] == i) {
                    punches[npunch].ridx = r; punches[npunch].at_bytes = txl_blen;
                    punches[npunch].before_esd = !g_sect_seen; npunch++; break; } }
        } else if (!strcmp(op, "PUSH") || !strcmp(op, "POP")) {   /* PUSH/POP USING: save/restore the active USING table (PRINT etc. ignored) */
            if (pass == 2 && strstr(opnd, "USING")) {
                static struct uent ustk[16][32]; static int ustkn[16], usp;
                if (op[1] == 'U') { if (usp < 16) { memcpy(ustk[usp], usings, sizeof usings); ustkn[usp] = nusing; usp++; } }   /* PUSH */
                else if (usp > 0) { usp--; memcpy(usings, ustk[usp], sizeof usings); nusing = ustkn[usp]; }                      /* POP */
            }
        } else if (!strcmp(op, "CNOP")) {                      /* align with NOPR (0x0700) fill */
            char F[2][FLDW]; split_fields(opnd, F, 2);
            int b = (int)expr_val(F[0], 0), nn = (int)expr_val(F[1], 0);
            /* CNOP positions a HALFWORD, so an odd location counter is brought
             * up first with a single zero byte -- and the label addresses THAT
             * point, before the no-ops. Measured on IFOX00 across `CNOP 0,4',
             * `2,4', `0,8' and `4,8' from odd and even counters.
             *
             * The old loop stepped two bytes at a time from wherever it was and
             * gave up after 64 tries. From an odd counter it could never reach
             * an even residue, so it emitted 64 no-ops and left the counter 128
             * bytes further on -- silently, at rc 0, with every following
             * address in the section wrong. `LBL CNOP 0,4' one byte into a
             * section put the next statement at x'81' where IFOX00 has x'04'.
             *
             * And the label was never defined at all: every macro that aligns
             * with `&NAME CNOP 0,4' -- LOAD, LINK, CALL and their relatives --
             * lost the symbol the caller had written in the name field, which
             * is 84 modules of "undefined symbol" that IFOX00 assembles without
             * a word (cc370#231, part of #153). */
            if (lc & 1) { if (pass == 2) put(lc, 0, 1); lc++; }
            if (pass == 1 && lbl[0]) { struct sym *s = sym_get(lbl); s->val = lc; s->defined = 1; s->sect = cur_sect_id; s->len = 1; }
            if (pass == 2) lrecs[i].loc = lc;
            if (nn > 1 && !(b & 1) && b < nn) {
                long need = ((long)b - lc) % nn; if (need < 0) need += nn;
                while (need > 0) { if (pass == 2) put(lc, 0x0700, 2); lc += 2; need -= 2; }
            }
        } else if (!strcmp(op, "ORG")) {                       /* set the location counter (ORG expr) or reset to the high-water mark (bare ORG) */
            if (lc > org_hwm) org_hwm = lc;
            lc = (!opnd[0] || opnd[0] == ',') ? org_hwm : expr_val(opnd, NULL);   /* bare ORG or `ORG ,` resets to the high-water mark */
            /* LOC keeps the counter on the way IN -- lrecs was stamped with it
             * before the statement ran -- and IFOX00 puts the NEW counter in
             * ADDR2, for all three forms: `ORG *-4', a bare ORG, and `ORG expr',
             * inside a dummy section as well (#227). */
            if (pass == 2) { lrecs[i].a2 = lc; lrecs[i].hasa2 = 1; }
            /* The counter the ORG SETS extends the section too, not only the one
             * it left behind.  `ORG *+200' as a maintenance area at the end of a
             * CSECT reserves the space without emitting one byte of TXT, and
             * as370 tracked the high-water mark from DS/DC alone -- so the
             * section stayed 200 bytes short and the NEXT section moved forward
             * by the same 200.  Two wrong ESD entries and every reference into
             * the second section wrong with them, at rc 0 (cc370#279).
             * A backward ORG cannot shrink anything: sect_lc_of only raises. */
            if (lc > org_hwm) org_hwm = lc;
            if (!in_dsect) { if (org_hwm > modlen) modlen = org_hwm; note_sect_lc(org_hwm); }
        } else if (!strcmp(op, "CCW")) {                       /* channel command word: cmd, AL3 address, flags, AL2 count (doubleword aligned) */
            { long old = lc; while (lc & 7) lc++; if (pass == 2) while (old < lc) put(old++, 0, 1); }
            if (pass == 1 && lbl[0]) { struct sym *s = sym_get(lbl); s->val = lc; s->defined = 1; s->sect = cur_sect_id; s->len = 8; }
            if (pass == 2) { char F[4][FLDW]; int nf = split_fields(opnd, F, 4);
                put(lc, expr_val(F[0], 0) & 0xff, 1);
                int rc = 0; long av = nf >= 2 ? expr_val(F[1], &rc) : 0; put(lc + 1, av, 3);
                /* The data address is relocatable, so it needs an RLD entry -- and
                 * `*' is a relocatable target like any label.  This used to demand a
                 * SYMBOL: reloc_sym returns "*" for the location counter, sym_find
                 * has nothing to find, and the entry was dropped.  A channel program
                 * that reads into its own CCW string writes `CCW cmd,*,flags,n', which
                 * is ordinary rather than exotic -- the loader then never relocated the
                 * address, so it was right only while the module sat at the origin the
                 * assembler gave it.  The DC path has always taken the location counter
                 * (its `tgtreal' below); this is the same predicate, missing here. */
                if (rc != 0) { char rsym[64]; reloc_sym(F[1], rsym, sizeof rsym);
                    struct sym *es = (rsym[0] && rsym[0] != '*') ? sym_find(rsym) : NULL;
                    int tgtreal = (rsym[0] == '*') ? !dsect_sect[cur_sect_id & 255]
                                                   : (es && !dsect_sect[es->sect & 255]);
                    if (tgtreal) { add_reloc(lc + 1, rsym, 0, 3); } }
                put(lc + 4, nf >= 3 ? expr_val(F[2], 0) & 0xff : 0, 1); put(lc + 5, 0, 1);
                put(lc + 6, nf >= 4 ? expr_val(F[3], 0) & 0xffff : 0, 2); }
            lc += 8;
            if (!in_dsect) note_sect_lc(lc);   /* pass 1 too, for the same reason the instruction path does */
        } else if (!strcmp(op, "DS") || !strcmp(op, "DC")) {
            static char ops[256][1024]; int nops = dc_split(opnd, ops, 256), oi;
            int emit_dc = (pass == 2 && !strcmp(op, "DC"));
            /* One bit run per statement, flushed when a non-bit operand
             * interrupts it or the statement ends (cc370#240). */
            static unsigned char bitbuf[8192]; int bitn = 0;
            for (oi = 0; oi < nops; oi++) {
                /* The name field is defined BEFORE the operand is evaluated, so a
                 * duplication factor may name the statement's OWN label -- the
                 * pad-to-N idiom, `PATCH DC (4096-(PATCH-ERP1))X'00''. IGE0000I
                 * and IGE0002A write exactly that and IFOX00 assembles both at
                 * rc 0; as370 evaluated the factor first, so the symbol was not
                 * yet defined and the statement drew IFO231 and IFO217 and
                 * reserved nothing (cc370#310).
                 *
                 * The value is the location counter as it stands, which is what
                 * the oracle shows: tests/selfdup.s pads twice behind different
                 * run-ups and IFOX00 gives PATCH x'0A' and PATCH2 x'54'. The
                 * setlbl assignments below still run and still decide the final
                 * value, so an aligned type is unaffected -- this only makes the
                 * symbol resolvable while its own operand is being read. */
                if (pass == 1 && oi == 0 && lbl[0])
                    { struct sym *s0 = sym_get(lbl); s0->val = lc; s0->defined = 1; s0->sect = cur_sect_id; s0->len = 1; }
                const char *p = ops[oi]; int cnt = 0, hascnt = 0, k;
                while (isdigit((unsigned char)*p)) { cnt = cnt * 10 + (*p - '0'); hascnt = 1; p++; }
                /* A duplication factor may also be an absolute expression in
                 * parentheses (xdcds.asm:110 -- CLI CHAR1,JLPARN / SEE IF
                 * EXPRESSION).  The character is the constant's TYPE only when it
                 * is neither a digit nor '('; as370 used to go straight to the
                 * type test, so every such operand came out "invalid type" and
                 * reserved nothing -- and every symbol after it in the section
                 * moved (#93).
                 *
                 * Balanced scan, not strchr(')'): the common shape has an inner
                 * parenthesis, ((A-B)/8), and the first ')' is in the wrong place.
                 * The length modifier L(expr) below still has that defect; it is
                 * adjacent and not this change. */
                if (!hascnt && *p == '(') {
                    const char *st = p + 1, *q = st; int d = 1, qt = 0;
                    for (; *q; q++) {
                        if (*q == '\'') { qt = !qt; continue; }
                        if (qt) continue;
                        if (*q == '(') d++;
                        else if (*q == ')' && --d == 0) break;
                    }
                    char ex[256]; int exl = (int)(q - st); if (exl > 255) exl = 255;
                    memcpy(ex, st, (size_t)exl); ex[exl] = 0;
                    p = *q ? q + 1 : q;
                    hascnt = 1;
                    if (pass == 1) {
                        char ubad[64]; int rl = 0; long dv;
                        if (undefined_term(ex, ubad)) {
                            /* Three messages, in the oracle's order. IFOX raises
                             * the relocatability error as well because a term it
                             * cannot resolve is a term it cannot prove absolute,
                             * and IFO217 is severity 12 -- so one forward
                             * reference here takes the whole assembly to RC 12. */
                            char m[VALSZ];
                            snprintf(m, sizeof m, "Duplication factor uses a symbol not previously defined (IFOX00 IFO231) - %.20s", ubad);
                            note_operr(m, 8, i);
                            note_operr("Relocatable duplication factor - an absolute expression is required (IFOX00 IFO217)", 12, i);
                            note_operr("Duplication factor error - no storage reserved (IFOX00 IFO206)", 8, i);
                            note_dupbad(i, oi); cnt = 0;
                        } else if ((dv = expr_val_full(ex, &rl)), rl != 0) {   /* IFO217, severity 12 */
                            note_operr("Relocatable duplication factor - an absolute expression is required (IFOX00 IFO217)", 12, i);
                            note_operr("Duplication factor error - no storage reserved (IFOX00 IFO206)", 8, i);
                            note_dupbad(i, oi); cnt = 0;
                        } else if (!xrl_paired()) {
                            /* Net zero, but the terms came from DIFFERENT sections --
                             * (OTHER-TESTQ) rather than (*-HERE).  IFOX00 gives IFO206
                             * and reserves nothing; as370 read it as the absolute value
                             * 0, which is a LEGAL and silent duplication factor, so the
                             * statement vanished at RC 0 (cc370#133).
                             *
                             * It moves no byte, which is why it survived: the damage is
                             * a wrong CATEGORY.  A module IFOX rejects went into the
                             * recovery comparison as "assembled", differed, and the
                             * difference was charged to the source. */
                            note_operr("Duplication factor error - the terms are not from one section (IFOX00 IFO206)", 8, i);
                            note_dupbad(i, oi); cnt = 0;
                        } else if (dv < 0) {                      /* IFO206, severity 8 */
                            note_operr("Negative duplication factor (IFOX00 IFO206)", 8, i);
                            note_dupbad(i, oi); cnt = 0;
                        } else cnt = (int)dv;                     /* zero is LEGAL and silent: it reserves nothing */
                    } else {
                        /* Pass 2 looks the verdict up; it must not re-derive it,
                         * or a forward reference (defined by now) would allocate
                         * here and nowhere in pass 1. */
                        cnt = dup_rejected(i, oi) ? 0 : (int)expr_val_full(ex, NULL);
                        if (cnt < 0) cnt = 0;
                    }
                }
                if (!hascnt) cnt = 1;
                int ty = *p ? toupper((unsigned char)*p++) : 0;
                int blen = 0, haslen = 0, bitlen = 0;   /* explicit length modifier Ln, L(expr) or L.n (bits) */
                int scale = 0, hasscale = 0;            /* scale modifier Sn, before or after the length */
                /* Sn may stand either side of Ln: FS28 has no length, FL4S3 does.
                 * Parsed on both sides rather than in a loop so the length block
                 * below is untouched (cc370#217). */
                if (*p == 'S') { p++; int sneg = 0;
                    if (*p == '-') { sneg = 1; p++; } else if (*p == '+') p++;
                    while (isdigit((unsigned char)*p)) scale = scale * 10 + (*p++ - '0');
                    if (sneg) scale = -scale;
                    hasscale = 1; }
                if (*p == 'L' && p[1] == '.') { p += 2;   /* a length in BITS */
                    haslen = 1;
                    if (*p == '(') { const char *st = p + 1, *q = st; int d = 1, qt = 0;
                        for (; *q; q++) {
                            if (*q == '\'') { qt = !qt; continue; }
                            if (qt) continue;
                            if (*q == '(') d++;
                            else if (*q == ')' && --d == 0) break;
                        }
                        char ex2[256]; int en2 = (int)(q - st); if (en2 > 255) en2 = 255;
                        memcpy(ex2, st, (size_t)en2); ex2[en2] = 0;
                        bitlen = (int)expr_val_full(ex2, NULL);
                        p = *q ? q + 1 : q; }
                    else while (isdigit((unsigned char)*p)) bitlen = bitlen * 10 + (*p++ - '0');
                    if (bitlen < 1) bitlen = 1;
                }
                else if (*p == 'L') { p++; haslen = 1;
                    /* Two defects lived on this line, and the comment on the
                     * duplication factor above named the second one and left it.
                     * strchr(')') took the FIRST close paren, so L((*-CSECT)/20)
                     * measured "(*-CSECT"; and expr_val reads a leading '(' as a
                     * machine operand's subscript and answers 0.  Either alone
                     * still gives the wrong length -- paren-only yields 0,
                     * expr_val_full-only yields twenty times too many bytes --
                     * so both, with the same balanced scan the duplication
                     * factor uses.  A length of 0 stays legal: DS 0CL(...) is. */
                    if (*p == '(') { const char *st = p + 1, *q = st; int d = 1, qt = 0;
                        for (; *q; q++) {
                            if (*q == '\'') { qt = !qt; continue; }
                            if (qt) continue;
                            if (*q == '(') d++;
                            else if (*q == ')' && --d == 0) break;
                        }
                        char ex[256]; int en = (int)(q - st); if (en > 255) en = 255;
                        memcpy(ex, st, (size_t)en); ex[en] = 0;
                        blen = (int)expr_val_full(ex, NULL); if (blen < 0) blen = 0;
                        p = *q ? q + 1 : q; }
                    else while (isdigit((unsigned char)*p)) blen = blen * 10 + (*p++ - '0'); }
                if (!hasscale && *p == 'S') { p++; int sneg2 = 0;
                    if (*p == '-') { sneg2 = 1; p++; } else if (*p == '+') p++;
                    while (isdigit((unsigned char)*p)) scale = scale * 10 + (*p++ - '0');
                    if (sneg2) scale = -scale;
                    hasscale = 1; }
                int setlbl = (pass == 1 && oi == 0 && lbl[0]);   /* the symbol addresses the first operand */
                /* A bit field joins the run and does not move the location
                 * counter; anything else flushes the run first. The values are
                 * taken by type -- a paren list for the address constants, the
                 * quoted body otherwise -- and each is truncated to its width,
                 * most significant bit first (cc370#240). */
                if (bitlen > 0) {
                    if (setlbl) { struct sym *s0 = sym_get(lbl); s0->val = lc; s0->defined = 1; s0->sect = cur_sect_id; s0->len = (bitlen + 7) / 8; }
                    int rep;
                    if (*p == '(') {
                        const char *lp2 = p, *rp2 = strrchr(p, ')');
                        char in2[512]; int n2 = (rp2 && rp2 > lp2) ? (int)(rp2 - lp2 - 1) : 0;
                        if (n2 > 511) n2 = 511;
                        if (n2 > 0) memcpy(in2, lp2 + 1, (size_t)n2);
                        in2[n2 > 0 ? n2 : 0] = 0;
                        static char vv2[64][FLDW]; int nv2 = split_fields(in2, vv2, 64), vj2;
                        if (nv2 < 1) { nv2 = 1; vv2[0][0] = 0; }
                        for (rep = 0; rep < cnt; rep++)
                            for (vj2 = 0; vj2 < nv2; vj2++)
                                bits_put(bitbuf, (int)sizeof bitbuf, &bitn,
                                         (unsigned long)(vv2[vj2][0] ? expr_val_full(vv2[vj2], NULL) : 0), bitlen);
                    } else if (*p == '\'') {
                        const char *b2 = p + 1; unsigned long v2 = 0;
                        if (ty == 'B')      { while (*b2 && *b2 != '\'') v2 = v2 * 2 + (*b2++ == '1' ? 1 : 0); }
                        else if (ty == 'X') { while (*b2 && *b2 != '\'') { int c2 = toupper((unsigned char)*b2++);
                                                  v2 = v2 * 16 + (unsigned long)((c2 >= '0' && c2 <= '9') ? c2 - '0' : (c2 >= 'A' && c2 <= 'F') ? c2 - 'A' + 10 : 0); } }
                        else if (ty == 'C') { while (*b2 && *b2 != '\'') v2 = (v2 << 8) | mvs_a2e((unsigned char)*b2++); }
                        else                { char nb2[64]; int k2 = 0;
                                              while (*b2 && *b2 != '\'' && k2 < 63) nb2[k2++] = *b2++;
                                              nb2[k2] = 0; v2 = (unsigned long)strtol(nb2, NULL, 10); }
                        for (rep = 0; rep < cnt; rep++) bits_put(bitbuf, (int)sizeof bitbuf, &bitn, v2, bitlen);
                    } else {
                        for (rep = 0; rep < cnt; rep++) bits_put(bitbuf, (int)sizeof bitbuf, &bitn, 0UL, bitlen);   /* DS: reserve only */
                    }
                    continue;
                }
                if (bitn > 0) {   /* a non-bit operand ends the run: pad right to a byte */
                    int nb2 = (bitn + 7) / 8, z2;
                    for (z2 = 0; z2 < nb2; z2++) { if (emit_dc) put(lc, bitbuf[z2], 1); lc++; }
                    bitn = 0;
                }
                if (ty == 'E' || ty == 'D' || ty == 'L') {
                    /* Floating point. DCTABLE (ifnx5d.asm:1164): E 4 bytes on a
                     * fullword, D 8 and L 16 on a doubleword; a length modifier
                     * suppresses the alignment, as for the fixed types above.
                     * D used to sit in the integer arm below -- right space,
                     * wrong bytes, silently: D'1.5' came out 0000000000000001
                     * where IFOX00 says 4118000000000000 (#53). E and L reserved
                     * nothing at all and were flagged as unimplemented. */
                    int base = (ty == 'E') ? 4 : (ty == 'D') ? 8 : 16;
                    int flen = haslen ? blen : base; if (flen < 1) flen = 1;
                    if (!haslen) { long oldlc = lc; lc = (base == 4) ? align4(lc) : align8(lc);
                        if (emit_dc) while (oldlc < lc) put(oldlc++, 0, 1); }
                    /* The label is set ONCE, before the loop, exactly as the
                     * fixed-point arm does: a zero duplication factor (DS 0D, the
                     * alignment idiom) must still define it. */
                    if (setlbl) { struct sym *s = sym_get(lbl); s->val = lc; s->defined = 1; s->sect = cur_sect_id; s->len = flen; }
                    const char *q = strchr(p, '\'');
                    if (!q) {                          /* DS reserves the space; a valueless DC still emits zeros, as before */
                        for (k = 0; k < cnt; k++) { int j; for (j = 0; j < flen; j++) { if (emit_dc) put(lc, 0, 1); lc++; } }
                    } else {
                        /* one operand may carry a list of nominal values */
                        char body[1024]; int slen = 0; const char *e = q + 1;
                        while (*e && *e != '\'' && slen < 1023) body[slen++] = *e++;
                        body[slen] = 0;
                        static char fvals[512][FLDW]; int nv = split_fields(body, fvals, 512), vi;
                        if (nv < 1) { nv = 1; fvals[0][0] = 0; }
                        for (k = 0; k < cnt; k++) for (vi = 0; vi < nv; vi++) {
                            if (emit_dc) emit_float(lc, fvals[vi], flen);
                            lc += flen;
                        }
                    }
                } else if (ty == 'F' || ty == 'A' || ty == 'H' || ty == 'Y' || ty == 'V' || ty == 'S') {
                    int base = (ty == 'H' || ty == 'Y' || ty == 'S') ? 2 : 4;
                    if (!haslen) { blen = base; long oldlc = lc; lc = (base == 8) ? align8(lc) : (base == 2) ? ((lc + 1) & ~1L) : align4(lc);
                        if (emit_dc) while (oldlc < lc) put(oldlc++, 0, 1); }   /* DC alignment padding is emitted as zero TXT (IFOX-compatible) */
                    if (setlbl) { struct sym *s = sym_get(lbl); s->val = lc; s->defined = 1; s->sect = cur_sect_id; s->len = blen ? blen : 1; }
                    long val = 0; int isvcon = (ty == 'V'), isscon = (ty == 'S');
                    int isaddr = (ty == 'A' || ty == 'Y' || isvcon || isscon);
                    if (isaddr) {                                  /* address constant, possibly a value list A(v1,v2,..) */
                        const char *lp = strchr(p, '('), *rp = strrchr(p, ')');
                        char inside[DCINSIDE] = "";
                        if (lp && rp && rp > lp) { size_t n = (size_t)(rp - lp - 1); if (n > DCINSIDE - 1) { n = DCINSIDE - 1; note_operr("DC value list is longer than the operand buffer - the tail is dropped", 8, g_curln); } memcpy(inside, lp + 1, n); inside[n] = 0; }
                        static char vals[DCVALS][VALSZ]; int nv = 0;   /* split the operand list on top-level commas */
                        { const char *s = inside, *st = inside; int q = 0, d = 0;
                          for (;; s++) {
                              if (*s == '\'') { if (q || !(s > inside && strchr("KNLT", s[-1]))) q = !q; }  /* K'/N'/L'/T' apostrophe (e.g. AL2(L'SYM,0)) is an attribute, not a string quote */
                              else if (!q && *s == '(') d++;
                              else if (!q && *s == ')') { if (d) d--; }
                              if ((!q && d == 0 && *s == ',') || !*s) {
                                  if (nv < DCVALS) { int L = (int)(s - st); if (L > VALSZ - 1) L = VALSZ - 1; memcpy(vals[nv], st, L); vals[nv][L] = 0; nv++; }
                                  else note_operr("more than 128 values in one DC operand - the rest are dropped", 8, g_curln);
                                  if (!*s) { break; } st = s + 1; } } }
                        if (nv == 0) { vals[0][0] = 0; nv = 1; }   /* A() -> a single zero constant */
                        if (isvcon && pass == 1 && !in_dsect) { int vj; for (vj = 0; vj < nv; vj++) {   /* register each V-con ER */
                            char r[64]; int sn = 0; const char *se = vals[vj]; while (*se && !strchr("+-(), ", *se) && sn < 63) r[sn++] = *se++; r[sn] = 0;
                            if (r[0]) { struct sym *s = sym_get(r); if (!s->defined) s->type = S_ER; esd_add(s, ESD_ER); } } }
                        for (k = 0; k < cnt; k++) { int vj; for (vj = 0; vj < nv; vj++) {
                            if (emit_dc) {
                                if (isscon) {
                                    /* S-type: a HALFWORD carrying 4 bits of base
                                     * register and 12 of displacement, resolved
                                     * here and never relocated -- the loader has
                                     * nothing to fix up.  Measured on IFOX00
                                     * (cc370#108), one CSECT under USING TESTS,12:
                                     *   S(0)       -> 0000   base 0, disp 0
                                     *   S(4(3))    -> 3004   explicit base 3
                                     *   S(TARGET)  -> C010   base 12 from USING
                                     *   2S(0,TARGET) -> 0000 C010 0000 C010
                                     * The last one needs no code: the duplication
                                     * factor already wraps the whole operand list
                                     * in the loop above, which is what IFOX does. */
                                    long disp = 0; int reg = 0;
                                    const char *v = vals[vj];
                                    const char *ip = strchr(v, '(');
                                    if (ip) {                       /* explicit disp(base) */
                                        char ds[80]; int dn = (int)(ip - v); if (dn > 79) dn = 79;
                                        memcpy(ds, v, (size_t)dn); ds[dn] = 0;
                                        char bs[80]; int bn = 0; const char *bp = ip + 1;
                                        while (*bp && *bp != ')' && bn < 79) bs[bn++] = *bp++;
                                        bs[bn] = 0;
                                        disp = ds[0] ? expr_val(ds, NULL) : 0;
                                        reg  = bs[0] ? (int)expr_val(bs, NULL) : 0;
                                    } else if (v[0]) {
                                        /* Only a RELOCATABLE expression goes
                                         * through USING.  An absolute one is the
                                         * displacement itself with base 0 --
                                         * IFOX gives S(0) the halfword 0000,
                                         * where resolving it through the active
                                         * USING would say C000.  Measured; it is
                                         * the one case of the five that a
                                         * reasonable implementation gets wrong,
                                         * and S(0) is the common null S-con. */
                                        int src = 0; long a = expr_val(v, &src);
                                        if (src != 0) {
                                            reg = using_for(a, expr_sect(v), &disp);
                                            if (!r_addrok) {
                                                /* IFO209, and it is the SAME condition the RX/RS
                                                 * operands already report -- so it takes the same
                                                 * note_addrerr() wording rather than one of its
                                                 * own.  IFOX emits one message for one situation;
                                                 * two texts for it would read as two defects.
                                                 * Measured: "BASE AND DISPLACEMENT CANNOT BE
                                                 * RESOLVED AND ARE SET TO 0", and the halfword
                                                 * really is 0000 -- not the unresolved
                                                 * displacement, which is what using_for's
                                                 * cross-section fallback leaves behind. */
                                                note_addrerr(op, i);
                                                reg = 0; disp = 0;
                                            }
                                        } else { disp = a; reg = 0; }
                                    }
                                    put(lc, ((long)(reg & 0xf) << 12) | (disp & 0xfff), 2);
                                }
                                else if (isvcon) { char r[64]; int sn = 0; const char *se = vals[vj]; while (*se && !strchr("+-(), ", *se) && sn < 63) r[sn++] = *se++; r[sn] = 0;
                                    put(lc, 0, blen); add_reloc(lc, r, 1, blen); }
                                else { char rsym[64]; reloc_sym(vals[vj], rsym, sizeof rsym); int rc = 0;
                                    /* expr_val_full, not expr_val: a nominal value IS an
                                     * expression, and expr_val reads a LEADING '(' as a
                                     * machine operand's subscript and returns 0 without a
                                     * word -- so DC Y((INDEXEND-INDEX1)/2) assembled as
                                     * zero at rc 0 (cc370#167).  Nothing to do with the
                                     * forward references it was found through: DC Y((1+1))
                                     * had the same 0, and so did a backward pair.  The
                                     * same guard was already known wrong for a duplication
                                     * factor, which is what expr_val_full was written for
                                     * -- it was simply never applied here. */
                                    long v = vals[vj][0] ? expr_val_full(vals[vj], &rc) : 0;
                                    struct sym *es = (rsym[0] && rsym[0] != '*') ? sym_find(rsym) : NULL;
                                    int tgtreal = (rsym[0] == '*') ? !dsect_sect[cur_sect_id & 255] : (es && !dsect_sect[es->sect & 255]);
                                    /* in_dsect: a DC inside a DSECT reserves storage and generates no constant at all
                                     * (sysmac/cvt.macro's own `CVTMFRTR DC A(CVTBRET)` is one), so it is not IFO158. */
                                    if ((rc != 0) && !in_dsect && es && dsect_sect[es->sect & 255]) note_dsect_adcon(rsym, i);
                                    put(lc, v, blen);
                                    /* A difference of symbols in DIFFERENT control sections is not
                                     * absolute, and expr_val_full reports NET relocatability -- so
                                     * the two sections cancel and rc reads 0, which is exactly the
                                     * state that needs a SIGNED PAIR of entries (cc370#209). The
                                     * per-section tally decides: one entry per unit, negative where
                                     * the tally is. It is taken only when every named section is a
                                     * real defined section of this module, so an external reference
                                     * or an undefined symbol keeps the symbol-resolved path below.
                                     * A single section at net +1 IS that path, bit for bit. */
                                    { int ts[8]; long tg[8]; int nt = expr_sect_terms(vals[vj], ts, tg, 8);
                                      int q, nz = 0, simple = 1, allreal = 1;
                                      for (q = 0; q < nt; q++) { if (!tg[q]) continue; nz++;
                                          if (tg[q] != 1) simple = 0;
                                          if (!sect_esdid_of(ts[q]) || dsect_sect[ts[q] & 255]) allreal = 0; }
                                      if (nz && !(nz == 1 && simple) && allreal) {
                                          for (q = 0; q < nt; q++) { long t = tg[q], u;
                                              for (u = 0; u < (t < 0 ? -t : t); u++)
                                                  add_reloc_sect(lc, ts[q], blen, t < 0); }
                                      } else if ((rc != 0) && tgtreal) { add_reloc(lc, rsym, 0, blen); } } }   /* AL3 address -> 3-byte relocation, etc. */
                            }
                            lc += blen;
                        } }
                    } else {
                        /* One operand may carry a LIST of nominal values, and each is a
                         * constant of its own: `DC H'6,0,17,6,0'' is five halfwords.
                         * as370 read the body with a single strtol and emitted the
                         * duplication factor's worth of the FIRST value -- so a
                         * five-element table came out as one halfword and every symbol
                         * after it was eight bytes early, silently at rc 0 (cc370#253).
                         * The address types a few lines up have always split their list;
                         * this is the fixed-point arm doing the same. */
                        const char *q = strchr(p, '\'');
                        if (!q) { for (k = 0; k < cnt; k++) { if (emit_dc) put(lc, 0, blen); lc += blen; } }
                        else {
                            char body[1024]; int bn = 0; const char *e = q + 1;
                            while (*e && *e != '\'' && bn < 1023) body[bn++] = *e++;
                            body[bn] = 0;
                            static char fv[512][FLDW]; int nv = split_fields(body, fv, 512), vi;
                            if (nv < 1) { nv = 1; fv[0][0] = 0; }
                            for (k = 0; k < cnt; k++) for (vi = 0; vi < nv; vi++) {
                                val = fv[vi][0] ? (hasscale ? scaled_fixed(fv[vi], scale) : strtol(fv[vi], NULL, 10)) : 0;
                                if (emit_dc) put(lc, val, blen);
                                lc += blen;
                            }
                        }
                    }
                } else if (ty == 'C') {                     /* EBCDIC characters; '' -> one quote */
                    const char *q = strchr(p, '\''); char body[1024]; int slen = 0;
                    if (q) { const char *e = q + 1;
                        while (*e && slen < 1023) {
                            if (*e == '\'') { if (e[1] == '\'') { body[slen++] = '\''; e += 2; continue; } break; }
                            if (*e == '&' && e[1] == '&') { body[slen++] = '&'; e += 2; continue; }
                            body[slen++] = *e++;
                        } }
                    int emit = haslen ? blen : (q ? slen : 1);   /* valueless DS nC reserves cnt*1 bytes (default C length 1) */
                    /* L' comes from the nominal VALUE where no length modifier
                     * gives one, so the symbol cannot be entered before the body
                     * has been scanned -- doing so left L'C'ABC' at 1 where
                     * IFOX00 says 3, silently, at rc 0 (cc370#148).  `emit` is
                     * already the length of ONE constant, which is what L' is:
                     * L' of 3C'AB' is 2, not the field's 6. */
                    if (setlbl) { struct sym *s = sym_get(lbl); s->val = lc; s->defined = 1; s->sect = cur_sect_id; s->len = emit; }
                    for (k = 0; k < cnt; k++) { int j; for (j = 0; j < emit; j++) { if (emit_dc) put(lc, j < slen ? mvs_a2e((unsigned char)body[j]) : 0x40, 1); lc++; } }
                } else if (ty == 'X') {                     /* hex bytes, byte-aligned */
                    const char *q = strchr(p, '\''); unsigned char by[1024]; int nb = 0;
                    if (q) { char h[2056]; int hl = 0, s0 = 0; const char *e = q + 1;
                        while (*e && *e != '\'' && hl < 2055) { if (isxdigit((unsigned char)*e)) h[hl++] = *e; e++; }
                        if (hl & 1) { by[nb++] = (unsigned char)hexv(h[0]); s0 = 1; }
                        for (; s0 + 1 < hl && nb < 1024; s0 += 2) by[nb++] = (unsigned char)((hexv(h[s0]) << 4) | hexv(h[s0 + 1]));
                    }
                    int emit = haslen ? blen : (q ? nb : 1), pad = emit - nb;   /* valueless DS nX reserves cnt*1 */
                    /* L' comes from the nominal VALUE where no length modifier
                     * gives one, so the symbol cannot be entered before the body
                     * has been scanned -- doing so left L'C'ABC' at 1 where
                     * IFOX00 says 3, silently, at rc 0 (cc370#148).  `emit` is
                     * already the length of ONE constant, which is what L' is:
                     * L' of 3C'AB' is 2, not the field's 6. */
                    if (setlbl) { struct sym *s = sym_get(lbl); s->val = lc; s->defined = 1; s->sect = cur_sect_id; s->len = emit; }
                    for (k = 0; k < cnt; k++) { int j; for (j = 0; j < emit; j++) { if (emit_dc) put(lc, (j >= pad && j - pad < nb) ? by[j - pad] : 0, 1); lc++; } }
                } else if (ty == 'B') {                     /* binary, byte-aligned, MSB-first */
                    const char *q = strchr(p, '\''); unsigned char by[256]; int nb = 0;
                    if (q) { char bits[2056]; int bl2 = 0; const char *e = q + 1;
                        while (*e && *e != '\'' && bl2 < 2048) { if (*e == '0' || *e == '1') bits[bl2++] = *e; e++; }
                        int pos = 0, rem = bl2 % 8, first = rem ? rem : (bl2 ? 8 : 0);
                        while (pos < bl2 && nb < 256) { int take = (nb == 0) ? first : 8, v = 0, j; for (j = 0; j < take; j++) v = (v << 1) | (bits[pos++] - '0'); by[nb++] = (unsigned char)v; }
                    }
                    int emit = haslen ? blen : (q ? nb : 1), pad = emit - nb;   /* valueless DS nB reserves cnt*1 */
                    /* L' comes from the nominal VALUE where no length modifier
                     * gives one, so the symbol cannot be entered before the body
                     * has been scanned -- doing so left L'C'ABC' at 1 where
                     * IFOX00 says 3, silently, at rc 0 (cc370#148).  `emit` is
                     * already the length of ONE constant, which is what L' is:
                     * L' of 3C'AB' is 2, not the field's 6. */
                    if (setlbl) { struct sym *s = sym_get(lbl); s->val = lc; s->defined = 1; s->sect = cur_sect_id; s->len = emit; }
                    for (k = 0; k < cnt; k++) { int j; for (j = 0; j < emit; j++) { if (emit_dc) put(lc, (j >= pad && j - pad < nb) ? by[j - pad] : 0, 1); lc++; } }
                } else if (ty == 'P' || ty == 'Z') {   /* packed / zoned decimal: no alignment, DCTABLE mask 0 */
                    int packed = (ty == 'P');
                    const char *q = strchr(p, '\'');
                    if (!q) {
                        /* DS reserves the length with no value; a DC without one
                         * reaches IFOX's LDELIM3 and is a syntax error. */
                        int len = haslen ? blen : 1;   /* DCTABLE default length for P and Z is 1 */
                        if (pass == 1 && !strcmp(op, "DC")) note_operr("Syntax error - decimal constant has no nominal value (IFOX00 ERR178)", 8, i);
                        if (setlbl) { struct sym *s2 = sym_get(lbl); s2->val = lc; s2->defined = 1; s2->sect = cur_sect_id; s2->len = len; }
                        for (k = 0; k < cnt; k++) { int j; for (j = 0; j < len; j++) { if (emit_dc) put(lc, 0, 1); lc++; } }
                    } else {
                        /* One operand may carry a LIST of nominal values: PKON and
                         * ZKON end the current constant on a comma and the caller
                         * starts the next. Each gets the explicit length, or its
                         * own implicit one when there is no length modifier. */
                        char body[1024]; int slen = 0; const char *e = q + 1;
                        while (*e && *e != '\'' && slen < 1023) body[slen++] = *e++;
                        body[slen] = 0;
                        /* The bound cannot be reached, for the reason MAXEXTSYM
                         * carries: split_fields drops everything past its maximum
                         * without a diagnostic (#50), body holds at most 1023
                         * characters, and a value costs at least one digit plus
                         * its comma. A dropped value here would be worse than a
                         * dropped EXTRN symbol -- its storage would never be
                         * reserved, so lc would under-advance at RC 0 and every
                         * later symbol would shift: the very defect #53 closes. */
                        static char vals[512][FLDW]; int nv = split_fields(body, vals, 512), vi;
                        if (nv < 1) { nv = 1; vals[0][0] = 0; }
                        for (k = 0; k < cnt; k++) {
                            for (vi = 0; vi < nv; vi++) {
                                int len = emit_decimal(vals[vi], packed, lc, haslen ? blen : 0,
                                                       emit_dc, pass == 1, i);
                                if (!len) len = haslen ? blen : 1;   /* rejected: still reserve something so later symbols do not stack */
                                if (setlbl && k == 0 && vi == 0) { struct sym *s2 = sym_get(lbl); s2->val = lc; s2->defined = 1; s2->sect = cur_sect_id; s2->len = len; }
                                lc += len;
                            }
                        }
                    }
                } else {
                    /* No storage produced. Say which of the two it is, once per
                     * operand, in pass 1 -- pass 2 walks the same statements. */
                    if (pass == 1) {
                        if (ty && strchr("CXBPZLDEFHAYVQS", ty)) { char w[24]; snprintf(w, sizeof w, "DC/DS type %c", ty); note_notimpl(w, i); }   /* the fifteen valid Assembler XF types; all but Q are handled above */
                        else note_badtype(ty, i);
                    }
                    /* The label is still defined, as before: withholding it would
                     * turn one diagnostic into a cascade of undefined-symbol
                     * errors on every later reference. The address is wrong -- but
                     * the statement is now flagged, which is the whole point. */
                    if (setlbl) { struct sym *s = sym_get(lbl); s->val = lc; s->defined = 1; s->sect = cur_sect_id; s->len = blen ? blen : 1; }
                }
            }
            if (bitn > 0) {   /* the statement ends the run */
                int nb3 = (bitn + 7) / 8, z3;
                for (z3 = 0; z3 < nb3; z3++) { if (emit_dc) put(lc, bitbuf[z3], 1); lc++; }
                bitn = 0;
            }
            if (!in_dsect) { if (lc > modlen) modlen = lc; note_sect_lc(lc); }   /* a DS reserves space that extends the section length even though it writes no TXT */
        } else if (!strcmp(op, "CXD")) {
            /* CXD generates one fullword-aligned fullword, the cumulative length
             * of all pseudo registers. as370 reserves nothing for it, so it is
             * flagged rather than skipped. Pseudo registers are unimplemented --
             * they tie into the Q-type constant and, on the other side, ld370's
             * PR collection rules -- so all three land together or not at all. */
            if (pass == 1) { note_notimpl("CXD", i);
                if (lbl[0]) { struct sym *s = sym_get(lbl); s->val = lc; s->defined = 1; s->sect = cur_sect_id; s->len = 4; } }
        } else if (!strcmp(op, "EQU")) {
            if (pass == 1 && lbl[0]) { struct sym *s = sym_get(lbl); int rc = 0;
                char F[4][FLDW]; int nf = split_fields(opnd, F, 4);
                /* expr_val_full on both: an EQU operand is an expression, and
                 * expr_val reads a leading '(' as a subscript and answers 0.
                 * N EQU (B-A)/2 equated to zero while the control N EQU B-A-2
                 * was right -- silently, and an equate feeds every reference to
                 * it.  Measured on nine modules whose whole deck differs from
                 * IFOX00's in one to three bytes, eight with this as the sole
                 * cause: IEAVESVC BNGIRMOT IEAVELCR IEAVECH0 IGG019P7 IGFINTVL
                 * IGG019KG IGG019KH. */
                s->val = expr_val_full(F[0], &rc); s->defined = 1;
                /* A relocatable EQU belongs to the section of its VALUE, not to
                 * the section the EQU card happens to sit in.  PL/S output puts
                 * every EQU at the END of the module, after the mapping macros
                 * have left a DSECT current -- so `@RC00027 EQU @RC00025', a
                 * plain CSECT label, was booked into whatever DSECT IFGRPL had
                 * opened.  using_for() then looked for a USING covering THAT
                 * section: either none was in range (IFO209 on a module IFOX00
                 * assembles without a word, cc370#154, 156 modules) or the
                 * DSECT's own USING was, and the branch silently took the wrong
                 * base register at rc 0.  s->sect also drives the dsect_sect[]
                 * RLD-target test, so the same mis-booking can cost an address
                 * constant its relocation.
                 * An absolute equate keeps cur_sect_id (its section is dead
                 * weight -- expr_sect and using_for both skip S_ABS), `EQU *'
                 * is unchanged because expr_sect maps `*' to cur_sect_id, and an
                 * operand whose symbol is not yet defined falls back to
                 * cur_sect_id exactly as before. */
                s->sect = rc ? expr_sect(F[0]) : cur_sect_id;
                s->len = (nf >= 2 && F[1][0]) ? (int)expr_val_full(F[1], NULL) : equ_len_of(F[0]);   /* EQU value,length: 2nd operand sets the length attribute (L') */
                s->type = (rc == 0) ? S_ABS : S_REL; }   /* an absolute expression (e.g. SYM-SYM, length, *-DSECT) yields a non-relocatable equate */
        } else if (!strcmp(op, "LTORG") || !strcmp(op, "END")) {
            int k;
            if (!strcmp(op, "END") && opnd[0]) {
                end_has = 1;
                /* The END card's ESDID names the section the entry point is IN --
                 * the loader adds that section's origin to end_addr. Same lookup
                 * as the ESD's LD entry and the RLD's R (#52): an ENTRY symbol
                 * carries no ESDID of its own, and taking the module's first
                 * section for it stamped an offset into CSECT 2 against CSECT 1. */
                if (pass == 2) { struct sym *s = sym_find(opnd); if (s) { end_addr = s->val;
                    end_esdid = s->esdid ? s->esdid : sect_esdid(s->sect); } }
            }
            if (!strcmp(op, "END") && in_dsect) {   /* a trailing DSECT must not capture the pending literal pool: flush it into the control section */
                in_dsect = 0; lc = main_lc; cur_sect_id = main_sect_id; cur_sect_esdid = main_sect_esdid;
            }
            /* Register each =V literal's external reference in the ESD now, when the
             * pool is FLUSHED (not at first use), in first-reference order -- this is
             * IFOX's ESD timing, so an ENTRY (LD) declared between the reference and
             * the flush sorts ahead of these ERs (e.g. @@crtm's @@EXITA). Ahead of
             * the gather, whose segment sort is a placement order, not this one. */
            if (pass == 1) { for (k = 0; k < nlit; k++) { struct lit *l = &lits[k];
                if (l->placed || l->ltseq != litpool || !l->isV) continue;
                struct sym *s = sym_get(l->ext); if (!s->defined) s->type = S_ER; esd_add(s, ESD_ER); } }
            /* gather this pool's literals, segment-sorted (ltseq is assigned at
             * creation = the pool that was open when the literal was first used) */
            static int mem[4096]; int nmem = pool_gather(litpool, mem, 4096);
            /* An END pool goes into the FIRST control section, whose room
             * pool_reserve() already took: assemble it there and put the counter
             * back, so its bytes are punched last but carry that section's ESDID
             * and an address inside it -- IFOX00's LCSAVE/LCRESTOR (#68). */
            int defer = (pool_defer && !strcmp(op, "END") && nmem > 0);
            long sv_lc = lc; int sv_sid = cur_sect_id, sv_eid = cur_sect_esdid;
            if (defer) { lc = pool_org; cur_sect_id = first_ctl_sect; cur_sect_esdid = sect_esdid_of(first_ctl_sect); }
            if (!strcmp(op, "LTORG") || nmem > 0) lc = align8(lc);  /* pool starts on a doubleword */
            { int mi; for (mi = 0; mi < nmem; mi++) {
                struct lit *l = &lits[mem[mi]];
                lc = (lc + l->algn - 1) & ~(long)(l->algn - 1);
                if (pass == 1) { l->loc = lc; l->psect = cur_sect_id;   /* =V external refs are registered at first use in lit_get */
                    if (defer) l->sect = cur_sect_id; }   /* the pool moved sections: references resolve through the USING covering THIS one */
                else emit_lit(l);
                l->placed = 1;
                lc += l->size;
            } }
            if (!in_dsect) { if (lc > modlen) modlen = lc; note_sect_lc(lc); }   /* the pool's doubleword alignment extends the section length (no TXT for the pad) */
            if (defer) { lc = sv_lc; cur_sect_id = sv_sid; cur_sect_esdid = sv_eid; }
            litpool++;
        } else if (pass == 1) note_unknown(op, i);
    }
    if (listing && pass == 2 && have_prev) emit_listing(prev_lc, lc, prev_src);
    if (pass == 2 && prev_li >= 0) lrecs[prev_li].len = (int)(lc - lrecs[prev_li].loc);   /* close the byte count of the last assembled statement (no later statement triggers the flush) */
}

/* ---- OS/360 OBJ writer ---------------------------------------------------- */
/* ASCII -> EBCDIC is mvs_a2e() from common/mvs370: CP037 + the ecosystem NEL
 * (\n -> 0x15), verbatim from the cc370 compiler's i370_ascii_to_ebcdic, so DC C
 * output is byte-identical to the mvsMF upload (which uses the same table) and
 * hence to what IFOX assembled.  Verified table-identical to the copy that used
 * to live here: 0 of 256 bytes differ. */
static void cinit(unsigned char *c) { int i; for (i = 0; i < 80; i++) c[i] = 0x40; }
static void cname(unsigned char *c, const char *n) { c[0] = 0x02; c[1] = mvs_a2e(n[0]); c[2] = mvs_a2e(n[1]); c[3] = mvs_a2e(n[2]); }
static void cbe(unsigned char *c, int off, long v, int n) { int i; for (i = n - 1; i >= 0; i--) { c[off + i] = (unsigned char)(v & 0xff); v >>= 8; } }
static void cebc(unsigned char *c, int off, const char *s, int w) {
    int i, done = 0; for (i = 0; i < w; i++) { if (!done && (!s || !s[i])) done = 1; c[off + i] = done ? 0x40 : mvs_a2e((unsigned char)s[i]); }
}
static void cseq(unsigned char *c, int seq) {
    char b[16]; int i;
    if (deck_id[0]) {                              /* deck id left-justified, sequence right-justified in the leftover cols */
        int nl = (int)strlen(deck_id); if (nl > 8) nl = 8;
        int nd = 8 - nl;                           /* digits available for the sequence */
        for (i = 0; i < nl; i++) c[72 + i] = mvs_a2e((unsigned char)deck_id[i]);
        /* Width comes from the argument (%0*ld) rather than a format string
         * built at run time: identical output, but gcc can bound it, so the
         * -Werror build holds on GNU gcc (issue #33).  nd is 1..7 here and
         * seq % m < 10^nd, so d[] is ample. */
        if (nd > 0) { char d[16]; long m = 1; int k; for (k = 0; k < nd; k++) m *= 10;
            snprintf(d, sizeof d, "%0*ld", nd, (long)(seq % m));
            for (i = 0; i < nd; i++) c[72 + nl + i] = mvs_a2e(d[i]); }
        return;
    }
    sprintf(b, "%08d", seq); for (i = 0; i < 8; i++) c[72 + i] = mvs_a2e(b[i]);
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
/* A section's length is the extent of its own contents -- NOT the distance to
 * the next section's origin, which since #61 includes the doubleword padding in
 * front of that section and would charge it to this one. */
static long sect_length(int e) {
    struct sym *s = esdord[e].s;
    long hw = (s->sect > 0 && s->sect < MAXSECT) ? sect_hwm[s->sect] : 0;
    return hw > s->val ? hw - s->val : 0;
}

static void emit_obj(FILE *f) {
    unsigned char c[80]; int seq = 0, k;

    /* A REPRO ahead of the first control section is punched ahead of the ESD
     * block -- IFOX00 writes SYSPUNCH sequentially and has nothing to say about
     * a section yet. This is ICAPRTBL's case: three cards of IPL text that have
     * to reach the reader before the module does. They carry the source card's
     * own columns 73-80 and do not advance the deck's sequence number. */
    { int pi; for (pi = 0; pi < npunch; pi++)
        if (punches[pi].before_esd) fwrite(repro_img[punches[pi].ridx], 1, 80, f); }

    /* ESD: declaration order, 3 entries per card */
    { int e = 0; while (e < nesdord) {
        cinit(c); cname(c, "ESD");
        int n = 0, cardfirst = 0;
        while (n < 3 && e < nesdord) {
            int ei = e; struct sym *s = esdord[e].s; int role = esdord[e].role, slot = 16 + n * 16; e++;
            /* An ENTRY naming a CONTROL SECTION gets no LD entry: the SD already
             * is that entry point, and IFOX00 emits the SD alone. `ENTRY IERABW'
             * standing 104 cards ahead of `IERABW CSECT' is the ordinary shape --
             * the ENTRY is processed while the name is still unknown, so the LD
             * cannot be suppressed where it is registered and is dropped here
             * instead. as370 emitted LD, PC, SD where IFOX00 has PC, SD, and the
             * spurious entry came FIRST because ENTRY precedes the CSECT card
             * (cc370#199). An ENTRY on an ordinary label still gets its LD. */
            if (role == ESD_LD) { int q, issect = 0;
                for (q = 0; q < nesdord; q++) if (esdord[q].s == s && esdord[q].role == ESD_SECT) { issect = 1; break; }
                if (issect) continue; }
            if (role == ESD_SECT) { esd_ent(c, slot, s->name, s->type == S_PC ? 0x04 : 0x00, s->val, sect_length(ei), 0); if (!cardfirst) cardfirst = esdord[ei].esdid; }
            else if (role == ESD_ER) { esd_ent(c, slot, s->name, s->is_weak ? 0x0a : 0x02, 0, 0, 1); if (!cardfirst) cardfirst = esdord[ei].esdid; }
            /* LD: the last field is the ESDID of the section the symbol is DEFINED
             * IN, not the module's first section -- which is what it used to be,
             * so every entry in a second or later CSECT named the wrong one
             * (#52). The -a listing already resolved it this way. */
            else { esd_ent(c, slot, s->name, 0x01, s->val, sect_esdid(s->sect), 0); }   /* LD entry */
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
      long done = 0;   /* bytes of the emission log already punched -- a REPRO's position */
      for (e = 0; e <= ntxl; e++) {
        long ea; int el, eid; const unsigned char *eb;
        if (e < ntxl) { ea = txl_addr[e]; el = txl_len[e]; eb = txl_bytes + txl_boff[e]; eid = txl_esdid[e]; }
        else { ea = -1; el = 0; eb = NULL; eid = -1; }   /* sentinel: flush the open card */
        int pos = 0;
        do {
            /* A REPRO standing at this point in the emission log ends the TXT
             * card that is open and is punched between the two -- the oracle's
             * three DCs, which would share one card, come out as three cards
             * with a punched card between each pair. The position is a BYTE
             * offset and not an event index: contiguous put()s are merged into
             * one event, so two REPROs inside one run of text would otherwise
             * land at the same place and both come out at the end. */
            { int pi; for (pi = 0; pi < npunch; pi++)
                if (!punches[pi].before_esd && punches[pi].at_bytes == done) {
                    if (open) {
                        cinit(c); cname(c, "TXT"); cbe(c, 5, cstart, 3); cbe(c, 10, cn, 2); cbe(c, 14, cesdid, 2);
                        { int i; for (i = 0; i < cn; i++) c[16 + i] = cbuf[i]; }
                        cseq(c, ++seq); fwrite(c, 1, 80, f); open = 0;
                    }
                    fwrite(repro_img[punches[pi].ridx], 1, 80, f);
                    punches[pi].at_bytes = -1;                 /* punched */
                } }
            if (open && (e == ntxl || ea + pos != running || cn == 56 || eid != cesdid)) {   /* flush: gap, full card, or a section change */
                cinit(c); cname(c, "TXT"); cbe(c, 5, cstart, 3); cbe(c, 10, cn, 2); cbe(c, 14, cesdid, 2);
                { int i; for (i = 0; i < cn; i++) c[16 + i] = cbuf[i]; }
                cseq(c, ++seq); fwrite(c, 1, 80, f); open = 0;
            }
            if (e == ntxl) break;
            if (!open) { cstart = ea + pos; running = cstart; cn = 0; open = 1; cesdid = eid; }
            int take = 56 - cn; if (take > el - pos) take = el - pos;
            /* stop exactly at the next punch boundary so the card ends there */
            { int pi; for (pi = 0; pi < npunch; pi++) {
                long b = punches[pi].at_bytes;
                if (!punches[pi].before_esd && b > done && b - done < take) take = (int)(b - done); } }
            memcpy(cbuf + cn, eb + pos, (size_t)take); cn += take; pos += take; running += take; done += take;
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
                c[off] = (rels[k].isV ? 0x10 : 0) | (((rels[k].len - 1) & 3) << 2) | (rels[k].neg ? 0x02 : 0); cbe(c, off + 1, rels[k].addr, 3);
                prevflag = off; off += 4;
            } else {
                cbe(c, off, rels[k].rel, 2); cbe(c, off + 2, rels[k].pos, 2);
                c[off + 4] = (rels[k].isV ? 0x10 : 0) | (((rels[k].len - 1) & 3) << 2) | (rels[k].neg ? 0x02 : 0); cbe(c, off + 5, rels[k].addr, 3);
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
            /* LENGTH col 27: the section's own extent, the same figure the object
             * deck's ESD carries. It used to be the whole MODULE's length for the
             * first section and a hard zero for every other -- right only while a
             * module has one section, which is why three single-section listing
             * references never caught it (#70). */
            snprintf(b, sizeof b, "%06lX", sect_length(k) & 0xffffffL); memcpy(ln + 26, b, 6);
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
        int flag = (rels[k].isV ? 0x10 : 0) | (((rels[k].len - 1) & 3) << 2) | (rels[k].neg ? 0x02 : 0);
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
        char buf[STMTSZ], lbl[32], op[16], opnd[STMTSZ];
        strncpy(buf, lines[i], sizeof buf - 1); buf[sizeof buf - 1] = 0;
        parse(buf, lbl, op, opnd);
        int gen   = (lflags[i] & LF_GEN) != 0;
        int noasm = (lflags[i] & LF_NOASM) != 0;
        const struct opc *o = noasm ? NULL : op_find(op);
        int is_instr = (o != NULL);
        int show_loc = 0, show_obj = 0, show_equ = 0;
        if (!noasm) {
            if (is_instr) { show_loc = show_obj = 1; }
            else if (!strcmp(op, "DC") || !strcmp(op, "DS") || !strcmp(op, "CCW") || !strcmp(op, "CNOP")) { show_loc = show_obj = 1; }
            else if (!strcmp(op, "CSECT") || !strcmp(op, "DSECT") || !strcmp(op, "COM")) { show_loc = 1; }
            /* An EQU does not sit at the location counter -- it names a value --
             * and IFOX00 lists it that way: LOC blank, the symbol's value in
             * ADDR2. as370 printed the location counter in LOC instead, which is
             * a number that has nothing to do with the statement. It cost two
             * withdrawn findings in two sessions on one day (cc370#224 and the
             * PREFL lead on #201), both from reading that column as the value.
             * ORG and LTORG do move the counter and keep LOC. */
            else if (!strcmp(op, "EQU")) { show_equ = 1; }
            else if (!strcmp(op, "ORG") || !strcmp(op, "LTORG")) { show_loc = 1; }   /* ORG's ADDR2 is set at the statement, above */
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
        if (show_equ && lbl[0]) { struct sym *s = sym_find(lbl);
            if (s && s->defined) { char b[16]; sprintf(b, "%05lX", s->val & 0xfffffL); memcpy(ln + 28, b, 5); } }
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
"macro search order (highest first):  -I dirs ; $AS370_MACLIB ; <exedir>/../macros\n"
"  the last is a built-in relocatable default -- the installed sysroot macro\n"
"  library found from this executable's own path, so an installed as370\n"
"  (<prefix>/<triple>/bin/as370) assembles with no -I and no environment.\n"
"  AS370_MACLIB is a colon-separated override (the assembler C_INCLUDE_PATH).\n", o);
}
/* The flagged-statement count IFOX00 prints: the two key spaces, minus the
 * statements counted in both.
 *
 * The raw card number is the only key the spaces share, so an overlap is
 * credited only when EXACTLY ONE non-generated flagged statement carries that
 * origin card. Several sharing it means a COPY'd block -- whose lines keep the
 * COPY statement's origin (see mexp_block) -- or a macro expansion, and there
 * the card no longer identifies one statement. Over-counting is the safe
 * direction: a count one too high is visible beside the messages, an
 * under-count hides a diagnostic.
 *
 * ONE residual, and it is a library-member one. A continuation diagnostic
 * raised inside a macro library carries a MEMBER-RELATIVE card number, which
 * names no statement in this numbering -- so it is counted on its own even when
 * the statement it belongs to is also flagged by one of the ten recorders, and
 * the count comes out one too high. Reproduced deliberately in tests/run.sh
 * ("flagged_libmac"), where it is pinned as a tripwire rather than left to be
 * discovered. Closing it needs the origin (member, card) of every generated line
 * threaded through the macro expander -- issue #91, deliberately not done here:
 * that is the joiner and mexp, the code #63, #78 and #81 came out of, and this
 * is a cosmetic counter.
 *
 * Measured over 835 ecosystem modules: 13 raise a diagnostic at all, none has a
 * library-member continuation diagnostic (#81 removed the last of them), and the
 * count changes in two -- irxprobe.asm 208 -> 205 and, at 9012263^, nsf370's
 * nsfctcio.asm 15 -> 12. */
static int count_flagged_stmts(int nlines) {
    static unsigned char hits[MAXLINES];   /* flagged non-generated statements per origin card, saturating at 2 */
    int i, overlap = 0;
    for (i = 0; i < nlines && i < MAXLINES; i++) {
        if (!stmt_flagged[i] || (lflags[i] & LF_GEN)) continue;
        int c = line_org[i];
        if (c >= 0 && c < MAXLINES && hits[c] < 2) hits[c]++;
    }
    for (i = 0; i < MAXLINES; i++) if (hits[i] == 1 && (cont_mark[i] & CM_PRI)) overlap++;
    return nstmt_flagged + ncont_pri + ncont_lib - overlap;
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
        else if (!strncmp(argv[ai], "--sysparm=", 10)) scopy(g_sysparm, argv[ai] + 10, 95);   /* IFOX PARM=SYSPARM(...); default is the null string */
        else if (!strcmp(argv[ai], "-m") && ai + 1 < argc) ++ai;   /* -m HLASM-option: accepted, not yet implemented */
        else if (!strcmp(argv[ai], "--strict-cont")) strict_cont = 1;   /* a discarded statement becomes severity 8 -- see the RC note below */
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
    /* Macro search path, highest priority first:
     *   1. -I dirs            (added above during option parsing)
     *   2. AS370_MACLIB       (colon-separated override, like C_INCLUDE_PATH)
     *   3. <exedir>/../macros (built-in relocatable default = the sysroot macro
     *                          library; works for plain `as370 foo.asm` with no
     *                          env and no -I, the way a real toolchain assembler
     *                          finds its system macros).
     * Non-existent dirs are harmless -- lib_path() just fails the fopen and
     * moves on -- so running from the build tree (where ../macros is absent)
     * simply falls back to -I. */
    {
        const char *s = getenv("AS370_MACLIB");
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
    if (nmaclib < MAXMACLIB) {
        char exedir[PATH_MAX]; char macdir[PATH_MAX + 16];
        self_exe_dir(argv[0], exedir, sizeof exedir);
        snprintf(macdir, sizeof macdir, "%s/../macros", exedir);
        maclib_dirs[nmaclib++] = strdup(macdir);
    }
    if (!src) { usage(stderr); return 16; }                /* options given but no input file */
    init_sysvars();
    FILE *f = fopen(src, "r"); if (!f) { perror(src); return 16; }
    static char *raw0[MAXLINES], *raw[MAXLINES]; int nr = 0; char lb[256];
    while (nr < MAXLINES) {
        memset(lb, 0, sizeof lb);
        if (!fgets(lb, sizeof lb, f)) break;
        if (nr > 0 && nrepro_raw < MAXREPRO && card_op_is(raw0[nr - 1], "REPRO")) {
            int rl = 0; while (rl < (int)sizeof lb && lb[rl] != '\n') rl++;
            if (rl > 0 && lb[rl - 1] == '\r') rl--;
            { int j; for (j = 0; j < 80; j++) repro_raw[nrepro_raw][j] = (j < rl) ? (unsigned char)lb[j] : ' '; }
            repro_raw_line[nrepro_raw] = nr; nrepro_raw++;
        }
        raw0[nr++] = strdup(lb);
    }
    fclose(f);
    static int raw_org[MAXLINES];
    int n = join_cont(raw0, nr, raw, MAXLINES, NULL, raw_org);   /* fold column-72 continuations; raw_org = input line per statement */

    static char *lines[MAXLINES];
    prescan_symtypes(raw, n);   /* T' of a symbol is answered from open code, before any expansion (#144) */
    int nl = macro_pass(raw, n, lines, raw_org);
    if (eonly) { int j; for (j = 0; j < nl; j++) { fputs(lines[j], stdout); if (lines[j][0] && lines[j][strlen(lines[j]) - 1] != '\n') putchar('\n'); } return 0; }

    /* END ENDS THE ASSEMBLY.  Cards after it are not read, not listed and not
     * assembled -- and the MVSBLD tree has modules with a second module's source
     * appended behind the first END, which as370 assembled straight into the same
     * object: ISTINCU7 came out with three control sections and 2,269 bytes where
     * IFOX00 has one and 210, because IKJEGAPL is defined 1,100 cards past the END
     * (cc370#288).
     *
     * Truncating the statement array here rather than breaking out of do_pass
     * makes both passes and the listing agree by construction; a `break' in the
     * loop would have to be repeated in three places and kept in step. */
    { int k; for (k = 0; k < nl; k++) if (card_op_is(lines[k], "END")) { nl = k + 1; break; } }

    prescan_literals(lines, nl);   /* the END pool has to be known before pass 1 lays the first control section out (#68) */
    do_pass(1, lines, nl);
    { int k, id = 0; for (k = 0; k < nesdord; k++) {         /* SD/PC sections and ER refs get an ESDID; LD entries do not */
        if (esdord[k].role != ESD_SECT && esdord[k].role != ESD_ER) continue;
        esdord[k].esdid = ++id;
        /* FIRST entry wins for the symbol's own id -- among ERs. s->esdid feeds
         * cur_sect_esdid and so the TXT's id and the RLD's P, and last-wins put
         * an ER's id there. */
        if (!esdord[k].s->esdid) esdord[k].s->esdid = esdord[k].esdid; }
      /* But a SECTION outranks an ER for the same name whatever the order was.
       * This used to rest on "a section's SD is registered before any ER for the
       * same name", which is not true the moment the name is REFERENCED first:
       * `DC V(B)' ahead of `B CSECT' registers B's ER first, so s->esdid held the
       * ER and B's whole TXT was filed under it. The ESD itself was right -- both
       * entries present, right types, right lengths and origin -- and only the
       * TXT card named the wrong section, which is why nothing comparing one
       * section's bytes could see it. AMASPZAP files 6,700 bytes that way
       * (cc370#281). */
      for (k = 0; k < nesdord; k++)
        if (esdord[k].role == ESD_SECT) esdord[k].s->esdid = esdord[k].esdid; }
    { int k; main_sect_esdid = 0;            /* the content section: first named SD, else first section */
      for (k = 0; k < nesdord; k++) if (esdord[k].role == ESD_SECT && esdord[k].s->type == S_SD) { main_sect_esdid = esdord[k].s->esdid; break; }
      if (!main_sect_esdid) for (k = 0; k < nesdord; k++) if (esdord[k].role == ESD_SECT) { main_sect_esdid = esdord[k].s->esdid; break; } }
    { int k; for (k = 0; k < nlit; k++) lits[k].placed = 0; }
    { int k; for (k = 0; k < nsym; k++) syms[k].opened = 0; }   /* `opened` counts within a pass: pass 2 must see the same sections begin */
    assign_origins();
    do_pass(2, lines, nl);
    g_pass = 0;   /* everything below (emit_obj, emit_listing_a) is past the point where a diagnostic could still be printed */
    int max_sev = 0;   /* highest IFOX severity of any diagnostic emitted below (drives the RC) */
    if (ncontd) {   /* continuation cards: IFO026 / IFO069, both severity 4 -- warnings, and the RC says 4 */
        int j; for (j = 0; j < ncontd; j++) {
            fprintf(stderr, "%s\n", contd[j].card);                         /* the flagged card */
            if (contd[j].lost) {
                fprintf(stderr, " ERROR: This card was consumed as a continuation and the statement on it discarded%s",
                        contd[j].err == 26 ? (strict_cont ? " (IFOX00 IFO026, severity 4; --strict-cont raises it to 8)" : " (IFOX00 IFO026, severity 4)")
                                           : " (IFOX00 does not even warn here; the card's columns 1-15 are blank)");
            } else if (contd[j].err == 26)
                fprintf(stderr, " WARNING: Characters appear between the begin and continue columns on a continuation card (IFOX00 IFO026)");
            else if (contd[j].err == 27)
                /* IFOX00 issues IFO026 for this too, though its wording does not
                 * describe it: the card is blank from the continue column to 71,
                 * so there is nothing to continue with. Our own words, its number. */
                fprintf(stderr, " WARNING: Continuation card is empty - nothing between the continue column and 71 (IFOX00 IFO026)");
            else
                fprintf(stderr, " WARNING: Too many continuation cards, two allowed (IFOX00 IFO069)");
            if (contd[j].src[0]) fprintf(stderr, " in line %d of library member %s\n", contd[j].line, contd[j].src);
            else                 fprintf(stderr, " in line %d\n", contd[j].line);
        }
        if (ncontd_seen > ncontd)
            fprintf(stderr, " ... and %d further continuation diagnostic%s, %d of them a discarded statement\n",
                    ncontd_seen - ncontd, ncontd_seen - ncontd == 1 ? "" : "s", ncontd_lost);
        /* err 0 is the case as370's own message names: a continued COMMENT card
         * ate the card under it, and that card's columns 1-15 are blank. IFOX00
         * assembles it at severity 0 with NO STATEMENTS FLAGGED -- measured, and
         * the deck is byte-identical on both sides (tests/contsev.s). Raising
         * the return code for it made eight modules disagree with the oracle on
         * decks that were already right, and Mike's rule is that the return code
         * is half of `as370 == IFOX00' (cc370#320).
         *
         * The louder reading is still available and still defensible -- a lost
         * statement that nobody is told about is how nsf370 shipped a comment
         * card that ate a DCBD -- but it belongs to --strict-cont, which raises
         * exactly these to 8, and not to the default. */
        if (ncontd_ifox && max_sev < 4) max_sev = 4;   /* IFOX jermsgcd.asm SEV26 / SEV69 */
        if (strict_cont && ncontd_lost && max_sev < 8) max_sev = 8;   /* --strict-cont only: IFOX00 stays at 4 */
    }
    /* The statement-level diagnostics, in SOURCE order.
     *
     * They are recorded by ten independent category lists, and until 2026-09-07
     * they were PRINTED that way too -- badty, nyi, badfmt, reld, addr, ovl,
     * ovldef, ovlref, then undef.  That is not an order, it is the order the
     * recorders happen to be declared in, and reading it as one is wrong in a
     * way that costs real time: a module carrying any addressability or
     * relocation error could never show an undefined symbol first, whatever the
     * source said.  A whole class partition of the MVSBLD tree was built on
     * "the first message" and had to be thrown away (cc370#153).
     *
     * The key is the lines[] index -- as370's own statement identity, which is
     * source order for the expanded program.  The sort is stable, so several
     * diagnostics on one statement keep the category order they had.
     *
     * The continuation diagnostics above are deliberately NOT merged in: they
     * are raised while cards are being joined, before lines[] exists, so their
     * line number is a raw card and the two keys cannot be compared.  They stay
     * where the phase that raises them puts them, at the top. */
    enum { DG_UNK, DG_OPERR, DG_BADTY, DG_NYI, DG_BADFMT, DG_RELD, DG_ADDR, DG_OVL, DG_OVLDEF, DG_OVLREF, DG_UNDEF, DG_MNOTE };
    struct dgref { int ln, cat, idx; };
    { static struct dgref dg[128 * 11]; int ndg = 0, j;
#define DG_ADD(N, ARR, CAT) do { for (j = 0; j < (N); j++) { dg[ndg].ln = (ARR); dg[ndg].cat = (CAT); dg[ndg].idx = j; ndg++; } } while (0)
        DG_ADD(nunk,     unkln[j],        DG_UNK);
        DG_ADD(noperr,   operr_ln[j],     DG_OPERR);
        DG_ADD(nbadty,   badty_ln[j],     DG_BADTY);
        DG_ADD(nnyi,     nyi_ln[j],       DG_NYI);
        DG_ADD(nbadfmt,  badfmt_ln[j],    DG_BADFMT);
        DG_ADD(nreld,    reld_ln[j],      DG_RELD);
        DG_ADD(naddr,    addr_ln[j],      DG_ADDR);
        DG_ADD(novl,     ovl_ln[j],       DG_OVL);
        DG_ADD(novldef,  ovldef_ln[j],    DG_OVLDEF);
        DG_ADD(novlref,  ovlref_ln[j],    DG_OVLREF);
        DG_ADD(nundef,   undefs[j].line,  DG_UNDEF);
        DG_ADD(nmnote,   mnote_ln[j],     DG_MNOTE);
#undef DG_ADD
        /* Insertion sort: stable by construction, and ndg is at most 1408. */
        { int a, b; for (a = 1; a < ndg; a++) { struct dgref v = dg[a];
            for (b = a - 1; b >= 0 && dg[b].ln > v.ln; b--) dg[b + 1] = dg[b];
            dg[b + 1] = v; } }
        for (j = 0; j < ndg; j++) {
            int ln = dg[j].ln, i2 = dg[j].idx;
            const char *s = lines[ln]; int sl = (int)strlen(s);
            while (sl > 0 && (s[sl-1] == '\n' || s[sl-1] == '\r')) sl--;
            fprintf(stderr, "%.*s\n", sl, s);                               /* the flagged source statement */
            /* "in line N" is the input CARD (line_org).  For a statement that
             * came out of a macro or a COPY that card is the CALL, and every
             * statement of the expansion reports it -- all 75 of IFG0190P's said
             * "in line 1", because the whole module is one IECPDINI call.  So
             * name the statement too whenever it is not the card's own: it is
             * the number the -a listing prints and the number IFOX00 addresses a
             * diagnostic by, and without it an expansion cannot be triaged at
             * all.  Where the two agree -- open code with no expansion ahead of
             * it -- nothing is appended and the message is unchanged. */
            char at[48]; int card = line_org[ln];
            if (card == ln + 1) sprintf(at, "in line %d", card);
            else                sprintf(at, "in line %d (statement %d)", card, ln + 1);
            switch (dg[j].cat) {
            case DG_UNK:
                fprintf(stderr, " ERROR: Undefined operation code %s - %s\n", at, unkops[i2]); break;
            case DG_OPERR:
                fprintf(stderr, " %s: %s %s\n", operr_sev[i2] >= 8 ? "ERROR" : "WARNING", operr_msg[i2], at); break;
            case DG_BADTY:
                /* '?' is the recorder's marker for "no type letter at all" -- a bare
                 * DS 0, or an empty element in the operand list (a trailing comma
                 * that is not a column-72 continuation). Saying "invalid type - ?"
                 * for those would be needlessly cryptic. */
                if (badty_ch[i2] == '?') fprintf(stderr, " ERROR: DC/DS/DXD operand has no constant type %s\n", at);
                else fprintf(stderr, " ERROR: Invalid type declared on DC/DS/DXD constant %s - %c\n", at, badty_ch[i2]);
                break;
            case DG_NYI:
                fprintf(stderr, " ERROR: %s is valid Assembler XF but not implemented by as370 - no storage reserved, every later symbol in the section would move, %s\n", nyi_what[i2], at); break;
            case DG_BADFMT:
                fprintf(stderr, " ERROR: Illegal operand format (index/length not allowed on RS/SI/S operand) %s - %s\n", at, badfmt_op[i2]); break;
            case DG_RELD:
                fprintf(stderr, " ERROR: Relocatable displacement in machine instruction (explicit base requires an absolute displacement) %s - %s\n", at, reld_op[i2]); break;
            case DG_ADDR:
                fprintf(stderr, " ERROR: Addressability error - no active USING covers the operand's section (base and displacement set to 0) %s - %s\n", at, addr_op[i2]); break;
            case DG_OVL:
                fprintf(stderr, " ERROR: Symbol longer than 8 characters (MVS external names are limited to 8) %s - %s\n", at, ovl_sym[i2]); break;
            case DG_OVLDEF:
                fprintf(stderr, " ERROR: Symbol longer than 8 characters in name field (name rejected; MVS symbols are limited to 8) %s - %s\n", at, ovldef_sym[i2]); break;
            case DG_OVLREF:
                fprintf(stderr, " ERROR: Symbol longer than 8 characters in operand expression (instruction zeroed; MVS symbols are limited to 8) %s - %s\n", at, ovlref_op[i2]); break;
            case DG_UNDEF:
                fprintf(stderr, " ERROR: Undefined symbol %s - %s\n", at, undefs[i2].sym); break;
            case DG_MNOTE:
                /* The macro's own words, verbatim. A severity-bearing MNOTE is
                 * an error or a warning by its number; the comment and bare
                 * forms cost nothing and are printed as notes. */
                fprintf(stderr, " %s: MNOTE %s - %s\n",
                        mnote_sev[i2] >= 8 ? "ERROR" : mnote_sev[i2] > 0 ? "WARNING" : "NOTE",
                        at, mnote_txt[i2]); break;
            }
        }
        if (nundef_seen > nundef)
            fprintf(stderr, " ... and %d further undefined-symbol diagnostics\n", nundef_seen - nundef);
    }
    /* Severities, unchanged and per category: they do not depend on print order,
     * and the operand-error floor is per entry rather than shared because
     * ERR178/224/236 are severity 8 while ERR177 is 12 (jermsgcd.asm SEV177).
     * Citing an IFOX error number and then reporting the wrong severity for it
     * would be its own small lie. */
    if (nunk     && max_sev <  8) max_sev = 8;
    if (nbadty   && max_sev <  8) max_sev = 8;
    if (nnyi     && max_sev <  8) max_sev = 8;
    if (nbadfmt  && max_sev < 12) max_sev = 12;
    if (nreld    && max_sev <  8) max_sev = 8;
    if (naddr    && max_sev <  8) max_sev = 8;
    if (novl     && max_sev <  8) max_sev = 8;
    if (novldef  && max_sev <  8) max_sev = 8;
    if (novlref  && max_sev <  8) max_sev = 8;
    if (nundef_seen && max_sev < 8) max_sev = 8;
    { int j2; for (j2 = 0; j2 < noperr; j2++) if (max_sev < operr_sev[j2]) max_sev = operr_sev[j2]; }
    /* An MNOTE severity is the macro writer's judgement and goes straight into
     * the return code -- which is the whole point of #39: the IBM convention is
     * MNOTE 8/12 followed by MEXIT, so the severity is the ONLY trace the error
     * leaves. Per entry, like the operand errors, because they differ. */
    { int j2; for (j2 = 0; j2 < nmnote; j2++) if (max_sev < mnote_sev[j2]) max_sev = mnote_sev[j2]; }

    if (objfn) {
        FILE *of = fopen(objfn, "wb"); if (!of) { perror(objfn); return 16; }
        emit_obj(of); fclose(of);
    }
    emit_listing_a(lines, nl);
    errors = count_flagged_stmts(nl);
    /* A severity without a statement cannot happen -- every recorder marks before
     * it prints -- but if a line index ever went out of range the RC would drop to
     * 0 and a real error would ship silently. Floor it rather than trust that. */
    if (!errors && max_sev) errors = 1;
    if (errors)
        fprintf(stderr, " Assembler Done   %d Statement%s Flagged / %3d was Highest Severity\n", errors, errors == 1 ? "" : "s", max_sev);
    return errors ? max_sev : 0;   /* RC: 0 = clean (silent), else the highest IFOX severity seen (8 = error, 12 = severe). */
}
