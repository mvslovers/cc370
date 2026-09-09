* Ein Schluesselwort, das der Prototyp nicht kennt (#162).              
*                                                                       
* IFOX00: IFO092 KEYWORD PARAMETER <name> UNDEFINED IN MACRO            
* DEFINITION, Schweregrad 8, EINE Meldung je Schluesselwort -- und      
* die Expansion laeuft trotzdem.                                        
*                                                                       
* Dass sie trotzdem laeuft, ist der Kern und keine Nachsicht: die 118   
* Module, die das im Baum erreicht, haben bereits Decks, die byte-      
* identisch zu IFOX00s sind, weil MODID fuer einen unbekannten          
* Operanden nichts erzeugt und as370 ebenso wenig. Ein Ablehnen des     
* Aufrufs machte aus 115 Identitaeten Abweichungen. Die Divergenz ist   
* der RUECKGABECODE, den ein reiner Byte-Vergleich nicht sieht.         
*                                                                       
* Die Ursache liegt nicht bei uns: SYS1.AMACLIB(MODID) auf dem Ziel     
* ist ein aelterer Wartungsstand als die Quelle, die es ruft.           
*                                                                       
*   C1  nur deklarierte Schluesselwoerter -- keine Meldung              
*   C2  eines unbekannt -- eine Meldung                                 
*   C3  ZWEI unbekannte in EINER Anweisung -- zwei Meldungen, aber      
*       nur EINE markierte Anweisung. Das trennt die Meldungszahl       
*       von der Anweisungszahl, und nur so ist die Zaehlregel           
*       ueberhaupt geprueft.                                            
*   C4  positional PLUS deklariertes Schluesselwort -- keine Meldung    
*                                                                       
* Alle vier erzeugen ihr DC: der Deck ist byte-identisch, nur rc 8      
* trennt vorher und nachher.                                            
         MACRO                                                          
&L       MYM   &A=,&B=                                                  
&L       DC    AL1(1)                                                   
         MEND                                                           
T        CSECT                                                          
C1       MYM   A=1,B=2                                                  
C2       MYM   A=1,ZZ=2                                                 
C3       MYM   ZZ=2,YY=3                                                
C4       MYM   1,A=2                                                    
         END                                                            
