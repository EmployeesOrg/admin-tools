package NewAcct::PageIssueKey;

use strict;

use CGI   qw( :standard                    );
use POSIX qw( EEXIST O_CREAT O_EXCL O_RDWR );

use NewAcct::Boiler   qw( mail send_top send_bottom         );
use NewAcct::Config   qw( KEY_LEN TITLE TOKEN_DIR TOKEN_LEN );
use NewAcct::Validate qw( validate_fields                   );

use constant FIELDS => qw( account agree existing_account
                           existing_domain sponsor );

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
<p>We have mailed a URL including a token to your existing account.
When you receive that message, if you are not the user of the account,
forward the message to the user. The user should then follow the link,
and enter the following key. This will demonstrate that the sponsor
account is legal and that it is yours.</p>

<h1 align=center>Key (Keep This For Later!)</h1>
<h2 align=center>$key</h2>
EOF

    # And mail the user
    my $url = url() . "?token=$token";

    # HACK
    mail( "$Info{ sponsor }",
          'employees.org verification email', <<"EOF" );
Someone (hopefully you) has requested an employees.org account
named "$Info{ account }" to be sponsored by you. If you requested
this account, you can use the below URL to finish creating the
account. If you are sponsoring this account for a family member,
have him or her follow the URL (you may want to simply forward
this mail). Remember that violation of the Terms of Use of
employees.org by any member of a sponsorship group may lead to
the termination of all the accounts. Also remember that all
sponsored accounts together may only use 250M.

Note to Elm users:  Elm performs URL escaping improperly and
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
                    $Info{ account          }, "\n";

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
