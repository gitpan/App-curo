package App::curo::list; our $VERSION = '0.01_01';
use strict;
use warnings;
use App::curo::Util;

sub order { 5 }

sub arg_spec {
    return ( [ "project=s", "what to list" ], );
}

sub opt_spec { ( [ 'debug|d=s', 'Enable debugging output' ], ) }

sub run {
    my ( $self, $opt ) = @_;
    my $db = find_db($opt);

    if ( $opt->project ) {
        $db->path2project_id( $opt->project )
          || die "fatal: unknown project: $opt->{project}\n";
    }

    my $data = $db->arrayref_list_all($opt);

    return print "0 entries (use \"new\" to create)\n" unless @$data;

    start_pager;

    my $x    = render_table( ' r  l  l ', undef, $data );
    my $rs   = color('reset');
    my $dark = color('bold');

    $x =~ s/^(\s+)\.\s*(.*?)\s*$/$dark$2$rs/m;
    $x =~ s/^(\s+)\.\s*(.*?)\s*$/\n$dark$2$rs/gm;

    print $x;

    end_pager;

    return;
}

1;
__END__

=head1 NAME

App::curo::list - List project tasks and issues

=head1 SYNOPSIS

  curo list [<what>]

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
