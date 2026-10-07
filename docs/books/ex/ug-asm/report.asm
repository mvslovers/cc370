*        void report(int sum, int average) -- print both with printf
REPORT   CSECT
         PDPPRLG FRAME=104,BASER=12,ENTRY=NO
         LR    11,1               R11 = our parameter list
         LA    1,FMT              printf argument 1: the format
         ST    1,88(,13)
         MVC   92(8,13),0(11)     arguments 2 and 3: sum, average
         LA    1,88(,13)          R1 = printf's parameter list
         L     15,=V(PRINTF)
         BALR  14,15
         PDPEPIL
         LTORG
FMT      DC    C'SUM %d, AVERAGE %d',X'15',X'00'
         END
