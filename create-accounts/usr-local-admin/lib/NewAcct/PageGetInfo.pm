package NewAcct::PageGetInfo;

use strict;

use CGI qw( :standard );

use NewAcct::Boiler qw( send_top send_bottom );

use NewAcct::Config qw( ALTERNATE_LEN DEFAULT_SHELL DOMAIN KEY_LEN NAME_LEN
                        PASS_MAX_LEN PGP_LEN PHONE_LEN TITLE );

use NewAcct::Validate qw( validate_fields );

use constant FIELDS => qw( account existing_account existing_domain
                           token );

my %Info;

######################################################################
sub run {
    my( $message ) = @_;

    %Info = validate_fields( FIELDS );
    print start_html( '-title'  => TITLE . ': Account',
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
    my $existing = $Info{ existing_account };

    open( SHELLS, "/etc/shells" ) or die "Can't open /etc/shells: $!";
    my @shells = <SHELLS>;
    chomp( @shells );
    close( SHELLS ) or die "Can't read /etc/shells: $!";

    print( start_form( '-onSubmit' => 'return verify(this)' ),

           hidden( next => 'CreateAccount' ),

           "<h2>Account Information</h2>\n",

           "Account: <b>$account</b>\@employees.org",
           p, hr, p, "\n",

           "When you requested this account, you were issued a four
           character key. Enter it here.", p,

           "Key: ", textfield( '-name'      => 'key',
                               '-maxlength' => KEY_LEN,
                               '-size'      => KEY_LEN,
                               '-value'     => param( 'key' ),
                             ),
           p, hr, p, "\n",

           "Choose a password for this account. Your password must
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

           "Your 'Full name' is the name people will be given for this
           account (this is the field historically called gcos). It
           can be a handle or pseudonym, but it can't be blank. It can
           include most printable characters (including spaces) except
           colon (:) and ampersand (&). This can be changed in the
           future using the command 'chfn'.", p,

           "Full name: ", textfield( '-name'      => 'fullname',
                                     '-maxlength' => NAME_LEN,
                                     '-size'      => NAME_LEN,
                                     '-value'     => param( 'fullname' ),
                                   ),
           p, hr, p, "\n",

           "Choose a login shell for your account. If you have no
           preference, we suggest @{[DEFAULT_SHELL]}.", p,

           "Shell: ", popup_menu( '-name'    => 'shell',
                                  '-values'  => [ @shells ],
                                  '-default' => ( param( 'shell' ) ||
                                                  DEFAULT_SHELL ),
                                ),
           p, hr, p, "\n",

#           "The employees.org system supports collection of e-mail via
#           the POP protocol. If you plan to use POP, you can enable it
#           now. If you don't plan to use it right away, you can enable
#           it later from the UNIX command line. See <a
#           href=\"pop-howto.html\">the documentation</a> for more
#           information.", p,
#
#           "Enable POP? ", popup_menu( '-name'    => 'pop',
#                                       '-values'  => [ qw( no yes ) ],
#                                       '-default' => (param( 'pop' ) || 'no' ),
#                              ),
#           p, hr, p, "\n",

#	   We no longer take this setting
           hidden( -name  	=> 'pop',
		   -default 	=> 'no'),

           "<h2>Personal Information</h2>\n",

           "Enter your real full name. This will only be available to
           the administrators of employees.org and is not visible to
           other users or publicly.", p,

           "Real name: ", textfield( '-name'      => 'realname',
                                     '-size'      => NAME_LEN,
                                     '-maxlength' => NAME_LEN,
                                     '-value'     => param( 'realname' ),
                                   ), p, hr, p, "\n",

           "Enter your telephone number. We use this to get into
           contact with you if there's a problem with your account.
           Entering your phone number is optional, but strongly
           encouraged; we will often want to talk to you on the phone
           before we're willing to do things you've asked to have done
           to your account. If you're a covered company employee,
           please give your home number; we already have your work
           number anyway. We will not release your phone number to
           anybody except employees.org administrators, and we will
           use it only for employees.org business.", p,

           "Telephone (optional): ",
           textfield( '-name'      => 'telephone',
                      '-size'      => PHONE_LEN,
                      '-maxlength' => PHONE_LEN,
                      '-value'     => param( 'telephone' ),
                    ), p, hr, p, "\n",

           "Enter a trusted alternate E-mail address.  We can use this to
           contact with you if there's a problem with your account.
           Entering an is optional, but strongly encouraged; this will allow 
           us to contact you at an address you have already vetted with us 
           as being yours.  We can then safely contact you about problems 
           with your with your account, like losing your password with is
           preventing you from readng E-mail at Employees.org.  We will not
           divulge this address and will only use it for employees.org 
           business.", p,

           "Alternate E-mail Address (optional): ",
           textfield( '-name'      => 'alternate',
                      '-size'      => ALTERNATE_LEN,
                      '-maxlength' => ALTERNATE_LEN,
                      '-value'     => param( 'alternate' ),
                    ), p, hr, p, "\n",

           "If you have a PGP key, you can enter your key fingerprint
           here. We can then use PGP to authenticate any
           administrative requests you send us, greatly simplifying
           the whole process. If you don't know what PGP is, don't
           worry about it.", p,

           "PGP Key (optional): ", textfield( -name      => 'pgp',
                                              -size      => PGP_LEN,
                                              -maxlength => PGP_LEN,
                                              -value     => param( 'pgp' )
                                            ), p, hr, p, "\n",
         );

    print( p, submit( '-name' => 'Submit' ), reset, end_form );
}


######################################################################
use constant VERIFY => <<'EOF_VERIFY';
function verify(theform) {
    if( theform.key.value.search( /^\w{4}$/ ) == -1 ) {
        alert( "Invalid key." );
        return false;
    }
    else if( theform.fullname.value == "" ) {
        alert( "Please enter a full name." );
        return false;
    }
    else if( theform.fullname.value.search( /[:&]/ ) != -1 ) {
        alert( "Illegal characters (: or &) in full name." );
        return false;
    }
    else if( theform.realname.value == "" ) {
        alert( "Please enter your real name." );
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
