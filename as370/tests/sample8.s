         TITLE 'TINITVL - Live MVS test caller for IRXINIT INITENVB'            
*                                                                               
*  TINITVL - Minimal HLASM test caller that drives the production               
*            IRXINIT load module end-to-end via the SC28-1883-0 §14            
*            VLIST contract.                                                    
*                                                                               
*  Calls IRXINIT INITENVB through dynamic LOAD (no link-time symbol             
*  reference) so the IRXINIT load module from STEPLIB is exercised              
*  exactly as a real external caller would.                                     
*                                                                               
*  VLIST per SC28-1883-0 §14:                                                  
*    P1  function code         (CL8 'INITENVB')                                 
*    P2  parameter module name (CL8 blank — let IRXINIT default)              
*    P3  caller PARMBLOCK addr (fullword 0)                                     
*    P4  user field            (fullword 0)                                     
*    P5  reserved              (addr of fullword zero)                          
*    P6  out: ENVBLOCK addr    (fullword)                                       
*    P7  out: reason code      (fullword, VL endmarker)                         
*                                                                               
*  WTO output (50-char fixed layout — keeps the source DC inside              
*  the IFOX00 col-16-to-col-71 operand window):                                 
*    TINITVL OK   ENV=xxxxxxxx RC=xxxxxxxx REA=xxxxxxxx                         
*    TINITVL FAIL ENV=xxxxxxxx RC=xxxxxxxx REA=xxxxxxxx                         
*                                                                               
*  Return code (R15 to JCL):                                                    
*     0  IRXINIT RC=0 and ENVBLOCK eye-catcher OK                               
*     8  LOAD EP=IRXINIT failed (IRXINIT not on STEPLIB)                        
*    20  IRXINIT non-zero RC or eye-catcher mismatch                            
*                                                                               
*  The ENVBLOCK is intentionally NOT terminated — TTERMVL covers              
*  the IRXINIT + IRXTERM pairing. The address space ends with the               
*  job step, so MVS reclaims any leaked storage at job end.                     
*                                                                               
*  Ref: SC28-1883-0 §14 (IRXINIT Programming Service)                          
*  Ref: WP-I1c.5 / TSK-198 / GitHub mvslovers/rexx370#83 / #87                  
*                                                                               
*  (c) 2026 mvslovers - REXX/370 Project                                        
*                                                                               
         PRINT NOGEN                                                            
R0       EQU   0                                                                
R1       EQU   1                                                                
R2       EQU   2                                                                
R3       EQU   3                                                                
R4       EQU   4                                                                
R5       EQU   5                                                                
R6       EQU   6                                                                
R7       EQU   7                                                                
R8       EQU   8                                                                
R9       EQU   9                                                                
R10      EQU   10                                                               
R11      EQU   11                                                               
R12      EQU   12                                                               
R13      EQU   13                                                               
R14      EQU   14                                                               
R15      EQU   15                                                               
         PRINT GEN                                                              
*                                                                               
TINITVL  CSECT                                                                  
*                                                                               
*  --- standard MVS entry linkage ---                                           
         STM   R14,R12,12(R13)     save R14-R12 in caller SA                    
         BALR  R12,0                                                            
         USING *,R12                                                            
*                                                                               
*  --- allocate dynamic workarea (RENT) ----------------------------            
         L     R0,=A(WALEN)                                                     
         GETMAIN RU,LV=(0)                                                      
         LR    R8,R1               R8 = workarea ptr (saved for FREE)           
         ST    R13,4(,R1)          our SA back-chain  = caller SA               
         ST    R1,8(,R13)          caller SA forward  = our SA                  
         LR    R13,R1                                                           
         USING WAREA,R13                                                        
*                                                                               
*  --- initialize workarea slots used by the caller ----------------            
         XC    PARMP,PARMP         P3 PARMBLOCK pointer = NULL                  
         XC    USERP,USERP         P4 user field        = 0                     
         XC    OUTENV,OUTENV       P6 out ENVBLOCK      = 0                     
         XC    OUTRSN,OUTRSN       P7 out reason        = 0                     
         XC    WRC,WRC             saved IRXINIT RC     = 0                     
*                                                                               
*  --- build VLIST in workarea -------------------------------------            
*  Each slot is a 4-byte address pointing at the parameter value;               
*  the LAST slot has its high-order bit set to mark end-of-list.                
         LA    R1,FCODE                                                         
         ST    R1,VLIST+0          P1: function code addr                       
         LA    R1,PARMODE                                                       
         ST    R1,VLIST+4          P2: parm module name addr                    
         LA    R1,PARMP                                                         
         ST    R1,VLIST+8          P3: caller PARMBLOCK ptr addr                
         LA    R1,USERP                                                         
         ST    R1,VLIST+12         P4: user field addr                          
         LA    R1,RESVZ                                                         
         ST    R1,VLIST+16         P5: reserved zero addr                       
         LA    R1,OUTENV                                                        
         ST    R1,VLIST+20         P6: out ENVBLOCK addr                        
         LA    R1,OUTRSN                                                        
         O     R1,=X'80000000'     VL marker on last slot                       
         ST    R1,VLIST+24         P7: out reason addr (VL=1)                   
*                                                                               
*  --- LOAD IRXINIT (run-time resolution from STEPLIB) -------------            
         LOAD  EP=IRXINIT,ERRET=NOIRXIN                                         
         LR    R3,R0               R3 = IRXINIT entry-point address             
*                                                                               
*  --- call IRXINIT ------------------------------------------------            
         SR    R0,R0               no previous-env hint                         
         LA    R1,VLIST                                                         
         LR    R15,R3                                                           
         BALR  R14,R15                                                          
         ST    R15,WRC             save IRXINIT RC                              
*                                                                               
         DELETE EP=IRXINIT                                                      
*                                                                               
*  --- evaluate result ---------------------------------------------            
         L     R3,WRC                                                           
         LTR   R3,R3                                                            
         BNZ   FAILED              RC != 0 -> failure                           
         L     R3,OUTENV                                                        
         LTR   R3,R3                                                            
         BZ    FAILED              RC=0 but no ENVBLOCK -> failure              
         CLC   0(8,R3),=CL8'ENVBLOCK'                                           
         BNE   FAILED              eye-catcher mismatch -> failure              
*                                                                               
*  --- success path: emit OK message, exit RC=0 -------------------             
         BAL   R14,WTOSETUP                                                     
         MVC   WTOWORK+4(MSGLEN),OKMSG                                          
         BAL   R14,FILLHEX                                                      
         WTO   MF=(E,WTOWORK)                                                   
         LA    R3,0                exit RC = 0                                  
         B     EPILOG                                                           
*                                                                               
FAILED   EQU   *                                                                
*  --- failure path: emit FAIL message, exit RC=20 ---------------              
         BAL   R14,WTOSETUP                                                     
         MVC   WTOWORK+4(MSGLEN),FAILMSG                                        
         BAL   R14,FILLHEX                                                      
         WTO   MF=(E,WTOWORK)                                                   
         LA    R3,20               exit RC = 20                                 
         B     EPILOG                                                           
*                                                                               
NOIRXIN  EQU   *                                                                
*  --- LOAD failure: STEPLIB does not contain IRXINIT -------------             
*  Workarea was allocated, must FREEMAIN it on this path too.                   
         WTO   'TINITVL FAIL: LOAD EP=IRXINIT failed (check STEPLIB)'           
         LA    R3,8                exit RC = 8                                  
         B     EPILOG                                                           
*                                                                               
*  --- common epilog: free workarea, restore regs, return ---------             
EPILOG   EQU   *                                                                
         L     R13,WDPREV          R13 = caller SA                              
         L     R0,=A(WALEN)                                                     
         FREEMAIN RU,LV=(0),A=(8)                                               
         LR    R15,R3              output RC -> R15                             
         L     R14,12(,R13)                                                     
         LM    R1,R12,24(R13)                                                   
         BR    R14                                                              
*                                                                               
*  --- WTOSETUP: copy MF=L skeleton from CSECT into workarea -------            
*  R14 = caller link reg. Uses R1,R2 only. Sets up WTOWORK header               
*  (AL2 length + AL2 MCSFLAG) and trailing keyword fields by                    
*  copying the entire WTOSKEL block; the caller then MVCs the                   
*  variable text portion into WTOWORK+4.                                        
WTOSETUP DS    0H                                                               
         MVC   WTOWORK(WTOSKLEN),WTOSKEL                                        
         BR    R14                                                              
*                                                                               
*  --- FILLHEX: fill the three hex slots in WTOWORK text portion --             
*  R14 = caller link. Uses R1,R2. ENV at +17, RC at +29, REA at +42             
*  (offsets within text portion, which itself starts at WTOWORK+4).             
FILLHEX  DS    0H                                                               
         ST    R14,SAVR14                                                       
         L     R1,OUTENV                                                        
         LA    R2,WTOWORK+4+17                                                  
         BAL   R14,FMTHEX                                                       
         L     R1,WRC                                                           
         LA    R2,WTOWORK+4+29                                                  
         BAL   R14,FMTHEX                                                       
         L     R1,OUTRSN                                                        
         LA    R2,WTOWORK+4+42                                                  
         BAL   R14,FMTHEX                                                       
         L     R14,SAVR14                                                       
         BR    R14                                                              
*                                                                               
*  --- FMTHEX: convert R1 to 8 EBCDIC hex chars at addr R2 --------             
*  Standard UNPK + TR(HEXTAB) idiom (IFOX00-compatible). R14 = link.            
FMTHEX   DS    0H                                                               
         ST    R1,FMTTMP                                                        
         UNPK  FMTBUF(9),FMTTMP(5)                                              
         TR    FMTBUF(8),HEXTAB-X'F0'                                           
         MVC   0(8,R2),FMTBUF                                                   
         BR    R14                                                              
*                                                                               
         LTORG                                                                  
*                                                                               
*  --- static input data (read-only, RENT-safe) -------------------             
FCODE    DC    CL8'INITENVB'                                                    
PARMODE  DC    CL8' '              blank -> IRXINIT picks default               
RESVZ    DC    F'0'                P5 reserved zero                             
HEXTAB   DC    C'0123456789ABCDEF'                                              
*                                                                               
*  --- WTO parameter list skeleton (hand-built, SVC-35 standard) -              
*  Layout: AL2(total length incl. this halfword + flags) | AL2(MCSFLAG)         
*          | 60 bytes text. Hand-built (not via WTO MF=L) because               
*          the IFOX00 source-card column-71 limit cannot accommodate            
*          a TEXT='<60 spaces>' literal in a single continuation.               
*  WTOSETUP copies this read-only block into the writable WTOWORK               
*  in the workarea; the body code MVCs OKMSG/FAILMSG over the text              
*  region and fills hex slots before WTO MF=(E,WTOWORK).                        
WTOSKEL  DS    0H                                                               
         DC    AL2(WTOEND-WTOSKEL)                                              
         DC    AL2(0)                                                           
         DC    60C' '                                                           
WTOEND   EQU   *                                                                
WTOSKLEN EQU   *-WTOSKEL                                                        
*                                                                               
*  --- 50-char message templates (text portion of WPL) ------------             
*    01234567890123456789012345678901234567890123456789                         
*    0         1         2         3         4                                  
*    TINITVL OK   ENV=XXXXXXXX RC=XXXXXXXX REA=XXXXXXXX                         
*                     ^17          ^29           ^42                            
*  Hex slots: ENV@17, RC@29, REA@42 (8 chars each, 0-based offsets              
*  into the text portion of the WPL, i.e. WTOWORK+4+offset).                    
OKMSG    DC    CL50'TINITVL OK   ENV=XXXXXXXX RC=XXXXXXXX REA=XXXXXXXX'         
FAILMSG  DC    CL50'TINITVL FAIL ENV=XXXXXXXX RC=XXXXXXXX REA=XXXXXXXX'         
MSGLEN   EQU   50                                                               
*                                                                               
*  --- workarea DSECT (writable per-invocation storage) -----------             
WAREA    DSECT                                                                  
*  Standard MVS save area at +0..+71 (R14-R12 + back/forward chain).            
WDFLAGS  DS    F                   +0                                           
WDPREV   DS    F                   +4  back chain to caller SA                  
WDNEXT   DS    F                   +8  forward chain from caller SA             
         DS    15F                +12..+71 R14-R12 save slots                   
*  Caller-supplied input slots (zeroed via XC at entry).                        
PARMP    DS    F                   P3 PARMBLOCK ptr (=0 -> use default)         
USERP    DS    F                   P4 user field                                
OUTENV   DS    F                   P6 out: ENVBLOCK address                     
OUTRSN   DS    F                   P7 out: reason code                          
WRC      DS    F                   IRXINIT RC (R15)                             
SAVR14   DS    F                   FILLHEX R14 save slot                        
*  IRXINIT VLIST (7 fullword slots).                                            
VLIST    DS    7F                                                               
*  FMTHEX scratch (UNPK requires 5-byte source -> 9-byte target).               
FMTTMP   DS    F                   FMTHEX 32-bit input                          
FMTBUF   DS    CL16                FMTHEX UNPK target                           
*  Writable WTO parameter list (copied from WTOSKEL at runtime).                
*  Sized by the symbolic length of the MF=L skeleton; rounded to                
*  the next fullword by the assembler-generated alignment.                      
WTOWORK  DS    CL(WTOSKLEN)                                                     
*                                                                               
WALEN    EQU   *-WAREA                                                          
*                                                                               
         END   TINITVL                                                          
