* Ein ORG, der den Ortszaehler ueber den Inhalt hinausschiebt,          
* verlaengert die Sektion (#279).                                       
*                                                                       
* Gefunden ueber den dritten Zeugen: IBMs ausgeliefertes Objekt und     
* IFOX00 sind sich einig, as370 weicht ab -- IEHINITT.                  
*                                                                       
* `ORG *+200' als Wartungsbereich am Ende eines CSECT reserviert        
* Platz, ohne ein einziges Byte TXT zu erzeugen. as370 fuehrte den      
* Sektions-Hochstand nur aus DS/DC nach, also blieb die Sektion 200     
* Bytes zu kurz -- und die FOLGENDE Sektion ruecke um dieselben 200     
* Bytes nach vorn. Beide ESD-Eintraege sind dann falsch, und jeder      
* Adressverweis in die zweite Sektion ebenso, bei rc 0.                 
*                                                                       
*   T1 endet auf ORG *+200 -- Laenge muss 201 sein, nicht 1             
*   T2 liegt dahinter -- der Ursprung zeigt es im ESD                   
*   T3 ist die Kontrolle: ein ORG RUECKWAERTS und dann Daten, die       
*      den alten Hochstand nicht ueberschreiten; die Laenge darf        
*      sich davon nicht bewegen.                                        
*   T4 prueft den blossen ORG: er kehrt zum Hochstand zurueck, und      
*      der schliesst die per ORG erreichte Stelle ein.                  
T1       CSECT                                                          
         DC    X'01'                                                    
         ORG   *+200                                                    
T2       CSECT                                                          
         DC    X'02'                                                    
T3       CSECT                                                          
         DC    XL16'03'                                                 
         ORG   *-8                                                      
         DC    XL4'04'                                                  
T4       CSECT                                                          
         DC    X'05'                                                    
         ORG   *+64                                                     
         ORG                                                            
         DC    X'06'                                                    
         END                                                            
