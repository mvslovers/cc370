* An address constant written in extra parentheses. The value was     
* always right; the RLD entry was not, because both scanners that     
* find the relocation target skipped a parenthesised group whole.     
T        CSECT                                                        
TGT      DS    0H                                                     
ABS      EQU   4                                                      
* 1: plain -- the control that always worked                          
         DC    A(TGT)                                                 
* 2: grouped -- the case                                              
         DC    A((TGT))                                               
* 3: grouped inside an expression                                     
         DC    A((TGT)+4)                                             
* 4: grouped ABSOLUTE -- no relocation is correct here, and 38        
* MVSBLD modules write exactly this shape                             
         DC    A((ABS))                                               
* 5: a difference of two labels -- absolute, no relocation            
         DC    A((TGT-TGT))                                           
* 6: a machine operand with a SUBSCRIPT, not a group. The rule is     
* positional and this is the half that must keep skipping.            
         USING T,15                                                   
         L     1,TGT(2)                                               
         END                                                          
