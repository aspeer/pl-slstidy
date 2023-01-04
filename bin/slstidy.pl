#!/usr/bin/perl

#
#  This file is part of slstidy.
#
#  This software is copyright (c) 2023 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#

#  Compiler pragma
#
use strict;
use vars qw($VERSION);
use warnings;


#  Script support modules
#
use App::slstidy;
use App::slstidy::Util qw(msg err debug Dumper);
use App::slstidy::Opt qw(getopt);
use App::slstidy::Constant;


#  Other External modules
#


#  Constantas
#
use constant {


    #  Command line options in Getopt::Long format
    #
    OPTION_AR => [

        'recurse|recursive|r',
        'file_extension_ar|file_extebsion|extension|e=s@',
        'nobackup',
        'srce_fn|file_name|fn|f|s=s@',
        'dest_fn|d=s',
        'inplace',
        'dryrun',
        'preserve' # preserve intermediate files, don't delete

    ],


    #  Option defaults
    #
    OPTION_DEFAULT_HR => {
    },


};


#  Version Info, must be all one line for MakeMaker, CPAN.
#
$VERSION='0.001';


#  Run main
#
exit(${&main(&getopt(+OPTION_AR, +OPTION_DEFAULT_HR)) || die err ()} || 0);    # || 0 stops warnings


#===================================================================================================


sub main {    #no subsort


    #  Get base object blassed with options as first arg.
    #
    my $self=App::slstidy->new(shift());
    

    #  Do something
    #
    debug('running');
    $self->run();


    #  Done
    #
    return \undef;


}


1;
__END__

# Documentation in Markdown. Convert to POD using markpod from 
#
# https://github.com/aspeer/pl-markpod.git 

=begin markdown

# NAME

slstidy - script short description

# SYNOPSIS

`slstidy.pl [--option] <arguments>`

# DESCRIPTION

slstidy.pl script long description

# OPTIONS

**--help** show help synopsis

**--man** show man page

**--version** show version information

# USAGE

script usage here
```
slstidy.pl --option argument
```
  
# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of slstidy.

This software is copyright (c) 2023 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>

=end markdown


=head1 NAME

slstidy - script short description


=head1 SYNOPSIS

C<<< slstidy.pl [--option] <arguments> >>>


=head1 DESCRIPTION

slstidy.pl script long description


=head1 OPTIONS

B<--help> show help synopsis

B<--man> show man page

B<--version> show version information


=head1 USAGE

script usage here
 
 slstidy.pl --option argument



=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE and COPYRIGHT

This file is part of slstidy.

This software is copyright (c) 2023 by Andrew Speer L<mailto:andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

L<http://dev.perl.org/licenses/>

=cut
