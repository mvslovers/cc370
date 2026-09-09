* Ein USING-Operand, der mit * ANFAENGT, ist ein Ausdruck (#275).       
*                                                                       
* Gefunden ueber den dritten Zeugen: IBMs ausgeliefertes Objekt und     
* IFOX00 sind sich einig, as370 weicht ab -- IGG019GC und IGG019GD.     
*                                                                       
* `*' allein ist der Ortszaehler, `*+8' ist ein Ausdruck, der mit ihm   
* beginnt. as370 pruefte nur das erste Zeichen, nahm den blossen        
* Zaehler und warf den Rest weg. `USING *+8,R15' ist die uebliche Art,  
* die Adressierbarkeit hinter einem BALR und seinem Sicherungsbereich   
* herzustellen -- die Basis lag dann 8 Bytes zu tief und JEDE Distanz   
* ueber dieses Register kam 8 zu hoch heraus, ohne Diagnose.            
*                                                                       
*   C1  USING *+8  -- A liegt genau auf der Basis, Distanz 000          
*   C2  dasselbe Register, hoehere Adresse: 004 statt 00C               
*   C3  USING *-4  -- der Ausdruck darf auch nach unten gehen           
*   C4  Kontrolle: das blosse `*', das schon vorher richtig war         
*   C5  Kontrolle: ein Symbolausdruck ohne Stern, ebenfalls unbewegt    
TSTUSE   CSECT                                                          
         USING *+8,15                                                   
         DS    XL8                                                      
A        DS    F                                                        
B        DS    F                                                        
C1       L     1,A                                                      
C2       L     2,B                                                      
         DROP  15                                                       
         USING *-24,14                                                  
C3       L     3,B                                                      
         DROP  14                                                       
         USING *,13                                                     
D        DS    F                                                        
C4       L     4,D                                                      
         DROP  13                                                       
         USING A+4,12                                                   
C5       L     5,B                                                      
         END                                                            
