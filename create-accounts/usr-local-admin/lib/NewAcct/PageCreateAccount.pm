package NewAcct::PageCreateAccount;

use strict;

use CGI qw( :standard );
use Error qw( :try );
use IPC::Open3;
use IO::Handle;

use NewAcct::Boiler   qw( mail send_top send_bottom );
use NewAcct::Config   qw( MAKEUSER SUDO TITLE TOKEN_DIR  );
use NewAcct::Validate qw( validate_fields  log_it   );

use constant FIELDS => qw( account alternate fullname password passwordcheck pgp
                           pop realname shell sponsor telephone token key
                       );
my %Info;

######################################################################
sub run {
    my( $message ) = @_;

    %Info = validate_fields( FIELDS );
    print start_html( '-title' => TITLE . ': Create',
                    );
    send_top();
    send_page( $message );
    send_bottom();

    my $wtrfh = new IO::Handle;
    my $rdrfh = new IO::Handle;
    my $errfh = new IO::Handle;

    try {
        my @args = ( MAKEUSER, 
		     '-account',   $Info{ account },
                     '-sponsor',   $Info{ sponsor },
                     '-realname',  $Info{ realname },
                     '-shell',     $Info{ shell    },
                     '-telephone', $Info{ telephone },
                     '-alternate', $Info{ alternate },
                     '-fullname',  $Info{ fullname  },
                     '-pgp',       $Info{ pgp       },
                   );
        push @args, '-pop' if( $Info{ pop } );

        my $pid = open3( $wtrfh, $rdrfh, $errfh, SUDO, @args )
            or die "Can't run @{[MAKEUSER]}: $!";
        $wtrfh->print( $Info{ password } );
        $wtrfh->close or die "Can't close @{[MAKEUSER]}: $!";

        waitpid( $pid, 0 );

        my @errors = $errfh->getlines;
        die join("", @errors ) if( @errors );

	# Write the change to the log file
	log_it( 'Success', $Info{ account } );

        # Unlink token file
        my $token_file = "@{[TOKEN_DIR]}/$Info{ token }";
        unlink $token_file or die "Couldn't remove token file ($token_file): $!";

        mail( $Info{ sponsor }, 'employees.org account creation SUCCESS',
              <<"EOF_SUCCESS" );
Congratulations! Your account ($Info{account}) has been created.
EOF_SUCCESS
    }
    otherwise {
        my $e = shift;
        mail( $Info{ sponsor }, 'employees.org account creation FAILURE',
              <<"EOF_FAILURE" );
We were unable to create your account ($Info{account}) for the following reason:

 @{[ $e->stringify ]}

You should probably read http://www.employees.org/FAQ   
If that does not help, you may want to contact admin\@employees.org.
EOF_FAILURE
        throw $e;
    };
}

######################################################################
sub send_page {
    my( $message ) = @_;

    if( $message ) {
        print h1( $message ), hr;
    }

    print( "Your account ($Info{ account }) is being created. Your
            sponsor will be mailed with the results.\n" );
}


######################################################################

1;
