package Curo; our $VERSION = '0.01_02';
use strict;
use warnings;
use Moo;
use File::Spec::Functions qw/catfile rel2abs catdir/;
use Cwd qw/abs_path/;
use Carp qw/confess/;
use Log::Any qw/$log/;
use Curo::Config;
use SQL::DB ':all';
use SQL::DBx::Simple;
use SQL::DBx::Sequence;
use File::HomeDir;
use Data::UUID;
use Digest::SHA1 qw/sha1_hex/;

my $uuid = Data::UUID->new;
sub new_uuid { sha1_hex( lc $uuid->create_str ); }

extends 'SQL::DB';

has 'dir' => ( is => 'ro', );

has 'config' => ( is => 'ro', );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my %args  = ( @_, schema => 'Curo::Schema' );

    $args{dir} || confess 'Missing argument: dir';
    $args{dir} = rel2abs( $args{dir} );
    my $conffile = catfile( $args{dir}, 'config' );

    if ( $args{init} ) {
        mkdir $args{dir};

        confess "fatal: Config exists: " . $conffile if ( -e $conffile );

        my $config = Curo::Config->new;
        $config->{_}->{dsn}      = $args{dsn}      || '';
        $config->{_}->{username} = $args{username} || '';
        $config->{_}->{password} = $args{password} || '';
        $config->{alias}->{i}    = 'list issues';
        $config->{alias}->{t}    = 'list tasks';
        $config->{alias}->{h}    = 'list hubs';
        $config->write($conffile);

        require SQL::DBx::Deploy;
        my $db = Curo->new( dir => $args{dir} );
        $db->deploy('Curo');

        delete $args{init};
    }

    confess "file not found: " . $conffile unless -e $conffile;

    $args{config} =
         Curo::Config->read( catfile( $args{dir}, 'config' ), 'utf-8' )
      || confess $Curo::Config::errsttr;

    my $default_dsn =
      'dbi:SQLite:dbname=' . catfile( $args{dir}, 'curo.sqlite' );

    $args{dsn}      = $args{config}->{_}->{dsn} || $default_dsn;
    $args{username} = $args{config}->{_}->{username};
    $args{password} = $args{config}->{_}->{password};

    if ( !$args{config}->{user}->{name} ) {
        my $gitconfig =
          Curo::Config->read( catfile( File::HomeDir->my_home, '.gitconfig' ),
            'utf-8' );

        $args{config}->{user}->{name}  = $gitconfig->{user}->{name};
        $args{config}->{user}->{email} = $gitconfig->{user}->{email};
        $args{config}->{user}->{name}  =~ s/(^")|("$)//g;
        $args{config}->{user}->{email} =~ s/(^")|("$)//g;
    }

    return $class->$orig(%args);
};

sub upgrade {
    my $self = shift;
    require SQL::DBx::Deploy;
    return $self->deploy('Curo');
}

sub insert_thread {
    my $self = shift;
    my $ref  = shift;

    $ref->{thread_id} = $self->nextval('threads');
    $ref->{thread_uuid} ||= new_uuid();
    $ref->{thread_update_uuid} = $ref->{thread_uuid};
    $ref->{ctime} ||= $self->current_timestamp;
    $ref->{mtime} ||= $self->current_timestamp;

    $self->insert( into => 'threads', values => $ref );

    $ref->{thread_update_id} = $self->nextval('thread_updates');

    #    $ref->{last_update_id}   = $ref->{thread_update_id};
    $self->insert_thread_update($ref);

    return $ref->{thread_id};
}

sub insert_project {
    my $self = shift;
    my $ref  = shift;

    $ref->{thread_type} = 'project';
    $ref->{phase} ||= 'run';

    return $self->txn(
        sub {
            $self->insert_thread($ref);

            $ref->{project_id} = $ref->{thread_id};

            if ( $ref->{parent} ) {
                $ref->{parent_id} = $self->path2project_id( $ref->{parent} )
                  || die "Parent not found: $ref->{parent}";
            }

            $self->insert( into => 'projects', values => $ref );

            $ref->{project_self} = $ref->{project_id};
            $self->insert( into => 'project_threads', values => $ref );

            $ref->{project_update_id} = $ref->{thread_update_id};
            $self->insert( into => 'project_updates', values => $ref );
            return $ref->{project_id};
        }
    );
}

sub insert_issue {
    my $self = shift;
    my $ref  = shift;

    $ref->{thread_type} = 'issue';
    $ref->{status} ||= 'open';

    return $self->txn(
        sub {
            $self->insert_thread($ref);
            $ref->{issue_id} = $ref->{thread_id};
            $self->insert( into => 'issues', values => $ref );

            $ref->{issue_update_id} = $ref->{thread_update_id};
            $self->insert( into => 'issue_updates', values => $ref );

            if ( $ref->{project} ) {
                $ref->{project_id} = $self->path2project_id( $ref->{project} )
                  || die "Project not found: $ref->{project}";
                $self->insert( into => 'project_threads', values => $ref );
            }

            return $ref->{issue_id};
        }
    );
}

sub insert_task {
    my $self = shift;
    my $ref  = shift;

    $ref->{thread_type} = 'task';
    $ref->{status} ||= 'open';

    return $self->txn(
        sub {
            $self->insert_thread($ref);
            $ref->{task_id} = $ref->{thread_id};
            $self->insert( into => 'tasks', values => $ref );

            $ref->{task_update_id} = $ref->{thread_update_id};
            $self->insert( into => 'task_updates', values => $ref );

            if ( $ref->{project} ) {
                $ref->{project_id} = $self->path2project_id( $ref->{project} )
                  || die "Project not found: $ref->{project}";
                $self->insert( into => 'project_threads', values => $ref );
            }
            return $ref->{task_id};
        }
    );
}

sub insert_hub {
    my $self = shift;
    my $ref  = shift;

    $ref->{location} = abs_path( $ref->{location} ) || $ref->{location};

    return $self->insert( into => 'hubs', values => $ref );
}

sub insert_thread_update {
    my $self = shift;
    my $ref  = shift;

    $ref->{thread_id}          ||= $self->uuid2thread_id( $ref->{thread_uuid} );
    $ref->{thread_update_id}   ||= $self->nextval('thread_updates');
    $ref->{thread_update_uuid} ||= new_uuid();
    $ref->{ctime}              ||= $self->current_timestamp;
    $ref->{mtime}              ||= $self->current_timestamp;
    $ref->{lang}               ||= 'en';
    $ref->{email}              ||= $self->config->{user}->{email};
    $ref->{author}             ||= $self->config->{user}->{name};
    $ref->{itime} = $self->current_timestamp;

    $self->insert( into => 'thread_updates', values => $ref );

    return $ref->{thread_update_id};
}

sub insert_project_update {
    my $self = shift;
    my $ref = shift || confess 'insert_project_update($ref)';

    return $self->txn(
        sub {
            if ( $ref->{project} ) {
                my $id = $self->path2project_id( $ref->{project} )
                  || die "Project not found: $ref->{project}";
                $ref->{project_id} ||= $id;
            }
            $ref->{thread_id} ||= $ref->{project_id};
            $self->insert_thread_update($ref);

            $ref->{project_id} ||= $ref->{thread_id};
            $ref->{project_update_id} = $ref->{thread_update_id};
            $self->insert( into => 'project_updates', values => $ref );

            return $ref->{project_update_id};
        }
    );
}

sub insert_issue_update {
    my $self = shift;
    my $ref  = shift;

    return $self->txn(
        sub {
            $ref->{thread_id} ||= $ref->{issue_id};
            $self->insert_thread_update($ref);

            $ref->{issue_id} ||= $ref->{thread_id};
            $ref->{issue_update_id} = $ref->{thread_update_id};
            $self->insert( into => 'issue_updates', values => $ref );

            if ( exists $ref->{project_id} ) {
                $self->insert( into => 'project_threads', values => $ref );
            }
            if ( exists $ref->{rm_project_id} ) {
                $self->delete( from => 'project_threads', where => $ref );
            }
            return $ref->{issue_update_id};
        }
    );
}

sub insert_task_update {
    my $self = shift;
    my $ref  = shift;

    return $self->txn(
        sub {
            $ref->{thread_id} ||= $ref->{task_id};
            $self->insert_thread_update($ref);

            $ref->{task_id} ||= $ref->{thread_id};
            $ref->{task_update_id} = $ref->{thread_update_id};
            $self->insert( into => 'task_updates', values => $ref );

            if ( exists $ref->{project_id} ) {
                $self->insert( into => 'project_threads', values => $ref );
            }
            if ( exists $ref->{rm_project_id} ) {
                $self->delete( from => 'project_threads', where => $ref );
            }
            return $ref->{task_update_id};
        }
    );
}

sub path2project_id {
    my $self = shift;
    my $path = shift;

    my $projects = $self->srow('projects');

    my $project = $self->fetch1(
        select => [ $projects->project_id, ],
        from   => $projects,
        where  => $projects->path == $path,
    );
    return $project ? $project->project_id : undef;
}

sub id2thread_type {
    my $self = shift;
    my $id = shift || confess 'id2thread_type($id)';

    my $threads = $self->srow('threads');

    my $thread = $self->fetch1(
        select => [ $threads->thread_type, ],
        from   => $threads,
        where  => $threads->thread_id == $id,
    );
    return $thread ? $thread->thread_type : undef;
}

sub uuid2thread_id {
    my $self = shift;
    my $uuid = shift || confess 'uuid2thread_id($id)';

    my $threads = $self->srow('threads');

    my $thread = $self->fetch1(
        select => [ $threads->thread_id, ],
        from   => $threads,
        where  => $threads->thread_uuid == $uuid,
    );
    return $thread ? $thread->thread_id : undef;
}

sub name2hub {
    my $self = shift;
    my $name = shift;

    my $hubs = $self->srow('hubs');
    return $self->fetch1(
        select => [ $hubs->name, $hubs->location, $hubs->master, ],
        from   => $hubs,
        where  => $hubs->name == $name,
    );
}

sub arrayref_hub_list {
    my $self = shift;
    my $ref  = shift;

    my $hubs = $self->srow('hubs');
    return $self->sth(
        select => [
            $hubs->name,
            $hubs->location,
            sql_case(
                when => $hubs->master->is_null,
                then => '',
                else => '*',
              )->as('master'),
        ],
        from     => $hubs,
        order_by => $hubs->name,
    )->fetchall_arrayref;
}

sub arrayref_task_list {
    my $self = shift;
    my $opt  = shift;

    $opt->{project} ||= $self->config->{current}->{project};
    $opt->{status}  ||= 'new,open';
    $opt->{order}   ||= 'ctime';

    my $tasks           = $self->srow('tasks');
    my $threads         = $self->srow('threads');
    my $projects        = $self->srow('projects');
    my $project_threads = $self->srow('project_threads');

    my $where;
    if ( $opt->{status} ne 'all' ) {
        $where = $tasks->status->in( split( ',', $opt->{status} ) );
    }

    if ( $opt->{project} ) {
        $opt->{project_id} = $self->path2project_id( $opt->{project} )
          || die "Unknown project: $opt->{project}\n";

        if ($where) {
            $where =
              $where . AND . ( $projects->project_id == $opt->{project_id} );
        }
        else {
            $where = ( $projects->project_id == $opt->{project} );
        }
    }

    my @order;
    foreach my $o ( split( ',', $opt->{order} ) ) {
        if ( $opt->{asc} ) {
            push( @order, $threads->$o->asc ) if $threads->can($o);
            push( @order, $tasks->$o->asc )   if $tasks->can($o);
        }
        else {
            push( @order, $threads->$o->desc ) if $threads->can($o);
            push( @order, $tasks->$o->desc )   if $tasks->can($o);
        }
    }

    my $current = $self->config->{current}->{task} || 0;

    return $self->sth(
        select => [
            sql_case(
                when => $tasks->task_id == $current,
                then => '*',
                else => '',
              )->as('current'),
            $tasks->task_id,
            sql_coalesce( $threads->title, '' )->as('title'),
            $projects->path,
            sql_coalesce( $tasks->status, '' )->as('status'),
        ],
        from       => $tasks,
        inner_join => $threads,
        on         => $tasks->task_id == $threads->thread_id,
        inner_join => $project_threads,
        on         => ( $tasks->task_id == $project_threads->task_id ),
        inner_join => $projects,
        on         => ( $projects->project_id == $project_threads->project_id ),
        $where ? ( where => $where ) : (),

        #        order_by => \@order,
        order_by => [ $projects->path, $threads->ctime, ],
    )->fetchall_arrayref;
}

sub arrayref_issue_list {
    my $self = shift;
    my $opt  = shift;

    $opt->{project} ||= $self->config->{current}->{project};
    $opt->{status}  ||= 'new,open';
    $opt->{order}   ||= 'ctime';

    my $issues          = $self->srow('issues');
    my $threads         = $self->srow('threads');
    my $projects        = $self->srow('projects');
    my $project_threads = $self->srow('project_threads');

    my $where;
    if ( $opt->{status} ne 'all' ) {
        $where = $issues->status->in( split( ',', $opt->{status} ) );
    }

    if ( $opt->{project} ) {
        $opt->{project_id} = $self->path2project_id( $opt->{project} )
          || die "Unknown project: $opt->{project}\n";

        if ($where) {
            $where =
              $where . AND . ( $projects->project_id == $opt->{project_id} );
        }
        else {
            $where = ( $projects->project_id == $opt->{project} );
        }
    }

    my @order;
    foreach my $o ( split( ',', $opt->{order} ) ) {
        if ( $opt->{asc} ) {
            push( @order, $threads->$o->asc ) if $threads->can($o);
            push( @order, $issues->$o->asc )  if $issues->can($o);
        }
        else {
            push( @order, $threads->$o->desc ) if $threads->can($o);
            push( @order, $issues->$o->desc )  if $issues->can($o);
        }
    }

    my $current = $self->config->{current}->{issue} || 0;

    return $self->sth(
        select => [
            sql_case(
                when => $issues->issue_id == $current,
                then => '*',
                else => '',
              )->as('current'),
            $issues->issue_id,
            sql_coalesce( $threads->title, '' )->as('title'),
            $projects->path,
            sql_coalesce( $issues->status, '' )->as('status'),
        ],
        from       => $issues,
        inner_join => $threads,
        on         => $issues->issue_id == $threads->thread_id,
        inner_join => $project_threads,
        on         => ( $issues->issue_id == $project_threads->issue_id ),
        inner_join => $projects,
        on         => ( $projects->project_id == $project_threads->project_id ),
        $where ? ( where => $where ) : (),

        #        order_by => \@order,
        order_by => [ $projects->path, $threads->ctime, ],
    )->fetchall_arrayref;
}

sub arrayref_list_all {
    my $self = shift;
    my $opt  = shift;

    my $pid = $self->path2project_id( $opt->{project} );

    $opt->{issue_status} ||= 'new,open';
    delete $opt->{issue_status} if $opt->{issue_status} eq 'all';

    my (
        $projects,        $projects_tree, $threads,
        $project_threads, $hubs,          $threads2,
        $projects_tree2,  $tasks,         $issues
      )
      = $self->srow(
        qw/ projects projects_tree threads
          project_threads hubs threads
          projects_tree tasks issues/
      );

    return $self->sth(
        select => [
            sql_case(
                when => $threads->thread_type == 'project',
                then => '.',
                else => $threads->thread_id,
              )->as('thread_id'),
            sql_case(
                when => $threads->thread_type == 'project',
                then => sql_concat(
                    'Project: ', $projects->path, ' - ', $threads->title
                ),
                else => $threads->title,
              )->as('title'),
            sql_case(
                when => $threads->thread_type == 'project',
                then => '',                                   #$projects->phase,
                else => sql_concat(

                    $threads->thread_type,
                    '/',
                    sql_coalesce(
                        $tasks->status, $issues->status, $projects->phase
                    )
                )
              )->as('type'),
        ],
        from => $projects,
        $pid
        ? (
            inner_join => $projects_tree,
            on         => $projects->project_id == $projects_tree->child,
          )
        : (),
        left_join => $project_threads,
        on        => ( $projects->project_id == $project_threads->project_id ),
        left_join => $threads,
        on        => $threads->thread_id->in(
            $project_threads->issue_id,
            $project_threads->task_id,
            $project_threads->project_self
        ),
        left_join => $tasks,
        on        => $threads->thread_id == $tasks->task_id,
        left_join => $issues,
        on        => $threads->thread_id == $issues->issue_id,
        $pid ? ( where => $projects_tree->parent == $pid, ) : (),
        order_by => [
            $projects->path,
            sql_case(
                when => $threads->thread_type == 'project',
                then => 0,
                when => $threads->thread_type == 'task',
                then => 1,
                when => $threads->thread_type == 'issue',
                then => 2,
                else => 10,
            ),
        ],
    )->fetchall_arrayref;
}

sub arrayref_project_list {
    my $self = shift;
    my $opt  = shift;

    $opt->{issue_status} ||= 'new,open';
    delete $opt->{issue_status} if $opt->{issue_status} eq 'all';

    my ( $projects, $projects_tree, $threads, $project_threads, $hubs,
        $threads2, $projects_tree2, $tasks )
      = $self->srow(
        qw/ projects projects_tree threads
          project_threads hubs threads
          projects_tree tasks /
      );

    my $current = $self->config->{current}->{project} || 0;

    return $self->sth(
        select => [
            $projects->path,
            $threads->title,
            $projects->phase,
            sql_sum(
                sql_case(
                    when => $project_threads->task_id->is_not_null,
                    then => 1,
                    else => 0,
                )
              )->as('tasks'),

            sql_sum(
                sql_case(
                    when => $project_threads->issue_id->is_not_null,
                    then => 1,
                    else => 0,
                )
              )->as('issues'),
        ],
        from       => $projects,
        inner_join => $threads,
        on         => $projects->project_id == $threads->thread_id,
        inner_join => $projects_tree,
        on         => $projects->project_id == $projects_tree->child,
        left_join  => $project_threads,
        on         => ( $projects->project_id == $project_threads->project_id ),
        where      => $projects_tree->parent->in(
            select => [ $projects_tree2->child, ],
            from   => $projects_tree2,
            $opt->{pid}
            ? ( where => $projects_tree2->parent == $opt->{pid} )
            : (),
            group_by => $projects_tree2->child,
            having   => sql_count( $projects_tree2->parent ) == 1,
        ),
        group_by => [ $projects->path, $threads->title, $projects->phase, ],
        order_by => $projects->path,
    )->fetchall_arrayref;
}

sub iter_project_log {
    my $self = shift;
    my $path = shift;

    my $projects        = $self->srow('projects');
    my $project_updates = $self->srow('project_updates');
    my $threads         = $self->srow('threads');
    my $thread_updates  = $self->srow('thread_updates');

    return $self->iter(
        select => [
            $projects->path,
            $project_updates->project_id,
            $threads->thread_uuid,
            $project_updates->project_update_id,
            $thread_updates->thread_update_uuid,
            $thread_updates->thread_type,
            $thread_updates->title,
            $thread_updates->mtime,
            $thread_updates->author,
            $thread_updates->email,
            $thread_updates->push_to,
            $project_updates->name,
            $project_updates->phase,
            sql_coalesce( $thread_updates->comment, '' )->as('comment'),
        ],
        from       => $projects,
        inner_join => $thread_updates,
        on         => $thread_updates->thread_id == $projects->project_id,
        inner_join => $threads,
        on         => $thread_updates->thread_id == $threads->thread_id,
        left_join  => $project_updates,
        on         => $project_updates->project_update_id ==
          $thread_updates->thread_update_id,
        where    => $projects->path == $path,
        order_by => $thread_updates->mtime->asc,
    );
}

sub iter_task_log {
    my $self = shift;
    my $id   = shift;

    my $task_updates   = $self->srow('task_updates');
    my $threads        = $self->srow('threads');
    my $thread_updates = $self->srow('thread_updates');

    return $self->iter(
        select => [
            $task_updates->task_id,
            $threads->thread_uuid,
            $task_updates->task_update_id,
            $thread_updates->thread_update_uuid,
            $thread_updates->thread_type,
            $thread_updates->title,
            $thread_updates->mtime,
            $thread_updates->author,
            $thread_updates->email,
            $task_updates->status,
            sql_coalesce( $thread_updates->comment, '' )->as('comment'),
        ],
        from       => $thread_updates,
        inner_join => $threads,
        on         => $thread_updates->thread_id == $threads->thread_id,
        left_join  => $task_updates,
        on         => $task_updates->task_update_id ==
          $thread_updates->thread_update_id,
        where    => $thread_updates->thread_id == $id,
        order_by => $thread_updates->mtime->asc,
    );
}

sub iter_issue_log {
    my $self = shift;
    my $id   = shift;

    my $issue_updates  = $self->srow('issue_updates');
    my $threads        = $self->srow('threads');
    my $thread_updates = $self->srow('thread_updates');
    my $projects       = $self->srow('projects');

    return $self->iter(
        select => [
            $issue_updates->issue_id,
            $threads->thread_uuid,
            $issue_updates->issue_update_id,
            $thread_updates->thread_update_uuid,
            $thread_updates->thread_type,
            $thread_updates->title,
            $thread_updates->mtime,
            $thread_updates->author,
            $thread_updates->email,
            $issue_updates->status,
            sql_coalesce( $thread_updates->comment, '' )->as('comment'),
            $projects->name->as('project_name'),
        ],
        from       => $thread_updates,
        inner_join => $issue_updates,
        on         => $issue_updates->issue_update_id ==
          $thread_updates->thread_update_id,
        inner_join => $threads,
        on         => $thread_updates->thread_id == $threads->thread_id,
        left_join  => $projects,
        on         => $projects->project_id == $issue_updates->project_id,
        where      => $thread_updates->thread_id == $id,
        order_by   => $thread_updates->mtime->asc,
    );
}

sub iter_full_thread_log {
    my $self = shift;

    my (
        $threads,         $thread_updates, $projects,
        $project_updates, $issues,         $issue_updates,
        $tasks,           $task_updates,   $project_threads,
      )
      = $self->srow(
        qw/threads thread_updates projects project_updates
          issues issue_updates tasks task_updates project_threads/
      );

    return $self->iter(
        select => [
            $thread_updates->thread_id,
            $threads->thread_uuid,
            sql_coalesce( $thread_updates->thread_type, $threads->thread_type )
              ->as('thread_type'),
            $thread_updates->thread_update_id,
            $thread_updates->thread_update_uuid,
            $thread_updates->mtime,
            $thread_updates->author,
            $thread_updates->email,
            $thread_updates->push_to,
            $project_updates->phase,
            sql_coalesce( $thread_updates->title, $threads->title )
              ->as('title'),
            sql_coalesce( $thread_updates->comment, '' )->as('comment'),
            sql_coalesce( $issue_updates->status,   $task_updates->status )
              ->as('status'),
            $projects->path->as('project'),
            sql_case(
                when => $thread_updates->thread_update_uuid ==
                  $threads->thread_uuid,
                then => 1,
                else => 0
              )->as('new_item'),
        ],
        from       => $thread_updates,
        inner_join => $threads,
        on         => $threads->thread_id == $thread_updates->thread_id,
        left_join  => $project_updates,
        on         => $project_updates->project_update_id ==
          $thread_updates->thread_update_id,
        left_join => $issue_updates,
        on        => $issue_updates->issue_update_id ==
          $thread_updates->thread_update_id,
        left_join => $task_updates,
        on        => $task_updates->task_update_id ==
          $thread_updates->thread_update_id,
        left_join => $project_threads,
        on        => ( $project_threads->issue_id == $issue_updates->issue_id ) 
          . OR
          . ( $project_threads->task_id == $task_updates->task_id ),
        left_join => $projects,
        on        => ( $projects->project_id == $project_threads->project_id ) 
          . OR
          . ( $projects->project_id == $project_updates->project_id ),
        order_by => [
            $thread_updates->mtime->desc,
            $thread_updates->thread_update_id->desc,
        ],
    );
}

1;

