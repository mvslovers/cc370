* issue #53 (step 2) -- packed (P) and zoned (Z) decimal constants.
* Bytes follow IFOX00's PKON and ZKON (ifnx5d.asm:572-616 and
* :619-663):
*   sign nibble X'0C' plus / X'0D' minus, plus being the default
*   implicit length  P: (digits+1)*4 bits   Z: digits*8 bits
*   value right-justified into the length, padded with zero nibbles (P) or
*   X'F0' (Z), truncated on the LEFT
*   neither type is aligned (DCTABLE alignment mask 0)
* B is the case that shows the right-justification: five nibbles into
* three
* bytes gives 01 23 4C, not 12 34 C0. F and J are the left-truncation.
* K is the
* single permitted decimal point, skipped for the value. M is a value
* list --
* PKON ends a constant on a comma and the caller starts the next.
T        CSECT
A        DC    P'123'
B        DC    P'1234'
C        DC    P'-123'
D        DC    P'0'
E        DC    PL8'123'
F        DC    PL2'123456'
G        DC    Z'456'
H        DC    Z'-456'
I        DC    ZL5'456'
J        DC    ZL2'12345'
K        DC    P'1.25'
L        DC    2P'7'
M        DC    P'12,34'
N        DS    PL8
O        DS    P
         END
