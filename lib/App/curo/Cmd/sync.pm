package App::curo::Cmd::sync; our $VERSION = '0.0.2';
use strict;
use warnings;
use App::curo::Util;
use Path::Class;

# usage: curo [options] sync [ID] [LOCATION]
#
#     --debug,  -d     define modules to debug
#     --help,   -h     print this help message and exit
#
#     ID               the ID or project path to synchronise
#     LOCATION         hub repository address or alias

my $client;
my $type;
my $name;

sub connect_hub {
    my $location = shift;

    $client->on_connect(
        sub {
            print "connected to: $location\n";
            $client->cv->send(1);
        }
    );

    $client->connect($location)
      || die "$location\nfatal: could not connect\n";
}

sub setup {

    if ( -t STDOUT and !is_debug ) {
        $client->on_comparing_update(
            sub {
                line_print(
                    sprintf(
                        '%s %s: comparing: %s',
                        $type, $name, $client->comparing
                    )
                );
            }
        );

        my $show_update = sub {
            line_print(
                sprintf(
                    '%s %s: sent: %d received: %d',
                    $type,                 $name,
                    $client->sent_updates, $client->recv_updates
                )
            );
        };

        $client->on_send_update($show_update);

        $client->on_recv_update($show_update);
    }

}

sub teardown {
    if ( $client->sent_updates or $client->recv_updates ) {
        line_print(
            sprintf(
                "%s %s: sent: %d received: %d\n",
                $type, $name, $client->sent_updates, $client->recv_updates
            )
        );
    }
    else {
        line_print("$type $name: no changes\n");
    }
}

sub real_run {
    my $db       = shift;
    my $location = shift;
    my $id       = shift;

    if ($id) {

        $type = check_thread( { thread => $id } );
        if ( $type eq 'project' ) {
            $name = $id;
            setup();
            connect_hub($location);
            $client->sync_project( { id => $id } )
              || die "fatal: sync failed\n";
            teardown();
            $client->disconnect;
        }
        else {
            not_implemented('sync based on ID');
        }
        return;
    }
    elsif ($location) {

        my @threads = $db->hub_threads($location);
        if ( !@threads ) {
            return;
        }

        connect_hub($location);

        foreach my $thread (@threads) {

            $type = $thread->thread_type;
            if ( $type eq 'project' ) {
                $name = $thread->path;
                setup();
                $client->sync_project( { id => $thread->id } )
                  || die "fatal: sync failed\n";
                teardown();
            }
            else {
                $name = $thread->id;
                setup();
                print "type $type doesn't work\n";
            }
        }

        $client->disconnect;
        return;
    }
}

sub run {
    my $opts = shift;
    my $db   = find_db($opts);

    $client = $db->client;

    if ( $opts->{location} ) {
        check_thread($opts);
        check_hub($opts);
        real_run( $db, $opts->{location}, $opts->{id} );
    }
    elsif ( $opts->{thread} ) {
        check_thread($opts);
        my @locations = $db->id2hubs( $opts->{id} );
        real_run( $db, $_->location, $opts->{id} ) for @locations;
    }
    else {
        foreach my $hub ( $db->hubs ) {
            real_run( $db, $hub->location );
        }
    }

}

1;
__END__

=head1 NAME

App::curo::Cmd::sync - exchange updates with a hub

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
