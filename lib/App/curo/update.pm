package App::curo::update; our $VERSION = '0.01_01';
use strict;
use warnings;
use App::curo::Util;

sub order { 7 }

sub arg_spec {
    return ( [ "what=s", "ID or project name", { required => 1 } ], );
}

sub opt_spec { ( [ 'debug|d=s', 'Enable debugging output' ], ) }

sub require_order { 1 }

sub run {
    my ( $self, $opt ) = @_;
    my $db = find_db($opt);

    if ( $opt->what =~ m/^\d+$/ ) {
        my $type = $db->id2thread_type( $opt->what )
          || die "ID not found: " . $opt->what . "\n";

        if ( $type eq 'issue' ) {
            return $self->dispatch( 'update', $type, $opt->what, @ARGV );
        }
        elsif ( $type eq 'task' ) {
            return $self->dispatch( 'update', $type, $opt->what, @ARGV );
        }
        else {
            die "Can't update type: " . $type . "\n";
        }
    }
    return $self->dispatch( 'update', 'project', $opt->what, @ARGV );
}

1;
__END__

=head1 NAME

App::curo::update - Comment or modify something

=head1 SYNOPSIS

  ddb update ID

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
