* an attribute apostrophe must not open a quoted body: the next       
* literal's digits then read as one over-long symbol and the          
* instruction is zeroed for a name nobody wrote.                      
D        DSECT                                                        
         DS    CL4                                                    
FLD      DS    CL8                                                    
T        CSECT                                                        
         USING T,15                                                   
         USING D,3                                                    
* 1: L' in the length field, then a hex literal                       
         CLC   FLD-D(L'FLD,3),=X'FF00000000000000'                    
* 2: the control -- same statement, numeric length                    
         CLC   FLD-D(8,3),=X'FF00000000000000'                        
* 3: a character literal behind an attribute reference                
         CLC   FLD-D(L'FLD,3),=C'ABCDEFGH'                            
* 4: X' really does quote -- FF00 is a body, not a symbol             
         MVC   FLD-D(2,3),=X'FF00'                                    
         LTORG                                                        
         END                                                          
