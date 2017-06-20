package ResetPasswd::PageGetInfo;

use strict;

use CGI qw( :standard );

use ResetPasswd::Boiler qw( send_top send_bottom );

use ResetPasswd::Config qw( DISABLED_FILE KEY_LEN PASS_MAX_LEN TITLE );

use ResetPasswd::Validate qw( validate_fields );

use constant FIELDS => qw( account token );

my %Info;

######################################################################
sub run {
    my( $message ) = @_;

    %Info = validate_fields( FIELDS );
    print start_html( '-title'  => TITLE . ': Password',
                      '-script' => &VERIFY );
    send_top();
    send_page( $message );
    send_bottom();
}

######################################################################
sub send_page {
    my( $message ) = @_;

    if( $message ) {
        print h1( $message ), hr;
    }

    my $account  = $Info{ account          };

    print( start_form( '-onSubmit' => 'return verify(this)' ),

           hidden( next => 'ResetPasswd' ),

           "<h2>Account Information</h2>\n",

           "Account: <b>$account</b>\@employees.org",
           p, hr, p, "\n",

           "When you requested this account's password to be reset, you were 
           issued a four character key. Enter it here.", p,

           "Key: ", textfield( '-name'      => 'key',
                               '-maxlength' => KEY_LEN,
                               '-size'      => KEY_LEN,
                               '-value'     => param( 'key' ),
                             ),
           p, hr, p, "\n",

           "Choose a new password for this account. Your password must
           meet the following rules:", p,

           ol(
              li( "Between 6 and 128 characters."),

              li( "Contains at least two alphabetic characters and at
              least one numeric or special character. In this case,
              'alphabetic' refers to all upper or lower case letters."
              ),

              li( "Must differ from your login name and any reverse or
              circular shift of that login name. For comparison
              purposes, an upper case letter and its corresponding
              lower case letter are equivalent." )
             ), "\n", p,

           "Password: ", password_field( '-name'  => 'password',
                                         '-size'  => PASS_MAX_LEN,
                                         '-value' => param( 'password' ),
                                       ),
           p, 
           "Password (again): ", password_field( '-name'  => 'passwordcheck',
                                                 '-size'  => PASS_MAX_LEN,
                                                 '-value' => param( 'passwordcheck' ),
                                       ),
           hr, p, "\n",

         );

    print( p, submit, reset( '-name' => 'Clear'), end_form );
}


######################################################################
use constant VERIFY => <<'EOF_VERIFY';
function verify(theform) {
    if( theform.key.value.search( /^\w{4}$/ ) == -1 ) {
        alert( "Invalid key." );
        return false;
    }
    else if( theform.password.value != theform.passwordcheck.value ) {
        alert( "Passwords to not match." );
        return false;
    }        
    else {
        return true;
    }
}
EOF_VERIFY

1;
