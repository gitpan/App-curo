package App::curo::Cmd::list::projects; our $VERSION = '0.0.2';
use strict;
use warnings;
use App::curo::Util;

$ENV{CURO_DEBUG_PAGER} = 1;

sub run {
    my $opts = shift;
    my $db   = find_db($opts);

    return print "No projects (use \"new\" to create)\n"
      unless $db->project_count;

    my @invalid = $db->invalid_phases( @{ $opts->{phase} } );
    die "fatal: invalid phase: @invalid\n" if @invalid;

    my $data = $db->arrayref_project_list($opts);

    return
      print "No [phase:@{$opts->{phase}}] projects "
      . "(use \"new\" to create)\n"
      unless @$data;

    start_pager;

    print render_table( ' l  l  l  r r r ',
        [ 'Project', 'Title', 'Phase', 'Progress', 'Active', 'Stalled' ],
        $data );

    end_pager;

    return;
}

1;
__END__

=head1 NAME

App::curo::Cmd::list::projects - List projects

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
