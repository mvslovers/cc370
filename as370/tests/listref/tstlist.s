TSTLIST  CSECT
         PRINT GEN
         SAVE  (14,12),,'TSTLIST LISTING DEMO'
         BALR  12,0
         USING TSTLIST,12
         L     15,=V(EXTRTN)
         L     1,=A(WORKAREA)
         L     2,=F'42'
         MVC   WORKAREA(4),=X'01,02,03,04'
         RETURN (14,12)
WORKAREA DC    F'0'
         DC    A(TSTLIST)
         DC    AL3(WORKAREA)
         DC    C'HELLO WORLD'
         END
