# Capturing an IFOX00 oracle

`capture.py` assembles a module with the **real IFOX00** on an MVS 3.8j guest
and brings back the object deck byte-for-byte and the SYSPRINT listing.

```sh
export AS370_MVS_ENV=~/path/to/.env          # mbt-style connection file
python3 as370/tests/oracle/capture.py as370/tests/fltoracl.s \
        --deck as370/tests/ref/fltoracl.obj \
        --listing as370/tests/listref/ifox-listing-fltoracl.txt
```

## Why it exists

as370's claim is byte-identity to IFOX00, and the way that claim is kept honest
is a reference deck per shape. For most shapes the ecosystem corpus supplies one
— 737 libc370 modules, and the three the #52/#61 reporter contributed. **For a
construct nothing in reach uses, there is no oracle until one is made.**

Floating point was the first time that was true of a whole feature: the corpus
has no `D`/`E`/`L` constant with a value and no float literal, and the reporter's
COBOL-74 compiler cannot emit one, now or later (#53). `tests/ref/fltoracl.obj`
came from this script.

The same holds for the open coverage work: #23-full wants committed IFOX
references for the whole corpus rather than a SHA manifest of as370's own
output, and #70 wants a listing reference for a module with more than one
control section.

## What it touches on the target

One job. `SYSIN` is inline and `SYSPRINT` goes to the spool, so a `--listing`
run leaves nothing behind. `--deck` needs `SYSPUNCH` on a dataset: the script
creates `<userid>.CC370.ORACLE.OBJ`, reads it back with
`X-IBM-Data-Type: binary`, and deletes it in the same run. A leading `IEFBR14`
clears the dataset first, so an interrupted run does not block the next one.

`PARM='DECK,LIST,NOLOAD,XREF(FULL),RENT'` — the same options the committed
listing references were captured with, so a new listing is comparable to them.

## Two traps

**Column 72.** IFOX00 applies the continuation rule to *comment* cards as well;
as370 does not. A comment line reaching column 72 assembles clean on the host and
is flagged `IFO026` on the guest — with a cascade, because the next card is then
read as a continuation. The script warns per line rather than failing, since a
deliberate continuation looks the same.

**The deck says more than the listing.** IFOX prints at most eight object bytes
per statement line, so the low halves of 16-byte `L` constants and the second
element of a value list appear only in the punched deck. Capture `--deck` when
the bytes are the point.

## Connection file

mbt-style, the same keys `make deploy` uses:

```sh
MBT_MVS_HOST=        MBT_MVS_USER=        MBT_JES_JOBCLASS=A
MBT_MVS_PORT=        MBT_MVS_PASS=        MBT_JES_MSGCLASS=A
```

This repo carries no `.env` of its own and the script has no default — point
`AS370_MVS_ENV` at one from a sibling checkout, or write one. It needs mbt's
mvsMF client; `MBT_ROOT` overrides where that is looked for.
