package NewAcct::Validate;

use strict;

use base 'Exporter';

use CGI   qw( :standard );
use Error qw( :try );
use POSIX qw( ENOENT );

use NewAcct::Config qw( DOMAIN LEGAL_DOMAINS PASS_MAX_LEN PASS_MIN_LEN LOG_FILE
               TOKEN_DIR TOKEN_LEN );

our @EXPORT_OK = qw( validate_fields log_it );

my %VALIDATE_MAP = ( account          => \&validate_account,
                     agree            => \&validate_agree,
                     alternate        => \&validate_alternate,
                     existing_account => \&validate_existing_account,
                     existing_domain  => \&validate_existing_domain,
                     fullname         => \&validate_fullname,
                     old_group        => \&validate_old_group,
                     password         => \&validate_password,
                     passwordcheck    => \&validate_passwordcheck,
                     pgp              => \&validate_pgp,
                     pop              => \&validate_pop,
                     realname         => \&validate_realname,
                     shell            => \&validate_shell,
                     sponsor          => \&validate_sponsor,
                     telephone        => \&validate_telephone,
                     token            => \&validate_token,
                     key              => \&validate_key,
                   );

my %GOTO_MAP = ( GetSponsor => { load => 'NewAcct::PageGetSponsor',
                                 run  => \&NewAcct::PageGetSponsor::run },
                 GetInfo    => { load => 'NewAcct::PageGetInfo',
                                 run  => \&NewAcct::PageGetInfo::run },
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
    if( url_param( 'token' ) ) {
        _load_token_file();
        $account = $Token_info{ account } || '';
    }
    else {
        $account = param( 'account' ) || '';
    }

    throw Error( -text  => "ERROR: Illegal account name ($account).",
                 -value => 'GetSponsor' )
        unless $account =~ /(^[a-z0-9_]{1,16}$)/;

    $account = $1;              # Untaint $account

    # Write the change to the log file
    log_it( 'Attempt', $account );

    # Make sure this account doesn't already exist. Send the user back
    # if there's an issue
    if( getpwnam( $account ) or getgrnam( $account ) or _check_aliases( $account )  )
    {
        throw Error( -text  => "ERROR: The account you requested ($account) " .
                               "already exists on this system. Please choose " .
                               "another account name.",
                     -value => 'GetSponsor' );
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
sub validate_alternate {
    my $alternate = param( 'alternate' ) || '';

    return $alternate if ($alternate eq '');

    # If not empty, make sure it is legal
    $alternate = validate_email_address( $alternate );

    my %domains = map { $_ => 1 } LEGAL_DOMAINS;
    my ($adomain) = ($alternate =~ /@(.*)$/);

    throw Error( -text  => "Error: invalid alternate E-mail address",
                 -value => 'GetInfo' )
	unless ( $alternate );

    throw Error( -text  => "Error: illegal alternate email domain ($adomain)",
	         -value => 'GetInfo' )
	unless ( !$domains{ $adomain } );

    # OK, untaint
    ($alternate) = ($alternate =~ /(.*)/);

    return $alternate;
}
######################################################################
sub validate_agree {
    my $agree = param( 'agree' );
    throw Error( -text  => "ERROR: Bad request. Didn't agree to terms",
                 -value => 'GetSponsor' )
        unless $agree eq 'yes';

    return $agree;
}

######################################################################
sub validate_existing_account {

    my $existing_account;
    if( url_param( 'token' ) ) {
        _load_token_file();
        $existing_account = $Token_info{ existing_account };
    }
    else {
        $existing_account = param( 'existing_account' );
    }

    throw Error( -text  => "ERROR: Bad sponsor account ($existing_account)",
                 -value => 'GetSponsor' )
        unless $existing_account =~ /^(\w+)$/;

    $existing_account = $1;     # Untaint

    return $existing_account;
}

######################################################################
sub validate_existing_domain {

    my $existing_domain;
    if( url_param( 'token' ) ) {
        _load_token_file();
        $existing_domain = $Token_info{ existing_domain };
    }
    else {
        $existing_domain = param( 'existing_domain' );
    }

    my %domains = map { $_ => 1 } LEGAL_DOMAINS;
    throw Error(
              -text  => "ERROR: Bad request. Illegal domain ($existing_domain).",
              -value => 'GetSponsor'
               )
        unless exists $domains{ $existing_domain };

    # Untaint (we pulled this out of a fixed list, so it has to be ok)
    ($existing_domain) = ($existing_domain =~ /(.*)/);

    return $existing_domain;
}

######################################################################
sub validate_fullname {

    my $fullname = param( 'fullname' );

    throw Error( -text  => "ERROR: Missing fullname.",
                 -value => 'GetInfo' )
        unless $fullname ne '';

    throw Error( -text => "ERROR: Bad characters in fullname.",
                 -value => 'GetInfo' )
        unless $fullname =~ /^([^\n\r:&]*)$/;

    $fullname = $1;             # Untaint

    return $fullname
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
sub validate_old_group {
    my $old_group = param( 'old_group' );

    if( validate_existing_domain() ne DOMAIN ) {
        return 0;
    }
    throw Error( -text  => "Error: Bad old_group value ($old_group).",
                 -value => 'GetInfo' )
        unless ($old_group eq 'yes') or ($old_group eq 'no');

    return( $old_group eq 'yes' );
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
sub validate_pgp {
    my $pgp = param( 'pgp' ) || '';

    throw Error( -text  => "Error: pgp cannot contain newline.",
                 -value => 'GetInfo' ) if $pgp =~ /\n/;

    # OK, untaint
    ( $pgp ) = ( $pgp =~ /(.*)/ );

    return $pgp;
}

######################################################################
sub validate_pop {
    my $pop = param( 'pop' );

    throw Error( -text  => "Error: Bad pop value ($pop).",
                 -value => 'GetInfo' )
        unless ( $pop eq 'yes' ) or ( $pop eq 'no' );

    return ( $pop eq 'yes' );
}

######################################################################
sub validate_realname {
    my $realname = param( 'realname' );

    throw Error( -text  => "Error: Missing realname.",
                 -value => 'GetInfo' ) unless $realname;

    throw Error( -text  => "Error: realname cannot contain newline.",
                 -value => 'GetInfo' ) unless $realname =~ /^([^\r\n]*)$/;

    $realname = $1;

    return $realname;
}

######################################################################
sub validate_shell {
    my $shell = param( 'shell' );

    open( SHELLS, "/etc/shells" ) or die "Can't open /etc/shells: $!";
    chomp( my @shells = <SHELLS> );
    close( SHELLS ) or die "Can't read /etc/shells: $!";

    foreach my $legal_shell ( @shells ) {
        if( $shell eq $legal_shell ) {
            ($shell) = ($shell =~ /(.*)/); # Untaint
            return $shell;
        }
    }

    throw Error( -text  => "Error: Illegal shell ($shell).",
                 -value => 'GetInfo' );
}

######################################################################
sub validate_telephone {
    my $telephone = param( 'telephone' ) || '';

    throw Error( -text  => "Error: telephone cannot contain newline.",
                 -value => 'GetInfo' ) if $telephone =~ /\n/;

    # OK, untaint
    ($telephone) = ($telephone =~ /(.*)/);

    return $telephone;
}

######################################################################
sub validate_token {
    return _load_token_file();
}

######################################################################
sub validate_sponsor {
    return validate_existing_account() . "@" . validate_existing_domain();
}

######################################################################
sub _load_token_file {
    my( $token ) = ( url_param( 'token' ) =~ /^(\w{@{[TOKEN_LEN]}})$/ )
        or throw Error( -text  => "ERROR: Bad token (" .
                                  url_param( 'token' ) .")",
                        -value => 'GetSponsor' );

    return $token if %Token_info;

    my $token_file = "@{[TOKEN_DIR]}/${token}";
    if( ! open( TOKEN, $token_file ) ) {
        throw Error( -text  => "ERROR: No such token ($token)",
                     -value => 'GetSponsor' ) if $! == ENOENT;
        die "ERROR: Can't read token file ($token_file): $!";
    }

    chomp( $Token_info{ key              } = <TOKEN> )
                                          or die "Bad token file ($token_file)";
    chomp( $Token_info{ existing_account } = <TOKEN> )
                                          or die "Bad token file ($token_file)";
    chomp( $Token_info{ existing_domain  } = <TOKEN> )
                                          or die "Bad token file ($token_file)";
    chomp( $Token_info{ account          } = <TOKEN> )
                                          or die "Bad token file ($token_file)";

    close( TOKEN ) or die "Can't read $token_file: $!";

    return $token;
}

sub _check_aliases {
    my ( $alias ) = @_;

    chomp( $alias );

    open(ALIASES_FILE, "/etc/mail/aliases") or die ("could not open aliases file.");
    foreach ( <ALIASES_FILE> ) {
	if ( /^$alias:/i ) {
	    close ALIASES_FILE;
	    return 1;
	}
    }
    close ALIASES_FILE;
    return 0;
}

######################################################################
sub log_it {
    my ( $type, $account ) = @_;

    my $remote_addr = $ENV{ 'REMOTE_ADDR' };
    my $timestamp = localtime();
    my $log_file = ">>" . LOG_FILE;
    if ( open(LOG, $log_file) ) 
    {
	print LOG "[$timestamp] NEWACCT $type: account: $account IP: $remote_addr\n";
	close(LOG);
    }
}

1;
