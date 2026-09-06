/*
 * file370 -- identify and analyze the MVS object/load formats produced by the
 * host-native cc370 toolchain.  The read-only `file`/objdump-style counterpart
 * to as370 (assembler), ld370 (linker) and ar370 (archiver): it sniffs a file's
 * format from its leading bytes and prints either a one-line summary (default,
 * like `file`) or a full structural dump (-v).
 *
 * Recognized formats and their magic:
 *   OBJ deck          (as370)          byte0 X'02' + EBCDIC ESD/TXT/RLD/END/SYM
 *   ar370 archive     (ar370)          "!<arch>\n"
 *   MVS load module   (ld370 -o)       first record is a CESD (byte0 X'20'/X'28')
 *   IEBCOPY unload    (ld370 -iebcopy) COPYR1 eye-catcher X'00 CA 6D 0F'
 *   TSO XMIT/NETDATA  (ld370 -xmit)    EBCDIC "INMR01" at offset 2
 *
 * The XMIT wraps an IEBCOPY unload which wraps a load-module member; -v peels
 * the onion, decoding each layer in place.  Pure host tool -- no MVS contact.
 *
 * Build: gcc -O2 -Wall -Wextra -Werror -o file370/file370 file370/src/file370.c
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "mvs370.h"
#include "obj370.h"

#define VERSION_STR "file370 V1.0"

/* EBCDIC and big-endian primitives come from common/mvs370.  Everything that
 * gets PRINTED goes through mvs_e2a_pr(): the full CP037 inverse with '?' for
 * anything not printable ASCII. */

/* decode a run of EBCDIC bytes into ASCII (into a caller buffer) */
static void e2a_n(char *dst, const unsigned char *src, int n)
{
    int i;
    for (i = 0; i < n; i++) dst[i] = mvs_e2a_pr(src[i]);
    dst[n] = 0;
}

/* ESD tallies for the one-line summary, filled through obj_esd_walk. */
struct esd_sum { int nsd, nld, ner, ncm; char first[16]; };

static int sum_esd(const struct obj_esd *e, void *ctx)
{
    struct esd_sum *s = ctx;
    if (obj_is_section(e->type)) {
        if (e->type == OBJ_CM) s->ncm++; else s->nsd++;
        if (!s->first[0]) {
            const char *nm = mvs_nm(e->name);
            strcpy(s->first, nm[0] ? nm : "(private)");
        }
    } else if (e->type == OBJ_LD) s->nld++;
    else if (e->type == OBJ_ER || e->type == OBJ_WX) s->ner++;
    return 1;
}

/* ---- format detection ---- */
enum fmt { F_UNKNOWN, F_OBJ, F_AR, F_LMOD, F_IEBCOPY, F_XMIT };

/* an OBJ card's bytes 1-3 are one of the EBCDIC card types */
static enum fmt detect(const unsigned char *b, long n)
{
    if (n >= 8 && memcmp(b, "!<arch>\n", 8) == 0) return F_AR;
    if (n >= 4 && b[0] == 0x00 && b[1] == 0xCA && b[2] == 0x6D && b[3] == 0x0F)
        return F_IEBCOPY;                                         /* COPYR1 eye-catcher */
    if (n >= 8 && b[2] == 0xC9 && b[3] == 0xD5 && b[4] == 0xD4 &&
        b[5] == 0xD9 && b[6] == 0xF0 && b[7] == 0xF1)
        return F_XMIT;                                            /* "INMR01" at offset 2 */
    if (n >= 4 && obj_card_type(b) != OBJ_OTHER) return F_OBJ;
    if (n >= 1 && (b[0] == 0x20 || b[0] == 0x28)) return F_LMOD;  /* first record = CESD */
    return F_UNKNOWN;
}

/* ESD type byte (low nibble) -> name */
static const char *esd_type(int t)
{
    switch (t) {
        case 0x00: return "SD";    /* section definition          */
        case 0x01: return "LD";    /* label (entry) definition     */
        case 0x02: return "ER";    /* external reference           */
        case 0x04: return "PC";    /* private code (blank section) */
        case 0x05: return "CM";    /* common                       */
        case 0x0A: return "WX";    /* weak external reference      */
        default:   return "??";
    }
}

/* ====================================================================== */
/* OBJ deck                                                               */
/* ====================================================================== */
static void show_obj(const char *path, const unsigned char *b, long n, int v)
{
    struct esd_sum sm;
    long off, textbytes = 0;
    int nsd = 0, nld = 0, ner = 0, ncm = 0, nrld = 0, has_entry = 0;
    long entry_off = 0;
    char first_sect[16] = "";

    memset(&sm, 0, sizeof sm);
    /* one pass to summarize */
    for (off = 0; off + OBJ_CARD_LEN <= n; off += OBJ_CARD_LEN) {
        const unsigned char *c = b + off;
        switch (obj_card_type(c)) {
        case OBJ_ESD: obj_esd_walk(c, sum_esd, &sm); break;
        case OBJ_TXT: { struct obj_txt t; if (obj_txt_get(c, &t)) textbytes += t.len; break; }
        case OBJ_RLD: nrld++; break;
        case OBJ_END: { struct obj_end e;
                        if (obj_end_get(c, &e) && e.has_entry) {
                            has_entry = 1; entry_off = e.entry_addr;
                        }
                        break; }
        default: break;
        }
    }
    nsd = sm.nsd; nld = sm.nld; ner = sm.ner; ncm = sm.ncm;
    if (sm.first[0]) strcpy(first_sect, sm.first);

    printf("%s: OS/360 object deck -- %d section(s)", path, nsd + ncm);
    if (first_sect[0]) printf(" (first %s)", first_sect);
    if (ner) printf(", %d extern ref(s)", ner);
    printf(", %ldB text", textbytes);
    if (nrld) printf(", %d RLD card(s)", nrld);
    if (n % 80) printf(", WARNING: not a multiple of 80");
    printf("\n");
    if (!v) return;

    printf("    %ld card(s) of 80 bytes; %d LD entr(y/ies)\n", n / 80, nld);
    /* second pass: dump every ESD entry */
    for (off = 0; off + 80 <= n; off += 80) {
        const unsigned char *c = b + off;
        if (c[0] != 0x02 || !(c[1] == 0xC5 && c[2] == 0xE2 && c[3] == 0xC4)) continue;
        {
            int cnt = mvs_be16(c + 10), first = mvs_be16(c + 14), k, nid = 0;
            for (k = 0; k < cnt / 16; k++) {
                const unsigned char *e = c + 16 + (long)k * 16;
                int ty = e[8] & 0x0f;
                if (ty == 0x01) {                                     /* LD: no ESDID */
                    printf("    ESD  --   %-8s  LD  addr=%06lX\n", mvs_nm(e), mvs_be24(e + 9));
                    continue;
                }
                if (ty == 0x02 || ty == 0x0A)                         /* ER/WX: no addr/len */
                    printf("    ESD  %3d  %-8s  %s\n",
                           first + nid, mvs_nm(e)[0] ? mvs_nm(e) : "(blank)", esd_type(ty));
                else                                                  /* SD/PC/CM section */
                    printf("    ESD  %3d  %-8s  %s  addr=%06lX  len=%06lX\n",
                           first + nid, mvs_nm(e)[0] ? mvs_nm(e) : "(blank)", esd_type(ty),
                           mvs_be24(e + 9), mvs_be24(e + 13));
                nid++;
            }
        }
    }
    if (has_entry) printf("    END  entry at offset %06lX\n", entry_off);
    else           printf("    END  no entry point (defaults to section origin)\n");
}

/* ====================================================================== */
/* ar370 archive                                                          */
/* ====================================================================== */
static void show_ar(const char *path, const unsigned char *b, long n, int v)
{
    long p = 8, nmem = 0, nsym = 0;
    const unsigned char *symtab = NULL; long symsize = 0;

    /* first pass: count members + locate the "/" symbol table */
    while (p + 60 <= n) {
        char name[17]; long size;
        memcpy(name, b + p, 16); name[16] = 0;
        size = atol((const char *)b + p + 48);
        if (name[0] == '/' && (name[1] == ' ' || name[1] == 0)) {     /* "/" symtab */
            symtab = b + p + 60; symsize = size;
            if (size >= 4) nsym = (long)mvs_be32(b + p + 60);
        } else if (name[0] == '/' && name[1] == '/') {                /* "//" longnames */
            /* GNU long-name table -- not counted as an object member */
        } else {
            nmem++;
        }
        p += 60 + size + (size & 1);
    }

    printf("%s: ar370 archive -- %ld object member(s), %ld symbol(s)\n",
           path, nmem, nsym);
    if (!v) return;

    /* member list */
    p = 8;
    while (p + 60 <= n) {
        char name[17]; long size; int i;
        memcpy(name, b + p, 16); name[16] = 0;
        for (i = 15; i >= 0 && (name[i] == ' ' || name[i] == '/'); i--) name[i] = 0;
        size = atol((const char *)b + p + 48);
        if (name[0]) printf("    member  %-16s  %ld bytes\n", name, size);
        p += 60 + size + (size & 1);
    }
    /* symbol names: count(4) + count*offset(4) + NUL-terminated names */
    if (symtab && nsym > 0) {
        long base = 4 + nsym * 4, q = base; long s = 0;
        printf("    symbol table (%ld):\n", nsym);
        while (q < symsize && s < nsym) {
            const char *name = (const char *)symtab + q;
            printf("      %s\n", name);
            q += (long)strlen(name) + 1; s++;
        }
    }
}

/* ====================================================================== */
/* MVS load module member                                                 */
/* ====================================================================== */
/* walk the byte-0 record stream; counts by type, notes the trailing MODEND */
static void show_lmod(const char *path, const unsigned char *b, long n, int v)
{
    int ncesd = 0, nidr = 0, nctl = 0, ntext = 0, nrld = 0, last_modend = 0, bad = 0;

    if (v) printf("%s:\n", path);          /* header printed after the summary below */

    {
        struct lmod_iter it;
        struct lmod_item r;
        int rc;
        lmod_iter_init(&it, b, n);
        while ((rc = lmod_iter_next(&it, &r)) == 1) {
            const char *kind;
            switch (r.kind) {
            case LMOD_CESD: kind = "CESD";    ncesd++; break;
            case LMOD_IDR:  kind = "IDR";     nidr++;  break;
            case LMOD_TEXT: kind = "text";    ntext++; break;
            default:        kind = "control"; nctl++;
                            if (r.flags & LMOD_CTL_RLD) nrld++;
                            if (r.flags & LMOD_CTL_END) last_modend = 1;
                            break;
            }
            if (v) printf("    @%06lX  %-8s  %ld bytes%s\n", r.off, kind, r.len,
                          (r.kind == LMOD_CTL && (r.flags & LMOD_CTL_END))
                              ? "  (MODEND)" : "");
        }
        if (rc < 0) bad = 1;
    }

    /* the summary line goes first when not verbose; when verbose it was preceded
     * by the record dump, so print it as a trailing total either way. */
    if (!v) printf("%s: ", path);
    else    printf("  ");
    printf("MVS load module member -- %d CESD, %d IDR, %d text record(s), "
           "%d control, %d w/RLD%s, %ld bytes%s\n",
           ncesd, nidr, ntext, nctl, nrld, last_modend ? ", MODEND" : "", n,
           bad ? " (TRUNCATED/unrecognized record)" : "");
}

/* ====================================================================== */
/* PDS directory block decode (shared by IEBCOPY unload + the XMIT peel)   */
/* ====================================================================== */
/* Decode the load-module attributes in a member's PDS2 user data (IHAPDS
 * PDS2ATR1 at ud[8], PDS2ATR2 at ud[9], the APF AC at ud[22] valid when
 * PDSAPFLG ud[18] bit4 is set) into a readable flag list, e.g.
 * "RENT REUS EXEC 1BLK NRLD AC=1".  out is left empty if nothing is set. */
static void pds2_attrs(const unsigned char *ud, int nud, char *out, size_t cap)
{
    static const struct { int idx; unsigned char bit; const char *name; } F[] = {
        { 8, 0x80, "RENT" }, { 8, 0x40, "REUS" }, { 8, 0x20, "OVLY" },
        { 8, 0x10, "TEST" }, { 8, 0x08, "OL"   }, { 8, 0x04, "SCTR" },
        { 8, 0x02, "EXEC" }, { 8, 0x01, "1BLK" }, { 9, 0x10, "NRLD" },
        { 9, 0x01, "REFR" },
    };
    size_t n = 0; unsigned i; int r;
    if (cap) out[0] = 0;
    for (i = 0; i < sizeof F / sizeof F[0]; i++) {
        if (!(ud[F[i].idx] & F[i].bit)) continue;
        r = snprintf(out + n, cap - n, "%s%s", n ? " " : "", F[i].name);
        if (r > 0 && (size_t)r < cap - n) n += (size_t)r;
    }
    if (nud >= 24 && (ud[18] & 0x08)) {                 /* PDSAPFLG -> the AC is meaningful */
        r = snprintf(out + n, cap - n, "%sAC=%d", n ? " " : "", ud[22]);
        if (r > 0 && (size_t)r < cap - n) n += (size_t)r;
    }
}

/* parse one 256-byte PDS dir block at blk[0..]; print each member entry.
 * Returns the number of member entries found.  `indent` prefixes each line. */
static int show_dir_block(const unsigned char *blk, const char *indent, int v)
{
    int used = mvs_be16(blk), p = 2, members = 0;
    if (used < 2 || used > 256) used = 256;
    while (p + 12 <= used) {
        const unsigned char *e = blk + p;
        const unsigned char *ud;
        int c, alias, nud;
        if (memcmp(e, "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF", 8) == 0) break;  /* end marker */
        c = e[11];
        alias = (c & 0x80) >> 7;
        nud = (c & 0x1f) * 2;                       /* user data length in bytes */
        ud = e + 12;
        members++;
        printf("%smember %-8s%s  ttr=%06lX", indent, mvs_nm(e),
               alias ? " (alias)" : "", mvs_be24(e + 8));
        if (nud >= 18) {                            /* load-module PDS2 user data */
            long modlen = mvs_be24(ud + 10), entry = mvs_be24(ud + 15);
            char attrs[96];
            pds2_attrs(ud, nud, attrs, sizeof attrs);
            printf("  entry=%06lX  modlen=%ld", entry, modlen);
            if (attrs[0]) printf("  [%s]", attrs);
            if (v) {
                printf("\n%s         ATR1=%02X ATR2=%02X  AC=%02X  PDS2TTRT=%06lX",
                       indent, ud[8], ud[9], (nud >= 24) ? ud[22] : 0, mvs_be24(ud));
            }
        }
        printf("\n");
        p += 12 + nud;
    }
    return members;
}

/* ====================================================================== */
/* IEBCOPY unloaded PDS                                                    */
/* ====================================================================== */
/* env header is 328 bytes; the directory CKD record (count12 + key8 + data256)
 * begins right after, so the 256-byte dir block sits at offset 328+12+8 = 348. */
#define UNLOAD_ENVHDR  328
#define UNLOAD_DIRBLK  (UNLOAD_ENVHDR + 12 + 8)

static void show_iebcopy(const char *path, const unsigned char *b, long n, int v)
{
    int members = 0;

    printf("%s: IEBCOPY unloaded PDS (RECFM=U source)", path);
    if (!v) {
        /* one-liner: name the member(s) inline, across all directory blocks */
        long dp = UNLOAD_ENVHDR; int first = 1;
        printf(" --");
        while (dp + 12 + 8 + 256 <= n && b[dp + 9] == 8 && mvs_be16(b + dp + 10) == 256) {
            const unsigned char *blk = b + dp + 20;
            int used = mvs_be16(blk), p = 2;
            if (used < 2 || used > 256) used = 256;
            while (p + 12 <= used) {
                const unsigned char *e = blk + p; int c, nud;
                if (memcmp(e, "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF", 8) == 0) break;
                c = e[11]; nud = (c & 0x1f) * 2;
                printf("%s member %s", first ? "" : ",", mvs_nm(e));
                first = 0; members++;
                p += 12 + nud;
            }
            dp += 12 + 8 + 256;
        }
        if (!members) printf(" (no member entries found)");
        printf("\n");
        return;
    }

    printf("\n");
    printf("    env header %d bytes (COPYR1 X'CA6D0F' + COPYR2)\n", UNLOAD_ENVHDR);
    {
        /* the directory is one or more count12(KL=8,DL=256)+key(8)+256B block
         * records (>6 members spill into further blocks), ending at the EOD
         * marker; walk them all. */
        long dp = UNLOAD_ENVHDR; int nblk = 0;
        while (dp + 12 + 8 + 256 <= n && b[dp + 9] == 8 && mvs_be16(b + dp + 10) == 256) {
            members += show_dir_block(b + dp + 20, "    ", v);
            dp += 12 + 8 + 256; nblk++;
        }
        if (!nblk) printf("    (truncated: directory block beyond end of file)\n");
        else if (nblk > 1) printf("    %d directory block(s)\n", nblk);
    }
    printf("    %d directory member entr(y/ies)\n", members);
}

/* ====================================================================== */
/* TSO XMIT / NETDATA                                                     */
/* ====================================================================== */
/* decode the text units of a reassembled INMRxx control record.  Text units
 * start at offset 6 (after the "INMR0n" eyecatcher) -- except INMR02, which
 * carries a 4-byte file-number field first, so its text units start at 10. */
static void show_textunits(const unsigned char *r, long len, const char *indent)
{
    long p = (r[5] == 0xF2) ? 10 : 6;
    while (p + 4 <= len) {
        int key = mvs_be16(r + p), num = mvs_be16(r + p + 2);
        long vp = p + 4;                            /* first value: len(2)+data */
        if (key == 0x0002) {                        /* INMDSNAM: num qualifiers */
            char dsn[64]; int dl = 0, q; long t = vp;
            for (q = 0; q < num && t + 2 <= len; q++) {
                int ql = mvs_be16(r + t); t += 2;
                if (t + ql > len) break;
                if (q && dl < 62) dsn[dl++] = '.';
                { int z; for (z = 0; z < ql && dl < 62; z++) dsn[dl++] = mvs_e2a_pr(r[t + z]); }
                t += ql;
            }
            dsn[dl] = 0;
            printf("%sINMDSNAM   %s\n", indent, dsn);
            p = t; continue;
        }
        {
            const char *kn = key == 0x1028 ? "INMUTILN" : key == 0x1001 ? "INMTNODE" :
                             key == 0x1002 ? "INMTUID " : key == 0x1011 ? "INMFNODE" :
                             key == 0x1012 ? "INMFUID " : key == 0x1024 ? "INMFTIME" : NULL;
            if (kn && vp + 2 <= len) {
                int sl = mvs_be16(r + vp); char s[64];
                if (sl > 63) sl = 63;
                if (vp + 2 + sl <= len) { e2a_n(s, r + vp + 2, sl); printf("%s%s   %s\n", indent, kn, s); }
            } else if (key == 0x0049 && vp + 4 <= len) {        /* INMRECFM */
                int code = mvs_be16(r + vp + 2);
                printf("%sINMRECFM   %s\n", indent,
                       (code & 0xC000) == 0xC000 ? "U" : (code & 0x4800) == 0x4800 ? "VS" :
                       (code & 0x8000) ? "F" : (code & 0x4000) ? "V" : "data");
            } else if ((key == 0x0030 || key == 0x0042 || key == 0x003c ||
                        key == 0x102c || key == 0x000c) && vp + 2 <= len) {
                /* integer DCB / allocation text units: BLKSIZE, LRECL, DSORG,
                 * INMSIZE (alloc size hint), INMDIR (directory blocks) */
                int vl = mvs_be16(r + vp), z; long val = 0;
                for (z = 0; z < vl && vp + 2 + z < len; z++) val = (val << 8) | r[vp + 2 + z];
                if (key == 0x003c)                              /* INMDSORG */
                    printf("%sINMDSORG   %s\n", indent,
                           val == 0x0200 ? "PO" : val == 0x4000 ? "PS" :
                           val == 0x0040 ? "DA" : "?");
                else
                    printf("%s%s   %ld\n", indent,
                           key == 0x0030 ? "INMBLKSZ" : key == 0x0042 ? "INMLRECL" :
                           key == 0x102c ? "INMSIZE " : "INMDIR  ", val);
            }
        }
        { int j; long q = vp; for (j = 0; j < num && q + 2 <= len; j++) { int l = mvs_be16(r + q); q += 2 + l; } p = q; }
    }
}

static void show_xmit(const char *path, const unsigned char *b, long n, int v)
{
    /* reassemble: control records (INMRxx) and the concatenated data stream */
    static unsigned char rec[4096];        /* one reassembled control record */
    static unsigned char data[1 << 22];    /* the wrapped unload image (4 MB) */
    long datalen = 0, reclen = 0, p = 0;
    char target_dsn[64] = "", utility[16] = "";
    int nctl = 0;

    while (p + 2 <= n) {
        int seglen = b[p], flags;
        if (seglen < 2) break;                          /* FB80 padding -> end */
        if (p + seglen > n) break;
        flags = b[p + 1];
        if (flags & 0x20) {                             /* control segment */
            if (flags & 0x80) reclen = 0;               /* first-of-record */
            if (reclen + (seglen - 2) <= (long)sizeof rec) {
                memcpy(rec + reclen, b + p + 2, seglen - 2);
                reclen += seglen - 2;
            }
            if (flags & 0x40) {                         /* last-of-record: complete */
                nctl++;
                if (reclen >= 6 && rec[0] == 0xC9 && rec[1] == 0xD5 &&
                    rec[2] == 0xD4 && rec[3] == 0xD9 && rec[4] == 0xF0) {
                    int which = rec[5] - 0xF0;
                    /* harvest dsn + utility name for the summary (INMR02 #1; text
                     * units start at 10 -- after the 4-byte file-number field) */
                    if (which == 2 && !utility[0]) {
                        long q = 10;
                        while (q + 4 <= reclen) {
                            int key = mvs_be16(rec + q), num = mvs_be16(rec + q + 2);
                            long vp = q + 4;
                            if (key == 0x1028 && vp + 2 <= reclen) {        /* INMUTILN */
                                int sl = mvs_be16(rec + vp); if (sl > 15) sl = 15;
                                if (vp + 2 + sl <= reclen) e2a_n(utility, rec + vp + 2, sl);
                            }
                            if (key == 0x0002) {                            /* INMDSNAM */
                                int dl = 0, qq; long t = vp;
                                for (qq = 0; qq < num && t + 2 <= reclen; qq++) {
                                    int ql = mvs_be16(rec + t); t += 2;
                                    if (t + ql > reclen) break;
                                    if (qq && dl < 62) target_dsn[dl++] = '.';
                                    { int z; for (z = 0; z < ql && dl < 62; z++) target_dsn[dl++] = mvs_e2a_pr(rec[t + z]); }
                                    t += ql;
                                }
                                target_dsn[dl] = 0;
                                q = t; continue;
                            }
                            { int j; long t = vp; for (j = 0; j < num && t + 2 <= reclen; j++) { int l = mvs_be16(rec + t); t += 2 + l; } q = t; }
                        }
                    }
                }
            }
        } else {                                        /* data segment */
            if (datalen + (seglen - 2) <= (long)sizeof data) {
                memcpy(data + datalen, b + p + 2, seglen - 2);
                datalen += seglen - 2;
            }
        }
        p += seglen;
    }

    /* peel the onion: the data stream should be an IEBCOPY unload */
    {
        enum fmt inner = detect(data, datalen);
        const char *member = "";
        int nmemb = 0;
        if (inner == F_IEBCOPY) {                    /* count members across all dir blocks */
            long dp = UNLOAD_ENVHDR;
            while (dp + 12 + 8 + 256 <= datalen && data[dp + 9] == 8 && mvs_be16(data + dp + 10) == 256) {
                const unsigned char *blk = data + dp + 20;
                int used = mvs_be16(blk), q = 2;
                if (used < 2 || used > 256) used = 256;
                while (q + 12 <= used) {
                    const unsigned char *e = blk + q;
                    if (memcmp(e, "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF", 8) == 0) break;
                    if (!nmemb) member = mvs_nm(e);      /* first member name */
                    nmemb++;
                    q += 12 + (e[11] & 0x1f) * 2;
                }
                dp += 12 + 8 + 256;
            }
        }

        printf("%s: TSO XMIT/NETDATA", path);
        if (target_dsn[0]) printf(" -> %s", target_dsn);
        if (utility[0]) printf(", %s", utility);
        if (inner == F_IEBCOPY) {
            printf(", wraps IEBCOPY unload");
            if (nmemb == 1 && member[0]) printf(" (member %s)", member);
            else if (nmemb > 1)          printf(" (%d members)", nmemb);
        } else if (datalen) {
            printf(", wraps %s", inner == F_LMOD ? "load module" : "data");
        }
        if (n % 80) printf(", WARNING: not FB80 (size %% 80 != 0)");
        printf("\n");
        if (!v) return;

        printf("    %d control record(s) (INMR01..INMR06), %ld data byte(s)\n",
               nctl, datalen);
        /* re-walk for a per-record text-unit dump */
        p = 0; reclen = 0;
        while (p + 2 <= n) {
            int seglen = b[p], flags;
            if (seglen < 2) break;
            if (p + seglen > n) break;
            flags = b[p + 1];
            if (flags & 0x20) {
                if (flags & 0x80) reclen = 0;
                if (reclen + (seglen - 2) <= (long)sizeof rec) {
                    memcpy(rec + reclen, b + p + 2, seglen - 2); reclen += seglen - 2;
                }
                if ((flags & 0x40) && reclen >= 6 && rec[0] == 0xC9 && rec[4] == 0xF0) {
                    printf("    INMR%02d\n", rec[5] - 0xF0);
                    show_textunits(rec, reclen, "      ");
                }
            }
            p += seglen;
        }
        if (inner == F_IEBCOPY) {
            printf("    wrapped image:\n");
            show_iebcopy("      (unload)", data, datalen, v);
        }
    }
}

/* ====================================================================== */
static int inspect(const char *path, int v)
{
    long n; unsigned char *b = mvs_read_file(path, &n);
    enum fmt f;
    if (!b) { perror(path); return 1; }
    if (n == 0) { printf("%s: empty file\n", path); free(b); return 0; }
    f = detect(b, n);
    switch (f) {
        case F_OBJ:     show_obj(path, b, n, v); break;
        case F_AR:      show_ar(path, b, n, v); break;
        case F_LMOD:    show_lmod(path, b, n, v); break;
        case F_IEBCOPY: show_iebcopy(path, b, n, v); break;
        case F_XMIT:    show_xmit(path, b, n, v); break;
        default:        printf("%s: data (not a recognized cc370 toolchain format)\n", path); break;
    }
    free(b);
    return f == F_UNKNOWN ? 2 : 0;
}

static void usage(FILE *f)
{
    fprintf(f,
        "usage: file370 [-v] FILE...\n"
        "       file370 --help | --version\n"
        "\n"
        "Identify and analyze the MVS formats produced by the cc370 toolchain:\n"
        "  OBJ deck (as370), ar370 archive, MVS load module (ld370 -o),\n"
        "  IEBCOPY unload (ld370 -iebcopy), TSO XMIT/NETDATA (ld370 -xmit).\n"
        "\n"
        "  -v   verbose: full structural dump (ESD/records/directory/text units);\n"
        "       for an XMIT this peels the wrapped unload + member.\n");
}

int main(int argc, char **argv)
{
    int v = 0, i, rc = 0, nfiles = 0;
    for (i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "-v")) v = 1;
        else if (!strcmp(argv[i], "--help") || !strcmp(argv[i], "-h")) { usage(stdout); return 0; }
        else if (!strcmp(argv[i], "--version") || !strcmp(argv[i], "-V")) { printf("%s\n", VERSION_STR); return 0; }
        else if (argv[i][0] == '-' && argv[i][1]) { fprintf(stderr, "file370: unknown option '%s'\n", argv[i]); usage(stderr); return 2; }
        else { int r = inspect(argv[i], v); if (r > rc) rc = r; nfiles++; }
    }
    if (!nfiles) { usage(stderr); return 2; }
    return rc;
}
