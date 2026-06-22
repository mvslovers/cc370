         MACRO
&N       GEN   &R
         LCLA  &A
&A       SETA  N'&R
         AIF   (&A NE 2).ONE
&N       STM   &R(1),&R(2),12(13)
         MEXIT
.ONE     ANOP
&N       ST    &R(1),12(13)
         MEND
T        CSECT
         USING T,12
A        GEN   (14,12)
         GEN   (5)
         BR    14
         END   T
