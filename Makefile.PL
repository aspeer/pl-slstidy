use 5.006;
use strict;
use ExtUtils::MakeMaker;
my $mm_ver=$ExtUtils::MakeMaker::VERSION;
if ($mm_ver=~/_/) {    # dev version
    $mm_ver=eval $mm_ver;
    die $@ if $@;
}
my %WriteMakefile=(
    NAME          => 'slstidy',
    VERSION_FROM  => 'bin/slstidy.pl',
    ABSTRACT_FROM => 'bin/slstidy.pl',
    EXE_FILES     => do {
        [
  'bin/slstidy.pl'
]
    },
    LICENSE          => 'perl',
    AUTHOR           => 'Andrew Speer <andrew.speer@isolutions.com.au>',
    MIN_PERL_VERSION => '5.006',
    PREREQ_PM        => {
        'Test::Simple'  => 0.44,
        'Capture::Tiny' => 0,
        'Digest::MD5'   => 0,
        'File::Temp'    => 0,
        'Test::More'    => 0
    },
    META_MERGE => {
        'meta-spec' => {
            version => 2
        },
        resources => {
            homepage   => 'https://github.com/aspeer/pl-slstidy',
            repository => {
                type => 'git',
                url  => 'https://github.com/aspeer/pl-slstidy.git',
                web  => 'https://github.com/aspeer/pl-slstidy'
            }
        }
    },
    PM_FILTER => $ENV{'PM_DEBUG'} || do {
        use IO::File;
        my $fn='.pm_filter.pf';
        my $fh=IO::File->new($fn, O_WRONLY | O_CREAT | O_TRUNC) ||
            die("unable to write filter file '$fn', $!");
        print $fh 's/^(\s*)debug\\(/${1}0 && debug\\(/m; print';
        $fh->close();
        my $pm_filter="\$(PERL) -nl $fn";
    },
    'depend' => {
        Makefile => '$(VERSION_FROM)',
    },
    'dist' => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => '.gz'
    },
);
my %MM_Compat=(
    '5.46'   => [q(PM_FILTER)],
    '6.31'   => [q(LICENSE)],
    '6.46'   => [q(META_MERGE)],
    '6.48'   => [q(MIN_PERL_VERSION)],
    '6.52'   => [q(CONFIGURE_REQUIRES)],
    '6.5503' => [q(BUILD_REQUIRES)],
    '6.64'   => [q(TEST_REQUIRES)],
);
while (my ($mm_ver_test, $ar)=each %MM_Compat) {
    if (version->parse($mm_ver) < version->parse($mm_ver_test)) {
        delete @WriteMakefile{@{$ar}};
    }
}
WriteMakefile(%WriteMakefile);
package MY;


sub post_initialize {

    #  Add license file, other support files here
    #
    my $mm_or=shift();
    $mm_or->{'PM'}{'LICENSE'}='$(INST_LIBDIR)/$(BASEEXT)/LICENSE' if -e 'LICENSE';
    $mm_or->SUPER::post_initialize;
}
