T        CSECT                                                        
* 1: continued onto a WHOLLY BLANK card -- IFOX00 gives IFO026        
         DC    C'AB'                                                   X
                                                                      
* 2: control -- a continuation card with text at column 16            
         DC    C'CD'                                                   X
               ,C'EF'                                                 
* 3: control -- a blank card in the MIDDLE of a continuation. The     
* blanks are DATA inside the character constant, not an empty         
* continuation, and IFOX00 does not flag it.                          
         DC    C'GH                                                    X
                                                                       X
               IJ'                                                    
         END                                                          
