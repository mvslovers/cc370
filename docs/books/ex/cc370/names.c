/* How C names become external symbols */
extern int open_input_file(const char *);
extern int Trace(int);
extern int write_rec(int) asm("WRITEREC");
int record_count = 0;

int copy_file(const char *name)
{
    int rc = open_input_file(name);
    Trace(rc);
    record_count++;
    return write_rec(rc);
}
