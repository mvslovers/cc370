* cc370#393: every USING/DROP/PUSH/POP shape the export records.
*
* The answers are written into tests/useexp_check.py by hand and
* this file is what produces them.  Keep every line under column
* 72: a card that reaches it eats the next one, statement and all,
* at severity 4 -- silently.
*
* Two cases here exist ONLY here.  An omitted base register in a
* USING list (`USING D,,9') is 0 of 31,529 tree-wide, and an
* operandless DROP is 4 -- so no corpus run exercises either, and
* a fixture is the only thing that can.  The PUSH/POP block is the
* same argument one step further: exactly ONE module in the corpus
* writes PUSH USING and assembles identical, so these fixtures
* carry nearly all the coverage that half will ever have.
*
* The bare DROP releases every live register -- and this fixture
* is why cc370#394 could be fixed confidently.  It first pinned
* the DEFECT: split_fields("") returns one empty field, so the
* drop-all branch was unreachable and as370 dropped register 0
* instead.  When #394 landed this file failed, exactly as it was
* written to, and was updated on purpose.  A fixture that had
* agreed with both answers would have been no test at all.
*
USEEXP   CSECT
ABSD     EQU   0                 an ABSOLUTE domain
         BALR  12,0
         USING *,12              one register, base = 2
         USING USEEXP,11,10      by POSITION: 11@0, 10@4096
         USING USEEXP,,9         omitted reg: 9@4096, nothing at 0
         PUSH  USING
         DROP  11
         USING MYDS,8            a DSECT domain
         USING ABSD,7            absolute: not an address at all
         POP   USING             restores 11; 8 and 7 go
         DROP  6                 never based: noop, and recorded
         DROP  12,10
* A bare DROP takes no remark: with the operand field optional,
* the first token after the opcode IS the operand.  It releases
* R9 and R11, which are what is live here (cc370#394).
         DROP
         PUSH  USING             pushed and never popped
         ORG   USEEXP+X'20'
         USING *,5               after an ORG: loc and value both 20
         ORG
         LA    1,0
MYDS     DSECT
MYFLD    DS    F
         END
