use strict;
use warnings;
use Test::More;
use Test::Database;
use File::Spec::Functions qw/catfile catdir/;
use File::Temp qw/tempdir/;
use Sys::Cmd qw/run spawn/;
use Cwd qw/getcwd/;

{
    no warnings 'once';
    @Test::Script::Run::BINDIRS = ('t');
}

# Now check app-dispatcher

# save some typing
my $app = 'curo';

#my ( $return, $stdout, $stderr );
#
#( $return, $stdout, $stderr ) = run_script($app);
#like last_script_stderr, qr/^usage:/, 'usage';
#
my $cwd;
BEGIN { $cwd = getcwd }

my @handles = Test::Database->handles(qw/ Pg SQLite /);

if ( !@handles ) {
    plan skip_all => "No database handles to test with";
}

my $tempdir;
foreach my $handle (@handles) {
    chdir $cwd || die "chdir: $!";
    $tempdir = tempdir( CLEANUP => 1 );
    chdir $tempdir || die "chdir: $!";
    diag $handle->dbd . ' in ' . $tempdir;

    if ( $handle->dbd eq 'SQLite' ) {
        $handle->driver->drop_database( $handle->name );
        $handle->driver->drop_database( $handle->name . '.seq' );
    }

    my ( $dsn, $user, $pass ) = $handle->connection_info;

    if ( $handle->dbd eq 'Pg' ) {
        my $dbh = $handle->dbh;
        $dbh->do("SET client_min_messages = WARNING;");
        my $list = $dbh->selectall_arrayref(
            "SELECT 'DROP TABLE ' || n.nspname || '.' ||
c.relname || ' CASCADE;' FROM pg_catalog.pg_class AS c LEFT JOIN
pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace WHERE relkind =
'r' AND n.nspname NOT IN ('pg_catalog', 'pg_toast') AND
pg_catalog.pg_table_is_visible(c.oid)"
        );

        foreach my $s (@$list) {
            $dbh->do( $s->[0] );
        }

        $list = $dbh->selectall_arrayref(
            "SELECT 'DROP SEQUENCE ' || n.nspname || '.' ||
c.relname || ' CASCADE;' FROM pg_catalog.pg_class AS c LEFT JOIN
pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace WHERE relkind =
'S' AND n.nspname NOT IN ('pg_catalog', 'pg_toast') AND
pg_catalog.pg_table_is_visible(c.oid)"
        );

        foreach my $s (@$list) {
            $dbh->do( $s->[0] );
        }

        $list = $dbh->selectall_arrayref(
            "SELECT 'DROP FUNCTION ' || ns.nspname || '.' || proname || '(' ||
oidvectortypes(proargtypes) || ');' FROM pg_proc INNER JOIN
pg_namespace ns ON (pg_proc.pronamespace = ns.oid) WHERE ns.nspname =
'public'  order by proname;"
        );

        foreach my $s (@$list) {
            $dbh->do( $s->[0] );
        }

        my $curo = spawn(qw/curo init -p/);
        $curo->stdin->print( $dsn . "\n" );
        $curo->stdin->print( $user . "\n" );
        $curo->stdin->print( $pass . "\n" );
        like $curo->stdout->getline,
          qr/Database DSN:.*Database User:.*Database Password:/,
          'DSN details';
        like $curo->stdout->getline, qr/Database initialized/, 'created';

    }
    elsif ( $handle->dbd eq 'SQLite' ) {
        my $o = run(qw/curo init/);
        like $o, qr/Database initialized/, 'created';
    }

    my $o;

    $o = run(qw/curo new project testp Title -c x/);
    like $o, qr/^New project: testp/, 'new project';

    $o = run(qw/curo status/);
    like $o, qr/\Wtestp\s+Title\W/, 'status';

    $o = run(qw/curo update testp --comment comment1/);
    like $o, qr/^Updated project: testp/, 'updated project';

    $o = run(qw/curo log testp/);
    like $o, qr/comment1/, 'update logged';

}

done_testing();

# Force File::Temp to cleanup _after_ we have got out of its directory.
END {
    chdir $cwd;
}

