package App::curo::Cmd::list; our $VERSION = '0.0.2';
use strict;
use warnings;
use OptArgs qw/dispatch/;

sub run {
    my $opts = shift;
    return dispatch(qw/run App::curo::Cmd list project-threads/);
}

1;
__END__

=head1 NAME

App::curo::Cmd::list - List project threads

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
