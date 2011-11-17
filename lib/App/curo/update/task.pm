package App::curo::update::task; our $VERSION = '0.01_02';
use strict;
use warnings;
use App::curo::Util;
use Term::Prompt;

sub opt_spec {
    return (
        [ "status|s=s",    "Status" ],
        [ "thread_type=s", "Thread Type" ],
        [ "parent-id=s",   "Parent ID" ],
        [ "author=s",      "Author" ],
        [ "ctime=s",       "Created" ],
        [ "email=s",       "Email" ],
        [ "lang=s",        "Lang" ],
        [ "locale=s",      "Locale" ],
        [ "title=s",       "Title" ],
        [ "comment=s",     "Comment" ],
        [ 'debug|d=s',     'Enable debugging output' ],
    );
}

sub arg_spec {
    return ( [ "task_id=s", "ID", { required => 1 } ], );
}

sub run {
    my ( $self, $opt ) = @_;
    my $db = find_db($opt);

    $db->id2thread_type( $opt->{task_id} )
      || die "ID not found: " . $opt->id . "\n";

    $opt->{comment} ||= prompt_edit( name => 'Comment', );

    print "Updated task: $opt->{task_id}\n" if $db->insert_task_update($opt);

}

1;
__END__

=head1 NAME

App::curo::update::task - comment or modify an task

=head1 SYNOPSIS

  dpt tasks update <t_id>

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
