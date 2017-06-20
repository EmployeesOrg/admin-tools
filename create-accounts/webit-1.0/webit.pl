#!/usr/local/bin/perl5 -wT


use strict;

my $VERSION = '1.0';

######################################################################
# MODULES
######################################################################
use POSIX;
use Getopt::Long;
use Pod::Usage ();

######################################################################
# CONSTANTS
######################################################################

my $WWW_GRP          = 'www';
#my $WWW_GID          = getgrnam( $WWW_NAME ) or die "Can't find www group\n";

my $DIR_PERMS        = S_IRGRP | S_IXGRP;
my $FORCE_DIR_PERMS  = S_IRWXU | $DIR_PERMS;

my $HOME_PERMS       = S_IRGRP | S_IXGRP;
my $FORCE_HOME_PERMS = S_IRWXU | $HOME_PERMS;

my $FILE_PERMS       = S_IRGRP | S_IROTH;
my $FILE_PERMS_MASK  = 0;
my $FORCE_FILE_PERMS = S_IRUSR | S_IWUSR | $FILE_PERMS;

my $SETFACL          = '/bin/setfacl';

######################################################################
# GLOBALS
######################################################################
my( $Quiet, $Recurse, $Help, $Man, $Force, $Dry_Run, $No_Home, $Auto );

######################################################################
# SUBS
######################################################################

# We have our own pod2usage because Pod::Usage is not suid safe.
sub pod2usage {
    # Reduce our permissions back to the user
    $> = $<;
    $) = $(;
    $ENV{PATH} = "/bin";
    Pod::Usage::pod2usage( @_ );
}

sub fix_gid {
    my( $target ) = @_;
    $ENV{PATH} = "/bin:/sbin";
    $ENV{ENV} = '';

    my $gid  = (stat( $target ))[5];
    my $cgid = (getpwuid( $< ))[3];

    # chgrp if needed
    if( $gid != $cgid ) {
        printf( "chgrp $cgid %s\n", $target ) unless $Quiet;
        unless( $Dry_Run ) {
            chown $<, $cgid, $target or die "Can't chgrp $target: $!";
        }
    }
    if ( -d $target ) {
	unless( $Dry_Run ) {
	    my $safe_target = $target;
	    $safe_target =~ s/([;<>\*\|`&\$!#\(\)\[\]\{\}:'"\s])/\\$1/g;
	    printf( "setfacl -m g:%s:rx,u::rwx,g::---,o::--- %s\n", $WWW_GRP, $safe_target) unless $Quiet;
	    system("$SETFACL -m g:$WWW_GRP:rx,u::rwx,g::---,o::--- $safe_target");
	}
    }
}

sub fix_perms {
    my( %hash ) = @_;
    my( $target       ) = $hash{ TARGET } or die "Bad fix_perms call";
    my( $normal_perms ) = $hash{ NORMAL } or die "Bad fix_perms call";
    my( $force_perms  ) = $hash{ FORCE  } or die "Bad fix_perms call";
    my( $mask         ) = $hash{ MASK   } || 0;

    my $mode = (stat( $target ))[2] & 07777; # Mask off file type

    if( ( $Force && ( $mode                   != $force_perms  ) ) or
        (           ( $mode & $normal_perms ) != $normal_perms )   or
        (           ( $mode & ~$mask        ) != $mode         ) )
    {

        my $perms = $Force ? $force_perms :
            ( ($mode & ~ $mask ) | $normal_perms );
        printf( "chmod %o %s\n", $perms, $target ) unless $Quiet;
        unless( $Dry_Run ) {
            chmod $perms, $target
                or die "Can't chmod $target to $perms: $!\n";
        }
    }
}

sub fix_home {
    my( $home ) = @_;

    fix_gid( $home );
    fix_perms( TARGET => $home,
               NORMAL => $HOME_PERMS,
               FORCE  => $FORCE_HOME_PERMS );
}

sub process {
    my( @targets ) = @_;

    foreach my $target (@targets) {
        if( -O $target ) {
            # Target exists and is owned by user, so untaint it
            ($target) = ($target =~ /(.*)/);

            fix_gid( $target );

            # Directories
            if( -d _ ) {
                fix_perms( TARGET => $target,
                           NORMAL => $DIR_PERMS,
                           FORCE  => $FORCE_DIR_PERMS );

                # Dive
                if( $Recurse ) {
                    opendir( SUBDIR, $target )
                        or die "Couldn't open $target: $!\n";
                    my @children = grep {! /^\.\.?$/} readdir( SUBDIR );
                    closedir( SUBDIR ) or die "Couldn't read $target: $!\n";
                    process( map { "$target/$_" } @children );
                }
            }

            # Files
            elsif( -f _ ) {
                fix_perms( TARGET => $target,
                           NORMAL => $FILE_PERMS,
                           FORCE  => $FORCE_FILE_PERMS,
                           MASK   => $FILE_PERMS_MASK );
            }
        }
        else {
            warn( "$target does not exist or is not owned by current user. ",
                  "Skipping.\n" );
        }
    }
    return 1;
}

######################################################################
# MAIN
######################################################################

GetOptions( 'quiet|q'   => \$Quiet,
            'recurse|R' => \$Recurse,
            'force'     => \$Force,
            'dryrun|n'  => \$Dry_Run,
            'nohome'    => \$No_Home,
            'auto'      => \$Auto,
            'help|?'    => \$Help,
            'man'       => \$Man,
            'version'   => sub { print "$VERSION\n"; exit(0) },
          ) or pod2usage( 2 );

pod2usage( 1 ) if $Help;
pod2usage( -noperldoc => 1, -exitstatus => 0, -verbose => 2 ) if $Man;
pod2usage( 2 ) unless(!$Auto && @ARGV) or ($Auto && !@ARGV);
pod2usage( 2 ) if( $Auto and $Recurse );

my @targets = @ARGV;

my $home = (getpwuid( $< ))[7];

fix_home( $home ) unless $No_Home;

if( $Auto ) {
    $Recurse = 1;
    @targets = "$home/WWW";
}

process( @targets );

__END__

=head1 NAME

webit - Enable web access to files

=head1 SYNOPSIS

B<webit> S<[ B<-R|--recurse> ]>
         S<[ B<-q|--quiet  > ]>
         S<[ B<-f|--force  > ]>
         S<[ B<-n|--dryrun > ]>
         S<[ B<--nohome    > ]>
         I<file ...>

B<webit> S<  B<-a|--auto   >  >
         S<[ B<-q|--quiet  > ]>
         S<[ B<-f|--force  > ]>
         S<[ B<-n|--dryrun > ]>
         S<[ B<--nohome    > ]>

B<webit> S< B<-h|--help>>

B<webit> S< B<-m|--man>>

B<webit> S< B<--version>>

=head1 DESCRIPTION

Makes files readable by employees.org web server.

=head2 Switches

=over 4

=item B<--auto>

Automatically fix WWW directory. Equivalent to S<B<webit -R ~/WWW>>.

=item B<--dryrun>

Don't actually change anything.

=item B<--force>

Change permissions to exactly expected permissions (02750 for
directories, 00640 for files)

=item B<--help>

Output basic help and exit.

=item B<--man>

Output full man page and exit.

=item B<--nohome>

Skip home directory fix-up.

=item B<--recurse>

Recursively modify entire directory tree.

=item B<--quiet>

Only output errors.

=item B<--version>

Output version number.

=head2 Details

The web server runs as group F<www>. In order for static HTML to be read, the
file must be readable by that group. B<webit> modifies the group ownership to
F<www>, and makes files and directories group readable. Directories are also
made setgid so that new files will automatically be group F<www>.

Note that B<webit> only adds permissions. It does not remove any
existing permissions except S_ISGID and S_ISUID (which it always
removes from files, but not directories).

=head1 AUTHOR

Rob Napier, rnapier@employees.org

=cut
