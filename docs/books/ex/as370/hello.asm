HELLO    CSECT
         USING HELLO,15
         SR    15,15
         BR    14
MSG      DC    C'HELLO, MVS'
         END   HELLO
