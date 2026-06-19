# OS/360 Object-Module (OBJ Deck) Format — as370 Reference Spec

**Oracle:** `~/repos/mvs/c2asm370/as/as370.c` — the host-native MVS Assembler-XF (IFOX00) clone, byte-identical to IFOX00 over 950 ecosystem modules.
**Authority rule:** This document describes **what as370 actually emits**. Source code is authoritative; the IBM manual (LY26-3921, Fig. 69–75) is cross-reference only. Where the manual and the source diverge, the source wins and the divergence is flagged. All citations are to `as370.c` line numbers.

All card images are **80-byte EBCDIC** records, written by `fwrite(c, 1, 80, f)`. Every field below is given as **byte offset (0-based)** and **column (1-based)** with fixed hex values where applicable.

---

## 1. General Card Layout

Every object card is built from a buffer initialized to **all EBCDIC blanks (`0x40`)** by `cinit` (`as370.c:1608`), then stamped with a 3-character type by `cname` (`as370.c:1609`).

```c
static void cinit(unsigned char *c){ int i; for(i=0;i<80;i++) c[i]=0x40; }                 // :1608
static void cname(unsigned char *c,const char *n){ c[0]=0x02; c[1]=a2e(n[0]); ... }         // :1609
```

| Offset | Col   | Len | Field             | Value / Meaning                                                              | Source |
|--------|-------|-----|-------------------|------------------------------------------------------------------------------|--------|
| 0      | 1     | 1   | Record identifier | Fixed **`0x02`** (the OS/360 object "loader" punch byte)                     | `:1609` |
| 1–3    | 2–4   | 3   | Card type         | EBCDIC `ESD` / `TXT` / `RLD` / `END` (3 chars, ASCII→EBCDIC via `a2e`)        | `:1609`, `:1637`, `:1664`, `:1680`, `:1703` |
| 4–71   | 5–72  | 68  | Type-specific body| See per-card sections. Unused positions remain blank `0x40`.                | per card |
| 72–79  | 73–80 | 8   | Deck id / sequence| See §1.2. Written by `cseq` (`:1614`).                                        | `:1614–1625` |

> **Byte 0 = `0x02`, not `0x12`/etc.** as370 emits the classic OS/360 object loader byte for every record (ESD/TXT/RLD/END). It is a constant in `cname` — there is no per-type record byte in the object deck (that is a *load-module* concept; do not confuse with the load-module control byte X'01'/X'02' etc.).

### 1.1 Character encoding

Card-type letters, names, and the deck id are translated host-ASCII → EBCDIC by `a2e` / `a2e_tab` (`as370.c:1589–1607`). This is **CP037 + ecosystem NEL** (`\n`→`0x15`), byte-identical to the c2asm370 compiler's `i370_ascii_to_ebcdic` and to the mvsMF upload table, which is why `DC C'...'` text matches what IFOX assembled. Binary fields (addresses, counts, ESD-IDs) are written **big-endian** by `cbe` (`as370.c:1610`):

```c
static void cbe(unsigned char *c,int off,long v,int n){ int i; for(i=n-1;i>=0;i--){ c[off+i]=(unsigned char)(v&0xff); v>>=8; } }   // :1610
```

8-byte EBCDIC name fields (blank-padded, truncated, NUL-stops) are written by `cebc` (`as370.c:1611–1613`).

### 1.2 Columns 73–80 — deck id and sequence (`cseq`, `as370.c:1614–1625`)

`seq` is a **single continuous counter** incremented across *all* card types (ESD, then TXT, then RLD, then END) in one object deck. The layout of cols 73–80 is **conditional** on whether a deck id exists:

- **`deck_id` is set** (the label of the first named `TITLE` statement, captured in pass 1 at `as370.c:1398`):
  - Deck id, **left-justified**, EBCDIC, up to 8 chars at cols 73+.
  - The remaining `8 − len(deck_id)` columns hold the sequence number, **zero-padded right-justified** (`sprintf("%0*ld", nd, seq % 10^nd)`), EBCDIC.
- **No `deck_id`:** cols 73–80 = the 8-digit zero-padded sequence `"%08d"` (EBCDIC).

```c
static char deck_id[9];   // first named TITLE label  (:98, set :1398)
// cseq: deck_id ? [deck_id left | seq right-justified zero-padded] : "%08d" seq   (:1614-1625)
```

### 1.3 Deck record order (`emit_obj`, `as370.c:1632–1708`)

`emit_obj` writes records strictly in this grouped order:

```
1. ESD card(s)   — all ESD entries, 3 per card                (:1635-1649)
2. TXT card(s)   — all text, in pass-2 emission order          (:1651-1673)
3. RLD card(s)   — all relocation items, packed                (:1675-1701)
4. END card      — exactly one                                 (:1703-1707)
```

There is **no SYM card** and **no separate end record** beyond the single END card.

---

## 2. ESD Card (External Symbol Dictionary)

Emitted by the first block of `emit_obj` (`as370.c:1635–1649`). **Up to 3 ESD data items per card** (`n < 3`, each item 16 bytes). Items are emitted in source-declaration order (`esdord[]`, `as370.c:60–62`, `:156–157`).

### 2.1 ESD card header

| Offset | Col   | Len | Field                | Value / Meaning                                                                                  | Source |
|--------|-------|-----|----------------------|--------------------------------------------------------------------------------------------------|--------|
| 0      | 1     | 1   | Record id            | `0x02`                                                                                           | `:1637` |
| 1–3    | 2–4   | 3   | Card type            | EBCDIC `ESD`                                                                                     | `:1637` |
| 4–9    | 5–10  | 6   | (blank)              | `0x40` (left untouched by `cinit`)                                                               | `cinit` |
| 10–11  | 11–12 | 2   | **Byte count of ESD data** | `n × 16` (n = items on this card, 1–3), big-endian                                          | `:1646` |
| 12–13  | 13–14 | 2   | (blank)              | `0x40`                                                                                            | `cinit` |
| 14–15  | 15–16 | 2   | **ESD-ID of first item** | ESD-ID of the first non-LD item on this card (`cardfirst`), big-endian. **Stays blank `0x40` if the card holds only LD items** (LD entries carry no ESD-ID, so `cardfirst` is never set on an LD-only card). | `:1638`,`:1641–1642`,`:1647` |
| 16–63  | 17–64 | 48  | ESD data items       | 1–3 × 16-byte ESD entry (§2.3); unused slots remain blank `0x40`                                 | `:1640–1644` |
| 64–71  | 65–72 | 8   | (blank)              | `0x40`                                                                                            | `cinit` |
| 72–79  | 73–80 | 8   | Deck id / sequence   | §1.2                                                                                             | `:1648` |

### 2.2 ESD-ID assignment (`as370.c:1936–1940`)

After pass 1, ESD-IDs are assigned in `esdord[]` order: **only `ESD_SECT` (SD/PC sections) and `ESD_ER` (external refs, including WXTRN) receive an ESD-ID** (`++id`, starting at 1). **`ESD_LD` entries get no ESD-ID** (`as370.c:1936–1937`). The "main" content section (`main_sect_esdid`) is the first **SD** (`s->type == S_SD`), else the first section of any kind (`as370.c:1938–1940`).

### 2.3 ESD data item (16 bytes) — `esd_ent` (`as370.c:1627–1629`)

```c
static void esd_ent(unsigned char *c,int slot,const char *name,int type,
                    long addr,long sizeOrId,int blankSize){
    cebc(c,slot,name,8);            // bytes 0-7  name
    c[slot+8]=(unsigned char)type;  // byte  8    type
    cbe(c,slot+9,addr,3);           // bytes 9-11 address (binary)
    c[slot+12]=0x40;                // byte  12   ALWAYS blank
    if(blankSize){ c[slot+13]=c[slot+14]=c[slot+15]=0x40; }   // ER/WX: blank
    else cbe(c,slot+13,sizeOrId,3); // bytes 13-15 length or LD's SD-ID
}                                                                  // :1627-1629
```

Item slot for entry *n* on a card is `16 + n*16` (n = 0,1,2), i.e. cols 17, 33, 49.

| Item off | Len | Field          | Value / Meaning                                                                                                                  | Source |
|----------|-----|----------------|----------------------------------------------------------------------------------------------------------------------------------|--------|
| 0–7      | 8   | Name           | EBCDIC symbol name, blank-padded to 8. For an unnamed (PC) section the section symbol's name is empty → 8 blanks (`cebc` NUL-stops to blank). | `:1628` |
| 8        | 1   | **Type**       | One hex byte (see §2.4)                                                                                                           | `:1628`,`:1641–1643` |
| 9–11     | 3   | Address        | 24-bit binary address. SD/PC = section origin (`s->val`); LD = entry value (`s->val`); **ER/WX = `00 00 00`** (binary zero, *not* blank — `addr` arg is 0). | `:1628`,`:1641–1643` |
| 12       | 1   | (reserved)     | **Always blank `0x40`** — as370 never sets this byte                                                                              | `:1628` |
| 13–15    | 3   | Length / SD-ID | SD/PC: control-section **length**; LD: the **ESD-ID of the SD** containing it (`main_sect_esdid`); **ER/WX: blank `0x40`** (`blankSize=1`) | `:1629`,`:1641–1643` |

#### SD/PC length field — exact rule

For an `ESD_SECT` item the length at bytes 13–15 is:

```c
s->esdid == main_sect_esdid ? modlen : 0      // :1641
```

i.e. **only the main content section carries the module length (`modlen`); every other SD/PC section emits length `0`** (its length is then supplied on the END record / by the linkage editor). `modlen` is the **high-water mark of all emitted text and reserved space** (`:288`, `:1433`, `:1528`, `:1577`), not the per-section length. This is the literal conditional — do not generalize it to "the section's own length."

### 2.4 ESD type codes

**Types as370 actually emits** (authoritative — `as370.c:1641–1643`):

| Type | Hex (byte 8) | Meaning                          | Emitted by                                                                 |
|------|--------------|----------------------------------|----------------------------------------------------------------------------|
| SD   | `0x00`       | Section Definition (named CSECT) | `role==ESD_SECT && type!=S_PC` → `esd_ent(...,0x00,...)` `:1641`            |
| PC   | `0x04`       | Private Code (unnamed CSECT)     | `role==ESD_SECT && type==S_PC` → `esd_ent(...,0x04,...)` `:1641`            |
| LD   | `0x01`       | Label Definition (ENTRY)         | `role==ESD_LD` → `esd_ent(...,0x01,...)` `:1643`                            |
| ER   | `0x02`       | External Reference (EXTRN / =V)  | `role==ESD_ER && !is_weak` → `esd_ent(...,0x02,...,blankSize=1)` `:1642`    |
| WX   | `0x0A`       | Weak External Reference (WXTRN)  | `role==ESD_ER && is_weak` → `esd_ent(...,0x0a,...,blankSize=1)` `:1642`     |

**Types the OBJ format defines but as370 does NOT emit** (manual cross-reference only — Fig. 70 of LY26-3921):

| Type | Hex  | Meaning            | Status in as370 |
|------|------|--------------------|-----------------|
| CM   | `0x05` | Common section     | Not emitted     |
| PR   | `0x06` | Pseudo-register    | Not emitted     |
| Null | `0x07` | Null entry         | Not emitted     |

> **Note (object LD ≠ load-module LR):** in the *object* deck the entry-point type byte is **`0x01` (LD)**. The linkage editor later folds it into a composite **LR (`0x03`)** in the *load-module CESD* — that `0x03` belongs to the load-module spec, not here.

> **DFP manual divergence (byte 12):** Fig. 70 of LY26-3921 annotates ESD byte 12 as "AMODE/RMODE/RSECT data (SD/PC)" and an alignment/PR-length pair. Those are **DFP `5665-295`** features. The MVS 3.8j F-level target is 24-bit only, and **as370 unconditionally writes byte 12 = blank `0x40`** (`as370.c:1628`). Do not emit or expect AMODE/RMODE/RSECT bits, PR alignment factors, or PR length here.

---

## 3. TXT Card (Text / Object Code)

Emitted by the TXT block of `emit_obj` (`as370.c:1651–1673`). as370 replays the pass-2 emission log (`txl_*`, `as370.c:83–87`, `:276–286`) the way IFOX's PUNRTN does: bytes accumulate into a 56-byte card and a new card is cut whenever the next byte's address is not contiguous (a gap or an ORG overlay) or the card fills. **Max 56 text bytes per card** (cols 17–72).

| Offset | Col   | Len | Field                 | Value / Meaning                                                                | Source |
|--------|-------|-----|-----------------------|--------------------------------------------------------------------------------|--------|
| 0      | 1     | 1   | Record id             | `0x02`                                                                          | `:1664` |
| 1–3    | 2–4   | 3   | Card type             | EBCDIC `TXT`                                                                    | `:1664` |
| 4      | 5     | 1   | (blank)               | `0x40`                                                                          | `cinit` |
| 5–7    | 6–8   | 3   | **Text load address** | 24-bit binary address of the first text byte on this card (`cstart`), BE       | `:1664` |
| 8–9    | 9–10  | 2   | (blank)               | `0x40`                                                                          | `cinit` |
| 10–11  | 11–12 | 2   | **Byte count**        | Number of text bytes on this card (`cn`, 1–56), big-endian                     | `:1664` |
| 12–13  | 13–14 | 2   | (blank)               | `0x40`                                                                          | `cinit` |
| 14–15  | 15–16 | 2   | **ESD-ID**            | ESD-ID of the SD/PC control section owning this text — always `main_sect_esdid`, BE | `:1664` |
| 16–71  | 17–72 | ≤56 | **Text bytes**        | Raw object code / data bytes (`cbuf`)                                          | `:1665` |
| 72–79  | 73–80 | 8   | Deck id / sequence    | §1.2                                                                            | `:1666` |

```c
cinit(c); cname(c,"TXT");
cbe(c,5,cstart,3);          // load address  (cols 6-8)
cbe(c,10,cn,2);             // byte count     (cols 11-12)
cbe(c,14,main_sect_esdid,2);// ESD-ID         (cols 15-16)
for(i=0;i<cn;i++) c[16+i]=cbuf[i];   // text   (col 17+)            // :1664-1665
```

> A backward `ORG` overlay re-punches the overlaid bytes as a fresh, address-overlapping TXT card carrying the pre-overwrite content, byte-for-byte as IFOX does (`as370.c:1651–1655`, `put`/`txl_*` `:276–286`).

---

## 4. RLD Card (Relocation Dictionary)

Emitted by the RLD block of `emit_obj` (`as370.c:1675–1701`). Items are first sorted by (P-pointer `pos`, R-pointer `rel`) so identical-(R,P) items are adjacent for continuation packing (`as370.c:1676–1678`). RLD data occupies cols 17–72; the loop breaks (cuts a card) when the next item would pass offset 72 (`off + need > 72`, `as370.c:1688`).

### 4.1 RLD card header

| Offset | Col   | Len | Field                 | Value / Meaning                                                       | Source |
|--------|-------|-----|-----------------------|-----------------------------------------------------------------------|--------|
| 0      | 1     | 1   | Record id             | `0x02`                                                                | `:1680` |
| 1–3    | 2–4   | 3   | Card type             | EBCDIC `RLD`                                                          | `:1680` |
| 4–9    | 5–10  | 6   | (blank)               | `0x40`                                                                | `cinit` |
| 10–11  | 11–12 | 2   | **Byte count of RLD data** | `off − 16` = bytes of RLD items on this card, big-endian          | `:1700` |
| 12–15  | 13–16 | 4   | (blank)               | `0x40`                                                                | `cinit` |
| 16–71  | 17–72 | ≤56 | **RLD items**         | Sequence of 8-byte and/or 4-byte items (§4.2)                        | `:1681–1699` |
| 72–79  | 73–80 | 8   | Deck id / sequence    | §1.2                                                                  | `:1700` |

### 4.2 RLD item

There are two physical forms. The **full (leader) item is 8 bytes**; a **continuation item that reuses the previous R&P is 4 bytes** (`need = reuse ? 4 : 8`, `as370.c:1687`). The first item on every card is always a full 8-byte leader (`reuse` requires `off > 16`, `as370.c:1686`), so a same-(R,P) group that spans a card boundary re-emits R/P automatically.

**Full item (8 bytes):**

| Item off | Len | Field         | Value / Meaning                                                            | Source |
|----------|-----|---------------|----------------------------------------------------------------------------|--------|
| 0–1      | 2   | **R pointer** | ESD-ID of the symbol referenced in the adcon's value (`rels[k].rel`), BE   | `:1694` |
| 2–3      | 2   | **P pointer** | ESD-ID of the SD containing the adcon (`rels[k].pos`), BE                   | `:1694` |
| 4        | 1   | **Flag byte** | See §4.3                                                                    | `:1695` |
| 5–7      | 3   | **Address**   | 24-bit address of the adcon within its CSECT (`rels[k].addr`), BE          | `:1695` |

**Continuation item (4 bytes)** — only when `rel`/`pos` equal the predecessor's on the same card:

| Item off | Len | Field         | Value / Meaning                            | Source |
|----------|-----|---------------|--------------------------------------------|--------|
| 0        | 1   | **Flag byte** | See §4.3 (no R/P precede it)               | `:1691` |
| 1–3      | 3   | **Address**   | 24-bit adcon address, BE                   | `:1691` |

When a continuation follows, the **predecessor's flag byte** has the same-R&P bit `0x01` OR'd in (`c[prevflag] |= 0x01`, `as370.c:1690`), signalling "the next item omits R/P."

### 4.3 RLD flag byte — bit layout

The flag byte is built as `(isV ? 0x10 : 0) | (((len-1) & 3) << 2)`, with the continuation bit `0x01` set on the *predecessor* (`as370.c:1691`, `:1695`, `:1690`).

| Bits (mask) | Field            | Meaning                                                                                                   | as370 behavior |
|-------------|------------------|-----------------------------------------------------------------------------------------------------------|----------------|
| `0x10`      | Adcon **type**   | `0` = A-type (`DC A`, nonbranch); `1` = V-type (`DC V`, branch external)                                  | Set from `rels[k].isV` `:1691`,`:1695` |
| `0x0C`      | **Length** (LL)  | `((len−1)&3)<<2`: `00`→1 byte, `01`→2 bytes, `10`→3 bytes, `11`→4 bytes of adcon                           | **Variable** — depends on the adcon width (see below) |
| `0x02`      | Sign (negative)  | `1` = negative relocation                                                                                  | **Never set** by as370 |
| `0x01`      | Same R&P (cont.) | `1` ⇒ the **next** item omits R/P (is a 4-byte continuation)                                               | Set on predecessor `:1690` |

#### Length field is VARIABLE, not fixed

The relocation length (`rels[k].len`) defaults to **4** in `add_reloc` (`as370.c:500`) but is **overridden by every caller to match the actual adcon width** (5 override sites):

- **3 bytes** — CCW second operand / `AL3`-style adcon (`rels[nrel-1].len = 3`, `as370.c:1441`) → LL bits `10` → flag nibble `0x08`.
- **`per`** (literal element width, `=V`/`=A`/`=Y` and value lists like `=AL2(...)`) — `as370.c:1267`, `:1272`. A `=AL2` literal gives `len=2` → LL `01` → `0x04`; a `=Y` (2-byte) likewise; a 4-byte `=V`/`=A` → `0x0C`.
- **`blen`** (inline `DC` element width, e.g. `DC AL2(...)`, `DC A(...)`, `DC V(...)`) — `as370.c:1484`, `:1488`.

So the LL field genuinely varies with adcon width. The flag bytes as370 can emit (per `(isV?0x10:0) | (((len-1)&3)<<2) | optional 0x01`) include, for example:

| `len` | A-type flag | V-type flag | + continuation (`0x01`) |
|-------|-------------|-------------|--------------------------|
| 2     | `0x04`      | `0x14`      | `0x05` / `0x15`          |
| 3     | `0x08`      | `0x18`      | `0x09` / `0x19`          |
| 4     | `0x0C`      | `0x1C`      | `0x0D` / `0x1D`          |

(`len==1` would give `0x00`/`0x10`, though a 1-byte relocatable adcon is not produced by normal C output.) Sign bit `0x02` is never set by as370.

> The manual (Fig. 72) and the load-module RLD decoder define additional type encodings (PR displacement `0010`, PR cumulative/CXD `0011`, unresolved `1000`/`1001`) and use the high three bits as a "must-be-zero-to-relocate" field. **as370 emits none of those** — it produces only A and V adcons (`isV` 0/1), of lengths 2/3/4, never negative.

---

## 5. END Card

Emitted as exactly one card at the tail of `emit_obj` (`as370.c:1703–1707`). as370 produces an **END Type 1** record (entry point given as address + ESD-ID). It never produces an END Type 2 (symbolic entry-point name).

```c
cinit(c); cname(c,"END");
if(end_has){ cbe(c,5,end_addr,3); cbe(c,14,end_esdid,2); }     // :1703
// IDR (cols 33-52):
julian5(g_sysdate,jul);
snprintf(idr,"%-10.10s %-4.4s%5.5s", AS370_IDR_PROD, AS370_IDR_VER, jul);
cebc(c,32,idr,20);                                             // :1704-1706
```

| Offset | Col   | Len | Field                 | Value / Meaning                                                                              | Source |
|--------|-------|-----|-----------------------|----------------------------------------------------------------------------------------------|--------|
| 0      | 1     | 1   | Record id             | `0x02`                                                                                        | `:1703` |
| 1–3    | 2–4   | 3   | Card type             | EBCDIC `END`                                                                                  | `:1703` |
| 4      | 5     | 1   | (blank)               | `0x40`                                                                                        | `cinit` |
| 5–7    | 6–8   | 3   | **Entry-point addr**  | 24-bit binary entry address (`end_addr`), BE. **Present only if `end_has`** (an `END expr` was coded); otherwise blank `0x40`. | `:1703`,`:1537–1539` |
| 8–13   | 9–14  | 6   | (blank)               | `0x40`                                                                                        | `cinit` |
| 14–15  | 15–16 | 2   | **Entry-point ESD-ID**| ESD-ID of the SD containing the entry point (`end_esdid`), BE. Present only if `end_has`. `end_esdid = s->esdid ? s->esdid : main_sect_esdid`. | `:1703`,`:1539` |
| 16–31  | 17–32 | 16  | (blank)               | `0x40`                                                                                        | `cinit` |
| 32–51  | 33–52 | 20  | **IDR data**          | Translator-identification block (§5.1). Always present.                                       | `:1704–1706` |
| 52–71  | 53–72 | 20  | (blank)               | `0x40`                                                                                        | `cinit` |
| 72–79  | 73–80 | 8   | Deck id / sequence    | §1.2                                                                                          | `:1707` |

**Entry point determination** (`as370.c:1537–1539`): `END symbol` sets `end_has=1`; in pass 2 `end_addr = sym->val` and `end_esdid = sym->esdid` (falling back to `main_sect_esdid` if the entry symbol has no ESD-ID). A bare `END` with no operand leaves cols 6–8 and 15–16 blank.

### 5.1 IDR block (cols 33–52) — `as370.c:1704–1706`

The 20-byte IDR is `"%-10.10s %-4.4s%5.5s"` of:

| Sub-offset (within IDR) | Col   | Len | Field             | Value (as370)                                  | Source |
|-------------------------|-------|-----|-------------------|------------------------------------------------|--------|
| 0–9                     | 33–42 | 10  | Translator product id | `ASM370` (`AS370_IDR_PROD`), left-justified, blank-padded to 10 | `:110`,`:1705` |
| 10                      | 43    | 1   | (space)           | EBCDIC blank                                   | `:1705` |
| 11–14                   | 44–47 | 4   | Version            | `0100` (= V01.00; `AS370_IDR_VER`)             | `:111`,`:1705` |
| 15–19                   | 48–52 | 5   | Julian date        | `YYDDD` from `g_sysdate` via `julian5` (`:113–121`) | `:1704–1706` |

> **END Type 2 (manual cross-reference, NOT emitted):** Fig. 74 of LY26-3921 defines a Type-2 END card carrying a symbolic entry-point name (cols 6–13) and a control-section length. as370 emits only Type 1; it supplies the entry by ESD-ID + address.

---

## 6. SYM Card

**as370 emits no SYM card.** `emit_obj` (`as370.c:1632–1708`) calls `cname` with only `"ESD"`, `"TXT"`, `"RLD"`, and `"END"` — there is no `cname(c,"SYM")` anywhere in the source (verified). (SYM/TESTRAN records exist in the OBJ format and the load-module format, but as370 does not produce them.)

---

## 7. Non-Reproducible / Carve-Outs

"**Byte-identical to IFOX00**" for as370 means the **ESD, TXT, and RLD records reproduce exactly** (verified over 950 ecosystem modules). The following are deliberate, documented exceptions:

1. **END-record IDR (cols 33–52) — intentionally NOT IFOX's.** as370 stamps its **own** translator identity `ASM370 / 0100` (`AS370_IDR_PROD`/`AS370_IDR_VER`, `as370.c:110–111`, `:1704–1706`) rather than masquerading as IFOX's `15741SC103`. So the END card's IDR field is *expected to differ* from IFOX byte-for-byte; the deck identifies itself. Byte-identity to IFOX excludes this field.

2. **Julian date within the IDR (cols 48–52) — run-to-run variable.** `julian5(g_sysdate, ...)` derives `YYDDD` from the assembly date (`as370.c:1704`, `:113–121`). By default this is the host clock. For reproducible/verifiable builds, `g_sysdate`/`g_systime` are overridable via the **`ASMDATE` / `ASMTIME`** environment variables (`init_sysvars`, `as370.c:124–134`), which pins the IDR date to a fixed value.

3. **cols 73–80 sequence/deck-id** are deterministic given the same source (the `seq` counter and the first-`TITLE` `deck_id`), so they reproduce — but note they depend on card *count and order*, which a different assembler's card-cutting would change.

---

## 8. Manual (DFP) vs. F-level / as370 Divergences

The IBM manual LY26-3921 (`/tmp/lel_logic.txt`, Fig. 69–75) documents the **DFP `5665-295`** linkage editor — a later, 24/31-bit product. The MVS 3.8j target and as370 are **24-bit only**. Divergences relevant to the object deck:

| Topic | Manual (DFP, Fig.) | as370 / F-level (authoritative) |
|-------|--------------------|----------------------------------|
| ESD item byte 12 | "AMODE/RMODE/RSECT data (SD/PC)"; PR alignment factor | **Always blank `0x40`** (`as370.c:1628`). No AMODE/RMODE/RSECT, no PR alignment. |
| ESD types | Lists SD/LD/ER/PC/CM/PR/WX (and Null) | as370 emits only SD `0x00`, LD `0x01`, ER `0x02`, PC `0x04`, WX `0x0A` (`:1641–1643`). CM `0x05`/PR `0x06`/Null `0x07` defined but not emitted. |
| RLD flag types | A/V/PR-disp/PR-cumulative/unresolved; variable length & sign | as370 emits A and V only (`isV` 0/1), length **2/3/4 matching the adcon width** (`:500` default 4, overridden at `:1267`,`:1272`,`:1441`,`:1484`,`:1488`), never negative. |
| END record | Type 1 (addr+ESD-ID) and Type 2 (symbolic name) | as370 emits **Type 1 only** (`:1703`). |
| IDR | "Translator identification — PID order number" | as370 stamps its own `ASM370`/`0100`/Julian (`:1704–1706`); not an IBM PID. |

The type codes themselves (`SD=00, LD=01, ER=02, PC=04, CM=05, PR=06, WX=0A`) and the RLD R/P pointer semantics (R = ESD-ID of referenced symbol, P = ESD-ID of SD containing the adcon) **agree** between the manual (Fig. 70, Fig. 72) and the source — those parts of the manual are reliable cross-reference. Note: the RLD **length** encoding (LL = `((len-1)&3)<<2`) also agrees with the manual's `01`→2 / `10`→3 / `11`→4 convention; the draft error was claiming as370 *only ever* emits length 4, which it does not.

---

### Source-file map
- OBJ writer / card emission: `as370.c:1585–1708` (`cinit` `:1608`, `cname` `:1609`, `cbe` `:1610`, `cebc` `:1611`, `cseq` `:1614`, `esd_ent` `:1627`, `emit_obj` `:1632`).
- ESD-ID assignment & main section: `as370.c:1936–1940`.
- END / entry / IDR identity: `as370.c:1537–1539`, `:96`, `:108–121`, `:124–134`, `:1703–1707`.
- Relocation recording (default len 4, overridden per adcon width): `add_reloc` `as370.c:495–501`; overrides `:1267`, `:1272`, `:1441`, `:1484`, `:1488`.
- `reloc` struct (`int ... len`): `as370.c:69`.
- `modlen` high-water mark: `as370.c:88`, `:288`, `:1433`, `:1528`, `:1577`.
- EBCDIC table (CP037 + NEL): `as370.c:1589–1607`.
