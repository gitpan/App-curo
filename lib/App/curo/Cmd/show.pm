package App::curo::Cmd::show; our $VERSION = '0.0.2';
use strict;
use warnings;
use App::curo::Util;
use POSIX qw/floor strftime/;
use Time::Duration;
use Time::Piece;
use locale;

$ENV{CURO_DEBUG_PAGER} = 1;

my $bold   = color('bold');
my $yellow = color('yellow');
my $red    = color('red');
my $dark   = color('dark');
my $reset  = color('clear reset');

my $now;
my $nowtzoffset;

sub new_ago {
    my $time    = shift;
    my $offset  = shift;
    my $hours   = floor( $offset / 60 / 60 );
    my $minutes = ( abs($offset) - ( abs($hours) * 60 * 60 ) ) / 60;

    my $local =
        Time::Piece->strptime( $time - $nowtzoffset + $offset, '%s' )->datetime
      . ' '
      . sprintf( '%+.2d%.2d', $hours, $minutes );

    $local =~ s/T/ /;

    if ( -t STDOUT ) {
        return ( Time::Duration::ago( $now - $time, 1 ), $local );
    }
    else {
        return ( strftime( '%c', localtime($time) ), $local );
    }
}

sub header {
    return [
        $_[0] . ':',
        $_[1] . ( defined $_[2] ? $dark . ' <' . $_[2] . '>' : '' ) . $reset
    ];
}

sub header2 {
    return [
        $dark . $yellow . $_[0] . ':',
        $_[1] . ( defined $_[2] ? ' <' . $_[2] . '>' : '' ) . $reset
    ];
}

sub show_project {
    my $opts   = shift;
    my $db     = find_db;
    my $spacer = [ ' ', $dark . '-' ];

    my $project = $db->id2project( $opts->{id} );
    my @phases  = $db->iter_project_phases($opts)->objects;
    my $phases =
      join( ', ', map { $_->current ? uc $_->phase : $_->phase } @phases );

    my @data;
    push( @data,
        header( $bold . 'Project', $project->path . ' - ' . $project->title ) );
    push( @data, $spacer );

    push( @data, header( 'Phases', $phases ) );
    push( @data, $spacer );

    my $tasks = join( "\n",
        map { "$_->{count} $_->{state} $dark($_->{status})$reset" }
          $db->iter_project_tasks($opts)->hashes );
    push( @data, header( 'Tasks', $tasks ) );
    push( @data, $spacer );

    my $issues = join( "\n",
        map { "$_->{count} $_->{state} $dark($_->{status})$reset" }
          $db->iter_project_issues($opts)->hashes );
    push( @data, header( 'Issues', $issues ) );

    my $hubs = join( "\n",
        map { "$_->{alias} $dark<$_->{location}>$reset" }
          $db->iter_project_links($opts)->hashes );
    push( @data, $spacer, header( 'Hubs', $hubs ) ) if $hubs;

    start_pager;

    print render_table( 'l  l', undef, \@data );
    end_pager;
}

sub show_hub {
    my $opts = shift;
    my $db   = find_db;

    not_implemented('');
    start_pager;

    end_pager;
}

sub run {
    my $opts = shift;
    my $db   = find_db($opts);

    $now         = time;
    $nowtzoffset = int( localtime->tzoffset );

    my $type = check_thread($opts);

    if ( $type eq 'issue' ) {
        return show_issue( $db->iter_issue_show( $opts->{id} ) );
    }
    elsif ( $type eq 'task' ) {
        return show_task( $db->iter_task_show( $opts->{id} ) );
    }
    elsif ( $type eq 'project' ) {
        return show_project($opts);
    }
    elsif ( $type eq 'hub' ) {
        return show_hub($opts);
    }
    else {
        die "fatal: Can't show type: " . $type . "\n";
    }
}

1;
__END__

=head1 NAME

App::curo::Cmd::show - Display thread status

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
