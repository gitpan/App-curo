package App::curo::Cmd::pull; our $VERSION = '0.0.2';
use strict;
use warnings;
use App::curo::Util;
use Path::Class;

sub run {
    my $opts   = shift;
    my $config = find_conf($opts);
    my $db     = find_db($opts);

    check_project( $opts->{project} ) if $opts->{project};
    check_hub($opts);

    $opts->{email}  ||= $config->{user}->{email};
    $opts->{author} ||= $config->{user}->{name};

    die "fatal: project already exists locally: $opts->{thread}\n"
      if $db->path2project_id( $opts->{thread} );

    my $client = $db->client;

    $client->on_connect(
        sub {
            print "connected to: $opts->{location}\n";
            $client->cv->send(1);
        }
    );

    $client->connect( $opts->{location} )
      || die "$opts->{location}\nfatal: could not connect\n";

    if ( -t STDOUT and !is_debug ) {

        my $show_update = sub {
            line_print(
                sprintf(
                    '%s: received: %d',
                    $opts->{thread}, $client->recv_updates
                )
            );
        };

        $client->on_recv_update($show_update);
    }

    $client->pull_project($opts) || die "fatal: pull failed\n";

    printf( "%s: received: %d\n", $opts->{thread}, $client->recv_updates );

    # TODO move this into Curo::Sync::Client or Curo
    if ( my $hub = $db->location2hub( $opts->{location} ) ) {
        my $pid = $db->path2project_id( $opts->{thread} );

        $db->insert_hub_thread(
            {
                hub_id    => $hub->id,
                thread_id => $pid,
            }
        );

        print "tracking link created\n";
    }

    $client->disconnect;

}

1;
__END__

=head1 NAME

App::curo::Cmd::pull - Fetch and merge hub threads

=head1 DESCRIPTION

See L<curo>(1) for details.

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

=cut
