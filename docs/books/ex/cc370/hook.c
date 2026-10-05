#include <stdio.h>

int trace_hook(const char *msg)
{
    return printf("TRACE: %s\n", msg);
}
