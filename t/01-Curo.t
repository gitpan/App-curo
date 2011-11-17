use strict;
use warnings;
use Cwd;
use File::Temp qw/tempdir/;
use Test::More;
use Test::Database;
use File::Spec::Functions qw/catfile catdir/;
use Curo;

my $cwd;
BEGIN { $cwd = getcwd }

can_ok(
    'Curo', qw/
      new
      /
);

my @handles = Test::Database->handles(qw/ Pg SQLite /);    #Pg mysql /);

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
    }

    my $db = Curo->new(
        dir      => $tempdir,
        dsn      => $dsn,
        username => $user,
        password => $pass,
        init     => 1,
    );

    isa_ok $db , 'Curo';
    isa_ok $db->config, 'Curo::Config';
    is $db->dir, $tempdir, 'dir';

    $db = Curo->new( dir => $tempdir );
    isa_ok $db , 'Curo';
    isa_ok $db->config, 'Curo::Config';
    is $db->dir, $tempdir, 'dir';

    $db->insert_project(
        {
            title  => 'new p',
            email  => 'sdlkf',
            author => 'sdlkfj',
            name   => 'myproj'
        }
    );
}

done_testing();

# Force File::Temp to cleanup _after_ we have got out of its directory.
END {
    chdir $cwd;
}

