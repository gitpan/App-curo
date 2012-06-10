package Curo; our $VERSION = '0.0.2';
use strict;
use warnings;
use Carp qw/confess croak/;
use Log::Any qw/$log/;
use Moo;
use SQL::DB ':all';
use SQL::DBx::SQLite;

extends 'SQL::DB';

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my %args  = ( @_, schema => 'Curo::Schema' );

    return $class->$orig(%args);
};

sub BUILD {
    my $self = shift;

    # TODO Remove this before the first production release.
    $self->conn->dbh->do('PRAGMA reverse_unordered_selects = ON;')
      if ( $self->dbd eq 'SQLite' );

    $self->conn->dbh->do('PRAGMA temp_store = MEMORY;')
      if ( $self->dbd eq 'SQLite' );

    $self->sqlite_create_function_nextval;
    $self->sqlite_create_function_debug;
    $self->sqlite_create_function_sha1;
}

sub db_version {
    my $self = shift;
    require SQL::DBx::Deploy;
    return $self->last_deploy_id('Curo::Deploy');
}

sub upgrade {
    my $self = shift;
    require SQL::DBx::Deploy;
    return $self->deploy('Curo::Deploy');
}

sub client {
    my $self = shift;
    require Curo::Sync::Client;
    return Curo::Sync::Client->new( db => $self, );
}

sub server {
    my $self = shift;
    require Curo::Sync::Server;
    return Curo::Sync::Server->new( db => $self, );
}

sub insert_task {
    my $self = shift;
    my $ref  = shift;

    $ref->{thread_type} = 'task';

    return $self->txn(
        sub {
            $self->insert_thread($ref);

            $self->insert( into => 'tasks', values => $ref );

            my $project_task_states = $self->srow(qw/project_task_states/);

            $ref->{state} ||= $self->object(
                select => [ $project_task_states->state ],
                from   => $project_task_states,
                where =>
                  ( $project_task_states->project_id == $ref->{project_id} )
                  . AND
                  . ( $project_task_states->def == 1 ),
            )->state;

            $ref->{task_id} = $ref->{id};
            $self->insert( into => 'task_updates', values => $ref );

            return $ref->{task_id};
        }
    );
}

sub insert_issue {
    my $self = shift;
    my $ref  = shift;

    $ref->{thread_type} = 'issue';

    return $self->txn(
        sub {
            $self->insert_thread($ref);
            $self->insert( into => 'issues', values => $ref );

            my $project_issue_states = $self->srow(qw/project_issue_states/);

            $ref->{state} ||= $self->object(
                select => [ $project_issue_states->state ],
                from   => $project_issue_states,
                where =>
                  ( $project_issue_states->project_id == $ref->{project_id} )
                  . AND
                  . ( $project_issue_states->def == 1 ),
            )->state;

            $ref->{issue_id} = $ref->{id};
            $self->insert( into => 'issue_updates', values => $ref );

            return $ref->{issue_id};
        }
    );
}

sub insert_hub {
    my $self = shift;
    my $ref  = shift;

    require Time::Piece;
    require Digest::SHA1;

    $ref->{thread_type} = 'hub';
    $ref->{id}          = $self->nextval('threads');
    $ref->{ctime}       = time;
    $ref->{ctimetz}     = int( Time::Piece->new->tzoffset );
    $ref->{mtime}       = $ref->{ctime};
    $ref->{mtimetz}     = $ref->{ctimetz};
    $ref->{title}       = $ref->{alias};
    $ref->{comment}     = "Location: $ref->{location}\n";
    $ref->{uuid}        = Digest::SHA1::sha1( each %$ref );

    return $self->txn(
        sub {

            $self->insert(
                into   => 'threads',
                values => $ref,
            );

            return $self->insert( into => 'hubs', values => $ref );
        }
    );
}

sub insert_hub_thread {
    my $self = shift;
    my $ref  = shift;

    require Time::Piece;
    require Digest::SHA1;

    $ref->{thread_type} = 'hub_thread';
    $ref->{id}          = $self->nextval('threads');
    $ref->{ctime}       = time;
    $ref->{ctimetz}     = int( Time::Piece->new->tzoffset );
    $ref->{mtime}       = $ref->{ctime};
    $ref->{mtimetz}     = $ref->{ctimetz};
    $ref->{title}       = 'hub_thread insert';
    $ref->{comment}     = "$ref->{hub_id} $ref->{thread_id}\n";
    $ref->{uuid}        = Digest::SHA1::sha1( each %$ref );

    return $self->txn(
        sub {

            $self->insert(
                into   => 'threads',
                values => $ref,
            );

            return $self->insert( into => 'hub_threads', values => $ref );
        }
    );
}

sub drop_thread {
    my $self = shift;
    my $id   = shift;
    my $type = shift;

    return $self->delete(
        from  => 'threads',
        where => { id => $id, thread_type => $type, },
    );
}

sub check_update {
    my $self = shift;
    my $ref  = shift;

    #    if (!exists $ref->{id}) {
    #        my $thread_updates = $self->srow(qw/thread_updates/);
    #        $ref->{id} = $self->fetch1(
    #            select => [
    #                $thread_updates->thread_id,
    #            ],
    #            from => $thread_updates,
    #            where => $thread_updates->update_id == $ref->{update_id},
    #        )->thread_id;
    #    }

    my $thread_updates  = $self->srow(qw/thread_updates/);
    my $projects        = $self->srow(qw/projects/);
    my $project_threads = $self->srow(qw/project_threads/);
    my $projects_tree   = $self->srow(qw/projects_tree/);
    my $ptp             = $self->srow(qw/project_tree_prefix/);

    use Data::Show;
    use Data::Dumper;
    use Digest::SHA1 qw/sha1_hex/;

    my @checks = $self->objects(
        select => [ $projects->id, $projects->hash, $thread_updates->slots, ],
        from   => $thread_updates,
        inner_join => $projects_tree,
        on         => $projects_tree->child == $thread_updates->thread_id,
        inner_join => $projects,
        on         => $projects->id == $projects_tree->parent,
        where      => $thread_updates->update_id == $ref->{update_id},
        order_by   => $projects->id,
    );

    foreach my $check (@checks) {

        my @slots = $self->fetch(
            select     => [ $thread_updates->update_uuid, ],
            from       => $thread_updates,
            inner_join => $project_threads,
            on         => $thread_updates->thread_id->in(
                $project_threads->self, $project_threads->issue_id,
                $project_threads->task_id,
            ),
            inner_join => $projects_tree,
            on         => ( $projects_tree->parent == $check->id ) 
              . AND
              . ( $projects_tree->child == $project_threads->project_id ),
            where    => $thread_updates->slots == $check->slots,
            order_by => $thread_updates->update_uuid,
        );

        my $hash = substr( sha1_hex( map { $_->update_uuid } @slots ), 0, 8 );

        my $got = $self->hash(
            select => $ptp->hash,
            from   => $ptp,
            where  => ( $ptp->project_id == $check->id ) 
              . AND
              . ( $ptp->slot == $check->slots ),
        )->{hash};

        eval { ( $hash eq $got ) } || do {
            print Dumper( \@slots );
            print Dumper [ $hash, $got, $ref ];

            #            die "no match";
        };

        foreach my $i ( 0 .. 4 ) {
            my $prefix = substr( $check->slots, 0, 4 - $i );
            my @slots = $self->objects(
                select => [ $ptp->slot, $ptp->hash, ],
                from   => $ptp,
                where  => ( $ptp->project_id == $check->id ) 
                  . AND
                  . $ptp->slot->like( $prefix . '_' ),
                order_by => $ptp->slot,
            );

            my $hash = substr( sha1_hex( map { $_->hash } @slots ), 0, 8 );

            my $got;
            if ( $i != 4 ) {
                $got = $self->hash(
                    select => [ $ptp->slot, $ptp->hash, ],
                    from   => $ptp,
                    where  => ( $ptp->project_id == $check->id ) 
                      . AND
                      . $ptp->slot == $prefix,
                )->{hash};
            }
            else {
                $got = $check->hash;
            }

            eval { ( $hash eq $got ) } || do {
                print Dumper ( \@slots );
                print Dumper [ $check->id, $prefix, $hash, $got, $ref ];

                #                die "no match";
            };

        }
    }
}

sub insert_project {
    my $self = shift;
    my $ref = shift || confess 'insert_project($ref)';
    require Time::Piece;

    return my $res = $self->txn(
        sub {

            $ref->{id}        = $self->nextval('threads');
            $ref->{update_id} = $self->nextval('thread_updates');

            $ref->{mtime}   = time;
            $ref->{mtimetz} = int( Time::Piece->new->tzoffset );
            my $defaults = $self->srow('project_defaults');

            my $default_phase = $self->fetch1(
                select =>
                  [ $defaults->status, $defaults->state, $defaults->rank ],
                from  => $defaults,
                where => ( $defaults->kind == 'phase' ) 
                  . AND
                  . ( $defaults->def == 1 ),
            );

            $ref->{phase} ||= $default_phase->state;
            $ref->{add_kind}    = 'phase',
              $ref->{add_state} = $default_phase->state;
            $ref->{add_status} = $default_phase->status;
            $ref->{add_rank} ||= $default_phase->rank;

            my $res = $self->insert(
                into   => 'func_import_project_update',
                values => $ref,
            );

            my @states = $self->fetch(
                select => [
                    $defaults->kind, $defaults->state, $defaults->status,
                    $defaults->rank, $defaults->def
                ],
                from  => $defaults,
                where => !(
                      ( $defaults->kind == 'phase' ) 
                    . AND
                    . ( $defaults->state == $default_phase->state )
                ),
                order_by => $defaults->rank->asc,
            );

            foreach my $state (@states) {
                $self->update_project(
                    {
                        mtime      => $ref->{mtime},
                        mtimetz    => $ref->{mtimetz},
                        email      => $ref->{email},
                        author     => '__curo',
                        id         => $ref->{id},
                        comment    => '(automatic default phases setup)',
                        add_kind   => $state->kind,
                        add_state  => $state->state,
                        add_status => $state->status,
                        add_rank   => $state->rank,
                        add_def    => $state->def,
                    }
                );
            }

            return 1;
        }
    );

    $self->check_update($ref);
    return $res;
}

sub update_project {
    my $self = shift;
    my $ref = shift || confess 'update_project($ref)';

    $ref->{update_id} = $self->nextval('thread_updates');

    return $self->insert(
        into   => 'func_import_project_update',
        values => $ref,
    );
}

sub import_project_update {
    my $self = shift;
    my $ref = shift || confess 'insert_project_update($ref)';

    $ref->{update_id} = $self->nextval('thread_updates');

    return my $res = $self->insert(
        into   => 'func_import_project_update',
        values => $ref,
    );

    $self->check_update($ref);
    return $res;
    return $self->insert(
        into   => 'func_import_project_update',
        values => $ref,
    );
}

sub insert_issue_update {
    my $self = shift;
    my $ref  = shift;

    return $self->txn(
        sub {
            $ref->{thread_id} = $ref->{issue_id};
            $self->insert_thread_update($ref);

            $self->insert( into => 'issue_updates', values => $ref );

            # TODO convert this into a trigger (what does it actually
            # do?)
            if ( exists $ref->{rm_project_id} ) {
                $self->delete( from => 'project_threads', where => $ref );
            }
            return $ref->{update_id};
        }
    );
}

sub insert_task_update {
    my $self = shift;
    my $ref  = shift;

    return $self->txn(
        sub {
            $ref->{thread_id} = $ref->{task_id};
            $self->insert_thread_update($ref);

            $self->insert( into => 'task_updates', values => $ref );

            # TODO convert this into a trigger (what does it actually
            # do?)
            if ( exists $ref->{rm_project_id} ) {
                $self->delete( from => 'project_threads', where => $ref );
            }
            return $ref->{update_id};
        }
    );
}

sub drop_issue {
    my $self = shift;
    my $id = shift || confess 'drop_issue($id)';

    return $self->delete(
        from  => 'threads',
        where => { id => $id, thread_type => 'issue', },
    );
}

sub drop_task {
    my $self = shift;
    my $id = shift || confess 'drop_task($id)';

    return $self->delete(
        from  => 'threads',
        where => { id => $id, thread_type => 'task' },
    );
}

sub drop_project {
    my $self = shift;
    my $id = shift || confess 'drop_project($id)';

    return $self->delete(
        from  => 'threads',
        where => { id => $id, thread_type => 'project', },
    );
}

sub one_and_only_project_id {
    my $self = shift;
    my $task_issue_id = shift || confess 'one_and_only_project($task_issue_id)';

    my $project_threads = $self->srow('project_threads');

    my @projects = $self->objects(
        select => [ $project_threads->project_id, ],
        from   => $project_threads,
        where  => ( $project_threads->issue_id == $task_issue_id ) 
          . OR
          . ( $project_threads->task_id == $task_issue_id ),
        limit => 2,
    );

    return @projects != 1 ? 0 : $projects[0]->project_id;
}

sub project_count {
    my $self = shift;

    my $projects = $self->srow('projects');

    my $p = $self->object(
        select => [ sql_count( $projects->id )->as('count') ],
        from   => $projects,
    );
    return $p->count;
}

sub one_and_only_project_path {
    my $self = shift;

    my $projects = $self->srow('projects');

    my @projects = $self->objects(
        select => [ $projects->path, ],
        from   => $projects,
        limit  => 2,
    );
    return @projects != 1 ? 0 : $projects[0]->path;
}

sub path2project_id {
    my $self = shift;
    my $path = shift || confess 'path2project_id($path)';

    my $projects = $self->srow('projects');

    my $project = $self->object(
        select => [ $projects->id, ],
        from   => $projects,
        where  => $projects->path == $path,
    );
    return $project ? $project->id : undef;
}

sub project_id2path {
    my $self = shift;
    my $id   = shift;

    my $projects = $self->srow('projects');

    my $project = $self->object(
        select => [ $projects->path, ],
        from   => $projects,
        where  => $projects->id == $id,
    );
    return $project ? $project->path : undef;
}

sub id2project {
    my $self = shift;
    my $id = shift || confess 'id2project($id)';

    croak "id must be an integer: $id" unless $id =~ m/^\d+$/;

    my ( $projects, $threads, $thread_updates ) =
      $self->srow(qw/projects threads thread_updates/);

    return $self->object(
        select => [
            $threads->id,
            sql_lower( sql_hex( $threads->uuid ) )->as('uuid'),
            $projects->path,
            $projects->name,
            $projects->hash,
            $projects->phase_id,
            $threads->ctime,
            $threads->ctimetz,
            $threads->mtime,
            $threads->mtimetz,
            $threads->title,
            $thread_updates->update_id,
            sql_lower( sql_hex( $thread_updates->update_uuid ) )
              ->as('update_uuid'),
            $thread_updates->author,
            $thread_updates->email,
        ],
        from       => $projects,
        inner_join => $threads,
        on         => $threads->id == $projects->id,
        inner_join => $thread_updates,
        on         => $thread_updates->update_uuid == $threads->uuid,
        where      => $projects->id == $id,
    );
}

sub path2uuid {
    my $self = shift;
    my $path = shift;

    my ( $projects, $threads ) = $self->srow(qw/projects threads/);

    my $thread = $self->object(
        select     => sql_lower( sql_hex( $threads->uuid ) )->as('uuid'),
        from       => $threads,
        inner_join => $projects,
        on         => $projects->id == $threads->id,
        where      => $projects->path == $path,
    );
    return $thread ? $thread->uuid : undef;
}

sub path2project {
    my $self = shift;
    my $path = shift;

    my ( $projects, $threads, $thread_updates, $project_states ) =
      $self->srow(qw/projects threads thread_updates project_states/);

    return $self->object(
        select => [
            $threads->id,
            sql_lower( sql_hex( $threads->uuid ) )->as('uuid'),
            $projects->path,
            $projects->name,
            $project_states->state->as('phase'),
            $thread_updates->update_id,
            $projects->hash,
            sql_lower( sql_hex( $thread_updates->update_uuid ) )
              ->as('update_uuid'),
        ],
        from       => $projects,
        inner_join => $project_states,
        on         => $project_states->id == $projects->phase_id,
        inner_join => $threads,
        on         => $threads->id == $projects->id,
        inner_join => $thread_updates,
        on         => ( $thread_updates->thread_id == $threads->id ) 
          . AND
          . $thread_updates->parent_update_id->is_null,
        where => $projects->path == $path,
    );
}

sub id2thread_type {
    my $self = shift;
    my $id = shift || confess 'id2thread_type($id)';

    my $threads = $self->srow('threads');

    my $thread = $self->object(
        select => [ $threads->thread_type, ],
        from   => $threads,
        where  => $threads->id == $id,
    );
    return $thread ? $thread->thread_type : undef;
}

sub uuid2id {
    my $self = shift;
    my $uuid = shift || confess 'uuid2id($id)';

    my $threads = $self->srow('threads');

    my $thread = $self->object(
        select => [ $threads->id ],
        from   => $threads,
        where  => $threads->uuid == pack( 'H*', $uuid ),
    );
    return $thread ? $thread->id : undef;
}

sub update2id {
    my $self = shift;
    my $update_id = shift || confess 'update2id($id)';

    my $thread_updates = $self->srow('thread_updates');

    my $thread_update = $self->object(
        select => [ $thread_updates->thread_id, ],
        from   => $thread_updates,
        where  => $thread_updates->update_id == $update_id,
    );
    return $thread_update ? $thread_update->thread_id : undef;
}

sub name2hub {
    my $self  = shift;
    my $alias = shift;

    my $hubs = $self->srow('hubs');
    return $self->object(
        select => '*',
        from   => $hubs,
        where  => $hubs->alias == $alias,
    );
}

sub location2hub {
    my $self     = shift;
    my $location = shift;

    my $hubs = $self->srow('hubs');
    return $self->object(
        select => '*',
        from   => $hubs,
        where  => $hubs->location == $location,
    );
}

sub hub_threads {
    my $self     = shift;
    my $location = shift;

    my ( $hubs, $hub_threads, $threads, $projects ) =
      $self->srow(qw/hubs hub_threads threads projects/);

    return $self->objects(
        select     => [ $threads->id, $threads->thread_type, $projects->path, ],
        from       => $hubs,
        inner_join => $hub_threads,
        on         => $hub_threads->hub_id == $hubs->id,
        inner_join => $threads,
        on         => $threads->id == $hub_threads->thread_id,
        left_join  => $projects,
        on         => $projects->id == $threads->id,
        where      => $hubs->location == $location,
    );
}

sub id2hubs {
    my $self = shift;
    my $id   = shift;

    my ( $hubs, $hub_threads ) = $self->srow(qw/hubs hub_threads/);

    return $self->objects(
        select     => [ $hubs->location, $hubs->alias ],
        from       => $hub_threads,
        inner_join => $hubs,
        on         => $hubs->id == $hub_threads->hub_id,
        where      => $hub_threads->thread_id == $id,
    );
}

sub hubs {
    my $self = shift;

    my ($hubs) = $self->srow(qw/hubs/);

    return $self->objects(
        select => $hubs->location,
        from   => $hubs,
    );
}

sub iter_project_phases {
    my $self = shift;
    my $ref  = shift;

    my ( $project_states, $projects ) =
      $self->srow(qw/project_states projects/);

    return $self->iter(
        select => [
            $project_states->rank,
            $project_states->state->as('phase'),
            sql_case(
                when => $project_states->id == $projects->phase_id,
                then => 1,
                else => 0,
              )->as('current'),
        ],
        from       => $project_states,
        inner_join => $projects,
        on         => $projects->id == $project_states->project_id,
        where      => ( $project_states->project_id == $ref->{id} ) 
          . AND
          . ( $project_states->kind == 'phase' ),
        order_by => $project_states->rank->asc,
    );
}

sub iter_project_tasks {
    my $self = shift;
    my $ref  = shift;

    my ( $project_threads, $project_states ) =
      $self->srow(qw/project_threads project_states/);

    return $self->iter(
        select => [
            $project_states->status,
            $project_states->state,
            sql_count( $project_threads->thread_id )->as('count'),
        ],
        from      => $project_states,
        left_join => $project_threads,
        on        => $project_threads->state_id == $project_states->id,
        where     => ( $project_states->project_id == $ref->{id} ) 
          . AND
          . ( $project_states->kind eq 'task' ),
        group_by => [ $project_states->status, $project_states->state, ],
        order_by => $project_states->rank->asc,
    );
}

sub iter_project_issues {
    my $self = shift;
    my $ref  = shift;

    my ( $project_threads, $project_states ) =
      $self->srow(qw/project_threads project_states/);

    return $self->iter(
        select => [
            $project_states->status,
            $project_states->state,
            sql_count( $project_threads->thread_id )->as('count'),
        ],
        from      => $project_states,
        left_join => $project_threads,
        on        => $project_threads->state_id == $project_states->id,
        where     => ( $project_states->project_id == $ref->{id} ) 
          . AND
          . ( $project_states->kind eq 'issue' ),
        group_by => [ $project_states->status, $project_states->state, ],
        order_by => $project_states->rank->asc,
    );
}

sub iter_project_links {
    my $self = shift;
    my $ref  = shift;

    my ( $hub_threads, $hubs ) = $self->srow(qw/hub_threads hubs/);

    return $self->iter(
        select     => [ $hubs->alias, $hubs->location, ],
        from       => $hub_threads,
        inner_join => $hubs,
        on         => $hubs->id == $hub_threads->hub_id,
        where      => $hub_threads->thread_id == $ref->{id},
        order_by   => $hubs->alias,
    );
}

sub arrayref_project_phases_list {
    my $self = shift;
    my $ref  = shift;

    my ( $ppt, $projects ) = $self->srow(qw/project_phases projects/);

    return $self->arrays(
        select => [
            $projects->path,
            $ppt->rank,
            sql_case(
                when => $projects->phase_id == $ppt->phase,
                then => '*',
                else => '',
              )->as('current'),
            $ppt->phase,
        ],
        from       => $projects,
        inner_join => $ppt,
        on         => $projects->id == $ppt->project_id,
        order_by   => [ $projects->path, $ppt->rank, ],
    );
}

sub arrayref_hub_list {
    my $self = shift;
    my $ref  = shift;

    my ( $hubs, $hub_threads ) = $self->srow(qw/hubs hub_threads/);
    return $self->arrays(
        select => [
            $hubs->id, $hubs->alias, $hubs->location,
            sql_count( $hub_threads->thread_id )->as('link_count'),
        ],
        from      => $hubs,
        left_join => $hub_threads,
        on        => $hub_threads->hub_id == $hubs->id,
        group_by  => [ $hubs->alias, $hubs->location, ],
        order_by  => $hubs->alias,
    );
}

sub iter_list_links {
    my $self = shift;

    my ( $hubs, $hub_threads, $threads, $projects ) =
      $self->srow(qw/hubs hub_threads threads projects/);

    return $self->iter(
        select => [
            $hub_threads->id->as('listid'),
            $hubs->alias,
            $threads->id,
            $threads->thread_type,
            sql_case(
                when => $threads->thread_type == 'project',
                then => sql_concat( $projects->path, ' - ', $threads->title ),
                else => $threads->title,
              )->as('title'),
        ],
        from       => $hub_threads,
        inner_join => $threads,
        on         => $threads->id == $hub_threads->thread_id,
        inner_join => $hubs,
        on         => $hubs->id == $hub_threads->hub_id,
        left_join  => $projects,
        on         => $projects->id == $threads->id,
        order_by   => [ $hubs->alias, $hub_threads->id ],
    );
}

sub arrayref_task_list {
    my $self = shift;
    my $opt  = shift;

    my $tasks               = $self->srow('tasks');
    my $threads             = $self->srow('threads');
    my $projects            = $self->srow('projects');
    my $project_threads     = $self->srow('project_threads');
    my $project_task_states = $self->srow('project_task_states');

    return $self->arrays(
        select => [
            sql_case(
                when => $tasks->id == ( $opt->{current} || 0 ),
                then => '*',
                else => '',
              )->as('current'),
            $tasks->id,
            sql_coalesce( $threads->title, '' )->as('title'),
            $projects->path,
            sql_coalesce( $project_threads->task_state, '' )->as('state'),
        ],
        from       => $tasks,
        inner_join => $threads,
        on         => $tasks->id == $threads->id,
        inner_join => $project_threads,
        on         => ( $tasks->id == $project_threads->task_id ) 
          . AND
          . (
            $project_threads->task_state->in(
                select => [ $project_task_states->state, ],
                from   => $project_task_states,
                where  => $project_task_states->state->in( @{ $opt->{status} } )
                  . OR
                  . $project_task_states->status->in( @{ $opt->{status} } ),
            ),
          ),
        inner_join => $projects,
        on         => ( $projects->id == $project_threads->project_id ),
        $opt->{project_id}
        ? ( where => $projects->id == $opt->{project_id} )
        : (),
        order_by => [ $projects->path, $threads->ctime->asc, ],
    );
}

sub arrayref_issue_list {
    my $self = shift;
    my $opt  = shift;

    my $issues               = $self->srow('issues');
    my $threads              = $self->srow('threads');
    my $projects             = $self->srow('projects');
    my $project_threads      = $self->srow('project_threads');
    my $project_issue_states = $self->srow('project_issue_states');

    return $self->arrays(
        select => [
            sql_case(
                when => $issues->id == ( $opt->{current} || 0 ),
                then => '*',
                else => '',
              )->as('current'),
            $issues->id,
            sql_coalesce( $threads->title, '' )->as('title'),
            $projects->path,
            sql_coalesce( $project_threads->issue_state, '' )->as('state'),
        ],
        from       => $issues,
        inner_join => $threads,
        on         => $issues->id == $threads->id,
        inner_join => $project_threads,
        on         => ( $issues->id == $project_threads->issue_id ) 
          . AND
          . (
            $project_threads->issue_state->in(
                select => [ $project_issue_states->state, ],
                from   => $project_issue_states,
                where => $project_issue_states->state->in( @{ $opt->{status} } )
                  . OR
                  . $project_issue_states->status->in( @{ $opt->{status} } ),
            ),
          ),
        inner_join => $projects,
        on         => ( $projects->id == $project_threads->project_id ),
        $opt->{project_id}
        ? ( where => $projects->id == $opt->{project_id} )
        : (),
        order_by => [ $projects->path, $threads->ctime->asc, ],
    );
}

sub invalid_state_status {
    my $self = shift;
    return () unless @_;

    my %try = map { $_ => 1 } @_;

    my ($project_states) = $self->srow(qw/project_states/);

    map { delete $try{ $_->state } } $self->objects(
        select       => [ $project_states->state->as('state') ],
        from         => $project_states,
        where        => $project_states->state->in(@_),
        union_select => [ $project_states->status->as('state') ],
        from         => $project_states,
        where        => $project_states->status->in(@_),
    );

    return keys %try;
}

sub invalid_phases {
    my $self = shift;
    return () unless @_;

    my %try = map { $_ => 1 } @_;

    my ($project_states) = $self->srow(qw/project_states/);

    map { delete $try{ $_->state } } $self->objects(
        select => [ $project_states->state ],
        from   => $project_states,
        where  => ( $project_states->kind eq 'phase' ) 
          . AND
          . $project_states->state->in(@_),
    );

    return keys %try;
}

sub arrayref_project_list {
    my $self = shift;
    my $opt  = shift;

    my (
        $projects,       $projects_tree, $threads,        $project_threads,
        $hubs,           $threads2,      $projects_tree2, $tasks,
        $project_states, $project_states2,
      )
      = $self->srow(
        qw/ projects projects_tree threads
          project_threads hubs threads
          projects_tree tasks project_states project_states/
      );

    my $data = $self->arrays(
        select => [
            $projects->path,
            $threads->title,
            $project_states->state->as('phase'),
            sql_sum(
                sql_case(
                    when => $project_states2->status == 'resolved',
                    then => 1,
                    else => 0,
                )
              )->as('resolved'),
            sql_sum(
                sql_case(
                    when => $project_states2->status == 'active',
                    then => 1,
                    else => 0,
                ),
              )->as('active'),
            sql_sum(
                sql_case(
                    when => $project_states2->status == 'stalled',
                    then => 1,
                    else => 0,
                ),
              )->as('stalled'),
        ],
        from       => $project_states,
        inner_join => $projects,
        on         => ( $projects->id == $project_states->project_id ) 
          . AND
          . ( $projects->phase_id == $project_states->id ),
        inner_join => $threads,
        on         => $projects->id == $threads->id,
        left_join  => $project_threads,
        on         => ( $project_threads->project_id == $projects->id ) 
          . AND
          . ( $project_threads->thread_id != $projects->id ),
        left_join => $project_states2,
        on        => $project_states2->id == $project_threads->state_id,
        where     => ( $project_states->kind eq 'phase' ) 
          . AND
          . $project_states->state->in( @{ $opt->{phase} } ),
        group_by =>
          [ $projects->path, $threads->title, $project_states->state, ],
        order_by => $projects->path,
    );

    foreach my $i ( 0 .. $#$data ) {
        my $row = $data->[$i];
        if ( $row->[3] ) {
            $row->[3] =
              int( 100 * $row->[3] / ( $row->[3] + $row->[4] + $row->[5] ) )
              . '%';
        }
        else {
            $row->[3] = '0%';
        }
    }
    return $data;
}

sub arrayref_list_all {
    my $self = shift;
    my $opt  = shift;

    my (
        $projects,        $projects_tree, $threads,
        $project_threads, $hubs,          $threads2,
        $projects_tree2,  $tasks,         $issues,
        $project_states,  $project_states2,
      )
      = $self->srow(
        qw/ projects projects_tree threads
          project_threads hubs threads
          projects_tree tasks issues project_states project_states/
      );

    return $self->arrays(
        select => [
            sql_case(
                when => $threads->thread_type == 'project',
                then => -1,
                else => $threads->id,
              )->as('id'),
            sql_case(
                when => $threads->thread_type == 'project',
                then => $projects->path,
                else => $threads->title,
              )->as('title'),
            sql_case(
                when => $threads->thread_type == 'project',
                then => '',                                   #$projects->phase,
                else => sql_concat(
                    $project_states2->state, ' (',
                    $threads->thread_type,   ')',
                )
              )->as('type'),
        ],
        from       => $project_states,
        inner_join => $projects,
        on         => ( $projects->id == $project_states->project_id ) 
          . AND
          . ( $projects->phase_id == $project_states->id ),
        left_join => $project_threads,
        on        => ( $project_threads->project_id == $projects->id ),
        left_join => $threads,
        on        => $threads->id == $project_threads->thread_id,
        left_join => $tasks,
        on        => $tasks->id == $threads->id,
        left_join => $issues,
        on        => $issues->id == $tasks->id,
        left_join => $project_states2,
        on        => $project_states2->id == $project_threads->state_id,
        where     => ( $project_states->kind eq 'phase' ) 
          . AND
          . $project_states->state->in( @{ $opt->{phase} } ),
        order_by => [
            $projects->path,
            sql_case(
                when => $threads->thread_type == 'project',
                then => 0,
                else => 1,
            ),
            $threads->id->desc,
        ],
    );
}

sub iter_project_log {
    my $self = shift;
    my $id   = shift;

    my $projects            = $self->srow('projects');
    my $project_updates     = $self->srow('project_updates');
    my $project_states      = $self->srow('project_states');
    my $threads             = $self->srow('threads');
    my $thread_updates      = $self->srow('thread_updates');
    my $thread_updates_tree = $self->srow('thread_updates_tree');

    my $updateid = $self->object(
        select     => [ $thread_updates->update_id, ],
        from       => $projects,
        inner_join => $threads,
        on         => $threads->id == $projects->id,
        inner_join => $thread_updates,
        on         => $thread_updates->update_uuid == $threads->uuid,
        where      => $projects->id == $id,
    ) || die "project id not found: $id";

    return $self->iter(
        select => [
            $projects->path,
            $project_updates->project_id,
            sql_lower( sql_hex( $threads->uuid ) )->as('uuid'),
            $project_updates->update_id,
            sql_lower( sql_hex( $thread_updates->update_uuid ) )
              ->as('update_uuid'),
            $thread_updates->title,
            $thread_updates->mtime,
            $thread_updates->mtimetz,
            $thread_updates->author,
            $thread_updates->email,
            $thread_updates->push_to,
            $project_updates->name,
            $project_states->state->as('phase'),
            $project_updates->add_kind,
            $project_updates->add_state,
            $project_updates->add_status,
            $project_updates->add_rank,
            $project_updates->add_def,
            $thread_updates_tree->depth,
            sql_coalesce( $thread_updates->comment, '' )->as('comment'),
        ],
        from       => $thread_updates_tree,
        inner_join => $thread_updates,
        on => ( $thread_updates_tree->child == $thread_updates->update_id )
          . AND
          . ( $thread_updates->author != '__curo' ),
        inner_join => $threads,
        on         => $thread_updates->thread_id == $threads->id,
        inner_join => $projects,
        on         => $projects->id == $threads->id,
        left_join  => $project_updates,
        on         => $project_updates->update_id == $thread_updates->update_id,
        left_join  => $project_states,
        on         => $project_states->id == $project_updates->phase_id,
        where      => $thread_updates_tree->parent == $updateid->update_id,
        order_by =>
          [ $thread_updates->path->asc, $thread_updates->update_id->asc, ],
    );
}

sub iter_task_log {
    my $self = shift;
    my $id   = shift;

    my $task_updates        = $self->srow('task_updates');
    my $project_task_states = $self->srow('project_task_states');
    my $threads             = $self->srow('threads');
    my $thread_updates      = $self->srow('thread_updates');
    my $thread_updates_tree = $self->srow('thread_updates_tree');
    my $projects            = $self->srow('projects');

    my $updateid = $self->object(
        select     => [ $thread_updates->update_id, ],
        from       => $threads,
        inner_join => $thread_updates,
        on         => $thread_updates->update_uuid == $threads->uuid,
        where      => $threads->id == $id,
    ) || die "update_id not found: $id";

    return $self->iter(
        select => [
            $task_updates->task_id,
            $threads->uuid,
            $task_updates->update_id,
            $thread_updates->update_uuid,
            $thread_updates->title,
            $thread_updates->mtime,
            $thread_updates->mtimetz,
            $thread_updates->author,
            $thread_updates->email,
            $task_updates->state,
            $project_task_states->status,
            $projects->path,
            $thread_updates_tree->depth,
            sql_coalesce( $thread_updates->comment, '' )->as('comment'),
        ],
        from       => $thread_updates_tree,
        inner_join => $thread_updates,
        on => ( $thread_updates_tree->child == $thread_updates->update_id ),
        inner_join => $threads,
        on         => $thread_updates->thread_id == $threads->id,
        left_join  => $task_updates,
        on         => $task_updates->update_id == $thread_updates->update_id,
        left_join  => $project_task_states,
        on => ( $project_task_states->project_id == $task_updates->project_id )
          . AND
          . ( $project_task_states->state == $task_updates->state ),
        left_join => $projects,
        on        => $task_updates->project_id == $projects->id,
        where     => $thread_updates_tree->parent == $updateid->update_id,
        order_by  => $thread_updates->path->asc,
    );
}

sub iter_issue_log {
    my $self = shift;
    my $id   = shift;

    my $issue_updates        = $self->srow('issue_updates');
    my $project_issue_states = $self->srow('project_issue_states');
    my $threads              = $self->srow('threads');
    my $thread_updates       = $self->srow('thread_updates');
    my $thread_updates_tree  = $self->srow('thread_updates_tree');
    my $projects             = $self->srow('projects');

    my $updateid = $self->object(
        select     => [ $thread_updates->update_id, ],
        from       => $threads,
        inner_join => $thread_updates,
        on         => $thread_updates->update_uuid == $threads->uuid,
        where      => $threads->id == $id,
    ) || die "update_id not found: $id";

    return $self->iter(
        select => [
            $issue_updates->issue_id,
            $threads->uuid,
            $issue_updates->update_id,
            $thread_updates->update_uuid,
            $thread_updates->title,
            $thread_updates->mtime,
            $thread_updates->mtimetz,
            $thread_updates->author,
            $thread_updates->email,
            $issue_updates->state,
            $project_issue_states->status,
            $projects->path,
            $thread_updates_tree->depth,
            sql_coalesce( $thread_updates->comment, '' )->as('comment'),
        ],
        from       => $thread_updates_tree,
        inner_join => $thread_updates,
        on => ( $thread_updates_tree->child == $thread_updates->update_id ),
        inner_join => $threads,
        on         => $thread_updates->thread_id == $threads->id,
        left_join  => $issue_updates,
        on         => $issue_updates->update_id == $thread_updates->update_id,
        left_join  => $project_issue_states,
        on =>
          ( $project_issue_states->project_id == $issue_updates->project_id )
          . AND
          . ( $project_issue_states->state == $issue_updates->state ),
        left_join => $projects,
        on        => $issue_updates->project_id == $projects->id,
        where     => $thread_updates_tree->parent == $updateid->update_id,
        order_by  => $thread_updates->path->asc,
    );
}

sub iter_full_thread_log {
    my $self = shift;

    my (
        $threads,         $thread_updates, $projects,
        $project_updates, $issues,         $issue_updates,
        $tasks,           $task_updates,   $project_threads,
        $project_states
      )
      = $self->srow(
        qw/threads thread_updates projects project_updates
          issues issue_updates tasks task_updates project_threads
          project_states/
      );

    return $self->iter(
        select => [
            $threads->id,
            sql_substr( sql_lower( sql_hex( $threads->uuid ) ), 1, 8 )
              ->as('uuid'),
            $threads->thread_type,
            $thread_updates->update_id,
            sql_lower( sql_hex( $thread_updates->update_uuid ) )
              ->as('update_uuid'),
            $thread_updates->mtime,
            $thread_updates->mtimetz,
            $thread_updates->author,
            $thread_updates->email,
            $thread_updates->push_to,
            $project_updates->add_kind,
            $project_updates->add_state,
            $project_updates->add_status,
            $project_updates->add_rank,
            $project_updates->add_def,
            sql_coalesce( $thread_updates->title, $threads->title )
              ->as('title'),
            sql_coalesce( $thread_updates->comment, '' )->as('comment'),
            $project_states->state,
            $project_states->status,
            $project_updates->name,
            $projects->path,
            sql_case(
                when => $thread_updates->update_uuid == $threads->uuid,
                then => 1,
                else => 0
              )->as('new_item'),
        ],
        from       => $thread_updates,
        inner_join => $threads,
        on         => $threads->id == $thread_updates->thread_id,
        left_join  => $project_updates,
        on         => $project_updates->update_id == $thread_updates->update_id,
        left_join  => $task_updates,
        on         => $task_updates->update_id == $thread_updates->update_id,
        left_join  => $issue_updates,
        on         => $issue_updates->update_id == $thread_updates->update_id,
        left_join  => $project_threads,
        on => ( $project_threads->thread_id == $thread_updates->thread_id ),
        left_join => $project_states,
        on        => $project_states->id->in(
            $project_updates->phase_id, $task_updates->state_id,
            $issue_updates->state_id,
        ),
        left_join => $projects,
        on        => ( $projects->id == $project_threads->project_id ) 
          . OR
          . ( $projects->id == $project_updates->project_id ),
        where => $thread_updates->author != '__curo',
        order_by =>
          [ $thread_updates->mtime->desc, $thread_updates->update_id->desc, ],
    );
}

1;

=cut
sub insert_work {
    $log->debug('insert_work');
    my $self = shift;
    my $ref  = shift;
    if ( !exists $ref->{email} ) {
        $ref->{email} = $self->config->get('user.email');
    }
    if ( !exists $ref->{author} ) {
        $ref->{author} = $self->config->get('user.name');
    }
    $self->insert( into => 'work', values => $ref );

    my $id = $ref->{email};

    return $id;
}
=cut
