package ResetPasswd::PageGetAccount;
# Get the account to reset for this account.

use strict;
use CGI::Pretty qw( :standard );

use ResetPasswd::Boiler qw( send_top send_bottom );
use ResetPasswd::Config qw( ACCOUNT_LEN TITLE );
# use NewAcct::Config qw( ACCOUNT_LEN TITLE );

use constant VERIFY => <<'EOF_VERIFY';
function verify(theform) {
    if( theform.account.value == "" ) {
        alert( "Please enter an account." );
        return false;
    }
    else if( theform.account.value == "cisco" ) {
        alert( "You have misread the instructions. 'cisco@employees.org' is not your account." );
        return false;
    }
    else if( theform.account.value.search( /[^a-z0-9_]/ ) != -1 ) {
        alert( "The account may only contain lowercase letters, numbers or underscore." );
        return false;
    }
    else {
        return true;
    }
}
EOF_VERIFY

######################################################################

sub run {
    my( $message ) = @_;
    print start_html( '-title'  => TITLE,
                      '-script' => VERIFY );
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

    Delete( 'next' );

    print <DATA>;
    close DATA;
    print( start_form( -onSubmit => 'return verify(this)',
                       -action   => url() ),
           hidden( next => 'IssueKey' ), "\n",

           "Enter the employees.org account name. ",
           p,
           "Account name:",
           textfield( '-name'      => 'account',
                      '-size'      => ACCOUNT_LEN,
                      '-maxlength' => ACCOUNT_LEN ),
           '@employees.org',
           p, hr, p, "\n",

           submit( '-name' => 'Submit' ), reset( '-name' => 'Clear'),
           end_form,
         );
}

1;

__DATA__

<p>A user can use this form to request a reset of an account's
password on the employees.org system.  An authentication key will
be generated and displayed on the web page while a URL with a token
in will be E-mailed to the account's E-mail address, the E-mail address
of the sponsor of record, and the user's alternate E-mail contact, if
any has been given.  The user or sponsor can then use the combination
of this key and the URL token to reset the account's password.
<p>
<hr>

