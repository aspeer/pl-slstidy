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
use vars qw($VERSION);
use warnings;


#  Support modules
#
use App::slstidy::Util qw(msg debug err Dumper);
use App::slstidy::Constant;


#  External modules
#
use IO::File;
use File::Find;
use File::Copy qw(copy move);
use Cwd qw(cwd);
use Capture::Tiny qw(capture);
use File::Temp qw(tempfile);


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
    return bless(ref($param)?$param:\$param, $class);

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
        my @dn=$self->{'action_ar'} ? 
            @{$self->{'action_ar'}} : (cwd());
            
        
        #  Process permitted file extensions
        #
        my @fn_ext=$self->{'file_extension_ar'} ?
            @{$self->{'file_extension_ar'}} :
            ($SLS_FILE_EXTENSION);
        @fn_ext=map { split(/,/, $_) } @fn_ext;
        

        #  Filter subroutine to get just files we want
        #
        my @fn;
        my $find_sr=sub {
            my $fn=shift();
            return unless (grep { $fn=~/\.${_}$/ } @fn_ext);
            push @fn, $fn;
        };
        

        #  Run filter across all files in target directory
        #
        find(sub { $find_sr->($File::Find::name)} , @dn);
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
    my ($self, $fn_srce)=@_;
    msg("file $fn_srce: processing start");
    
    
    #  Dest file name and open handle
    #
    my ($fn_dest, $fh_dest);
    if ($self->{'dryrun'}) {
        ($fh_dest, $fn_dest)=tempfile();
    }
    else {
        $fn_dest=$self->{'dest_fn'} || "${fn_srce}.tdy";
        $fh_dest=IO::File->new($fn_dest, O_CREAT|O_TRUNC|O_WRONLY) ||
            return err("error opening $fn_dest for write, $!");
    }
    #my ($fh_dest, $fn_dest)=tempfile(UNLINK => 1);
    
    
    #  Make backup
    #
    unless ($self->{'nobackup'} || $self->{'dryrun'}) {
        copy($fn_srce, "${fn_srce}.bak") ||
            return err("unable to make backup copy of $fn_srce, $!")
    }


    #  Source file handle
    #
    my $fh_srce=IO::File->new($fn_srce, O_RDONLY) ||
        return err("unable to open $fn_srce for reading: $!");
        

    #  Start reading line by line, add document start if not present on first line
    #
    my $doc_start_seen;
    my $doc_end_seen;
    my $nl_count=0;
    my $in_jinja=0;
    my $line_no=0;
    my @line;
    while (my $line=<$fh_srce>) {
    
    
        #  Keep track of what line we are on
        #
        $line_no++;
        chomp($line);
        
    
        #  Start tidy up. Print doc start header if not seen
        #
        if ($line=~/^\-\-\-/) {
            $doc_start_seen++;
        }
        if (!$doc_start_seen && !(($line =~ /^\#/) || ($line=~/^\%/))) {
            print $fh_dest '---', $/;
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
            #$line.=$/;
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
        $line=~s/^\s*\{\%/#  \{\%/;
        $line=~s/^\s*\%\}/#  \%\}/;
        
        
        #  Keep track if in or out of jinja block and comment out if in block
        #
        if ($in_jinja) {
            unless ($line=~/^#/) {
                $line="#  ${line}";
            }
        }
        $in_jinja+=($line=~/\{\%/);
        $in_jinja+=($line=~/\%\}/);
        $in_jinja%=2;
        #print "in jinja: $in_jinja, line: $line_no, line:$line\n";
        
        
        #  SLS => SLSPATH in values. Plus keys if applicable
        #
        $line=~s/([:-].*?)\{\{\s*sls\s*\}\}/$1\{\{ slspath \}\}/i;
        #$line=~s/^.*\'?(.*?)\{\{\s*salt\.random\.shadow_hash\(\)\s*\}\}(.*?)(?=[-:])/\'\{\{ sls \}\}.$1\{\{ salt.random.shadow_hash() \}\}\'/;
        
        
        
        #\'{{ sls }}.$1{{ salt.random.shadow_hash() }}\'/;
            
        #  Space in {{ varname }}
        $line=~s/\{\{\s*/{{ /ig;
        $line=~s/\s*\}\}/ }}/ig;
        #$line=~s/(?<=:)\{\{\s*sls\s*\}\}/{{ slspath }}/gi;
        #$line=~s/\{\{\s*sls\s*\}\}/{{ slspath }}/gi;
        
        
        #  Quote keys using {{
        #
        if ($line=~/^(.*?)\{\{(.*)\}\}\s*:\s*(.*)/) {
            $line="${1}'{{$2}}': $3";
        }


        #  Quote values with {{
        #
        #if ($line=~.*/) {
        #    $line="'{{$1}}': $2";
        #}
        #$line=~s/({{)(?!.*:)/'$1/g;
        #$line=~s/(}})(?!.*:)/$1'/g;
        #$line=~s/'{2}/'/g;
        
        #  Clumsy regxp to quote lines with jinja variables {{. First check if value is quoted already - if so leave it
        #
        #print "line: $line\n";
        if ($line=~/^(.*?)[:-]\s+\S/) {
            unless ($line=~/^(.*?)[:-]\s+['""](.*)['""]$/) {
            
                #  Does it contain a single quote somewhere in the value already ? If so double quote it
                #
                if ($line=~/^.*?[:-].*'/) {
                    #print "hit 1\n";
                    #$line=~s/^(.*?)([:-])\s+(.*?\{\{.*\}\}.*)$/$1$2 "$3"/g;
                    unless ($line=~s/^(.*?)(?!-)([:-])\s+(.*?\{\{.*\}\}.*)$/$1$2 "$3"/g) { 
                        $line=~s/^(.*?)([:-])\s+(.*?\{\{.*\}\}.*)$/$1$2 "$3"/g }
                    $line=~s/"{2,}/"/g;
                }
                #  And vica vesra if contains a double quote
                #
                #elsif ($line=~/^.*?[:-].*"/) {
                #    $line=~s/^(.*?)([:-])\s+(.*?\{\{.*\}\}.*)$/$1$2 '$3'/g;
                #    $line=~s/'{2,}/'/g;
                #}
                #  Otherwise single quote it
                #
                else {
                    #print "hit 2\n";
                    #$line=~s/^(.*?)([:-])\s+(.*?\{\{.*\}\}.*)$/$1$2 '$3'/g;
                    unless ($line=~s/^(.*?)(?!-)([:-])\s+(.*?\{\{.*\}\}.*)$/$1$2 '$3'/g) {
                        $line=~s/^(.*?)([:-])\s+(.*?\{\{.*\}\}.*)$/$1$2 '$3'/g
                    }
                    $line=~s/'{2,}/'/g;
                }
                
            }
        }
        #print "line: $line\n";
            

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
        #print $fh_dest $line, $/;
        push @line, $line;
    }
    
    #  Get rid of trailing lines at end of file
    #
    for (my $line_ix=$#line; $line_ix > 0; $line_ix--) {
        last if ($line[$line_ix]!~/^\s*$/);
        splice @line, ($line_ix);
    }
    map { print $fh_dest $_, $/ } @line;
    
    
    #  Add document end footer if not seen in document. REMOVED - not prited by YQ anyway
    #
    #unless ($doc_end_seen) {
    #    print $fh_dest '...', $/;
    #}
    
    
    #  Close file handles
    #
    $fh_dest->close();
    $fh_srce->close();
    
    
    #  Now run through pretty print
    #
    #my ($fh_lint, $fn_lint)=tempfile(UNLINK=>1);
    {
        my ($stdout, $stderr, $exit)=capture{ system(
            'yq',
            #'-P', # Doesn't work - doesn't quote scalar = character as value for example
            $fn_dest
        )};
        if ($exit != 0) {
            #copy($fn_dest, my $fn_tidy=File::Spec->catfile(cwd(), [File::Spec->splitpath($fn_srce)]->[2].'.tdy'));
            return err("yq command exited with non-zero code: $exit, output was: $stderr, tdy file: $fn_dest");
        }
        else {
            msg("file $fn_dest: yq format OK")
        }
        
        #  And save
        #
        my $fh_yq=IO::File->new("${fn_dest}.yq", O_CREAT|O_TRUNC|O_WRONLY) ||
            return err("unable to open file ${fn_dest}.yq for output, $!");
        print $fh_yq $stdout;
        $fh_yq->close();
        
    }
    
    
    #  And linter
    #
    {
        my ($stdout, $stderr, $exit)=capture{ system(
            'yamllint',
            "${fn_dest}.yq"
        )};
        if ($exit != 0) {
            #copy($fn_lint, my $fn_tidy=File::Spec->catfile(cwd(), [File::Spec->splitpath($fn_srce)]->[2].'.tdy.yq'));
            return err("yaml linter exited with non-zero code: $exit, output was: $stdout. tdy.yq file: ${fn_dest}.yq");
        }
        else {
            msg("file $fn_dest.yq: yaml linter OK");
        }
    }
    
    
    #  Now move file back to inplace if that is what is needed
    #
    if ($self->{'inplace'}) {
        move("${fn_dest}.yq", $fn_srce) ||
            return err("unable to move file ${fn_dest}.yq => $fn_srce: $!");	
    }
    elsif ($self->{'dest_fn'}) {
        move("${fn_dest}.yq", $fn_dest) ||
            return err("unable to move file ${fn_dest}.yq => $fn_dest: $!");	
    }
    
    
    #  Cleanup unless asked to preserve intermediate files
    #
    unless ($self->{'preserve'}) {
        unlink($fn_dest) ||
            return err("unable to unlink $fn_dest, $!"); 
    }
    else {
        msg("file $fn_srce: preserving intermediate file $fn_dest");
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
