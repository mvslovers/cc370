* Der Sektions-Hochstand muss auch in PASS 1 steigen (#282).            
*                                                                       
* Gefunden ueber den dritten Zeugen: IBMs ausgeliefertes Objekt und     
* IFOX00 sind sich einig, as370 weicht ab -- AMASPZAP.                  
*                                                                       
* Er wurde von DS/DC gesetzt und von put(), und put() laeuft nur in     
* Pass 2. Eine Sektion, die auf MASCHINENBEFEHLE endet, war also beim   
* Verketten der naechsten nur bis zu ihrem letzten DS/DC lang -- und    
* die beiden Sektionen UEBERLAPPTEN. Die eigene ESD-Laenge stimmte      
* dabei, weil sie aus Pass 2 kommt; nur der Ursprung der naechsten      
* Sektion war falsch. AMASZDMP endet 332 Bytes hinter seinem letzten    
* DS, und AMASZCON lag genau 332 Bytes in ihm drin.                     
*                                                                       
*   T1 endet auf einem Befehl und laeuft ueber die Doppelwortgrenze     
*      hinaus: Laenge 00000C, T2 muss auf 000010 liegen (vorher 8).     
*   T3 endet auf einem CCW -- derselbe Pfad, dieselbe Luecke.           
*   T5 ist die Kontrolle: eine Sektion, die auf DC endet, war schon     
*      vorher richtig und darf sich nicht bewegen.                      
T1       CSECT                                                          
         DS    XL8                                                      
         L     1,0(2)                                                   
T2       CSECT                                                          
         DC    X'02'                                                    
T3       CSECT                                                          
         DS    XL4                                                      
         CCW   1,0,0,8                                                  
T4       CSECT                                                          
         DC    X'04'                                                    
T5       CSECT                                                          
         DC    XL9'05'                                                  
T6       CSECT                                                          
         DC    X'06'                                                    
         END                                                            
