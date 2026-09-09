* Feste Puffergroessen im Makropfad -- eine Fixture pro Grenze (#153).  
*                                                                       
* Alle sind still: der Wert wird gekuerzt, K' meldet die gekuerzte      
* Laenge, und niemand sagt etwas, solange niemand einen Wert dieser     
* Groesse schreibt.  as370 hielt Parameterwerte in 96 Bytes, Defaults   
* im Prototyp in 40, &SYSLIST-Elemente in 128 und SETC in 96.           
*                                                                       
* IFOX00s Grenze ist 255, gemessen: bei 255 sauber, ab 256 IFO042       
* PARAMETER ... EXCEEDS 255 CHARACTERS, Schweregrad 8.                  
*                                                                       
*   C1  positionaler Wert (200), Default im Prototyp (60), und          
*       &SYSLIST(1) -- alle drei aus EINEM Aufruf                       
*   C2  derselbe Wert im SCHLUESSELWORT statt positional                
*   C3  SETC in offenem Code, 150 Zeichen -- ein SETC ist eine          
*       Assembler-Operation und damit auf ZWEI Fortsetzungen            
*       begrenzt (IFO069); ein Makroaufruf ist es nicht, C1 und         
*       C2 stehen auf vier Karten. Genau die Asymmetrie aus #78.        
*                                                                       
* C1s dritter Wert ist die Probe darauf, dass die Elementgrenze         
* getrennt von der Parametergrenze war: 95 gegen 127, zwei Puffer.      
         MACRO                                                          
&N       KP    &P,&KW=DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDX
               DDDDDDDDDDD                                              
         LCLA  &LA,&LB,&LC                                              
&LA      SETA  K'&P                                                     
&LB      SETA  K'&KW                                                    
&LC      SETA  K'&SYSLIST(1)                                            
&N       DC    AL2(&LA,&LB,&LC)                                         
         MEND                                                           
TSTBUF   CSECT                                                          
         LCLC  &S                                                       
         LCLA  &L5                                                      
C1       KP    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAX
               AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAX
               AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAX
               AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA                         
C2       KP    B,KW=CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCX
               CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCX
               CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCX
               CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC                    
&S       SETC  'EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEX
               EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEX
               EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE'                 
&L5      SETA  K'&S                                                     
C3       DC    AL2(&L5)                                                 
         END                                                            
