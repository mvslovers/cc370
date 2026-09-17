* cc370#425: a COPY member is resolved BY THE NAME AS WRITTEN.
*
* lib_path() lowercased the member name and never tried it as
* written, so `COPY CPYUPR' opened only `cpyupr'.  An MVS member
* name IS uppercase and every macro library this project has is
* stored that way: across the ten -I directories gate.sh passes,
* 2,041 files are uppercase, 0 are lowercase and the one mixed
* name is a README.  On a case-sensitive filesystem lib_path
* found NONE of them.
*
* THE FAILURE DOES NOT LOOK LIKE A PATH PROBLEM.  A member that
* does not resolve makes every macro call an undefined operation
* code and every symbol it defines an undefined symbol, so the
* module assembles short with addressability errors -- which is
* exactly what #241's 32 EREP modules look like, and that is a
* gap this project has hunted twice already.
*
* THIS FIXTURE CANNOT FAIL ON macOS, BEFORE OR AFTER THE FIX.
* APFS answers a lowercase open with an uppercase file, so both
* spellings resolve here whichever pass finds them.  CI's Linux
* is not a check on this change, it is the only instrument for
* it.  What the pre-fix binary scores THERE is recorded in
* run.sh beside the test.
*
* Keep every line under column 72.
*
CPYC     CSECT
         COPY  CPYUPR
         COPY  CPYLOW
         BR    14
         END
