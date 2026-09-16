/* cmplmd370 -- does this object deck match that CSECT, byte for byte?
 *
 * The host equivalent of COMPLMD, the utility Dave Kreiss wrote for his MVS 3.8j
 * source recovery (mvslovers/cc370#110).  It is the SUCCESS CRITERION of a
 * recovery pipeline: a module may be declared recovered only when this exits 0,
 * so exit 0 must mean identity and nothing weaker.
 *
 * WHAT IT COMPARES, AND WHY NOT WHAT COMPLMD COMPARED.  Dave compared two LOAD
 * MODULES -- assemble, bind, compare.  This compares an as370 object deck
 * directly against the shipped load module with no binder in between, and that
 * is possible for one reason: in a bound module every address constant is
 * relocated and in a deck none is, but the binder does not touch instructions.
 * Zero the adcons on BOTH sides and the remaining text is identical.
 *
 * So --clearrld is not noise suppression, it is what makes the comparison
 * possible without reproducing IBM's bind -- which is why it defaults ON, as
 * COMPLMD's CLEARRLD did.  71 of the 102 measured DLIB members carry RLD items;
 * without it they cannot be compared at all.
 *
 * Sections are paired BY NAME, never by ESDID: the two sides number differently
 * (a deck numbers from its card's first-id field and skips LD items; a load
 * module's CESD position IS the id), and about 1 member in 10 carries several
 * sections, so assuming either is wrong twice over.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "mvs370.h"
#include "obj370.h"

#define MAXSECT 512

struct sect {
    char name[9];
    long org;                   /* origin: within the object, or in the module image */
    long len;                   /* declared length -- the unit the comparison uses */
    unsigned char *bytes;       /* text image, zero where no text landed */
    unsigned char *relo;        /* 1 per byte covered by an address constant */
    unsigned char *made;        /* 1 where a TXT card actually put something   */
    unsigned char *ign;         /* 1 where --difin says to ignore              */
    int seg;                    /* overlay segment (CESDSEG); 0 when not overlaid */
};

struct side {
    struct sect s[MAXSECT];
    int n;
    int id2sect[65536];         /* ESDID -> index into s[]; -1 for none */
    int is_lmod;                /* this side came from a bound member */
    struct lmod_info info;      /* what the record walk could account for */
};

static void die(const char *m, const char *a)
{
    fprintf(stderr, "cmplmd370: %s%s%s\n", m, a ? ": " : "", a ? a : "");
    exit(2);
}

static struct sect *sect_add(struct side *sd, const unsigned char *nm8,
                             long org, long len, int esdid, int seg)
{
    struct sect *s;
    if (sd->n >= MAXSECT) die("too many sections", NULL);
    s = &sd->s[sd->n];
    memset(s, 0, sizeof *s);
    strncpy(s->name, mvs_nm(nm8), sizeof s->name - 1);
    s->org = org;
    s->len = len;
    s->seg = seg;
    s->bytes = calloc((size_t)(len > 0 ? len : 1), 1);
    s->relo  = calloc((size_t)(len > 0 ? len : 1), 1);
    s->made  = calloc((size_t)(len > 0 ? len : 1), 1);
    s->ign   = calloc((size_t)(len > 0 ? len : 1), 1);
    if (!s->bytes || !s->relo || !s->made || !s->ign) die("out of memory", NULL);
    if (esdid > 0 && esdid < 65536) sd->id2sect[esdid] = sd->n;
    sd->n++;
    return s;
}

static struct sect *sect_find(struct side *sd, const char *name)
{
    int i;
    for (i = 0; i < sd->n; i++)
        if (!strcmp(sd->s[i].name, name)) return &sd->s[i];
    return NULL;
}

static void side_init(struct side *sd)
{
    memset(sd, 0, sizeof *sd);
    memset(sd->id2sect, -1, sizeof sd->id2sect);
}

/* Mark the bytes an address constant covers.  The item's `addr` is relative to
 * whatever the producer measured from -- section origin in a deck, module origin
 * in a bound member -- and `p` names the section, so the section's own origin is
 * the right thing to subtract in both cases. */
static int mark_relo(const struct obj_rld *r, void *ctx)
{
    struct side *sd = ctx;
    int si = (r->p > 0 && r->p < 65536) ? sd->id2sect[r->p] : -1;
    long a, w, i;
    if (si < 0) return 1;
    a = r->addr - sd->s[si].org;
    w = obj_rld_len(r->flag);
    for (i = 0; i < w; i++)
        if (a + i >= 0 && a + i < sd->s[si].len) sd->s[si].relo[a + i] = 1;
    return 1;
}

/* ---------------- object deck ---------------- */

static int deck_esd(const struct obj_esd *e, void *ctx)
{
    if (obj_is_section(e->type)) sect_add(ctx, e->name, e->addr, e->len, e->esdid, 0);
    return 1;
}

static void load_deck(struct side *sd, const unsigned char *b, long n)
{
    long off;
    side_init(sd);
    for (off = 0; off + OBJ_CARD_LEN <= n; off += OBJ_CARD_LEN)
        if (obj_card_type(b + off) == OBJ_ESD) obj_esd_walk(b + off, deck_esd, sd);

    for (off = 0; off + OBJ_CARD_LEN <= n; off += OBJ_CARD_LEN) {
        const unsigned char *c = b + off;
        if (obj_card_type(c) == OBJ_TXT) {
            struct obj_txt t;
            int si;
            if (!obj_txt_get(c, &t)) continue;
            si = (t.esdid > 0 && t.esdid < 65536) ? sd->id2sect[t.esdid] : -1;
            if (si < 0) continue;
            {   /* TXT addresses are section-relative in a deck */
                long a = t.addr - sd->s[si].org;
                if (a >= 0 && a + t.len <= sd->s[si].len) {
                    memcpy(sd->s[si].bytes + a, t.data, (size_t)t.len);
                    /* Record WHERE the assembler produced something.  An offset
                     * no TXT card covers is one as370 never wrote: the loader
                     * zeroes it, and whatever the shipped module carries there
                     * is residue from a DS hole, not a disagreement.  A zero
                     * INSIDE a TXT card, by contrast, is a zero the assembler
                     * meant.  That distinction is the difference between "not
                     * recovered" and "recovered", so the tool computes it
                     * rather than leaving it to a reader. */
                    memset(sd->s[si].made + a, 1, (size_t)t.len);
                }
            }
        } else if (obj_card_type(c) == OBJ_RLD) {
            obj_rld_walk(c, mark_relo, sd);
        }
    }
}

/* ---------------- load module ---------------- */

static int lmod_sect(const struct lmod_esd *e, void *ctx)
{
    /* The LOW NIBBLE, not the whole byte.  A finished module is supposed to
     * carry no edit-time control bits, and 21 of TK5's 2,396 bound target
     * members do: IEANUC01's nucleus proper is 24 entries of X'20' over an SD,
     * and testing the byte made every one of them invisible -- "no section
     * named IGFPEXIT", exit 2, on a module that holds it at 0x021F80.  See
     * LMOD_ESD_FLAGS in obj370.h. */
    if (obj_is_section(e->type))
        sect_add(ctx, e->name, e->addr, e->len, e->esdid, e->seg);
    return 1;
}

static void load_lmod(struct side *sd, const unsigned char *m, long n)
{
    struct lmod_iter it;
    struct lmod_item r;
    unsigned char *img;
    long imglen = 0, pend = -1;
    int rc, i, nseg, want;

    side_init(sd);
    sd->is_lmod = 1;
    /* Ask the reader what it could account for BEFORE using what it returns.
     * A member the walk cannot finish still yields sections and still compares;
     * saying so is the difference between a verdict and a guess (#372). */
    lmod_scan(m, n, &sd->info);
    lmod_cesd_walk(m, n, lmod_sect, sd);
    nseg = sd->info.nseg;                    /* 0 when the module is not overlaid */
    /* A storage-owning section with no segment number in a module that HAS
     * segments would never be sliced by the loop below, which walks segments
     * 1..nseg.  Measured across both of TK5's corpora -- 2,396 bound target
     * members and 5,353 DLIB members -- this never occurs, so the line is
     * insurance and not a fix; the root segment is the only reading that keeps
     * such a section reachable. */
    if (nseg >= 1)
        for (i = 0; i < sd->n; i++) if (!sd->s[i].seg) sd->s[i].seg = 1;

    for (i = 0; i < sd->n; i++)
        if (sd->s[i].org + sd->s[i].len > imglen) imglen = sd->s[i].org + sd->s[i].len;
    /* A text record can reach PAST the sum of the section lengths: the binder
     * pads to a doubleword, so a 12-byte section arrives as 16 bytes of text.
     * Sizing the image from the sections alone made the bounds check below
     * reject the whole copy and every reference byte then read as zero --
     * which looks exactly like a real difference at offset 0.  Found on
     * IGG026DU, the first real DLIB member this was pointed at. */
    lmod_iter_init(&it, m, n);
    {
        long pa = -1;
        while (lmod_iter_next(&it, &r) == 1) {
            if (r.kind == LMOD_CTL)
                pa = (r.flags & LMOD_CTL_TEXT) ? mvs_be24(m + r.off + 9) : -1;
            else if (r.kind == LMOD_TEXT) {
                if (pa >= 0 && pa + r.len > imglen) imglen = pa + r.len;
                pa = -1;
            }
        }
    }
    img = calloc((size_t)(imglen > 0 ? imglen : 1), 1);
    if (!img) die("out of memory", NULL);

    /* RLDs first, and ONCE.  They are per-section, not per-segment, and the
     * image below is rebuilt once per segment -- marking them inside that loop
     * would mark them n times. */
    lmod_iter_init(&it, m, n);
    while ((rc = lmod_iter_next(&it, &r)) == 1)
        if (r.kind == LMOD_CTL && (r.flags & LMOD_CTL_RLD)) {
            long idl = mvs_be16(m + r.off + 4), rl = mvs_be16(m + r.off + 6);
            long dat = r.off + 16 + idl;
            if (rl > 0 && dat + rl <= n) obj_rld_items(m + dat, rl, mark_relo, sd);
        }
    /* rc < 0 used to die here.  It still means the image is incomplete, but
     * that is now reported through sd->info rather than by exiting from inside
     * a loader -- so --json keeps its shape and a caller learns WHY. */
    (void)rc;

    /* Reassemble the module image, then slice each section out of it: a control
     * record carries the load address (24-bit at +9) of the text record that
     * follows it.
     *
     * ONE IMAGE PER OVERLAY SEGMENT, because the segments deliberately SHARE
     * addresses.  HEWLF064 has seven: segments 2, 3 and 4 all begin at
     * 0x001090 and 5, 6 and 7 all begin at 0x0020C0.  Flattening them into a
     * single image is last-writer-wins, so the sections of every segment but
     * the last one at a given address were compared against another segment's
     * text -- silently, with an ordinary verdict and an ordinary exit code.
     * Segments are written in order and each ends at a control record carrying
     * SEGEND (X'04'); CESDSEG says which segment a section belongs to. */
    for (want = nseg ? 1 : 0; want <= nseg; want++) {
        int cs = 1, segend = 0;
        memset(img, 0, (size_t)(imglen > 0 ? imglen : 1));
        pend = -1;
        lmod_iter_init(&it, m, n);
        while (lmod_iter_next(&it, &r) == 1) {
            if (r.kind == LMOD_CTL) {
                pend = (r.flags & LMOD_CTL_TEXT) ? mvs_be24(m + r.off + 9) : -1;
                /* MODEND is also a segment end, but nothing follows it. */
                segend = (r.flags & LMOD_CTL_SEGEND) && !(r.flags & LMOD_CTL_END);
                if (pend < 0 && segend) { cs++; segend = 0; }
            } else if (r.kind == LMOD_TEXT) {
                if ((!nseg || cs == want) && pend >= 0 && pend + r.len <= imglen)
                    memcpy(img + pend, m + r.off, (size_t)r.len);
                pend = -1;
                if (segend) { cs++; segend = 0; }
            }
        }
        for (i = 0; i < sd->n; i++)
            if (sd->s[i].seg == want && sd->s[i].org >= 0
                && sd->s[i].org + sd->s[i].len <= imglen)
                memcpy(sd->s[i].bytes, img + sd->s[i].org, (size_t)sd->s[i].len);
    }
    free(img);
}

/* ---------------- compare ---------------- */

/* ---- DIFIN / DIFOUT ----
 * Dave Kreiss' format, unchanged: a header line with '>' in column 1 and the
 * CSECT name in 2-9, then difference records with a 6-digit hex offset in 1-6
 * and a 2-digit hex length in 7-8.
 *
 * This is the one option whose PURPOSE is to suppress differences, so it is the
 * one that can quietly turn a real divergence into an exit 0.  It is therefore
 * the last thing built, after the teeth, and it reports how much it masked --
 * an exit 0 that needed 400 ignored bytes is a different claim from one that
 * needed none.
 */
static int hexn(const char *s, int n, long *out)
{
    long v = 0;
    int i;
    for (i = 0; i < n; i++) {
        int c = s[i], d;
        if (c >= '0' && c <= '9') d = c - '0';
        else if (c >= 'a' && c <= 'f') d = c - 'a' + 10;
        else if (c >= 'A' && c <= 'F') d = c - 'A' + 10;
        else return 0;
        v = v * 16 + d;
    }
    *out = v;
    return 1;
}

static void difin_load(struct side *sd, const char *path)
{
    FILE *f = fopen(path, "r");
    char line[256], cur[9] = "";
    int lineno = 0;
    if (!f) { perror(path); exit(2); }
    while (fgets(line, sizeof line, f)) {
        char *p2 = line;
        long off, len, i;
        struct sect *s;
        lineno++;
        while (*p2 && (p2[strlen(p2) - 1] == '\n' || p2[strlen(p2) - 1] == '\r'))
            p2[strlen(p2) - 1] = 0;
        if (!*p2) continue;
        if (*p2 == '>') {
            int k;
            for (k = 0; k < 8 && p2[1 + k] && p2[1 + k] != ' '; k++) cur[k] = p2[1 + k];
            cur[k] = 0;
            continue;
        }
        if (strlen(p2) < 8 || !hexn(p2, 6, &off) || !hexn(p2 + 6, 2, &len)) {
            fprintf(stderr, "cmplmd370: %s:%d: not a DIFIN record: %s\n", path, lineno, p2);
            exit(2);
        }
        if (!cur[0]) {
            fprintf(stderr, "cmplmd370: %s:%d: record before any '>' header\n", path, lineno);
            exit(2);
        }
        s = sect_find(sd, cur);
        if (!s) continue;              /* a section this comparison does not cover */
        for (i = 0; i < len; i++)
            if (off + i >= 0 && off + i < s->len) s->ign[off + i] = 1;
    }
    fclose(f);
}

/* Text output lists at most this many clusters and this many bytes each; --json
 * lists every cluster whole.  The reader's limit is legibility, the consumer's
 * is nothing. */
#define TEXTCLU   64
#define CLUBYTES  16

static void hexrun(const unsigned char *p, long n)
{
    long i;
    for (i = 0; i < n && i < CLUBYTES; i++) printf("%02x", p[i]);
    if (n > CLUBYTES) printf("..");
}

/* Clusters matter more than the total: three separate one-byte differences and
 * one three-byte run mean very different things (#110).
 *
 * They are collected into a growable array rather than a fixed one.  The fixed
 * MAXCLU 64 this started with was fine for reading, but --difout silently
 * omitted every range past the 64th, and a JSON consumer would have had no way
 * to know its cluster list was short.  A machine-read format that truncates
 * without saying so is the failure the caller asked for JSON to avoid. */
struct clu { long off, len; int in_hole; };

struct result {
    const char *name;
    int paired, length_differs, identical;
    long len_new, len_ref;
    long diff, nrelo, nign, in_hole, in_text;
    struct clu *c;
    long nc, ccap;
};

static void clu_add(struct result *r, long off, int in_hole)
{
    if (r->nc >= r->ccap) {
        r->ccap = r->ccap ? r->ccap * 2 : 64;
        r->c = realloc(r->c, (size_t)r->ccap * sizeof *r->c);
        if (!r->c) die("out of memory", NULL);
    }
    r->c[r->nc].off = off; r->c[r->nc].len = 0; r->c[r->nc].in_hole = in_hole;
    r->nc++;
}

static void compare(const struct sect *a, const struct sect *b, int clearrld,
                    const char *label, struct result *r)
{
    long i;
    int inrun = 0;

    memset(r, 0, sizeof *r);
    r->name = label;
    r->paired = 1;
    r->len_new = a->len;
    r->len_ref = b->len;
    if (a->len != b->len) { r->length_differs = 1; return; }

    for (i = 0; i < a->len; i++) {
        if (clearrld && (a->relo[i] || b->relo[i])) { r->nrelo++; inrun = 0; continue; }
        if (a->ign[i]) { r->nign++; inrun = 0; continue; }
        if (a->bytes[i] != b->bytes[i]) {
            r->diff++;
            if (a->made[i]) r->in_text++; else r->in_hole++;
            if (!inrun) { inrun = 1; clu_add(r, i, !a->made[i]); }
            r->c[r->nc - 1].len++;
        } else inrun = 0;
    }
    r->identical = (r->diff == 0);
}

/* Every differing byte outside what a TXT card produced is a DS hole: the loader
 * zeroed it, and the shipped module's content there is residue.  A difference
 * wholly in holes says the SOURCE agrees and a tolerance list is what is
 * missing; one inside generated text says it does not. */
static const char *verdict(const struct result *r)
{
    if (!r->paired)        return "unpaired";
    if (r->length_differs) return "length";
    if (r->identical)      return "identical";
    if (!r->in_text)       return "holes";
    if (!r->in_hole)       return "text";
    return "mixed";
}

static void report_text(const struct result *r, const struct sect *a,
                        const struct sect *b, int verbose)
{
    long i;
    if (!r->paired) { printf("  %-8s not in the reference\n", r->name); return; }
    if (r->length_differs) {
        printf("  %-8s LENGTH differs: new %ld, reference %ld (%+ld)\n",
               r->name, r->len_new, r->len_ref, r->len_new - r->len_ref);
        return;
    }
    if (r->identical) {
        if (verbose)
            printf("  %-8s identical (%ld bytes%s%s)\n", r->name, r->len_new,
                   r->nrelo ? ", adcons cleared" : "", r->nign ? ", difin applied" : "");
        return;
    }
    printf("  %-8s %ld byte(s) differ in %ld cluster(s) of %ld -- %s\n",
           r->name, r->diff, r->nc, r->len_new,
           !r->in_text ? "ALL in DS holes (no byte as370 wrote)"
                       : !r->in_hole ? "all in GENERATED TEXT"
                                     : "some in DS holes, some in generated text");
    if (!verbose) return;
    for (i = 0; i < r->nc && i < TEXTCLU; i++) {
        printf("      @%06lX  %2ld  new ", r->c[i].off, r->c[i].len);
        hexrun(a->bytes + r->c[i].off, r->c[i].len);
        printf("  ref ");
        hexrun(b->bytes + r->c[i].off, r->c[i].len);
        printf("%s\n", r->c[i].in_hole ? "  (hole)" : "");
    }
    if (r->nc > TEXTCLU)
        printf("      ... %ld more cluster(s) not listed (use --json for all)\n",
               r->nc - TEXTCLU);
}

/* ---- what the reader could not account for ----
 * Rendered the same way in both output modes, because a caller that filters on
 * a reason can only do so if the reason is always there.  #372: a boolean says
 * how many results to distrust, a reason says which. */
static void anom_list(const struct lmod_info *in, char *buf, size_t cap)
{
    static const int bits[] = { LMOD_ANOM_TRAILING, LMOD_ANOM_BADREC,
                                LMOD_ANOM_BADLEN, LMOD_ANOM_NOMODEND };
    size_t k = 0;
    int i;
    buf[0] = 0;
    for (i = 0; i < 4; i++) {
        const char *nm;
        if (!(in->anomalies & bits[i])) continue;
        nm = lmod_anom_name(bits[i]);
        if (k && k + 2 < cap) { buf[k++] = ','; buf[k++] = ' '; buf[k] = 0; }
        if (k + strlen(nm) + 1 < cap) { strcpy(buf + k, nm); k += strlen(nm); }
    }
}

static void report_reader(const struct lmod_info *in, int json, const char *fb)
{
    char names[128];
    anom_list(in, names, sizeof names);
    if (json) {
        printf("  \"reader\": {\"records\": %ld, \"segments\": %d, "
               "\"scatter\": %s, \"sym\": %s, \"trailing_bytes\": %ld, "
               "\"image_incomplete\": %s, \"anomalies\": \"%s\"},\n",
               in->nrec, in->nseg,
               in->has_scatter ? "true" : "false", in->has_sym ? "true" : "false",
               in->trailing,
               (in->anomalies & LMOD_IMAGE_INCOMPLETE) ? "true" : "false",
               names);
    } else if (in->anomalies) {
        printf("  reader: %s (%s)%s\n", fb, names,
               (in->anomalies & LMOD_IMAGE_INCOMPLETE) ? "  IMAGE INCOMPLETE" : "");
    }
}

static void report_json(const struct result *r, const struct sect *a,
                        const struct sect *b, int first)
{
    long i, k;
    printf("%s\n    {\n", first ? "" : ",");
    printf("      \"name\": \"%s\",\n", r->name);
    printf("      \"verdict\": \"%s\",\n", verdict(r));
    if (!r->paired) { printf("      \"paired\": false\n    }"); return; }
    printf("      \"paired\": true,\n");
    printf("      \"identical\": %s,\n", r->identical ? "true" : "false");
    printf("      \"length_new\": %ld,\n      \"length_ref\": %ld,\n", r->len_new, r->len_ref);
    printf("      \"length_differs\": %s,\n", r->length_differs ? "true" : "false");
    printf("      \"diff_bytes\": %ld,\n", r->diff);
    printf("      \"diff_in_holes\": %ld,\n      \"diff_in_text\": %ld,\n",
           r->in_hole, r->in_text);
    printf("      \"bytes_cleared_rld\": %ld,\n      \"bytes_ignored_difin\": %ld,\n",
           r->nrelo, r->nign);
    printf("      \"clusters\": [");
    for (i = 0; i < r->nc; i++) {
        printf("%s\n        {\"offset\": %ld, \"length\": %ld, \"in_hole\": %s, \"new\": \"",
               i ? "," : "", r->c[i].off, r->c[i].len, r->c[i].in_hole ? "true" : "false");
        for (k = 0; k < r->c[i].len; k++) printf("%02x", a->bytes[r->c[i].off + k]);
        printf("\", \"ref\": \"");
        for (k = 0; k < r->c[i].len; k++) printf("%02x", b->bytes[r->c[i].off + k]);
        printf("\"}");
    }
    printf("%s]\n    }", r->nc ? "\n      " : "");
}

static void write_difout(FILE *f, const struct result *r)
{
    long i;
    if (!r->paired || r->length_differs || r->identical) return;
    fprintf(f, ">%s\n", r->name);
    for (i = 0; i < r->nc; i++) {
        long o = r->c[i].off, l = r->c[i].len;
        while (l > 0) {                     /* the length field is one byte */
            long chunk = l > 255 ? 255 : l;
            fprintf(f, "%06lX%02lX\n", o, chunk);
            o += chunk; l -= chunk;
        }
    }
}

/* ---------------- driver ---------------- */

static void usage(FILE *f)
{
    fprintf(f,
      "usage: cmplmd370 [options] NEW.obj REFERENCE\n"
      "\n"
      "  NEW.obj     an object deck (as370 output)\n"
      "  REFERENCE   a bound load-module member, or another object deck\n"
      "\n"
      "  --csect NAME   compare only this section (default: pair all by name)\n"
      "  --clearrld     zero address constants before comparing (DEFAULT)\n"
      "  --no-clearrld  compare adcons too -- only meaningful deck against deck\n"
      "  --difin FILE   ignore the ranges this file lists ('>' + CSECT name,\n"
      "                 then a 6-hex offset and a 2-hex length per record)\n"
      "  --difout FILE  write the differences found, in that same format\n"
      "  --json         machine-readable result on stdout, all clusters\n"
      "  --allow-incomplete  compare anyway when the reference's record stream\n"
      "                 could not be walked to its end (default: refuse, exit 2)\n"
      "  -v             report identical sections and list clusters\n"
      "\n"
      "Exit 0 ONLY on identity; 1 on any difference; 2 on a usage or format error.\n"
      "A reference whose image is INCOMPLETE is refused rather than compared: the\n"
      "bytes that are there may well match, and that is not the same as a match.\n");
}

int main(int argc, char **argv)
{
    const char *fa = NULL, *fb = NULL, *only = NULL;
    const char *difin = NULL, *difoutp = NULL;
    FILE *difout = NULL;
    int clearrld = 1, verbose = 0, json = 0, i, rc = 0, npair = 0, firstj = 1;
    int allow_incomplete = 0;
    static int pair[MAXSECT], bused[MAXSECT];
    unsigned char *ba, *bb;
    long na, nb;
    static struct side A, B;

    for (i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "--csect") && i + 1 < argc) only = argv[++i];
        else if (!strcmp(argv[i], "--clearrld")) clearrld = 1;
        else if (!strcmp(argv[i], "--no-clearrld")) clearrld = 0;
        else if (!strcmp(argv[i], "--difin") && i + 1 < argc) difin = argv[++i];
        else if (!strcmp(argv[i], "--difout") && i + 1 < argc) difoutp = argv[++i];
        else if (!strcmp(argv[i], "--json")) json = 1;
        else if (!strcmp(argv[i], "--allow-incomplete")) allow_incomplete = 1;
        else if (!strcmp(argv[i], "-v")) verbose = 1;
        else if (!strcmp(argv[i], "-h") || !strcmp(argv[i], "--help")) { usage(stdout); return 0; }
        else if (argv[i][0] == '-') { fprintf(stderr, "cmplmd370: unknown option %s\n", argv[i]); usage(stderr); return 2; }
        else if (!fa) fa = argv[i];
        else if (!fb) fb = argv[i];
        else { usage(stderr); return 2; }
    }
    if (!fa || !fb) { usage(stderr); return 2; }

    ba = mvs_read_file(fa, &na); if (!ba) { perror(fa); return 2; }
    bb = mvs_read_file(fb, &nb); if (!bb) { perror(fb); return 2; }

    if (na < 4 || obj_card_type(ba) == OBJ_OTHER) die("not an object deck", fa);
    load_deck(&A, ba, na);

    /* A bound member leads with its CESD, or with a SYM record when it was
     * linked with TEST (docs/load-module-format.md section 2). */
    if (nb >= 1 && ((bb[0] & 0xf0) == 0x20 || (nb >= 8 && (bb[0] & 0xf0) == 0x40)))
        load_lmod(&B, bb, nb);
    else if (nb >= 4 && obj_card_type(bb) != OBJ_OTHER) load_deck(&B, bb, nb);
    else die("reference is neither a load module nor an object deck", fb);

    if (difin) difin_load(&A, difin);
    if (difoutp && !(difout = fopen(difoutp, "w"))) { perror(difoutp); return 2; }

    if (json) {
        printf("{\n  \"new\": \"%s\",\n  \"reference\": \"%s\",\n", fa, fb);
        printf("  \"clearrld\": %s,\n", clearrld ? "true" : "false");
        printf("  \"difin\": %s%s%s,\n", difin ? "\"" : "null",
               difin ? difin : "", difin ? "\"" : "");
        if (B.is_lmod) report_reader(&B.info, 1, fb);
        printf("  \"sections\": [");
    } else {
        printf("%s vs %s%s%s\n", fa, fb, clearrld ? "" : "  (adcons compared)",
               difin ? "  (difin applied)" : "");
        if (B.is_lmod) report_reader(&B.info, 0, fb);
    }

    /* ---- pair the sections ----
     * By NAME, with one exception that the name rule cannot express: an
     * UNNAMED section.  as370 and cc370 put code in a bare CSECT, which is an
     * ESD type-04 private-code entry with a blank name, and the linkage editor
     * names it after the member -- so the deck says "" and the bound module
     * says IFCE0115, and pairing by name gives "not in the reference" for a
     * section that is plainly there.  15 of TK5's 16 remaining unreadable
     * CSECTs are exactly this.
     *
     * The exception is taken only where it is UNAMBIGUOUS: an unnamed section
     * pairs with the one section left over on the other side, never with one
     * of several.  Positional pairing beyond that would be the ESDID guess
     * this tool exists not to make. */
    {
        int k;
        for (i = 0; i < A.n; i++) {
            pair[i] = -1;
            if (!A.s[i].name[0]) continue;
            for (k = 0; k < B.n; k++)
                if (!bused[k] && !strcmp(B.s[k].name, A.s[i].name)) {
                    pair[i] = k; bused[k] = 1; break;
                }
        }
        for (i = 0; i < A.n; i++) {
            int cand = -1, ncand = 0;
            if (pair[i] >= 0 || A.s[i].name[0]) continue;
            for (k = 0; k < B.n; k++) if (!bused[k]) { cand = k; ncand++; }
            if (ncand == 1) { pair[i] = cand; bused[cand] = 1; }
        }
    }

    for (i = 0; i < A.n; i++) {
        struct sect *b2 = pair[i] >= 0 ? &B.s[pair[i]] : NULL;
        struct result r;
        /* An unnamed section is reported under the name it was paired to, so a
         * caller can ask for it by the name the module uses. */
        const char *label = A.s[i].name[0] ? A.s[i].name
                          : (b2 && b2->name[0] ? b2->name : "(private)");
        if (only && strcmp(label, only)) continue;
        if (!b2) {
            memset(&r, 0, sizeof r);
            r.name = label; r.paired = 0; r.len_new = A.s[i].len;
            rc = 1;
            if (json) { report_json(&r, &A.s[i], &A.s[i], firstj); firstj = 0; }
            else report_text(&r, &A.s[i], &A.s[i], verbose);
            continue;
        }
        npair++;
        compare(&A.s[i], b2, clearrld, label, &r);
        if (!r.identical) rc = 1;
        if (json) { report_json(&r, &A.s[i], b2, firstj); firstj = 0; }
        else report_text(&r, &A.s[i], b2, verbose);
        if (difout) write_difout(difout, &r);
        free(r.c);
    }
    if (difout) fclose(difout);

    {   /* One exit through here, so the JSON object has ONE shape.  The error
         * paths used to print "error" and stop, leaving out "exit" and
         * "identical" -- the two fields a caller branches on, missing in
         * exactly the case where it most needs them.  A bulk run over 3,888
         * modules found 16 of them: the consumer read exit as null and had to
         * know to fall back on the process status.  A machine-readable answer
         * that omits a field without saying so is the same defect as one that
         * truncates a list without saying so. */
        const char *err = NULL;
        /* 128 for anom_list's four names plus the 56-character sentence around
         * them, rounded up.  It was 160, which snprintf would have TRUNCATED --
         * gcc says so under _FORTIFY_SOURCE and clang does not, so the Mac
         * builds clean and CI does not. */
        char errbuf[256];
        if (B.is_lmod && (B.info.anomalies & LMOD_IMAGE_INCOMPLETE)
            && !allow_incomplete) {
            /* The peer's rule, and the reason it is a refusal rather than a
             * footnote: a section sliced out of an image the reader could not
             * finish may match byte for byte and still not be a match, because
             * the records after the break were never seen.  Reporting that as
             * "identical" with a flag would put it on a scoreboard that no
             * counter written before the flag existed knows to read. */
            char names[128];
            anom_list(&B.info, names, sizeof names);
            snprintf(errbuf, sizeof errbuf,
                     "reference image incomplete (%s); --allow-incomplete to compare anyway",
                     names);
            err = errbuf; rc = 2;
        } else if (only && !npair) {
            snprintf(errbuf, sizeof errbuf, "no section named %s", only);
            err = errbuf; rc = 2;
        } else if (!npair && !rc) {
            err = "no sections paired"; rc = 2;
        }
        if (json) {
            printf("%s],\n", firstj ? "" : "\n  ");
            printf("  \"error\": %s%s%s,\n", err ? "\"" : "null",
                   err ? err : "", err ? "\"" : "");
            printf("  \"identical\": %s,\n  \"exit\": %d\n}\n",
                   rc == 0 ? "true" : "false", rc);
        } else if (err) {
            fprintf(stderr, "cmplmd370: %s\n", err);
        } else {
            printf("%s\n", rc ? "DIFFER" : "IDENTICAL");
        }
        return rc;
    }
}
