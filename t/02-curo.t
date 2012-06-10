use strict;
use warnings;
use File::chdir;
use File::Temp;
use IO::Capture::Stdout;
use OptArgs qw/dispatch/;
use Path::Class;
use Test::More;
use Test::Database;

my $capture  = IO::Capture::Stdout->new();
my $dbnewdir = File::Temp->newdir;           # will cleanup on undef
my $dbdir    = dir($dbnewdir);
my $dotcuro;

sub in_tmp (&) {
    my $sub = shift;
    $dbnewdir = File::Temp->newdir;          # will cleanup on undef
    $dbdir    = dir($dbnewdir);
    local $CWD = $dbdir;
    $sub->();
}

sub db_cmd {
    my $args = shift;
    my $qr   = shift;
    $capture->start();
    dispatch( qw/ run App::curo::Cmd /, @$args );
    $capture->stop;

    like join( '', $capture->read ), $qr, "@$args";
}

in_tmp {
    $dotcuro = $dbdir->subdir('.curo');
    ok !-d $dotcuro, "no $dotcuro";
    db_cmd( [qw/init/], qr/database initialised/i );
    ok -d $dotcuro, $dotcuro;
    ok -f $dotcuro->file('config'),      $dotcuro->file('config');
    ok -f $dotcuro->file('curo.sqlite'), $dotcuro->file('curo.sqlite');
};

in_tmp {
    $dotcuro = $dbdir->subdir( 'other', '.curo' );
    ok !-d $dotcuro, "no $dotcuro";
    db_cmd( [qw/init other/], qr/database initialised/i );
    ok -d $dotcuro, $dotcuro;
    ok -f $dotcuro->file('config'),      $dotcuro->file('config');
    ok -f $dotcuro->file('curo.sqlite'), $dotcuro->file('curo.sqlite');
};

in_tmp {
    $dotcuro = $dbdir;
    db_cmd( [qw/init --hub/], qr/hub database initialised/i );
    ok -f $dotcuro->file('config'),      $dotcuro->file('config');
    ok -f $dotcuro->file('curo.sqlite'), $dotcuro->file('curo.sqlite');
};

in_tmp {
    $dotcuro = $dbdir->subdir('hub');
    ok !-d $dotcuro, "no $dotcuro";
    db_cmd( [qw/init --hub hub/], qr/hub database initialised/i );
    ok -d $dotcuro, $dotcuro;
    ok -f $dotcuro->file('config'),      $dotcuro->file('config');
    ok -f $dotcuro->file('curo.sqlite'), $dotcuro->file('curo.sqlite');
};

done_testing();
