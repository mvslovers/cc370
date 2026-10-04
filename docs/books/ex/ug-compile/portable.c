#include <stdio.h>

#if defined(__CC370__) && __CC370__ < 10100
#error "this program needs cc370 1.1.0 or later"
#endif

#ifdef __MVS__
#define INPUT "DD:SYSIN"        /* a DD statement of the job step */
#else
#define INPUT "input.txt"       /* a file on the workstation */
#endif

int main(void)
{
    char line[256];
    FILE *f = fopen(INPUT, "r");

    if (f == NULL) {
        perror(INPUT);
        return 8;
    }
    while (fgets(line, sizeof line, f) != NULL)
        fputs(line, stdout);
    fclose(f);
    return 0;
}
