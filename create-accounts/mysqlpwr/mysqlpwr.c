/* 
 * This is the C wrapper for MySQLPWR
 * Using this, I can effectively use setuid with Perl.
 *
 * Copyright (c)2011 Joe Clarke
 *
 */

#define REAL_PATH "/usr/local/libexec/mysqlpwr.pl"

int
main(int argc, char **argv) {
	execv(REAL_PATH, argv);

	return 0;
}
