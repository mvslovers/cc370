/* SUMUP -- add the numbers given as the parameter */
#include <stdio.h>
#include <stdlib.h>

#define MAXNUM 20

extern int addup(int n, const int *v);       /* in addup.asm  */
extern void report(int sum, int average);    /* in report.asm */

int main(int argc, char **argv)
{
    int v[MAXNUM];
    int n = 0;
    int i, sum;

    for (i = 1; i < argc && n < MAXNUM; i++)
        v[n++] = atoi(argv[i]);

    sum = addup(n, v);
    report(sum, sum / n);
    return 0;
}
