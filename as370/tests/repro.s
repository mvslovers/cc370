* REPRO punches the NEXT card into the object deck as it stands.      
* Where does it land -- at the front, or where it was written?        
         REPRO                                                        
CARD-BEFORE-THE-CSECT                                                 
T        CSECT                                                        
         DC    C'AAAA'                                                
         REPRO                                                        
CARD-IN-THE-MIDDLE                                                    
         DC    C'BBBB'                                                
         REPRO                                                        
CARD-AT-THE-END                                                       
         DC    C'CCCC'                                                
         END                                                          
