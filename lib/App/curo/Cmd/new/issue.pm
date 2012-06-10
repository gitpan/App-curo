package App::curo::Cmd::new::issue; our $VERSION = '0.0.2';
use strict;
use warnings;
use App::curo::Util;
use Term::Prompt;

sub run {
    my $opts   = shift;
    my $config = find_conf($opts);
    my $db     = find_db($opts);

    $opts->{lang}    ||= 'en';
    $opts->{email}   ||= $config->{user}->{email};
    $opts->{author}  ||= $config->{user}->{name};
    $opts->{title}   ||= prompt( 'x', "Title:", '', '' );
    $opts->{project} ||= $db->one_and_only_project_path
      || prompt( 'x', "Project:", '', '' );

    $opts->{project_id} = check_project( delete $opts->{project} );
    $opts->{comment} ||= prompt_edit( opts => $opts );

    printf( "Issue created: %d <%s>\n", $opts->{id}, short( $opts->{uuid} ) )
      if $db->insert_issue($opts);

}

1;
__END__

=head1 NAME

App::curo::Cmd::new::issue - insert a new issue into the database

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
