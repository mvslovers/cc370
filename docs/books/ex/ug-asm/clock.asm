CLOCK    CSECT
         SAVE  (14,12),,CLOCK
         LR    12,15
         USING CLOCK,12
         TIME  DEC                R0 = time, R1 = date
         ST    1,TODAY            keep the date
         RETURN (14,12),RC=0
TODAY    DS    F
         END   CLOCK
