* a duplication factor in a LITERAL: =8X'0F' is eight bytes, and a    
* literal of the right length also lands in the right pool segment,   
* so the factor decides the ORDER as well as the size.                
T        CSECT                                                        
         USING T,15                                                   
         MVC   0(1,1),=C'A'                                           
         MVC   0(8,1),=8X'0F'                                         
         L     2,=F'1'                                                
         MVC   0(4,1),=4X'FF'                                         
         MVC   0(6,1),=3C'AB'                                         
         L     3,=2F'7'                                               
         LH    4,=H'9'                                                
         LTORG                                                        
         END                                                          
