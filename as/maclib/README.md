# as/maclib — macro library (test fixtures for the WP-4 macro processor)

Self-contained macro library so `as370` can assemble real compiler output without
depending on another repo's layout. Search this dir (and any others passed on the
command line) by member name, HLASM-SYSLIB style.

## Members

| File | Member | Origin | Role |
|------|--------|--------|------|
| `pdptop.copy`   | PDPTOP   | crent370/maclib (Paul Edwards, public domain) | `COPY`ed top-of-file: globals, R0-R15 EQU, `DSA` DSECT |
| `pdpprlg.macro` | PDPPRLG  | crent370/maclib | GCC entry prologue; calls **SAVE** |
| `pdpepil.macro` | PDPEPIL  | crent370/maclib | GCC exit epilogue; calls **RETURN** |
| `save.macro`    | SAVE     | MVS 3.8j SYS1.MACLIB (public domain) | save-area linkage + entry-point eyecatcher |
| `return.macro`  | RETURN   | MVS 3.8j SYS1.MACLIB | restore + `BR 14` |
| `ihbermac.macro`| IHBERMAC | MVS 3.8j SYS1.MACLIB | error-message generator — only on SAVE/RETURN **error paths** (never reached for valid compiler output) |

## What expanding these requires

`PDPPRLG`/`PDPEPIL` (ours) use: name + keyword params, `GBLC`/`GBLB`, `SETB`/`SETC`,
`AIF` (string `EQ`/`NE`, arithmetic, `T'`, `OR`), `AGO`/`ANOP`, sequence symbols,
substitution + `&x.` concatenation.

`SAVE`/`RETURN` (IBM) additionally use nearly the **full** macro language:
- **sublist params** and subscripting: `&REG(1)`, `&REG(2)`
- **attributes**: `K'` (string length), `N'` (sublist count), `T'` (type)
- **substrings**: `'&ID'(start,len)`
- `SETA`/`SETC` arithmetic & string expressions; `&SYSECT`; `MEXIT`

So faithfully expanding the real SYS1.MACLIB macros (the "point at the maclib"
model) means a near-complete HLASM macro engine — this is the bulk of WP-4b/d.
For the compiler's specific call forms (`SAVE (14,12),,name`,
`RETURN (14,12),RC=(15)`), hand-tracing confirms the expansion matches IFOX
(e.g. `SAVE (14,12),,F` → `B *+6` / `DC AL1(1)` / `DC CL1'F'` / `STM 14,12,12(13)`).
