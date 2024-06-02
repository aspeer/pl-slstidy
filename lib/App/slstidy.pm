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

#
#
package App::slstidy;


#  Pragma
#
use strict qw(vars);
use vars   qw($VERSION);
use warnings;


#  Support modules
#
use App::slstidy::Util qw(msg debug err Dumper);
use App::slstidy::Constant;


#  External modules
#
use IO::File;
use File::Find;
use File::Copy    qw(copy move);
use Cwd           qw(cwd);
use Capture::Tiny qw(capture);
use File::Temp    qw(tempfile);


#  Version information in a format suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='0.001';


#  All done, init finished
#
1;

#===================================================================================================


sub new {


    #  Create self ref
    #
    my ($class, $param)=@_;
    debug('initiating %s', Dumper($param));
    return bless(ref($param) ? $param : \$param, $class);

}


sub run {

    #  Run the command
    #
    my $self=shift();


    #  Are we recursive - or single file
    #
    if ($self->{'recurse'}) {

        #  Get directory we are operating on
        #
        my @dn=$self->{'action_ar'}
            ?
            @{$self->{'action_ar'}}
            : (cwd());


        #  Process permitted file extensions
        #
        my @fn_ext=$self->{'file_extension_ar'}
            ?
            @{$self->{'file_extension_ar'}}
            :
            ($SLS_FILE_EXTENSION);
        @fn_ext=map {split(/,/, $_)} @fn_ext;


        #  Filter subroutine to get just files we want
        #
        my @fn;
        my $find_sr=sub {
            my $fn=shift();
            return unless (grep {$fn=~/\.${_}$/} @fn_ext);
            push @fn, $fn;
        };


        #  Run filter across all files in target directory
        #
        find(sub {$find_sr->($File::Find::name)}, @dn);
        foreach my $fn (@fn) {
            $self->slstidy($fn) ||
                return err();
        }

    }
    else {

        #  Single or nominated files only
        #
        foreach my $fn (grep {$_} @{$self->{'srce_fn'}}, @{$self->{'action_ar'}}) {

            $self->slstidy($fn) ||
                return err();

        }

    }

    #  Done
    #
    return \undef;

}


sub slstidy {


    #  Get self ref, file name we are operating on
    #
    my ($self, $srce_fn)=@_;
    msg("file $srce_fn: processing start");


    #  Dest file name and open handle
    #
    my ($dest_fn, $dest_fh);
    if ($self->{'dryrun'}) {
        ($dest_fh, $dest_fn)=tempfile(SUFFIX => '.tdy');
    }
    else {
        $dest_fn=$self->{'dest_fn'} ? $self->{'dest_fn'} . '.tdy' : "${srce_fn}.tdy";
        $dest_fn=File::Spec->rel2abs($dest_fn);
        $dest_fh=IO::File->new($dest_fn, O_CREAT | O_TRUNC | O_WRONLY) ||
            return err("error opening $dest_fn for write, $!");
    }

    #my ($dest_fh, $dest_fn)=tempfile(UNLINK => 1);


    #  Make backup
    #
    unless ($self->{'nobackup'} || $self->{'dryrun'}) {
        copy($srce_fn, "${srce_fn}.bak") ||
            return err("unable to make backup copy of $srce_fn, $!")
    }


    #  Source file handle
    #
    my $srce_fh=IO::File->new($srce_fn, O_RDONLY) ||
        return err("unable to open $srce_fn for reading: $!");


    #  Start reading line by line, add document start if not present on first line
    #
    my $doc_start_seen;
    my $doc_end_seen;
    my $nl_count=0;
    my $in_jinja=0;
    my @in_jinja;
    my $line_no=0;
    my @line;

    while (my $line=<$srce_fh>) {


        #  Keep track of what line we are on
        #
        $line_no++;
        chomp($line);


        #  Start tidy up. Print doc start header if not seen
        #
        if ($line=~/^\-\-\-/) {
            $doc_start_seen++;
        }
        if (!$doc_start_seen && !(($line=~/^\#/) || ($line=~/^\%/))) {
            print $dest_fh '---', $/;
            $doc_start_seen++;
        }


        #  Take note if we see doc end/start header
        #
        if ($line=~/^\.\.\./) {
            $doc_end_seen++;
        }

        #  Lower case True=>true
        #
        if ($line=~/:\s*True\s*$/) {
            $line=~s/:\s*True\s*$/: true/;
        }

        #  Is this a new line ? Make sure not more than 2
        #
        if ($line=~/^\s*$/) {
            $nl_count++;
        }
        else {
            $nl_count=0;
        }
        next if ($nl_count > 2);


        #  Does a line start with a Jinja comment token ? Change to regular one
        #
        if ($line=~/^\s*{#/ || $line=~/^\s*#}/) {
            $line=~s/\s*[{}]//;
        }


        #  Comment out Jinja syntax
        #
        #$line=~s/^\s*\{\%/#  \{\%/;
        ##$line=~s/^\s*\%\}/#  \%\}/;


        #  Keep track if in or out of jinja block and comment out if in block.
        #
        #  UPDATE. Breaks Jinja. No multiline statements for you.
        #
        #if ($in_jinja) {
        #unless ($line=~/^#/) {
        #    $line="#  ${line}";
        #}
        #}
        #$in_jinja+=($line=~/\{\%/);
        #$in_jinja+=($line=~/\%\}/);
        #$in_jinja%=2;
        if ($line=~/\{\%/ && $line=~/\%\}/) {

            #  All on one line. Just comment out if needed and continue
            #
            #print "line 0: $line\n";
            $line=~s/^\s*\{\%/#  \{\%/;
        }
        elsif ($line=~/\{\%/ && $line !~ /\%\}/) {

            #  Onlt start of Jinja line or already in block. Push and loop
            #
            #print "line 1: $line\n";
            push @in_jinja, $line;
            $in_jinja=1;
            next;
        }
        elsif ($line !~ /\{\%/ && $line=~/\%\}/) {

            #  End of Jinja, consolidate and continue
            #
            #print "line 2: $line\n";
            $line=~s/^\s*//;
            $line=join('', @in_jinja, $line);
            $in_jinja=0;
            @in_jinja=();
            $line=~s/^\s*\{\%/#  \{\%/;
        }
        elsif ($in_jinja) {

            #  Still in Jinja block.
            #
            $line=~s/^\s*//;
            push @in_jinja, $line;
            next;
        }

        #print "line: $line\n";

        #elsif ($in_jinja) {
        #    #  Still in Jinja block.
        #    #
        #    puh


        #  Space in {{ varname }}
        $line=~s/\{\{\s*/{{ /ig;
        $line=~s/\s*\}\}/ }}/ig;


        #  Single quote keys with {{ in content
        #
        if ($line=~/^(.*?)\{\{(.*)\}\}\s*:\s*(.*)/) {
            $line="${1}'{{$2}}': $3";
        }


        #  SLS => SLSPATH in values. Plus keys if applicable, add {{ sls }} to any {{ salt.random.shadow_hash()
        #  }} keys
        #
        $line=~s/([:-].*?)\{\{\s*sls\s*\}\}/$1\{\{ slspath \}\}/i;
        unless ($line=~/\{\{\s*sls\s*\}\}.*?[:-]/) {
            $line=~s/^(.*)\'+(.*?)\{\{\s*salt\.random\.shadow_hash\(\)\s*\}\}(.*?)(?=[-:])/$1\'\{\{ sls \}\}.$2\{\{ salt.random.shadow_hash() \}\}\'/;
        }


        #  Clumsy regxp to quote lines with jinja variables {{. First check if value is quoted already - if so leave it
        #
        if ($line=~/^(.*?)[:-]\s+\S/) {
            unless ($line=~/^(.*?)[:-]\s+['""](.*)['""]$/) {

                #  Does it contain a single quote somewhere in the value already ? If so double quote it
                #
                if ($line=~/^.*?[:-].*'/) {
                    unless ($line=~s/^(.*?)(?!-)([:-])\s+(.*?\{\{.*\}\}.*)$/$1$2 "$3"/g) {
                        $line=~s/^(.*?)([:-])\s+(.*?\{\{.*\}\}.*)$/$1$2 "$3"/g
                    }
                    $line=~s/"{2,}/"/g;
                }

                #  Otherwise single quote it
                #
                else {
                    unless ($line=~s/^(.*?)(?!-)([:-])\s+(.*?\{\{.*\}\}.*)$/$1$2 '$3'/g) {
                        $line=~s/^(.*?)([:-])\s+(.*?\{\{.*\}\}.*)$/$1$2 '$3'/g
                    }
                    $line=~s/'{2,}/'/g;
                }

            }
        }


        #  At least two spaces betwee start of comment and text
        #
        if ($line=~/^#\s{1}(\S+)(.*)$/) {
            $line="#  ${1}${2}";
        }


        #  Get rid of trailing spaces
        #
        $line=~s/\s+$//;


        #  OK - print it out
        #
        push @line, $line;
    }


    #  Get rid of trailing empty lines at end of file
    #
    for (my $line_ix=$#line; $line_ix > 0; $line_ix--) {
        last if ($line[$line_ix] !~ /^\s*$/);
        splice @line, ($line_ix);
    }
    map {print $dest_fh $_, $/} @line;


    #  Add document end footer if not seen in document. REMOVED - not prited by YQ anyway
    #
    #unless ($doc_end_seen) {
    #    print $dest_fh '...', $/;
    #}


    #  Close file handles
    #
    $dest_fh->close();
    $srce_fh->close();


    #  Now run through pretty print
    #
    my $yq_fn="${dest_fn}.yq";
    {   my ($stdout, $stderr, $exit)=capture {
            system(
                'yq',

                #'-P', # Doesn't work - doesn't quote scalar = character as value for example
                $dest_fn
            )
        };
        if ($exit != 0) {

            #copy($dest_fn, my $fn_tidy=File::Spec->catfile(cwd(), [File::Spec->splitpath($srce_fn)]->[2].'.tdy'));
            return err("yq command exited with non-zero code: $exit, output was: $stderr, tdy file: $dest_fn");
        }
        else {
            msg("file $dest_fn: yq format OK")
        }

        #  And save
        #
        my $yq_fh=IO::File->new($yq_fn, O_CREAT | O_TRUNC | O_WRONLY) ||
            return err("unable to open file $yq_fn for output, $!");
        print $yq_fh $stdout;
        $yq_fh->close();

    }


    #  And linter
    #
    {   my ($stdout, $stderr, $exit)=capture {
            system(
                'yamllint',
                $yq_fn
            )
        };
        if ($exit != 0) {

            #copy($fn_lint, my $fn_tidy=File::Spec->catfile(cwd(), [File::Spec->splitpath($srce_fn)]->[2].'.tdy.yq'));
            return err("yaml linter exited with non-zero code: $exit, output was: $stdout. tdy.yq file: $yq_fn");
        }
        else {
            msg("file $yq_fn: yaml linter OK");
        }
    }


    #  Now move file back to inplace if that is what is needed
    #
    if ($self->{'inplace'}) {
        move($yq_fn, $srce_fn) ||
            return err("unable to move file $yq_fn => $srce_fn: $!");
        msg("file $srce_fn updated in-place");
    }
    elsif ((my $dest_opt_fn=$self->{'dest_fn'}) && !$self->{'dryrun'}) {
        $dest_opt_fn=File::Spec->rel2abs($dest_opt_fn);
        move($yq_fn, $dest_opt_fn) ||
            return err("unable to move file $yq_fn => $dest_opt_fn: $!");
    }
    elsif ($self->{'dryrun'}) {
        msg("file $dest_fn not saving to output file '$dest_opt_fn' as --dryrun option in effect");
    }


    #  Cleanup unless asked to preserve intermediate files
    #
    unless ($self->{'preserve'} || $self->{'dest_fn'}) {
        unlink($dest_fn) ||
            return err("unable to unlink $dest_fn, $!");
    }
    if ($self->{'preserve'}) {
        msg("file $srce_fn: preserving intermediate file ${dest_fn}");
    }


    #  Done
    #
    return \undef;

}


__END__

# Documentation in Markdown. Convert to POD using markpod from 
#
# https://github.com/aspeer/pl-markpod.git 

=begin markdown

# NAME
    
App::slstidy - module short description

# SYNOPSIS

module synopsis
```
```

# DESCRIPTION

App::slstidy script long description

# USAGE

module usage here
```
```
  
# AUTHOR

Andrew Speer andrew.speer@isolutions.com.au

# LICENSE and COPYRIGHT

This file is part of slstidy.

This software is copyright (c) 2023 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>

=end markdown


=head1 NAME

App::slstidy - module short description


=head1 SYNOPSIS

module synopsis
 



=head1 DESCRIPTION

App::slstidy script long description


=head1 USAGE

module usage here
 



=head1 AUTHOR

Andrew Speer andrew.speer@isolutions.com.au


=head1 LICENSE and COPYRIGHT

This file is part of slstidy.

This software is copyright (c) 2023 by Andrew Speer L<mailto:andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

L<http://dev.perl.org/licenses/>

=cut
