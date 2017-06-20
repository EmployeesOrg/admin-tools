package MigrateAcct::PageGetSponsor;
# Get the sponsor for this account

use strict;
use CGI::Pretty qw( :standard );

use MigrateAcct::Boiler qw( send_top send_bottom );
use MigrateAcct::Config qw( ACCOUNT_LEN LEGAL_DOMAINS DOMAIN TITLE ALTERNATE_LEN );

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
    else if( theform.alternate.value == "" ) {
        alert( "Please enter an alternate email address." );
        return false;
    }
    else if( theform.alternate.value.match( /@.*employees\.org$/ ) ||
	     theform.alternate.value.match( /@.*cisco\.com$/ ) ) {
	alert( "The alternate account must NOT be an employees.org or cisco.com account." );
	return false;
    }
    else {
	theform.account.value = theform.existing_account.value;
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
           hidden( existing_domain => 'willers.employees.org' ), "\n",
	   hidden( account => '' ), "\n",

           "Have you read the Operating Policies and agreed to them?",
           popup_menu( '-name'    => 'agree',
                       '-values'  => [ 'no', 'yes' ],
                       '-default' => param( 'agree' ) || 'no' ),
           p, hr, p,

           "In order to receive a banjo.employees.org account, you need
           an existing account on willers.employees.org. This is
           where the validation mail including further instructions
           will be sent.",
	   p,
	   "<b>Important:</b> to migrate, you will need to read your email
	    on Willers.  To do this, <b>specify the full hostname
	    willers.employees.org</b> in your IMAP, POP, or SSH client.",
           p,
           "Existing willers account:",

           textfield( '-name'      => 'existing_account',
                      '-size'      => ACCOUNT_LEN,
                      '-maxlength' => ACCOUNT_LEN,
                      '-value'     => param( 'existing_account' ),
                    ),

           '@employees.org',

           p, hr, p, "\n",
           
           "Specify an alternate email address to which part of your
           account creation token will be sent.  This email address
           must <b>NOT</b> be an employees.org or a cisco.com address
           (e.g. specify a gmail.com, yahoo.com, acm.org, etc. address).",
           p,
           "Alternate email address:",
           
           textfield ( '-name'      => 'alternate',
                       '-size'      => ALTERNATE_LEN,
                       '-maxlength' => ALTERNATE_LEN,
                       '-value'     => param( 'alternate' ),
                    ),
            
           p, hr, p, "\n",

           submit( '-name' => 'Submit' ), reset,
           end_form,
         );
}

1;

__DATA__

<p>Use this form to migrate an existing account from willers.employees.org
to banjo.employees.org.  The migration covers user accounts
<b><i>ONLY</i></b>.  Any data you wish to move from willers to banjo must be
migrated manually.</p>

<p>In order to migrate your willers account to banjo, you will need to provide
two email address.  The first address is your existing employees.org address
(i.e. your willers.employees.org email address).  The second address can be
any address you want <i>other than</i> and employees.org or cisco.com address
(e.g. gmail.com, yahoo.com, hotmail.com, etc.).  Each email will receive part
of a key you will need to complete the new banjo account activation.  Make
sure you are able to retrieve your employees.org email before beginning the
migration process.</p>

<p>If you have any questions about migration, please contact
<a href="mailto:admin@employees.org?subject=Banjo account migration">
admin@employees.org</a>.</p>

<p>You must re-read
the employees.org <a href="http://www.employees.org/docs/policy">Operating Policies</a> before
migrating your account.</p>

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
href="http://www.employees.org/docs/policy">Operating Policies</a> now.
<hr>
