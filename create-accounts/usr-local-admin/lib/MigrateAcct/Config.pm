package MigrateAcct::Config;

use strict;

use base 'Exporter';

our @EXPORT_OK = qw( ACCOUNT_LEN ADMIN ALTERNATE_LEN BASEDIR_FILE CHOWN CONFIG_FILE
                     COVERED DEFAULT_SHELL DOMAIN EDQUOTA ERROR_FILE
                     GROUPADD HOMEDIR_PERM KEY_LEN LEGAL_DOMAINS
                     LINK_DIR LOCK_FILE LOG_FILE MAKEUSER NAME_LEN
                     PASS_MAX_LEN PASS_MIN_LEN PASSWD PGP_LEN
                     PHONE_LEN POPME QUOTA_USER SKEL SUDO TITLE TOKEN_DIR
                     TOKEN_LEN USERADD
                   );

use constant _ROOT_DIR     => '/var/newacct';

use constant ACCOUNT_LEN   => 16;
# use constant ADMIN         => 'rnapier@employees.org';
use constant ADMIN         => 'admin@employees.org';
use constant ALTERNATE_LEN => 50;
use constant BACKUP_DIR    => "@{[ _ROOT_DIR ]}/backup";
#use constant BASEDIR_FILE  => '/usr/sadm/defadduser';
use constant CHOWN         => '/usr/sbin/chown';
use constant CONFIG_FILE   => "@{[ _ROOT_DIR ]}/config";
use constant COVERED       => qw( willers.employees.org );
# Example for using 2 covered companies.
#use constant COVERED       => qw( cisco.com ksquared.net );
use constant DEFAULT_SHELL => '/bin/csh';
use constant DOMAIN        => 'employees.org';
#use constant EDQUOTA       => '/usr/sbin/edquota';
use constant ERROR_FILE    => "@{[ _ROOT_DIR ]}/error_log";
#use constant GROUPADD      => '/usr/sbin/groupadd';
use constant KEY_LEN       => 4;
use constant HOMEDIR_PERM  => 02700;
use constant LEGAL_DOMAINS => ( DOMAIN, COVERED );
use constant LINK_DIR      => '/users';
use constant LOCK_FILE     => "@{[ _ROOT_DIR ]}/lock";
use constant LOG_FILE      => "@{[ _ROOT_DIR ]}/log";
use constant MAKEUSER      => '/usr/local/admin/bin/makeuser';
use constant NAME_LEN      => 50;
use constant PASSWD        => '/etc/passwd';
use constant PASS_MAX_LEN  => 8;
use constant PASS_MIN_LEN  => 6;
use constant PGP_LEN       => 50;
use constant PHONE_LEN     => 50;
#use constant POPME         => '/usr/local/bin/popme';
#use constant QUOTA_USER    => 'rnapier'; # HACK
#use constant QUOTA_USER    => 'key'; # HACK
use constant SKEL          => '/etc/skel';
use constant SUDO	   => '/usr/local/bin/sudo';
use constant TITLE         => 'banjo.employees.org Account Creation Form';
use constant TOKEN_DIR     => "@{[ _ROOT_DIR ]}/tokens";
use constant TOKEN_LEN     => 8;
#use constant USERADD       => '/usr/sbin/useradd';
1;
