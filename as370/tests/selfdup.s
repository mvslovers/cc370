* a DC whose duplication factor names its OWN label:                  
* the pad-to-N idiom, and IGE0000I is one of two modules              
* in MVSBLD that use it.                                              
T        CSECT                                                        
ERP1     DS    0H                                                     
         DC    CL10'ABCDEFGHIJ'                                       
PATCH    DC    (64-(PATCH-ERP1))X'00'                                 
* the same idiom behind a DIFFERENT run-up, so a wrong                
* answer cannot be a constant that fits the first one                 
ERP2     DS    0H                                                     
         DC    CL20'ABCDEFGHIJKLMNOPQRST'                             
PATCH2   DC    (48-(PATCH2-ERP2))X'FF'                                
LEN1     EQU   PATCH-ERP1                                             
LEN2     EQU   PATCH2-ERP2                                            
END1     EQU   *-ERP2                                                 
         DC    AL1(LEN1,LEN2,END1)                                    
         END                                                          
