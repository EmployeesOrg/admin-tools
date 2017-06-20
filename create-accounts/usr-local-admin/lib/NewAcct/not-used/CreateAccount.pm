package NewAcct::CreateAccount;

use strict;

use base 'Exporter';

our @EXPORT_OK = qw( create );

use Fcntl qw( LOCK_EX );
use File::Copy qw( copy );
use IO::Handle;
use IPC::Open3;

# Note: Unix::PasswdFile routines are good for reading, but don't do
# proper writing on Solaris (they don't handle shadow, and they don't
# lock correctly). Do all passwd writing with Passwd::Solaris
# routines. BTW, Unix::GroupFile is very, very slow, too. groupadd is
# much better.
use Passwd::Solaris qw( setpwinfo );
use Unix::PasswdFile;

use NewAcct::Config qw( BASEDIR_FILE CHOWN DOMAIN EDQUOTA
                        GROUPADD HOMEDIR_PERM LINK_DIR LOCK_FILE
                        LOG_FILE PASSWD POPME QUOTA_USER SKEL
                        TOKEN_DIR USERADD );

use NewAcct::Database;

######################################################################
sub create {
    my( %info ) = @_;

    my $account          = $info{ account          };
    my $existing_account = $info{ existing_account };
    my $existing_domain  = $info{ existing_domain  };
    my $fullname         = $info{ fullname         };
    my $old_group        = $info{ old_group        };
    my $password         = $info{ password         };
    my $pgp              = $info{ pgp              };
    my $pop              = $info{ pop              };
    my $realname         = $info{ realname         };
    my $shell            = $info{ shell            };
    my $sponsor          = $info{ sponsor          };
    my $telephone        = $info{ telephone        };
    my $token            = $info{ token            };

    # Fix up UID so things like groupadd will work.
    $< = $>;

    # Creation lock. Only one of these should run at a time.
    open( LOCK, ">@{[ LOCK_FILE ]}" )
        or die "Couldn't open lock( @{[ LOCK_FILE ]}): $!";
    flock( LOCK, LOCK_EX ) or die "Couldn't get lock: $!";

    my $result;
    # Create group if needed
    my $group;
    my $gid;
    if( $old_group ) {
        $group = $existing_account;
        $gid   = getgrnam( $group ) or die "Couldn't find group ($group)."
    }
    else {
        $group = $account;
        my $result = run( GROUPADD, $group );
        if( $? ) { die "Unable to create group ($group): rc=$?\n$result\n" };
        $gid = getgrnam( $group ) or die "Failed to create group\n";
    }

    # Create account. We do it by hand rather than with useradd for
    # two reasons: better security since we don't shell out, and
    # because useradd is painfully, evilly, ridiculously slow.
    my $pw = new Unix::PasswdFile PASSWD, locking => 'flock'
        or die "Unable to create password object: $!";
    my $uid = $pw->maxuid( getpwnam( 'nobody' ) || 60_000 ) + 1;
    my $encpass = $pw->encpass( $password );
    my $home_dir = join( '/', LINK_DIR, $account );

    my @info = ( $account, $encpass, $uid, $gid, $fullname, $home_dir, $shell );

    setpwinfo( @info ) == 0
        or die "Couldn't create account: $!";

    # Set quota
    $result = run( EDQUOTA, '-p', QUOTA_USER, $account );
    if( $? ) { die $result };

    # Figure out where the real home directory should go
    my $basedir;
    open( BASEDIR, BASEDIR_FILE ) or die "Couldn't open defadduser: $!";
    while( <BASEDIR> ) { last if ($basedir) = /^defparent=(\S+)$/ };
    close( BASEDIR ) or die "Couldn't read defadduser: $!";
    die "Couldn't determine basedir" unless $basedir;

    # Create home directory
    my $real_home_dir = "${basedir}/${account}";
    mkdir( $real_home_dir , HOMEDIR_PERM )
        or die "Couldn't create home directory ($real_home_dir): $!";

    # Copy skel files
    opendir( SKELDIR, SKEL ) or die "Couldn't opendir @{[SKEL]}: $!";
    foreach my $file( grep { ! -d } readdir( SKELDIR ) ) {
        # Untaint $file. We got it out of /etc/skel, which is only
        # root writable, so we know it's safe.
        ($file) = ($file =~ /(.*)/ );
        copy( "@{[SKEL]}/$file", "$real_home_dir/$file" )
            or die "Couldn't copy @{[SKEL]}/$file: $!";
    }
    closedir( SKELDIR ) or die "Couldn't close @{[SKEL]}: $!";

    # Fix up ownership (much easier to use 'chown -R' rather than
    # doing this by hand in perl).
    $result = run( CHOWN, '-R', $account, $real_home_dir );
    if( $? ) { die $result };

    # Link the home directory into the "master" directory unless we
    # just created the home directory in that directory anyway.
    if ( $real_home_dir ne $home_dir ) {
        symlink($real_home_dir, $home_dir ) or die "Couldn't link homedir: $!";
    }

    # Turn on pop if needed
    if( $pop ) {
        $result = run(POPME, '-y', $account);
        if( $? ) { die $result }; # HACK
    }

    # Log it
    my $db = new NewAcct::Database;

    $db->insert( account   => $account,
                 sponsor   => $sponsor,
                 realname  => $realname,
                 telephone => $telephone,
                 pgp       => $pgp,
               );

    # Unlock
    close LOCK;
}

######################################################################
sub run {
    my( @args ) = @_;

    my $wtrfh = new IO::Handle;
    my $rdrfh = new IO::Handle;
    my $errfh = new IO::Handle;

    my $pid = open3( $wtrfh, $rdrfh, $errfh, @args )
        or die "Can't run @args: $!";
    waitpid( $pid, 0 );
    return( join( '', $rdrfh->getlines, $errfh->getlines ) );
}
