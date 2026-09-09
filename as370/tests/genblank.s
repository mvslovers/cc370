* Ein Leerzeichen in einer ERZEUGTEN Anweisung beendet den Operanden    
* nicht (#302).                                                         
*                                                                       
* IFOX00 legt die Feldgrenzen auf der MODELLKARTE fest und substituiert 
* hinein -- eine Variable, deren Wert ein Leerzeichen ist, bleibt also  
* im Operandenfeld. as370 parste den substituierten Text neu und blieb  
* an diesem Leerzeichen stehen.                                         
*                                                                       
* Das Spiegelbild von #295: dort musste ein Operand, der zu NICHTS      
* substituiert, leer bleiben; hier muss einer, der zu einem LEERZEICHEN 
* substituiert, im Feld bleiben. Dieselbe Wurzel -- die Grenzen         
* gehoeren der Modellkarte, nicht dem Ergebnis.                         
*                                                                       
* Gefunden ueber IFDOLT12: IFDCOM erzeugt `IFDPF1 &V,&X,&Z,&S' mit &Z   
* als einzelnem Leerzeichen. as370 verlor damit BEIDE restlichen        
* Operanden, &S war leer, ein AIF darauf nahm den falschen Zweig, und   
* PARTITEM wurde nie definiert -- 400 Karten weiter als undefiniertes   
* Symbol gemeldet.                                                      
*                                                                       
*   K'&C = 1 (ein Leerzeichen)   und   C'&D' = MVM22                    
*   vorher: K'&C = 0 und &D leer                                        
         MACRO                                                          
         INNER &A,&B,&C,&D                                              
         LCLA  &K                                                       
&K       SETA  K'&C                                                     
         DC    AL1(&K)                                                  
         DC    C'&D'                                                    
         MEND                                                           
         MACRO                                                          
         OUTER                                                          
         LCLC  &Z,&S                                                    
&Z       SETC  ' '                                                      
&S       SETC  'MVM22'                                                  
         INNER DS,C,&Z,&S                                               
         MEND                                                           
T        CSECT                                                          
         OUTER                                                          
         END                                                            
