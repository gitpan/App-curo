package App::curo::Cmd::upgrade; our $VERSION = '0.0.2';
use strict;
use warnings;
use App::curo::Util;
use Curo;
use Term::Prompt;

sub run {
    my $opts = shift;

    add_debug( $opts->{debug} );

    my $db = $opts->{hub} ? Curo->new( dir => $opts->{hub} ) : find_db($opts);

    my ( $prev, $now ) = $db->upgrade;

    if ( $now == 0 ) {
        printf( "Database initialised (v%s) in %s/\n", $now, $db->dir );
        return;
    }
    elsif ( $now > $prev ) {
        printf( "Database upgraded (v%s-v%s) in %s/\n", $prev, $now, $db->dir );
    }
    elsif ( $now < $prev ) {
        printf( "Database TRAVELLED FORWARD IN TIME! (v%s-v%s) in %s/\n",
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

App::curo::Cmd::upgrade - Upgrade a repository database

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
