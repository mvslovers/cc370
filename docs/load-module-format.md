# MVS 3.8j F-Level Load-Module Format — Reference for the host-native `ld`

**Target product:** OS/VS2 MVS 3.8j **F-level linkage editor, `5752-SC104`** (the HEWL source; IDR component-name byte string is `5752SC104`, no hyphen — `HEWLFOUT.ASM:1438`). This is **not** the DFP `5665-295` editor documented in LY26-3921; 24-bit addressing only, no AMODE/RMODE/RSECT.

**Authority rule:** the HEWL/IEWFETCH source is authoritative. The manual (LY26-3921, OCR at `/tmp/lel_logic.txt`) is a cross-reference only; divergences are flagged in §13. Every field below is cited to a source line (`FILE:line`), files under `~/repos/MVSSRC/Dave Kreiss - MVS from Source/MVSBLD/` unless noted.

---

## 1. Data set / DCB and blocking

A load module is a member of a partitioned data set (PDS).

| Attribute | Value | Source |
|---|---|---|
| DDNAME (output) | `SYSLMOD` | linkage-editor output DD (briefing baseline) |
| DSORG | `PO` (partitioned) | `IHAPDS` (PDS directory) |
| RECFM | `U` (undefined) | one physical record per `WRITE SF` (`HEWLFSYM.ASM`, `HEWLFOUT.ASM` write subroutine) |
| LRECL | none (RECFM=U) | n/a |
| KEY | none | records are keyless |
| BLKSIZE | device track geometry, taken at OPEN | reader rebuilds CCWs from device; writer uses BSAM `WRITE SF` |

Each logical record = one BSAM block = one `WRITE SF`. The first byte of every record is the **record-type indicator** (§3). The **control record** carries the read-CCW (command + address + count) for the **text record** that follows it (`HEWLFSCD.ASM:99-102`).

---

## 2. Record order within a member

1. **SYM record(s)** — only if TEST attribute present (`HEWLFSYM.ASM`); normally absent for NCAL/production links.
2. **CESD record(s)** — composite ESD (`HEWLFOUT.ASM:296-337`).
3. **IDR record(s)** — CSECT identification (`IDROUT`, `HEWLFOUT.ASM:993-1450`, written after the last CESD line).
4. **(overlay only)** SEGTAB control record + SEGTAB text record.
5. **(scatter only)** scatter/translation record(s) (`HEWLFOUT.ASM:840-984`).
6. **repeating:** `{ control record ; text record ; RLD record(s) }` (`HEWLFSCD.ASM`).

**No separate end-of-module record.** The last control/RLD record carries `MODEND X'08'` in byte 0 (`HEWLFSCD.ASM:204`); the last IDR carries `LASTIDR X'80'` OR'd into its **subtype byte** (`HEWLFOUT.ASM:195,1155`); the last CESD record (when there is no following text) carries `LASTESD X'08'` (`HEWLFOUT.ASM:216,309`).

---

## 3. Record identification — byte 0

Two EQU sets define byte 0. Writer (`HEWLFSCD.ASM:204-208`): `MODEND=X'08'`, `SEGEND=X'04'`, `RLD=X'02'`, `TXT=X'01'`. Reader (`IEWFETCH.ASM:209-211,227`): `CTLFLG=X'01'`, `RLDFLG=X'02'`, `ENDFLG=X'04'`, and `TSTBITS=X'F0'` — **the high nibble must be zero** for control/RLD/text records, else the record type is invalid (RC `RCBADREC=X'0D'`, `IEWFETCH.ASM:236`). Because CESD/IDR/SYM/scatter records have a non-zero high nibble in byte 0 (X'20'/X'80'/X'40'/X'10'), they are unambiguously distinct from the control/RLD/text stream.

| byte 0 | record | source |
|---|---|---|
| `X'40'` | SYM record | `HEWLFSYM.ASM:78` `SYMCTL EQU X'40'`; `:122` `MVI 0(BUFFADD),SYMCTL` |
| `X'20'` | CESD record | `HEWLFOUT.ASM:180` `CESDCNTL EQU X'20'`; `:314` `OI 8(CESDADD),CESDCNTL` |
| `X'28'` | last CESD in module (`X'20'+X'08'`) | `HEWLFOUT.ASM:216` `LASTESD X'08'`; `:309` |
| `X'10'` | scatter/translation record | `HEWLFOUT.ASM:974` `MVI 0(SCATTADD),X'10'` |
| `X'80'` | IDR / CSECT-identification record (byte 0 of every IDR header) | `HEWLFOUT.ASM:1434` `IDRZHDR DC X'80FA0100'`; `:1437` `LKIDR DC X'801102'` |
| `X'01'` | control record, **text follows** (no RLDs) | `HEWLFSCD.ASM:75` |
| `X'02'` | control record, **RLDs only** (no text) | `HEWLFSCD.ASM:76` |
| `X'03'` | control record, **RLDs present + text follows** | `HEWLFSCD.ASM:77-78` |
| `X'05'` | as `01`, **last control rec of segment** (`+SEGEND X'04'`) | `HEWLFSCD.ASM:79-80` |
| `X'06'` | as `02`, last of segment (RLDs only, no text) | `HEWLFSCD.ASM:81-82` |
| `X'07'` | as `03`, last of segment (RLDs + text) | `HEWLFSCD.ASM:83-84` |
| `X'0D'` | as `01`, **last of segment AND module** (`+MODEND X'08'+SEGEND X'04'`) | `HEWLFSCD.ASM:85-87` |
| `X'0E'` | as `02`, last of segment and module (RLDs only) | `HEWLFSCD.ASM:88-90` |
| `X'0F'` | as `03`, last of segment and module (RLDs + text) | `HEWLFSCD.ASM:91-92` |

A module-end record is always also a segment-end (`X'0?'` = `MODEND(08) | SEGEND(04)` together). For a non-overlay module there is one segment, so the last record is `X'0D'/X'0E'/X'0F'`.

---

## 4. Control record (16-byte header)

Verified against the `HEWLFSCD.ASM:74-106` prologue **and** the literal single-byte-text control-record template `BYTCTRRD` at `HEWLFSCD.ASM:1056-1070`, which sets each byte explicitly.

| off | len | hex (1-CSECT example) | field | source |
|---|---|---|---|---|
| 0 | 1 | `01` | control indicators (§3 table) | `HEWLFSCD.ASM:75-92`; template `:1059` (`DC X'01'`) |
| 1–3 | 3 | `00 00 00` | zeros | `HEWLFSCD.ASM:93` |
| 4–5 | 2 | `00 04` | **count of ID/length-list bytes** in this record = 4 × (#CSECTs in following text). **Zero** for control indicators `02`,`06`,`0E` (RLD-only). | `HEWLFSCD.ASM:94-96`; template byte 5 = `X'04'` at `:1061` |
| 6–7 | 2 | `00 00` | **count of RLD-info bytes** in this record (=0 here; nonzero on `02/03/06/07/0E/0F`). | `HEWLFSCD.ASM:97-98`; reader `RLDLEN EQU 6` (`IEWFETCH.ASM:215`) |
| 8–15 | 8 | (CCW) | **read CCW for program fetch** — see breakdown below | `HEWLFSCD.ASM:99-102`; `IEWFETCH.ASM:212` `CTLCCW EQU 8` |
| 16… | 4·n | per CSECT | **ID/length list**: for each CSECT in the following text, a 2-byte CESD-ID + 2-byte CSECT length | `HEWLFSCD.ASM:94`; template `BYTCTRRD+16` (ID-length area), byte 19 = `X'01'` length low byte at `:1069` |

**Bytes 8–15 are a standard 8-byte CCW** (`cmd(1) + addr(3) + flags(1) + rsvd(1) + count(2)`), built so program fetch reads the following text directly:

| off | len | hex | field | source |
|---|---|---|---|---|
| 8 | 1 | `06` | read command = `READOP X'06'` (read-data) | template `:1063` (`DC X'06'`); `IEWFETCH.ASM:263` `READOP EQU X'06'` |
| 9–11 | 3 | LE-assigned text origin | data address of the text record that follows | `HEWLFSCD.ASM:99-100`; `IEWFETCH.ASM:271` `RDCT1AD EQU 9` |
| 12 | 1 | `40` | CCW flags — `CMCH X'40'` (command chain) | template `:1065` (`DC X'40'`); `IEWFETCH.ASM:260` `CCWFLG EQU 4` (flag offset within CCW), `:266` `CMCH EQU X'40'`, `:273` `RDCT1FL EQU 12` |
| 13 | 1 | `00` | reserved (CCW) | (CCW byte) |
| 14–15 | 2 | text length | byte count of the following text record (the CCW count) | template byte 15 = `X'01'` at `:1067`; `HEWLFSCD.ASM:101-102` |

The prologue describes bytes 8–11 as "READ BITS AND ... ASSIGNED ADDRESS" and bytes 12–15 as "FLAGS AND ... LENGTH" — i.e. an 8-byte CCW spanning both halfwords; the template confirms the read-cmd at byte 8, flags at byte 12, length (CCW count) at bytes 14–15.

For control indicators `02`,`06`,`0E` (RLD-only, no text), **bytes 8–15 are zero** (`HEWLFSCD.ASM:103-106`).

The reader rebuilds its read channel program from these fields (`IEWFETCH.ASM:269` `CPRDRLD EQU 16` = offset of read-RLD CCW; `:212` `CTLCCW EQU 8`). The prologue NOTES warn: any change to CCW format changes control-record formatting.

---

## 5. Text record

A text record immediately follows its control record (when byte 0 has `TXT X'01'`). It is **pure CSECT text** — no header of its own. Its length and load address are given entirely by the preceding control record (CCW address at off 9–11 = origin, CCW count at off 14–15 = length) (`HEWLFSCD.ASM:103-106`; template `TXTBYT` at `:1070` is a one-byte text record). The ID/length list in the control record (off 16…) tells the loader which CESD-ID owns each span of bytes within the text record so adcons can be relocated CSECT-relative.

---

## 6. RLD record, RLD item, and the flag byte

### 6.1 RLD record

An RLD record (byte 0 has `RLDFLG X'02'`) shares the 16-byte control header. Relevant fields: byte 0 = indicators; offset 6–7 = **RLD byte count** (`RLDLEN EQU 6`, `IEWFETCH.ASM:215`); RLD data begins at **offset 16** (`RLDATA EQU 16`, `IEWFETCH.ASM:213`). An RLD-only record (`02/06/0E`) has zero ID-length count and a zero CCW (§4).

Reader scan loop (`IEWFETCH.ASM:3448-3457`): `LA R13,RLDATA(R1)`, `AH R0,RLDLEN(R1)` to find the end, iterating in increments of 4 (`LA R12,4`).

### 6.2 RLD item layout

`R-pointer (2) + P-pointer (2) + flag (1) + address (3)`.

| off | len | field | meaning | source |
|---|---|---|---|---|
| 0 | 2 | **R-pointer** | CESD-ID of the symbol the adcon's value depends on (the *relocation* pointer) | `IEWFETCH.ASM:3493-3497`; `HEWLFREL` PREVRPAD |
| 2 | 2 | **P-pointer** | CESD-ID of the CSECT that **contains** the adcon (the *position* pointer) | as above |
| 4 | 1 | **flag byte** | see §6.3 | `IEWFETCH.ASM:3470-3504` |
| 5 | 3 | **address** | offset of the adcon within the module (P-relative) | `IEWFETCH.ASM:3472` `ICM R9,ADDR,1(R13)` (3-byte address at flag+1) |

The item is 8 bytes (full R&P + flag + address); a *continuation* item that reuses the previous R&P is **4 bytes** (flag + address only), flagged by bit 7 of the **preceding** item (§6.3, `SAMERP`).

### 6.3 Flag byte — full bit breakdown (CORRECTED)

The on-disk RLD flag byte has the layout **`TTTT LL S Tn`** (manual Fig.16/27 `(TTTTLLST)`, OCR lines 3629-3645 & 5380-5400; confirmed by the as370 OBJ oracle and the IEWFETCH decode). Bit numbering 0 (MSB) … 7 (LSB):

| bits | mask | name | meaning | source |
|---|---|---|---|---|
| 0–3 | `X'F0'` (RELREQ=`X'E0'` within it) | **TTTT — adcon type** | `0000`=A (DC A / nonbranch); `0001`=V (DC V / branch, bit `X'10'`); `0010`=PR type 1 (displacement); `0011`=PR type 2 (cumulative length / CXD). High bit `X'80'` set ⇒ **unresolved** (`1000`=A, `1001`=V) → do NOT relocate. | manual Fig.16 `3629-3645`, Fig.27 `5380-5400`; `as370.c:1696` (V-bit = `0x10`); `IEWFETCH.ASM:217` `RELREQ EQU X'E0'` |
| 0–2 | `X'E0'` | **RELREQ** | must be **all zero** for the loader to relocate. `IEWFETCH:3470` `TM 0(R13),RELREQ / BCR 7,...` skips relocation if any bit set. | `IEWFETCH.ASM:217,3470` |
| 4–5 | `X'0C'` | **LL — adcon length = (length − 1)** | `01`(`X'04'`)→**2 bytes**; `10`(`X'08'`)→**3 bytes**; `11`(`X'0C'`)→**4 bytes**. Emit `((len−1)&3)<<2`. Reader: `NI 0(R13),ADCLEN`(`X'0F'`), `IC`, `SRL R10,2`, index `BITMSK={00,03,07,0F}` → ICM mask for 0/2/3/4 bytes. | `as370.c:1694,1696` `((len-1)&3)<<2`; `IEWFETCH.ASM:221,3478-3504` (`ADCLEN X'0F'`, `BITMSK`); manual `11=4 bytes` |
| 6 | `X'02'` | **S / RELNEG** | sign of relocation: 1 ⇒ subtract the relocation factor (negative relocation). | `IEWFETCH.ASM:223` `RELNEG EQU X'02'`; `:3487` `TM 0(R13),RELNEG` |
| 7 | `X'01'` | **Tn / SAMERP** | 1 ⇒ the next RLD item has the **same R&P pointers**; it is encoded as flag+address only (4 bytes), no new R&P pair. | `IEWFETCH.ASM:224` `SAMERP EQU X'01'`; `:3493-3497` |

Loader algorithm (`IEWFETCH.ASM:3467-3502`): for each item, if `(flag & RELREQ)==0`: load the adcon (width per LL via `BITMSK`), add or subtract the module relocation factor (bit 6), store it back; bounds-checked against module start/end (`XSOMAD`/`XEOMAD`). If `(flag & SAMERP)`, the next 4 bytes are another flag+address for the same R&P; else advance past a new 4-byte R&P pair.

> **Why the length encoding is off-by-one-from-the-naive-reading:** LL = **length−1**. A resolved 4-byte A-con flag = `X'0C'`; a resolved 4-byte V-con (`DC V(x)`) flag = `X'10' | X'0C'` = `X'1C'`; a resolved 3-byte A-con (AL3 address) flag = `X'08'`; a resolved 2-byte adcon = `X'04'`. Get this wrong and program fetch loads the wrong number of bytes.

> **Internal vs on-disk flag bits — do NOT copy the editor's working bits into output.** `HEWLFREL.ASM` manipulates an *internal* RLD-set representation during pass 2 with its own working bits: `UNRESER EQU X'80'` (`:120`), `PROC EQU X'40'` (`:122`), `CONT EQU X'01'` (`:124`), `RELREL EQU X'7F'` (`:126`), and length tests at `:312` (`TM X'04'`) / `:317` (`TM X'08'`) that operate on that internal layout — they are **not** the on-disk byte. The authoritative on-disk encoding is the as370/IFOX object form (`((len-1)&3)<<2` for LL, `X'10'` for V) that IEWFETCH decodes via `BITMSK`. Emit `RELREQ`=0 (TTTT `0000`/`0001`) for ordinary resolved A/V adcons.

---

## 7. CESD record (composite ESD)

### 7.1 Record header

Written by `HEWLFOUT.ASM:296-337` (`OUT00200`). The writer addresses the record through `CESDADD`, whose record data begins at `CESDADD+8`. Up to **15** composite entries per record (`LA FIFTEEN,15`, `:302`).

| off | len | hex | field | source |
|---|---|---|---|---|
| 0 | 1 | `20` | `CESDCNTL X'20'`; `+X'08'` (`X'28'`) if last ESD record of module | `HEWLFOUT.ASM:180,314`; last via `LASTESD X'08'` `:216,309` |
| 1–3 | 3 | `00 00 00` | spare zeros (high word zeroed) | `HEWLFOUT.ASM:303` `XC 8(4,CESDADD),8(CESDADD)` |
| 4–5 | 2 | ESD-ID | CESD-ID of **first** entry in this record | `HEWLFOUT.ASM:313` `STH CESDID,12(CESDADD)` (record off 4) |
| 6–7 | 2 | byte count | bytes of ESD data = 16 × (entries in record) | `HEWLFOUT.ASM:311-312` `SLL FIFTEEN,4 / STH FIFTEEN,14(CESDADD)` (record off 6) |
| 8… | 16·n | entries | composite ESD entries (≤15) | `HEWLFOUT.ASM:302,316`; `WRITECT = 8+16n` `:315` |

### 7.2 Composite ESD entry (16 bytes)

Field displacements from `HEWLFESD.ASM:77-127` (`CESDNAME=0`, `CESDID/CESDORG=9`, `CESDTYPE=8`, `CESDSEG=12`, `CESDLEN/SUBTYPE=13`) and `HEWLFEND.ASM:53-58` (`RNTTYPE=3`, `CESDTYPE=8`, `CHID=14`, `SUBTYPE=13`).

| off | len | field | meaning | source |
|---|---|---|---|---|
| 0–7 | 8 | name | symbol name, EBCDIC, blank-padded | `HEWLFESD.ASM:91` `CESDNAME EQU 0` |
| 8 | 1 | **type** | type code (low nibble) — see §7.3; control/subtype bits during edit — see §7.4 | `HEWLFESD.ASM:90` `CESDTYPE EQU 8` |
| 9–11 | 3 | address | LE-assigned 24-bit address (SD/PC/CM/PR). Zero for ER/WX/Null. | `HEWLFESD.ASM:79` `CESDID/CESDORG EQU 9` |
| 12 | 1 | **overlay segment number** | F-level: **segment number only** (1 byte). For LR, the owning CSECT's segment number is copied here. **NOT** DFP AMODE/RMODE/RSECT. | `HEWLFESD.ASM:82` `CESDSEG EQU 12`; `HEWLFENS.ASM:118` `MVC 12(1,WORK1),12(WORK3)`; scatter HN `HEWLFOUT.ASM:909-921` |
| 13–15 | 3 | length **or** ID | SD/PC/CM/PR: 3-byte length (`CESDLEN EQU 13`). LR: 2-byte ID at offset 14 (`CHID EQU 14`) pointing to the SD/PC it labels. ER/WX/Null: zero; `X'06'` in the subtype byte (off 13) marks a **never-call** ER. | `HEWLFESD.ASM:87` `CESDLEN EQU 13`; `HEWLFEND.ASM:55` `CHID EQU 14`; `HEWLFENS.ASM:111-118` (LR ID at 14); never-call `HEWLFINC.ASM:82`, `HEWLFESD.ASM:378` |

During edit processing, offset 13 (the high byte of the length field) doubles as the **subtype/control byte** (`SUBTYPE EQU 13`), holding Delete/Replace/Chain flags (§7.4); on a finished module it is the high byte of the 3-byte length for SD/PC/CM/PR.

### 7.3 Type codes (byte 8, low nibble)

From `HEWLFESD.ASM:77-127` (cross-checked against the as370 OBJ oracle `as370.c:1641-1643`):

| code | type | meaning | source |
|---|---|---|---|
| `0` | **SD** | Section Definition (CSECT) | `HEWLFESD.ASM:77` `SD EQU X'00'`; as370 `0x00` |
| `1` | **LD** | Label Definition (object-deck only) — becomes composite **LR** | `HEWLFESD.ASM:96` `LD EQU X'01'`; as370 `0x01` |
| `2` | **ER** | External Reference | `HEWLFESD.ASM:101` `ER EQU X'02'`; as370 `0x02` |
| `3` | **LR** | Label Reference (composite form of LD; 2-byte ID at off 14) | `HEWLFESD.ASM:98` `LR EQU X'03'` |
| `4` | **PC** | Private Code (unnamed CSECT) | `HEWLFESD.ASM:97` `PC EQU X'04'`; as370 `0x04` |
| `5` | **CM** | Common | `HEWLFESD.ASM:85` `CM EQU X'05'` |
| `6` | **PR** | Pseudo-Register (external dummy section) | `HEWLFESD.ASM:103` `PR EQU X'06'` |
| `7` | **Null** | deleted/null entry | `HEWLFESD.ASM:78` `NULL EQU X'07'` |
| `A` | **WX** | Weak External Reference | `HEWLFESD.ASM:127` `WX EQU X'0A'`; as370 `0x0a` |

### 7.4 Subtype / control bits (edit-time, byte 8 and offset-13 control byte)

Working markers seen by `HEWLFEND`/`HEWLFENS`; a finished module's CESD entries carry the resolved type (§7.3) with these control bits cleared except where the module legitimately records a deleted/null (`X'07'`) entry.

| mask | meaning | source |
|---|---|---|
| `X'80'` | "Type-A card" / map marker | `HEWLFEND.ASM:152-155` ("IS TYPE A CARD") |
| `X'60'` | Replace/Change indicator (in offset-13 control byte) | `HEWLFEND.ASM:157` `TM 13(CESDXR),X'60'` |
| `X'40'` | **Chain** | `HEWLFEND.ASM:102` `TM CESDTYPE(TEMP2),X'40'` |
| `X'10'` | **Delete** | `HEWLFEND.ASM:104` `TM CESDTYPE(TEMP2),X'10'` |
| `X'08'` | Subtype-Delete (in SUBTYPE byte) | `HEWLFEND.ASM:106` `TM SUBTYPE(TEMP2),X'08'` |

---

## 8. Scatter / translation record

Present only when the module has the SCTR (scatter-load) or OVLY attribute. Built and written by `HEWLFOUT.ASM:840-984`.

### 8.1 Record header

| off | len | hex | field | source |
|---|---|---|---|---|
| 0 | 1 | `10` | scatter control byte | `HEWLFOUT.ASM:974` `MVI 0(SCATTADD),X'10'` |
| 1–3 | 3 | count | byte count of scatter data in this record (≤1020); `ST TEMP1,0(SCATTADD)` then control byte overlaid into byte 0 | `HEWLFOUT.ASM:973-974` |
| 4… | ≤1020 | data | translation table then scatter table (§8.2) | `HEWLFOUT.ASM:976` `LA WRITECT,4(TEMP1)` (4-byte header) |

Data is segmented into ≤1024-byte records (1020 data + 4-byte header), looped at `OUT02500` (`HEWLFOUT.ASM:973-984`).

### 8.2 Translation table and scatter table

Two tables built contiguously (`HEWLFOUT.ASM:840-962`):

- **Translation table** — 2-byte entries, one per ESD-ID, indexed by `2 × ESD-ID`. Each entry is a halfword pointer into the scatter table (the scatter entry's relative offset / 4). First entry zeroed (`XC 4(2,TRANSADD)` `:854`). Built via `STH TEMP3,0(TRANSADD,TEMP2)` (`:911,961`). Size stored via `MVC PDSE14(2),WORD` → `PDS2TTSZ` (`:855`).
- **Scatter table** — **4-byte entries**: 1 high byte + 3-byte address.
  - High byte = **hierarchy number (HN)** when HIAR is specified (`MVC 0(1,SCATTADD),0(HIARAD)` `:920`), else `X'00'` (`MVI 0(SCATTADD),X'00'` `:921`).
  - Bytes 1–3 = 24-bit SD/PC/CM address (`MVC 1(3,SCATTADD),1(TEMP1)` `:923`).
  - Only SD/PC/CM types get a scatter entry (`TM 0(TEMP1),X'02'` `:919`). Size stored via `MVC PDSE13(2),WORD` → `PDS2SLSZ` (`:962`).

> **F-level constraint (DFP caveat):** the scatter-table high byte is **HN or zero** — there are **no** DFP RSECT/RMODE scatter flags. Do not emit them.

---

## 9. SYM record

Written by `HEWLFSYM.ASM` only when the output module has the TEST attribute. Format from the prologue `HEWLFSYM.ASM:14-19` and the writer `:113-128`.

| off | len | field | meaning | source |
|---|---|---|---|---|
| 0 | 1 | `X'40'` | `SYMCTL` header byte | `HEWLFSYM.ASM:78,122` |
| 1 | 1 | flag | `1xxxxxxx` ⇒ record holds **ESDs** from a load module **not** in TEST when originally link-edited; `0xxxxxxx` ⇒ actual SYM (TESTRAN) data | `HEWLFSYM.ASM:14-18` |
| 2–3 | 2 | byte count | data byte count in this SYM record | `HEWLFSYM.ASM:18-19,113` `LH BUFFCT,2(BUFFADD)` |
| 4… | ≤240 | data | SYM/ESD card images, packed up to 3 cards (240 bytes) per record; last record may be 80/160/240 | `HEWLFSYM.ASM:8-11` |

Header length is 4 (`LA BUFFCT,4(BUFFCT)`, `:122`). For NCAL/production links there is no TEST attribute, so SYM records are absent — `ld` may skip them entirely.

---

## 10. IDR (CSECT-identification) records

Written by `IDROUT` (`HEWLFOUT.ASM:993-1450`) immediately after the last CESD record. Common framing: byte 0 = `X'80'`-class header; byte 1 = data byte count (= record length − 1) (`IDRBYTCT EQU IDRBUF+1`, `:1483`); byte 2 = subtype (`SUBTYPE EQU IDRBUF+2`, `:1481`); byte 3+ = data (`TRUDATA EQU IDRBUF+3`, `:1484`).

Up to four IDR record kinds, written in this order:

### 10.1 HMASPZAP IDR
- Header constant `X'80FA0100'` (`HEWLFOUT.ASM:1434` `IDRZHDR`). Byte 0=`X'80'`, byte 1=`X'FA'` (=250), byte 2=`X'01'` subtype (HMASPZAP), byte 3=count of SPZAP entries (with `CHAIN X'40'` OR'd in if a continuation record follows, `:185,1049`).
- Header length `HDRLEN=4` (`:221`); each SPZAP entry is 13 bytes (`ZAPSIZE DC F'13'`, `:1436`); count field max `ZAPMAX X'53'` (`:187`); record length `ZPRECLEN=251` (`:228`). Data starts at IDRBUF+4 (= byte 4).

### 10.2 Linkage-editor IDR (always present)
- Header `X'801102'` (`HEWLFOUT.ASM:1437` `LKIDR`): byte 0=`X'80'`, byte 1=`X'11'` (=17 = record length 18 − 1), byte 2=`X'02'` subtype (Linkage Editor).
- Component name `CL10'5752SC104'` (`HEWLFOUT.ASM:1438`).
- Version/modification `LKRELNO` = 2 bytes, packed from the SYSGEN-assigned OS release (`HEWLFOUT.ASM:1439` `DS XL2'2100'`, set at `:1123-1130` from `SGRELNO`).
- Date `LKDATE` (3-byte packed `yyddd`) from the `TIME` macro at link time (`HEWLFOUT.ASM:1140`, `LKDATE EQU IDRBUF+15`, `:1475`).
- `LKLEN=15` bytes of header+constant template moved (`:241,1132`); record length `LKRECLEN=18` (`:240`). Layout: header(3)+name(10)+relno(2)+date(3) = 18.

### 10.3 Translator IDR(s)
- Subtype `TRNSTYPE X'04'` (`HEWLFOUT.ASM:198,1171`). Holds translator id, name, and date(s) copied **from each input object/load module's END-card IDR** (`HEWLFOUT.ASM:1170-1412`). Variable length up to `TRUDMAX X'FF'` per record (`:203,1270`).

### 10.4 User-data IDR(s)
- Subtype `USERTYPE X'08'` (`HEWLFOUT.ASM:201,1302`). From IDENTIFY control statements.

### 10.5 Last-IDR marker
- The final IDR written has `LASTIDR X'80'` OR'd into its **subtype byte** (`HEWLFOUT.ASM:1155` `OI SUBTYPE,LASTIDR`, `:195`). This is how the loader knows IDR processing is complete.

---

## 11. PDS directory entry (load-module attributes)

Mapped by `IHAPDS` → DSECT `PDS2` (`~/repos/MVSSRC/www.stben.net/files/MVS_3.8/maclib/IHAPDS`; also `IHAPDS DSECT=NO` at `IEWFETCH.ASM:3940`). The directory has a **basic section** (always) plus optional **scatter-load**, **alias**, **SSI**, **APF** sections in that order (`IHAPDS:13-18`).

The macro default is `PDSBLDL=YES`, which expands the DSECT **with** 2 BLDL bytes (`PDS2CNCT`+`PDS2LIBF`, `IHAPDS:64-65`). Those 2 bytes are inserted **by BLDL only when reading the directory into storage** — they are **not** on disk (`IHAPDS:14,22-24`). `ld` writes the **on-disk** form; the table below gives **on-disk offsets** (PDSBLDL=NO layout). In-storage code that uses `IHAPDS` (e.g. IEWFETCH) sees everything from `PDS2INDC` onward shifted +2.

### 11.1 Basic section — on-disk offsets

| on-disk off | len | field | meaning | source |
|---|---|---|---|---|
| 0 | 8 | `PDS2NAME` | member name or alias (EBCDIC) | `IHAPDS:61` |
| 8 | 3 | `PDS2TTRP` | TTR of first block of the member | `IHAPDS:62` |
| 11 | 1 | `PDS2INDC` | indicator: `PDS2ALIS`=BIT0 alias, `PDS2NTTR`=BIT1+2 (# TTRs in user data), `PDS2LUSR`=BIT3-7 (user-data length, halfwords) | `IHAPDS:75-80` |
| 12 | 3 | `PDS2TTRT` | TTR of first block of **text** | `IHAPDS:82` |
| 15 | 1 | `PDS2ZERO` | zero | `IHAPDS:83` |
| 16 | 3 | `PDS2TTRN` | TTR of **note list** (overlay) or **scatter/translation table** (scatter); else zero | `IHAPDS:84-86` |
| 19 | 1 | `PDS2NL` | # note-list entries (overlay), else zero | `IHAPDS:87-89` |
| 20 | 1 | `PDS2ATR1` | attribute byte 1 (§11.2) | `IHAPDS:91` |
| 21 | 1 | `PDS2ATR2` | attribute byte 2 (§11.3) | `IHAPDS:108` |
| 22 | 3 | `PDS2STOR` | total contiguous main-storage requirement of module | `IHAPDS:123` |
| 25 | 2 | `PDS2FTBL` | length of first block of text | `IHAPDS:125` |
| 27 | 3 | `PDS2EPA` | entry-point address (member or alias) | `IHAPDS:126` |
| 30 | 3 | `PDS2FTBO` | LE-assigned origin of first text block (OS use), overlaid by 3 AOS flag bytes `PDS2FTB1/2/3` (`PDSAOSLE`, `PDS2PAGA`, `PDS2SSI`, `PDSAPFLG`) | `IHAPDS:129-142` |
| 33 | — | `PDSBCEND` | end of basic section | `IHAPDS:143` |

> **In-storage (BLDL=YES) offsets** — the form `IHAPDS`/IEWFETCH code uses, with the 2 BLDL bytes present after `PDS2TTRP`: TTRT=14, ZERO=17, TTRN=18, NL=21, ATR1=22, ATR2=23, STOR=24, FTBL=27, EPA=29, FTBO=32, end=35. Both views are correct for their context; `ld` produces the **on-disk** (33-byte basic section) form.

### 11.2 `PDS2ATR1` — attribute byte 1 (`IHAPDS:91-107`)

| bit | mask | name | meaning |
|---|---|---|---|
| 0 | `X'80'` | `PDS2RENT` | reenterable (RENT) |
| 1 | `X'40'` | `PDS2REUS` | reusable (REUS) |
| 2 | `X'20'` | `PDS2OVLY` | in overlay structure |
| 3 | `X'10'` | `PDS2TEST` | module to be tested (TESTRAN ⇒ SYM records present) |
| 4 | `X'08'` | `PDS2LOAD` | only loadable |
| 5 | `X'04'` | `PDS2SCTR` | scatter format (⇒ scatter/translation record + scatter dir section) |
| 6 | `X'02'` | `PDS2EXEC` | executable |
| 7 | `X'01'` | `PDS21BLK` | if 1: module has **no RLD items and exactly one text block**; if 0: multiple records / ≥1 text block (`IHAPDS:104-107`) |

### 11.3 `PDS2ATR2` — attribute byte 2 (`IHAPDS:108-122`)

| bit | mask | name | meaning |
|---|---|---|---|
| 0 | `X'80'` | `PDS2FLVL` | if 1, module processable **only** by F-level editor |
| 1 | `X'40'` | `PDS2ORG0` | LE-assigned origin of first text block is zero |
| 2 | `X'20'` | `PDS2EP0` | LE-assigned entry point is zero |
| 3 | `X'10'` | `PDS2NRLD` | module contains no RLD items |
| 4 | `X'08'` | `PDS2NREP` | module cannot be reprocessed by the editor |
| 5 | `X'04'` | `PDS2TSTN` | module contains TESTRAN symbol cards |
| 6 | `X'02'` | `PDS2LEF` | module created by linkage editor F |
| 7 | `X'01'` | `PDS2REFR` | refreshable (REFR) |

### 11.4 Optional scatter-load directory section (`IHAPDS:148-157`)

Present only when `PDS2SCTR` is set. Immediately after the basic section:

| off (rel) | len | field | meaning |
|---|---|---|---|
| +0 | 2 | `PDS2SLSZ` | number of bytes in scatter list (stored from `HEWLFOUT.ASM:962`) |
| +2 | 2 | `PDS2TTSZ` | number of bytes in translation table (stored from `HEWLFOUT.ASM:855`) |
| +4 | 2 | `PDS2ESDT` | ESD-ID of CSECT owning the first text block |
| +6 | 2 | `PDS2ESDC` | ESD-ID of CSECT containing the entry point |

The alias (`PDSS02`), SSI (`PDSS03`), and APF (`PDSS04`) sections (`IHAPDS:161-213`) are not produced by a basic `ld` link and are out of scope.

---

## 12. Non-reproducible / carve-outs

These bytes differ run-to-run or depend on PDS placement; a byte-identity oracle must mask them.

| item | where | why it varies | source |
|---|---|---|---|
| **LKED IDR date** | LK IDR `LKDATE`, 3-byte packed `yyddd` | `TIME` macro at link time | `HEWLFOUT.ASM:1140` |
| **LKED version/mod level** | LK IDR `LKRELNO` (2 bytes) | host SYSGEN-assigned OS release (`SGRELNO`) | `HEWLFOUT.ASM:1123-1130,1439` |
| **Translator IDR dates/ids** | translator IDR records | copied verbatim from each input module's END-card IDR | `HEWLFOUT.ASM:1170-1412` |
| **HMASPZAP IDR data** | SPZAP IDR | reflects zaps applied to the input modules | `HEWLFOUT.ASM:1021-1085` |
| **All TTR fields** | `PDS2TTRP`,`PDS2TTRT`,`PDS2TTRN`; control-record CCW text origin (off 9–11) | depend on physical block placement (track/record) in the target PDS | `IHAPDS:62,82,84`; `HEWLFSCD.ASM:99-100` |
| **Note-list TTRs** (overlay) | note list | placement-dependent | `IEWFETCH.ASM` EXLNL DSECT (~`:4021`) |

**Byte-comparable part** (the analog of as370's IFOX byte-identity): the **record stream** — CESD entries, control-record indicators + ID/length lists + lengths, RLD items (R/P/flag/address as *module-relative* offsets), text bytes, scatter/translation tables, IDR subtypes — and the **directory attributes** (`PDS2ATR1`/`PDS2ATR2`, `PDS2STOR`, `PDS2FTBL`, `PDS2EPA`, scatter sizes). Compare those, not TTRs or the LKED IDR date/version. This mirrors the IFOX END-card translator IDR (`15741SC103`+date) that as370 already excludes.

---

## 13. Manual (DFP `5665-295`, LY26-3921) vs F-level source divergences

The manual at `/tmp/lel_logic.txt` documents a **later DFP product**. The F-level source wins.

| topic | DFP manual | F-level (`5752-SC104`) source | action |
|---|---|---|---|
| **CESD entry byte 12** | AMODE/RMODE/RSECT addressing-mode flags | **overlay segment number only** (1 byte) | `HEWLFESD.ASM:82` `CESDSEG EQU 12`; `HEWLFENS.ASM:118`. **Do not emit AMODE/RMODE/RSECT.** |
| **Scatter table entry high byte** | RSECT/RMODE flags | **HIAR hierarchy number or `X'00'`** | `HEWLFOUT.ASM:920-921`. No RSECT/RMODE. |
| **Addressing** | 24-bit and 31-bit (AMODE/RMODE) | **24-bit only** | all addresses 3 bytes; no 31-bit residency flags |
| **Fig. 79 (Control Record)** | byte assignments **garbled by OCR** | byte layout in §4 | use `HEWLFSCD.ASM:74-106` + the `BYTCTRRD` template `:1056-1070`; **ignore Fig. 79 bit patterns** |
| **`PDS2ATR2` bit 0** | DFP may redefine | `PDS2FLVL` = "processable only by F-level editor" | `IHAPDS:109-112` |
| **Directory user-data extensions** | DFP adds AOS/extended fields | `PDS2FTBO` AOS flag bytes (`PDSAOSLE`/`PDS2PAGA`/`PDS2SSI`/`PDSAPFLG`) defined but unused by a basic F-level link | `IHAPDS:131-142` |
| **IDR component id** | DFP id differs | `5752SC104` (byte string; product number `5752-SC104`) | `HEWLFOUT.ASM:1438` |

The manual's RLD flag-field figure (Fig.16/27, `(TTTTLLST)`) **agrees** with the F-level/object encoding and was used to confirm §6.3 (`11 = 4-byte adcon`; `1000`/`1001` = unresolved A/V). For any other bit/byte value, the cited HEWL/IEWFETCH/IHAPDS/as370 source is authoritative.

---

### Source files cited
- `HEWLFSCD.ASM` — control + text + RLD record writer; control-record prologue `:74-106`; byte-0 EQUs `:204-208`; `BYTCTRRD` template `:1056-1070`.
- `HEWLFREL.ASM` — RLD item build (internal representation); working-bit EQUs `:120-126`; internal length/type tests `:312-439` (NOT the on-disk byte).
- `HEWLFOUT.ASM` — CESD writer `:296-337`; scatter/translation `:840-984`; IDR `IDROUT` `:993-1450`; record-type EQUs `:180,195,198,201,203,216`; IDR header constants `:1434-1439`.
- `HEWLFESD.ASM` — composite ESD field displacements `:77-127`; type codes; never-call `:378`.
- `HEWLFEND.ASM` / `HEWLFENS.ASM` — CESD subtype/chain/delete `:97-106,152-157`; LR segment-number/ID processing `HEWLFENS.ASM:111-118`; EQUs `HEWLFEND.ASM:53-58`.
- `HEWLFINC.ASM` — never-call ER (`X'06'`) `:82`.
- `HEWLFSYM.ASM` — SYM record `:8-19,78,113-128`.
- `IEWFETCH.ASM` — loader; ID/RLD EQUs `:209-227`; CCW EQUs `:260-273`; `DIERELOC` reloc decode + `BITMSK` `:3444-3504`; `IHAPDS DSECT=NO` `:3940`.
- `IHAPDS` — PDS2 directory DSECT `:55-213`.
- `as/as370.c` — object-deck oracle: RLD flag `((len-1)&3)<<2 | (isV?0x10:0)` `:1694,1696`; ESD type codes `:1641-1643`.
- `/tmp/lel_logic.txt` — DFP manual (cross-reference only; Figs.16/27 RLD flag `:3629-3645,5380-5400`).
