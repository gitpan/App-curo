package Curo::Sync; our $VERSION = '0.01_01';
use strict;
use warnings;
use Moo::Role;
use Carp qw/confess/;
use Log::Any qw/$log/;
use File::Spec::Functions qw/catfile rel2abs/;
use File::Temp qw/mktemp/;
use Try::Tiny;
use SQL::DB qw/:all/;
use SQL::DBx::Deploy;
use JSON::XS;
use AnyEvent;
use AnyEvent::Handle;
use Sys::Cmd qw/spawn/;
use File::Basename;
use constant TIMEOUT => 5;

has connected => ( is => 'rw', );
has rcmd      => ( is => 'rw', );
has timeout   => ( is => 'rw', );
has rversion  => ( is => 'rw', );
has rdbid     => ( is => 'rw', );
has json => ( is => 'rw', default => sub { JSON::XS->new->utf8->canonical } );
has connect_cv => ( is => 'rw', );
has cv         => ( is => 'rw', );
has err        => ( is => 'rw', );
has lparent    => ( is => 'rw', );
has rparent    => ( is => 'rw', );
has rpath      => ( is => 'rw', );
has rh         => ( is => 'rw', );
has wh         => ( is => 'rw', );
has here       => ( is => 'rw', );
has there      => ( is => 'rw', );
has temp_table => ( is => 'rw', );
has pushed     => ( is => 'rw', );

sub _fetch_project_update_uuids {
    my $self  = shift;
    my @names = @_;

    my ( $projects, $thread_updates, $projects_tree, $projects2,
        $project_threads, $threads, )
      = $self->srow(
        qw/projects thread_updates projects_tree projects
          project_threads threads/
      );

    my $sth = $self->sth(
        select => [
            $thread_updates->thread_update_uuid,
            sql_case(
                when => ( $threads->thread_type == 'project' ) 
                  . AND
                  . (
                    $thread_updates->thread_update_uuid == $threads->thread_uuid
                  ),
                then => $projects->path,
                else => undef,
              )->as('insert_project_path'),
        ],
        from       => $projects_tree,
        inner_join => $projects,
        on         => $projects_tree->child == $projects->project_id,
        left_join  => $project_threads,
        on         => $project_threads->project_id == $projects->project_id,
        left_join  => $thread_updates,
        on         => $thread_updates->thread_id->in(
            $projects->project_id, $project_threads->issue_id,
            $project_threads->task_id
        ),
        left_join => $threads,
        on        => $threads->thread_id == $thread_updates->thread_id,
        where     => $projects_tree->parent->in(
            select => $projects2->project_id,
            from   => $projects2,
            where  => $projects2->path->in(@names),
        )
    );

    my $ref = { map { $_->[0] => $_->[1] } @{ $sth->fetchall_arrayref() } };
    return $ref;
}

sub _sth_project_updates {
    my $self    = shift;
    my $lparent = $self->lparent;
    my $rparent = $self->rparent;
    my $temp    = $self->temp_table;

    my $length = length($lparent);

    my (
        $x,        $project_updates, $thread_updates,
        $threads,  $issue_updates,   $task_updates,
        $projects, $project_threads, $projects2
      )
      = $self->srow(
        $temp,
        qw/project_updates thread_updates
          threads issue_updates task_updates projects project_threads
          projects/,
      );

    #    SRC        DEST             $lparent $rparent  parent from path
    #       tree            parent
    # ----------------------------------------------------------------------
    # 1. path(/*)   -> path(/*)         ''      ''      s!/?$name!!
    #
    #       path            (undef)
    #       path/tail       path
    #
    # 2. path(/*)   -> newp/path(/*)    ''      'newp'  'newp/'. then 1
    #
    #       path            newp
    #       path/tail       newp/path
    #
    # 3. p/path(/*) -> path(/*)         'p'     ''      s!^p/!! then 1
    #
    #       p/path          (undef)
    #       p/path/tail     path
    #
    # 4. p/path(/*) -> p/path(/*)       'p'     'p'     Same as 1
    #
    #       p/path          p
    #       p/path/tail     p/path
    #
    # 5. p/path(/*) -> newp/path(/*)    'p'     'newp'  s!^p!newp! then 1
    #
    #       p/path          newp
    #       p/path/tail     newp/path
    #
    #

    my $parent;
    my $project;

    if ( $lparent eq $rparent ) {    # 1 and 4
        $parent = sql_case(
            when =>
              ( $thread_updates->thread_update_uuid == $threads->thread_uuid )
              . AND
              . $projects->path->is_not_null,
            then => sql_case(
                when => $projects->path == $projects->name,
                then => undef,
                else => sql_substr(
                    $projects->path,
                    1,
                    sql_length( $projects->path ) -
                      sql_length( $projects->name ) - 1
                ),
            ),
            else => undef,
        )->as('parent');

        $project = sql_case(
            when =>
              ( $thread_updates->thread_update_uuid == $threads->thread_uuid )
              . AND
              . $projects2->project_id->is_not_null,
            then => $projects2->path,
            else => undef,
        )->as('project');
    }
    elsif ( !$lparent and $rparent ) {
        $parent = sql_case(
            when =>
              ( $thread_updates->thread_update_uuid == $threads->thread_uuid )
              . AND
              . $projects->path->is_not_null,
            then => sql_case(
                when => $projects->path == $projects->name,
                then => $rparent,
                else => sql_concat(
                    $rparent . '/',
                    sql_substr(
                        $projects->path,
                        1,
                        sql_length( $projects->path ) -
                          sql_length( $projects->name ) - 1
                    )
                ),
            ),
            else => undef,
        )->as('parent');

        $project = sql_case(
            when =>
              ( $thread_updates->thread_update_uuid == $threads->thread_uuid )
              . AND
              . $projects2->project_id->is_not_null,
            then => sql_concat( $rparent . '/', $projects2->path ),
            else => undef,
        )->as('project');
    }
    elsif ( $lparent and !$rparent ) {
        $parent = sql_case(
            when =>
              ( $thread_updates->thread_update_uuid == $threads->thread_uuid )
              . AND
              . $projects->path->is_not_null,
            then => sql_case(
                when => sql_substr( $projects->path, length($lparent) + 2 ) ==
                  $projects->name,
                then => undef,
                else => sql_substr(
                    sql_substr(
                        $projects->path,
                        1,
                        sql_length( $projects->path ) -
                          sql_length( $projects->name ) - 1
                    ),
                    length($lparent) + 2,
                ),
            ),
            else => undef,
        )->as('parent');

        $project = sql_case(
            when =>
              ( $thread_updates->thread_update_uuid == $threads->thread_uuid )
              . AND
              . $projects2->project_id->is_not_null,
            then => sql_substr( $projects2->path, length($lparent) + 2 ),
            else => undef,
        )->as('project');
    }
    elsif ( $lparent ne $rparent ) {
        $parent = sql_case(
            when =>
              ( $thread_updates->thread_update_uuid == $threads->thread_uuid )
              . AND
              . $projects->path->is_not_null,
            then => sql_case(
                when => sql_substr( $projects->path, length($lparent) + 2 ) ==
                  $projects->name,
                then => $rparent,
                else => sql_concat(
                    $rparent . '/',
                    sql_substr(
                        sql_substr(
                            $projects->path,
                            1,
                            sql_length( $projects->path ) -
                              sql_length( $projects->name ) - 1
                        ),
                        length($lparent) + 2,
                    )
                ),
            ),
            else => undef,
        )->as('parent');

        $project = sql_case(
            when =>
              ( $thread_updates->thread_update_uuid == $threads->thread_uuid )
              . AND
              . $projects2->project_id->is_not_null,
            then => sql_concat(
                $rparent . '/',
                sql_substr( $projects2->path, length($lparent) + 2 )
            ),
            else => undef,
        )->as('project');
    }

    return $self->sth(
        select => [
            $threads->thread_uuid,
            sql_case(
                when => $thread_updates->thread_update_uuid ==
                  $threads->thread_uuid,
                then => $threads->ctime,
                else => undef,
              )->as('ctime'),
            sql_case(
                when => $thread_updates->thread_update_uuid ==
                  $threads->thread_uuid,
                then => 'insert',
                else => 'update',
              )->as('_action'),
            $parent, $project,
            $threads->thread_type->as('_type'),
            $thread_updates->email,
            $thread_updates->author,
            $thread_updates->push_to,
            $thread_updates->title,
            $thread_updates->comment,
            $thread_updates->mtime,
            $thread_updates->thread_update_uuid,
            $thread_updates->thread_update_uuid,
            $project_updates->name,
            $project_updates->phase,
            sql_coalesce( $issue_updates->status, $task_updates->status )
              ->as('status'),
        ],
        from       => $x,
        inner_join => $thread_updates,
        on         => $thread_updates->thread_update_uuid == $x->uuid,
        inner_join => $threads,
        on         => $threads->thread_id == $thread_updates->thread_id,
        left_join  => $project_updates,
        on         => $project_updates->project_update_id ==
          $thread_updates->thread_update_id,
        left_join => $projects,
        on        => $project_updates->project_id == $projects->project_id,
        left_join => $issue_updates,
        on        => $issue_updates->issue_update_id ==
          $thread_updates->thread_update_id,
        left_join => $task_updates,
        on        => $task_updates->task_update_id ==
          $thread_updates->thread_update_id,
        left_join => $project_threads,
        on        => $project_threads->thread_update_id ==
          $thread_updates->thread_update_id,
        left_join => $projects2,
        on        => $projects2->project_id == $project_threads->project_id,
        order_by  => [ $thread_updates->thread_update_id ],
    );
}

# also do for search on thread_uuid?
sub _fetch_thread_updates {
    my $self       = shift;
    my @thread_ids = @_;

    my ($thread_updates) = $self->srow(qw/thread_updates/);

    my $sth = $self->sth(
        select => [ $thread_updates->thread_update_uuid, ],
        from   => $thread_updates,
        where  => $thread_updates->thread_id->in(@thread_ids),
    );

    my $ref = { map { $_->[0] => undef } @{ $sth->fetchall_arrayref() } };
    return $ref;
}

sub getmsg {
    my $self = shift;
    my $line = shift;
    $log->debug( 'recv: ' . $line );

    if ( my $ref = eval { $self->json->decode($line) } ) {
        if ( ref $ref ne 'ARRAY' ) {
            $self->sendmsg(
                { err => 400, msg => 'ARRAY expected: ' . ref $ref } );
            $self->err( 'ARRAY expected: ' . ref $ref );
            return;
        }

        my ( $header, @rest ) = @$ref;

        if ( ref $header ne 'HASH' ) {
            $self->sendmsg(
                { err => 400, msg => 'ARRAY expected: ' . ref $ref } );
            $self->err( 'ARRAY[HASH] expected: ' . ref $header );
            return;
        }

        return ( $header, @rest );
    }

    $self->sendmsg( { err => 400, msg => 'Invalid JSON' } );
    $self->err('Invalid JSON');
    return;
}

sub sendmsg {
    my $self = shift;
    my $json = $self->json->encode( \@_ );
    $log->debug( 'send: ' . $json );

    $self->rcmd->stdin->print( $json . "\n" ) || die "print: $!";
    return;
}

sub connect {
    my $self = shift;
    my $args = {@_};
    $args->{location} || confess 'connect(location => $location)';

    my $cv = $self->connect_cv( AnyEvent->condvar );

    $self->rversion(undef);
    $self->rdbid(undef);
    $self->json( JSON::XS->new->utf8->canonical );

    if ( $args->{location} =~ s!^ssh://(.*)!! ) {
    }
    else {    # assume local
        $self->rcmd( spawn( 'curo-sync', $args->{location} ) );
        $self->rcmd->stdout->autoflush(1);
    }

    my $hdl;
    $hdl = AnyEvent::Handle->new(
        fh => $self->rcmd->stdout,

        on_read => sub {
            $hdl->push_read(
                line => sub {
                    my ( $header, @rest ) = $self->getmsg( $_[1] );
                    if ( $self->err ) {
                        $hdl->destroy;
                        $cv->send;
                        return;
                    }

                    if (    $header->{_} eq 'reset'
                        and $header->{from} =~ m/^curo-sync:/ )
                    {
                        $self->connected( $args->{location} );
                        $args->{on_connect}->( $args->{location} )
                          if $args->{on_connect};
                    }
                    else {
                        $self->err( 'hub '
                              . $args->{location} . ': '
                              . $header->{err} . ' '
                              . $header->{msg} );
                    }
                    $hdl->destroy;
                    $cv->send;
                }
            );
        },

        on_err => sub {
            my ( $hdl, $fatal, $m ) = @_;
            $self->err($m);
            $hdl->destroy;
            $cv->send;
        },

        timeout => TIMEOUT,

        on_timeout => sub {
            my ($hdl) = @_;
            $self->err('Connect: Timeout');
            $hdl->destroy;
            $cv->send;
        },

        on_eof => sub {
            $self->err('Connect: Received EOF');
            $hdl->destroy;
            $cv->send;
        },

    );

    if ( $args->{on_connect} ) {
        return 1;
    }

    $cv->recv;
    die $self->err . "\n" if $self->err;
    return 1;
}

sub _write_handler {
    my $self = shift;

    my $i   = 0;
    my $sth = $self->_sth_project_updates;

    $self->wh(
        AnyEvent::Handle->new(
            fh => $self->rcmd->stdin,

            on_err => sub {
                my ( $hdl, $fatal, $m ) = @_;
                $self->err($m);
                $self->rh->destroy;
                $self->wh->destroy if $self->wh;
                $self->cv->send;
            },

            timeout => TIMEOUT,

            on_timeout => sub {
                my ($hdl) = @_;
                $self->err('Write: Timeout');
                $self->rh->destroy;
                $self->wh->destroy if $self->wh;
                $self->cv->send;
            },

            on_eof => sub {
                $self->err('Write: EOF');
                $self->rh->destroy;
                $self->wh->destroy if $self->wh;
                $self->cv->send;
            },
        )
    );
    $self->pushed(0);
    $self->wh->on_drain(
        sub {

            if ( my $ref = $sth->fetchrow_hashref ) {
                defined $ref->{$_}
                  or delete $ref->{$_}
                  for keys %$ref;

                my $type   = delete $ref->{_type};
                my $action = delete $ref->{_action};

                my $json = $self->json->encode(
                    [
                        {
                            _    => $action,
                            type => $type
                        },
                        $ref
                    ]
                );

                $log->debug( 'send: ' . $json );
                $self->wh->push_write( $json . "\n" );
                $self->pushed( 1 + $self->pushed );
            }
            else {
                my $json = $self->json->encode( [ { _ => 'commit', }, ] );
                $log->debug( 'send: ' . $json );
                $self->wh->on_drain(undef);
                $self->wh->push_write( $json . "\n" );
            }
        }
    );
}

sub _read_handler {
    my $self = shift;
    $self->rh(
        AnyEvent::Handle->new(
            fh => $self->rcmd->stdout,

            on_read => sub {
                $self->rh->push_read(
                    line => sub {
                        my ( $header, @rest ) = $self->getmsg( $_[1] );
                        if ( $self->err ) {
                            $self->rh->destroy;
                            $self->cv->send;
                            return;
                        }

                        if ( exists $header->{err} ) {
                            $self->conn->dbh->rollback;
                            $self->temp_table(undef);
                            $self->err( $header->{err} . ' ' . $header->{msg} );
                        }
                        elsif ( $header->{_} eq 'have'
                            and $header->{path} eq $self->rpath )
                        {
                            my $temp =
                              $self->temp_table( 'T' . mktemp('XXXXXX') );

                            my $dbh = $self->conn->dbh;

                            $dbh->begin_work;

                            $dbh->do(
                                "CREATE TEMPORARY TABLE $temp(uuid varchar)");

                            my $sth =
                              $dbh->prepare("INSERT INTO $temp VALUES(?)");

                            my @projects;

                            my $here  = $self->here;
                            my $there = $rest[0];
                            $log->debug(
                                "push_project remote: " . scalar keys %$there );

                            foreach ( keys %$here ) {
                                if ( !exists $there->{$_} ) {
                                    $sth->execute($_);
                                    push( @projects, $here->{$_} )
                                      if $here->{$_};
                                }
                                else {
                                }
                            }

                            # The sort here is important and in fact
                            # the reason why we don't do this inline in
                            # the above foreach: We don't want an
                            # update for a sub-project to have a lower
                            # update_id then its parent.

                            my $lparent = $self->lparent;
                            my $rparent = $self->rparent;

                            foreach my $project ( sort @projects ) {
                                my $dest = $project;
                                if ($rparent) {
                                    $dest =~ s!^$lparent/?!$rparent/!;
                                }
                                else {
                                    $dest =~ s!^$lparent/?!$rparent!;
                                }
                                $dest = $self->connected . ':' . $dest;
                                my $ref = {
                                    project => $project,
                                    push_to => $dest,
                                };
                                $self->insert_project_update($ref);
                                $sth->execute( $ref->{thread_update_uuid} );
                            }
                            $self->_write_handler;
                            return;
                        }
                        elsif ( $header->{_} eq 'reset'
                            and exists $header->{commit} )
                        {
                            $self->conn->dbh->commit;
                        }
                        else {
                            $self->conn->dbh->rollback;
                            $self->temp_table(undef);
                            $self->err('Unknown reponse');
                        }

                        $self->rh->destroy;
                        $self->wh->destroy if $self->wh;
                        $self->cv->send;
                    }
                );
            },

            on_err => sub {
                my ( $hdl, $fatal, $m ) = @_;
                $self->err($m);
                $self->rh->destroy;
                $self->wh->destroy if $self->wh;
                $self->cv->send;
            },

            timeout => TIMEOUT,

            on_timeout => sub {
                my ($hdl) = @_;
                $self->err('Read: Timeout');
                $self->rh->destroy;
                $self->wh->destroy if $self->wh;
                $self->cv->send;
            },

            on_eof => sub {
                $self->err('Read: EOF');
                $self->rh->destroy;
                $self->wh->destroy if $self->wh;
                $self->cv->send;
            },
        )
    );
}

sub push_project {
    my $self = shift;

    $self->connect_cv->recv;
    die $self->err if $self->err;

    my $path  = shift || confess 'push_project($PATH,$rpath)';
    my $rpath = shift || confess 'push_project($path,$RPATH)';
    my @tmp;
    @tmp = split( '/', $path );
    my $name = pop @tmp || '';
    my $lparent = join( '/', @tmp );

    @tmp = split( '/', $rpath );
    my $rname = pop @tmp || '';
    my $rparent = join( '/', @tmp );

    confess "Names must match ($name!=$rname)" if ( $name ne $rname );

    $log->debug("push_project $path $rpath");

    $self->rpath($rpath);
    $self->lparent($lparent);
    $self->rparent($rparent);
    $self->json( JSON::XS->new->utf8->canonical );
    $self->sendmsg(
        {
            _      => 'want',
            'path' => $rpath,
            from   => basename($0) . ':' 
              . $VERSION . ':'
              . $self->last_deploy_id('Curo')
        }
    );

    my $dbh = $self->conn->dbh;
    $self->here( $self->_fetch_project_update_uuids($path) );
    $log->debug( "push_project local: " . scalar keys %{ $self->here } );

    #    $dbh->begin_work;

    $self->cv( AnyEvent->condvar );

    $self->_read_handler;
    $self->cv->recv;

    #    $dbh->do( "DROP TABLE " . $self->temp_table ) if $self->temp_table;
    die $self->err . "\n" if $self->err;
    return $self->pushed;
}

sub disconnect {
    my $self = shift;
    my $msg = shift || 'bye';

    return unless $self->connected;

    $self->sendmsg( { quit => $msg } );
    $self->timeout(undef);

    $self->rcmd->close;
    $self->rcmd(undef);
    return $msg;
}

Moo::Role->apply_role_to_package( 'Curo', __PACKAGE__ );

1;

