package App::curo::Cmd::list::tasks; our $VERSION = '0.0.2';
use strict;
use warnings;
use App::curo::Util;

$ENV{CURO_DEBUG_PAGER} = 1;

sub run {
    my $opts = shift;
    my $db   = find_db($opts);

    if ( exists $opts->{project} ) {
        $opts->{project_id} = check_project( delete $opts->{project} );
    }

    my @invalid = $db->invalid_state_status( @{ $opts->{status} } );
    die "fatal: invalid state or status: @invalid\n" if @invalid;

    my $data = $db->arrayref_task_list($opts);
    return print "No [@{$opts->{status}}] tasks (use \"new task\" to create)\n"
      unless @$data;

    start_pager;
    print render_table( 'lr  l  l  l ',
        [ ' ', 'ID', 'Task', 'Project', 'State' ], $data );
    end_pager;

    return;
}

1;
__END__

=head1 NAME

App::curo::Cmd::list::tasks - List project tasks

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
