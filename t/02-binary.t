use strict;
use warnings;
use Test::More tests => 2;
use File::Which qw(which);
our @Binary=qw(
    yq yamllint
);
foreach my $binary (@Binary) {
    # Check for the presence of the required binary
    unless (which($binary)) {
        fail("Required binary '$binary' not found in PATH");
    } 
    else {
        pass("Required binary: '$binary' is present");
    }
}
