* Die BR-Formen von BNP und BNM (#298).                                 
*                                                                       
* Die BC-Formen standen in der Tabelle, ihre BR-Gegenstuecke nicht --   
* dieselben Masken, 13 und 11. IGG0203A und IGC0009D benutzen sie, und  
* as370 meldete `Undefined operation code', wo IFOX00 sauber ist.       
*                                                                       
* Die uebrigen zehn BR-Formen stehen als Kontrolle daneben: eine        
* Maske, die man beim Ergaenzen verwechselt, faellt hier auf.           
T        CSECT                                                          
         USING *,15                                                     
         BNPR  14                                                       
         BNMR  14                                                       
         BNP   T                                                        
         BNM   T                                                        
         BR    14                                                       
         BER   14                                                       
         BNER  14                                                       
         NOPR  14                                                       
         BHR   14                                                       
         BLR   14                                                       
         BNHR  14                                                       
         BNLR  14                                                       
         BOR   14                                                       
         BNOR  14                                                       
         END                                                            
