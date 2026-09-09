* Ein CSECT, dessen Name schon einen ER aus V() hat (#281).             
*                                                                       
* s->esdid speist cur_sect_esdid und damit die ESDID der TXT-Karte.     
* Die Zuweisung nahm den ERSTEN Eintrag und stuetzte sich darauf, dass  
* der SD einer Sektion vor jedem ER desselben Namens registriert wird.  
* Das stimmt nicht, sobald der Name zuerst REFERENZIERT wird: `DC V(B)' 
* vor `B CSECT' registriert Bs ER zuerst, und Bs gesamter TXT landete   
* unter dieser ID.                                                      
*                                                                       
* Das ESD selbst war richtig -- beide Eintraege da, richtige Typen,     
* Laengen und Ursprung. Falsch war allein, welche Sektion die TXT-Karte 
* nennt, weshalb kein Vergleich der Bytes EINER Sektion das sehen kann. 
*                                                                       
*   B  ist der Fall: V(B) steht vor B CSECT.                            
*   C  ist die Kontrolle in der ueblichen Reihenfolge -- CSECT zuerst,  
*      V() danach; die darf sich nicht bewegen.                         
*   EXT ist ein echter externer Verweis, der nie eine Sektion wird;     
*      sein ER und sein RLD-Eintrag muessen unveraendert bleiben.       
A        CSECT                                                          
         DC    V(B)                                                     
         DC    V(EXT)                                                   
         DC    XL4'11111111'                                            
C        CSECT                                                          
         DC    XL4'33333333'                                            
A        CSECT                                                          
         DC    V(C)                                                     
B        CSECT                                                          
         DC    XL8'2222222222222222'                                    
         END                                                            
