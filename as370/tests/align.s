* IFO220: a storage operand the assembler resolved itself, whose      
* address is not on the boundary the instruction requires. It is a    
* warning -- the instruction assembles unchanged.                     
T        CSECT                                                        
         USING T,15                                                   
         DC    C'A'                                                   
ODDF     DS    CL4                      at x'1', not fullword         
         DS    0F                                                     
GOODF    DS    F                        aligned                       
         DC    C'A'                                                   
ODDH     DS    CL2                      not halfword aligned          
* 1: symbol, misaligned -- IFO220                                     
         L     1,ODDF                                                 
* 2: symbol, aligned -- silent                                        
         L     2,GOODF                                                
* 3: symbol, misaligned halfword -- IFO220                            
         LH    3,ODDH                                                 
* 4: the control. Explicit base: the address is not known here        
* and IFOX00 does not check it, however odd the displacement.         
         L     4,7(,9)                                                
* 5: an instruction with no alignment requirement at all              
         IC    5,ODDF                                                 
* 6: the control that cost 95 modules. BXLE's operand is a BRANCH     
* TARGET, not a data reference -- LOOP is halfword aligned and not    
* fullword aligned, which is the ordinary case for any label.         
LOOP     BXLE  6,8,LOOP                                               
         END                                                          
