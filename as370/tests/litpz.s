* a packed or zoned LITERAL. Each one is paired with its own DC twin  
* in the same assembly: the DC form was already right, so a difference
* between the two cannot be the pool, the alignment or the ordering.  
T        CSECT                                                        
         USING T,15                                                   
         AP    0(2,1),=P'0'                                           
         AP    0(3,1),=P'12345'                                       
         AP    0(3,1),=PL3'7'                                         
         MVC   0(3,1),=Z'123'                                         
         MVC   0(2,1),=ZL2'9'                                         
A        DC    P'0'                                                   
B        DC    P'12345'                                               
C        DC    PL3'7'                                                 
D        DC    Z'123'                                                 
E        DC    ZL2'9'                                                 
         LTORG                                                        
         END                                                          
