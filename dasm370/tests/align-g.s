* cc370#385: THE LAST CLAIMANT OF AN OFFSET IS NOT THE RULE -- the
* last that RESERVES is.  Found in the control corpus by mvs38src,
* not reasoned about, and this fixture reproduces the shape rather
* than describing it.
*
* IEHPROG1's second section winds the counter back with `ORG *-18',
* overwrites six statements and winds it forward again with a bare
* `ORG'.  That forward ORG has an advance of +10, so it CLAIMS
* 4476..4485 and is LAST in listing order -- and the deck there holds
* 50210000 92801000 0A14: the ST, the MVI and the SVC.  The TXT cards
* agree from the other side, the rewritten run being one card of 8
* bytes at 4468 that stops short of 4476.  An ORG moves over bytes
* and never writes them.
*
* Measured over both populations: 3,266 overlapped offsets over the
* 30 with 45 wrong under the plain rule, and 189,227 over the 832
* with 53,328 wrong -- 28.2 % of overlaps, in 121 of the 378
* modules that have one.  Under the reserves rule, 0 in both.
*
* AND IT IS KEYED ON `reserves' AND NOT ON THE OPERATION.  Of those
* 53,328 last claimants 53,323 are ORG and FIVE ARE NOT: HMASMREC
* has a zero-duplication DC 0F as the last claimant of 13865, and
* IGE0704B an ASCTAB DS 0F of 170 -- storage statements sitting on
* bytes an earlier statement emitted.  "An ORG never outranks an
* emitter" leaves those five standing.
*
* HERE the bare ORG sits at 000005 with an advance of 7, so it claims
* 000005..00000B.  TWO wind-backs are needed: the first to overwrite,
* the second to leave the counter short of the high-water mark so the
* bare ORG has an advance at all.  The ENTRY splits the disassembly
* at 000008 so the finding starts inside the ORG's range instead of
* before it; without it the run coalesces from 000004 and the case
* cannot be reached.
*
* Offset 000008 has THREE claimants -- the first L, the MVI that
* overwrote it, and the ORG that moved over it.  The deck holds the
* MVI.
*
* cc370#414 is what makes the rule EXPRESSIBLE: before it every one
* of these ORGs reported reserves=1, and nothing in the export could
* have told them apart.
*
* Keep every line under column 72.
*
ORGX     CSECT
         ENTRY OVERMVI
         BALR  12,0
         USING *,12
         BR    14
         L     2,0(0,12)
         L     3,0(0,12)
         ORG   *-8
         ST    2,0(1,0)
OVERMVI  MVI   0(1),128
         ORG   *-8
         DC    X'77'
         ORG
         BR    14
         END
