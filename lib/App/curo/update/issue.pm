package App::curo::update::issue; our $VERSION = '0.01_01';
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
    return ( [ "issue_id=s", "ID", { required => 1 } ], );
}

sub run {
    my ( $self, $opt ) = @_;
    my $db = find_db($opt);

    $db->id2thread_type( $opt->{issue_id} )
      || die "ID not found: " . $opt->id . "\n";

    $opt->{comment} ||= prompt_edit( name => 'Comment', );

    print "Updated issue: $opt->{issue_id}\n"
      if $db->insert_issue_update($opt);

}

1;
__END__

=head1 NAME

App::curo::update::issue - comment or modify an issue

=head1 SYNOPSIS

  dpt issues update <t_id>

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
