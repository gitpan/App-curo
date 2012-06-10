package App::curo::Cmd::push; our $VERSION = '0.0.2';
use strict;
use warnings;
use App::curo::Util;
use Path::Class;

sub run {
    my $opts   = shift;
    my $config = find_conf($opts);
    my $db     = find_db($opts);

    $opts->{email}  ||= $config->{user}->{email};
    $opts->{author} ||= $config->{user}->{name};

    my $name = $opts->{thread};
    my $type = check_thread($opts);
    check_hub($opts);

    if ( $type eq 'project' ) {
    }
    else {
        not_implemented('push based on ID');
    }

    my $client = $db->client;

    $client->on_connect(
        sub {
            print "connected to: $opts->{location}\n";
            $client->cv->send(1);
        }
    );

    $client->connect( $opts->{location} )
      || die "$opts->{location}\nfatal: could not connect\n";

    if ( my $hub = $db->location2hub( $opts->{location} ) ) {
        $db->insert_hub_thread(
            {
                hub_id    => $hub->id,
                thread_id => $opts->{id},
            }
        );
    }

    if ( -t STDOUT and !is_debug ) {

        my $show_update = sub {
            line_print(
                sprintf( '%s %s: sent: %d',
                    $type, $name, $client->sent_updates )
            );
        };

        $client->on_send_update($show_update);
    }

    if ( $type eq 'project' ) {
        $client->push_project($opts) || die "fatal: push failed\n";
    }
    else {
    }

    printf( "%s %s: sent: %d\n", $type, $name, $client->sent_updates );

    $client->disconnect;

}

1;
__END__

=head1 NAME

App::curo::Cmd::push - Share threads with a hub

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
