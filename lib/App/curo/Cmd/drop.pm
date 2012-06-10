package App::curo::Cmd::drop; our $VERSION = '0.0.2';
use strict;
use warnings;
use App::curo::Util;

sub run {
    my $opts = shift;
    my $db   = find_db($opts);

    my $type = check_thread($opts);

    if ( $type eq 'issue' ) {
        if ( $opts->{force} ) {
            print "Issue dropped: $opts->{thread}\n"
              if $db->drop_issue( $opts->{thread} );
        }
        else {
            print "Nothing dropped (missing --force, -f)\n";
        }
    }
    elsif ( $type eq 'task' ) {
        if ( $opts->{force} ) {
            print "Task dropped: $opts->{thread}\n"
              if $db->drop_task( $opts->{thread} );
        }
        else {
            print "Nothing dropped (missing --force, -f)\n";
        }
    }
    elsif ( $type eq 'project' ) {
        if ( $opts->{force} ) {
            print "Project dropped: $opts->{thread}\n"
              if $db->drop_project( $opts->{thread} );
        }
        else {
            print "Nothing dropped (missing --force, -f)\n";
        }
    }
    elsif ( $type eq 'hub' ) {
        if ( $opts->{force} ) {
            print "Hub dropped: $opts->{thread}\n"
              if $db->drop_thread( $opts->{id}, $type );
        }
        else {
            print "Nothing dropped (missing --force, -f)\n";
        }
    }
    else {
        die "fatal: Can't drop type: " . $type . "\n";
    }

    return;
}

1;
__END__

=head1 NAME

App::curo::Cmd::drop - Remove items from the database

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
