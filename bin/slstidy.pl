#!/usr/bin/perl

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

#  Compiler pragma
#
use strict;
use vars qw($VERSION);
use warnings;


#  Script support modules
#
use App::slstidy;
use App::slstidy::Util qw(msg err debug Dumper);
use App::slstidy::Opt  qw(getopt);
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
        'stdout',
        'inplace',
        'dryrun',
        'preserve'    # preserve intermediate files, don't delete

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
exit(${&main(&getopt(+OPTION_AR, +OPTION_DEFAULT_HR)) || die err()} || 0);    # || 0 stops warnings


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

slstidy - tidy up Saltstack (Salt) SLS files

# SYNOPSIS

`slstidy.pl [--option] <arguments>`

# DESCRIPTION

slstidy.pl - tidy up Saltstack (Salt) SLS files by unifying comment and
quoting conventions, then passing through the `yq` data processor and
`yamllint` linter to clean up syntax.

The code contains several optimisations specific to the author's
requirements but it is hoped the script may be generally useful.

# OPTIONS

**--help** show help synopsis

**--man** show man page

**--version** show version information

**--quiet** don't output any status information

**--recurse** iterate through all sls file in the current and lower directories

**--extension|e** the file extensions to process when recursing. Defaults to 'sls'

**--nobackup** don't make a backup of files before tidying them

**--file_name|fn|f** file or files to process

**--dest_fn|d** output file. Defaults to source file name with '.tdy' extension added

**--stdout** send output to STDOUT

**--inplace** update files in-place

**--dryrun** just run through yq processor and linter, do not create any output files

**--preserve** preserve intermediate files for examination


# USAGE

```
slstidy.pl --option argument
```

# EXAMPLES

Tidy the Salt top.sls file and send output to screen
```
slstidy.pl --stdout /srv/salt/top.sls
```
  
# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of slstidy.

This software is copyright (c) 2024 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>

=end markdown


=head1 NAME

slstidy - tidy up Saltstack (Salt) SLS files


=head1 SYNOPSIS

C<<< slstidy.pl [--option] <arguments> >>>


=head1 DESCRIPTION

slstidy.pl - tidy up Saltstack (Salt) SLS files by unifying comment and
quoting conventions, then passing through the C<yq> data processor and
C<yamllint> linter to clean up syntax.

The code contains several optimisations specific to the author's
requirements but it is hoped the script may be generally useful.


=head1 OPTIONS

B<--help> show help synopsis

B<--man> show man page

B<--version> show version information

B<--quiet> don't output any status information

B<--recurse> iterate through all sls file in the current and lower directories

B<--extension|e> the file extensions to process when recursing. Defaults to 'sls'

B<--nobackup> don't make a backup of files before tidying them

B<--file_name|fn|f> file or files to process

B<--dest_fn|d> output file. Defaults to source file name with '.tdy' extension added

B<--stdout> send output to STDOUT

B<--inplace> update files in-place

B<--dryrun> just run through yq processor and linter, do not create any output files

B<--preserve> preserve intermediate files for examination


=head1 USAGE


 slstidy.pl --option argument

=head1 EXAMPLES

Tidy the Salt top.sls file and send output to screen
 
 slstidy.pl --stdout /srv/salt/top.sls



=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE and COPYRIGHT

This file is part of slstidy.

This software is copyright (c) 2024 by Andrew Speer L<mailto:andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

L<http://dev.perl.org/licenses/>

=cut
