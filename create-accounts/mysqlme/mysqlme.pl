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
# Create your mysql userid and Create a db named after your userid.
#
# $callname [flags]
# defaults:
#
# flags:
#   -h             display this help
#   -db [db]       database to create (defaults to your userid)
#                  db will be prefixed with your userid if not already
#
#-----------------------------------------------------------------------------
EOH
;
}

#----------------------- Initialization --------------------------------------

$| = 1;
my $help = 0;
my $debug = 0;
my $dryrun = 0;
my $quote_db = 0;
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
my $newdb = $id;
my $host = hostname() or die "Can't get hostname: $!\n";

#----------------------- Validate flags --------------------------------------

GetOptions( 'help' => \$help,
            'debug|d:i' => \$debug,
	    'dryrun|n' => \$dryrun,
	    'database|db:s' => \$newdb,
	    'quote|q' => \$quote_db,
           ) or showhelp();

$newdb = "${id}_${newdb}" if ( $newdb !~ /^$id(_|$)/ );

showhelp() if scalar @ARGV;

#----------------------- Display help if required ----------------------------

if ( $help == 1 ) {
  &showhelp;
}

#-------------------- See if newdb is among reserved words ------------------

# Load reserved words from __DATA__ section
my (%reserved_words);
while(<DATA>) {
    chomp;
    my(@words)=split(' ',$_);
    for (@words) {	
	$reserved_words{$_}=1;
    }
}

if ( ! $quote_db ) {
    my $lower_newdb = lc($newdb);	
    if ( defined($reserved_words{$lower_newdb}) ) {
	die <<RESERVED

    *** WARNING: database \"$newdb\" is a MySQL reserved word!  ***

Your database has NOT been created.  If you try to use this as your 
database name, you will have to back-quote the name everywhere it 
is used.  Many scripts will probably break on this database name.  

It is recommended that you use a different database name, using the 
\"-db <database name>\" option of \"mysqlme\".  The  -db option will 
append the \"<database name>\" given with the \"<username>_\" to create 
a new database.  If you really, really need this as your database name, 
re-run \"mysqlme\" with the \"-q\" option to cause the database name
to be back-quoted.

RESERVED
    }
}

#----------------------- Connect to database ---------------------------------

use DBI;

my $db_handle = DBI -> connect("DBI:mysql:database=$db;host=$dbhost",
                               $dbuser,$dbpw, { RaiseError => 1 })
                               or die "Can't open database: $DBI::errstr\n";

print "$callname: Connect OK\n" if ( $debug && $debug > 1 );


#-------------------- See if user already exists -----------------------------

$cmd = "SELECT * FROM user WHERE user = '$id'";
print "$cmd\n" if ( $debug && $debug >= 2 );

$cmd_handle = $db_handle -> prepare($cmd);
$cmd_handle -> execute;
my $users = $cmd_handle -> fetchall_arrayref;
$cmd_handle -> finish;

print map { "$_->[1]\n" } @$users if ( $debug && $debug >= 2 );

die "Found multiple users with this id. Contact help\@employees.org!\n"
   if( scalar @$users > 1 );

if( ! scalar @$users ) {
   #----------------------- Get User's password ------------------------------

   print "Please specify a password for your new mysql userid ($id) : ";
   ReadMode( 'noecho' );
   chomp( my $pw = <STDIN> );
   print "\nValidate password : ";
   chomp( my $pwcheck = <STDIN> );
   print "\n";
   die "Passwords do not match.\n" unless $pw eq $pwcheck;
   ReadMode( 0 );

   #----------------------- Add userid with no privileges --------------------

   my $set  =  "Host = 'localhost'";
      $set .= ",User = '$id'";
      $set .= ",Lock_tables_priv = 'Y'";
      $set .= ",create_tmp_table_priv = 'Y'";

   my $dset = $set . ",Password = PASSWORD('...')";
      $set .=        ",Password = PASSWORD('$pw')";

   my $cmd  = "INSERT INTO user SET $set";
   my $dcmd = "INSERT INTO user SET $dset";

   print "$dcmd\n" if ( $debug && $debug >= 2 );
  
   if( ! $dryrun ) {
      $cmd_handle = $db_handle -> prepare($cmd);
      $cmd_handle -> execute;
      $cmd_handle -> finish;
   }
   print "Created user: $id\n";
}

#-------------------- See if host/db/user already exists ---------------------

my $where  = "Host = 'localhost'";
   $where .= " AND Db = '$newdb'";
   $where .= " AND User = '$id'";

$cmd = "SELECT * FROM db WHERE $where";
print "$cmd\n" if ( $debug && $debug >= 2 );

$cmd_handle = $db_handle -> prepare($cmd);
$cmd_handle -> execute;
my $entries = $cmd_handle -> fetchall_arrayref;
$cmd_handle -> finish;

#----------------------- Give user Privileges to user's own db only ----------

if( ! scalar @$entries ) {
  my $set  =  "Host = 'localhost'";
     $set .= ",Db = '$newdb'";
     $set .= ",User = '$id'";
     $set .= ",Select_priv = 'Y'";
     $set .= ",Insert_priv = 'Y'";
     $set .= ",Update_priv = 'Y'";
     $set .= ",Delete_priv = 'Y'";
     $set .= ",Create_priv = 'Y'";
     $set .= ",Drop_priv = 'Y'";
     $set .= ",Grant_priv = 'Y'";
     $set .= ",References_priv = 'Y'";
     $set .= ",Index_priv = 'Y'";
     $set .= ",Alter_priv = 'Y'";
     $set .= ",Create_tmp_table_priv = 'Y'";
     $set .= ",Lock_tables_priv = 'Y'";

  $cmd = "INSERT INTO db SET $set";
  print "$cmd\n" if ( $debug && $debug >= 2 );
  
  if( ! $dryrun ) {
     $cmd_handle = $db_handle -> prepare($cmd);
     $cmd_handle -> execute;
     $cmd_handle -> finish;
  }
}

#----------------------- Enable the privileges -------------------------------

# Need the RELOAD privilege
$cmd = "FLUSH PRIVILEGES";
print "$cmd\n" if ( $debug && $debug >= 2 );
  
if( ! $dryrun ) {
   $cmd_handle = $db_handle -> prepare($cmd);
   $cmd_handle -> execute;
   $cmd_handle -> finish;
}

#----------------------- Create users own database ---------------------------

############################################################################
# 	NOTE: the back quotes around the newdb are important.  Some usernames
#	(like mine - "key") are in the large table of reserved words in 
#	MySQL.  The back-quotes identify the string as an IDENTIFER.
############################################################################
my $create_db = $newdb;
$create_db = "`$create_db`" if ( $quote_db );

$cmd = "CREATE DATABASE $create_db";
print "$cmd\n" if ( $debug && $debug >= 2 );
  
if( ! $dryrun ) { 
   $cmd_handle = $db_handle -> prepare($cmd);
   $cmd_handle -> execute;
   $cmd_handle -> finish;
}
print "Created database: $create_db\n";

if ( $quote_db && defined($reserved_words{$newdb}) ) {
    print <<WARNING

			NOTE WELL!  

Your database name \"$newdb\" happens to be one of the many MySQL 
reserved words.  You will need to use back-quotes (`) around the 
database  name to signify that that the string is an IDENTIFIER in
your reference.  You have been warned!

WARNING

}


#----------------------- Disconnect from database ----------------------------

$db_handle -> disconnect;


#----------------------- Collection of MySQL reserved words ------------------

__DATA__

action add all alter and as asc auto_increment between bigint bit binary
blob both by cascade char character change check column columns create data
database databases date datetime day day_hour day_minute day_second
dayofweek dec decimal default delete desc describe distinct double drop
escaped enclosed enum explain fields float float4 float8 foreign from for
full grant group having hour hour_minute hour_second ignore in index infile
insert int integer interval int1 int2 int3 int4 int8 into is join key keys
leading left like lines limit lock load long longblob longtext match
mediumblob mediumtext mediumint middleint minute minute_second month
natural numeric no not null on option optionally or order outer outfile
partial precision primary procedure privileges read real references rename
regexp repeat replace restrict rlike select set show smallint
sql_big_tables sql_big_selects sql_select_limit sql_log_off straight_join
starting table tables terminated text time timestamp tinyblob tinytext
tinyint trailing to use using unique unlock unsigned update usage values
varchar varying varbinary with write where year year_month zerofill
