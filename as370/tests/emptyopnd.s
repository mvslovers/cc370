* Ein Operand, der zu nichts substituiert, bleibt leer (#295).          
*                                                                       
* as370 substituierte die ganze Karte und parste sie neu -- und         
* parse() kann `INNER          REMARK HERE' (ein verschwundener         
* Operand) nicht von einer so geschriebenen Karte unterscheiden. Also   
* las es das erste Wort der BEMERKUNG als Operanden.                    
*                                                                       
* Gefunden ueber BLSCAMOD: BLSCAMMM ruft                                
*   BLSCAMM1 &DYRB(2)         COUNT FLAGS1 ENTRIES                      
* mit einem &DYRB, das keine Sublist ist -- &DYRB(2) ist null, und das  
* zaehlende Makro bekam die Zeichenkette COUNT. Ein Element statt       
* keinem, eine Schleife, die nicht laufen darf, und eine MNOTE eines    
* Makros, das sich ueber Eingaben beschwert, die wir erfunden haben.    
*                                                                       
*   C1  &P(2) auf einem &P, das keine Sublist ist -> leer, K' = 0       
*   C2  ein ungesetztes Schluesselwort -> leer, K' = 0                  
*   C3  Kontrolle: &P(1) liefert AL, K' = 2 -- war immer richtig        
*                                                                       
* K' und nicht der Text, damit der DECK die Antwort traegt: vorher      
* 6,6,2 (K'REMARK, K'SECOND), nachher 0,0,2.                            
         MACRO                                                          
         INNER &A                                                       
         LCLA  &K                                                       
&K       SETA  K'&A                                                     
         DC    AL1(&K)                                                  
         MEND                                                           
         MACRO                                                          
         OUTER &P=AL,&Q=                                                
         INNER &P(2)         REMARK HERE                                
         INNER &Q            SECOND REMARK                              
         INNER &P(1)         THIRD REMARK                               
         MEND                                                           
T        CSECT                                                          
         OUTER                                                          
         END                                                            
