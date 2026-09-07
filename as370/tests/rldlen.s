* Die Laenge im RLD-Kennzeichenbyte gehoert zu IHRER Eintragung.
*
* add_reloc() steigt bei in_dsect aus, die Aufrufstelle schrieb die
* Laenge aber danach in rels[nrel-1] -- also in die VORIGE, echte
* Eintragung.  Ein Adresskonstante in einer DSECT ist voellig
* gewoehnlich: IEAVELCR ruft 24 mal echt und 138 mal aus Dummy-
* Sektionen, die letzte echte Eintragung wurde also 138 mal
* ueberschrieben und behielt die Breite der letzten DSECT-Konstante.
*
* Ein Bit eines Kennzeichenbytes (0x04, das niedrige Bit von
* Laenge-1) in einem sonst byte-gleichen Deck (#186).
*
*   VL3 -> Laenge 3 -> Kennzeichen 0x18
*   ohne Fix uebernimmt die letzte die Breite des V(...) aus
*   der DSECT und meldet Laenge 4: 0x1C
T        CSECT
         DC    VL3(EXTA)
         DC    X'00'
         DC    VL3(EXTB)
D        DSECT
         DC    V(EXTC)
         DC    V(EXTD)
         END   T
