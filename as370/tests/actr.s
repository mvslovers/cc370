* ACTR bounds the conditional-assembly loops, and as370 had none.     
* Three loops pin the whole rule in one assembly:                     
*   UNDER  4000 branches, no ACTR   -- completes                      
*   OVER   4200 branches, no ACTR   -- IFO118, so the default         
*                                      lies between the two           
*   RAISED 5000 branches, ACTR 20000 -- completes                     
         MACRO                                                        
         UNDER                                                        
         LCLA  &A                                                     
&A      SETA  0                                                       
.A      ANOP                                                          
&A      SETA  &A+1                                                    
         AIF   (&A LT 4000).A                                         
         DC    AL2(&A)                                                
         MEND                                                         
         MACRO                                                        
         OVER                                                         
         LCLA  &B                                                     
&B      SETA  0                                                       
.B      ANOP                                                          
&B      SETA  &B+1                                                    
         AIF   (&B LT 4200).B                                         
         DC    AL2(&B)                                                
         MEND                                                         
         MACRO                                                        
         RAISED                                                       
         LCLA  &C                                                     
         ACTR  20000                                                  
&C      SETA  0                                                       
.C      ANOP                                                          
&C      SETA  &C+1                                                    
         AIF   (&C LT 5000).C                                         
         DC    AL2(&C)                                                
         MEND                                                         
T        CSECT                                                        
         UNDER                                                        
         OVER                                                         
         RAISED                                                       
         END                                                          
