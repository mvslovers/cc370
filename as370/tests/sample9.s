         TITLE 'IRXTMPW - REXX/370 TMP Wrapper'                                 
*                                                                               
*  IRXTMPW - Try loading IRXANCHR so its CDE lives in                           
*            the Step-TCB JPQ (survives XCTL, found by command                  
*            subtasks via JPA lookup). Attempt eager IRXINIT                    
*            INITENVB to create a default TSO environment in                    
*            IRXANCHR slot 1 before handing control to IKJEFT01.                
*            XCTL to IKJEFT01.                                                  
*                                                                               
*  Must be link-edited AC(1),RENT and REUS into an APF-authorized               
*  library (e.g. SYS2.LINKLIB).                                                 
*                                                                               
*  On entry: R1 = PARM pointer, R13 = caller SA, R14 = return.                  
*  On exit:  no return - XCTLs to IKJEFT01 (which ends via SVC 3).              
*                                                                               
         PRINT NOGEN                                                            
R0       EQU   0                                                                
R1       EQU   1                                                                
R2       EQU   2                                                                
R3       EQU   3                                                                
R5       EQU   5                                                                
R6       EQU   6                                                                
R7       EQU   7                                                                
R8       EQU   8                                                                
R12      EQU   12                                                               
R13      EQU   13                                                               
R14      EQU   14                                                               
R15      EQU   15                                                               
         PRINT GEN                                                              
*                                                                               
IRXTMPW  CSECT                                                                  
         BALR  R12,0                                                            
         USING *,R12                                                            
*                                                                               
* --- save registers that IKJEFT01 expects to be preserved ---                  
         LR    R5,R0                                                            
         LR    R6,R1                                                            
         LR    R7,R14                                                           
         LR    R8,R15                                                           
*                                                                               
* --- try loading IRXANCHR ---                                                  
         LOAD  EP=IRXANCHR,ERRET=NOANCH                                         
*                                                                               
NOANCH   DS    0H                                                               
         LOAD  EP=IRXINIT,ERRET=NOINIT                                          
*                                                                               
* --- eager INITENVB: capture EP, allocate workarea ---                         
         LR    R2,R0              save IRXINIT EP (LOAD returns in R0)          
         L     R0,=A(WALEN)                                                     
         GETMAIN RC,LV=(0)                                                      
         LTR   R15,R15                                                          
         BNZ   NOINIT             GETMAIN failed - skip INITENVB                
         LR    R3,R1              save workarea ptr for FREEMAIN                
         ST    R13,4(,R1)        backward chain (caller's R13)                  
         ST    R1,8(,R13)        forward chain                                  
         LR    R13,R1                                                           
         USING WAREA,R13                                                        
*                                                                               
* --- clear output cells ---                                                    
         XC    WENVOUT,WENVOUT                                                  
         XC    WREASON,WREASON                                                  
*                                                                               
* --- build INITENVB VLIST (SC28-1883-0 §14) ---                               
*                                                                               
*  P3/P4/P5: VLIST slots hold ADDRESSES of fullwords containing                 
*  the actual values. IRXINIT does L Rx,VLIST_slot then                         
*  L Ry,0(,Rx) -- a literal zero in the slot would dereference                  
*  PSA[0] and yield a non-NULL bogus pointer. Use RESZERO (a                    
*  static F'0' in the CSECT) and store its address.                             
         LA    R1,FCODE                                                         
         ST    R1,WVLIST+0       P1: function code addr                         
         LA    R1,PARMODE                                                       
         ST    R1,WVLIST+4       P2: parm module name addr                      
         LA    R1,RESZERO                                                       
         ST    R1,WVLIST+8       P3: caller PARMBLK = addr of null word         
         ST    R1,WVLIST+12      P4: user field = addr of null word             
         ST    R1,WVLIST+16      P5: reserved = addr of null word               
         LA    R1,WENVOUT                                                       
         ST    R1,WVLIST+20      P6: out ENVBLOCK addr                          
         LA    R1,WREASON                                                       
         O     R1,=X'80000000'   VL marker on last slot                         
         ST    R1,WVLIST+24      P7: out reason addr (VL=1)                     
*                                                                               
* --- call IRXINIT INITENVB ---                                                 
         SR    R0,R0              no previous-env hint                          
         LA    R1,WVLIST                                                        
         LR    R15,R2                                                           
         BALR  R14,R15                                                          
*                                                                               
* --- WTO on success; proceed regardless ---                                    
         LTR   R15,R15                                                          
         BNZ   INITDONE                                                         
         WTO   'IRXTMPW: default REXX env initialized'                          
*                                                                               
INITDONE DS    0H                                                               
* --- restore R13 and release workarea ---                                      
         L     R13,WSAVE+4       R13 = caller SA (backward chain)               
         L     R0,=A(WALEN)                                                     
         FREEMAIN RU,LV=(0),A=(R3)                                              
         DROP  R13                                                              
*                                                                               
NOINIT   DS    0H                                                               
* --- restore registers for IKJEFT01 ---                                        
         LR    R0,R5                                                            
         LR    R1,R6                                                            
         LR    R14,R7                                                           
         LR    R15,R8                                                           
*                                                                               
* --- give control to IKJEFT01 ---                                              
         XCTL  EP=IKJEFT01                                                      
*                                                                               
* --- read-only static data (RENT-safe) ---                                     
FCODE    DC    CL8'INITENVB'                                                    
PARMODE  DC    CL8' '                                                           
RESZERO  DC    F'0'                                                             
*                                                                               
         LTORG                                                                  
*                                                                               
* --- workarea DSECT ---                                                        
WAREA    DSECT                                                                  
WSAVE    DS    18F               standard save area (+0..+71)                   
WVLIST   DS    7F                INITENVB VLIST (+72..+99)                      
WENVOUT  DS    F                 P6: out ENVBLOCK pointer (+100)                
WREASON  DS    F                 P7: out reason code (+104)                     
WALEN    EQU   *-WAREA                                                          
*                                                                               
         END   IRXTMPW                                                          
