package App::curo::Cmd::reply; our $VERSION = '0.0.2';
use strict;
use warnings;
use App::curo::Util;
use Term::Prompt;

sub order { 8 }

sub arg_spec {
    return ( [ "id=s", "ID, Update ID or project", { required => 1 } ], );
}

sub opt_spec {
    return (
        [ "author=s",  "Author" ],
        [ "ctime=s",   "Created" ],
        [ "email=s",   "Email" ],
        [ "lang=s",    "Lang" ],
        [ "locale=s",  "Locale" ],
        [ "comment=s", "Comment" ],
        [ 'debug|d=s', 'Enable debugging output' ],
    );
}

sub run {
    my ( $self, $opt ) = @_;
    my $db = find_db($opt);

    my $type;

    if ( $opt->id =~ m/^\d+$/ ) {
        $type = $db->id2thread_type( $opt->id )
          || die "fatal: ID not found: " . $opt->id . "\n";
    }
    elsif ( $opt->id =~ m/^u(\d+)$/ ) {
        $opt->{parent_id} = $1;
        $opt->{id}        = $db->update2id( $opt->{parent_id} )
          || die "fatal: Update ID not found: c$opt->{parent_id}\n";

        $type = $db->id2thread_type( $opt->id )
          || die "fatal: ID not found: " . $opt->id . "\n";
    }
    else {
        $db->path2project_id( $opt->{id} )
          || die "fatal: Unknown project: $opt->{id}\n";
        $type = 'project';
    }

    $opt->{comment} ||= prompt_edit( opts => $opt );

    if ( $type eq 'issue' ) {
        $opt->{issue_id} = delete $opt->{id};
        print "Issue updated: $opt->{issue_id} " . "(u$opt->{update_id})\n"
          if $db->insert_issue_update($opt);
    }
    elsif ( $type eq 'task' ) {
        $opt->{task_id} = delete $opt->{id};
        print "Task updated: $opt->{task_id} " . "(u$opt->{update_id})\n"
          if $db->insert_task_update($opt);
    }
    elsif ( $type eq 'project' ) {
        if ( $db->insert_project_update($opt) ) {
            my $project = $db->id2project( $opt->{id} );

            printf( "Updated project: %s (u%d)\n",
                $project->path, $project->update_id );
        }
    }
    else {
        die "fatal: Can't comment on type: " . $type . "\n";
    }
}

1;
__END__

=head1 NAME

App::curo::Cmd::reply - Comment on a particular update

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
