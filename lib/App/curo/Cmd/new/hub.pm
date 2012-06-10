package App::curo::Cmd::new::hub; our $VERSION = '0.0.2';
use strict;
use warnings;
use App::curo::Util;
use Cwd qw/abs_path/;
use Path::Class;
use Term::Prompt;

sub run {
    my $opts   = shift;
    my $config = find_conf($opts);
    my $db     = find_db($opts);

    $opts->{lang}     ||= 'en';
    $opts->{email}    ||= $config->{user}->{email};
    $opts->{author}   ||= $config->{user}->{name};
    $opts->{alias}    ||= prompt( 'x', "Alias:", '', '' );
    $opts->{location} ||= prompt( 'x', "Location:", '', '' );
    $opts->{location} = dir( $opts->{location} )->absolute || $opts->{location};

    die "fatal: hub reference already exists: $opts->{reference}\n"
      if $db->name2hub( $opts->{alias} );

    die "fatal: hub location already exists: $opts->{location}\n"
      if $db->location2hub( $opts->{location} );

    print "Hub reference: $opts->{alias} => $opts->{location}\n"
      if $db->insert_hub($opts);
    return;
}

1;
__END__

=head1 NAME

App::curo::Cmd::new::hub - insert a hub into the database

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
