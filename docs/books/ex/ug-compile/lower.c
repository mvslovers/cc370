#include <ctype.h>

/* Count the lower-case letters of a string. */
int count_lower(const char *s)
{
    int n = 0;

    for (; *s; s++)
        if (islower((unsigned char)*s))   /* not: *s >= 'a' && *s <= 'z' */
            n++;
    return n;
}
