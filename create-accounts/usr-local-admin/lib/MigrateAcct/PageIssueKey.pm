package MigrateAcct::PageIssueKey;

use strict;

use CGI   qw( :standard                    );
use POSIX qw( EEXIST O_CREAT O_EXCL O_RDWR );

use MigrateAcct::Boiler   qw( mail send_top send_bottom         );
use MigrateAcct::Config   qw( KEY_LEN TITLE TOKEN_DIR TOKEN_LEN );
use MigrateAcct::Validate qw( validate_fields log_it             );

use constant FIELDS => qw( account agree existing_account
                           existing_domain sponsor alternate );

my %Info;

######################################################################
sub run {
    %Info = validate_fields( FIELDS );
    print start_html( '-title' => TITLE . ': Issue Key',
                    );
    send_top();
    send_page( );
    send_bottom();
}

######################################################################
sub send_page {
    my( $message ) = @_;

    if( $message ) {
        print h1( $message ), hr;
    }

    # We're good. Let's do the page

    my( $key, $token ) = generate_key_token();

    print<<EOF;
<p>We have sent two email messages containing the token necessary
to activate your new account on Banjo.</p>

<p>One message was sent to your alternate address, $Info{ alternate }.  This
contains a URL which you must access.  This URL encodes half of token
necessary to activate your new account on Banjo.</p>

<p>The second message was sent to your existing account, $Info{ sponsor }.
This contains the other half of the token necessary to activate your new
account on Banjo.</p>
EOF

    # Mail the key to the alternate.
    mail( "$Info{ alternate }",
          'banjo.employees.org verification email', <<"EOF" );
Someone (hopefully you) has requested an account on banjo.employees.org
name "$Info{ existing_account }".  If you requested this account,
you can use the key below together with a token emailed to your
employees.org address to activate the account.

Note to Elm / mail users:  Elm performs URL escaping improperly and
mangles the URL.  You will need to remove any "3D" sequences
in the key below (they key should be four characters).

Key (Keep This for Later!) : $key
EOF

    # And mail the token to the existing employees.org account.
    my $url = url() . "?token=$token";

    log_it( 'Sending URL to existing account ' . $Info{ sponsor } , $Info{ existing_account });

    # HACK
    mail( "$Info{ sponsor }",
          'employees.org verification email', <<"EOF" );
Someone (hopefully you) has requested an account on banjo.employees.org
named "$Info{ existing_account }". If you requested
this account, you can use the below URL to finish creating the
account. Remember that violation of the Terms of Use of
employees.org by any member of a sponsorship group may lead to
the termination of all the accounts. Also remember that all
sponsored accounts together may only use 250M.

Note to Elm / mail users:  Elm performs URL escaping improperly and
mangles the URL.  You will need to remove the "3D" from between
the "token=" and the 8 character token itself in the URL.

$url
EOF

}

######################################################################
sub generate_key_token {

    LOOP: {
        my $key   = random_string( KEY_LEN   );
        my $token = random_string( TOKEN_LEN );

        my $token_file = "@{[TOKEN_DIR]}/${token}";
        if( ! sysopen( TOKEN, $token_file, O_RDWR | O_CREAT | O_EXCL, 0600 ) ) {
            redo LOOP if( $! == EEXIST );
            die "Couldn't create token file ($token_file): $!";
        }

        print TOKEN $key,                      "\n",
                    $Info{ existing_account }, "\n",
                    $Info{ existing_domain  }, "\n",
                    $Info{ existing_account }, "\n",
                    $Info{ alternate        }, "\n";

        close TOKEN or die "Couldn't write $token_file: $!";
        return( $key, $token );
    }
}

######################################################################
sub random_string {
    my( $length ) = @_;

    my @dictionary = ( 'a' .. 'z', 'A' .. 'Z', '0' .. '9' );

    my $string = '';
    foreach( 1 .. $length ) {
        $string .= $dictionary[ int( rand( @dictionary ) ) ];
    }

    return $string;
}

######################################################################
1;
