package ResetPasswd::Boiler;

use strict;

use base 'Exporter';

our @EXPORT_OK = qw( mail send_top send_bottom );

use CGI::Carp qw( confess );

use ResetPasswd::Config qw( ADMIN );

######################################################################
sub send_top {

    print <<EOF;
[<a href="http://www.employees.org/">Site top</a>]
[<a href="http://www.employees.org/docs/">General</a>]
<hr>
<h1>employees.org Account Password Reset Form</h1>
<hr>
EOF
}

######################################################################
sub send_bottom {

    print <<EOF;
<hr>
<address><a href="mailto:@{[ADMIN]}">@{[ADMIN]}</a></address>
<hr>
</body>
</html>
EOF

    close STDOUT;
}

######################################################################
sub mail {
    my( $to, $subject, @body ) = @_;

    # Hate to do this, but Mail::Sendmail spews "Mail::Sendmail::S opened
    # only for output" warnings.
    local $^W = 0;

    require Mail::Sendmail;
    Mail::Sendmail::sendmail( From    => ADMIN,
                              Subject => $subject,
                              To      => $to,
                              Message => join( '', @body ) )
        or confess( "Unable to send mail: $Mail::Sendmail::error\n" );
}
