         COPY  PDPTOP                                                           
         CSECT                                                                  
* Program text area                                                             
@V1      EQU   *                                                                
         DC    C'/* REXX/370 demo exec */'                                      
         DC    X'15'                                                            
         DC    C'say ''Hello from REXX/370!'''                                  
         DC    X'15'                                                            
         DC    C'say ''Running as'' USERID() ''(NUMERIC DIGITS ='               
         DC    C''' DIGITS()'')'''                                              
         DC    X'15'                                                            
         DC    C'say'                                                           
         DC    X'15'                                                            
         DC    X'15'                                                            
         DC    C'say ''--- Arithmetic ---'''                                    
         DC    X'15'                                                            
         DC    C'say ''  2 ** 28        ='' 2 ** 28'                            
         DC    X'15'                                                            
         DC    C'say ''  355 / 113 (pi) ='' 355 / 113'                          
         DC    X'15'                                                            
         DC    C'numeric digits 20'                                             
         DC    X'15'                                                            
         DC    C'say ''  pi at digits=20:'' 355 / 113'                          
         DC    X'15'                                                            
         DC    C'numeric digits 9'                                              
         DC    X'15'                                                            
         DC    X'15'                                                            
         DC    C'fact = 1'                                                      
         DC    X'15'                                                            
         DC    C'do i = 1 to 10'                                                
         DC    X'15'                                                            
         DC    C'   fact = fact * i'                                            
         DC    X'15'                                                            
         DC    C'end'                                                           
         DC    X'15'                                                            
         DC    C'say ''  10! (iterative) ='' fact'                              
         DC    X'15'                                                            
         DC    C'say'                                                           
         DC    X'15'                                                            
         DC    X'15'                                                            
         DC    C'greet = ''hello world'''                                       
         DC    X'15'                                                            
         DC    C'say ''--- String BIFs on "''greet''" ---'''                    
         DC    X'15'                                                            
         DC    C'say ''  LENGTH    ='' LENGTH(greet)'                           
         DC    X'15'                                                            
         DC    C'say ''  REVERSE   ='' REVERSE(greet)'                          
         DC    X'15'                                                            
         DC    C'say ''  uppercase ='' TRANSLATE(greet)'                        
         DC    X'15'                                                            
         DC    C'say ''  SUBSTR 7  ='' SUBSTR(greet, 7)'                        
         DC    X'15'                                                            
         DC    C'say ''  WORDS/W2  ='' WORDS(greet) ''/'' WORD(gr'              
         DC    C'eet, 2)'                                                       
         DC    X'15'                                                            
         DC    C'say ''  CENTER    ='' CENTER(greet, 20, ''.'')'                
         DC    X'15'                                                            
         DC    C'say'                                                           
         DC    X'15'                                                            
         DC    X'15'                                                            
         DC    C'say ''--- DO + SELECT ---'''                                   
         DC    X'15'                                                            
         DC    C'do n = 1 to 5'                                                 
         DC    X'15'                                                            
         DC    C'   select'                                                     
         DC    X'15'                                                            
         DC    C'      when n // 2 = 0 then kind = ''even'''                    
         DC    X'15'                                                            
         DC    C'      otherwise            kind = ''odd '''                    
         DC    X'15'                                                            
         DC    C'   end'                                                        
         DC    X'15'                                                            
         DC    C'   say ''  n ='' RIGHT(n, 2) ''is'' kind'                      
         DC    X'15'                                                            
         DC    C'end'                                                           
         DC    X'15'                                                            
         DC    C'say'                                                           
         DC    X'15'                                                            
         DC    X'15'                                                            
         DC    C'say ''--- Conversion BIFs ---'''                               
         DC    X'15'                                                            
         DC    C'say ''  C2X("ABC") ='' C2X(''ABC'')'                           
         DC    X'15'                                                            
         DC    C'say ''  D2X(255)   ='' D2X(255)'                               
         DC    X'15'                                                            
         DC    C'say ''  X2D("FF")  ='' X2D(''FF'')'                            
         DC    X'15'                                                            
         DC    C'say'                                                           
         DC    X'15'                                                            
         DC    X'15'                                                            
         DC    C'say ''--- PARSE VAR ---'''                                     
         DC    X'15'                                                            
         DC    C'full = ''Grace Murray Hopper'''                                
         DC    X'15'                                                            
         DC    C'parse var full first mid last'                                 
         DC    X'15'                                                            
         DC    C'say ''  full   ='' full'                                       
         DC    X'15'                                                            
         DC    C'say ''  first  ='' first'                                      
         DC    X'15'                                                            
         DC    C'say ''  middle ='' mid'                                        
         DC    X'15'                                                            
         DC    C'say ''  last   ='' last'                                       
         DC    X'15'                                                            
         DC    C'say'                                                           
         DC    X'15'                                                            
         DC    X'15'                                                            
         DC    C'say ''--- TSK-155 ---'''                                       
         DC    X'15'                                                            
         DC    C'say ''  C2X(ERRORTEXT(6))  ='' C2X(ERRORTEXT(6))'              
         DC    X'15'                                                            
         DC    C'say ''  C2X(ERRORTEXT(31)) ='' C2X(ERRORTEXT(31)'              
         DC    C')'                                                             
         DC    X'15'                                                            
         DC    C'say ''Demo complete. Exiting with RC=0.'''                     
         DC    X'15'                                                            
         DC    C'say'                                                           
         DC    X'15'                                                            
         DC    C'exit 0'                                                        
         DC    X'15'                                                            
         DC    X'0'                                                             
@@LC0    EQU   *                                                                
         DC    C'IRX#HELO: irx_exec_run failed (rc=%d)'                         
         DC    X'15'                                                            
         DC    X'0'                                                             
         DS    0F                                                               
         DC    C'GCCMVS!!'                                                      
         EXTRN @@CRT0                                                           
         ENTRY @@MAIN                                                           
@@MAIN   DS    0H                                                               
         BALR  15,0                                                             
         USING *,15                                                             
         L     15,=V(@@CRT0)                                                    
         BR    15                                                               
         DROP  15                                                               
         LTORG                                                                  
* X-func main prologue                                                          
MAIN     PDPPRLG CINDEX=0,FRAME=120,BASER=12,ENTRY=YES                          
         B     @@FEN0                                                           
         LTORG                                                                  
@@FEN0   EQU   *                                                                
         DROP  12                                                               
         BALR  12,0                                                             
         USING *,12                                                             
@@PG0    EQU   *                                                                
         LR    11,1                                                             
         L     10,=A(@@PGT0)                                                    
* Function main code                                                            
         MVC   112(4,13),=F'0'                                                  
         MVC   88(4,13),=A(@V1)                                                 
         MVC   92(4,13),=F'1323'                                                
         MVC   96(4,13),=F'0'                                                   
         MVC   100(4,13),=F'0'                                                  
         LA    2,112(,13)                                                       
         ST    2,104(13)                                                        
         MVC   108(4,13),=F'0'                                                  
         LA    1,88(,13)                                                        
         L     15,=V(IRX@EXEC)                                                  
         BALR  14,15                                                            
         LR    2,15                                                             
         LTR   15,15                                                            
         BE    @@L2                                                             
         MVC   88(4,13),=A(@@LC0)                                               
         ST    15,92(13)                                                        
         LA    1,88(,13)                                                        
         L     15,=V(PRINTF)                                                    
         BALR  14,15                                                            
         LR    15,2                                                             
         B     @@L1                                                             
@@L2     EQU   *                                                                
         L     12,0(,10)                                                        
         L     15,112(13)                                                       
@@L1     EQU   *                                                                
         L     12,0(,10)                                                        
* Function main epilogue                                                        
         PDPEPIL                                                                
* Function main literal pool                                                    
         DS    0F                                                               
         LTORG                                                                  
* Function main page table                                                      
         DS    0F                                                               
@@PGT0   EQU   *                                                                
         DC    A(@@PG0)                                                         
         END   @@MAIN                                                           
