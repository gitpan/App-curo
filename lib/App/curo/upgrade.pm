package App::curo::upgrade; our $VERSION = '0.01_02';
use strict;
use warnings;
use File::Spec::Functions qw/rel2abs catdir/;
use Term::Prompt;
use Curo;
use SQL::DBx::Deploy;
use App::curo::Util;

sub order { 20 }

sub opt_spec {
    return (
        [ "hub",       "Initialize a database 'hub'" ],
        [ 'debug|d=s', 'Enable debugging output' ],
    );
}

sub arg_spec {
    return ( [ "directory=s", "location of the database or hub", ], );
}

sub run {
    my ( $self, $opt ) = @_;

    add_debug( $opt->debug );

    $opt->{directory} ||= '.' if $opt->hub;
    $opt->{directory} ||= '.curo';

    my $db = Curo->new(
        dir => $opt->directory,
        hub => $opt->hub,
    );

    print $opt->hub ? 'Hub ' : '';

    my ( $prev, $now ) = $db->upgrade;

    print $opt->hub ? 'Hub ' : '';

    if ( $now == 0 ) {
        printf( "Database initialized (%s) in %s/\n", $now, $db->dir );
        return;
    }
    elsif ( $now > $prev ) {
        printf( "Database upgraded (%s-%s) in %s/\n", $prev, $now, $db->dir );
    }
    elsif ( $now < $prev ) {
        printf( "Database TRAVELLED FORWARD IN TIME! (%s-%s) in %s/\n",
            $prev, $now, $db->dir );
    }
    else {
        printf( "Database remains at v%s in %s/\n", $now, $db->dir );
    }
    return;
}

1;
__END__

=head1 NAME

App::curo::upgrade - Upgrade existing database or hub

=head1 SYNOPSIS

  curo init

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
