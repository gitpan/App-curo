package App::curo; our $VERSION = '0.01_02';
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

App::curo - distributed project management database

=head1 SYNOPSIS

  curo COMMAND [...]

=head1 DESCRIPTION

Curo is a scalable, distributed project management system designed to
perform independent of location or connectivity status. Don't let that
scare you away though; Curo has also been designed to be simple to use
and works just as well for standalone projects.

Every Curo database is a fully-functional repository of state and
history, easily modified without needing access to a central server.
The databse schema allows for the creation and efficient querying of
tasks, issues, and nested (hierarchical) projects.

The system is truly distributed in the sense that status updates and
comments are tracked globally. Tasks and issues can be synchronized
across projects hosted on different repositories. Entire projects can
be pushed or pulled as sub-elements of other projects. These key
features, when used widely, allow individuals to focus on their own
view of projects' activities and to combine them together in unique
ways.

See L<curo>(1) for details.

=head1 SEE ALSO

L<Curo>

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

=cut
