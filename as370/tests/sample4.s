TEST     CSECT
         USING TEST,12
         STM   14,12,12(13)
         LM    14,12,12(13)
         MVC   4(8,13),0(11)
         MVI   3(13),C'Z'
         B     DONE
         L     1,=V(SUB)
DONE     BR    14
MSG      DC    C'HELLO WORLD'
         LTORG
         END   TEST
