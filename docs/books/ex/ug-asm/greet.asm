GREET    CSECT
         SAVE  (14,12),,GREET     save the caller's registers
         LR    12,15              R12 = base register
         USING GREET,12
         WTO   'GREETINGS FROM AS370' write a message to the console
         RETURN (14,12),RC=0      restore registers, return code 0
         END   GREET
