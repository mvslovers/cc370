#include <stdio.h>
extern int trace_hook(const char *msg) __attribute__((weak));

int main(void)
{
    if (trace_hook != 0)
        trace_hook("main entered");
    else
        printf("no trace hook\n");
    return 0;
}
