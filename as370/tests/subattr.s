* Der Attribut-Apostroph in einer SUBLIST (#300).                       
*                                                                       
* Ein Attribut-Apostroph ist kein Anfuehrungszeichen, und innerhalb     
* einer Zeichenkette kann ein Apostroph nur schliessen -- dasselbe      
* Regelpaar, das parse() in #182, split_card() in #183 und dc_split()   
* in #218 gebraucht hat. Die SUBLIST-Leser sind das vierte Augenpaar    
* auf dieser Syntax und hatten es nie.                                  
*                                                                       
* `ENQ (SYSZPSWD,,E,L'JFCBDSNM,SYSTEM),MF=L' zaehlte VIER Elemente,     
* wo IFOX00 fuenf zaehlt, und Element 4 kam als das einzelne Zeichen    
* `L' zurueck, mit dem Rest der Liste verschluckt. Das Makro erzeugte   
* daraufhin SYSTEM als Symbol statt als Geltungsbereich.                
*                                                                       
* Gemessen wird ueber K' und N', nicht ueber den Text: ein Wert, der    
* selbst einen Apostroph enthaelt, zerlegt die MNOTE, in die man ihn    
* einsetzt -- was die erste Fassung dieser Sonde erst gezeigt hat.      
*                                                                       
*   N=5  K3=1  K4=3  K5=6      (E, L'F, SYSTEM)                         
*   vorher N=4, und K4 auf dem abgeschnittenen Rest                     
         MACRO                                                          
         SUBP  &P                                                       
         LCLA  &N,&K3,&K4,&K5                                           
&N       SETA  N'&P                                                     
&K3      SETA  K'&P(3)                                                  
&K4      SETA  K'&P(4)                                                  
&K5      SETA  K'&P(5)                                                  
         DC    AL1(&N,&K3,&K4,&K5)                                      
         MEND                                                           
T        CSECT                                                          
F        DS    CL8                                                      
         SUBP  (SYSZPSWD,,E,L'F,SYSTEM)                                 
         SUBP  (A,B,C)                                                  
         END                                                            
