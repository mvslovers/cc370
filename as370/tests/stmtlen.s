* Drei stille Deckel auf der Laenge EINER Anweisung (#153).             
*                                                                       
* join_cont baut eine fortgesetzte Anweisung in acc[8192]; alles        
* dahinter deckelte bei etwa 1024, und zwar OHNE jede Diagnose:         
*   - sysvar_sub schnitt JEDE Quellzeile bei 1022 ab,                   
*   - parse() den Operanden bei 1023,                                   
*   - und &SYSLIST wird als EINE synthetische Sublist gebaut, deren     
*     Puffer die GANZE Liste begrenzte statt eines Elements: bei        
*     gewoehnlicher Operandenbreite war nach etwa 61 Schluss.           
* Dazu ein vierter, ausgesprochener Deckel: MAXSYSLIST stand auf 64,    
* eine Grenze, die IFOX00 nicht hat.                                    
*                                                                       
* Der Aufruf traegt 86 positionale Operanden -- die Zahl aus dem        
* DBV-Aufruf in JTEXT -- und ist mit Absicht ueber 1022 Zeichen lang,   
* damit er alle vier zugleich prueft. &SYSLIST(70) liegt hinter der     
* 64er-Grenze, &SYSLIST(86) hinter dem Puffer.                          
*                                                                       
* Vorher: rc 8 mit 'More than 64', und das DC bekam leere Werte.        
* IFOX00 und jetzt: X'4D58' -- 77 und 88.                               
*                                                                       
* T2 ist die Kontrolle: derselbe Aufruf mit vier Operanden war schon    
* vorher richtig und darf sich nicht bewegen.                           
         MACRO                                                          
&N       SLTAIL &Z                                                      
&N       DC    AL1(&SYSLIST(70),&SYSLIST(86))                           
         MEND                                                           
         MACRO                                                          
&N       SLSHRT &Z                                                      
&N       DC    AL1(&SYSLIST(2),&SYSLIST(4))                             
         MEND                                                           
TSTLONG  CSECT                                                          
T1       SLTAIL 1+0+0+0+0+0,2+0+0+0+0+0,3+0+0+0+0+0,                   X
               4+0+0+0+0+0,5+0+0+0+0+0,6+0+0+0+0+0,7+0+0+0+0+0,        X
               8+0+0+0+0+0,9+0+0+0+0+0,1+0+0+0+0+0,2+0+0+0+0+0,        X
               3+0+0+0+0+0,4+0+0+0+0+0,5+0+0+0+0+0,6+0+0+0+0+0,        X
               7+0+0+0+0+0,8+0+0+0+0+0,9+0+0+0+0+0,1+0+0+0+0+0,        X
               2+0+0+0+0+0,3+0+0+0+0+0,4+0+0+0+0+0,5+0+0+0+0+0,        X
               6+0+0+0+0+0,7+0+0+0+0+0,8+0+0+0+0+0,9+0+0+0+0+0,        X
               1+0+0+0+0+0,2+0+0+0+0+0,3+0+0+0+0+0,4+0+0+0+0+0,        X
               5+0+0+0+0+0,6+0+0+0+0+0,7+0+0+0+0+0,8+0+0+0+0+0,        X
               9+0+0+0+0+0,1+0+0+0+0+0,2+0+0+0+0+0,3+0+0+0+0+0,        X
               4+0+0+0+0+0,5+0+0+0+0+0,6+0+0+0+0+0,7+0+0+0+0+0,        X
               8+0+0+0+0+0,9+0+0+0+0+0,1+0+0+0+0+0,2+0+0+0+0+0,        X
               3+0+0+0+0+0,4+0+0+0+0+0,5+0+0+0+0+0,6+0+0+0+0+0,        X
               7+0+0+0+0+0,8+0+0+0+0+0,9+0+0+0+0+0,1+0+0+0+0+0,        X
               2+0+0+0+0+0,3+0+0+0+0+0,4+0+0+0+0+0,5+0+0+0+0+0,        X
               6+0+0+0+0+0,7+0+0+0+0+0,8+0+0+0+0+0,9+0+0+0+0+0,        X
               1+0+0+0+0+0,2+0+0+0+0+0,3+0+0+0+0+0,4+0+0+0+0+0,        X
               5+0+0+0+0+0,6+0+0+0+0+0,77+0+0+0+0+0,8+0+0+0+0+0,       X
               9+0+0+0+0+0,1+0+0+0+0+0,2+0+0+0+0+0,3+0+0+0+0+0,        X
               4+0+0+0+0+0,5+0+0+0+0+0,6+0+0+0+0+0,7+0+0+0+0+0,        X
               8+0+0+0+0+0,9+0+0+0+0+0,1+0+0+0+0+0,2+0+0+0+0+0,        X
               3+0+0+0+0+0,4+0+0+0+0+0,88+0+0+0+0+0                     
T2       SLSHRT 1,44+0,3,55+0                                           
         END                                                            
