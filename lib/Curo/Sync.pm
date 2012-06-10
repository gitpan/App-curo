package Curo::Sync; our $VERSION = '0.0.2';
use strict;
use warnings;
use AnyEvent;
use AnyEvent::Handle;
use Carp qw/confess/;
use JSON::XS;
use Log::Any qw/$log/;
use Moo;
use MooX::Types::MooseLike::Base qw/:all/;
use SQL::DB qw/:all/;
use Try::Tiny;

has db => (
    is       => 'ro',
    isa      => Object,
    required => 1,
);

has dbh => (
    is  => 'rw',
    isa => Object,
);

has stdin => (
    is      => 'rw',
    isa     => FileHandle,
    trigger => sub {
        my $self = shift;
        $self->_build_rh;
    },
);

has stdout => (
    is      => 'rw',
    isa     => FileHandle,
    trigger => sub {
        my $self = shift;
        $self->_build_wh;
    },
);

has stderr => (
    is      => 'rw',
    isa     => FileHandle,
    trigger => sub {
        my $self = shift;
        $self->_build_eh;
    },
);

has rh => (
    is       => 'rw',
    init_arg => undef,
);

has wh => (
    is       => 'rw',
    init_arg => undef,
);

has eh => (
    is       => 'rw',
    init_arg => undef,
);

has timeout => (
    is      => 'rw',
    isa     => Int,
    default => sub { 15 },
);

has json => (
    is  => 'rw',
    isa => Object
);

has cv => (
    is  => 'rw',
    isa => Object
);

has errstr => (
    is      => 'rw',
    trigger => sub {
        my $self = shift;
        $log->error( $self->errstr ) if $self->errstr;
    },
);

has id => ( is => 'rw' );

has temp_table => ( is => 'rw' );

has iter => ( is => 'rw' );

has expecting => ( is => 'rw', isa => Int );

has sent_all => ( is => 'rw', isa => Int );

has recv_all => ( is => 'rw', isa => Int );

has on_send_update => (
    is  => 'rw',
    isa => CodeRef,
);

has sent_updates => (
    is      => 'rw',
    isa     => Int,
    trigger => sub {
        my $self = shift;

        # no need to call when setting to 0
        return unless $_[0];
        $self->on_send_update->() if $self->on_send_update;
    },
);

has on_recv_update => (
    is  => 'rw',
    isa => CodeRef,
);

has recv_updates => (
    is      => 'rw',
    isa     => Int,
    trigger => sub {
        my $self = shift;

        # no need to call when setting to 0
        return unless $_[0];
        $self->on_recv_update->() if $self->on_recv_update;
    },
);

has comparing => (
    is      => 'rw',
    isa     => Str,
    trigger => sub {
        my $self = shift;
        $self->on_comparing_update->() if $self->on_comparing_update;
    },
);

has on_run => (
    is  => 'rw',
    isa => CodeRef,
);

has on_comparing_update => (
    is  => 'rw',
    isa => CodeRef,
);

has on_commit => (
    is  => 'rw',
    isa => CodeRef,
);

has on_shutdown => (
    is  => 'rw',
    isa => CodeRef,
);

has on_cleanup => (
    is      => 'rw',
    isa     => CodeRef,
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->cv->send( $self->errstr ? 0 : 1 );
    },
);

sub BUILD {
    my $self = shift;
    $self->dbh( $self->db->conn->dbh );
}

sub _build_rh {
    my $self = shift;

    $self->rh(
        AnyEvent::Handle->new(
            fh         => $self->stdin,
            timeout    => $self->timeout,
            json       => $self->json,
            on_timeout => sub {
                my $hdl = shift;
                $hdl->destroy;
                $self->error('read timeout');
            },
            on_eof => sub {
                my $hdl = shift;
                $hdl->destroy;
                $self->error('read EOF');
            },
            on_error => sub {
                my ( $hdl, $fatal, $m ) = @_;
                $hdl->destroy;
                $self->error( 'read error: ' . $m );
            },
        )
    );
}

sub _build_wh {
    my $self = shift;

    $self->wh(
        AnyEvent::Handle->new(
            fh       => $self->stdout,
            autocork => 1,
            json     => $self->json,
            on_error => sub {
                my ( $hdl, $fatal, $m ) = @_;
                $hdl->destroy;

                # only log here, hope to get error message from the rh.
                $log->error( 'stdout error: ' . $m );
            },
        )
    );
}

sub _build_eh {
    my $self = shift;

    return unless $self->stderr;
    return $self->eh(
        AnyEvent::Handle->new(
            fh       => $self->stderr,
            on_error => sub {
                my ( $hdl, $fatal, $m ) = @_;
                $hdl->destroy;

                # only log here, hope to get error message from the rh.
                $log->error( 'stderr error: ' . $m );
            },
        )
    );
}

sub init {
    my $self = shift;
    my %args = @_;

    $self->errstr('');
    $self->expecting(0);
    $self->comparing('');
    $self->sent_updates(0);
    $self->recv_updates(0);
    $self->sent_all(0);
    $self->recv_all(0);

    $self->json( JSON::XS->new->utf8 ) unless $self->json;

    $self->cv( AnyEvent->condvar ) unless ( eval { !$self->cv->ready } );

    return;
}

sub send {
    my $self = shift;
    my $ref  = \@_;

    $log->debugf( 'send: %s', $self->json->canonical->pretty->encode($ref) )
      if $log->is_debug;

    $self->wh->push_write( json => $ref );
    $self->wh->push_write("\012");

    return;
}

sub getmsg {
    my $self = shift;
    my ( $hdl, $ref ) = @_;

    $log->debugf( 'recv: %s', $self->json->canonical->pretty->encode($ref) )
      if $log->is_debug;

    my ( $header, @rest ) = @$ref;

    unless ( ( ref $header eq 'HASH' ) && $header->{_} ) {
        $self->error( 'missing/invalid header', 'missing/invalid header' );
    }

    if ( $header->{_} eq 'error' ) {
        $self->error( 'received error: ' . $header->{msg} );
    }

    return ( $header, @rest );
}

sub error {
    my $self      = shift;
    my $m         = shift || 'unknown error';
    my $send      = shift;
    my $update_id = shift;

    $self->errstr($m);
    $self->iter->finish if $self->iter;
    $self->dbh->rollback unless $self->dbh->{AutoCommit};

    if ( !$self->wh->destroyed ) {

        if ($send) {
            $self->send(
                {
                    _         => 'error',
                    msg       => $send,
                    update_id => $update_id,
                },
                @_
            );
        }

        $self->wh->on_drain(
            sub {
                eval { shutdown $self->wh->fh, 1 };
                eval { $self->wh->fh->close };
                $self->on_shutdown->() if $self->on_shutdown;
                $self->wh->destroy;
                $self->cv->send(0);
            }
        );

        return;
    }

    $self->cv->send(0);
    return;
}

sub _cleanup {
    my $self = shift;

    $self->dbh->do( 'DROP TABLE IF EXISTS ' . $self->temp_table )
      if $self->temp_table;

    if ( $self->db->conn->in_txn ) {
        if ( $self->errstr ) {
            $self->dbh->rollback;
        }
        else {
            $self->dbh->commit;
        }
    }

    $self->rh->destroy if $self->rh;
    $self->wh->destroy if $self->wh;
    $self->eh->destroy if $self->eh;

    $self->stdout->close;
    $self->stdin->close;
    $self->stderr->close if $self->stderr;

    $self->on_cleanup->() if $self->on_cleanup;
    return;
}

sub compare_get {
    my $self    = shift;
    my $compare = shift;
    my $here    = shift;

    $self->rh->push_read(
        json => sub {
            my ( $header, $there ) = $self->getmsg(@_);
            return if $header->{_} eq 'error';

            if ( $header->{_} ne 'map' ) {
                my $str = 'expected map';
                return $self->error( $str, $str );
            }
            elsif ( !exists $header->{prefix} ) {
                my $str = 'missing prefix';
                return $self->error( $str, $str );
            }
            elsif ( $compare ne $header->{prefix} ) {
                my $str = sprintf( 'wrong prefix. want %s have %s',
                    $compare, $header->{prefix} );
                return $self->error( $str, $str );
            }
            $self->expecting( $self->expecting - 1 );
            $self->comparing($compare);

            my @next;
            my @missing;

            my $temp_table = $self->db->irow( $self->temp_table );
            my ( $thread_updates, $project_threads, $projects_tree ) =
              $self->db->srow(
                qw/thread_updates project_threads projects_tree /);

            my $where;

            while ( my ( $k, $v ) = each %$here ) {
                if ( !exists $there->{$k} ) {
                    push( @missing, $k );
                }
                elsif ( $there->{$k} ne $v ) {
                    push( @next, $k );

                    #                    $next{$k} = [ @$compare, $k ];
                }
            }

            if (@missing) {
                my $where;
                foreach my $miss (@missing) {

              #                    my $slots = join('', @$compare, $miss) . '%';
                    $where =
                        $where
                      ? $where 
                      . OR
                      . $thread_updates->slots->like( $miss . '%' )
                      : $thread_updates->slots->like( $miss . '%' );
                }
                $self->db->do(
                    insert_into => $temp_table->('id'),
                    select      => [ $thread_updates->update_id ],
                    from        => $thread_updates,
                    inner_join  => $project_threads,
                    on          => $project_threads->thread_id ==
                      $thread_updates->thread_id,
                    inner_join => $projects_tree,
                    on =>
                      ( $projects_tree->child == $project_threads->project_id )
                      . AND
                      . ( $projects_tree->parent == $self->id ),
                    where => $where,
                );
            }

            $log->debugf( 'next %s and expecting %d', \@next,
                $self->expecting );
            return $self->run unless @next or $self->expecting;

            foreach my $k ( sort @next ) {
                $self->compare($k);
            }
        }
    );
}

sub compare {
    my $self    = shift;
    my $compare = shift;
    my $id      = $self->id;
    my $temp    = $self->temp_table;

    #    if (!$ptp->can($s)) {
    #        return $self->error('full sync not implemented yet');
    #    }

    my ( $threads, $ptp ) = $self->db->srow(qw/threads project_tree_prefix/);

    my @refs = $self->db->arrays(
        select => [ $ptp->slot, $ptp->hash ],
        from   => $ptp,
        where  => ( $ptp->project_id == $self->id ) 
          . AND
          . $ptp->slot->like( $compare . '_' ),
    );

    my $here = { map { $_->[0] => $_->[1] } @refs };

    $self->expecting( $self->expecting + 1 );
    $self->compare_get( $compare, $here );
    $self->send( { _ => 'map', prefix => $compare }, $here );
    return;
}

sub sync_full {
    my $self = shift;

    my ( $threads1, $projects_tree, $project_threads, $threads,
        $thread_updates ) = $self->db->srow(
        qw/threads projects_tree project_threads threads thread_updates/);

    $self->db->do(
        insert_into => $self->temp_table,
        select      => $thread_updates->update_id,
        from        => $projects_tree,
        inner_join  => $project_threads,
        on          => $project_threads->project_id == $projects_tree->child,
        inner_join  => $threads,
        on          => $threads->id == $project_threads->thread_id,
        inner_join  => $thread_updates,
        on          => $thread_updates->thread_id == $threads->id,
        where       => $projects_tree->parent == $self->id,
    );

    $self->run;
    return;
}

sub get_gotupdates {
    my $self = shift;

    $self->rh->timeout_reset;
    $self->rh->timeout( $self->timeout );

    $self->rh->push_read(
        json => sub {
            my ( $header, @rest ) = $self->getmsg(@_);
            return if $header->{_} eq 'error';

            if ( $header->{_} ne 'gotupdates' ) {
                return $self->error(
                    'expected gotupdates but got ' . $header->{_},
                    'expected gotupdates' );
            }
            elsif ( $header->{count} != $self->sent_updates ) {
                my $str =
                    'sent_updates mismatch: sent: '
                  . $self->sent_updates
                  . ' gotupdates: '
                  . $header->{count};
                return $self->error( $str, $str );
            }

            $self->commit;
        }
    );

    $self->send(
        {
            _     => 'gotupdates',
            count => $self->recv_updates
        }
    );
}

sub commit {
    my $self = shift;

    $self->dbh->do( 'DROP TABLE ' . $self->temp_table );
    $self->dbh->commit;

    $self->rh->push_read(
        json => sub {
            my ( $header, @rest ) = $self->getmsg(@_);
            return if $header->{_} eq 'error';

            if ( $header->{_} ne 'commit' ) {
                my $str = 'no commit, you must be kidding me';
                return $self->error( $str, $str );
            }

            if ( my $sub = $self->on_commit ) {
                return $sub->();
            }
            $self->cv->send(1);
        }
    );

    $self->send( { _ => 'commit' } );
}

sub run {
    my $self = shift;

    $self->on_run->() if $self->on_run;

    my (
        $temptable,       $threads,         $thread_updates,
        $thread_updates2, $project_updates, $threads2,
        $task_updates,    $issue_updates,   $project_states
      )
      = $self->db->srow(
        $self->temp_table, qw/threads thread_updates
          thread_updates project_updates threads task_updates
          issue_updates project_states/
      );

    my $iter = $self->db->iter(
        select => [
            sql_case(
                when => $thread_updates2->update_id->is_null,
                then => undef,
                else => sql_lower( sql_hex( $threads->uuid ) ),
              )->as('uuid'),
            sql_case(
                when => $thread_updates2->update_uuid->is_not_null,
                then => sql_lower( sql_hex( $thread_updates2->update_uuid ) ),
                else => undef,
              )->as('parent_update_uuid'),
            $threads->thread_type->as('_type'),
            $thread_updates->update_id,
            $thread_updates->email,
            $thread_updates->author,
            $thread_updates->push_to,
            $thread_updates->title,
            $thread_updates->comment,
            $thread_updates->mtime,
            $thread_updates->mtimetz,
            sql_case(
                when => $threads2->uuid->is_not_null,
                then => sql_lower( sql_hex( $threads2->uuid ) ),
                else => undef,
              )->as('parent_project_uuid'),
            $project_updates->name,
            $project_states->state->as('phase'),
            $project_updates->add_kind,
            $project_updates->add_state,
            $project_updates->add_status,
            $project_updates->add_rank,
            $project_updates->add_def,
            $project_states->state,
        ],
        from       => $temptable,
        inner_join => $thread_updates,
        on         => $thread_updates->update_id == $temptable->id,
        left_join  => $thread_updates2,
        on => $thread_updates2->update_id == $thread_updates->parent_update_id,
        inner_join => $threads,
        on         => $threads->id == $thread_updates->thread_id,
        left_join  => $project_updates,
        on         => $project_updates->update_id == $thread_updates->update_id,
        left_join  => $threads2,
        on         => $threads2->id == $project_updates->parent_id,
        left_join  => $issue_updates,
        on         => $issue_updates->update_id == $thread_updates->update_id,
        left_join  => $task_updates,
        on         => $task_updates->update_id == $thread_updates->update_id,
        left_join  => $project_states,
        on         => $project_states->id->in(
            $project_updates->phase_id, $task_updates->state_id,
            $issue_updates->state_id,
        ),
        order_by => [ $thread_updates->update_id->asc ],
    );

    $self->iter($iter);

    $self->wh->on_drain(
        sub {
            if ( my $ref = $self->iter->hash ) {
                defined $ref->{$_} or delete $ref->{$_} for keys %$ref;

                my $type = delete $ref->{_type};

                $self->send(
                    {
                        _         => 'update',
                        type      => $type,
                        update_id => delete $ref->{update_id},
                    },
                    $ref
                );

                $self->sent_updates( $self->sent_updates + 1 );
            }
            else {
                $self->wh->on_drain(undef);
                $self->iter(undef);
                $self->sent_all(1);
                $self->send( { _ => 'endupdates' } );

                return unless $self->recv_all;
                return $self->get_gotupdates;
            }
        }
    );

    $self->rh->on_read(
        sub {
            $self->rh->push_read(
                json => sub {
                    my ( $header, $arg ) = $self->getmsg(@_);
                    return if $header->{_} eq 'error';

                    if ( $header->{_} eq 'update' ) {
                        my $action = 'import_' . $header->{type} . '_update';
                        my $ref;
                        while ( my ( $k, $v ) = each %$arg ) {
                            $ref->{$k} = $k =~ m/uuid$/ ? pack( 'H*', $v ) : $v;
                        }
                        if ( $self->db->can($action) ) {
                            my $result = try {
                                $self->db->$action($ref);
                                $self->recv_updates( $self->recv_updates + 1 );
                            }
                            catch {
                                $self->rh->on_read(undef);
                                $self->error( $_, 'update failed',
                                    $header->{update_id}, $arg );
                            };
                        }
                        else {
                            $self->error(
                                'not implemented: ' . $action,
                                'not implemented: ' . $action
                            );
                        }
                    }
                    elsif ( $header->{_} eq 'endupdates' ) {
                        $self->rh->on_read(undef);
                        $self->rh->timeout(0);
                        $self->recv_all(1);

                        return unless $self->sent_all;
                        return $self->get_gotupdates;

                    }
                    else {
                        my $str =
                          'expected endupdates/insert/update/commit not:'
                          . $header->{_};
                        $self->error( $str, $str );
                    }
                }
            );
        }
    );

}

sub _sync_project {
    my $self        = shift;
    my $uuid        = shift;
    my $hash        = shift;
    my $remote_hash = shift;

    # Create temporary database
    my $temp = 't' . substr( $uuid, int( rand( length($uuid) - 8 ) ), 8 );

    $self->dbh->begin_work if $self->dbh->{AutoCommit};
    $self->dbh->do("CREATE TEMPORARY TABLE $temp(id integer)");

    $self->temp_table($temp);

    if ($hash) {
        $self->id( $self->db->uuid2id($uuid) );

        if ( !$remote_hash ) {    # a full push
            $self->sync_full;
        }
        elsif ( $remote_hash eq $hash ) {

            # a perfect match but let sync_run clean up for us anyway
            $self->run;
        }
        else {                    # a partial sync
            $self->compare('');
        }
    }
    elsif ($remote_hash) {        # a full pull
        $self->run;
    }
    else {
        my $str = 'no hash and no remote_hash - wtf?!?';
        $self->error( $str, $str );
    }

    return;
}

1;

