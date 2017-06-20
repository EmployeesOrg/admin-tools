package ResetPasswd::PageIssueKey;

use strict;

use CGI   qw( :standard                    );
use POSIX qw( EEXIST O_CREAT O_EXCL O_RDWR );

use ResetPasswd::Boiler   qw( mail send_top send_bottom         );
use ResetPasswd::Config   qw( DOMAIN KEY_LEN TITLE TOKEN_DIR TOKEN_LEN );
use ResetPasswd::Validate qw( validate_fields                   );
use constant FIELDS => qw( account alternate sponsor );

use EmplOrg::AccountDB;


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

    my $account_address = "$Info{ account }" . "@" . DOMAIN;

    print<<EOF;
<p>We have mailed a URL including a token to the account,
the account's sponsor, and the account alternate contact, if one
was given.  The user or sponsor show then follow the link,
and enter the following key. This will demonstrate that the 
account is legal and that it is yours.</p>

<h1 align=center>Key (Keep This For Later!)</h1>
<h2 align=center>$key</h2>
EOF

    # And mail the users and sponsors
    my $url = url() . "?token=$token";

    # HACK
    mail( "$account_address",
          'employees.org verification email', <<"EOF" );
Someone (hopefully you) requested an employees.org account password
to be reset.  If you requested this account password to be reset,
you can use the below URL to finish resetting the password.

Account: $account_address

Note to Elm users:  Elm performs URL escaping improperly and
mangles the URL.  You will need to remove the "3D" from between
the "token=" and the 8 character token itself in the URL.

$url
EOF

    if( $Info{ sponsor } ) {
        mail( "$Info{ sponsor }",
          'employees.org verification email', <<"EOF" );
You are the sponsor of record for $account_address

Someone requested an employees.org account password
to be reset.  If you requested this account password to be reset,
you can use the below URL to finish resetting the password.

Account: $account_address

Note to Elm users:  Elm performs URL escaping improperly and
mangles the URL.  You will need to remove the "3D" from between
the "token=" and the 8 character token itself in the URL.

$url
EOF
    }

    if( $Info{ alternate } ) {
        mail( "$Info{ alternate }",
          'employees.org verification email', <<"EOF" );
You are listed as the alternate contact email address for
$account_address

Someone (hopefully you) requested an employees.org account password
to be reset.  If you requested this account password to be reset,
you can use the below URL to finish resetting the password.

Account: $account_address

Note to Elm users:  Elm performs URL escaping improperly and
mangles the URL.  You will need to remove the "3D" from between
the "token=" and the 8 character token itself in the URL.

$url
EOF
    }
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
