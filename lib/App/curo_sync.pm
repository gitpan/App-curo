package App::curo_sync; our $VERSION = '0.0.2';
use strict;
use warnings;
use App::curo::Config;
use Curo;
use Log::Any qw/$log/;
use Log::Any::Adapter;
use OptArgs;
use Path::Class;
use Try::Tiny;

opt debug => (
    isa     => 'Str',
    comment => 'turn on debugging',
    alias   => 'd',
);

arg directory => (
    isa      => 'Str',
    comment  => 'location of curo repository',
    required => 1,
);

sub run {
    my $opts = shift;

    if ( $opts->{debug} ) {
        Log::Any::Adapter->set(
            {
                category => $opts->{debug} eq 'all'
                ? qr/.*/
                : qr/$opts->{debug}/
            },
            'Dispatch',
            outputs => [
                [
                    'Screen',
                    name      => 'screen',
                    min_level => 'debug',
                    stderr    => 1,
                    newline   => 1,
                ],
            ]
        );
    }
    else {
        Log::Any::Adapter->set(
            'Dispatch',
            outputs => [
                [
                    'Screen',
                    name      => 'screen',
                    min_level => 'error',
                    stderr    => 1,
                    newline   => 1,
                ],
            ]
        );
    }

    my $db = try {
        my $config =
          App::curo::Config->read( dir( $opts->{directory} )->file('config') );

        my $dsn =
          'dbi:SQLite:dbname=' . dir( $opts->{directory} )->file('curo.sqlite');

        return Curo->new(
            dsn => $config->{_}->{dsn} || $dsn,
            username => $config->{_}->{username},
            password => $config->{_}->{password},
        );
    }
    catch {
        $log->error($_);
        print
          qq![{"_":"error","msg":"invalid repository: $opts->{directory}"}]\n!;
        exit 1;
    };

    $db->sqlite_create_function_debug if $opts->{debug};

    my $server = $db->server;

    $server->accept(
        stdin  => IO::Handle->new_from_fd( fileno(STDIN),  'r' ),
        stdout => IO::Handle->new_from_fd( fileno(STDOUT), 'w' ),
    );
}

1;
__END__

=head1 NAME

App::curo_sync - Curo synchronisation server

=head1 DESCRIPTION

See L<curo-sync>(1) for details.

=head1 SEE ALSO

L<curo>(1)

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

=cut
