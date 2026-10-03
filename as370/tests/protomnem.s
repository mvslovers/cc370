         MACRO
         M     &A,&B
         MNOTE 4,'MACRO M CALLED'
         MEND
T        CSECT
         M     1,2
         END
