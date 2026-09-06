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

int obj_rld_walk(const unsigned char *card,
                 int (*fn)(const struct obj_rld *r, void *ctx), void *ctx)
{
    int cnt, p = 16, end, r = 0, pp = 0, same = 0, n = 0;

    if (obj_card_type(card) != OBJ_RLD) return 0;
    cnt = mvs_be16(card + 10);
    end = 16 + cnt;
    if (end > OBJ_CARD_LEN) end = OBJ_CARD_LEN;
    while (p + 4 <= end) {
        struct obj_rld it;
        /* R and P are present only on the first item of a run; the previous
         * item's flag bit 0x01 says the next one repeats them. */
        if (!same) { r = mvs_be16(card + p); pp = mvs_be16(card + p + 2); p += 4; }
        if (p + 4 > end) break;
        it.r = r; it.p = pp;
        it.flag = card[p];
        it.addr = mvs_be24(card + p + 1);
        same = card[p] & 0x01;
        p += 4;
        n++;
        if (fn && !fn(&it, ctx)) break;
    }
    return n;
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
