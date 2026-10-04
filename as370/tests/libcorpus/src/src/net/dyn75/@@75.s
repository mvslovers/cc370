         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '@@75'
* Program text area
         DS    0F
* X-func __75 prologue
@@75     PDPPRLG CINDEX=0,FRAME=136,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __75 code
         L     2,0(11)
         LA    3,88(,13)
         LR    14,3            => save area for regs
         STM   0,11,0(14)      Save R0-R11 in stack save area
         LR    11,2             => PL75
         LM    0,9,0(11)        Load R0-R9 from parameter list
*
         LA    3,0              To Host PC
         SLR   0,0              Restart = No
         DC    X'75005000'      TCPIP 0,000(0,R5)
         LTR   15,15            Check for error
         BNZ   DYN75ERR
*
         LA    3,1              From Host PC
         SLR   0,0              Restart = No
         DC    X'75006000'      TCPIP 0,000(0,R6)
DYN75ERR DS    0H
         STM   0,15,0(11)       Save results in parameter list
         LM    0,11,0(14)       Restore registers
         LR    2,15
         LR    15,2
* Function __75 epilogue
         PDPEPIL
* Function __75 literal pool
         DS    0F
         LTORG
* Function __75 page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
