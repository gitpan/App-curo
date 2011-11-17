package App::curo::new; our $VERSION = '0.01_02';
use strict;
use warnings;
use App::curo::Util;

sub order { 4 }

sub arg_spec {
    return ( [ "type=s", "the kind of sometime to create", { required => 1 } ],
    );
}

1;
__END__

=head1 NAME

App::curo::new - Create something new

=head1 SYNOPSIS

  ddb issues

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
