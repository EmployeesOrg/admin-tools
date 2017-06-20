package ResetPasswd::Config;

use strict;

use base 'Exporter';

our @EXPORT_OK = qw( ACCOUNT_LEN ADMIN CONFIG_FILE DISABLED_FILE 
		     DOMAIN ERROR_FILE KEY_LEN LOCK_FILE LOG_FILE
		     PASS_MAX_LEN PASS_MIN_LEN RESETPASSWD SUDO 
                     TITLE TOKEN_DIR TOKEN_LEN UID_MIN UID_MAX
                   );

use constant _ROOT_DIR     => '/var/resetpw';

use constant ACCOUNT_LEN   => 16;
use constant ADMIN         => 'admin@employees.org';
use constant CONFIG_FILE   => "@{[ _ROOT_DIR ]}/config";
use constant DISABLED_FILE => "@{[ _ROOT_DIR ]}/disabled";
use constant DOMAIN        => 'employees.org';
use constant ERROR_FILE    => "@{[ _ROOT_DIR ]}/error_log";
use constant KEY_LEN       => 4;
use constant LOCK_FILE     => "@{[ _ROOT_DIR ]}/lock";
use constant LOG_FILE      => "@{[ _ROOT_DIR ]}/log";
use constant PASS_MAX_LEN  => 8;
use constant PASS_MIN_LEN  => 6;
use constant RESETPASSWD   => '/usr/local/admin/bin/resetpw';
use constant SUDO	   => '/usr/local/bin/sudo';
use constant TITLE         => 'employees.org Account Password Reset Form';
use constant TOKEN_DIR     => "@{[ _ROOT_DIR ]}/tokens";
use constant TOKEN_LEN     => 8;
use constant UID_MIN	   => 1000;
use constant UID_MAX	   => 32000;


1;
