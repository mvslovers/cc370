* Das Attribut-Apostroph ist kein Anfuehrungszeichen (#149).
*
* parse() kippte den Quote-Zustand an jedem Apostroph.  Nach einem
* L'/T'/K' war das erste Blank damit "in Anfuehrungszeichen", der
* Operand endete nicht, und die Bemerkung wurde mitgelesen.
*
* Drei Faelle, und jeder pruefte etwas anderes:
*
* 1  Makroaufruf -- die verschluckte Bemerkung wird Parameter.
*    IFOX00: DC C'XX' = 2 Bytes.  Ohne Fix 21.
*
* 2  Literal mit Bemerkung -- der Name des Literals enthielt die
*    Bemerkung, dasselbe Literal wurde also zweimal angelegt.
*    IFOX00: EIN Pooleintrag, 4 Bytes.  Ohne Fix zwei, 8 Bytes.
*    Das ist die Form aus libc370 @@crt0 Karte 266.
*
* 3  Gegenprobe: eine Zeichenkette, die auf ein Attributzeichen
*    ENDET.  Innerhalb einer Zeichenkette kann ein Apostroph sie
*    nur schliessen -- attr_apos() allein sieht das nicht, und
*    ohne das `q ||' verlor AMDPREAD seine Symbole.  Die Karte ist
*    dem READ ...,'S' aus AMDPREAD nachgebaut: schliesst die
*    Zeichenkette nicht, wird OK zu `OK  READ RECORD INTO BUFFER'.
*    IFOX00: DC C'OK' = 2 Bytes.
         MACRO
         MYM   &A,&B
         DC    C'&B'
         MEND
         MACRO
&L       MYQ   &A,&B
&L       DC    C'&B'
         MEND
PD       DSECT
PP       DS    CL4
T        CSECT
         USING T,12
         LR    3,1
A        DC    CL4'ABCD'
         MYM   L'A,XX          BEMERKUNG
         MYM   4,YY            KONTROLLE OHNE ATTRIBUT
         CLC   PP-PD(L'A,3),=A(A) eye catcher?
         L     2,=A(A)
MAPD     MYQ   'S',OK  READ RECORD INTO BUFFER
         BR    14
         LTORG
         END   T
