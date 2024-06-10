
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