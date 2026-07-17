RELOC18  CSECT
         PRINT GEN
         USING RELOC18,12
*  RX illegal: explicit base + reloc disp
         L     1,LAB(,2)
*  RS illegal: STM explicit base + reloc disp
         STM   14,12,LAB(13)
*  SI illegal: CLI explicit base + reloc disp
         CLI   LAB(13),X'00'
*  SS illegal: MVC explicit base + reloc disp
         MVC   LAB(8,2),0(3)
*  S illegal: STCK explicit base + reloc disp
         STCK  LAB(2)
*  S illegal: SPKA explicit base + reloc disp
         SPKA  LAB(2)
*  legal RX implicit D(X): index 2, base from USING
         LA    1,LAB(2)
*  legal S implicit: base from USING
         STCK  LAB
*  legal SS implicit length: base from USING
         MVC   LAB(8),0(3)
*  legal SS absolute difference: FLD-MYDS is absolute
         MVC   FLD-MYDS(8,2),0(3)
LAB      DS    CL8
MYDS     DSECT
         DS    XL40
FLD      DS    CL8
         END
