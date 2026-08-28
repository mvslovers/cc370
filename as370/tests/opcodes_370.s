* issue #51 -- S/370 machine instructions missing from as370's opcode
* table.
* Every operand is written with an explicit base and displacement so
* the
* expected bytes are unambiguous and no USING is involved. DP sits
* beside MP as
* the control: it was already in the table and is pinned to IFOX00 by
* the
* corpus, so an MP that does not match its shape is a table error, not
* an
* encoder error.
OPC370   CSECT
         MP    0(8,1),0(4,2)
         DP    0(8,1),0(4,2)
         SSK   1,2
         ISK   3,4
         WRD   0(1),X'05'
         RDD   0(1),X'06'
         SSM   0(1)
         LPSW  0(1)
         TS    0(1)
         SIO   0(1)
         SIOF  0(1)
         TIO   0(1)
         CLRIO 0(1)
         HIO   0(1)
         HDV   0(1)
         TCH   0(1)
         CLRCH 0(1)
         CONCS 0(1)
         DISCS 0(1)
         STIDP 0(1)
         STIDC 0(1)
         SCK   0(1)
         SCKC  0(1)
         STCKC 0(1)
         SPT   0(1)
         STPT  0(1)
         PTLB
         SPX   0(1)
         STPX  0(1)
         STAP  0(1)
         RRB   0(1)
         END
