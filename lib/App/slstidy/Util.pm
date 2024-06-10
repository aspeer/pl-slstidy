#
#  This file is part of slstidy.
#
#  This software is copyright (c) 2024 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#

#
#
package App::slstidy::Util;


#  Pragma
#
use strict;
use vars qw($VERSION @EXPORT_OK);
use warnings;


#  External modules
#
use FindBin qw($RealBin $Script);
FindBin::again();
use Data::Dumper;
$Data::Dumper::Indent=1;
$Data::Dumper::Terse=1;


#  Export functions
#
use base 'Exporter';
@EXPORT_OK=qw(err msg arg debug debug_set quiet_set verbose_set script realbin Dumper);


#  Version information in a format suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='0.002';


#  Debugging on ?
#
#$Script=~s/\.pl$//;
#($Carp::Verbose=++$DEBUG) if $ENV{uc("${Script}_DEBUG")};
our ($Debug, $Quiet, $Verbose);


#  All done, init finished
#
1;

#==================================================================================================


sub debug {

    #  Debug
    #
    {   no strict qw(refs);
        $Debug ||= (${"${Script}::DEBUG"} ||= 0);
    }
    goto &msg if $Debug;

}


sub debug_set {
    $Debug=$Carp::Verbose=shift()
}


sub err {

    #  Quit on errors
    #
    my $msg=&fmt('error: %s', @_ ? @_ : 'unknown error');
    CORE::print STDERR $msg, "\n";
    eval {require Carp; 1};
    Carp::croak;

}


sub fmt {

    #  Format message nicely. Always called by err or msg so caller=2
    #
    my $message=sprintf(shift(), @_);
    chomp($message);
    my $caller=(caller(2))[3] || 'main';
    $caller=~s/^_?!(_)//;
    $caller=~s/.*:://;
    return "[${caller}] $message";

}


sub msg {

    #  Print message
    #
    return (CORE::print &fmt(@_), "\n") unless $Quiet;

}


sub quiet_set {
    $Quiet=shift();
}


sub realbin {
    $RealBin
}


sub script {
    $Script
}


sub verbose_set {
    $Verbose=shift();
}


__END__
