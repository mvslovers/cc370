#include <stdio.h>

int main(void)
{
    int total = 0;

    for (int i = 1; i <= 10; i++)
        total += i;
    printf("total = %d\n", total);
    return 0;
}
