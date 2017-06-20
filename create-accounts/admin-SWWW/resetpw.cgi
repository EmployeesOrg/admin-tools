#!/usr/local/bin/perl5 -wT

use strict;
use lib qw( /usr/local/admin/lib );

use CGI       qw( :standard :ssl          );
use CGI::Carp qw( fatalsToBrowser carpout );
use Error     qw( :try                    );

use ResetPasswd::Boiler qw( mail             );
use ResetPasswd::Config qw( ADMIN ERROR_FILE );

######################################################################
sub assert_https {
    if( ! https() ) {
        print h1("Must be run via HTTPS");
        return 0;
    }
    else {
        return 1;
    }
}

######################################################################
# MAIN
######################################################################
try {
    $ENV{ PATH } = '/usr/bin:/bin';

    open( ERROR, ">>@{[ERROR_FILE]}") or die "Can't open error_log: $!";
    carpout( \*ERROR );

    print header;

    if( assert_https() ) {

        my $next = param( 'next' ) || '';

        if( $next eq 'IssueKey' ) {
            require ResetPasswd::PageIssueKey;
            ResetPasswd::PageIssueKey::run();
        }
        elsif( $next eq 'ResetPasswd' ) {
            require ResetPasswd::PageResetPasswd;
            ResetPasswd::PageResetPasswd::run();
        }
        elsif( url_param( 'token' ) ) {
            require ResetPasswd::PageGetInfo;
            ResetPasswd::PageGetInfo::run();
        }
        else {
            require ResetPasswd::PageGetAccount;
            ResetPasswd::PageGetAccount::run();
        }
    }
    otherwise {
        my $e = shift;
        my $stamp = CGI::Carp::stamp;
        my $message = '';
        try {
            mail( ADMIN, "employees.org account creation error", $e->stringify );
        }
        otherwise {
            my $sub_e = shift;
            $message .= $sub_e->stringify;
        };
        $message .= $e->stringify;
        CGI::Carp::fatalsToBrowser $message;
        param( 'password', '' );    # Just in case
        $message .= CGI::Dump();
        $message =~ s/^/$stamp/gm;
        die $message;
    };
}
