package NewAcct::PageGetSponsor;
# Get the sponsor for this account

use strict;
use CGI::Pretty qw( :standard );

use NewAcct::Boiler qw( send_top send_bottom );
use NewAcct::Config qw( ACCOUNT_LEN LEGAL_DOMAINS DOMAIN TITLE );

use constant VERIFY => <<'EOF_VERIFY';
function verify(theform) {
    if( theform.agree.selectedIndex != 1 ) {
        alert( "Please read and agree to terms of service." );
        return false;
    }
    else if( theform.existing_account.value == "" ) {
        alert( "Please enter an existing account." );
        return false;
    }
    else if( theform.existing_account.value == "cisco" ) {
        alert( "You have misread the instructions. 'cisco@employees.org' is not your existing account." );
        return false;
    }
    else if( theform.existing_account.value == "admin" ) {
        alert( "You have misread the instructions. 'admin@employees.org' is not your existing account." );
        return false;
    }
    else if( theform.account.value == "" ) {
        alert( "Please enter a requested account." );
        return false;
    }
    else if( theform.account.value.search( /[^a-z0-9_]/ ) != -1 ) {
        alert( "Requested account may only contain lowercase letters, numbers or underscore." );
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

           "Have you read the Operating Policies and agreed to them?",
           popup_menu( '-name'    => 'agree',
                       '-values'  => [ 'no', 'yes' ],
                       '-default' => param( 'agree' ) || 'no' ),
           p, hr, p,

           "In order to receive an employees.org account, you need
           either an existing account at employees.org or at one of
           our sponsored companies (currently Cisco Systems). This is
           where the validation mail including further instructions
           will be sent.",
           p,
           "Sponsoring account (not the account you're requesting!):",

           textfield( '-name'      => 'existing_account',
                      '-size'      => ACCOUNT_LEN,
                      '-maxlength' => ACCOUNT_LEN,
                      '-value'     => param( 'existing_account' ),
                    ),

           '@',
           popup_menu( '-name'    => 'existing_domain',
                       '-values'  => [ LEGAL_DOMAINS ],
                       '-default' => ( param( 'existing_domain' ) || DOMAIN ),
                     ),

           p, hr, p, "\n",

           "Choose an employees.org account name. It must be sixteen
           characters or fewer and contain only lowercase letters,
           numbers and underscores (no spaces).",
           p,
           "Requested account name:",
           textfield( '-name'      => 'account',
                      '-size'      => ACCOUNT_LEN,
                      '-maxlength' => ACCOUNT_LEN ),
           '@employees.org',
           p, hr, p, "\n",

           submit( '-name' => 'Submit' ), reset,
           end_form,
         );
}

1;

__DATA__

<p>Use this form to request an account on the employees.org system.
This requires that you already have an existing account at
employees.org, or be an employee of a covered company (right now, only
Cisco Systems is covered). Please be careful to read all instructions,
and make sure you understand what you're agreeing to. You must read
the employees.org <a href="http://www.employees.org/policy">Operating Policies</a> before
applying for an account.</p>

<h2>Overview of terms of service</h2>

<ol>
  <li>employees.org is a volunteer-supported resource. We have no
      service level agreement with the users. The machine may become
      unavailable at any time for any length of time. Requests for
      assistance will be addressed when possible given the admins'
      workloads.</li>
  <li>You are generally expected to take care of yourself. There is a
      help alias (<a href="mailto:help@employees.org">
      help@employees.org </a>), but it is staffed by volunteers with
      varying available free time. Before contacting the help list, it
      is expected that you have already consulted the employees.org
      <a href="http://www.employees.org/FAQ">FAQ</a>, online documentation, man pages, and
      other readily available sources of information.</li>
  <li>If you need a higher level of support, you should seriously
      consider other providers. There are a large number of groups on
      the internet who will provide free email and web space and who
      provide a higher level of support. Most of the advantages of
      employees.org are only useful to advanced users who are familiar
      with Unix systems.</li>
  <li>You are expected to read the email sent to all of your accounts,
      particularly email that copies admin@employees.org. If you do
      not read emails from the admins, we will lock your account and
      see if you respond. If you still do not respond, we will
      determine that the account is inactive and delete it.</li>
  <li>There is no backup of data on employees.org. You are responsible
      for backing up your own data.</li>
  <li>User space is restricted to 250M per sponsor (not per account).
      Remember this when sponsoring new accounts.</li>
  <li>You may create accounts for family members, and you may have
      multiple accounts for yourself. Sponsorship groups "sink or
      swim" together. If one account in a sponsorship group abuses the
      system, the entire group may be deleted. Remember this when
      sponsoring new accounts.</li>
  <li>If you forget your password, you will need to use the resetpw
      facility found at <a href="https://www.employees.org/~admin/resetpw.cgi">
      https://www.employees.org/~admin/resetpw.cgi</a>
      In order to have your account deleted, mail <a
      href="mailto:nukeme@employees.org">nukeme@employees.org</a>.</li>
  <li>No work-related information belongs on employees.org. Placing
      confidential information regarding your employeer on
      employees.org may lead to your employeer terminating you. Lest
      there be any confusion about this: <strong>Do not put
      Cisco-related information on this machine. We will report you to
      corporate security.</strong> This machine is not part of
      Cisco. This policy includes links to internal web pages, as they
      will generally get indexed by web search engines.</li>
  <li>Commerical content is forbidden. This includes any financial
      transactions, including not-for-profit donations.</li>
</ol>

This is not the entire Terms of Service. Please go read the entire <a
href="http://www.employees.org/policy">Operating Policies</a> now.
<hr>
