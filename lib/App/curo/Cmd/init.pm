package App::curo::Cmd::init; our $VERSION = '0.0.2';
use strict;
use warnings;
use File::Temp qw/tempdir/;
use File::chdir;
use Term::Prompt;
use Curo;
use App::curo::Config;
use OptArgs qw/:default dispatch/;
use Path::Class;
use App::curo::Util;

sub run {
    my $opts = shift;

    add_debug( $opts->{debug} );

    my $dir = dir( $opts->{directory} || dir() )->absolute;
    my $conffile;

    if ( $opts->{hub} ) {
        die "fatal: --todo and --hub conflict\n" if $opts->{todo};

        if ( -e $dir ) {
            die "fatal: not a directory: $dir\n" unless -d $dir;
        }
        else {
            mkdir($dir) || die "fatal: mkdir $dir: $!\n";
        }

        $conffile = $dir->file('config');
        die "fatal: config exists: $conffile\n" if -e $conffile;
    }
    else {
        mkdir $dir;    # don't care if this already exists

        $dir = $dir->subdir('.curo');
        die "fatal: directory exists: $dir\n" if -e $dir;

        $dir = dir( tempdir( DIR => $dir->parent, CLEANUP => 1 ) );
        $conffile = $dir->file('config');
    }

    if ( $opts->{prompt} ) {
        $opts->{dsn} ||= prompt( 'e', 'Database DSN: ', '', '', qr/dbi:.*/ );
        unless ( $opts->{dsn} =~ /^dbi:SQLite:/ ) {
            $opts->{username} ||= prompt( 'x', 'Database User: ',     '', '' );
            $opts->{password} ||= prompt( 'p', 'Database Password: ', '', '' );
            print "\n";
        }
    }

    my $config = App::curo::Config->new;
    $config->{_}->{dsn}      = $opts->{dsn}      || '';
    $config->{_}->{username} = $opts->{username} || '';
    $config->{_}->{password} = $opts->{password} || '';
    $config->{_}->{hub}          = $opts->{hub} ? 1 : 0;
    $config->{alias}->{projects} = 'list projects';
    $config->{alias}->{issues}   = 'list issues';
    $config->{alias}->{tasks}    = 'list tasks';
    $config->{alias}->{hubs}     = 'list hubs';
    $config->{alias}->{links}    = 'list links';
    $config->write($conffile);

    my $dsn = $config->{_}->{dsn}
      || 'dbi:SQLite:dbname=' . $dir->file('curo.sqlite');

    my $db = Curo->new(
        dsn      => $dsn,
        username => $config->{_}->{username},
        password => $config->{_}->{password},
    );

    $db->sqlite_create_function_debug if $opts->{debug};
    $db->upgrade;

    if ( $opts->{hub} ) {

        # this is just for development so I can chdir and look around
        symlink( $dir, $dir->file('.curo') );
    }
    else {
        my $newdir = $dir->parent->subdir('.curo');
        rename( $dir, $newdir ) || die "fatal: rename $dir $newdir: $!\n";
        $dir = $newdir;
    }

    print $opts->{hub} ? 'Hub ' : '';
    printf( "Database initialised (v%s) in %s/\n", $db->db_version, $dir );

    if ( $opts->{todo} ) {
        local $CWD = $dir;
        dispatch(
            qw/run App::curo::Cmd new project todo /,
            'The default to-do list',
            '--comment',
            'Created by init --todo.',
            '-d',
            $opts->{debug} || '',
        );
    }

    return;
}

1;
__END__

=head1 NAME

App::curo::Cmd::init - Setup a new repository

=head1 DESCRIPTION

See L<curo>(1) for details.

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

=cut
