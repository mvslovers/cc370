* Eine Definition setzt sich gegen einen ER-Typ durch (#285).           
*                                                                       
* Das Geschwister von #281, eine Ebene tiefer. Dort gewann der ER die   
* ESDID der Sektion, hier gewinnt er den TYP des Symbols.               
*                                                                       
* Jede S_ER-Zuweisung steht unter `if (!s->defined)', der Typ wird also 
* nur gesetzt, solange das Symbol undefiniert ist -- und nie            
* zurueckgenommen, wenn die Definition kommt. `DC V(B)' vor Bs eigenem  
* Label laesst B dauerhaft S_ER tragen, und assign_origins uebersprang  
* solche Symbole: der LD-Eintrag bekam den sektionsrelativen Wert ohne  
* den Ursprung.                                                         
*                                                                       
* Jede TXT-Karte der betroffenen Module ist bereits identisch; die EINE 
* LD-Adresse ist die ganze Abweichung.                                  
*                                                                       
*   B liegt in einer SPAETEREN Sektion -- nur dann trennen sich Versatz 
*     und Ursprung ueberhaupt. Versatz (24) und Ursprung (16) sind mit  
*     Absicht verschieden, sonst waere nicht ablesbar, welcher fehlt.   
*   D ist die Kontrolle: ein ENTRY ohne V() davor.                      
*   EXT ist ein echter externer Verweis, der nie definiert wird.        
A        CSECT                                                          
         DC    V(B)                                                     
         DC    V(EXT)                                                   
         ENTRY B                                                        
         ENTRY D                                                        
         DS    XL8                                                      
C        CSECT                                                          
         DS    XL24                                                     
B        DS    0H                                                       
         DC    XL4'11111111'                                            
D        DS    0H                                                       
         DC    XL4'22222222'                                            
         END                                                            
