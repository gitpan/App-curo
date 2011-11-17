package App::curo_sync; our $VERSION = '0.01_02';
use strict;
use warnings;
use Carp qw/confess/;
use File::Basename;
use Curo;
use Curo::Sync;
use SQL::DBx::Deploy;
use EV;
use AnyEvent;
use AnyEvent::Handle;
use JSON::XS;
use Try::Tiny;

use constant TIMEOUT => 5;

my $db;
my $dbh;
my $dbid;
my $from;
my $cv;
my $count;
my $j = JSON::XS->new->utf8->canonical;

sub opt_spec {
    return ( [ 'debug|d', 'debug mode' ], );
}

sub arg_spec {
    return (
        [ 'directory=s', 'location of curo repository', { required => 1 } ], );
}

sub run {
    my ( $self, $opt ) = @_;

    select STDERR;
    $| = 1;
    select STDOUT;
    $| = 1;

    $db = try {
        Curo->new( dir => $opt->{directory} );
    }
    catch {
        send_quit(
            from => basename($0) . ':' . $VERSION . ':0',
            err  => 500,
            msg  => 'Curo->new failed',
        );
        exit 1;
    };

    $dbh = $db->conn->dbh;
    $j = $j->pretty->canonical if $opt->debug;

    send_reset( from => basename($0) . ':' 
          . $VERSION . ':'
          . $db->last_deploy_id('Curo') );

    $cv = AnyEvent->condvar;

    my $hdl;
    $hdl = AnyEvent::Handle->new(
        fh      => \*STDIN,
        on_read => sub {
            $hdl->push_read( line => \&input );
        },
        timeout    => TIMEOUT,
        on_timeout => sub {
            my ($hdl) = @_;
            send_quit(
                err => 408,
                msg => 'Timeout',
            );
            $hdl->destroy;
            $cv->send;
        },
        on_eof => sub {
            send_quit(
                err => 400,
                msg => 'EOF received',
            );
            $hdl->destroy;
            $cv->send;
        },
        on_err => sub {
            my ( $hdl, $fatal, $m ) = @_;
            send_quit(
                err => 500,
                msg => $m,
            );
            $hdl->destroy;
            $cv->send;
        },
    );

    $cv->recv;
}

sub sendmsg {
    my $str = $j->encode( \@_ ) . "\n";
    print $str || die "print: $!";
    return;
}

sub send_reset {
    my $args = { @_, _ => 'reset' };

    sendmsg($args);
    $count = 0;
    $dbh->rollback if $db->conn->in_txn;
    $dbh->begin_work;
    return;
}

sub send_quit {
    my $args = { @_, _ => 'quit' };

    sendmsg($args);
    $dbh->rollback if $db && $db->conn->in_txn;
    return;
}

sub getmsg {
    my $line = shift;

    if ( my $ref = eval { $j->decode($line) } ) {
        if ( ref $ref ne 'ARRAY' ) {
            send_reset( err => 400, msg => 'ARRAY expected: ' . ref $ref );
            return;
        }

        my ( $header, @rest ) = @$ref;

        if ( ref $header ne 'HASH' ) {
            send_reset(
                err => 400,
                msg => 'ARRAY[HASH] expected: ' . ref $header
            );
            return;
        }

        return ( $header, @rest );
    }

    send_reset( err => 400, msg => 'Invalid JSON' );
    return;
}

sub input {
    my ( $hdl,    $line )  = @_;
    my ( $header, @other ) = getmsg($line);
    return unless $header;

    my $req = $header->{_} || '';

    $from ||= exists $header->{from} ? $header->{from} : undef;
    $from || return send_reset(
        err => 400,
        msg => 'Require from',
    );

    if ( $req eq 'want' ) {
        if ( $header->{path} ) {
            my $data = $db->_fetch_project_update_uuids( $header->{path} );
            sendmsg( { _ => 'have', path => $header->{path} }, $data );
        }
        elsif ( $header->{id} ) {
            send_reset( err => 501, msg => 'Not implemented' );
        }
        else {
            send_reset( err => 501, msg => 'Unknown want item' );
        }
    }
    elsif ( $req eq 'insert' ) {
        my $action = 'insert_' . $header->{type};
        if ( $db->can($action) ) {
            try {
                $db->$action(@other);
                $count++;
            }
            catch {
                send_reset( err => 500, err => $@ );
            };
        }
        else {
            send_reset( err => 501, msg => 'Not implemented:' . $action );
        }
    }
    elsif ( $req eq 'update' ) {
        my $action = 'insert_' . $header->{type} . '_update';
        if ( $db->can($action) ) {
            try {
                $db->$action(@other);
                $count++;
            }
            catch {
                send_reset( err => 500, err => $@ );
            };
        }
        else {
            send_reset( err => 501, msg => 'Not iplemented' );
        }
    }
    elsif ( $req eq 'commit' ) {
        try {
            $dbh->commit;
            send_reset( commit => $count );
        }
        catch {
            send_reset( err => 500, msg => $@ );
        };
    }
    elsif ( $req eq 'quit' ) {
        send_quit();
        $hdl->destroy;
        $cv->send;
    }
    else {
        send_reset( err => 501, msg => 'Not iplemented' );
    }
    return;
}

1;
__END__

=head1 NAME

App::curo_sync - Sync Server for curo

=head1 DESCRIPTION

See L<curo-sync>(1) for details.

=head1 SEE ALSO

L<curo>(1)

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

=cut
