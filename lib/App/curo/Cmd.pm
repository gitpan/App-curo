package App::curo::Cmd;
use strict;
use warnings;
use OptArgs ':all';

our $VERSION = '0.0.2';

arg command => (
    isa      => 'SubCmd',
    required => 1,
    comment  => '',
    fallback => {
        name    => 'alias',
        comment => 'run an alias from .curo/config',
    },
);

opt help => (
    isa     => 'Bool',
    alias   => 'h',
    ishelp  => 1,
    comment => 'print this help message and exit',
);

opt debug => (
    isa     => 'Str',
    alias   => 'd',
    comment => 'define modules to debug',
);

### init ###
subcmd( 'init', 'initialize a new Curo repository' );

arg directory => (
    isa     => 'Str',
    comment => 'location of the database or hub',
);

opt prompt => (
    isa     => 'Bool',
    alias   => 'p',
    comment => 'Prompt for configuration parameters',
);

opt hub => (
    isa     => 'Bool',
    comment => 'Initialize database as a hub',
);

opt todo => (
    isa     => 'Bool',
    alias   => 't',
    comment => 'Auto-create a new to-do type project',
);

### new ###
subcmd( qw/new/, 'create a new project, task or issue' );

arg type => (
    isa      => 'SubCmd',
    required => 1,
    comment  => '',
);

subcmd( qw/new project/, 'create a new project' );

arg name => (
    isa     => 'Str',
    comment => 'The name of the project',
);

arg title => (
    isa     => 'Str',
    comment => 'A short description of the project',
    greedy  => 1,
);

opt phase => (
    isa     => 'Str',
    comment => 'Phase',
);

opt author => (
    isa     => 'Str',
    comment => 'Author',
);

opt email => (
    isa     => 'Str',
    comment => 'Email',
);

opt lang => (
    isa     => 'Str',
    comment => 'Lang',
);

opt locale => (
    isa     => 'Str',
    comment => 'Locale',
);

opt comment => (
    isa     => 'Str',
    alias   => 'c',
    comment => 'Comment',
);

subcmd( qw/new task/, 'define an item of work' );

arg title => (
    isa     => 'Str',
    comment => 'Title',
    greedy  => 1,
);

opt state => (
    isa     => 'Str',
    comment => 'State',
);

opt author => (
    isa     => 'Str',
    comment => 'Author',
);

opt ctime => (
    isa     => 'Str',
    comment => 'Created',
);

opt email => (
    isa     => 'Str',
    comment => 'Email',
);

opt lang => (
    isa     => 'Str',
    comment => 'Lang',
);

opt locale => (
    isa     => 'Str',
    comment => 'Locale',
);

opt project => (
    isa     => 'Str',
    alias   => 'p',
    comment => 'Project',
);

opt comment => (
    isa     => 'Str',
    alias   => 'c',
    comment => 'Comment',
);

subcmd( qw/new issue/, 'define a problem to be solved' );

arg title => (
    isa     => 'Str',
    comment => 'Title',
    greedy  => 1,
);

opt state => (
    isa     => 'Str',
    comment => 'State',
);

opt author => (
    isa     => 'Str',
    comment => 'Author',
);

opt ctime => (
    isa     => 'Str',
    comment => 'Created',
);

opt email => (
    isa     => 'Str',
    comment => 'Email',
);

opt lang => (
    isa     => 'Str',
    comment => 'Lang',
);

opt locale => (
    isa     => 'Str',
    comment => 'Locale',
);

opt project => (
    isa     => 'Str',
    alias   => 'p',
    comment => 'Project',
);

opt comment => (
    isa     => 'Str',
    alias   => 'c',
    comment => 'Comment',
);

subcmd( qw/new hub/, 'create a reference to a remote hub' );

arg alias => (
    isa     => 'Str',
    comment => 'Local name for the remote hub',
);

arg location => (
    isa     => 'Str',
    comment => 'How to connect to the hub',
);

### list ###
subcmd( qw/list/, 'list various threads in the database' );

arg type => (
    isa     => 'SubCmd',
    comment => '',
);

opt status => (
    isa     => 'ArrayRef',
    alias   => 's',
    default => ['active'],
    comment => 'Task/Issue status or state',
);

opt phase => (
    isa     => 'ArrayRef',
    alias   => 'p',
    default => [qw/define plan run/],
    comment => 'Project phase',
);

subcmd( qw/list projects/, 'Project, Title, Phase, Progress, Active, Stalled' );

subcmd( qw/list tasks/, 'list tasks' );

arg project => (
    isa     => 'Str',
    comment => 'project to limit tasks to',
);

subcmd( qw/list issues/, 'list issues' );

arg project => (
    isa     => 'Str',
    comment => 'project to limit issues to',
);

subcmd( qw/list hubs/, 'list hub references' );

subcmd( qw/list links/, 'list threads linked to a hub' );

subcmd( qw/list project-threads/, 'list project threads by ID, Topic, State' );

### show ###
subcmd( qw/show/, 'display current status of a thread' );

arg thread => (
    isa      => 'Str',
    comment  => 'thread ID or project name',
    required => 1,
);

### log ###
subcmd( qw/log/, 'review the history of an thread' );

arg thread => (
    isa     => 'Str',
    comment => 'task ID, issue ID or project name',
);

### update ###
subcmd( qw/update/, 'comment on or modify a thread\'s status' );

arg thread => (
    isa      => 'Str',
    required => 1,
    comment  => 'task ID, issue ID or project name',
);

opt name => (
    isa     => 'Str',
    alias   => 'n',
    comment => 'Name',
);

opt phase => (
    isa     => 'Str',
    alias   => 'p',
    comment => 'Phase',
);

opt state => (
    isa     => 'Str',
    alias   => 's',
    comment => 'State',
);

opt thread_type => (
    isa     => 'Str',
    comment => 'Thread Type',
);

opt author => (
    isa     => 'Str',
    comment => 'Author',
);

opt lang => (
    isa     => 'Str',
    comment => 'Lang',
);

opt locale => (
    isa     => 'Str',
    comment => 'Locale',
);

opt title => (
    isa     => 'Str',
    comment => 'Title',
);

opt comment => (
    isa     => 'Str',
    comment => 'Comment',
);

opt add_kind => (
    isa     => 'Str',
    comment => 'Add a new project state (kind)',
);

opt add_state => (
    isa     => 'Str',
    comment => 'Add a new project state (state)',
);

opt add_status => (
    isa     => 'Str',
    comment => 'Add a new project state (status)',
);

opt add_rank => (
    isa     => 'Str',
    comment => 'Add a new project state (rank)',
);

opt add_def => (
    isa     => 'Str',
    comment => 'Add a new project state (default)',
);

### drop ###
subcmd( qw/drop/, 'remove a thread from the database' );

arg thread => (
    isa      => 'Str',
    required => 1,
    comment  => 'task ID, issue ID or project name',
);

opt force => (
    isa     => 'Bool',
    alias   => 'f',
    comment => 'Do not ask for confirmation',
);

### upgrade ###
subcmd( qw/upgrade/, 'upgrade a Curo repository' );

arg hub => (
    isa     => 'Str',
    comment => 'location if this is a hub upgrade',
);

### pull ###
subcmd( qw/pull/, 'fetch a thread from a hub' );

arg thread => (
    isa      => 'Str',
    required => 1,
    comment  => 'remote task ID, issue ID or project name',
);

arg hub => (
    isa      => 'Str',
    required => 1,
    comment  => 'hub repository address or alias',
);

arg project => (
    isa     => 'Str',
    comment => 'local project path',
);

opt force => (
    isa     => 'Bool',
    alias   => 'f',
    comment => 'force pull even though already in database',
);

### push ###
subcmd( qw/push/, 'send a thread to a hub' );

arg thread => (
    isa      => 'Str',
    required => 1,
    comment  => 'task ID, issue ID or project name',
);

arg hub => (
    isa      => 'Str',
    required => 1,
    comment  => 'hub repository address or alias',
);

arg project => (
    isa     => 'Str',
    comment => 'remote project path',
);

### sync ###
subcmd( qw/sync/, 'exchange updates with a hub' );

arg thread => (
    isa     => 'Str',
    comment => 'task ID, issue ID or project name',
);

arg hub => (
    isa     => 'Str',
    comment => 'hub repository address or alias',
);

# Now add user defined aliases

sub run {
    my $opts = shift;
    require App::curo::Util;

    my $config = App::curo::Util::find_conf($opts);

    if ( my $alias = $config->{alias}->{ $opts->{command} } ) {
        if ( my @cmd = split( ' ', $config->{alias}->{ $opts->{command} } ) ) {
            return dispatch( 'run', __PACKAGE__, @cmd );
        }
    }
    die usage("Unknown COMMAND or ALIAS: $opts->{command}");
}

1;
__END__


=head1 NAME

App::curo::Cmd - federated project management system

=head1 DESCRIPTION

See L<curo>(1) for details.

=head1 SEE ALSO

L<Curo>

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

=cut
