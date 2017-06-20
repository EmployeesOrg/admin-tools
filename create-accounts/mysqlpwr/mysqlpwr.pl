#!/usr/local/bin/perl5 -Tw

use strict;
use Getopt::Long;
use Sys::Hostname;
use Term::ReadKey;

my $callname = "mysql";

sub showhelp {
die <<EOH
#------------------------------------------------------------------------------
#
# Reset your mysql userid's password
#
# $callname [flags]
# defaults:
#
# flags:
#   -h             display this help
#
#------------------------------------------------------------------------------
EOH
;
}

#----------------------- Initialization --------------------------------------

$| = 1;
my $ok = 1;
my $help = 0;
my $debug = 0;
my $dryrun = 0;
my $cmd_handle;
my $cmd;

#----------------------- Keep SUID privs for shortest period possible!  ------

############################################################################
# /mysql.passwd should only be readable to the user this script is setuid to
############################################################################
my $db     = "mysql";
my $dbuser = "root";
my $dbhost = "localhost";

open( PASSWD, "/var/db/mysql/mysql.passwd" ) or die "Can't get password: $!\n";
chomp( my $dbpw = <PASSWD> );
close( PASSWD ) or die "Can't read password: $!\n";

# We are done with SUID - reset real UID to the user for rest of script
$> = $<;

#----------------------- Get id ----------------------------------------------

my $id = getpwuid( $< ) or die "Can't get id: $!\n";
my $host = hostname() or die "Can't get hostname: $!\n";

#----------------------- Validate flags --------------------------------------

GetOptions( 'help' => \$help,
            'debug|d:i' => \$debug,
	    'dryrun|n' => \$dryrun,
           ) or showhelp();


showhelp() if scalar @ARGV;

#----------------------- Display help if required ----------------------------

if ( $help == 1 ) {
  &showhelp;
}

use DBI;

#----------------------- Connect to database ---------------------------------

my $db_handle = DBI -> connect("DBI:mysql:database=$db;host=$dbhost",
                               $dbuser,$dbpw, { RaiseError => 1 })
                               or die "Can't open database: $DBI::errstr\n";

print "$callname: Connect OK\n" if ( $debug && $debug > 1 );


#-------------------- See if user already exists -------------------------------

$cmd = "SELECT * from user where User = '$id'";
print "$cmd\n" if ( $debug && $debug >= 2 );

$cmd_handle = $db_handle -> prepare($cmd);
$cmd_handle -> execute;
my $users = $cmd_handle -> fetchall_arrayref;
$cmd_handle -> finish;

print map { "$_->[1]\n" } @$users if ( $debug && $debug >= 2 );

die "Found multiple users with this id. Contact help\@employees.org!\n"
   if ( scalar @$users > 1 );

if ( scalar @$users ) {
   #----------------------- Get User's password ------------------------------

   print "Please specify your new password userid ($id) : ";
   ReadMode( 'noecho' );
   chomp( my $pw = <STDIN> );
   print "\nValidate password : ";
   chomp( my $pwcheck = <STDIN> );
   print "\n";
   die "Passwords do not match.\n" unless $pw eq $pwcheck;
   ReadMode( 0 );

   #----------------------- Reset the password -------------------------------

   my $dset = "Password = PASSWORD('...')";
   my $set  = "Password = PASSWORD('$pw')";

   my $where = "User = '$id'";

   my $cmd  = "UPDATE user SET $set WHERE $where";
   my $dcmd = "UPDATE user SET $dset WHERE $where";

   print "$dcmd\n" if ( $debug && $debug >= 2 );
  
   if ( ! $dryrun ) {
      $cmd_handle = $db_handle -> prepare($cmd);
      $cmd_handle -> execute;
      $cmd_handle -> finish;
   }
   print "Resetting ${id}'s password\n";
}
else {
  print "Userid '${id}' doesn't exist in mysql\n";
  $ok = 0;
}

#----------------------- Enable the privileges -------------------------------

if ( $ok ) {
  # Need the RELOAD privilege
  $cmd = "FLUSH PRIVILEGES";
  print "$cmd\n" if ( $debug && $debug >= 2 );
  
  if ( ! $dryrun ) {
     $cmd_handle = $db_handle -> prepare($cmd);
     $cmd_handle -> execute;
     $cmd_handle -> finish;
  }
}

#----------------------- Disconnect from database ----------------------------

$db_handle -> disconnect;
