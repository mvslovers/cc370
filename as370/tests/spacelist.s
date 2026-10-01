* SPACE im Listing (#623), gemessen MIT Spalte 1 (capture.py --asa).
* Jeder Fall steht zwischen zwei DC, damit die Zeilen um ihn herum
* zeigen, was er bewirkt:
*   S1  SPACE ohne Operand    S2  SPACE 2    S3  SPACE 3
*   S4  SPACE 0               S5  SPACE aus einem Makro unter GEN
*   S6  dasselbe unter NOGEN  S7  SPACE ueber das Seitenende hinaus
         MACRO
         SPMAC &N
         DC    C'M&N'
         SPACE 2
         DC    C'N&N'
         MEND
TSPC     CSECT
         DC    C'A1'
         SPACE
         DC    C'B1'
         DC    C'A2'
         SPACE 2
         DC    C'B2'
         DC    C'A3'
         SPACE 3
         DC    C'B3'
         DC    C'A4'
         SPACE 0
         DC    C'B4'
         DC    C'A5'
         SPMAC 5
         DC    C'B5'
         PRINT NOGEN
         DC    C'A6'
         SPMAC 6
         DC    C'B6'
         PRINT GEN
         DC    C'00'
         DC    C'01'
         DC    C'02'
         DC    C'03'
         DC    C'04'
         DC    C'05'
         DC    C'06'
         DC    C'07'
         DC    C'08'
         DC    C'09'
         DC    C'A7'
         SPACE 10
         DC    C'B7'
         END
