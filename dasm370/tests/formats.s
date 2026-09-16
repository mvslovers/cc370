* Every instruction shape dasm370 decodes, in one section (#381).
*
* The fixture is a SOURCE and not a hand-built deck: as370 is the
* encoder, so the bytes under test are the ones the assembler really
* produces, and the round trip has one reader on each side and
* nothing in between.
*
* Keep every line under column 72.  A card that reaches it eats the
* next card, statement and all, at severity 4 -- silently.
*
FORMATS  CSECT
         ENTRY ENTRYPT
         EXTRN EXTNAME
ENTRYPT  BALR  12,0
         USING *,12
         LR    1,2                    RR
         LA    3,8(0,12)              RX
         L     4,12(1,12)             RX indexed
         ST    4,16(0,12)             RX
         LM    2,4,20(13)             RS three operands
         STM   14,12,12(13)           RS three operands
         SLL   5,4(0)                 RS shift, R3 zero
         SRL   5,3(0)                 RS shift, R3 zero
         CLI   0(1),X'40'             SI
         MVI   1(1),C'A'              SI
         MVC   0(8,1),0(2)            SS one length
         CLC   0(4,1),0(2)            SS one length
         TR    0(6,1),0(2)            SS one length
         ED    0(5,1),0(2)            SS one length, decimal edit
         EX    0,MVCTARG              EX
         AP    0(4,1),0(3,2)          SS two lengths
         ZAP   0(8,1),0(4,2)          SS two lengths
         PACK  0(8,1),0(5,2)          SS two lengths
         UNPK  0(9,1),0(5,2)          SS two lengths
         SRP   0(8,1),2(0),5          SS, length plus a rounding digit
         SVC   35                     SVC
         LPSW  0(1)                   S, one-byte opcode as <op>00
         TS    0(1)                   S, one-byte opcode as <op>00
         STIDP 0(1)                   S, a real two-byte opcode
         PTLB                         S0, no operand at all
         IPK                          S0, no operand at all
         B     BRTARG                 mask 15
         NOP   BRTARG                 mask 0
         BE    BRTARG                 mask 8, BE beats BZ (measured)
         BNE   BRTARG                 mask 7
         BH    BRTARG                 mask 2
         BL    BRTARG                 mask 4
         BNH   BRTARG                 mask 13
         BNL   BRTARG                 mask 11
         BO    BRTARG                 mask 1
         BNO   BRTARG                 mask 14
         BC    3,BRTARG               a mask no pseudo names
BRTARG   BR    14                     BCR mask 15
         BER   14                     BCR mask 8
         BNER  14                     BCR mask 7
         BCR   5,14                   a mask no pseudo names
MVCTARG  MVC   0(1,1),0(2)            the EX target
         DS    0F
ACON     DC    A(ENTRYPT)             an A-con into this section
VCON     DC    V(EXTNAME)             a V-con out of it
LITS     DC    C'ABCD'                plain text
         DC    X'0102030405'          plain bytes
HOLE     DS    XL7                    a hole: covered by no TXT card
         DC    F'1'                   and text again after it
         END   ENTRYPT
