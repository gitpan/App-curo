package App::curo; our $VERSION = '0.01_01';
use strict;
use warnings;
use App::curo::Util;

sub require_order { 1 }

sub arg_spec {
    return ( [ 'command=s', 'command to run', { required => 1 } ], );
}

sub run {
    my ( $self, $opt ) = @_;
    my $config = find_conf($opt);

    if ( !$opt->command ) {
        die $self->usage;
    }

    if ( my $alias = $config->{alias}->{ $opt->command } ) {
        return $self->dispatch(
            split( ' ', $alias ),
            @ARGV, $opt->{debug} ? ( '--debug', $opt->{debug} ) : (),
        );
    }
    die $self->usage;
}

1;
__END__

=head1 NAME

App::curo - Distributed Database Tool

=head1 SYNOPSIS

  curo COMMAND

=head1 DESCRIPTION

See L<ddb>(1) for details.

=head1 SEE ALSO

L<DDB::Cmd>(3p), L<ddb>(1)

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.


=cut
