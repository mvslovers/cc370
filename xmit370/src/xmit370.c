/* xmit370 -- host-native TSO TRANSMIT / RECEIVE for MVS source libraries.
 *
 * Packs a host directory into a TSO TRANSMIT (NETDATA) file holding a
 * partitioned dataset with fixed-length records -- the shape a samplib, a JCL
 * library or a macro library has -- so a distribution can be built entirely on
 * the host and installed with one RECV370 step on MVS.  Also lists and extracts
 * XMIT files, including ones produced by real TSO TRANSMIT / XMIT370.
 *
 *   xmit370 create -o OUT.xmit --dsn HLQ.SAMPLIB [options] DIR
 *   xmit370 list    [-v] FILE.xmit
 *   xmit370 extract [-C DIR] FILE.xmit
 *
 * Relationship to ld370: ld370 emits the same two nested formats (IEBCOPY
 * unloaded PDS wrapped in NETDATA) for RECFM=U *load* libraries.  The container
 * is shared; what differs is the source-library DCB in COPYR1/INMR02, the
 * directory user data (ISPF statistics instead of load-module PDS2 fields) and
 * how member bytes are produced (fixed-length text records instead of
 * load-module record images).  The geometry model here is ld370's, which is
 * validated on real MVS -- see docs/unload-format.md.
 *
 * Format references: docs/xmit-source-pds.md, docs/unload-format.md,
 * docs/xmit-format.md.
 */

#include <ctype.h>
#include <dirent.h>
#include <fnmatch.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <sys/stat.h>
#include <time.h>

#include "mvs370.h"

#define VERSION_STR "xmit370 V1.0"

/* ---- IEBCOPY unload geometry ------------------------------------------------
 * Identical to ld370's, deliberately: this model (contiguous packing costed in
 * REAL 3350 track bytes) is what survived program FETCH on MVS.  Costing by
 * BLKSIZE instead over-packs tracks with many small records into a physically
 * impossible layout -- the S106-0F class of bug.  A source library has many
 * more, smaller blocks than a load library, so the density matters here more,
 * not less.  See docs/unload-format.md.
 */
#define UNLOAD_DATA_CC    0x008d   /* base cylinder of the echoed data extent   */
#define UNLOAD_TRKPERCYL  30       /* 3350 tracks/cylinder                      */
#define TRK_CAP_3350      19069    /* 3350 usable bytes per track               */
#define TRK_OVH_3350      185      /* per-record gap+count overhead             */
#define UDEBX_ENDCC       78       /* DEBENDCC within the 328-byte env header   */
#define UDEBX_ENDHH       80
#define UDEBX_NMTRK       82
#define ENV_HDR_LEN       328      /* COPYR1(52) + COPYR2(276)                  */
#define COPYR1_LEN        52       /* MVS 3.8j COPYR1 = L$XC138 in DXCOPYR1     */
#define DIR_BLK           256      /* PDS directory block                       */

/* COPYR1 field offsets (DXCOPYR1 / IEBLDUL) */
#define XC1DSORG 4
#define XC1BLKSZ 6
#define XC1LRECL 8
#define XC1RECFM 10
#define XC1KEYLN 11
#define XC1TBLKS 14

/* Largest NETDATA logical record RECV370 can take: RECVRCPY GETMAINs a fixed
 * 32 KiB buffer ("L R0,=A(32*1024)  max QSAM blocksize") and reserves the first
 * 4 bytes for an RDW, so one reloaded record may not exceed 32764 bytes.
 * (ld370 uses 18432 instead -- that is the IEWL TXTSIZE ceiling for load-module
 * text records, a different constraint, not RECV370's.) */
#define RECV_MAXREC 32764

/* A block sits on one track as a single record, so it may not exceed the
 * device's maximum block: track length 19254 less the 185-byte record overhead
 * = 19069, which is exactly the UMBLK the 3350 device table in COPYR1 carries. */
#define MAX_BLK_3350 19069
#define TRK_LEN_3350 19254

/* COPYR1 + COPYR2, echoed from a real IEBCOPY unload (same template as ld370).
 * Describes the synthetic source PDS: device characteristics (3350) and the DEB
 * extents the fake-DEB TTR conversion needs.  The DCB half (DSORG/BLKSIZE/
 * LRECL/RECFM/KEYLEN and the unloaded-PS blocksize) is stamped at emit time
 * from the CLI -- that is exactly what differs between a load library and a
 * source library. */
static const unsigned char env_hdr_template[ENV_HDR_LEN] = {
    0x00, 0xca, 0x6d, 0x0f, 0x02, 0x00, 0x4a, 0x7d, 0x00, 0x00, 0xc0, 0x00,
    0x00, 0x00, 0x4a, 0x7d, 0x30, 0x50, 0x20, 0x0b, 0x00, 0x00, 0x4a, 0x7d,
    0x02, 0x30, 0x00, 0x1e, 0x4b, 0x36, 0x01, 0x0b, 0x52, 0x08, 0x02, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0xff, 0x00, 0x00, 0x00,
    0x8f, 0x09, 0x66, 0x44, 0x04, 0x9b, 0xd0, 0xe8, 0x50, 0x00, 0x27, 0xc8,
    0x00, 0x00, 0x00, 0x8d, 0x00, 0x00, 0x00, 0x8d, 0x00, 0x1d, 0x00, 0x1e,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00 };

/* ---- options ---- */
static const char *opt_dsn;
static const char *opt_out;
static const char *opt_outdir = ".";
static long opt_lrecl   = 80;
static long opt_blksize = 3120;      /* 39*80: the universally safe FB80 default */
static int  opt_recfm   = MVS_RECFM_FB;
static int  opt_stats   = 1;
static int  opt_tabs    = 8;         /* 0 = reject tabs */
static int  opt_latin1  = 0;         /* map bytes >= 0x80 through CP037 */
static int  verbose     = 0;
static char opt_userid[9];
static int  have_stats_date = 0;
static struct tm stats_tm;

static const char **excl;
static int nexcl;

/* explicit NAME=FILE mappings */
struct mapping { const char *name, *path; };
static struct mapping *maps;
static int nmaps;

static void die(const char *fmt, ...)
{
    va_list ap;
    fputs("xmit370: ", stderr);
    va_start(ap, fmt); vfprintf(stderr, fmt, ap); va_end(ap);
    fputc('\n', stderr);
    exit(2);
}

/* ---- members --------------------------------------------------------------*/

struct blk { long off, len; int tt, r; };

struct member {
    char name[9];                 /* ASCII, uppercase, NUL-terminated  */
    unsigned char ebc[8];         /* EBCDIC, blank-padded (sort key)   */
    char *path;
    time_t mtime;
    unsigned char *data;          /* EBCDIC, nrec * lrecl bytes        */
    long nrec;
    struct blk *blk;
    int nblk;
    int first_tt, first_r;        /* -> directory TTR                  */
    int eof_tt, eof_r;            /* the DL=0 end-of-member record     */
};

static struct member *mem;
static int nmem, memcap;

static struct member *add_member(void)
{
    if (nmem >= memcap) {
        memcap = memcap ? memcap * 2 : 64;
        mem = realloc(mem, (size_t)memcap * sizeof *mem);
        if (!mem) die("out of memory");
    }
    memset(&mem[nmem], 0, sizeof mem[nmem]);
    return &mem[nmem++];
}

/* ---- member names ---------------------------------------------------------*/

/* An MVS member name is 1-8 of A-Z 0-9 @ # $, first character alphabetic or
 * @ # $.  Real libraries do contain names outside that (the ctca_demo oracle
 * has PEERS_1); those need an explicit --member mapping rather than a silent
 * mangling. */
static int valid_member_name(const char *s)
{
    int i, n = (int)strlen(s);
    if (n < 1 || n > 8) return 0;
    if (!(isalpha((unsigned char)s[0]) || s[0] == '@' || s[0] == '#' || s[0] == '$'))
        return 0;
    for (i = 0; i < n; i++)
        if (!(isalnum((unsigned char)s[i]) || s[i] == '@' || s[i] == '#' || s[i] == '$'))
            return 0;
    return 1;
}

/* basename, minus one trailing extension, uppercased */
static void member_from_path(char out[9], const char *path)
{
    const char *b = strrchr(path, '/');
    const char *dot;
    size_t n;
    int i;
    b = b ? b + 1 : path;
    dot = strrchr(b, '.');
    n = dot && dot != b ? (size_t)(dot - b) : strlen(b);
    if (n > 8) n = 8;
    for (i = 0; i < (int)n; i++) out[i] = (char)toupper((unsigned char)b[i]);
    out[n] = 0;
}

/* ---- text -> fixed-length EBCDIC records ---------------------------------- */

/* Convert one host text file into fixed-length EBCDIC records.
 *
 * The record boundary IS the line break, so no line-terminator byte is ever
 * written -- in particular NOT the ecosystem \n -> NEL mapping, which would put
 * a stray 0x15 into a source card.  Tabs are expanded (column position is
 * load-bearing in assembler and JCL); anything that cannot be represented is a
 * hard error with file:line:column, never a silent substitution.
 */
/* Is the whole buffer well-formed UTF-8?  A file that is drives the diagnostic
 * for a high byte: valid UTF-8 means an editor wrote multi-byte characters that
 * simply have no EBCDIC equivalent (the fix is to clean the file), whereas an
 * ill-formed sequence means the bytes are single-byte Latin-1 -- which CP037
 * does cover, and which --latin1 maps losslessly. */
static int is_utf8(const unsigned char *b, long n)
{
    long i = 0;
    while (i < n) {
        unsigned char c = b[i];
        int extra;
        if (c < 0x80) { i++; continue; }
        else if ((c & 0xe0) == 0xc0) extra = 1;
        else if ((c & 0xf0) == 0xe0) extra = 2;
        else if ((c & 0xf8) == 0xf0) extra = 3;
        else return 0;
        if (i + extra >= n) return 0;
        while (extra--) if ((b[++i] & 0xc0) != 0x80) return 0;
        i++;
    }
    return 1;
}

static int text_to_records(struct member *m, const char *path)
{
    unsigned char *raw, *exp = NULL;
    long rlen, i, expcap = 0;
    long line = 1, cap = 0;
    int errs = 0, utf8;

    raw = mvs_read_file(path, &rlen);
    if (!raw) { fprintf(stderr, "xmit370: %s: cannot read\n", path); return 1; }
    utf8 = is_utf8(raw, rlen);
#define MAXDIAG 8            /* a binary file would otherwise flood the terminal */
#define DIAG(...) do { if (errs < MAXDIAG) fprintf(stderr, __VA_ARGS__); } while (0)

    m->nrec = 0;
    i = 0;
    while (rlen > 0 && i <= rlen) {
        long start = i, end, col = 0, j;
        unsigned char *rec;

        while (i < rlen && raw[i] != '\n') i++;
        end = i;
        if (end > start && raw[end - 1] == '\r') end--;   /* CRLF: \r is terminator */
        /* a trailing newline at EOF does not create an extra empty record */
        if (start == rlen) break;

        /* expand the line into `exp`, validating every byte, so the width check
         * sees the real column count instead of a truncated one */
        for (j = start; j < end; j++) {
            unsigned char c = raw[j];
            long want = col + (c == '\t' && opt_tabs ? (long)opt_tabs : 1);
            if (want + 1 > expcap) {
                expcap = (want + 1) * 2;
                exp = realloc(exp, (size_t)expcap);
                if (!exp) die("out of memory");
            }
            if (c == '\t') {
                long stop;
                if (!opt_tabs) {
                    DIAG("%s:%ld:%ld: tab character (use --tabs N to expand)\n",
                         path, line, col + 1);
                    errs++; break;
                }
                stop = ((col / opt_tabs) + 1) * opt_tabs;
                while (col < stop) exp[col++] = ' ';
                continue;
            }
            if (c >= 0x80 && !opt_latin1) {
                if (utf8)
                    DIAG("%s:%ld:%ld: file is UTF-8; this character has no"
                         " EBCDIC equivalent -- use plain ASCII here\n", path, line, col + 1);
                else
                    DIAG("%s:%ld:%ld: byte 0x%02X is outside ASCII"
                         " (pass --latin1 to map it through CP037)\n", path, line, col + 1, c);
                errs++; break;
            }
            if (c < 0x20 || c == 0x7f) {
                DIAG("%s:%ld:%ld: control character 0x%02X in a text member"
                     " (binary content cannot be a fixed-length text member)\n",
                     path, line, col + 1, c);
                errs++; break;
            }
            exp[col++] = c;
        }
        while (col > 0 && exp[col - 1] == ' ') col--;      /* strip trailing blanks */
        if (col > opt_lrecl) {
            DIAG("%s:%ld:%ld: line is %ld columns, exceeds LRECL %ld\n",
                 path, line, opt_lrecl + 1, col, opt_lrecl);
            errs++;
            col = opt_lrecl;
        }

        if (m->nrec >= cap) {
            cap = cap ? cap * 2 : 64;
            m->data = realloc(m->data, (size_t)cap * (size_t)opt_lrecl);
            if (!m->data) die("out of memory");
        }
        rec = m->data + m->nrec * opt_lrecl;
        memset(rec, 0x40, (size_t)opt_lrecl);              /* pad with EBCDIC blanks */
        for (j = 0; j < col; j++) rec[j] = mvs_a2e(exp[j]);
        m->nrec++;

        if (i >= rlen) break;
        i++;                                               /* step over the '\n' */
        line++;
    }
    if (errs > MAXDIAG)
        fprintf(stderr, "%s: ... and %d more error(s)\n", path, errs - MAXDIAG);
    free(exp);
    free(raw);
    return errs;
#undef DIAG
#undef MAXDIAG
}

/* ---- ISPF statistics ------------------------------------------------------*/

/* Packed 0cyydddF as ISPF stores creation/modification dates. */
static void packed_date(unsigned char d[4], const struct tm *t)
{
    int year = t->tm_year + 1900, ddd = t->tm_yday + 1;
    int yy = year % 100;
    d[0] = (unsigned char)(year >= 2000 ? 0x01 : 0x00);
    d[1] = (unsigned char)(((yy / 10) << 4) | (yy % 10));
    d[2] = (unsigned char)(((ddd / 100) << 4) | ((ddd / 10) % 10));
    d[3] = (unsigned char)(((ddd % 10) << 4) | 0x0f);
}
static unsigned char bcd2(int v) { return (unsigned char)(((v / 10) << 4) | (v % 10)); }

/* The 30-byte ISPF statistics user data, as measured on a real TSO TRANSMIT of
 * a source PDS (see docs/xmit-source-pds.md for the field map). */
static void build_ispf_stats(unsigned char ud[30], const struct member *m)
{
    struct tm t;
    long lines = m->nrec > 65535 ? 65535 : m->nrec;
    int i;

    if (have_stats_date) t = stats_tm;
    else {
        time_t mt = m->mtime;
        struct tm *p = localtime(&mt);
        t = *p;
    }
    memset(ud, 0, 30);
    ud[0] = 0x01;                       /* version    */
    ud[1] = 0x00;                       /* mod level  */
    ud[2] = 0x00;                       /* flags      */
    ud[3] = bcd2(t.tm_sec > 59 ? 59 : t.tm_sec);
    packed_date(ud + 4, &t);            /* created    */
    packed_date(ud + 8, &t);            /* changed    */
    ud[12] = bcd2(t.tm_hour); ud[13] = bcd2(t.tm_min);
    mvs_put16(ud + 14, (int)lines);     /* current lines */
    mvs_put16(ud + 16, (int)lines);     /* initial lines */
    mvs_put16(ud + 18, 0);              /* modified lines */
    for (i = 0; i < 8; i++)
        ud[20 + i] = opt_userid[i] ? mvs_a2e((unsigned char)opt_userid[i]) : 0x40;
    ud[28] = 0x40; ud[29] = 0x40;       /* filler, as the oracle has it */
}

/* ---- the unloaded image ---------------------------------------------------*/

static int ud_len(void)   { return opt_stats ? 30 : 0; }
static int ent_len(void)  { return 12 + ud_len(); }
static int dir_cbyte(void)
{
    /* alias(0x80) | number of TTRs in user data (bits 6-5) | halfwords (bits 4-0).
     * A source member's user data holds no TTR, so the load-module 0x2C becomes
     * 0x0F with ISPF statistics and 0x00 without. */
    return (ud_len() / 2) & 0x1f;
}

/* Blocks per non-last / last directory block.  The last one must also hold the
 * 12-byte X'FF' end-of-directory entry. */
static int per_full(void) { return (DIR_BLK - 2) / ent_len(); }
static int per_last(void) { return (DIR_BLK - 2 - 12) / ent_len(); }

static int count_dir_blocks(void)
{
    int i = 0, n = 1;
    while (nmem - i > per_last()) { i += per_full(); n++; }
    return n;
}

/* Exact size emit_unload() writes, so the buffer is malloc'd to fit rather than
 * guessed (the fixed-buffer class of bug ld370 hit with large --pack sets). */
static long unload_size(void)
{
    long n = ENV_HDR_LEN + 12;                       /* header + EOD marker */
    int i, j;
    n += (long)count_dir_blocks() * (12 + 8 + DIR_BLK);
    for (i = 0; i < nmem; i++) {
        for (j = 0; j < mem[i].nblk; j++) n += 12 + mem[i].blk[j].len;
        n += 12;                                     /* per-member DL=0 EOF */
    }
    return n;
}

static int cmp_member(const void *a, const void *b)
{
    const struct member *x = a, *y = b;
    return memcmp(x->ebc, y->ebc, 8);
}

/* Split each member's records into BLKSIZE blocks and assign every block (and
 * every DL=0 EOF) a relative (track, record). */
static void assign_geometry(void)
{
    long rpb = opt_blksize / opt_lrecl;              /* records per block */
    int tt = 0, r = 1;
    long trkbytes = 0;
    int i;

    for (i = 0; i < nmem; i++) {
        struct member *m = &mem[i];
        long done = 0;
        int j;
        m->nblk = (int)((m->nrec + rpb - 1) / rpb);
        m->blk = m->nblk ? malloc((size_t)m->nblk * sizeof *m->blk) : NULL;
        if (m->nblk && !m->blk) die("out of memory");
        for (j = 0; j < m->nblk; j++) {
            long nr = m->nrec - done; if (nr > rpb) nr = rpb;
            m->blk[j].off = done * opt_lrecl;
            m->blk[j].len = nr * opt_lrecl;          /* last block short, not padded */
            done += nr;
        }

        m->first_tt = tt; m->first_r = r;            /* default for an empty member */
        for (j = 0; j < m->nblk; j++) {
            long need = TRK_OVH_3350 + m->blk[j].len;
            if (r > 1 && trkbytes + need > TRK_CAP_3350) { tt++; r = 1; trkbytes = 0; }
            if (j == 0) { m->first_tt = tt; m->first_r = r; }
            m->blk[j].tt = tt; m->blk[j].r = r;
            r++; trkbytes += need;
        }
        if (r > 1 && trkbytes + TRK_OVH_3350 > TRK_CAP_3350) { tt++; r = 1; trkbytes = 0; }
        m->eof_tt = tt; m->eof_r = r;
        r++; trkbytes += TRK_OVH_3350;
    }
}

/* Emit the IEBCOPY unloaded image.  bounds[] reports the four payload record
 * boundaries the NETDATA layer frames on: COPYR1, COPYR2, directory+EOD, data. */
static long emit_unload(unsigned char *o, long *bounds)
{
    long p = 0;
    int i, j, ntracks = 0, ncyl;
    int esz = ent_len();

    memcpy(o, env_hdr_template, ENV_HDR_LEN);
    /* Stamp the source-library DCB.  For a load library ld370 only has to touch
     * the two blocksizes; a source library differs in DSORG/LRECL/RECFM too, and
     * RECV370 allocates the target from exactly these when the JCL gives no DCB. */
    mvs_put16(o + XC1DSORG, MVS_DSORG_PO);
    mvs_put16(o + XC1BLKSZ, (int)opt_blksize);           /* library BLKSIZE  */
    mvs_put16(o + XC1LRECL, (int)opt_lrecl);
    o[XC1RECFM] = (unsigned char)opt_recfm;
    o[XC1KEYLN] = 0;
    mvs_put16(o + XC1TBLKS, (int)opt_blksize + 20);      /* unloaded-PS BLKSIZE */
    p = ENV_HDR_LEN;
    bounds[0] = COPYR1_LEN;
    bounds[1] = ENV_HDR_LEN;

    for (i = 0; i < nmem; i++)
        if (mem[i].nblk && mem[i].blk[mem[i].nblk - 1].tt + 1 > ntracks)
            ntracks = mem[i].blk[mem[i].nblk - 1].tt + 1;
    for (i = 0; i < nmem; i++)
        if (mem[i].eof_tt + 1 > ntracks) ntracks = mem[i].eof_tt + 1;
    if (ntracks < 1) ntracks = 1;

    /* grow the UDEBX data extent to span every track used, in whole cylinders,
     * so the fake-DEB TTR <-> MBBCCHHR conversion stays valid */
    ncyl = (ntracks + UNLOAD_TRKPERCYL - 1) / UNLOAD_TRKPERCYL;
    if (ncyl < 1) ncyl = 1;
    mvs_put16(o + UDEBX_ENDCC, UNLOAD_DATA_CC + ncyl - 1);
    mvs_put16(o + UDEBX_ENDHH, UNLOAD_TRKPERCYL - 1);
    mvs_put16(o + UDEBX_NMTRK, ncyl * UNLOAD_TRKPERCYL);

    /* directory: name-sorted entries across 256-byte blocks, filled by SIZE
     * rather than by a fixed entry count (the entry is 42 bytes with ISPF
     * statistics, 12 without, 36 for ld370's load modules).  The last block
     * additionally carries the X'FF' end-of-directory entry. */
    {
        unsigned char dir[DIR_BLK];
        int lo = 0;
        for (;;) {
            int last = (nmem - lo <= per_last());
            int hi = last ? nmem : lo + per_full();
            int used = 2;
            memset(dir, 0, sizeof dir);
            for (i = lo; i < hi; i++) {
                unsigned char *e = dir + used;
                memcpy(e, mem[i].ebc, 8);
                mvs_put16(e + 8, mem[i].first_tt);
                e[10] = (unsigned char)mem[i].first_r;
                e[11] = (unsigned char)dir_cbyte();
                if (opt_stats) build_ispf_stats(e + 12, &mem[i]);
                used += esz;
            }
            if (last) { memset(dir + used, 0xff, 8); used += 12; }
            mvs_put16(dir, used);
            mvs_put_count(o + p, 0, 0, 0, 8, DIR_BLK); p += 12;
            if (last) memset(o + p, 0xff, 8);              /* key = high values */
            else memcpy(o + p, mem[hi - 1].ebc, 8);        /* key = high name   */
            p += 8;
            memcpy(o + p, dir, DIR_BLK); p += DIR_BLK;
            if (last) break;
            lo = hi;
        }
        memset(o + p, 0, 12); p += 12;                     /* end-of-directory */
    }
    bounds[2] = p;

    for (i = 0; i < nmem; i++) {
        for (j = 0; j < mem[i].nblk; j++) {
            long bl = mem[i].blk[j].len;
            int tt = mem[i].blk[j].tt, r = mem[i].blk[j].r;
            mvs_put_count(o + p, UNLOAD_DATA_CC + tt / UNLOAD_TRKPERCYL,
                          tt % UNLOAD_TRKPERCYL, r, 0, (int)bl); p += 12;
            memcpy(o + p, mem[i].data + mem[i].blk[j].off, (size_t)bl); p += bl;
        }
        mvs_put_count(o + p, UNLOAD_DATA_CC + mem[i].eof_tt / UNLOAD_TRKPERCYL,
                      mem[i].eof_tt % UNLOAD_TRKPERCYL, mem[i].eof_r, 0, 0); p += 12;
    }
    bounds[3] = p;
    return p;
}

/* current local time as a 16-EBCDIC-digit INMFTIME */
static void xmit_ftime(unsigned char e[16])
{
    char a[17];
    struct tm t;
    int i;
    if (have_stats_date) t = stats_tm;
    else { time_t now = time(NULL); t = *localtime(&now); }
    sprintf(a, "%04d%02d%02d%02d%02d%02d00",
            ((t.tm_year + 1900) % 10000 + 10000) % 10000,
            (t.tm_mon + 1) % 100, t.tm_mday % 100,
            t.tm_hour % 100, t.tm_min % 100, t.tm_sec % 100);
    for (i = 0; i < 16; i++) e[i] = mvs_a2e((unsigned char)a[i]);
}

/* Wrap the unloaded image in NETDATA (RECFM=FB80). */
static long emit_xmit(unsigned char *o, const unsigned char *unl, const long *bounds)
{
    unsigned char r[1024], ft[16];
    long rp, p = 0;
    long data_size = bounds[3] - bounds[2];
    long unl_size  = bounds[3];
    long maxrec = opt_blksize + 20;
    int ndb = count_dir_blocks();
    int inmdir = ndb + 5 < 10 ? 10 : ndb + 5;

    if (maxrec > RECV_MAXREC) maxrec = RECV_MAXREC;

    rp = mvs_inmr_hdr(r, 1);
    mvs_tui(r, &rp, INM_LRECL, 80, 4);
    mvs_tus(r, &rp, INM_FNODE, "ORIGNODE");
    mvs_tus(r, &rp, INM_FUID,  opt_userid);
    mvs_tus(r, &rp, INM_TNODE, "ORIGNODE");
    mvs_tus(r, &rp, INM_TUID,  opt_userid);
    xmit_ftime(ft); mvs_tu(r, &rp, INM_FTIME, ft, 16);
    mvs_tui(r, &rp, INM_NUMF, 1, 1);
    mvs_netdata_seg(o, &p, r, rp, 1);

    /* INMR02 #1 -- IEBCOPY: the SOURCE library's attributes.  RECEIVE (and
     * RECV370 with a DCB-less SYSUT2) allocates the target dataset from these,
     * so unlike the load-library case they are computed, not echoed. */
    rp = mvs_inmr_hdr(r, 2);
    mvs_put24(r + rp, 0); r[rp + 3] = 1; rp += 4;        /* file number = 1 */
    mvs_tus(r, &rp, INM_UTILN, "IEBCOPY");
    mvs_tui(r, &rp, INM_SIZE, data_size, 4);
    mvs_tui(r, &rp, INM_DIR, inmdir, 3);
    mvs_tui(r, &rp, INM_LRECL, opt_lrecl, 4);
    mvs_tui(r, &rp, INM_DSORG, MVS_DSORG_PO, 2);
    mvs_tui(r, &rp, INM_BLKSZ, opt_blksize, 4);
    mvs_tui(r, &rp, INM_RECFM, opt_recfm << 8, 2);
    mvs_tu_dsname(r, &rp, opt_dsn);
    mvs_netdata_seg(o, &p, r, rp, 1);

    /* INMR02 #2 -- INMCOPY: the unloaded form itself (RECFM=VS) */
    rp = mvs_inmr_hdr(r, 2);
    mvs_put24(r + rp, 0); r[rp + 3] = 1; rp += 4;
    mvs_tus(r, &rp, INM_UTILN, "INMCOPY");
    mvs_tui(r, &rp, INM_SIZE, unl_size, 4);
    mvs_tui(r, &rp, INM_LRECL, opt_blksize + 20 - 4, 4);
    mvs_tui(r, &rp, INM_DSORG, MVS_DSORG_PS, 2);
    mvs_tui(r, &rp, INM_BLKSZ, opt_blksize + 20, 4);
    mvs_tui(r, &rp, INM_RECFM, MVS_RECFM_VS << 8, 2);
    mvs_netdata_seg(o, &p, r, rp, 1);

    rp = mvs_inmr_hdr(r, 3);
    mvs_tui(r, &rp, INM_SIZE, data_size, 4);
    mvs_tui(r, &rp, INM_LRECL, 80, 4);
    mvs_tui(r, &rp, INM_DSORG, MVS_DSORG_PS, 2);
    mvs_tui(r, &rp, INM_RECFM, 0x0001, 2);
    mvs_netdata_seg(o, &p, r, rp, 1);

    /* COPYR1 and COPYR2 are one logical record each */
    mvs_netdata_seg(o, &p, unl, bounds[0], 0);
    mvs_netdata_seg(o, &p, unl + bounds[0], bounds[1] - bounds[0], 0);

    /* Directory: one VS record per 256-byte block, the trailing EOD marker
     * riding with the last one.  A real TSO TRANSMIT bundles all directory
     * blocks into a single logical record instead (measured on the ctca_demo
     * oracle: 564 bytes = 2x276 + 12); ld370's per-block framing is the variant
     * that has been through RECV370, so it is what we emit.  See
     * docs/xmit-source-pds.md. */
    {
        long q = bounds[1];
        while (q < bounds[2]) {
            long reclen = 12 + unl[q + 9] + mvs_be16(unl + q + 10);
            long nq = q + reclen;
            if (nq < bounds[2]) {
                long nlen = 12 + unl[nq + 9] + mvs_be16(unl + nq + 10);
                if (nq + nlen >= bounds[2]) reclen += nlen;
            }
            mvs_netdata_seg(o, &p, unl + q, reclen, 0);
            q += reclen;
        }
    }

    /* Member data: whole CKD records packed into logical records, ALWAYS ending
     * at each member's DL=0 EOF.  IEBCOPY LOAD reads SYSUT1 one VS record at a
     * time and loses anything packed behind an EOF in the same record (IEB183I). */
    {
        long q = bounds[2];
        while (q < bounds[3]) {
            long cs = q, clen = 0;
            while (q < bounds[3]) {
                long dl = mvs_be16(unl + q + 10);
                long reclen = 12 + unl[q + 9] + dl;
                if (clen > 0 && clen + reclen > maxrec) break;
                clen += reclen; q += reclen;
                if (dl == 0) break;
                if (clen >= maxrec) break;
            }
            mvs_netdata_seg(o, &p, unl + cs, clen, 0);
        }
    }

    rp = mvs_inmr_hdr(r, 6);
    mvs_netdata_seg(o, &p, r, rp, 1);

    while (p % 80) o[p++] = 0;
    return p;
}

/* ---- create ---------------------------------------------------------------*/

static int excluded(const char *base)
{
    int i;
    for (i = 0; i < nexcl; i++)
        if (fnmatch(excl[i], base, 0) == 0) return 1;
    return 0;
}

static int scan_dir(const char *dir)
{
    DIR *d = opendir(dir);
    struct dirent *de;
    int errs = 0;
    if (!d) { fprintf(stderr, "xmit370: %s: cannot open directory\n", dir); return 1; }
    while ((de = readdir(d)) != NULL) {
        char path[4096];
        struct stat st;
        struct member *m;
        char name[9];
        if (de->d_name[0] == '.') continue;
        if (excluded(de->d_name)) continue;
        snprintf(path, sizeof path, "%s/%s", dir, de->d_name);
        if (stat(path, &st) != 0) { fprintf(stderr, "xmit370: %s: cannot stat\n", path); errs++; continue; }
        if (!S_ISREG(st.st_mode)) {
            if (S_ISDIR(st.st_mode))
                fprintf(stderr, "xmit370: %s: subdirectories are not members, skipped\n", path);
            continue;
        }
        member_from_path(name, path);
        if (!valid_member_name(name)) {
            fprintf(stderr, "xmit370: %s: '%s' is not a valid member name"
                    " (1-8 of A-Z 0-9 @ # $, first not a digit); use --member NAME=%s\n",
                    path, name, path);
            errs++; continue;
        }
        m = add_member();
        strcpy(m->name, name);
        mvs_name8(m->ebc, name);
        m->path = strdup(path);
        m->mtime = st.st_mtime;
    }
    closedir(d);
    return errs;
}

static int do_create(const char *dir)
{
    long usize, xcap, ulen, xlen;
    unsigned char *unl, *xm;
    long bounds[4];
    FILE *f;
    int i, errs = 0;

    if (!opt_out) die("create: -o OUT.xmit is required");
    if (!opt_dsn) die("create: --dsn NAME is required");
    if (opt_lrecl < 1 || opt_lrecl > 32760) die("--lrecl %ld out of range (1..32760)", opt_lrecl);
    if (opt_blksize < opt_lrecl || opt_blksize > 32760)
        die("--blocksize %ld out of range (%ld..32760)", opt_blksize, opt_lrecl);
    if (opt_blksize % opt_lrecl)
        die("--blocksize %ld is not a multiple of --lrecl %ld", opt_blksize, opt_lrecl);
    if (opt_blksize > MAX_BLK_3350)
        die("--blocksize %ld exceeds %d, the largest block that fits one track",
            opt_blksize, MAX_BLK_3350);

    if (!opt_userid[0]) {
        const char *u = getenv("USER");
        int n = 0;
        if (opt_dsn) { while (opt_dsn[n] && opt_dsn[n] != '.' && n < 8) n++; }
        if (n > 0) memcpy(opt_userid, opt_dsn, (size_t)n);
        else if (u) { n = (int)strlen(u); if (n > 8) n = 8; memcpy(opt_userid, u, (size_t)n); }
        opt_userid[n] = 0;
        for (i = 0; opt_userid[i]; i++) opt_userid[i] = (char)toupper((unsigned char)opt_userid[i]);
    }

    if (dir) errs += scan_dir(dir);
    for (i = 0; i < nmaps; i++) {
        struct stat st;
        struct member *m;
        size_t nl = strlen(maps[i].name);
        if (nl < 1 || nl > 8)
            die("--member: '%s' is %d characters, a member name is 1-8",
                maps[i].name, (int)nl);
        /* An explicit mapping is deliberate, so a name outside the standard set
         * is allowed with a warning rather than refused -- real libraries do
         * contain them (the ctca_demo oracle has PEERS_1), and this is the
         * escape hatch the directory scan points at. */
        if (!valid_member_name(maps[i].name))
            fprintf(stderr, "xmit370: warning: '%s' is not a standard member name"
                    " (A-Z 0-9 @ # $); ISPF and TSO may not handle it\n", maps[i].name);
        if (stat(maps[i].path, &st) != 0)
            { fprintf(stderr, "xmit370: %s: cannot stat\n", maps[i].path); errs++; continue; }
        m = add_member();
        strncpy(m->name, maps[i].name, 8); m->name[8] = 0;
        mvs_name8(m->ebc, m->name);
        m->path = strdup(maps[i].path);
        m->mtime = st.st_mtime;
    }
    if (errs) return 1;
    if (nmem == 0) die("no members found");

    qsort(mem, (size_t)nmem, sizeof *mem, cmp_member);
    for (i = 1; i < nmem; i++)
        if (memcmp(mem[i - 1].ebc, mem[i].ebc, 8) == 0)
            die("duplicate member name %s (%s and %s)", mem[i].name, mem[i - 1].path, mem[i].path);

    for (i = 0; i < nmem; i++) errs += text_to_records(&mem[i], mem[i].path);
    if (errs) { fprintf(stderr, "xmit370: %d error(s), no output written\n", errs); return 1; }

    assign_geometry();
    usize = unload_size();
    unl = malloc((size_t)usize + 64);
    if (!unl) die("out of memory");
    ulen = emit_unload(unl, bounds);
    if (ulen > usize) die("internal: unload overrun (%ld > %ld)", ulen, usize);

    xcap = usize + usize / 32 + 65536;
    xm = malloc((size_t)xcap);
    if (!xm) die("out of memory");
    xlen = emit_xmit(xm, unl, bounds);

    f = fopen(opt_out, "wb");
    if (!f) die("%s: cannot write", opt_out);
    if (fwrite(xm, 1, (size_t)xlen, f) != (size_t)xlen) die("%s: write failed", opt_out);
    fclose(f);

    if (verbose) {
        for (i = 0; i < nmem; i++)
            printf("%-8s %6ld lines %4d block(s) TTR=%04X%02X  %s\n",
                   mem[i].name, mem[i].nrec, mem[i].nblk,
                   mem[i].first_tt, mem[i].first_r, mem[i].path);
        printf("%s: %d member(s), %d directory block(s), RECFM=%s LRECL=%ld BLKSIZE=%ld, %ld bytes\n",
               opt_out, nmem, count_dir_blocks(),
               opt_recfm == MVS_RECFM_FB ? "FB" : "F", opt_lrecl, opt_blksize, xlen);
    }
    free(unl); free(xm);
    return 0;
}

/* ---- reading XMIT files ---------------------------------------------------*/

struct logrec { unsigned char *b; long len; int control; };

/* Reassemble the NETDATA segment stream into logical records. */
static struct logrec *read_xmit(const char *path, int *nrec_out, long *flen)
{
    unsigned char *d;
    long n, p = 0;
    struct logrec *recs = NULL;
    int nr = 0, cap = 0;
    unsigned char *cur = NULL;
    long curlen = 0;
    int curctl = 0;

    d = mvs_read_file(path, &n);
    if (!d) { fprintf(stderr, "xmit370: %s: cannot read\n", path); return NULL; }
    *flen = n;
    while (p + 2 <= n) {
        int len = d[p], flags = d[p + 1];
        long dl;
        if (len < 2) break;                    /* zero padding at end of file */
        dl = len - 2;
        if (p + len > n) break;
        if (flags & NETSEG_FIRST) { free(cur); cur = NULL; curlen = 0; curctl = flags & NETSEG_CTL; }
        cur = realloc(cur, (size_t)curlen + (size_t)dl + 1);
        if (!cur) die("out of memory");
        memcpy(cur + curlen, d + p + 2, (size_t)dl);
        curlen += dl;
        if (flags & NETSEG_LAST) {
            if (nr >= cap) { cap = cap ? cap * 2 : 32; recs = realloc(recs, (size_t)cap * sizeof *recs); if (!recs) die("out of memory"); }
            recs[nr].b = cur; recs[nr].len = curlen; recs[nr].control = curctl;
            nr++;
            cur = NULL; curlen = 0;
        }
        p += len;
    }
    free(cur);
    free(d);
    *nrec_out = nr;
    return recs;
}

static const char *recfm_str(int rf)
{
    static char b[8];
    int i = 0;
    if ((rf & 0xc0) == 0xc0) b[i++] = 'U';
    else if (rf & 0x80) b[i++] = 'F';
    else if (rf & 0x40) b[i++] = 'V';
    else b[i++] = '?';
    if (rf & 0x10) b[i++] = 'B';
    if (rf & 0x08) b[i++] = 'S';
    if (rf & 0x04) b[i++] = 'A';
    if (rf & 0x02) b[i++] = 'M';
    b[i] = 0;
    return b;
}

static const char *tu_name(int key)
{
    switch (key) {
    case INM_DSNAM: return "INMDSNAM"; case INM_DIR:   return "INMDIR";
    case INM_BLKSZ: return "INMBLKSZ"; case INM_DSORG: return "INMDSORG";
    case INM_LRECL: return "INMLRECL"; case INM_RECFM: return "INMRECFM";
    case INM_TNODE: return "INMTNODE"; case INM_TUID:  return "INMTUID";
    case INM_FNODE: return "INMFNODE"; case INM_FUID:  return "INMFUID";
    case INM_FTIME: return "INMFTIME"; case INM_UTILN: return "INMUTILN";
    case INM_SIZE:  return "INMSIZE";  case INM_NUMF:  return "INMNUMF";
    default: return NULL;
    }
}
static int tu_is_text(int key)
{
    return key == INM_DSNAM || key == INM_UTILN || key == INM_TNODE ||
           key == INM_TUID  || key == INM_FNODE || key == INM_FUID || key == INM_FTIME;
}

/* Decode the text units of one INMRxx control record. */
static void show_textunits(const struct logrec *r)
{
    long p = 6;
    if (r->len >= 6 && r->b[5] == 0xf2) p = 10;    /* INMR02 has a 4-byte file number */
    while (p + 6 <= r->len) {
        int key = mvs_be16(r->b + p), cnt = mvs_be16(r->b + p + 2);
        const char *label = tu_name(key);
        long q = p + 4;
        int k;
        for (k = 0; k < cnt && q + 2 <= r->len; k++) {
            int len = mvs_be16(r->b + q);
            const unsigned char *v = r->b + q + 2;
            if (q + 2 + len > r->len) return;
            if (label && tu_is_text(key)) {
                int i;
                if (k == 0) printf("      %-10s ", label);
                else putchar('.');                      /* dsname qualifier separator */
                for (i = 0; i < len; i++) putchar(mvs_e2a(v[i]));
                if (k == cnt - 1) putchar('\n');
            } else if (label) {
                long val = mvs_rdval(v, len);
                if (key == INM_DSORG)
                    printf("      %-10s %s\n", label, val == MVS_DSORG_PO ? "PO" :
                           val == MVS_DSORG_PS ? "PS" : "?");
                else if (key == INM_RECFM)
                    printf("      %-10s %s\n", label, recfm_str((int)(val >> 8)));
                else
                    printf("      %-10s %ld\n", label, val);
            }
            q += 2 + len;
        }
        p = q;
    }
}

/* ---- the unloaded payload -------------------------------------------------*/

struct dirent370 {
    unsigned char name[8];
    int tt, r;
    int cbyte;
    unsigned char ud[64];
    int udlen;
};

/* The payload's data logical records concatenated back into the unload image. */
static unsigned char *payload(struct logrec *recs, int nrec, long *plen)
{
    unsigned char *b = NULL;
    long n = 0;
    int i;
    for (i = 0; i < nrec; i++) {
        if (recs[i].control) continue;
        b = realloc(b, (size_t)n + (size_t)recs[i].len);
        if (!b) die("out of memory");
        memcpy(b + n, recs[i].b, (size_t)recs[i].len);
        n += recs[i].len;
    }
    *plen = n;
    return b;
}

/* COPYR1's length is the length of its logical record -- it is 52 bytes on MVS
 * 3.8j but 56 in some real transmissions, so it must never be assumed. */
static long copyr1_len(struct logrec *recs, int nrec)
{
    int i;
    for (i = 0; i < nrec; i++)
        if (!recs[i].control && recs[i].len >= 4 && recs[i].b[1] == 0xca &&
            recs[i].b[2] == 0x6d && recs[i].b[3] == 0x0f)
            return recs[i].len;
    return COPYR1_LEN;
}

/* The environment header is COPYR1 + COPYR2, each its own logical record, so
 * its length follows from the stream rather than from a fixed 328. */
static long env_hdr_len(struct logrec *recs, int nrec, long c1len)
{
    int i;
    for (i = 0; i < nrec; i++)
        if (!recs[i].control && recs[i].len == c1len && recs[i].b[1] == 0xca &&
            recs[i].b[2] == 0x6d && recs[i].b[3] == 0x0f)
            return c1len + (i + 1 < nrec && !recs[i + 1].control ? recs[i + 1].len : 0);
    return c1len;
}

static void decode_stats(const unsigned char *ud, int udlen)
{
    int i;
    if (udlen < 30) return;
    printf(" v%d.%d", ud[0], ud[1]);
    printf(" %d%02x/%x%02x", ud[4] ? 20 : 19, ud[5], ud[6] >> 4, ((ud[6] & 0xf) << 4) | (ud[7] >> 4));
    printf(" %02x:%02x", ud[12], ud[13]);
    printf(" %d lines", mvs_be16(ud + 14));
    printf(" ");
    for (i = 0; i < 8; i++) {
        unsigned char a = mvs_e2a(ud[20 + i]);
        if (a != ' ') putchar(a);
    }
}

/* Walk the directory blocks of an unloaded image. */
static int read_directory(const unsigned char *u, long ulen, long hdrlen,
                          struct dirent370 **out, long *data_off)
{
    struct dirent370 *e = NULL;
    int n = 0, cap = 0;
    long p = hdrlen;
    while (p + 12 <= ulen) {
        int kl = u[p + 9];
        long dl = mvs_be16(u + p + 10);
        long q;
        if (kl != 8 || dl != DIR_BLK) break;          /* first non-directory record */
        q = p + 12 + 8;
        if (q + DIR_BLK > ulen) break;
        {
            int used = mvs_be16(u + q);
            int o = 2;
            while (o + 12 <= used) {
                const unsigned char *ent = u + q + o;
                int c, hw;
                if (memcmp(ent, "\xff\xff\xff\xff\xff\xff\xff\xff", 8) == 0) break;
                c = ent[11];
                hw = c & 0x1f;
                if (n >= cap) { cap = cap ? cap * 2 : 32; e = realloc(e, (size_t)cap * sizeof *e); if (!e) die("out of memory"); }
                memcpy(e[n].name, ent, 8);
                e[n].tt = mvs_be16(ent + 8);
                e[n].r  = ent[10];
                e[n].cbyte = c;
                e[n].udlen = hw * 2 > 64 ? 64 : hw * 2;
                memcpy(e[n].ud, ent + 12, (size_t)e[n].udlen);
                n++;
                o += 12 + hw * 2;
            }
        }
        p = q + DIR_BLK;
    }
    while (p + 12 <= ulen && u[p + 9] == 0 && mvs_be16(u + p + 10) == 0 &&
           mvs_be16(u + p + 4) == 0 && mvs_be16(u + p + 6) == 0 && u[p + 8] == 0)
        p += 12;                                       /* end-of-directory marker */
    *out = e;
    *data_off = p;
    return n;
}

/* Geometry of the unloaded image, read from its own header rather than assumed.
 * The directory stores RELATIVE track numbers; the data records carry absolute
 * MBBCCHHR within the source DEB extent, so converting between them needs that
 * extent's origin and the device's tracks-per-cylinder.  Both are in the header
 * (DEB extent at COPYR2 offsets 74/76, XC1UHEAD at COPYR1 offset 26) -- taking
 * them from there is what makes this work on a foreign 3380 transmission as
 * well as on our own 3350-shaped one. */
struct geom { int start_cc, start_hh, trkpercyl; };

static struct geom read_geom(const unsigned char *u)
{
    struct geom g;
    g.trkpercyl = mvs_be16(u + 26);
    g.start_cc  = mvs_be16(u + 74);
    g.start_hh  = mvs_be16(u + 76);
    if (g.trkpercyl < 1) g.trkpercyl = UNLOAD_TRKPERCYL;
    return g;
}

/* relative track of a data record's absolute address */
static long rel_track(const struct geom *g, long cc, long hh)
{
    return (cc - g->start_cc) * g->trkpercyl + (hh - g->start_hh);
}

/* Collect one member's bytes by following its directory TTR through the data
 * records, as IEBCOPY's fake DEB does: start at the first record whose relative
 * (track, record) reaches the TTR, stop at the first DL=0 (end of member). */
static unsigned char *member_bytes(const unsigned char *u, long ulen, long data_off,
                                   const struct geom *g, int tt, int r, long *mlen)
{
    long p = data_off;
    long want = ((long)tt << 8) | (long)r;
    unsigned char *b = NULL;
    long n = 0;
    int started = 0;
    while (p + 12 <= ulen) {
        long cc = mvs_be16(u + p + 4), hh = mvs_be16(u + p + 6), rr = u[p + 8];
        long here = (rel_track(g, cc, hh) << 8) | rr;
        long dl = mvs_be16(u + p + 10);
        long reclen = 12 + u[p + 9] + dl;
        if (!started && here >= want) started = 1;
        if (started) {
            if (dl == 0) break;
            b = realloc(b, (size_t)n + (size_t)dl);
            if (!b) die("out of memory");
            memcpy(b + n, u + p + 12 + u[p + 9], (size_t)dl);
            n += dl;
        }
        p += reclen;
    }
    *mlen = n;
    return b;
}

static int do_list(const char *path)
{
    struct logrec *recs;
    int nrec, i, nent;
    long flen, plen, hdrlen, c1len, data_off;
    unsigned char *u;
    struct dirent370 *ents;
    struct geom g;

    recs = read_xmit(path, &nrec, &flen);
    if (!recs) return 1;
    if (flen % 80) fprintf(stderr, "xmit370: %s: warning: not a multiple of 80 bytes\n", path);

    for (i = 0; i < nrec; i++) {
        int k;
        if (!recs[i].control || recs[i].len < 6) continue;
        printf("  ");
        for (k = 0; k < 6; k++) putchar(mvs_e2a(recs[i].b[k]));
        putchar('\n');
        show_textunits(&recs[i]);
    }

    u = payload(recs, nrec, &plen);
    if (!u) { free(recs); return 1; }
    c1len = copyr1_len(recs, nrec);
    hdrlen = env_hdr_len(recs, nrec, c1len);
    printf("  environment header %ld bytes (COPYR1 %ld + COPYR2)\n", hdrlen, c1len);
    if (plen >= 16) {
        printf("  source DCB: DSORG=%s RECFM=%s LRECL=%d BLKSIZE=%d (unloaded %d)\n",
               mvs_be16(u + XC1DSORG) == MVS_DSORG_PO ? "PO" : "PS",
               recfm_str(u[XC1RECFM]), mvs_be16(u + XC1LRECL),
               mvs_be16(u + XC1BLKSZ), mvs_be16(u + XC1TBLKS));
    }

    g = read_geom(u);
    nent = read_directory(u, plen, hdrlen, &ents, &data_off);
    printf("  %d member(s):\n", nent);
    for (i = 0; i < nent; i++) {
        long mlen;
        unsigned char *b = member_bytes(u, plen, data_off, &g, ents[i].tt, ents[i].r, &mlen);
        printf("    %-8s TTR=%04X%02X %7ld bytes", mvs_nm(ents[i].name),
               ents[i].tt, ents[i].r, mlen);
        if (verbose) printf(" C=%02X ud=%d", ents[i].cbyte, ents[i].udlen);
        if (ents[i].udlen >= 30) decode_stats(ents[i].ud, ents[i].udlen);
        putchar('\n');
        free(b);
    }
    free(ents); free(u);
    for (i = 0; i < nrec; i++) free(recs[i].b);
    free(recs);
    return 0;
}

static int do_extract(const char *path)
{
    struct logrec *recs;
    int nrec, i, nent, rc = 0;
    long flen, plen, hdrlen, data_off;
    unsigned char *u;
    struct dirent370 *ents;
    struct geom g;
    int recfm;
    long lrecl;

    recs = read_xmit(path, &nrec, &flen);
    if (!recs) return 1;
    u = payload(recs, nrec, &plen);
    if (!u) { free(recs); return 1; }

    hdrlen = env_hdr_len(recs, nrec, copyr1_len(recs, nrec));
    if (plen < 16) { fprintf(stderr, "xmit370: %s: not an IEBCOPY unload payload\n", path); rc = 1; goto out; }
    recfm = u[XC1RECFM];
    lrecl = mvs_be16(u + XC1LRECL);

    g = read_geom(u);
    nent = read_directory(u, plen, hdrlen, &ents, &data_off);
    for (i = 0; i < nent; i++) {
        long mlen;
        unsigned char *b = member_bytes(u, plen, data_off, &g, ents[i].tt, ents[i].r, &mlen);
        char out[4096];
        FILE *f;
        snprintf(out, sizeof out, "%s/%s", opt_outdir, mvs_nm(ents[i].name));
        f = fopen(out, "wb");
        if (!f) { fprintf(stderr, "xmit370: %s: cannot write\n", out); rc = 1; free(b); continue; }
        if ((recfm & 0x80) && lrecl > 0) {
            long o;
            for (o = 0; o + lrecl <= mlen; o += lrecl) {
                long k = lrecl, x;
                while (k > 0 && b[o + k - 1] == 0x40) k--;      /* strip pad blanks */
                for (x = 0; x < k; x++) fputc(mvs_e2a(b[o + x]), f);
                fputc('\n', f);
            }
        } else {
            /* RECFM=U (or anything not fixed-length text): raw bytes.  This is
             * for inspection and archiving -- it is NOT a form ld370 --pack can
             * re-ingest, which needs the directory's entry point and attributes. */
            if (mlen) fwrite(b, 1, (size_t)mlen, f);
        }
        fclose(f);
        if (verbose) printf("%s (%ld bytes)\n", out, mlen);
        free(b);
    }
    free(ents);
out:
    free(u);
    for (i = 0; i < nrec; i++) free(recs[i].b);
    free(recs);
    return rc;
}

/* ---- CLI ------------------------------------------------------------------*/

static void usage(FILE *f)
{
    fputs(
"usage: xmit370 create -o OUT.xmit --dsn NAME [options] DIR\n"
"       xmit370 list    [-v] FILE.xmit\n"
"       xmit370 extract [-C DIR] [-v] FILE.xmit\n"
"\n"
"create options:\n"
"  --dsn NAME          target dataset name (required)\n"
"  -o FILE             output file (required)\n"
"  --lrecl N           logical record length (default 80)\n"
"  --blocksize N       block size, multiple of --lrecl (default 3120)\n"
"  --recfm fb|f        record format (default fb)\n"
"  --stats/--no-stats  ISPF statistics in the directory (default on)\n"
"  --userid NAME       userid recorded in the statistics\n"
"  --stats-date D      fix all statistics to D (YYYY-MM-DD[THH:MM:SS])\n"
"  --member NAME=FILE  add FILE as member NAME (repeatable)\n"
"  --exclude GLOB      skip matching files (repeatable)\n"
"  --tabs N            expand tabs to N columns (default 8; 0 rejects tabs)\n"
"  --latin1            map bytes >= 0x80 through CP037 instead of refusing them\n"
"  -v                  list members as they are packed\n", f);
}

static int parse_date(const char *s)
{
    int y, mo, d, h = 0, mi = 0, se = 0;
    int n = sscanf(s, "%d-%d-%d%*[T ]%d:%d:%d", &y, &mo, &d, &h, &mi, &se);
    struct tm t;
    time_t tv;
    if (n < 3) return 0;
    memset(&t, 0, sizeof t);
    t.tm_year = y - 1900; t.tm_mon = mo - 1; t.tm_mday = d;
    t.tm_hour = h; t.tm_min = mi; t.tm_sec = se;
    t.tm_isdst = -1;
    tv = mktime(&t);
    if (tv == (time_t)-1) return 0;
    stats_tm = *localtime(&tv);          /* normalises tm_yday */
    have_stats_date = 1;
    return 1;
}

int main(int argc, char **argv)
{
    const char *cmd, *arg = NULL;
    int i;

    if (argc < 2) { usage(stderr); return 2; }
    cmd = argv[1];
    if (!strcmp(cmd, "--help") || !strcmp(cmd, "-h")) { usage(stdout); return 0; }
    if (!strcmp(cmd, "--version") || !strcmp(cmd, "-V")) { puts(VERSION_STR); return 0; }

    excl = malloc((size_t)argc * sizeof *excl);
    maps = malloc((size_t)argc * sizeof *maps);
    if (!excl || !maps) die("out of memory");

    for (i = 2; i < argc; i++) {
        const char *a = argv[i];
        if (!strcmp(a, "-o") && i + 1 < argc) opt_out = argv[++i];
        else if (!strcmp(a, "--dsn") && i + 1 < argc) opt_dsn = argv[++i];
        else if (!strcmp(a, "-C") && i + 1 < argc) opt_outdir = argv[++i];
        else if (!strcmp(a, "--lrecl") && i + 1 < argc) opt_lrecl = strtol(argv[++i], NULL, 10);
        else if (!strcmp(a, "--blocksize") && i + 1 < argc) opt_blksize = strtol(argv[++i], NULL, 10);
        else if (!strcmp(a, "--tabs") && i + 1 < argc) opt_tabs = (int)strtol(argv[++i], NULL, 10);
        else if (!strcmp(a, "--no-tabs")) opt_tabs = 0;
        else if (!strcmp(a, "--latin1")) opt_latin1 = 1;
        else if (!strcmp(a, "--stats")) opt_stats = 1;
        else if (!strcmp(a, "--no-stats")) opt_stats = 0;
        else if (!strcmp(a, "--userid") && i + 1 < argc) {
            strncpy(opt_userid, argv[++i], 8); opt_userid[8] = 0;
        } else if (!strcmp(a, "--stats-date") && i + 1 < argc) {
            if (!parse_date(argv[++i])) die("--stats-date: cannot parse '%s'", argv[i]);
        } else if (!strcmp(a, "--recfm") && i + 1 < argc) {
            const char *v = argv[++i];
            if (!strcasecmp(v, "fb")) opt_recfm = MVS_RECFM_FB;
            else if (!strcasecmp(v, "f")) opt_recfm = MVS_RECFM_F;
            else die("--recfm: only 'f' and 'fb' are supported");
        } else if (!strcmp(a, "--member") && i + 1 < argc) {
            char *s = argv[++i], *eq = strchr(s, '=');
            if (!eq) die("--member: expected NAME=FILE, got '%s'", s);
            *eq = 0;
            maps[nmaps].name = s; maps[nmaps].path = eq + 1; nmaps++;
        } else if (!strcmp(a, "--exclude") && i + 1 < argc) {
            excl[nexcl++] = argv[++i];
        } else if (!strcmp(a, "-v") || !strcmp(a, "--verbose")) verbose = 1;
        else if (!strcmp(a, "--help") || !strcmp(a, "-h")) { usage(stdout); return 0; }
        else if (a[0] == '-') { fprintf(stderr, "xmit370: unknown option '%s'\n", a); usage(stderr); return 2; }
        else if (!arg) arg = a;
        else die("unexpected argument '%s'", a);
    }

    if (!strcmp(cmd, "create"))  return do_create(arg);
    if (!strcmp(cmd, "list"))    { if (!arg) die("list: need a file"); return do_list(arg); }
    if (!strcmp(cmd, "extract")) { if (!arg) die("extract: need a file"); return do_extract(arg); }
    fprintf(stderr, "xmit370: unknown command '%s'\n", cmd);
    usage(stderr);
    return 2;
}
