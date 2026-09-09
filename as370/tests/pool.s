* how does IFOX00 lay out a literal pool of mixed widths?             
* the references are in a deliberately awkward order, so a pool       
* that merely follows first-reference order cannot match one that     
* groups by size.                                                     
T        CSECT                                                        
         USING T,15                                                   
         L     0,=A(X)                                                
         MVC   0(1,1),=C'A'                                           
         LH    2,=H'1'                                                
         L     3,=F'3'                                                
         MVC   0(3,1),=X'FFFFFF'                                      
         LD    4,=D'1.0'                                              
         LH    6,=H'2'                                                
         L     7,=F'4'                                                
         MVC   0(5,1),=C'ABCDE'                                       
         LTORG                                                        
X        DS    F                                                      
         END                                                          
