package EmplOrg::AccountDB;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use DBI;

$VERSION = '1.0';

my $CONFIG_FILE = '/var/newacct/config';

sub new {
    my( $pkg ) = @_;

    my $self = bless( {}, $pkg );

    my( $user, $pass ) = $self->_getpass;

    $self->{ dbh } = DBI->connect( "DBI:mysql:database=admin;host=localhost",
                                   $user, $pass , { RaiseError => 1 });
    return $self;

}

sub insert {
    my( $self, %hash ) = @_;

    return $self->{ dbh }->
        do(
           q{
INSERT INTO accounts
            ( account, sponsor, realname, telephone, pgp, alternate_contact, created, record_updated, status, last_accessed )
     VALUES ( ?,       ?,       ?,        ?,         ?,   ?,                 NOW(),   NOW(),          'A',    NOW()         )
}, undef,
           $hash{ account   },
           $hash{ sponsor   },
           $hash{ realname  },
           $hash{ telephone },
           $hash{ pgp       },
           $hash{ alternate } );
}

sub delete {
    my( $self, $account ) = @_;

    # Grab everything but status
    my @row = $self->{ dbh }->selectrow_array(
        q{SELECT account, sponsor, realname, telephone, pgp, alternate_contact, created, last_accessed
          FROM accounts WHERE account = ?}, undef, $account);

    return undef unless @row;

    # Insert it into the accounts_deleted table
    $self->{ dbh }->do(
        q{
INSERT INTO accounts_deleted
       ( account, sponsor, realname, telephone, pgp, alternate_contact, created, last_accessed, deleted, status )
VALUES ( ?,       ?,       ?,        ?,         ?,   ?,                 ?,       ?,             NOW(),   'D'    )
}, undef, @row);

    # Remove the old record
    return $self->{ dbh }->do( q{DELETE FROM accounts WHERE account = ?},
                               undef, $account );
}

sub dump {
    my( $self, $file ) = @_;

    my( $user, $pass ) = $self->_getpass;

    my $command = "/usr/local/bin/mysqldump -u $user --password=$pass admin";
    if( $file ) {
        die "$file already exists" if( -e $file );
        return system( "$command > $file" ) == 0;
    }
    else {
        return `$command`;
    }
}

sub fetch {
    my( $self, $account ) = @_;

    # Grab all info
    my $result = $self->{ dbh }->selectall_hashref(
        q{SELECT * FROM accounts WHERE account = ?}, 'account', undef, $account);

    return $result->{ $account } if $result;
    return undef;

}

sub _getpass {
    my( $self ) = @_;

    open( CONFIG, $CONFIG_FILE ) or die "Couldn't open config: $!";
    my( $user, $pass );
    foreach ( <CONFIG> ) {
        if( /^user\s*=\s*(\w+)$/ ) {
            $user = $1;
            next;
        }
        if( /^pass\s*=\s*(\w+)$/ ) {
            $pass = $1;
            next;
        }
    }
    close CONFIG or die "Couldn't read config: $!";
    die "Couldn't find user and pass for log\n" unless $user && $pass;
    return( $user, $pass );
}

DESTROY {
    my( $self ) = @_;

    $self->{ dbh }->disconnect;
}

1;
__END__

=head1 NAME

EmplOrg::AccountDB - Perl interface to the employees.org account database

=head1 SYNOPSIS

  use EmplOrg::AccountDB;


=head1 DESCRIPTION

Unless you're in the staff group, you can't use this module.

=head1 AUTHOR

Rob Napier <rnapier@employees.org>

=head1 SEE ALSO

perl(1).

=cut
