#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int
main(int argc, char **argv)
{
  char error[80];

  execv(WEBIT_PATH, argv);
  snprintf( error, sizeof( error ), "Unable to run %s", WEBIT_PATH );
  perror( error );
  exit( 1 );

  /* NOTREACHED */
  return (0);
}
