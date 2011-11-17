package App::curo::init; our $VERSION = '0.01_02';
use strict;
use warnings;
use File::Spec::Functions qw/rel2abs catdir catfile/;
use Term::Prompt;
use Curo;
use SQL::DBx::Deploy;
use App::curo::Util;

sub order { 2 }

sub opt_spec {
    return (
        [ "prompt|p",  "Prompt for configuration parameters" ],
        [ "hub",       "Initialize a database 'hub'" ],
        [ 'debug|d=s', 'Enable debugging output' ],
    );
}

sub arg_spec {
    return ( [ "directory=s", "location of the database or hub", ], );
}

sub run {
    my ( $self, $opt ) = @_;

    add_debug( $opt->debug );

    $opt->{directory} ||= '.' if $opt->hub;
    $opt->{directory} ||= '.curo';

    my $config = catfile( $opt->{directory}, 'config' );
    die "fatal: config exists: $config\n" if -e $config;

    if ( -e $opt->{directory} ) {
        die "fatal: not a directory: $opt->{directory}\n"
          unless -d $opt->{directory};
    }

    my ( $dsn, $dbuser, $dbpass );

    if ( $opt->prompt ) {
        $dsn = prompt( 'e', 'Database DSN: ', '', '', qr/dbi:.*/ );
        unless ( $dsn =~ /^dbi:SQLite:/ ) {
            $dbuser = prompt( 'x', 'Database User: ',     '', '' );
            $dbpass = prompt( 'p', 'Database Password: ', '', '' );
            print "\n";
        }
    }

    my $db = Curo->new(
        dir      => $opt->directory,
        dsn      => $dsn,
        username => $dbuser,
        password => $dbpass,
        init     => 1,
    );

    if ( $opt->hub ) {
        chdir $opt->directory || die "chdir $opt->{directory}: $!";
        symlink( '.', '.curo' ) || die "symlink: $!";
    }

    print $opt->hub ? 'Hub ' : '';
    printf( "Database initialized (%s) in %s/\n",
        $db->last_deploy_id('Curo'), $db->dir );
    return;
}

1;
__END__

=head1 NAME

App::curo::init - Setup a new database or hub

=head1 SYNOPSIS

  curo init

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
