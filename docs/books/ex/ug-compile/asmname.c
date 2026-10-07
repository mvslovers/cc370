/* Names chosen for MVS with asm labels */
int print_header(int page)  asm("PRTHDR");
int print_heading(int page) asm("PRTHEAD");

int print_header(int page)  { return page; }
int print_heading(int page) { return page + 1; }
