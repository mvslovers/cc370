* a LIST of nominal values in a literal. Each is paired with its own  
* DC twin in the same assembly: the DC form was already right, so a   
* difference between the two cannot be the pool or the ordering.      
* The three F shapes are the ones the macro libraries actually use.   
T        CSECT                                                        
         USING T,15                                                   
         L     1,=F'-8,4'                                             
         L     2,=F'252,-4'                                           
         L     3,=F'128,4,128'                                        
         LH    4,=H'1,2,3'                                            
         LH    5,=HS2'100,25'                                         
A        DC    F'-8,4'                                                
B        DC    F'252,-4'                                              
C        DC    F'128,4,128'                                           
D        DC    H'1,2,3'                                               
E        DC    HS2'100,25'                                            
         LTORG                                                        
         END                                                          
