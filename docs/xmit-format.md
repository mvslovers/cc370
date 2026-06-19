# XMIT (TSO TRANSMIT / NETDATA) Format — the host→MVS install transport

**Producer:** `ld370 --xmit` (`ld/ld370.c`, the XMIT emitter).
**Consumer on MVS:** `RECV370` (a batch XMIT unpacker, `PGM=RECV370` in
`SYSC.LINKLIB`) — it parses the NETDATA stream and IEBCOPY-loads the member(s)
into a load library. (Stock TSO/E `RECEIVE` is **not** present on the target;
this system has *NJE38 RECEIVE v2.3.0*, whose command syntax differs — `RECEIVE
INDSN(...)` gives `IKJ56621I`. Use RECV370, the path httpd/brexx already use.)

**Why XMIT and not raw IEBCOPY-unload:** the IEBCOPY-unloaded dataset is
RECFM=VS (variable-spanned), and mvsMF's binary upload cannot reconstruct
variable-record boundaries (it splits/pads at LRECL; its `record` data-type is
not wired into the write path). A TSO TRANSMIT file is **RECFM=FB LRECL=80**,
which uploads byte-clean as a binary sequential dataset. TRANSMIT of a load
library internally runs IEBCOPY to unload it and wraps that in NETDATA — so the
IEBCOPY-unload (`docs/unload-format.md`) is the *payload* and this is the outer
wrapper. Commercial precedent: Dignus PLINK ships a TSO TRANSMIT file.

**Validated end-to-end on real MVS (2026-06-19):** `as370 → ld370 → --xmit`
built E2E entirely on the host (no IFOX/IEWL/IEBCOPY/TRANSMIT); the FB80 upload
was RECV370-installed (`IEB154I E2E HAS BEEN SUCCESSFULLY LOADED`) and ran with
**RC=7**. The IDR-less 303-byte ld370 member loads + runs because program fetch
finds the text via the directory `PDS2TTRT`, bypassing the (absent) IDRs.

---

## 1. Container: NETDATA segments in FB80

The file is a continuous NETDATA byte stream packed into 80-byte records (the
last zero-padded to a multiple of 80). The stream is a sequence of **logical
records**, each split into **segments**:

```
segment = len(1, incl. this 2-byte header) + flags(1) + data(len-2)
flags:  0x80 first-segment-of-record | 0x40 last-segment | 0x20 control-record
```

Max segment = 255 (so ≤253 data bytes); records longer than 253 span multiple
segments, and segments freely span the 80-byte record boundaries.
`netdata_seg()` in `ld/ld370.c` emits this.

## 2. Logical records (9, for a one-file transmission)

```
INMR01   header        (control)
INMR02   control #1     (control) -- IEBCOPY : the SOURCE load library DCB
INMR02   control #2     (control) -- INMCOPY : the unloaded form DCB
INMR03   data descriptor (control)
COPYR1                  (data) ┐
COPYR2                  (data) │ the 4 records of the IEBCOPY-unload payload
directory + EOD marker  (data) │ (52 / 276 / 288 / member+EOM bytes for E2E)
member data + EOM       (data) ┘
INMR06   trailer        (control)
```

The 4 payload records are exactly the 4 logical records the unloaded image is
split into when transmitted (confirmed by IDCAMS PRINT of a real unload:
COPYR1=52, COPYR2=276, dir+EOD=288, member+EOM=430). `emit_unload()` reports
these boundaries via its `bounds[]` out-parameter. One load library = one file
⇒ **INMNUMF=1**; a multi-member library is still one file (members inside the
unload directory), so `--pack` needs **no** wrapper change.

## 3. INMR control records (NETDATA text units)

After the 6-byte `INMR0n` EBCDIC eye-catcher, fields are **text units**:
`key(2) + count(2, =1) + length(2) + value`. `tu()/tui()/tus()/tu_dsname()`
emit them; `inmr_hdr()` writes the eye-catcher.

| Record | Text units (key) |
|--------|------------------|
| **INMR01** | INMLRECL=80, INMFNODE, INMFUID, INMTNODE, INMTUID, **INMFTIME** (timestamp), INMNUMF=1 |
| **INMR02 #1** | file#=1, INMUTILN=`IEBCOPY`, INMSIZE, INMDIR, INMLRECL=0, INMDSORG=PO, INMBLKSZ, INMRECFM=U, **INMDSNAM** (target dsn qualifiers) |
| **INMR02 #2** | file#=1, INMUTILN=`INMCOPY`, INMSIZE, INMLRECL=19085, INMDSORG=PS, INMBLKSZ=3120, INMRECFM=VS |
| **INMR03** | INMSIZE, INMLRECL=80, INMDSORG=PS, INMRECFM |
| **INMR06** | (none — trailer) |

Field classes: `INMDSNAM` is a **parameter** (`--dsn`, the install target);
`INMFTIME` is **computed** (current time — the byte-identity carve-out); the
DCB constants (RECFM/DSORG/LRECL of the source U-PO library and the VS unloaded
form) are **echoed** E2E-correct. **Open (TODO):** the `INMSIZE` allocation
hints and source `INMBLKSZ/INMDIR` are echoed E2E values — compute them from the
member for arbitrary modules (a single tiny oracle can't validate them; a wrong
size only bites RECEIVE on a larger member).

## 4. Install on MVS (RECV370)

Upload the FB80 XMIT as a binary PS dataset (mvsMF splits on the 80-byte
records), then:

```jcl
//RECV   EXEC PGM=RECV370,REGION=6144K
//STEPLIB DD DSN=SYSC.LINKLIB,DISP=SHR
//RECVLOG DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSIN  DD DUMMY
//SYSUT1 DD UNIT=VIO,SPACE=(CYL,(10,5)),DISP=(NEW,DELETE)
//SYSUT2 DD DSN=target.LOADLIB,DISP=(NEW,CATLG),UNIT=SYSDA,
//          SPACE=(CYL,(1,1,10)),DCB=(RECFM=U,BLKSIZE=19069)
//XMITIN DD DSN=uploaded.FB80.XMIT,DISP=SHR
```

`SYSUT2` is the (PO, RECFM=U) load library RECV370 STOWs the member into.

## 5. Status & open points

* **Done:** single-member XMIT byte-identical to the TRANSMIT oracle modulo the
  INMFTIME timestamp; payload == the unload image; **RECV370-installs and runs
  on MVS (RC=7)** for both the IEWL member and ld370's own host-linked member.
  Host checks: `ld/tests/run.sh` + `ld/tests/xmit_check.py`.
* **Open:** compute `INMSIZE`/source-DCB for arbitrary members (Stage-3
  generalisation); multi-track unload geometry for large libraries; an mbt
  host-assembly/link backend that ships the XMIT instead of submitting ASM/LINK
  JCL. The merge-separate-XMITs tool is deprioritised — `--pack --xmit` builds a
  multi-member library XMIT directly.
