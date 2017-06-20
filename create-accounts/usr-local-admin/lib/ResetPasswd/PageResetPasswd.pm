package ResetPasswd::PageResetPasswd;

use strict;

use CGI qw( :standard );
use Error qw( :try );
use IPC::Open3;
use IO::Handle;

use ResetPasswd::Boiler   qw( mail send_top send_bottom );
use ResetPasswd::Config   qw( DOMAIN RESETPASSWD SUDO TITLE TOKEN_DIR );
use ResetPasswd::Validate qw( validate_fields log_it    );

use constant FIELDS => qw( account alternate password passwordcheck sponsor token key );

my %Info;

######################################################################
sub run {
    my( $message ) = @_;

    %Info = validate_fields( FIELDS );
    print start_html( '-title' => TITLE . ': Reset',
                    );
    send_top();
    send_page( $message );
    send_bottom();

    my $wtrfh = new IO::Handle;
    my $rdrfh = new IO::Handle;
    my $errfh = new IO::Handle;

    my $account_address = "$Info{ account }" . "@" . DOMAIN;

    try {
        my @args = ( RESETPASSWD,
		     '-account',   $Info{ account },
                   );

        my $pid = open3( $wtrfh, $rdrfh, $errfh, SUDO, @args )
            or die "Can't run @{[RESETPASSWD]}: $!";
        $wtrfh->print( $Info{ password } );
        $wtrfh->close or die "Can't close @{[RESETPASSWD]}: $!";

        waitpid( $pid, 0 );

        my @errors = $errfh->getlines;
        die join("", @errors ) if( @errors );

	# Write the change to the log file
	log_it( 'Success', $Info{ account } );

        # Unlink token file
        my $token_file = "@{[TOKEN_DIR]}/$Info{ token }";
        unlink $token_file or die "Couldn't remove token file ($token_file): $!";

        mail( "$account_address" , 'employees.org account password reset SUCCESS',
              <<"EOF_SUCCESS" );
Congratulations! Your account ($Info{account}) has had its password reset.
EOF_SUCCESS
	if( $Info{ sponsor } ) {
            mail( $Info{ sponsor }, 'employees.org account password reset SUCCESS',
                  <<"EOF_SUCCESS" );
Congratulations! Your account ($Info{account}) has had its password reset.
EOF_SUCCESS
	}
	if( $Info{ alternate } ) {
	    mail( $Info{ alternate }, 'employees.org account password reset SUCCESS',
                  <<"EOF_SUCCESS" );
Congratulations! Your account ($Info{account}) has had its password reset.
EOF_SUCCESS
	}
    }
    otherwise {
        my $e = shift;
        mail( $account_address, 'employees.org account password reset FAILURE',
              <<"EOF_FAILURE" );
We were unable to reset the password of your account ($Info{account}) 
for the following reason:

 @{[ $e->stringify ]}

You should probably read http://www.employees.org/FAQ   
If that does not help, you may want to contact admin\@employees.org.
EOF_FAILURE

  	if( $Info{ sponsor } ) {
            mail( $Info{ sponsor }, 'employees.org account password reset FAILURE',
                  <<"EOF_FAILURE" );
We were unable to reset the password of your account ($Info{account}) 
for the following reason:

 @{[ $e->stringify ]}

You should probably read http://www.employees.org/FAQ   
If that does not help, you may want to contact admin\@employees.org.
EOF_FAILURE
	}

  	if( $Info{ alternate } ) {
            mail( $Info{ alternate }, 'employees.org account password reset FAILURE',
                  <<"EOF_FAILURE" );
We were unable to reset the password of your account ($Info{account}) 
for the following reason:

 @{[ $e->stringify ]}

You should probably read http://www.employees.org/FAQ   
If that does not help, you may want to contact admin\@employees.org.
EOF_FAILURE
        }

        throw $e;
    };
}

######################################################################
sub send_page {
    my( $message ) = @_;

    if( $message ) {
        print h1( $message ), hr;
    }

    print( "Your account ($Info{ account }) is having its password reset.  
            You and your sponsor will be mailed with the results.\n" );
}


######################################################################

1;
