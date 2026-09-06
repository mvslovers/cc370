/* mvs370.h -- primitives shared by the cc370 host tools.
 *
 * Big-endian field access, the CP037 translation tables, the CKD count field,
 * and the TSO TRANSMIT / NETDATA record primitives.  All five tools use these
 * now (as370, ld370, ar370, file370, xmit370); until 2026-09-06 only xmit370
 * did and the other four carried their own copies -- three byte-identical
 * EBCDIC decoders, two sets of big-endian accessors, and a second complete
 * NETDATA text-unit layer in ld370.
 *
 * Deliberately NOT here (yet): the IEBCOPY unload and XMIT *emitters*.  ld370's
 * versions are load-module specific and MVS-validated; xmit370 has its own
 * RECFM=FB emitter.  Unifying them is a follow-up, to be done with two proven
 * implementations in hand rather than one guessed abstraction.  That follow-up
 * is the remaining half of mvslovers/cc370#109, and what #110/#111/#112 wait on.
 */
#ifndef MVS370_H
#define MVS370_H

#include <stddef.h>

/* ---- big-endian field access ---- */
int  mvs_be16(const unsigned char *p);
long mvs_be24(const unsigned char *p);
unsigned long mvs_be32(const unsigned char *p);
void mvs_put16(unsigned char *p, int v);
void mvs_put24(unsigned char *p, long v);
void mvs_put32(unsigned char *p, unsigned long v);
long mvs_rdval(const unsigned char *p, int n);
void mvs_wrval(unsigned char *p, long v, int n);

/* ---- CP037 translation ----
 * mvs_a2e_tab is verbatim the cc370 compiler's i370_ascii_to_ebcdic (and hence
 * as370's a2e_tab), so text converted here is byte-identical to what mvsMF's
 * upload and the compiler produce.  Note \n (0x0A) -> NEL 0x15, the ecosystem
 * newline.  mvs_e2a_tab is its inverse; the two ambiguities are resolved the
 * way the ecosystem (httpd cp037_etoa) resolves them:
 *   - EBCDIC 0x15 is the image of both ASCII 0x0A and 0x85 -> maps back to 0x0A
 *   - EBCDIC 0x25 (pure-CP037 LF) is not in the forward table -> maps to 0x85
 */
extern const unsigned char mvs_a2e_tab[256];
extern const unsigned char mvs_e2a_tab[256];
unsigned char mvs_a2e(int c);
unsigned char mvs_e2a(int c);
/* EBCDIC -> ASCII for text we are about to PRINT: the full CP037 inverse, but
 * anything that lands outside printable ASCII becomes '?'.  Use this and never
 * mvs_e2a() for display -- 161 of the 256 EBCDIC bytes map to a non-printable
 * ASCII byte, and writing those to a terminal raw is how a hex dump starts
 * emitting control characters.  ld370/ar370/file370 each carried a hand-rolled
 * partial decoder that returned '?' for everything it did not know; this renders
 * the 53 printable characters they were losing (lowercase, '.', '-', '(' ...)
 * and keeps their '?' for the rest. */
char mvs_e2a_pr(int c);

/* 8-byte blank-padded EBCDIC member/section name from an ASCII string */
void mvs_name8(unsigned char d[8], const char *s);
/* inverse: 8-byte EBCDIC name -> NUL-terminated ASCII, trailing blanks trimmed.
 * Returns a pointer to a static buffer, valid until the next call. */
const char *mvs_nm(const unsigned char n[8]);

/* ---- whole-file read; returns malloc'd buffer, NULL on error ---- */
unsigned char *mvs_read_file(const char *path, long *len);

/* ---- CKD record images ----
 * 12-byte count field: F(1) + MBBCCHHR(8) + KL(1) + DL(2).
 */
void mvs_put_count(unsigned char *p, int cc, int hh, int r, int kl, int dl);

/* ---- 3350 CKD geometry ----
 * One derivation, several uses -- kept distinct because confusing them IS the
 * over-packing bug (S106-0F on FETCH, mvslovers/cc370 2026-06-24):
 *   LEN     physical usable bytes on one track
 *   OVH     gap + count field carried by every record on it
 *   MAXBLK  the largest single record that fits, LEN - OVH.  Also exactly the
 *           UMBLK the 3350 device table in COPYR1 carries, so it is what a
 *           --blocksize is capped at.
 * PACK_CAP, the budget the unload emitters pack a track against, is deliberately
 * MAXBLK and not LEN: costing every record at OVH + data and holding the sum
 * under MAXBLK leaves one record's overhead unspent, so a track can be
 * under-filled but never over-packed.  Program FETCH positions by each record's
 * on-disk count field and rejects a track that claims more than it can hold;
 * IEBCOPY and BPAM are directory-driven and do not, which is why an over-packed
 * image round-trips on the host and abends on the machine.
 */
#define MVS_TRK_LEN_3350     19254
#define MVS_TRK_OVH_3350     185
#define MVS_TRK_MAXBLK_3350  (MVS_TRK_LEN_3350 - MVS_TRK_OVH_3350)   /* 19069 */
#define MVS_TRK_PACK_CAP_3350 MVS_TRK_MAXBLK_3350
#define MVS_TRKPERCYL_3350   30

/* ---- IEBCOPY unloaded-PDS environment header ----
 * COPYR1 (52) + COPYR2 (276), echoed verbatim from a real IEBCOPY unload and
 * then stamped with the DCB and the data extent.  ld370 (RECFM=U load library)
 * and xmit370 (RECFM=FB source library) share it byte for byte; only which
 * fields they stamp differs.
 */
#define MVS_ENV_HDR_LEN   328
#define MVS_COPYR1_LEN    52       /* MVS 3.8j COPYR1 = L$XC138 in DXCOPYR1 */
extern const unsigned char mvs_unload_env_hdr[MVS_ENV_HDR_LEN];

/* COPYR1 field offsets (DXCOPYR1 / IEBLDUL) */
#define MVS_XC1DSORG   4
#define MVS_XC1BLKSZ   6           /* the LIBRARY blocksize */
#define MVS_XC1LRECL   8
#define MVS_XC1RECFM  10
#define MVS_XC1KEYLN  11
#define MVS_XC1TBLKS  14           /* the unloaded-PS blocksize (= library + 20) */

/* UDEBX (the DEB data extent) within the env header.  The directory's relative
 * TTR is resolved against this extent, so it must span every track written. */
#define MVS_UDEBX_STRCC  74
#define MVS_UDEBX_STRHH  76
#define MVS_UDEBX_ENDCC  78
#define MVS_UDEBX_ENDHH  80
#define MVS_UDEBX_NMTRK  82
#define MVS_UNLOAD_DATA_CC 0x008d  /* base cylinder of the echoed data extent */

/* Grow the UDEBX data extent to span `ntracks` relative tracks, in whole
 * cylinders, so the fake-DEB TTR <-> MBBCCHHR conversion stays valid.  Both
 * emitters did this identically; a divergence here reads the wrong track on
 * reload, which is silent until it is not. */
void mvs_udebx_extent(unsigned char *hdr, int ntracks);

/* ---- TSO TRANSMIT / NETDATA ----
 * Text-unit keys, cross-checked against the mainframed/xmi reference.
 */
enum {
    INM_DSNAM = 0x0002, INM_DIR   = 0x000c, INM_BLKSZ = 0x0030,
    INM_DSORG = 0x003c, INM_LRECL = 0x0042, INM_RECFM = 0x0049,
    INM_TNODE = 0x1001, INM_TUID  = 0x1002, INM_FNODE = 0x1011,
    INM_FUID  = 0x1012, INM_FTIME = 0x1024, INM_UTILN = 0x1028,
    INM_SIZE  = 0x102c, INM_NUMF  = 0x102f
};

/* DSORG / RECFM encodings as they appear in COPYR1 and the INMR02 text units */
enum { MVS_DSORG_PO = 0x0200, MVS_DSORG_PS = 0x4000 };
enum { MVS_RECFM_U = 0xc0, MVS_RECFM_F = 0x80, MVS_RECFM_FB = 0x90,
       MVS_RECFM_V = 0x40, MVS_RECFM_VS = 0x48 };

/* one text unit: key(2) + count(2) + length(2) + value */
void mvs_tu(unsigned char *b, long *p, int key, const unsigned char *val, int len);
void mvs_tui(unsigned char *b, long *p, int key, long v, int n);   /* integer value */
void mvs_tus(unsigned char *b, long *p, int key, const char *s);   /* EBCDIC string */
/* INMDSNAM: one value per '.'-separated qualifier of dsn */
void mvs_tu_dsname(unsigned char *b, long *p, const char *dsn);
/* 'INMR0n' eyecatcher; returns 6 */
long mvs_inmr_hdr(unsigned char *r, int n);
/* append a logical record as NETDATA segments (<=253 data bytes each):
 * segment = len(1, incl. this 2-byte header) + flags(1) + data
 * flags: 0x80 first-segment | 0x40 last-segment | 0x20 control-record */
void mvs_netdata_seg(unsigned char *o, long *p, const unsigned char *rec,
                     long len, int control);

/* NETDATA segment flag bits */
enum { NETSEG_FIRST = 0x80, NETSEG_LAST = 0x40, NETSEG_CTL = 0x20 };

#endif /* MVS370_H */
