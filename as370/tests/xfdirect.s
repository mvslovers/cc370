         ICTL  1,71,16
LR2      OPSYN LR
         MACRO
         M9
         AIFB  (1 EQ 1).L
         AGOB  .L
.L       ANOP
         DC    C'M9'
         MEND
P9OPS    CSECT
         M9
         LR2   1,2
         PUNCH ' PUNCHED CARD'
         END
