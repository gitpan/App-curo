use strict;
use warnings;
use Cwd;
use File::Temp qw/tempdir/;
use Test::More;
use Test::Database;
use File::Spec::Functions qw/catfile catdir/;
use Curo;
use Curo::Sync;

my $cwd;
BEGIN { $cwd = getcwd }

my $tempdir;
chdir $cwd || die "chdir: $!";
$tempdir = tempdir( CLEANUP => 1 );
chdir $tempdir || die "chdir: $!";
diag $tempdir;

my $hub = Curo->new(
    dir  => 'hub',
    init => 1,
    hub  => 1,
);

my $db = Curo->new(
    dir  => '.curo',
    init => 1,
);

isa_ok $db, 'Curo';

$db->insert_project(
    {
        title  => 'My project',
        email  => 'sdlkf',
        author => 'sdlkfj',
        name   => 'p'
    }
);

$db->insert_hub(
    {
        name     => 'upstream',
        location => $hub->dir,
    }
);

is_deeply $db->arrayref_hub_list, [ [ 'upstream', $hub->dir, '' ] ],
  'list hubs';

$db->connect( location => $hub->dir );
is $db->push_project( 'p', 'p' ), 2, 'pushed 2';

is_deeply [ $hub->arrayref_project_list ], [ $db->arrayref_project_list ],
  'db/hub match';

is $db->push_project( 'p', 'p' ), 0, 'pushed 0';

my @projects;
$db->txn(
    sub {
        for ( 1 .. 10 ) {
            $db->insert_project(
                {
                    title  => 'My project ' . $_,
                    email  => 'sdlkf',
                    author => 'sdlkfj',
                    name   => 'p' . $_,
                    parent => 'p',
                }
            );
            push( @projects, 'p' . $_ );
        }
    }
);
ok 1, 'insert 10';

is $db->push_project( 'p', 'p' ), 20, 'pushed 20';

is_deeply [ $hub->arrayref_project_list ], [ $db->arrayref_project_list ],
  'db/hub match';

done_testing();

# Force File::Temp to cleanup _after_ we have got out of its directory.
END {
    chdir $cwd;
}

