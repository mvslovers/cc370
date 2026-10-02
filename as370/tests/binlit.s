* A binary literal is sized and valued like the DC constant it spells
* (cc370#140): BLSR3270's =BL1'00001011' is one byte X'0B' in the byte
* group of the pool (IFOX00 deck); as370 gave four bytes of zero in the
* fullword group. Self-checking: each DC below is followed in the pool
* by the literal with the same operand, and run.sh compares the bytes.
BINLIT   CSECT
         USING BINLIT,15
DC1      DC    BL1'00001011'
DC2      DC    BL2'101'
DC3      DC    B'111111111'
DC4      DC    BL1'111111111'
         ICM   1,8,=BL1'00001011'
         ICM   1,8,=BL2'101'
         ICM   1,8,=B'111111111'
         ICM   1,8,=BL1'111111111'
         END
