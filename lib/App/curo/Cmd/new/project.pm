package App::curo::Cmd::new::project; our $VERSION = '0.0.2';
use strict;
use warnings;
use App::curo::Util;
use Curo;
use Term::Prompt;

sub run {
    my $opts   = shift;
    my $config = find_conf($opts);
    my $db     = find_db($opts);

    $opts->{lang}   ||= 'en';
    $opts->{email}  ||= $config->{user}->{email};
    $opts->{author} ||= $config->{user}->{name};
    $opts->{name}   ||= prompt( 'x', "Name:", '', '' ) || undef;

    die "fatal: project path already exists: $opts->{name}\n"
      if $db->path2project_id( $opts->{name} );

    my $path = $opts->{name};
    my @names = split( '/', $path );

    if ( @names > 1 ) {
        my $name = pop @names;
        my $parent_path = join( '/', @names );

        $opts->{parent_project_id} = check_project( $parent_path, 1 );
        $opts->{name} = $name;
    }
    else {
        $opts->{name} = $path;
    }

    $opts->{title} ||= prompt( 'x', "Title:", '', '' ) || undef;
    $opts->{comment} ||= prompt_edit( opts => $opts );

    if ( $db->insert_project($opts) ) {
        my $project = $db->path2project($path);
        printf( "Project created: %s (phase:%s)\n",
            $project->path, $project->phase );
    }
}

1;
__END__

=head1 NAME

App::curo::Cmd::new::project - insert a new project into the database

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
