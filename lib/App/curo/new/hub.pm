package App::curo::new::hub; our $VERSION = '0.01_02';
use strict;
use warnings;
use App::curo::Util;

sub arg_spec {
    return (
        [ "name=s",     "Name",     { required => 1 } ],
        [ "location=s", "Location", { required => 1 } ],
    );
}

sub opt_spec { ( [ 'debug|d=s', 'Enable debugging output' ] ) }

sub run {
    my ( $self, $opt ) = @_;
    my $db = find_db($opt);

    my $name = $opt->{name};

    print "Added hub: $name\n" if $db->insert_hub($opt);
    return;
}

1;
__END__

=head1 NAME

App::curo::new::hub - insert a hub into the database

=head1 SYNOPSIS

  dpt hubs ACTION

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
