# App::slstidy - check module loading and create testing directory

use Test::More tests => 3;

BEGIN { use_ok( 'App::slstidy' ) }
require_ok('App::slstidy');
my $object = App::slstidy->new ();
isa_ok ($object, 'App::slstidy');
