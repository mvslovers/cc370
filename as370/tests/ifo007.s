* cc370#421: a SUBSCRIPTED reference to a variable symbol declared
* WITHOUT a dimension.
*
* IFOX00 raises IFO007 USAGE OF <name> IS INCONSISTENT WITH ITS
* DECLARATION at severity 8 and generates NO OBJECT CODE for the
* statement.  as370 substituted nothing and assembled the result,
* so IEAVEXS's `LA 0,&CODE(,0)' -- MFROUTER's model card, with
* &CODE declared LCLA -- came out as `LA 0,0(0,0)' and the section
* was four bytes long, 432 against 428.
*
* THE THREE CASES BELOW ARE THE CHECK, and the two that must stay
* SILENT are what make it a check rather than a net:
*
*   &C(,0)   declared LCLA &C, used subscripted   -> IFO007
*   &A(1)    declared LCLA &A(10), used subscripted -> silent
*   &Z(1)    declared nowhere at all              -> not IFO007
*
* The middle one is a correct subscripted use and the last is the
* UNDECLARED case, which is cc370#97's and measured unsafe to
* diagnose here: as370 reaches the "names nothing" path 6,387 times
* in 771 of the 5,528 modules where IFOX00 raises nothing at all.
* This check keys on a POSITIVE DECLARATION OF THE WRONG SHAPE and
* fires in 2 modules of 5,528 -- IEAVEXS and IEAVRTI0 -- which are
* exactly the two IFOX00 flags IFO007, once each.
*
* Keep every line under column 72.
*
IFO7     CSECT
         MACRO
         M1
         LCLA  &C
         LCLA  &A(10)
&C       SETA  8
&A(1)    SETA  5
         LA    1,&C
         LA    2,&A(1)
         LA    3,&Z(1)
         LA    0,&C(,0)
         MEND
         M1
         BR    14
         END
