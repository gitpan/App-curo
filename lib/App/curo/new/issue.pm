package App::curo::new::issue; our $VERSION = '0.01_02';
use strict;
use warnings;
use App::curo::Util;
use Term::Prompt;

sub opt_spec {
    return (
        [ "status=s",      "Status" ],
        [ "t_id=s",        "ID" ],
        [ "thread_type=s", "Thread Type" ],
        [ "author=s",      "Author" ],
        [ "ctime=s",       "Created" ],
        [ "email=s",       "Email" ],
        [ "lang=s",        "Lang" ],
        [ "locale=s",      "Locale" ],
        [ "mtime=s",       "Modified" ],
        [ "project|p=s",   "Project" ],
        [ "thread_type=s", "Thread Type" ],
        [ "title=s",       "Title" ],
        [ "comment|c=s",   "Comment" ],
        [ 'debug|d=s',     'Enable debugging output' ],
    );
}

sub arg_spec {
    return ( [ "project=s", "Project" ], );
}

sub run {
    my ( $self, $opt ) = @_;
    my $db = find_db($opt);

    check_project( $opt->{project} ||= prompt( 'x', "Project:", '', '' ) );

    $opt->{title} ||= "@ARGV" || prompt( 'x', "Title:", '', '' );
    $opt->{comment} ||= prompt_edit( name => 'Description', );

    print "New issue: $opt->{issue_id} <$opt->{thread_uuid}>\n"
      if $db->insert_issue($opt);
}

1;
__END__

=head1 NAME

App::curo::new::issue - insert a new issue into the database

=head1 SYNOPSIS

  dpt issues ACTION

=head1 DESCRIPTION

See L<curo>(1) for details.

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.


=cut
