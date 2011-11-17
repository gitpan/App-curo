package App::curo::update::project; our $VERSION = '0.01_01';
use strict;
use warnings;
use App::curo::Util;
use Term::Prompt;

sub opt_spec {
    return (
        [ "name|n=s",    "Name" ],
        [ "phase|p=s",   "Phase" ],
        [ "parent-id=s", "Parent ID" ],
        [ "author=s",    "Author" ],
        [ "ctime=s",     "Created" ],
        [ "email=s",     "Email" ],
        [ "lang=s",      "Lang" ],
        [ "locale=s",    "Locale" ],
        [ "title=s",     "Title" ],
        [ "comment|c=s", "Comment" ],
        [ 'debug|d=s',   'Enable debugging output' ],
    );
}

sub arg_spec {
    return ( [ "project=s", "Project name", { required => 1 } ], );
}

sub run {
    my ( $self, $opt ) = @_;
    my $db = find_db($opt);

    $db->path2project_id( $opt->{project} )
      || die "Unknown project: $opt->{project}\n";

    $opt->{comment} ||= prompt_edit( name => 'Comment', );

    print "Updated project: $opt->{project} <$opt->{thread_update_uuid}>\n"
      if $db->insert_project_update($opt);
}

1;
__END__

=head1 NAME

App::curo::update::project - comment or modify an project

=head1 SYNOPSIS

  dpt projects update <t_id>

=head1 DESCRIPTION

See L<dpt>(1) for details.

=head1 SEE ALSO

L<DDB>(3p), L<dpt>(1)

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.


=cut
