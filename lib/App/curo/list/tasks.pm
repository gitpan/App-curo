package App::curo::list::tasks; our $VERSION = '0.01_01';
use strict;
use warnings;
use App::curo::Util;
use SQL::DB ':all';

sub order { 20 }

sub opt_spec {
    return (
        [ "status|s=s",  "Status" ],
        [ "progress=s",  "Progress" ],
        [ "order=s",     "Progress" ],
        [ 'project|p=s', 'Project to list tasks for' ],
        [ "asc",         "Ascending order" ],
        [ 'debug|d=s',   'Enable debugging output' ],
    );
}

sub arg_spec {
    return ( [ "project=s", "Project name" ], );
}

sub run {
    my ( $self, $opt ) = @_;
    my $db = find_db($opt);

    my $data = $db->arrayref_task_list($opt);
    return print "0 entries (use \"new\" to create)\n" unless @$data;

    start_pager;
    print render_table( 'lr  l  l  l ',
        [ ' ', 'ID', 'Task', 'Project', 'Status' ], $data );
    end_pager;

    return;
}

1;
__END__

=head1 NAME

App::curo::list::tasks - List project tasks

=head1 SYNOPSIS

  curo  ACTION

=head1 DESCRIPTION

See L<curo>(1) for details.

=head1 SEE ALSO

L<DDB>(3p), L<curo>(1)

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.


=cut
