package App::curo::new::project; our $VERSION = '0.01_02';
use strict;
use warnings;
use App::curo::Util;
use Curo;
use Term::Prompt;

sub opt_spec {
    return (
        [ "phase=s",     "Phase", { default => 'run' } ],
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
    return ( [ "name=s", "Project Name" ], );
}

sub run {
    my ( $self, $opt ) = @_;
    my $db = find_db($opt);

    $opt->{name} ||= prompt( 'x', "Name:", '', '' );

    my $orig_name = $opt->{name};
    my @names = split( '/', $opt->{name} );
    if ( @names > 1 ) {
        my $name = pop @names;
        my $path = join( '/', @names );

        check_project( $path, 1 );
        $opt->{parent} = $path;
        $opt->{name}   = $name;
    }

    if ( $opt->{ref_uuid} ) {
        $opt->{title} = "<remote project>";
    }
    else {
        $opt->{title} ||= "@ARGV" || prompt( 'X', "Title:", '', '' );
    }
    $opt->{title} ||= "@ARGV" || prompt( 'X', "Title:", '', '' ) || undef;
    $opt->{comment} ||= prompt_edit( name => 'Description', );

    #    $opt->{description} ||= prompt_edit( name => 'Description', );
    #    $opt->{comment} = "Project Created";

    print "New project: $orig_name <$opt->{thread_uuid}>\n"
      if $db->insert_project($opt);
}

1;
__END__

=head1 NAME

App::curo::new::project - insert a new project into the database

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
