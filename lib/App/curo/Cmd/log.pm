package App::curo::Cmd::log; our $VERSION = '0.0.2';
use strict;
use warnings;
use App::curo::Util;
use POSIX qw/floor strftime/;
use Time::Duration;
use Time::Piece;
use Text::Autoformat qw/autoformat/;
use locale;

$ENV{CURO_DEBUG_PAGER} = 1;

my $bold   = color('bold');
my $yellow = color('yellow');
my $red    = color('red');
my $dark   = color('dark');
my $reset  = color('clear reset');

my $now;
my $nowtzoffset;

sub reformat {
    my $text = shift;
    my $depth = shift || 0;

    $depth-- if $depth;

    my $left   = 1 + 4 * $depth;
    my $indent = '    ' x $depth;

    my @result;

    foreach my $para ( split /\n\n/, $text ) {
        if ( $para =~ m/^[^\s]/ ) {
            push( @result, autoformat( $para, { left => $left } ) );
        }
        else {
            $para =~ s/^/$indent/gm;
            push( @result, $para, "\n\n" );
        }
    }

    return @result;
}

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
        $yellow . $_[0] . ':',
        $_[1] . ( defined $_[2] ? $dark . ' <' . $_[2] . '>' : '' ) . $reset
    ];
}

sub header2 {
    return [
        $dark . $yellow . $_[0] . ':',
        $_[1] . ( defined $_[2] ? ' <' . $_[2] . '>' : '' ) . $reset
    ];
}

sub _log_issue {
    my $row = shift;
    my $i   = shift;
    my @data;

    if ( $i == 1 ) {
        push( @data, header( 'Issue', $row->issue_id, $row->uuid ) );
        push( @data, header( 'From',  $row->author,   $row->email ) );

        push( @data, header( 'When', new_ago( $row->mtime, $row->mtimetz ) ) );
    }
    else {
        push( @data,
            header2( 'Update', 'u' . $row->update_id, $row->update_uuid ) );
        push( @data, header2( 'From', $row->author, $row->email ) );

        push( @data, header2( 'When', new_ago( $row->mtime, $row->mtimetz ) ) );
    }

    push(
        @data,
        header(
            'State',
            $row->state . ' (' . $row->status . ')',
            'project:' . $row->path
        )
    ) if defined $row->state;

    push( @data, header( 'Title', $row->title ) )
      if ( defined $row->title and $i != 1 );

    print render_table( 'l  l', undef, \@data, 4 * $row->depth ) . "\n";

    my $prefix = '    ' x $row->depth;

    print $bold. $prefix . $row->title . $reset . "\n\n"
      if ( defined $row->title and $i == 1 );

    print reformat( $row->comment, $row->depth ), "\n";
}

sub log_issue {
    my $cursor = shift;

    start_pager;

    my $i = 1;
    while ( my $row = $cursor->next ) {
        _log_issue( $row, $i );
        $i++;
    }

    end_pager;
}

sub _log_task {
    my $row = shift;
    my $i   = shift;
    my @data;

    if ( $i == 1 ) {
        push( @data, header( 'Task', $row->task_id, $row->uuid ) );
        push( @data, header( 'From', $row->author,  $row->email ) );

        push( @data, header( 'When', new_ago( $row->mtime, $row->mtimetz ) ) );
    }
    else {
        push( @data,
            header2( 'Update', 'u' . $row->update_id, $row->update_uuid ) );
        push( @data, header2( 'From', $row->author, $row->email ) );

        push( @data, header2( 'When', new_ago( $row->mtime ) ) );

    }

    push(
        @data,
        header(
            'State',
            $row->state . ' (' . $row->status . ')',
            'project:' . $row->path
        )
    ) if defined $row->state;

    push( @data, header( 'Title', $row->title ) )
      if ( defined $row->title and $i != 1 );

    print render_table( 'l  l', undef, \@data, 4 * ( $row->depth - 1 ) ) . "\n";

    my $prefix = '    ' x $row->depth;

    print $bold. $prefix . $row->title . $reset . "\n\n"
      if ( defined $row->title and $i == 1 );

    print reformat( $row->comment, $row->depth ), "\n";
}

sub log_task {
    my $cursor = shift;

    start_pager;

    my $i = 1;
    while ( my $row = $cursor->next ) {
        _log_task( $row, $i );
        $i++;
    }

    end_pager;
}

sub _log_project {
    my $row = shift;
    my $i   = shift;
    my @data;

    if ( $i == 1 ) {
        push( @data, header( 'Project', $row->path,   $row->uuid ) );
        push( @data, header( 'From',    $row->author, $row->email ) );

        push( @data, header( 'When', new_ago( $row->mtime, $row->mtimetz ) ) );

    }
    else {
        push( @data,
            header2( 'Update', 'u' . $row->update_id, $row->update_uuid ) );
        push( @data, header2( 'From', $row->author, $row->email ) );

        push( @data, header2( 'When', new_ago( $row->mtime, $row->mtimetz ) ) );
    }

    push( @data, header( 'Name', $row->name, ) )
      if ( defined $row->name and ( $i != 1 or $row->name ne $row->path ) );

    push( @data, header( 'Phase', $row->phase, ) )
      if defined $row->phase;

    if ( $i != 1 ) {
        push( @data, header( 'AddKind', $row->add_kind, ) )
          if defined $row->add_kind;

        push( @data, header( 'AddState', $row->add_state, ) )
          if defined $row->add_state;

        push( @data, header( 'AddStatus', $row->add_status, ) )
          if defined $row->add_status;

        push( @data, header( 'AddRank', $row->add_rank, ) )
          if defined $row->add_rank;

        push( @data, header( 'AddDefault', $row->add_def ? 'yes' : 'no', ) )
          if defined $row->add_def;
    }

    push( @data, header( 'Title', $row->title ) )
      if ( defined $row->title and $i != 1 );

    print render_table( 'l  l', undef, \@data, 4 * ( $row->depth - 1 ) ) . "\n";

    if ( $row->push_to ) {
        print "[Pushed to " . $row->push_to . "]\n\n\n";
    }
    else {
        my $prefix = '    ' x $row->depth;

        print $bold. $prefix . $row->title . $reset . "\n\n"
          if defined $row->title;

        print reformat( $row->comment, $row->depth ), "\n";
    }
}

sub log_project {
    my $cursor = shift;

    start_pager;

    my $i = 1;
    while ( my $row = $cursor->next ) {
        _log_project( $row, $i );
        $i++;
    }

    end_pager;
}

sub run {
    my $opts = shift;
    my $db   = find_db($opts);
    $now         = time;
    $nowtzoffset = int( localtime->tzoffset );

    if ( $opts->{thread} ) {
        my $type = check_thread($opts);

        if ( $type eq 'issue' ) {
            return log_issue( $db->iter_issue_log( $opts->{id} ) );
        }
        elsif ( $type eq 'task' ) {
            return log_task( $db->iter_task_log( $opts->{id} ) );
        }
        elsif ( $type eq 'project' ) {
            return log_project( $db->iter_project_log( $opts->{id} ) );
        }
        else {
            die "fatal: Can't log type: " . $type . "\n";
        }
    }

    my $cursor = $db->iter_full_thread_log;

    start_pager;

    while ( my $row = $cursor->next ) {
        my @data;

        if ( $row->new_item ) {

            if ( $row->thread_type eq 'project' ) {
                push( @data, header( 'Project', $row->path, $row->uuid ) );

                push( @data, header( 'From', $row->author, $row->email ) );

                push( @data,
                    header( 'When', new_ago( $row->mtime, $row->mtimetz ) ) );

                my $name = $row->name;
                push( @data, header( 'Name', $row->name, ) )
                  unless $row->path =~ m/\/?$name$/;

            }
            else {
                push(
                    @data,
                    header(
                        ucfirst( $row->thread_type ), $row->id, $row->uuid
                    )
                );
                push( @data, header( 'From', $row->author, $row->email ) );

                push( @data,
                    header( 'When', new_ago( $row->mtime, $row->mtimetz ) ) );

            }

        }
        else {
            push( @data,
                header2( 'Update', 'u' . $row->update_id, $row->update_uuid ) );

            if ( $row->thread_type eq 'project' ) {
                push(
                    @data,
                    header2(
                        'Project', $row->path . ' - ' . $row->title,
                        $row->uuid
                    )
                );

                push( @data, header2( 'From', $row->author, $row->email ) );

                push( @data,
                    header2( 'When', new_ago( $row->mtime, $row->mtimetz ) ) );

            }
            else {
                push(
                    @data,
                    header2(
                        ucfirst( $row->thread_type ),
                        '[' . $row->id . '] ' . $row->title
                    )
                );

                push( @data, header2( 'From', $row->author, $row->email ) );

                push( @data,
                    header2( 'When', new_ago( $row->mtime, $row->mtimetz ) ) );
            }
            push( @data, header( 'AddKind', $row->add_kind, ) )
              if defined $row->add_kind;

            push( @data, header( 'AddState', $row->add_state, ) )
              if defined $row->add_state;

            push( @data, header( 'AddStatus', $row->add_status, ) )
              if defined $row->add_status;

            push( @data, header( 'AddRank', $row->add_rank, ) )
              if defined $row->add_rank;

            push( @data, header( 'AddDefault', $row->add_def ? 'yes' : 'no', ) )
              if defined $row->add_def;

            push( @data, header( 'Name', $row->path, ) )
              if defined $row->name;
        }

        if ( $row->state ) {
            if ( $row->thread_type eq 'project' ) {
                push( @data, header( 'Phase', $row->state, ) );
            }
            else {
                push(
                    @data,
                    header(
                        'State',
                        $row->state . ' (' . $row->status . ')',
                        'project:' . $row->path
                    )
                );
            }
        }

        print render_table( 'l  l', undef, \@data ) . "\n";

        if ( $row->push_to ) {
            print "[Pushed to " . $row->push_to . "]\n\n\n";
        }
        else {
            my $prefix = '';    #'    ' x 0;

            print $bold. $prefix . $row->title . $reset . "\n\n"
              if ( defined $row->title and $row->new_item );

            print reformat( $row->comment ), "\n";
        }
        next;

    }
    end_pager;
}

1;
__END__

=head1 NAME

App::curo::Cmd::log - Review thread history

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
