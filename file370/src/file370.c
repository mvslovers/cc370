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

#include "cc370-version.h"   /* CC370_VERSION, CC370_COMMIT (common/mkversion.sh) */
#define VERSION_STR "file370 " CC370_VERSION " (" CC370_COMMIT ")"

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
/* The first byte of a load module is a CESD (X'20') or a SYM record (X'4n'),
 * and a text file beginning with a space or with '@'..'O' looks the same: the
 * sniff called such files load modules (found with #806).  One record the
 * iterator reads as a CESD or a control record decides; a truncated module
 * still has them, a text file has none. */
/* lmod_plausible() lives in common/obj370 now: dasm370 and idrdump370 ask it too (#809). */

static enum fmt detect(const unsigned char *b, long n)
{
    if (n >= 8 && memcmp(b, "!<arch>\n", 8) == 0) return F_AR;
    if (n >= 4 && b[0] == 0x00 && b[1] == 0xCA && b[2] == 0x6D && b[3] == 0x0F)
        return F_IEBCOPY;                                         /* COPYR1 eye-catcher */
    if (n >= 8 && b[2] == 0xC9 && b[3] == 0xD5 && b[4] == 0xD4 &&
        b[5] == 0xD9 && b[6] == 0xF0 && b[7] == 0xF1)
        return F_XMIT;                                            /* "INMR01" at offset 2 */
    if (n >= 4 && obj_card_type(b) != OBJ_OTHER) return F_OBJ;
    /* First record is the CESD -- unless the module was linked with TEST, in
     * which case the SYM records come first (internals/load-module-format.md
     * section 2), and a sniff that only knows X'20' calls the member "data". */
    if ((n >= 1 && (b[0] == 0x20 || b[0] == 0x28)) ||
        (n >= 8 && (b[0] & 0xf0) == 0x40))                       /* leading SYM */
        return lmod_plausible(b, n) ? F_LMOD : F_UNKNOWN;
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
        /* Composite-only codes.  A bound CESD carries these and an object deck
         * cannot, so they are named HERE and not in obj_type_name(): dasm370
         * relies on that function answering "??" for exactly this set, and
         * says so at dasm370.c:1709. */
        case 0x03: return "LR";    /* an LD, once bound            */
        case 0x06: return "PR";    /* pseudo-register              */
        case 0x07: return "Nul";   /* deleted entry, name survives */
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
/* An archive member's name as its header gives it: "name/" short, or "/NNN",
 * an offset into the GNU long-name member, which ar370 writes since #805.
 * Empty for the symbol table and the long-name member themselves. */
static void ar_member_name(const unsigned char *h, const unsigned char *ln, long lnlen, char *name, size_t namesz)
{
    size_t len = 0;
    if (h[0] == '/' && h[1] >= '0' && h[1] <= '9' && ln) {
        long o = atol((const char *)h + 1);
        while (o < lnlen && ln[o] != '/' && ln[o] != '\n' && len + 1 < namesz) name[len++] = (char)ln[o++];
    } else {
        while (len < 16 && h[len] != '/' && h[len] != ' ' && len + 1 < namesz) { name[len] = (char)h[len]; len++; }
    }
    name[len] = 0;
}

/* the member list, with long names resolved */
static void show_ar_members(const unsigned char *b, long n)
{
    const unsigned char *ln = NULL;
    long lnlen = 0;
    for (long p = 8; p + 60 <= n; ) {
        long size = atol((const char *)b + p + 48);
        if (b[p] == '/' && b[p + 1] == '/') { ln = b + p + 60; lnlen = size; }
        p += 60 + size + (size & 1);
    }
    for (long p = 8; p + 60 <= n; ) {
        long size = atol((const char *)b + p + 48);
        char name[64];
        ar_member_name(b + p, ln, lnlen, name, sizeof name);
        if (name[0]) printf("    member  %-16s  %ld bytes\n", name, size);
        p += 60 + size + (size & 1);
    }
}

static void show_ar(const char *path, const unsigned char *b, long n, int v)
{
    long nmem = 0;
    long nsym = 0;
    const unsigned char *symtab = NULL;
    long symsize = 0;

    /* first pass: count members + locate the "/" symbol table; the GNU
     * long-name member is not counted as an object member */
    for (long p = 8; p + 60 <= n; ) {
        long size = atol((const char *)b + p + 48);
        if (b[p] == '/' && (b[p + 1] == ' ' || b[p + 1] == 0)) {
            symtab = b + p + 60;
            symsize = size;
            if (size >= 4) nsym = (long)mvs_be32(b + p + 60);
        } else if (b[p] != '/' || b[p + 1] != '/') {
            nmem++;
        }
        p += 60 + size + (size & 1);
    }

    printf("%s: ar370 archive -- %ld object member(s), %ld symbol(s)\n",
           path, nmem, nsym);
    if (!v) return;
    show_ar_members(b, n);
    /* symbol names: count(4) + count*offset(4) + NUL-terminated names */
    if (symtab && nsym > 0) {
        long q = 4 + nsym * 4;
        printf("    symbol table (%ld):\n", nsym);
        for (long s = 0; q < symsize && s < nsym; s++) {
            const char *name = (const char *)symtab + q;
            printf("      %s\n", name);
            q += (long)strlen(name) + 1;
        }
    }
}

/* ---- the external symbol dictionary of a BOUND member -------------------
 * file370 has always dumped an object deck's ESD under -v and never a bound
 * member's CESD -- the same question, answered for one container and not the
 * other.  The consumer is "can two distributions' copies of a CSECT be linked
 * interchangeably", which is answered by comparing the two symbol lists, and
 * hand-written CESD decoders get it wrong: mvs38src wrote two in one day, one
 * inventing a name out of a header-length guess and one finding nothing.
 * lmod_cesd_walk() is the shared reader and already knew all of this. */
/* A JSON string: quotes, backslashes and control characters escaped.  Names
 * went out raw, so a file name with a quote broke the document (#806). */
static void json_str(const char *t)
{
    putchar('"');
    for (; *t; t++) {
        unsigned char c = (unsigned char)*t;
        if (c == '"' || c == '\\') printf("\\%c", c);
        else if (c < 0x20) printf("\\u%04x", c);
        else putchar(c);
    }
    putchar('"');
}

/* --json prints ONE document: the object for one file, as it always was, or
 * an array of them for several.  Each file printed its own object, so two
 * files made two documents (#806). */
static int json_items;
static int json_array;
static void json_item_open(const char *path)
{
    printf("%s  {\"file\": ", json_items++ ? ",\n" : "");
    json_str(path);
}

struct cesd_ctx { int json, first, n; };

/* THREE WAYS AN ENTRY CAN HAVE NO NAME, and they are different facts:
 *   8 x X'00'  an empty slot -- what a Nul entry usually carries
 *   8 x X'40'  EBCDIC blanks -- an unnamed PC section
 *   anything else, with '?' for the unprintable bytes
 * mvs_nm() renders the first as "????????", which is both indistinguishable
 * from a real name full of unprintables and a second spelling of "no name"
 * beside "(blank)".  Naming them apart costs nothing and 5,258 of 40,368
 * entries in the two corpora are the first case. */
static const char *cesd_name(const unsigned char *raw, const char *rendered)
{
    int i, zero = 1, blank = 1;
    for (i = 0; i < 8; i++) {
        if (raw[i] != 0x00) zero = 0;
        if (raw[i] != 0x40) blank = 0;
    }
    if (zero)  return "(null)";
    if (blank || !rendered[0]) return "(blank)";
    return rendered;
}

static int cesd_print(const struct lmod_esd *e, void *ctx)
{
    struct cesd_ctx *c = ctx;
    const char *nm = cesd_name(e->name, mvs_nm(e->name));
    int ty = e->type, flags = e->typebyte & 0xf0;
    c->n++;
    if (c->json) {
        printf("%s\n      {\"esdid\": %d, \"name\": ", c->first ? "" : ",", e->esdid);
        json_str(nm);
        printf(", \"type\": \"%s\"", esd_type(ty));
        if (flags) printf(", \"typebyte\": \"%02X\"", e->typebyte);
        if (obj_is_section(ty)) printf(", \"addr\": %ld, \"len\": %ld", e->addr, e->len);
        else if (ty == LMOD_LR)  printf(", \"addr\": %ld, \"owner\": %ld", e->addr, e->len);
        if (e->seg) printf(", \"seg\": %d", e->seg);
        printf("}");
        c->first = 0;
        return 1;
    }
    printf("    CESD %3d  %-8s  %-3s", e->esdid, nm, esd_type(ty));
    if (obj_is_section(ty))     printf("  addr=%06lX  len=%06lX", e->addr, e->len);
    else if (ty == LMOD_LR)     printf("  addr=%06lX  owner=%ld", e->addr, e->len);
    if (e->seg)   printf("  seg=%d", e->seg);
    /* The high nibble is an edit-time control bit a finished module should have
     * cleared, and 21 of TK5's 2,396 members do not.  Report what was seen. */
    if (flags)    printf("  [typebyte %02X]", e->typebyte);
    printf("\n");
    return 1;
}

static int show_cesd(const unsigned char *b, long n, int json)
{
    struct cesd_ctx c;
    c.json = json; c.first = 1; c.n = 0;
    lmod_cesd_walk(b, n, cesd_print, &c);
    return c.n;
}

/* ====================================================================== */
/* MVS load module member                                                 */
/* ====================================================================== */
/* walk the byte-0 record stream; counts by type, notes the trailing MODEND */
static void show_lmod(const char *path, const unsigned char *b, long n, int v,
                      int csects, int json)
{
    int ncesd = 0, nidr = 0, nctl = 0, ntext = 0, nrld = 0, nscat = 0, nsym = 0;
    int last_modend = 0, bad = 0;
    struct lmod_info info;

    if (csects) {                          /* the symbol list and nothing else */
        int ns;
        if (json) { json_item_open(path); printf(", \"format\": \"load module\", \"csects\": [");
                    ns = show_cesd(b, n, 1);
                    printf("%s  ],\n   \"count\": %d}", ns ? "\n" : "", ns); }
        else      { printf("%s:\n", path); ns = show_cesd(b, n, 0);
                    if (!ns) printf("    no CESD entries\n"); }
        return;
    }

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
            case LMOD_SCATTER: kind = "scatter"; nscat++; break;
            case LMOD_SYM:  kind = "SYM";     nsym++;  break;
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
    if (v) show_cesd(b, n, 0);             /* the deck path has always done this */
    lmod_scan(b, n, &info);

    /* the summary line goes first when not verbose; when verbose it was preceded
     * by the record dump, so print it as a trailing total either way. */
    if (!v) printf("%s: ", path);
    else    printf("  ");
    printf("MVS load module member -- %d CESD, %d IDR, ", ncesd, nidr);
    if (nscat) printf("%d scatter, ", nscat);
    if (nsym)  printf("%d SYM, ", nsym);
    if (info.nseg > 1) printf("%d overlay segments, ", info.nseg);
    printf("%d text record(s), %d control, %d w/RLD%s, %ld bytes",
           ntext, nctl, nrld, last_modend ? ", MODEND" : "", n);
    if (info.trailing) printf(" (+%ld after MODEND)", info.trailing);
    printf("%s\n", bad ? " (TRUNCATED/unrecognized record)" : "");
}

/* ====================================================================== */
/* PDS directory block decode (shared by IEBCOPY unload + the XMIT peel)   */
/* ====================================================================== */
/* Offset in the PDS2 user data of the APF section (PDSAPFCT, PDSAPFAC), or -1
 * when PDSAPFLG (ud[18] bit4) is off or the entry is too short to hold it.
 * IHAPDS puts the optional sections after the 21-byte basic section in this
 * order: scatter (8, when PDS2SCTR), alias (11, PDS2EPM + PDS2MNM, when the
 * entry is an alias), SSI (4, halfword-aligned, when PDS2SSI), then APF.  A
 * member's APF therefore sits at ud[21], an alias's at ud[32] with no pad. */
static int pds2_apf_off(const unsigned char *ud, int nud, int alias)
{
    int off = 21;
    if (nud < 21 || !(ud[18] & 0x08)) return -1;        /* PDSAPFLG */
    if (ud[8] & 0x04) off += 8;                         /* PDS2SCTR: PDSS01 */
    if (alias) off += 11;                               /* PDSS02 */
    if (ud[18] & 0x10) off = ((off + 1) & ~1) + 4;      /* PDS2SSI: PDSS03, 0H */
    return (off + 2 <= nud) ? off : -1;
}

/* Decode the load-module attributes in a member's PDS2 user data (IHAPDS
 * PDS2ATR1 at ud[8], PDS2ATR2 at ud[9], the APF AC where pds2_apf_off()
 * finds it) into a readable flag list, e.g. "RENT REUS EXEC 1BLK NRLD AC=1".
 * out is left empty if nothing is set. */
static void pds2_attrs(const unsigned char *ud, int nud, int alias, char *out, size_t cap)
{
    int apf = pds2_apf_off(ud, nud, alias);
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
    if (apf >= 0) {
        r = snprintf(out + n, cap - n, "%sAC=%d", n ? " " : "", ud[apf + 1]);
        if (r > 0 && (size_t)r < cap - n) n += (size_t)r;
    }
}

/* parse one 256-byte PDS dir block at blk[0..]; print each member entry.
 * Returns the number of member entries found.  `indent` prefixes each line. */
/* ISPF statistics, the 30-byte user data of a source-library member (the
 * layout xmit370 writes and lists): version.mod, changed date and time,
 * current lines, userid. */
static void show_ispf_stats(const unsigned char *ud)
{
    char uid[9];
    int k = 0;
    for (int i = 0; i < 8; i++) {
        char c = mvs_e2a_pr(ud[20 + i]);
        if (c != ' ') uid[k++] = c;
    }
    uid[k] = 0;
    printf("  ispf v%d.%02d %d%02x/%x%02x %02x:%02x %d lines %s",
           ud[0], ud[1], ud[8] ? 20 : 19, ud[9], ud[10] >> 4,
           ((ud[10] & 0xf) << 4) | (ud[11] >> 4), ud[12], ud[13], mvs_be16(ud + 14), uid);
}

/* A load-library member's PDS2 user data: entry point, length, the member an
 * alias names, the attributes, and with -v the raw attribute bytes. */
static void show_pds2(const unsigned char *ud, int nud, int alias, const char *indent, int v)
{
    long modlen = mvs_be24(ud + 10);
    long entry = mvs_be24(ud + 15);
    int apf = pds2_apf_off(ud, nud, alias);
    int als = 21 + ((ud[8] & 0x04) ? 8 : 0);        /* PDSS02, after any PDSS01 */
    int names = alias && als + 11 <= nud;            /* PDS2MNM / PDS2EPM present */
    char attrs[96];
    pds2_attrs(ud, nud, alias, attrs, sizeof attrs);
    printf("  entry=%06lX  modlen=%ld", entry, modlen);
    if (names) printf("  of %s", mvs_nm(ud + als + 3));   /* the member it names */
    if (attrs[0]) printf("  [%s]", attrs);
    if (!v) return;
    printf("\n%s         ATR1=%02X ATR2=%02X  AC=%02X  PDS2TTRT=%06lX",
           indent, ud[8], ud[9], (apf >= 0) ? ud[apf + 1] : 0, mvs_be24(ud));
    if (names) printf("  PDS2EPM=%06lX", mvs_be24(ud + als));
}

/* LOADLIB: the library is RECFM=U, so the user data is PDS2's.  Otherwise it is
 * a source library's, ISPF statistics when 30 bytes (#806: an xmit370 source
 * library's statistics were printed as entry, modlen and attributes). */
static int show_dir_block(const unsigned char *blk, const char *indent, int v, int loadlib)
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
        if (!loadlib) {                             /* source library */
            if (nud == 30) show_ispf_stats(ud);
            else if (nud) printf("  userdata=%d bytes", nud);
        } else if (nud >= 18) {                     /* load-module PDS2 user data */
            show_pds2(ud, nud, alias, indent, v);
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

/* "U", "FB" ... for a COPYR1 RECFM byte */
static const char *recfm_name(int r)
{
    if ((r & 0xc0) == 0xc0) return "U";
    if ((r & 0x48) == 0x48) return (r & 0x10) ? "VBS" : "VS";
    if (r & 0x80) return (r & 0x10) ? "FB" : "F";
    if (r & 0x40) return (r & 0x10) ? "VB" : "V";
    return "?";
}

/* The one-line form: name the member(s) inline, across all directory blocks. */
static int iebcopy_block_names(const unsigned char *blk, int *first)
{
    int used = mvs_be16(blk);
    int members = 0;
    if (used < 2 || used > 256) used = 256;
    for (int p = 2; p + 12 <= used; ) {
        const unsigned char *e = blk + p;
        if (memcmp(e, "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF", 8) == 0) break;
        printf("%s member %s", *first ? "" : ",", mvs_nm(e));
        *first = 0;
        members++;
        p += 12 + (e[11] & 0x1f) * 2;
    }
    return members;
}

static void show_iebcopy_names(const unsigned char *b, long n)
{
    int first = 1;
    int members = 0;
    printf(" --");
    for (long dp = UNLOAD_ENVHDR; dp + 12 + 8 + 256 <= n && b[dp + 9] == 8 && mvs_be16(b + dp + 10) == 256;
         dp += 12 + 8 + 256)
        members += iebcopy_block_names(b + dp + 20, &first);
    if (!members) printf(" (no member entries found)");
    printf("\n");
}

static void show_iebcopy(const char *path, const unsigned char *b, long n, int v)
{
    int members = 0;
    int recfm = n > MVS_XC1RECFM ? b[MVS_XC1RECFM] : 0;
    int loadlib = (recfm & 0xc0) == 0xc0;

    /* The library's own DCB, from COPYR1.  The heading said "RECFM=U source"
     * whatever the library was (#806). */
    if (loadlib) printf("%s: IEBCOPY unloaded PDS (RECFM=U load library)", path);
    else printf("%s: IEBCOPY unloaded PDS (RECFM=%s, LRECL=%d source library)", path,
                recfm_name(recfm), n > MVS_XC1LRECL + 1 ? mvs_be16(b + MVS_XC1LRECL) : 0);
    if (!v) {
        show_iebcopy_names(b, n);
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
            members += show_dir_block(b + dp + 20, "    ", v, loadlib);
            dp += 12 + 8 + 256; nblk++;
        }
        if (!nblk) printf("    (truncated: directory block beyond end of file)\n");
        else if (nblk > 1) printf("    %d directory block(s)\n", nblk);
    }
    printf("    %d directory member entr(y/ies)\n", members);
}


/* The integer text units' names.  INMNUMF (the number of files, INMR01) was
 * not among them and was left out of the dump (#804). */
static const char *int_tu_name(int key)
{
    switch (key) {
        case 0x0030: return "INMBLKSZ";
        case 0x0042: return "INMLRECL";
        case 0x102c: return "INMSIZE ";
        case 0x102f: return "INMNUMF ";
        default:     return "INMDIR  ";
    }
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
                /* X'0001' is the shortened VBS form of the transmission
                 * records themselves -- what INMR03 carries; it decoded as
                 * "data" (#806).  The value is shown beside its name. */
                int code = mvs_be16(r + vp + 2);
                char nm[32];
                printf("%sINMRECFM   %s (X'%04X')\n", indent, mvs_inmrecfm_name(code, nm), code);
            } else if ((key == 0x0030 || key == 0x0042 || key == 0x003c ||
                        key == 0x102c || key == 0x000c || key == 0x102f) && vp + 2 <= len) {
                /* integer DCB / allocation text units: BLKSIZE, LRECL, DSORG,
                 * INMSIZE (alloc size hint), INMDIR (directory blocks) */
                int vl = mvs_be16(r + vp), z; long val = 0;
                for (z = 0; z < vl && vp + 2 + z < len; z++) val = (val << 8) | r[vp + 2 + z];
                if (key == 0x003c)                              /* INMDSORG */
                    printf("%sINMDSORG   %s\n", indent,
                           val == 0x0200 ? "PO" : val == 0x4000 ? "PS" :
                           val == 0x0040 ? "DA" : "?");
                else
                    printf("%s%s   %ld\n", indent, int_tu_name(key), val);
            }
        }
        { int j; long q = vp; for (j = 0; j < num && q + 2 <= len; j++) { int l = mvs_be16(r + q); q += 2 + l; } p = q; }
    }
}

/* Append a data segment to the wrapped image, growing it as needed. */
static void data_append(unsigned char **data, long *len, long *cap, const unsigned char *src, long add)
{
    if (add <= 0) return;
    if (*len + add > *cap) {
        long nc = *cap ? *cap * 2 : 1L << 20;
        while (nc < *len + add) nc *= 2;
        unsigned char *nd = realloc(*data, (size_t)nc);
        if (!nd) { fprintf(stderr, "file370: out of memory\n"); free(*data); exit(1); }
        *data = nd;
        *cap = nc;
    }
    memcpy(*data + *len, src, (size_t)add);
    *len += add;
}

static void show_xmit(const char *path, const unsigned char *b, long n, int v)
{
    /* reassemble: control records (INMRxx) and the concatenated data stream */
    static unsigned char rec[4096];        /* one reassembled control record */
    /* The wrapped unload image grows as needed: it was a fixed 4 MB, and the
     * data of a larger transmission was cut without a word (#806). */
    unsigned char *data = NULL;
    long datacap = 0;
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
            data_append(&data, &datalen, &datacap, b + p + 2, seglen - 2);
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
        if (!v) { free(data); return; }

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
    free(data);
}

/* ====================================================================== */
/* "-" is standard input (#806: it was taken as a file name). */
static unsigned char *read_input(const char *path, long *n)
{
    if (strcmp(path, "-")) return mvs_read_file(path, n);
    unsigned char *b = NULL;
    long cap = 0;
    long len = 0;
    for (;;) {
        if (len == cap) {
            long nc = cap ? cap * 2 : 65536;
            unsigned char *nb = realloc(b, (size_t)nc);
            if (!nb) { free(b); return NULL; }
            b = nb; cap = nc;
        }
        size_t got = fread(b + len, 1, (size_t)(cap - len), stdin);
        if (!got) break;
        len += (long)got;
    }
    *n = len;
    return b ? b : malloc(1);
}

static const char *fmt_name(enum fmt f)
{
    switch (f) {
        case F_OBJ:     return "object deck";
        case F_AR:      return "ar370 archive";
        case F_LMOD:    return "load module";
        case F_IEBCOPY: return "IEBCOPY unload";
        case F_XMIT:    return "XMIT";
        default:        return "data";
    }
}

/* An object deck's ESD as --json: the same shape as a load module's CESD.
 * Only the load module had it, so --json on a deck said its format and no
 * more, although --csects lists a deck's ESD (#806 follow-up). */
struct obj_json { int n; };
static int obj_json_item(const struct obj_esd *e, void *ctx)
{
    struct obj_json *j = ctx;
    printf("%s\n      {", j->n++ ? "," : "");
    if (e->esdid) printf("\"esdid\": %d, ", e->esdid);
    printf("\"name\": ");
    json_str(cesd_name(e->name, mvs_nm(e->name)));
    printf(", \"type\": \"%s\"", esd_type(e->type));
    if (obj_is_section(e->type)) printf(", \"addr\": %ld, \"len\": %ld", e->addr, e->len);
    else if (e->type == 0x01) printf(", \"addr\": %ld, \"owner\": %ld", e->addr, e->len);
    printf("}");
    return 1;
}

static void obj_json(const char *path, const unsigned char *b, long n)
{
    struct obj_json j = { 0 };
    json_item_open(path);
    printf(", \"format\": \"object deck\", \"csects\": [");
    for (long off = 0; off + OBJ_CARD_LEN <= n; off += OBJ_CARD_LEN)
        if (obj_card_type(b + off) == OBJ_ESD) obj_esd_walk(b + off, obj_json_item, &j);
    printf("%s  ],\n   \"count\": %d}", j.n ? "\n" : "", j.n);
}

static int inspect(const char *path, int v, int csects, int json)
{
    long n;
    unsigned char *b = read_input(path, &n);
    enum fmt f;
    if (!b) { perror(path); return 1; }
    f = n ? detect(b, n) : F_UNKNOWN;
    if (json && f == F_OBJ) {              /* the deck's ESD */
        obj_json(path, b, n);
        free(b);
        return 0;
    }
    if (json && f != F_LMOD) {             /* no ESD to list: the format alone */
        json_item_open(path);
        printf(", \"format\": \"%s\"}", n ? fmt_name(f) : "empty");
        free(b);
        return n && f == F_UNKNOWN ? 2 : 0;
    }
    if (n == 0) { printf("%s: empty file\n", path); free(b); return 0; }
    switch (f) {
        case F_OBJ:     show_obj(path, b, n, v || csects); break;
        case F_AR:      show_ar(path, b, n, v); break;
        case F_LMOD:    show_lmod(path, b, n, v, csects, json); break;
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
        "usage: file370 [-v] [--csects] [--json] FILE...\n"
        "       file370 --help | --version\n"
        "\n"
        "Identify and analyze the MVS formats produced by the cc370 toolchain:\n"
        "  OBJ deck (as370), ar370 archive, MVS load module (ld370 -o),\n"
        "  IEBCOPY unload (ld370 -iebcopy), TSO XMIT/NETDATA (ld370 -xmit,\n"
        "  xmit370 create).  FILE - is standard input.\n"
        "\n"
        "  -v         full structural dump (ESD/records/directory/text units);\n"
        "             for an XMIT it peels the wrapped unload and its members\n"
        "  --csects   list the external symbol dictionary and nothing else:\n"
        "             a bound member's CESD, an object deck's ESD\n"
        "  --json     a JSON object per file -- a load module's CESD, an object\n"
        "             deck's ESD, the format of anything else -- and an array of\n"
        "             them for several files; implies --csects\n"
        "Options apply to the files named after them.\n"
        "Exit status: 0 all recognised, 2 a file not in a known format (it\n"
        "outranks 1), 1 a file that could not be read.\n");
}

/* One option: 1 = taken, 0 = not an option, or 100 + the exit status for one
 * that ends the run (--help, --version, an unknown option). */
static int option(const char *a, int *v, int *csects, int *json)
{
    if (!strcmp(a, "-v")) { *v = 1; return 1; }
    if (!strcmp(a, "--csects")) { *csects = 1; return 1; }
    if (!strcmp(a, "--json")) { *json = 1; *csects = 1; return 1; }
    if (!strcmp(a, "--help") || !strcmp(a, "-h")) { usage(stdout); return 100; }
    if (!strcmp(a, "--version") || !strcmp(a, "-V")) { printf("%s\n", VERSION_STR); return 100; }
    if (a[0] == '-' && a[1]) {
        fprintf(stderr, "file370: unknown option '%s'\n", a);
        usage(stderr);
        return 102;
    }
    return 0;
}

int main(int argc, char **argv)
{
    int v = 0;
    int rc = 0;
    int nfiles = 0;
    int csects = 0;
    int json = 0;
    int json_open = 0;
    int nargs = 0;
    for (int i = 1; i < argc; i++)          /* how many files: one object, or an array */
        if (argv[i][0] != '-' || !argv[i][1]) nargs++;
    json_array = nargs > 1;
    for (int i = 1; i < argc; i++) {
        int o = option(argv[i], &v, &csects, &json);
        if (o >= 100) return o - 100;
        if (o) continue;
        if (json && json_array && !json_open) { printf("[\n"); json_open = 1; }
        int r = inspect(argv[i], v, csects, json);
        if (r > rc) rc = r;
        nfiles++;
    }
    if (json_open) printf("\n]\n");
    else if (json && json_items) printf("\n");
    if (!nfiles) { usage(stderr); return 2; }
    return rc;
}
