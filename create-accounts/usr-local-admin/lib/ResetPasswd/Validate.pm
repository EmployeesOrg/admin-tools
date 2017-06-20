package ResetPasswd::Validate;

use strict;

use base 'Exporter';

use CGI   qw( :standard );
use Error qw( :try );
use POSIX qw( ENOENT );

use ResetPasswd::Config qw( DISABLED_FILE PASS_MAX_LEN PASS_MIN_LEN LOG_FILE
			    TOKEN_DIR TOKEN_LEN UID_MIN UID_MAX);

use EmplOrg::AccountDB;

our @EXPORT_OK = qw( validate_fields log_it );

my %VALIDATE_MAP = ( account          => \&validate_account,
		     alternate	      => \&validate_alternate,
		     sponsor	      => \&validate_sponsor,
                     password         => \&validate_password,
                     passwordcheck    => \&validate_passwordcheck,
                     token            => \&validate_token,
                     key              => \&validate_key,
                   );

my %GOTO_MAP = ( GetAcct => { load => 'ResetPasswd::PageGetAccount',
                                 run  => \&ResetPasswd::PageGetAccount::run },
                 GetInfo    => { load => 'ResetPasswd::PageGetInfo',
                                 run  => \&ResetPasswd::PageGetInfo::run },
               );

my %Token_info;

######################################################################
sub validate_fields {
    my( @fields ) = @_;

    my %info;
    try {
        @info{ @fields } = map {
            exists $VALIDATE_MAP{ $_ } or die "No validator for $_";
            $VALIDATE_MAP{ $_ }->() } @fields;
    }
    otherwise
    {
        my $e = shift;
        if( exists $GOTO_MAP{ $e->value } ) {
            eval "require $GOTO_MAP{ $e->value }->{ load }" or die $@;
            $GOTO_MAP{ $e->value }->{ run }->( $e->text );
            exit;               # We don't want to go back to the caller!
        }
        else {
            throw $e;
        }
    };
    return %info;
}

######################################################################
sub validate_account {
    my $account;
    my $uid;

    if( url_param( 'token' ) ) {
        _load_token_file();
        $account = $Token_info{ account } || '';
    }
    else {
        $account = param( 'account' ) || '';
    }

    throw Error( -text  => "ERROR: Illegal account name ($account).",
                 -value => 'GetAcct' )
        unless $account =~ /(^[a-z0-9_]{1,16}$)/;

    $account = $1;              # Untaint $account

    # Write the change to the log file
    log_it( 'Attempt', $account );

    # Make sure this account does exist. Send the user back
    # if there's an issue.
    $uid = getpwnam($account) || -1;			   
    if( ( $uid < UID_MIN ) || ( $uid > UID_MAX ) )
    {
        throw Error( -text  => "ERROR: The account you requested ($account) " .
                               "does not exist on this system. Please check " .
                               "your typing.",
                     -value => 'GetAcct' );
    }

    #			 
    #    Check if account is disabled
    #
    my @disabled_users;

    if (open(DISABLED, DISABLED_FILE) ) 
    {
	@disabled_users=<DISABLED>;
	close(DISABLED);
    }

    my $dissed;
    foreach $dissed (@disabled_users)
    {
	$dissed =~s/\s+$//;
	if ( $account eq $dissed ) {
	     throw Error( -text => "ERROR: Please contact admin\@employees.org " .
			           "about the status of account: $account",
			  -value => 'GetAcct' );
	 }
    }

    # Write the change to the log file
    log_it( 'Request', $account );

    return $account;
}
######################################################################
# lifted from: http://www.hk8.org/old_web/linux/cgi/ch09_02.htm
######################################################################
sub validate_email_address {
    my $addr_to_check = shift;
    $addr_to_check =~ s/("(?:[^"\\]|\\.)*"|[^\t "]*)[ \t]*/$1/g;
    
    my $esc         = '\\\\';
    my $space       = '\040';
    my $ctrl        = '\000-\037';
    my $dot         = '\.';
    my $nonASCII    = '\x80-\xff';
    my $CRlist      = '\012\015';
    my $letter      = 'a-zA-Z';
    my $digit       = '\d';
    
    my $atom_char   = qq{ [^$space<>\@,;:".\\[\\]$esc$ctrl$nonASCII] };
    my $atom        = qq{ $atom_char+ };
    my $byte        = qq{ (?: 1?$digit?$digit | 
                              2[0-4]$digit    | 
                              25[0-5]         ) };
    
    my $qtext       = qq{ [^$esc$nonASCII$CRlist"] };
    my $quoted_pair = qq{ $esc [^$nonASCII] };
    my $quoted_str  = qq{ " (?: $qtext | $quoted_pair )* " };
    
    my $word        = qq{ (?: $atom | $quoted_str ) };
    my $ip_address  = qq{ \\[ $byte (?: $dot $byte ){3} \\] };
    my $sub_domain  = qq{ [$letter$digit]
                          [$letter$digit-]{0,61} [$letter$digit]};
    my $top_level   = qq{ (?: $atom_char ){2,4} };
    my $domain_name = qq{ (?: $sub_domain $dot )+ $top_level };
    my $domain      = qq{ (?: $domain_name | $ip_address ) };
    my $local_part  = qq{ $word (?: $dot $word )* };
    my $address     = qq{ $local_part \@ $domain };
    
    return $addr_to_check =~ /^$address$/ox ? $addr_to_check : "";
}

######################################################################
sub validate_sponsor {
    my $account;
    # Look up this account's sponsor
    my $USERDB = new EmplOrg::AccountDB;
    my $result;
    my $sponsor = '';

    if( url_param( 'token' ) ) {
        _load_token_file();
        $account = $Token_info{ account } || '';
    }
    else {
        $account = param( 'account' ) || '';
    }

    throw Error( -text  => "ERROR: Illegal account name ($account).",
                 -value => 'GetAcct' )
        unless $account =~ /(^[a-z0-9_]{1,16}$)/;

    $account = $1;              # Untaint $account

    $result = $USERDB->fetch( $account );
    $sponsor = $result->{sponsor} if( $result );

    # Check that sponsor in the database is an E-mail address
    # (Some of the early accounts have blank sponsor fields)
    $sponsor = validate_email_address( $sponsor );

    # OK, untaint
    ($sponsor) = ($sponsor =~ /(.*)/);

    return $sponsor;
}

######################################################################
sub validate_alternate {
    my $account;
    # Look up this account's alternate E-mail contact
    my $USERDB = new EmplOrg::AccountDB;
    my $result;
    my $alternate = '';

    if( url_param( 'token' ) ) {
        _load_token_file();
        $account = $Token_info{ account } || '';
    }
    else {
        $account = param( 'account' ) || '';
    }

    throw Error( -text  => "ERROR: Illegal account name ($account).",
                 -value => 'GetAcct' )
        unless $account =~ /(^[a-z0-9_]{1,16}$)/;

    $account = $1;              # Untaint $account

    $result = $USERDB->fetch( $account );
    $alternate = $result->{alternate_contact} if( $result );

    # Check that alternate in the database is an E-mail address
    $alternate = validate_email_address( $alternate );

    # OK, untaint
    ($alternate) = ($alternate =~ /(.*)/);

    return $alternate;
}

######################################################################
sub validate_key {
    _load_token_file();

    my $key = param( 'key' );

    throw Error( -text  => "Error: Bad key ($key).",
                 -value => 'GetInfo' )
        unless $key eq $Token_info{ key };

    return $key;
}


######################################################################
sub validate_password {
    # HACK: should probably do more checking here. rotated account
    # name (since that's actually a rule. A dictionary check (as well
    # as trivial substitution) would be a good idea if it can be
    # reasonably fast (shouldn't be too hard).

    my $password = param( 'password' );

    # Check the length
    throw Error( -text  => "Error: Password too short.",
                 -value => 'GetInfo' )
        unless length( $password ) >= PASS_MIN_LEN;

    # FreeBSD allows up to 128 characters - don't truncate
    # # Only the first PASSLENGTH (8) characters matter
    # $password = substr( $password, 0, PASS_MAX_LEN );

    # need at least 2 alphabetics
    throw Error( -text  => "Error: Password needs at least two letters.",
                 -value => 'GetInfo' )
        unless ( $password =~ tr/A-Za-z// ) >= 2;

    # need at least 1 non-alphabetic
    throw Error( -text  => "Error: Password needs at least one non-letter.",
                 -value => 'GetInfo' )
        unless ( $password =~ tr/A-Za-z//c ) >= 1;

    # Can't be the login name or reverse
    my $account = validate_account();
    throw Error( -text  => "Error: Password too close to your login.",
                 -value => 'GetInfo' )
        if ( (index($password, $account) != -1) or                              
	     ( index($password, reverse( $account )) != -1 ));                   

    return $password;
}

######################################################################
sub validate_passwordcheck {
    my( $password )      = param( 'password' );
    my( $passwordcheck ) = param( 'passwordcheck' );
    
    throw Error( -text  => "Error: Passwords do not match.",
                 -value => 'GetInfo' )
        unless( $password eq $passwordcheck );
        
    return $passwordcheck;
}

######################################################################
sub validate_token {
    return _load_token_file();
}

######################################################################
sub _load_token_file {
    my( $token ) = ( url_param( 'token' ) =~ /^(\w{@{[TOKEN_LEN]}})$/ )
        or throw Error( -text  => "ERROR: Bad token (" .
                                  url_param( 'token' ) .")",
                        -value => 'GetAcct' );

    return $token if %Token_info;

    my $token_file = "@{[TOKEN_DIR]}/${token}";
    if( ! open( TOKEN, $token_file ) ) {
        throw Error( -text  => "ERROR: No such token ($token)",
                     -value => 'GetAcct' ) if $! == ENOENT;
        die "ERROR: Can't read token file ($token_file): $!";
    }

    chomp( $Token_info{ key              } = <TOKEN> )
                                          or die "Bad token file ($token_file)";
    chomp( $Token_info{ account          } = <TOKEN> )
                                          or die "Bad token file ($token_file)";

    close( TOKEN ) or die "Can't read $token_file: $!";

    return $token;
}

######################################################################
sub log_it {
    my ( $type, $account ) = @_;

    my $remote_addr = $ENV{ 'REMOTE_ADDR' };
    my $timestamp = localtime();
    my $log_file = ">>" . LOG_FILE;
    if ( open(LOG, $log_file) ) 
    {
	print LOG "[$timestamp] Reset $type: account: $account IP: $remote_addr\n";
	close(LOG);
    }
}

1;
