package App::curo::Cmd::list::project_threads; our $VERSION = '0.0.2';
use strict;
use utf8;
use App::curo::Util;
use OptArgs qw/usage dispatch/;

$ENV{CURO_DEBUG_PAGER} = 1;

sub run {
    my $opts = shift;
    my $db   = find_db($opts);

    return print "No projects (use \"new project\" to create)\n"
      unless $db->project_count;

    my @invalid = $db->invalid_state_status( @{ $opts->{status} } );
    die "fatal: invalid state or status: @invalid\n" if @invalid;

    @invalid = $db->invalid_phases( @{ $opts->{phase} } );
    die "fatal: invalid project phase: @invalid\n" if @invalid;

    my $data = $db->arrayref_list_all($opts);

    return
      print "No entries [phase:@{$opts->{phase}}, status:@{$opts->{status}}]\n"
      unless @$data > 1;

    require Text::FormatTable;
    require Term::Size;

    my $table = Text::FormatTable->new(' r  l  l ');
    my $dark  = color('dark');    # empty if STDOUT isn't a terminal
    my $bold  = color('bold');
    my $reset = color('reset');

    foreach my $i ( 0 .. ( scalar @$data - 1 ) ) {
        if ( $data->[$i]->[0] == -1 ) {
            $table->rule(' ') if $i;
            $table->head(
                $bold . 'ID',
                'Topic (' . $data->[$i][1] . ')',
                'State' . $reset
            );
            if ($dark) {
                $table->rule('–');
            }
            else {
                $table->rule('-');
            }

        }
        else {
            $data->[$i]->[2] =~ s/\(/$dark\(/ if $dark;
            $table->row( @{ $data->[$i] } );
        }
    }

    start_pager;

    print $table->render( ( Term::Size::chars() )[0] );

    end_pager;

    return;
}

1;
__END__

=head1 NAME

App::curo::Cmd::list::project_threads - List project threads

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
