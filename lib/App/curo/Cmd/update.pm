package App::curo::Cmd::update; our $VERSION = '0.0.2';
use strict;
use warnings;
use App::curo::Util;

sub update_task {
    my $opts = shift;
    my $db   = find_db($opts);

    $opts->{task_id} = delete $opts->{id};

    if ( $opts->{title} ) {
        die "fatal: cannot modify title in threaded comments\n"
          if $opts->{parent_id};
    }

    if ( $opts->{state} ) {
        die "fatal: cannot modify state in threaded comments\n"
          if $opts->{parent_id};

        if ( $opts->{state} =~ m/^(.*):(.*)$/ ) {
            $opts->{project_id} = $db->path2project_id($1);
            $opts->{state}      = $2;
        }
        elsif ( my $project_id =
            $db->one_and_only_project_id( $opts->{task_id} ) )
        {
            $opts->{project_id} = $project_id;
        }
        else {
            die "fatal: usage: --state PROJECT:STATUS\n";
        }
    }
    $opts->{comment} ||= prompt_edit( opts => $opts );

    print "Updated task: $opts->{task_id} (u$opts->{update_id})\n"
      if $db->insert_task_update($opts);

}

sub update_issue {
    my $opts = shift;
    my $db   = find_db($opts);

    $opts->{issue_id} = delete $opts->{id};

    if ( $opts->{title} ) {
        die "fatal: cannot modify title in threaded comments\n"
          if $opts->{parent_id};
    }

    if ( $opts->{state} ) {
        die "fatal: cannot modify state in threaded comments\n"
          if $opts->{parent_id};

        if ( $opts->{state} =~ m/^(.*):(.*)$/ ) {
            $opts->{project_id} = $db->path2project_id($1);
            $opts->{state}      = $2;
        }
        elsif ( my $project_id =
            $db->one_and_only_project_id( $opts->{issue_id} ) )
        {
            $opts->{project_id} = $project_id;
        }
        else {
            die "fatal: usage: --state PROJECT:STATUS\n";
        }
    }

    $opts->{comment} ||= prompt_edit( opts => $opts );

    print "Updated issue: $opts->{issue_id} (u$opts->{update_id})\n"
      if $db->insert_issue_update($opts);
}

sub update_project {
    my $opts = shift;
    my $db   = find_db($opts);

    if ( $opts->{title} ) {
        die "fatal: cannot modify title in threaded comments\n"
          if $opts->{parent_id};
    }

    if ( $opts->{phase} ) {
        die "fatal: cannot modify phase in threaded comments\n"
          if $opts->{parent_id};
    }

    if ( $opts->{name} ) {
        die "fatal: cannot modify name in threaded comments\n"
          if $opts->{parent_id};
    }

    $opts->{comment} ||= prompt_edit( opts => $opts );

    if ( $db->update_project($opts) ) {
        my $project = $db->id2project( $opts->{id} );

        printf( "Updated project: %s (u%d)\n",
            $project->path, $project->update_id );
    }
}

sub run {
    my $opts   = shift;
    my $config = find_conf($opts);
    my $db     = find_db($opts);

    $opts->{lang}   ||= 'en';
    $opts->{email}  ||= $config->{user}->{email};
    $opts->{author} ||= $config->{user}->{name};

    my $type = check_thread($opts);

    if ( $type eq 'issue' ) {
        return update_issue($opts);
    }
    elsif ( $type eq 'task' ) {
        return update_task($opts);
    }
    elsif ( $type eq 'project' ) {
        return update_project($opts);
    }
    else {
        die "fatal: Can't update type: " . $type . "\n";
    }
}

1;
__END__

=head1 NAME

App::curo::Cmd::update - Modify thread meta-data

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
