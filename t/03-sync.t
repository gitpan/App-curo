use strict;
use warnings;
use Curo;
use File::chdir;
use File::Temp;
use IO::Capture::Stdout;
use OptArgs qw/dispatch/;
use Path::Class;
use Test::More;
use Test::Database;

#use App::curo::Util qw/add_debug/;
#add_debug('all');

my $capture = IO::Capture::Stdout->new();

my $dbnewdir = File::Temp->newdir;    # will cleanup on undef
my $dbdir    = dir($dbnewdir);

my $hubnewdir = File::Temp->newdir;    # will cleanup on undef
my $hubdir    = dir($hubnewdir);

sub db_cmd {
    local $CWD = $dbdir;
    $capture->start();
    dispatch( qw/run App::curo::Cmd/, @_ );
    $capture->stop;
    $capture->read;
}

sub hub_cmd {
    local $CWD = $hubdir;
    $capture->start();
    dispatch( qw/run App::curo::Cmd/, @_ );
    $capture->stop();
    $capture->read;
}

db_cmd( qw/init -t/, $dbdir );
hub_cmd( qw/init --hub/, $hubdir );

my $db = Curo->new(
    dsn => 'dbi:SQLite:dbname=' . $dbdir->subdir('.curo')->file('curo.sqlite'),
    schema => 'Curo::Schema',
);

my $hub = Curo->new(
    dsn    => 'dbi:SQLite:dbname=' . $hubdir->file('curo.sqlite'),
    schema => 'Curo::Schema',
);

sub compare_projects {
    is_deeply [ $hub->arrayref_project_list( { phase => ['run'] } ) ],
      [ $db->arrayref_project_list( { phase => ['run'] } ) ],
      'db/hub match';
}

ok $db->insert_hub(
    {
        alias    => 'upstream',
        location => $hubdir,
    }
  ),
  'insert hub';

is_deeply $db->arrayref_hub_list, [ 2, 'upstream', $hubdir, 0 ], 'list hubs';

my $client = $db->client;
ok $client->connect($hubdir), 'connect';
my $id  = $db->path2project_id('todo');
my $ref = {
    id     => $id,
    author => 'test',
    email  => 'test@email.com',
};
ok $client->push_project($ref), 'pushed';
compare_projects();

ok $client->sync_project($ref), 'sync';
compare_projects();

db_cmd(qw/update todo --comment nocomment/);
ok $client->sync_project($ref), 'sync single update';

ok $client->disconnect, 'disconnect';

done_testing();
