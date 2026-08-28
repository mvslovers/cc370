* issue #63 -- a DCB twelve bytes short, from two silent truncations.
*
* An ordinary QSAM DCB expands correctly on its own.  It stops doing so
* once the VSAM macros have been expanded first, which is why the defect
* needed a real module to surface: SYS1.MACLIB's MODCB/ACB/RPL exhaust
* the list of names known to be global, so IHB01's "&COMSW SETB 1" is no
* longer recognised as a global assignment, goes to IHB01's own local
* table, and DCB reads back an unset -- and therefore false -- switch.
* It then takes the wrong branch and skips the common-interface block:
* BUFNO, BUFCB, BUFL, DSORG and IOBAD, twelve bytes, ahead of the
* DDNAME.  RC 0, no diagnostic.
*
* The order matters: MODCB before DCB is what fills the table.  All four
* macros come from libc370's sysmac mirror, so this runs from a plain
* checkout -- no SYS1.MACLIB extract needed.
T        CSECT
         USING T,12
         MODCB RPL=R1,OPTCD=(KEY,DIR)
FD000    DCB   DDNAME=CARDIN,DSORG=PS,MACRF=(GM)
A1       ACB   DDNAME=VS1,MACRF=(KEY,DIR,IN)
R1       RPL   ACB=A1,AREA=BUF,AREALEN=80,OPTCD=(KEY,DIR)
BUF      DS    CL80
         END
