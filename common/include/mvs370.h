/* mvs370.h -- primitives shared by the cc370 host tools.
 *
 * These are the pieces that were byte-for-byte duplicated across ld370, ar370,
 * file370 and as370: big-endian field access, the CP037 translation tables, the
 * CKD count field, and the TSO TRANSMIT / NETDATA record primitives.
 *
 * Deliberately NOT here (yet): the IEBCOPY unload and XMIT *emitters*.  ld370's
 * versions are load-module specific and MVS-validated; xmit370 has its own
 * RECFM=FB emitter.  Unifying them is a follow-up, to be done with two proven
 * implementations in hand rather than one guessed abstraction.
 */
#ifndef MVS370_H
#define MVS370_H

#include <stddef.h>

/* ---- big-endian field access ---- */
int  mvs_be16(const unsigned char *p);
long mvs_be24(const unsigned char *p);
void mvs_put16(unsigned char *p, int v);
void mvs_put24(unsigned char *p, long v);
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
