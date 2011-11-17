package App::curo::push; our $VERSION = '0.01_01';
use strict;
use warnings;
use App::curo::Util;
use Curo::Sync;

sub order { 9 }

sub arg_spec {
    return ( [ 'src=s', 'What to push' ], [ 'dest=s', 'Where to push it to' ],
    );
}

sub opt_spec { ( [ 'debug|d=s', 'Enable debugging output' ], ) }

sub push_all {
    warn "push to everywhere not implemented yet";
}

sub run {
    my ( $self, $opt ) = @_;
    my $db = find_db($opt);

    if ( !$opt->src and !$opt->dest ) {
        return push_all();
    }

    if ( $opt->src and !$opt->dest ) {
        die "fatal: destination required\n";
    }

    my $id;
    my $project;
    my $location;
    my $remote_project;

    if ( $opt->src =~ m/^(\d+)$/ ) {
        $id = $1;
        die "fatal: ID not found: $id\n" unless $db->id2thread_type($id);

        if ( $opt->dest =~ /^(.+):(.+)$/ ) {
            ( $location, $remote_project ) = ( $1, $2 );
        }
        else {
            die "fatal: destination needs project name\n";
        }
    }
    else {
        $project = $opt->src;
        die "fatal: project not found: $project\n"
          unless $db->path2project_id($project);

        if ( $opt->dest =~ /^(.+):(.+)$/ ) {
            ( $location, $remote_project ) = ( $1, $2 );
        }
        elsif ( $opt->dest =~ /^(.+?):?$/ ) {
            ( $location, $remote_project ) = ( $1, $project );
        }
    }

    if ( my $hub = $db->name2hub($location) ) {
        $location = $hub->location;
    }
    elsif ( !-d $location ) {
        die "fatal: hub (or directory) not found: $location\n";
    }

    $db->connect( location => $location )
      || die "Could not connect: $location\n";
    print "Connected to $location\n";
    print "Pushed: ";

    my $res;
    if ($id) {
    }
    else {
        $res = $db->push_project( $project, $remote_project );
    }

    print $res . "\n";
    $db->disconnect;

}

1;
__END__

=head1 NAME

App::curo::push - Send updates to a hub

=head1 SYNOPSIS

  curo push

=head1 DESCRIPTION

See L<curo>(1) for details.

=head1 SEE ALSO

L<App::curo>(3p), L<curo>(1)
=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.


=cut
