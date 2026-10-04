#include "version.h"

/* This is the string reported as the version number by all components
   of the compiler.  If you distribute a modified version of GCC,
   please modify this string to indicate that, e.g. by putting your
   organization's name in parentheses at the end of the string.  */

/* cc370: the GCC base first -- configure takes gcc_version from the first word
   of this line (configure.ac, gcc_version_trigger) and the driver compares
   that word with cc1's -- then the toolchain version from VERSION.  No commit
   here: this string is __VERSION__ and is written into PCH files, and neither
   should change with every commit.  `cc370 --version' prints the commit.  */
#include "../../common/include/cc370-version.h"
const char version_string[] = "3.4.6 - cc370 " CC370_VERSION;

/* This is the location of the online document giving instructions for
   reporting bugs.  If you distribute a modified version of GCC,
   please change this to refer to a document giving instructions for
   reporting bugs to you, not us.  (You are of course welcome to
   forward us bugs reported to you, if you determine that they are
   not bugs in your modifications.)  */

const char bug_report_url[] = "<URL:https://github.com/mvslovers/cc370/issues>";
