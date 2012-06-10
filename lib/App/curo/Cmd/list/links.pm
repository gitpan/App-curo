package App::curo::Cmd::list::links; our $VERSION = '0.0.2';
use strict;
use App::curo::Util;

$ENV{CURO_DEBUG_PAGER} = 1;

sub run {
    my $opts = shift;
    my $db   = find_db($opts);

    my $data = $db->iter_list_links->arrays;

    return print "0 entries\n" unless @$data;
    start_pager;

    print render_table( ' r  l  r  l  l ',
        [ 'LID', 'Hub', 'ID', 'Type', 'Title' ], $data );

    end_pager;

    return;
}

1;
__END__

=head1 NAME

App::curo::Cmd::list::links - List threads linked to a hub

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
