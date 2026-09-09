* Feste Grenzen im DC-Pfad (#270).                                      
*                                                                       
* Ein DC-Operand hielt hoechstens 32 Nominalwerte und jeden EINZELNEN   
* Wert in 80 Bytes. Beides ist still: der Rest faellt weg, der          
* Ortszaehler laeuft zu frueh weiter, und jede spaetere Adresse in      
* der Sektion ist falsch.                                               
*                                                                       
* Die Grenze ist in gueltiger Quelle erreichbar, und das ist der        
* Punkt: ein DC ist eine Assembler-Operation und bekommt ZWEI           
* Fortsetzungen, also bis etwa 168 Zeichen Operand -- Platz fuer        
* rund 55 kurze Werte, also deutlich mehr als 32.                       
*                                                                       
*   C1  48 Werte auf drei Karten -- vorher 32, also 64 Bytes zu kurz    
*   C2  EIN Wert aus zehn achtstelligen Symbolen, 89 Zeichen --         
*       vorher bei 79 mitten im zehnten Symbol abgeschnitten.           
*       Zehn Terme und nicht fuenfzig, weil IFOX00 einen Ausdruck       
*       ausserhalb der bedingten Assemblierung bei 20 Termen            
*       abweist (IFO168) und die Fixture gueltige Quelle sein muss.     
*   C3  Kontrolle: drei Werte, war immer richtig                        
*                                                                       
* L1 und L2 halten die erzeugte Laenge fest, damit der Vergleich        
* den Ortszaehler prueft und nicht nur die Bytes.                       
TSTDC    CSECT                                                          
S0000001 EQU   1                                                        
S0000002 EQU   2                                                        
S0000003 EQU   3                                                        
S0000004 EQU   4                                                        
S0000005 EQU   5                                                        
S0000006 EQU   6                                                        
S0000007 EQU   7                                                        
S0000008 EQU   8                                                        
S0000009 EQU   9                                                        
S0000010 EQU   10                                                       
D1       DC    A(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,X
               22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40X
               ,41,42,43,44,45,46,47,48)                                
L1       EQU   *-D1                                                     
D2       DC    A(S0000001+S0000002+S0000003+S0000004+S0000005+S0000006+X
               S0000007+S0000008+S0000009+S0000010)                     
L2       EQU   *-D2                                                     
D3       DC    A(1,2,3)                                                 
         DC    AL2(L1,L2)                                               
         END                                                            
