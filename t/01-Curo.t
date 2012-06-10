use strict;
use warnings;
use Curo;
use File::chdir;
use File::Temp;
use Test::More;
use Test::Database;
use Path::Class;

my @handles = Test::Database->handles(qw/ Pg SQLite /);

foreach my $handle (@handles) {
    my $tempdir = File::Temp->newdir;
    local $CWD = $tempdir;

    diag $handle->dbd . ' in ' . $CWD;

    my ( $dsn, $user, $pass ) = $handle->connection_info;

    $dsn = 'dbi:SQLite:dbname=curo.sqlite' if $handle->dbd eq 'SQLite';

    my $db = Curo->new(
        dsn      => $dsn,
        username => $user,
        password => $pass,
    );

    isa_ok $db , 'Curo';

    ok $db->upgrade, 'initialization';

    # insert a parent
    ok $db->insert_project(
        {
            title  => 'new p',
            email  => 'sdlkf',
            author => 'sdlkfj',
            name   => 'p',
            phase  => 'run',
        }
      ),
      'insert p';

    is $db->one_and_only_project_path, 'p', 'insert_project';

    my $pid = $db->path2project_id('p');
    ok $pid, 'path2project_id' . $pid;
    is $db->id2thread_type($pid), 'project', 'id2thread_type';

    # insert a child
    ok $db->insert_project(
        {
            title             => 'new p',
            email             => 'sdlkf',
            author            => 'sdlkfj',
            name              => '2',
            parent_project_id => $pid,
            phase             => 'run',

        }
      ),
      'insert p/2';

    my $cid = $db->path2project_id('p/2');
    ok $cid, 'child at right path';
    is $db->id2thread_type($cid), 'project', 'id2thread_type';

    # remove child and check
    ok $db->drop_project($cid), 'drop child';
    ok !$db->id2thread_type($cid), 'no id2thread_type';

    # but parent still there
    ok $pid, 'path2project_id' . $pid;
    is $db->id2thread_type($pid), 'project', 'id2thread_type';

    # insert a new child at same path
    ok $db->insert_project(
        {
            title             => 'new p',
            email             => 'sdlkf',
            author            => 'sdlkfj',
            name              => '2',
            parent_project_id => $pid,
            phase             => 'run',

        }
      ),
      'insert p/2 again';

    $cid = $db->path2project_id('p/2');
    ok $cid, 'path2project_id ' . $cid;

    ok $db->drop_project($pid), 'drop parent project';
    ok !$db->id2thread_type($cid), 'no child';
    ok !$db->id2thread_type($pid), 'no parent';
}

done_testing();

