package App::curo::log; our $VERSION = '0.01_02';
use strict;
use warnings;
use App::curo::Util;
use Time::Duration;
use Time::Local;

sub order { 6 }

sub opt_spec {
    return (
        [ "title|t",   "Include title in log summary", ],
        [ 'debug|d=s', 'Enable debugging output' ],
    );
}

sub arg_spec {
    return ( [ "what=s", "ID or project name", ], );
}

my $bold   = color('bold');
my $yellow = color('yellow');
my $dark   = color('dark');
my $reset  = color('clear reset');

my $now = time;

sub new_ago {
    my $time = shift;
    my ( $y, $m, $d, $h, $min, $s ) = split( /[-:\s]+/, $time );
    return Time::Duration::ago( $now - timegm( $s, $min, $h, $d, $m - 1, $y ),
        1 );
}

sub log_issue {
    my $cursor = shift;
    start_pager;

    my $i = 1;

    while ( my $row = $cursor->next ) {
        my @data;

        push( @data,
            [ 'Issue:', $row->issue_id . ' <' . $row->thread_uuid . '>' ] )
          if $i == 1;

        push(
            @data,
            [
                $dark . 'Update:',
                $row->issue_update_id . ' <' . $row->thread_update_uuid . '>'
            ]
        ) if $i != 1;

        push( @data,
            [ $dark . 'From:', $row->author . ' <' . $row->email . '>' ] );

        my $ago = new_ago( $row->mtime );
        push( @data, [ $dark . 'When:',   $ago . ' <' . $row->mtime . 'Z>' ] );
        push( @data, [ $dark . 'Status:', $row->status ] )
          if defined $row->status;
        push( @data, [ $dark . 'Project:', '+' . $row->project_name ] )
          if defined $row->project_name;

        my $header = render_table( 'l l', undef, \@data );
        $header =~ s/^/$yellow/gsm;
        print $header . $reset . "\n";

        print $bold. $row->title . $reset . "\n\n" if defined $row->title;
        if ( $row->comment ) {
            print $row->comment . "\n\n";
        }
        else {
            print "[No further description]\n\n" if $i == 1;
            print "[Update without comment]\n\n" if $i != 1;
        }
        $i++;
    }
    end_pager;
}

sub log_task {
    my $cursor = shift;
    start_pager;

    my $i = 1;

    while ( my $row = $cursor->next ) {
        my @data;

        push( @data,
            [ 'Task:', $row->task_id . ' <' . $row->thread_uuid . '>' ] )
          if $i == 1;

        push(
            @data,
            [
                $dark . 'Update:',
                $row->task_update_id . ' <' . $row->thread_update_uuid . '>'
            ]
        ) if $i != 1;

        push( @data,
            [ $dark . 'From:', $row->author . ' <' . $row->email . '>' ] );

        my $ago = new_ago( $row->mtime );
        push( @data, [ $dark . 'When:',   $ago . ' <' . $row->mtime . 'Z>' ] );
        push( @data, [ $dark . 'Status:', $row->status ] )
          if defined $row->status;

        my $header = render_table( 'l l', undef, \@data );
        $header =~ s/^/$yellow/gsm;
        print $header . $reset . "\n";

        print $bold. $row->title . $reset . "\n\n" if defined $row->title;
        if ( $row->comment ) {
            print $row->comment . "\n\n";
        }
        else {
            print "[No further description]\n\n" if $i == 1;
            print "[Update without comment]\n\n" if $i != 1;
        }
        $i++;
    }
    end_pager;
}

sub log_project {
    my $path   = shift;
    my $cursor = shift;
    start_pager;

    my $i = 1;

    while ( my $row = $cursor->next ) {
        my @data;

        if ( $i == 1 ) {
            push( @data,
                [ 'Project:', $row->path . ' <' . $row->thread_uuid . '>' ] );
            push( @data,
                [ $dark . 'Creator:', $row->author . ' <' . $row->email . '>' ]
            );
        }
        else {

            push(
                @data,
                [
                    $dark . 'Update:',
                    $row->project_update_id . ' <'
                      . $row->thread_update_uuid . '>'
                ]
            );
            push( @data,
                [ $dark . 'From:', $row->author . ' <' . $row->email . '>' ] );
        }

        my $ago = new_ago( $row->mtime );
        push( @data, [ $dark . 'When:', $ago . ' <' . $row->mtime . 'Z>' ] );

        push( @data, [ $dark . 'Name:', $row->name ] ) if defined $row->name;

        push( @data, [ $dark . 'Phase:', $row->phase ] ) if defined $row->phase;

        my $header = render_table( 'l l', undef, \@data );
        $header =~ s/^/$yellow/gsm;
        print $header . $reset . "\n";

        if ( $row->push_to ) {
            print "[Pushed to " . $row->push_to . "]\n\n";
        }
        else {
            print $bold. $row->title . $reset . "\n\n" if defined $row->title;
            if ( $row->comment ) {
                print $row->comment . "\n\n";
            }
            else {
                print "[No further description]\n\n" if $i == 1;
                print "[Update without comment]\n\n" if $i != 1;
            }
        }
        $i++;
    }
    end_pager;
}

sub run {
    my ( $self, $opt ) = @_;
    my $db = find_db($opt);

    if ( defined $opt->what ) {
        if ( $opt->what =~ m/^\d+$/ ) {
            my $type = $db->id2thread_type( $opt->what )
              || die "ID not found: " . $opt->what . "\n";

            if ( $type eq 'issue' ) {
                return log_issue( $db->iter_issue_log( $opt->what ) );
            }
            elsif ( $type eq 'task' ) {
                return log_task( $db->iter_task_log( $opt->what ) );
            }
            else {
                die "Can't log type: " . $type . "\n";
            }
        }
        else {
            $db->path2project_id( $opt->what )
              || die "fatal: unknown project: $opt->{what}\n";
            return log_project( $opt->what,
                $db->iter_project_log( $opt->what ) );
        }

    }

    my $now    = time;
    my $cursor = $db->iter_full_thread_log;

    start_pager;

    while ( my $row = $cursor->next ) {

        #        print $yellow. $row->mtime .$reset .' ';
        print $yellow. new_ago( $row->mtime ) . $reset . ' ';

        if ( $row->thread_type eq 'project' ) {
            if ( $row->new_item ) {
                print 'NEW project "'
                  . $row->project
                  . '" [phase:'
                  . $row->phase . '] ';
            }
            else {
                print $dark . '[' . $row->project . '] ' . $reset;
                if ( $row->push_to ) {
                    print 'pushed to ' . $row->push_to . ' ';
                }
                else {
                    print 'project update';
                    print ' [phase:' . $row->phase . '] ' if $row->phase;
                }
            }
        }
        else {    # issue and task
            print $dark . '[' . $row->project . '] ' . $reset;
            if ( $row->new_item ) {
                print 'NEW ';
            }
            print $row->thread_type . ' #' . $row->thread_id;
            if ( !$row->new_item ) {
                print ' update';
            }
            print ' [status:' . $row->status . ']' if $row->status;
        }

        print $dark . ' ' . $row->author . ' <' . $row->email . '>' . $reset;
        print "\n";

        if ( $opt->title ) {
            print '  ' . $row->title . "\n";
        }
    }
    end_pager;
}

1;
__END__

=head1 NAME

App::curo::log - Review update history

=head1 SYNOPSIS

  curo log [<id>]

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
