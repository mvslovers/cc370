/* obj370.c -- OS/360 object-module record reader.  See obj370.h.
 *
 * Every decode here is lifted from the tool that already did it, not rewritten:
 * the ESD walk and its ESDID numbering from ld370's parse_object (which is the
 * one validated against 743 corpus decks), the card classification from
 * file370's obj_card_type, the RLD continuation handling from ld370's RLD
 * branch, the END fields from the same. */

#include <string.h>

#include "obj370.h"

enum obj_card obj_card_type(const unsigned char *c)
{
    if (c[0] != 0x02) return OBJ_OTHER;
    if (c[1] == 0xC5 && c[2] == 0xE2 && c[3] == 0xC4) return OBJ_ESD;
    if (c[1] == 0xE3 && c[2] == 0xE7 && c[3] == 0xE3) return OBJ_TXT;
    if (c[1] == 0xD9 && c[2] == 0xD3 && c[3] == 0xC4) return OBJ_RLD;
    if (c[1] == 0xC5 && c[2] == 0xD5 && c[3] == 0xC4) return OBJ_END;
    if (c[1] == 0xE2 && c[2] == 0xE8 && c[3] == 0xD4) return OBJ_SYM;
    return OBJ_OTHER;
}

int obj_is_section(int type)
{
    return type == OBJ_SD || type == OBJ_PC || type == OBJ_CM;
}

const char *obj_type_name(int type)
{
    switch (type) {
        case OBJ_SD: return "SD";
        case OBJ_LD: return "LD";
        case OBJ_ER: return "ER";
        case OBJ_PC: return "PC";
        case OBJ_CM: return "CM";
        case OBJ_WX: return "WX";
        default:     return "??";
    }
}

int obj_esd_walk(const unsigned char *card,
                 int (*fn)(const struct obj_esd *e, void *ctx), void *ctx)
{
    int cnt, first, k, nid = 0, n = 0;

    if (obj_card_type(card) != OBJ_ESD) return 0;
    cnt = mvs_be16(card + 10);
    first = mvs_be16(card + 14);
    for (k = 0; k * 16 < cnt && 16 + (k + 1) * 16 <= OBJ_CARD_LEN; k++) {
        const unsigned char *e = card + 16 + k * 16;
        struct obj_esd it;
        it.name = e;
        it.type = e[8] & 0x0f;
        it.addr = mvs_be24(e + 9);
        it.len  = mvs_be24(e + 13);
        /* LD carries no ESDID and does not advance the counter; every other
         * item takes the next one.  This is the numbering the RLD's R and P
         * refer to, so getting it wrong silently mis-targets a relocation. */
        it.esdid = (it.type == OBJ_LD) ? 0 : first + nid++;
        n++;
        if (fn && !fn(&it, ctx)) break;
    }
    return n;
}

int obj_txt_get(const unsigned char *card, struct obj_txt *t)
{
    long cnt;
    if (obj_card_type(card) != OBJ_TXT) return 0;
    cnt = mvs_be16(card + 10);
    if (cnt < 0 || 16 + cnt > OBJ_CARD_LEN) cnt = OBJ_CARD_LEN - 16;
    t->addr  = mvs_be24(card + 5);
    t->esdid = mvs_be16(card + 14);
    t->len   = cnt;
    t->data  = card + 16;
    return 1;
}

int obj_rld_len(int flag)
{
    return ((flag & 0x0c) >> 2) + 1;
}

int obj_rld_items(const unsigned char *d, long len,
                  int (*fn)(const struct obj_rld *r, void *ctx), void *ctx)
{
    long p = 0;
    int r = 0, pp = 0, same = 0, n = 0;

    while (p + 4 <= len) {
        struct obj_rld it;
        /* R and P are present only on the first item of a run; the previous
         * item's flag bit 0x01 says the next one repeats them. */
        if (!same) { r = mvs_be16(d + p); pp = mvs_be16(d + p + 2); p += 4; }
        if (p + 4 > len) break;
        it.r = r; it.p = pp;
        it.flag = d[p];
        it.addr = mvs_be24(d + p + 1);
        same = d[p] & 0x01;
        p += 4;
        n++;
        if (fn && !fn(&it, ctx)) break;
    }
    return n;
}

int obj_rld_walk(const unsigned char *card,
                 int (*fn)(const struct obj_rld *r, void *ctx), void *ctx)
{
    long cnt, avail;
    if (obj_card_type(card) != OBJ_RLD) return 0;
    cnt = mvs_be16(card + 10);
    avail = OBJ_CARD_LEN - 16;
    if (cnt > avail) cnt = avail;
    return obj_rld_items(card + 16, cnt, fn, ctx);
}

int obj_end_get(const unsigned char *card, struct obj_end *e)
{
    if (obj_card_type(card) != OBJ_END) return 0;
    memset(e, 0, sizeof *e);
    /* Columns 6-8 blank means "no entry named here"; otherwise they hold the
     * offset and columns 15-16 the section's ESDID. */
    if (!(card[5] == 0x40 && card[6] == 0x40 && card[7] == 0x40)) {
        e->has_entry = 1;
        e->entry_addr = mvs_be24(card + 5);
        e->entry_esdid = mvs_be16(card + 14);
    }
    return 1;
}

/* ---- load-module records ----
 * The framing is lifted verbatim from ld370's split_member, which file370's
 * show_lmod already duplicated statement for statement:
 *   0x2x  CESD   8 + count at +6
 *   0x8x  IDR    byte at +1, plus one
 *   0x0x  CTL    16 + count at +4 + count at +6, and if bit 0x01 is set a pure
 *                text record of the length at +14 follows it
 * Anything else is a form neither tool produces (SYM, scatter/translate) and is
 * reported as malformed rather than guessed at.
 */
void lmod_iter_init(struct lmod_iter *it, const unsigned char *m, long n)
{
    it->m = m; it->n = n; it->p = 0; it->pending = 0;
}

int lmod_iter_next(struct lmod_iter *it, struct lmod_item *out)
{
    const unsigned char *m = it->m;
    long p = it->p, blen;
    int b0, hi;

    if (it->pending) {                       /* the text record announced last time */
        out->kind = LMOD_TEXT;
        out->off = p; out->len = it->pending; out->flags = 0;
        if (p + it->pending > it->n) return -1;
        it->p = p + it->pending;
        it->pending = 0;
        return 1;
    }
    if (p >= it->n) return 0;
    if (p + 8 > it->n) return -1;

    b0 = m[p]; hi = b0 & 0xf0;
    out->off = p; out->flags = 0;
    if (hi == 0x20) {
        out->kind = LMOD_CESD;
        blen = 8 + mvs_be16(m + p + 6);
    } else if (hi == 0x80) {
        out->kind = LMOD_IDR;
        blen = m[p + 1] + 1;
    } else if (hi == 0x00) {
        if (p + 16 > it->n) return -1;
        out->kind = LMOD_CTL;
        out->flags = b0;
        blen = 16 + mvs_be16(m + p + 4) + mvs_be16(m + p + 6);
        if (b0 & LMOD_CTL_TEXT) it->pending = mvs_be16(m + p + 14);
    } else {
        return -1;
    }
    if (blen <= 0 || p + blen > it->n) { it->pending = 0; return -1; }
    out->len = blen;
    it->p = p + blen;
    return 1;
}

int lmod_cesd_walk(const unsigned char *m, long n,
                   int (*fn)(const struct lmod_esd *e, void *ctx), void *ctx)
{
    long p = 0;
    int id = 0, reported = 0;

    /* The CESD records are the leading ones; the first non-CESD ends the walk. */
    while (p + 8 <= n && (m[p] & 0xf0) == 0x20) {
        long cnt = mvs_be16(m + p + 6), it;
        for (it = 8; it + 16 <= 8 + cnt && p + it + 16 <= n; it += 16) {
            const unsigned char *e = m + p + it;
            struct lmod_esd x;
            x.name = e;
            x.type = e[8];
            x.esdid = ++id;              /* position IS the id, counting from 1 */
            x.addr = mvs_be24(e + 9);
            x.len  = mvs_be24(e + 13);
            reported++;
            if (fn && !fn(&x, ctx)) return reported;
        }
        p += 8 + cnt;
    }
    return reported;
}
