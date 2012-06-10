package Curo::Sync::Server; our $VERSION = '0.0.2';
use strict;
use warnings;
use Log::Any qw/$log/;
use Moo;
use SQL::DB qw/sql_hex sql_lower/;

extends 'Curo::Sync';

sub accept {
    my $self = shift;
    my %args = (
        stdin  => undef,
        stdout => undef,
        @_,
    );

    $self->stdin( $args{stdin} );
    $self->stdout( $args{stdout} );

    $self->on_commit(
        sub {
            $self->init;
            $self->setup_request_handler;
        }
    );

    $self->init;
    $self->setup_request_handler;

    $self->send(
        {
            _      => 'hello',
            server => __PACKAGE__ . ':' . $VERSION,
            db     => $self->db->db_version
        }
    );

    return $self->cv->recv;
}

sub push_project {
    my $self   = shift;
    my $header = shift;

    my ( $projects, $threads ) = $self->db->srow(qw/projects threads/);

    my $p = $self->db->object(
        select     => [ $projects->hash, ],
        from       => $threads,
        inner_join => $projects,
        on         => $projects->id == $threads->id,
        where      => $threads->uuid == pack( 'H*', $header->{uuid} ),
    );

    if ($p) {
        my $str = 'project exists with hash: ' . $p->hash;
        return $self->error( $str, $str );
    }

    $self->send(
        {
            _    => 'pull',
            type => 'project',
            uuid => $header->{uuid},
        }
    );

    $self->_sync_project( $header->{uuid}, undef, $header->{hash} );

    return;
}

sub pull_project {
    my $self   = shift;
    my $header = shift;

    my ( $projects, $threads ) = $self->db->srow(qw/projects threads/);

    my $p = $self->db->object(
        select => [
            $projects->hash, sql_lower( sql_hex( $threads->uuid ) )->as('uuid'),
        ],
        from       => $projects,
        inner_join => $threads,
        on         => $threads->id == $projects->id,
        where      => $projects->id == $header->{id},
    );

    $self->send(
        {
            _    => 'push',
            type => 'project',
            hash => $p->hash,
            uuid => $p->uuid,
        }
    );

    $self->_sync_project( $p->uuid, $p->hash, undef );

    return;
}

sub setup_request_handler {
    my $self = shift;

    $self->rh->push_read(
        json => sub {
            my ($header) = $self->getmsg(@_);

            if ( $header->{_} eq 'quit' ) {
                $self->send( { _ => 'bye' } );
                $self->rh->destroy;
                $self->wh->on_drain(
                    sub {
                        shutdown $self->wh->fh, 1;
                        $self->wh->destroy;
                        $self->cv->send(1);
                    }
                );
            }
            elsif ( $header->{_} eq 'push' ) {
                return $self->error('missing type')
                  unless $header->{type};

                return $self->error('missing uuid')
                  unless $header->{uuid};

                return $self->push_project($header)
                  if $header->{type} eq 'project';

                $self->error( '', 'type unimplemented: ' . $header->{type} );
            }
            elsif ( $header->{_} eq 'pull' ) {

                return $self->error('missing thread')
                  unless $header->{thread};

                if ( $header->{thread} =~ m/^\d+$/ ) {
                    if ( my $type =
                        $self->db->id2thread_type( $header->{thread} ) )
                    {
                        my $method = 'pull_' . $type;
                        return $self->$method($header);
                    }
                }
                elsif ( my $id =
                    $self->db->path2project_id( $header->{thread} ) )
                {
                    $header->{id} = $id;
                    return $self->pull_project($header);
                }

                $self->error( '', 'not found: ' . $header->{id} );
            }
            elsif ( $header->{_} eq 'sync' ) {
                if ( $header->{uuid} ) {    # a push or sync request
                    my ( $projects, $threads ) =
                      $self->db->srow(qw/projects threads/);

                    my $p = $self->db->fetch1(
                        select     => [ $projects->hash, ],
                        from       => $threads,
                        inner_join => $projects,
                        on         => $projects->id == $threads->id,
                        where      => $threads->uuid ==
                          pack( 'H*', $header->{uuid} ),
                    );

                    $self->send(
                        {
                            _    => 'sync',
                            type => 'project',
                            uuid => $header->{uuid},
                            hash => $p ? $p->hash : undef,
                        }
                    );

                    $self->_sync_project( $header->{uuid},
                        $p ? $p->hash : undef,
                        $header->{hash} );
                }
                elsif ( $header->{path} ) {    # we have a pull request
                    my ( $projects, $threads ) =
                      $self->db->srow(qw/projects threads/);

                    my $p = $self->db->fetch1(
                        select => [
                            sql_lower( sql_hex( $threads->uuid ) )->as('uuid'),
                            $projects->hash,
                        ],
                        from       => $threads,
                        inner_join => $projects,
                        on         => $projects->id == $threads->id,
                        where      => $projects->path == $header->{path},
                    );

                    if ( !$p ) {
                        my $str = 'project path unkown: ' . $header->{path};
                        return $self->error( $str, $str );
                    }

                    $self->send(
                        {
                            _    => 'sync',
                            type => 'project',
                            path => $header->{path},
                            uuid => $p->uuid,
                            hash => $p->hash,
                        }
                    );

                    $self->_sync_project( $p->uuid, $p->hash, undef );
                }
                else {
                    my $str = 'missing uuid';
                    $self->error( $str, $str );
                }
            }
            else {
                my $str = 'unexpected or invalid header: ' . $header->{_};
                $self->error( $str, $str );
            }
            return;
        }
    );
}

1;
