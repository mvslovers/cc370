* Verkettung nach einem Substring.                                      
*                                                                       
* Gefunden ueber den dritten Zeugen: IBMs ausgeliefertes DLIB-Objekt    
* und IFOX00 sind sich einig, as370 weicht ab -- ISTINCDT und fuenf     
* weitere. Bei einer stillen Abweichung sagt keiner der beiden          
* Assembler etwas, also entscheidet erst ein dritter Zeuge, wer         
* recht hat.                                                            
*                                                                       
* '&F'(1,n) unmittelbar gefolgt von '&P' ist eine VERKETTUNG, ohne      
* Punkt dazwischen. as370 wertete den Substring aus und liess den       
* zweiten Teil fallen.                                                  
*                                                                       
* Das ist die Padding-Routine, mit der IBMs USS-Makros Namen wie        
* ISTC001, ISTC002 bilden: der Zaehler steckt genau in dem Teil, der    
* wegfiel. Also hiessen alle erzeugten Bloecke gleich, und jeder        
* A(...)-Verweis darauf zeigte auf denselben Ort oder auf 0.            
*                                                                       
*   C1..C4 sind vier Zaehlerstaende. C4s Zaehler ist vierstellig,       
*   damit die LAENGE des zweiten Teils mitvariiert: ein Fix, der        
*   einfach ein Zeichen anhaengt, faellt hier durch.                    
*   C5 ist die Kontrolle -- dieselbe Verkettung MIT Punkt, die          
*   schon vorher richtig war und sich nicht bewegen darf.               
*                                                                       
* Beide Makros stehen vor dem CSECT: IFOX00 weist eine In-Stream-       
* MACRO nach dem ersten Programmsatz ab (IFO023), was die erste         
* Fassung dieser Fixture erst vom Orakel erfahren hat.                  
         MACRO                                                          
&L       PADP   &P=                                                     
         LCLC  &F,&Q                                                    
         LCLA  &K                                                       
&F       SETC  '0000000'                                                
&Q       SETC  '&F'(1,8-K'&P)'&P'                                       
&K       SETA  K'&Q                                                     
&L       DC    C'&Q',AL1(&K)                                            
         MEND                                                           
         MACRO                                                          
&L       PADD   &P=                                                     
         LCLC  &F,&Q                                                    
         LCLA  &K                                                       
&F       SETC  '0000000'                                                
&Q       SETC  '&F'(1,3).'&P'                                           
&K       SETA  K'&Q                                                     
&L       DC    C'&Q',AL1(&K)                                            
         MEND                                                           
TSTPAD   CSECT                                                          
C1       PADP  P=0                                                      
C2       PADP  P=7                                                      
C3       PADP  P=42                                                     
C4       PADP  P=1234                                                   
C5       PADD  P=9                                                      
         END                                                            
