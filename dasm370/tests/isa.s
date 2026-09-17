* cc370#395: what a narrower opcode table removes, and what it must
* not.
*
* A disassembler decides at every byte whether an instruction is
* there, and the larger the table the more nonsense is
* representable.  THE ROUND TRIP CANNOT OBJECT: it re-encodes the
* wrong reading to the same bytes, so a false instruction and a true
* one are equally byte-safe.  Narrowing the table is the only
* mechanism that removes the reading rather than reporting it.
*
* Two of the DC runs below are data that `--isa full' reads as
* instructions nobody wrote:
*
*   X'2A34'              ADR 3,4 -- floating point, opcode 20-3F
*   X'F811000000000000'  ZAP     -- packed decimal, and SIX bytes,
*                        so it swallows two of the eight and leaves
*                        the rest as a DC of its own
*
* Under `--isa app' both come back as the DC they are -- the second
* as exactly the eight bytes this file wrote -- and EVERY REAL
* INSTRUCTION SURVIVES: the BALR, both LRs and the BR decode the
* same under either setting.  Two false readings removed, none lost.
*
* THE ENTRYs ARE NOT DECORATION.  A failed decode costs everything
* after it until something names an offset, so without RESYNC and
* TAIL the cut turns the whole tail into one DC and loses two real
* instructions.  That is why the corpus answer is not one-sided:
* over 1,200 sections `app' decodes 3.25 % fewer instructions, and
* the count FALLS in 746 sections, is unchanged in 256 and RISES in
* 198 -- a rise being a false decode removed and a true one
* re-syncing behind it, which is the mechanism working.
*
* WHAT MAY NOT MOVE IS THE DECK.  run.sh round-trips this under each
* setting and requires byte-identity both times: a wrong cut changes
* how a byte PRINTS, not what anything DOES.  Measured over 500
* corpus modules, 0 round-trip verdicts change in either direction.
*
* Keep every line under column 72.
*
ISAX     CSECT
         ENTRY RESYNC,TAIL
         BALR  12,0
         USING *,12
         LR    1,2
         DC    X'2A34'
RESYNC   LR    3,4
         DC    X'F811000000000000'
TAIL     BR    14
         END
