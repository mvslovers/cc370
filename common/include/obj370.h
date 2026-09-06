/* obj370.h -- the OS/360 object-module RECORD layer, shared by the cc370 tools.
 *
 * Companion to mvs370.h.  That header owns the BYTE layer (big-endian access,
 * CP037, the CKD count field, NETDATA framing); this one owns the layer above
 * it: the 80-byte card stream and the ESD / TXT / RLD / END records in it.
 *
 * Scope, deliberately narrow (mvslovers/cc370#109): this is a READER.  It
 * decodes records and locates fields; it never emits a deck and never APPLIES a
 * relocation.  Consumers as370, ld370, ar370 and file370 each carried their own
 * copy of this decoding; cmplmd370 (#110), idrdump370 (#111) and dasm370 (#112)
 * would each have added another.
 *
 * It reproduces exactly what those four already do -- no API is invented for a
 * consumer that does not exist yet.
 */
#ifndef OBJ370_H
#define OBJ370_H

#include "mvs370.h"

/* ---- card stream ----
 * An object deck is a stream of 80-byte cards.  A record card carries 0x02 in
 * column 1 and a three-byte EBCDIC type in columns 2-4.
 */
#define OBJ_CARD_LEN 80

enum obj_card {
    OBJ_OTHER = 0,      /* not one of ours (comment, sequence-only, padding) */
    OBJ_ESD,
    OBJ_TXT,
    OBJ_RLD,
    OBJ_END,
    OBJ_SYM
};

/* Classify one 80-byte card.  `c` must point at OBJ_CARD_LEN readable bytes. */
enum obj_card obj_card_type(const unsigned char *c);

/* ---- ESD ----
 * An ESD card holds up to three 16-byte items at offset 16.  Byte 8 of an item
 * is the type; the low nibble is what every tool actually tests.
 *
 * ESDIDs are assigned to every item EXCEPT LD, which carries none -- an LD's
 * "address" field is its offset within the section named by its owner id.  The
 * iterator below reproduces that numbering, so the id it reports is the one the
 * RLD's R and P point at.
 */
enum {
    OBJ_SD = 0x00,      /* section definition                */
    OBJ_LD = 0x01,      /* label (entry) definition, no ESDID */
    OBJ_ER = 0x02,      /* external reference                */
    OBJ_PC = 0x04,      /* private code (blank-named section) */
    OBJ_CM = 0x05,      /* common                            */
    OBJ_WX = 0x0A       /* weak external reference           */
};

/* Is this a type that OWNS storage (as opposed to referencing it)? */
int obj_is_section(int type);
/* Short mnemonic ("SD", "LD", ...) for a type; "??" if unknown. */
const char *obj_type_name(int type);

struct obj_esd {
    const unsigned char *name;  /* 8 bytes, EBCDIC, blank-padded (not copied) */
    int  type;                  /* low nibble of the type byte */
    int  esdid;                 /* assigned id; 0 for LD, which gets none */
    long addr;                  /* SD/PC/CM: origin.  LD: offset in its owner. */
    long len;                   /* SD/PC/CM: length.  LD: owning section's id. */
};

/* Walk the ESD items of ONE card, in order, assigning ESDIDs from the card's
 * own "id of first item" field (columns 15-16).  Returns the number of items
 * reported.  `fn` may be NULL to count only.  Stops early if `fn` returns 0. */
int obj_esd_walk(const unsigned char *card,
                 int (*fn)(const struct obj_esd *e, void *ctx), void *ctx);

/* ---- TXT ---- */
struct obj_txt {
    long addr;                  /* offset within the section */
    int  esdid;                 /* section this text belongs to */
    long len;                   /* byte count */
    const unsigned char *data;  /* points into the card (not copied) */
};
/* Decode one TXT card.  Returns 1 on success, 0 if `card` is not a TXT card. */
int obj_txt_get(const unsigned char *card, struct obj_txt *t);

/* ---- RLD ----
 * Located, never applied.  `flag` bit 0x01 means "the NEXT item on this card
 * repeats this item's R and P" and so is 4 bytes rather than 8; the walk below
 * resolves that, so a caller sees every item with its R and P filled in.
 *
 * Bits 0x0c hold length-1 of the address constant, which is what a consumer
 * needs in order to ZERO the field without resolving it (cc370#110 --clearrld).
 */
struct obj_rld {
    int  r;                     /* ESDID of the symbol referred to */
    int  p;                     /* ESDID of the section holding the adcon */
    int  flag;                  /* raw flag byte */
    long addr;                  /* offset of the adcon within section P */
};
/* Length in bytes of the address constant an RLD item describes (1..4). */
int obj_rld_len(int flag);

/* Walk the RLD items of ONE card, resolving the continuation bit.  Returns the
 * number reported; `fn` may be NULL to count.  Stops early if `fn` returns 0. */
int obj_rld_walk(const unsigned char *card,
                 int (*fn)(const struct obj_rld *r, void *ctx), void *ctx);

/* ---- END ---- */
struct obj_end {
    int  has_entry;             /* an entry point is named by id + offset */
    int  entry_esdid;
    long entry_addr;
    int  has_len;               /* the END card carries a module length */
    long len;
};
/* Decode one END card.  Returns 1 on success, 0 if `card` is not an END card. */
int obj_end_get(const unsigned char *card, struct obj_end *e);

#endif /* OBJ370_H */
