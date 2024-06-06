#!perl


#  Load
#
use strict;

use Test::More qw(no_plan);
BEGIN { use_ok( 'App::slstidy' ); }

use File::Temp qw(tempfile);
use FindBin qw($RealBin);
use Digest::MD5;
use File::Find qw(find);
use Data::Dumper;
use IO::File;
$Data::Dumper::Indent=1;


#  Get test files
#
my @test_fn;
my $wanted_sr=sub { push (@test_fn, $File::Find::name) if /\.sls$/ };
find($wanted_sr, $RealBin);
foreach my $test_fn (sort {$a cmp $b } @test_fn) {


    # Temp file to hanlde output
    #
    #my ($temp_fh, $temp_fn)=tempfile();
    my $dest_fn="${test_fn}.tst";
    my $slstidy_or=App::slstidy->new({
        srce_fn		=> $test_fn,
        dest_fn		=> $dest_fn,
        preserve	=> 1,
        nobackup	=> 1,
    });
    #diag("temp_fn, $temp_fn");
    ok($slstidy_or, 'request created');


    #  run handler which sends output to file
    #
    ok($slstidy_or->slstidy($test_fn));
    #seek($temp_fh,0,0);


    #  Get MD5 of file we just rendered
    #
    my $dest_fh=IO::File->new($dest_fn, O_RDONLY) ||
        die diag("unable to open file $dest_fn for read");
    binmode($dest_fh);
    my $md5_or=Digest::MD5->new();
    $md5_or->addfile($dest_fh);
    my $md5_tidy=$md5_or->hexdigest();


    #  Now look at reference file
    #
    my $dump_fn="${test_fn}.tdy.yq";
    #diag("dump_fn: $dump_fn");
    my $dump_fh=IO::File->new($dump_fn, O_RDONLY) ||
        die diag("unable to open file $dump_fn for read");
    ok($dump_fh, "loaded render dump file for $dump_fn");
    binmode($dump_fh);
    $md5_or->reset();
    $md5_or->addfile($dump_fh);
    my $md5_dump=$md5_or->hexdigest();
    #die diag("tidy $md5_tidy, dump $md5_dump");
    my $pass;
    if ($md5_tidy eq $md5_dump) {
        $pass++;
        pass("render $dump_fn");
    }
    else {
        diag("fail $dest_fn");
        seek($dest_fh,0,0);
        seek($dump_fh,0,0);
        my @diff;
        my $line;
        while (my $made=<$dest_fh>) {
            my $test=<$dump_fh>;
            $line++;
            unless ($made eq $test) {
                push @diff, "$line [gen]: $made", "$line [ref]: $test";
            }
        }
        if (@diff) {
            diag('  diff: - ', Dumper(\@diff));
            fail("render $test_fn");
        }
        else {
            pass("render $test_fn");
        }
    };


    #  Clean up
    #
    $dest_fh->close();
    $dump_fh->close();
    unlink($dest_fn) if $pass;
}

