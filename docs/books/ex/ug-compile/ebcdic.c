/* What the preprocessor sees: character constants have their EBCDIC values */
#if 'A' == 193
#warning "'A' is 193 (X'C1'), as on MVS"
#endif
#if 'j' - 'i' != 1
#warning "the lower-case letters are not contiguous"
#endif
#if '~' > 'a' && '~' < 'z'
#warning "'~' lies between 'a' and 'z'"
#endif
#if '0' > 'z'
#warning "the digits sort after the letters"
#endif
#if 'a' < 'A'
#warning "the lower-case letters sort before the upper-case ones"
#endif
