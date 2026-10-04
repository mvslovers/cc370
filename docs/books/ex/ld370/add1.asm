ADD1     CSECT
         ENTRY ADD2
         LA    15,1(,1)
         BR    14
ADD2     LA    15,2(,1)
         BR    14
         END
