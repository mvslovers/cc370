* cc370#416: a COPY whose member is not on the path.
*
* as370 fell through and let the COPY card stand as an ordinary
* statement -- RC 0, nothing on either stream -- and EVERY OFFSET
* AFTER IT MOVED, because a COPY that resolves to nothing has
* changed the program.  IFFAAA01 then reports eight undefined
* symbols and names the member nowhere: the diagnostics point at
* consequences and never at the cause, which is the one case where
* a byte comparison cannot attribute what it found.
*
* IFOX00's answer is the reference and the severity is ITS number,
* not a judgement of ours:
*
*   erms.asm:84         COPY MEMBER $ NOT FOUND IN LIBRARY
*   jermsgcd.asm:95     SEV68 EQU 8
*   ifnx1a.asm:1524     snapshot SEV68/ERR68, then read the next
*                       statement -- so IFOX00 ABANDONS the COPY and
*                       carries on, exactly as as370 does
*
* So this changes no byte and no return code.  What it changes is
* that the message names the member.
*
* THE RESOLVING COPY BELOW IS THE CONTROL.  A check that fired on
* every COPY would pass a fixture carrying only the missing one.
*
* Keep every line under column 72.
*
CPYM     CSECT
         COPY  CPYOK
         COPY  NOSUCHM
         BR    14
         END
