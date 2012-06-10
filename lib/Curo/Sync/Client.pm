package Curo::Sync::Client; our $VERSION = '0.0.2';
use strict;
use warnings;
use Carp qw/confess/;
use Log::Any qw/$log/;
use Moo;
use MooX::Types::MooseLike::Base qw/:all/;
use Sys::Cmd qw/spawn/;

extends 'Curo::Sync';

has hub_db => (
    is  => 'rw',
    isa => Defined,
);

has hub_server => (
    is  => 'rw',
    isa => Defined,
);

has rcmd => (
    is  => 'rw',
    isa => Object,
);

has on_connect => (
    is  => 'rw',
    isa => CodeRef,
);

has on_disconnect => (
    is  => 'rw',
    isa => CodeRef,
);

sub connect {
    my $self     = shift;
    my $location = shift;

    if ( $location =~ m!^ssh://(.+?):(.+)! ) {
        $self->rcmd( spawn( 'ssh', $1, 'curo-sync', $2 ) );
    }
    else {

        # assume a local repository
        $self->rcmd(
            spawn(
                'curo-sync', $log->is_debug ? ( '-d', 'Curo' ) : (),
                $location
            )
        );
    }

    $self->on_shutdown(
        sub {
            $self->rcmd->wait_child;
        }
    );

    $self->stderr( $self->rcmd->stderr );
    $self->stdout( $self->rcmd->stdin );
    $self->stdin( $self->rcmd->stdout );

    $self->init;

    $self->eh->on_read(
        sub {
            $self->eh->push_read(
                line => sub {
                    my ( $hdl, $line ) = @_;
                    $log->error( 'curo-sync: ' . $line );
                }
            );
        }
    );

    $self->rh->push_read(
        json => sub {
            my ($header) = $self->getmsg(@_);
            return unless $header;

            if (    $header->{_} eq 'hello'
                and $header->{db}
                and $header->{server} )
            {
                $self->rh->on_read(undef);
                $self->hub_db( $header->{db} );
                $self->hub_server( $header->{server} );

                if ( my $sub = $self->on_connect ) {
                    $sub->();
                }
                else {
                    $self->cv->send(1);
                }
            }
            else {
                $self->error('invalid server hello');
            }
        }
    );

    return $self->cv->recv;
}

sub push_project {
    my $self = shift;
    my $opts = shift;

    my $p = $self->db->id2project( $opts->{id} )
      || confess "project_id not found: $opts->{id}";

    $self->init;
    $self->dbh->begin_work;
    $opts->{push_to} = $opts->{location};
    $self->db->update_project($opts);

    # Any kind of AnyEvent event can potentially disconnect us. So if
    # we call push_read() on a handle before we do anything else we can
    # avoid rh becoming undefined underneath us.
    $self->rh->push_read(
        json => sub {
            my ($header) = $self->getmsg(@_);
            return unless $header;

            if (    $header->{_} eq 'pull'
                and $header->{type} eq 'project'
                and $header->{uuid} eq $p->uuid )
            {
                $self->_sync_project( $p->uuid, $p->hash, undef );
            }
            else {
                my $str = 'expected pull got: ' . $header->{_};
                $self->error( $str, $str );
            }
        }
    );

    $self->send(
        {
            _    => 'push',
            type => 'project',
            uuid => $p->uuid,
            hash => $p->hash,
        }
    );

    return if $self->on_commit;
    return $self->cv->recv;
}

sub sync_project {
    my $self = shift;
    my $opts = shift;

    my $p = $self->db->id2project( $opts->{id} )
      || confess "project_id not found: $opts->{id}";

    $self->init;
    $self->dbh->begin_work;

    $self->rh->push_read(
        json => sub {
            my ($header) = $self->getmsg(@_);
            return unless $header;

            if (    $header->{_} eq 'sync'
                and $header->{type} eq 'project'
                and $header->{uuid} eq $p->uuid
                and $header->{hash} )
            {
                $self->_sync_project( $p->uuid, $p->hash, $header->{hash} );
            }
            else {
                my $str = 'expected sync got: ' . $header->{_};
                $self->error( $str, $str );
            }
        }
    );

    $self->send(
        {
            _    => 'sync',
            type => 'project',
            uuid => $p->uuid,
            hash => $p->hash,
        }
    );

    return if $self->on_commit;
    return $self->cv->recv;
}

sub pull_project {
    my $self = shift;
    my $opts = shift;

    $self->init;

    # Any kind of AnyEvent event can potentially disconnect us. So if
    # we call push_read() on a handle before we do anything else we can
    # avoid rh becoming undefined underneath us.
    $self->rh->push_read(
        json => sub {
            my ($header) = $self->getmsg(@_);
            return unless $header;

            if (    $header->{_} eq 'push'
                and $header->{type} eq 'project'
                and $header->{uuid}
                and $header->{hash} )
            {
                if ( my $id = $self->db->uuid2id( $header->{uuid} ) ) {
                    my $str = 'id already exists locally: ' . $id;
                    return $self->error( $str, $str );
                }

                $self->_sync_project( $header->{uuid}, undef, $header->{hash} );
            }
            else {
                my $str = 'expected push got: ' . $header->{_};
                $self->error( $str, $str );
            }
        }
    );

    $self->send(
        {
            _      => 'pull',
            thread => $opts->{thread},
        }
    );

    return if $self->on_commit;
    return $self->cv->recv;
}

sub disconnect {
    my $self = shift;
    my %opts = (@_);

    $self->init;

    $self->rh->push_read(
        json => sub {
            my ($header) = $self->getmsg(@_);
            return unless $header;

            if ( $header->{_} eq 'bye' ) {

                # don't really care
            }

            $self->rh->destroy;
            $self->eh->destroy if $self->eh;
            $self->rcmd->close;
            $self->rcmd->wait_child;

            if ( my $sub = $self->on_disconnect ) {
                $sub->();
            }
            else {
                $self->cv->send(1);
            }
        }
    );

    $self->send( { _ => 'quit' } );

    return if $self->on_disconnect;
    return $self->cv->recv;
}

1;
