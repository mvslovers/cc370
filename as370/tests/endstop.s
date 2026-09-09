* END beendet die Assemblierung (#288).                                 
*                                                                       
* Karten hinter dem ersten END werden nicht gelesen, nicht gelistet     
* und nicht assembliert. as370 las weiter.                              
*                                                                       
* Das ist keine Spitzfindigkeit: im MVSBLD-Baum stehen Module, hinter   
* deren END die Quelle eines ZWEITEN Moduls angehaengt ist. as370       
* assemblierte beide in dasselbe Objekt -- ISTINCU7 kam mit drei        
* Kontrollsektionen und 2269 Bytes heraus, wo IFOX00 eine und 210 hat,  
* weil IKJEGAPL 1100 Karten hinter dem END definiert wird.              
*                                                                       
*   A steht vor dem END und muss allein im Deck stehen.                 
*   B steht dahinter: seine Sektion darf im ESD gar nicht auftauchen,   
*     nicht bloss leer sein -- deshalb prueft die Fixture den ganzen    
*     Deck und nicht einzelne Bytes.                                    
A        CSECT                                                          
         DC    XL4'11111111'                                            
         END                                                            
B        CSECT                                                          
         DC    XL4'22222222'                                            
         END                                                            
