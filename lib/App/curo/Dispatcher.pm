# Do not modify!
# This file is autogenerated and your changes will be overwritten.
package App::curo::Dispatcher;
use Getopt::Long::Descriptive qw/describe_options prog_name/;
use strict;
use warnings;

our $VERSION = '0.11';

my $me = prog_name;

my $program = {
    'App::curo::push' => {
        'opt_spec' => [
            [ 'help|h',    'print usage message and exit' ],
            [ 'debug|d=s', 'Enable debugging output' ]
        ],
        'arg_spec' => [
            [ 'src=s',  'What to push',        {} ],
            [ 'dest=s', 'Where to push it to', {} ]
        ],
        'name'          => 'push',
        'usage_desc'    => 'usage: %c push [options] [SRC] [DEST]',
        'order'         => 9,
        'class'         => 'App::curo::push',
        'abstract'      => 'Send updates to a hub',
        'require_order' => 0,
        'getopt_conf'   => [ 'permute' ]
    },
    'App::curo::list' => {
        'opt_spec' => [
            [ 'help|h',    'print usage message and exit' ],
            [ 'debug|d=s', 'Enable debugging output' ]
        ],
        'arg_spec' => [ [ 'project=s', 'what to list', {} ] ],
        'name' => 'list',
        'usage_desc'    => 'usage: %c list [options] [PROJECT]',
        'order'         => 5,
        'class'         => 'App::curo::list',
        'abstract'      => 'List project tasks and issues',
        'require_order' => 0,
        'getopt_conf'   => [ 'permute' ]
    },
    'App::curo::new::project' => {
        'opt_spec' => [
            [ 'help|h', 'print usage message and exit' ],
            [ 'phase=s',     'Phase', { 'default' => 'run' } ],
            [ 'author=s',    'Author' ],
            [ 'ctime=s',     'Created' ],
            [ 'email=s',     'Email' ],
            [ 'lang=s',      'Lang' ],
            [ 'locale=s',    'Locale' ],
            [ 'title=s',     'Title' ],
            [ 'comment|c=s', 'Comment' ],
            [ 'debug|d=s', 'Enable debugging output' ]
        ],
        'arg_spec' => [ [ 'name=s', 'Project Name', {} ] ],
        'name' => 'project',
        'usage_desc'    => 'usage: %c new project [options] [NAME]',
        'order'         => 2147483647,
        'class'         => 'App::curo::new::project',
        'abstract'      => 'insert a new project into the database',
        'require_order' => 0,
        'getopt_conf'   => [ 'permute' ]
    },
    'App::curo::list::hubs' => {
        'opt_spec' => [
            [ 'help|h',    'print usage message and exit' ],
            [ 'debug|d=s', 'Enable debugging output' ]
        ],
        'arg_spec'      => [],
        'name'          => 'hubs',
        'usage_desc'    => 'usage: %c list hubs [options]',
        'order'         => 20,
        'class'         => 'App::curo::list::hubs',
        'abstract'      => 'List project hubs',
        'require_order' => 0,
        'getopt_conf'   => [ 'permute' ]
    },
    'App::curo::update::task' => {
        'opt_spec' => [
            [ 'help|h',        'print usage message and exit' ],
            [ 'status|s=s',    'Status' ],
            [ 'thread_type=s', 'Thread Type' ],
            [ 'parent-id=s',   'Parent ID' ],
            [ 'author=s',      'Author' ],
            [ 'ctime=s',       'Created' ],
            [ 'email=s',       'Email' ],
            [ 'lang=s',        'Lang' ],
            [ 'locale=s',      'Locale' ],
            [ 'title=s',       'Title' ],
            [ 'comment=s',     'Comment' ],
            [ 'debug|d=s',     'Enable debugging output' ]
        ],
        'arg_spec' => [ [ 'task_id=s', 'ID', { 'required' => 1 } ] ],
        'name' => 'task',
        'usage_desc'    => 'usage: %c update task [options] TASK_ID',
        'order'         => 2147483647,
        'class'         => 'App::curo::update::task',
        'abstract'      => 'comment or modify an task',
        'require_order' => 0,
        'getopt_conf'   => [ 'permute' ]
    },
    'App::curo::update' => {
        'opt_spec' => [
            [ 'help|h',    'print usage message and exit' ],
            [ 'debug|d=s', 'Enable debugging output' ]
        ],
        'arg_spec' =>
          [ [ 'what=s', 'ID or project name', { 'required' => 1 } ] ],
        'name'          => 'update',
        'usage_desc'    => 'usage: %c update [options] WHAT',
        'order'         => 7,
        'class'         => 'App::curo::update',
        'abstract'      => 'Comment or modify something',
        'require_order' => 1,
        'getopt_conf'   => [ 'require_order' ]
    },
    'App::curo::update::issue' => {
        'opt_spec' => [
            [ 'help|h',        'print usage message and exit' ],
            [ 'status|s=s',    'Status' ],
            [ 'thread_type=s', 'Thread Type' ],
            [ 'parent-id=s',   'Parent ID' ],
            [ 'author=s',      'Author' ],
            [ 'ctime=s',       'Created' ],
            [ 'email=s',       'Email' ],
            [ 'lang=s',        'Lang' ],
            [ 'locale=s',      'Locale' ],
            [ 'title=s',       'Title' ],
            [ 'comment=s',     'Comment' ],
            [ 'debug|d=s',     'Enable debugging output' ]
        ],
        'arg_spec' => [ [ 'issue_id=s', 'ID', { 'required' => 1 } ] ],
        'name' => 'issue',
        'usage_desc'    => 'usage: %c update issue [options] ISSUE_ID',
        'order'         => 2147483647,
        'class'         => 'App::curo::update::issue',
        'abstract'      => 'comment or modify an issue',
        'require_order' => 0,
        'getopt_conf'   => [ 'permute' ]
    },
    'App::curo::status' => {
        'opt_spec' => [
            [ 'help|h',         'print usage message and exit' ],
            [ 'issue-status=s', 'Status' ],
            [ 'debug|d=s',      'Enable debugging output' ]
        ],
        'arg_spec' =>
          [ [ 'project=s', 'Project to list sub-projects for', {} ] ],
        'name'          => 'status',
        'usage_desc'    => 'usage: %c status [options] [PROJECT]',
        'order'         => 8,
        'class'         => 'App::curo::status',
        'abstract'      => 'Show project status',
        'require_order' => 0,
        'getopt_conf'   => [ 'permute' ]
    },
    'App::curo::list::issues' => {
        'opt_spec' => [
            [ 'help|h',      'print usage message and exit' ],
            [ 'status|s=s',  'Status' ],
            [ 'progress=s',  'Progress' ],
            [ 'order=s',     'Progress' ],
            [ 'project|p=s', 'Project to list issues for' ],
            [ 'asc',         'Ascending order' ],
            [ 'debug|d=s',   'Enable debugging output' ]
        ],
        'arg_spec' => [ [ 'project=s', 'Project name', {} ] ],
        'name' => 'issues',
        'usage_desc'    => 'usage: %c list issues [options] [PROJECT]',
        'order'         => 20,
        'class'         => 'App::curo::list::issues',
        'abstract'      => 'List project issues',
        'require_order' => 0,
        'getopt_conf'   => [ 'permute' ]
    },
    'App::curo::log' => {
        'opt_spec' => [
            [ 'help|h',    'print usage message and exit' ],
            [ 'title|t',   'Include title in log summary' ],
            [ 'debug|d=s', 'Enable debugging output' ]
        ],
        'arg_spec' => [ [ 'what=s', 'ID or project name', {} ] ],
        'name' => 'log',
        'usage_desc'    => 'usage: %c log [options] [WHAT]',
        'order'         => 6,
        'class'         => 'App::curo::log',
        'abstract'      => 'Review update history',
        'require_order' => 0,
        'getopt_conf'   => [ 'permute' ]
    },
    'App::curo::upgrade' => {
        'opt_spec' => [
            [ 'help|h',    'print usage message and exit' ],
            [ 'hub',       'Initialize a database \'hub\'' ],
            [ 'debug|d=s', 'Enable debugging output' ]
        ],
        'arg_spec' =>
          [ [ 'directory=s', 'location of the database or hub', {} ] ],
        'name'          => 'upgrade',
        'usage_desc'    => 'usage: %c upgrade [options] [DIRECTORY]',
        'order'         => 20,
        'class'         => 'App::curo::upgrade',
        'abstract'      => 'Upgrade existing database or hub',
        'require_order' => 0,
        'getopt_conf'   => [ 'permute' ]
    },
    'App::curo::new' => {
        'opt_spec' => [ [ 'help|h', 'print usage message and exit' ] ],
        'arg_spec' => [
            [ 'type=s', 'the kind of sometime to create', { 'required' => 1 } ]
        ],
        'name'          => 'new',
        'usage_desc'    => 'usage: %c new [options] TYPE',
        'order'         => 4,
        'class'         => 'App::curo::new',
        'abstract'      => 'Create something new',
        'require_order' => 0,
        'getopt_conf'   => [ 'permute' ]
    },
    'App::curo::list::tasks' => {
        'opt_spec' => [
            [ 'help|h',      'print usage message and exit' ],
            [ 'status|s=s',  'Status' ],
            [ 'progress=s',  'Progress' ],
            [ 'order=s',     'Progress' ],
            [ 'project|p=s', 'Project to list tasks for' ],
            [ 'asc',         'Ascending order' ],
            [ 'debug|d=s',   'Enable debugging output' ]
        ],
        'arg_spec' => [ [ 'project=s', 'Project name', {} ] ],
        'name' => 'tasks',
        'usage_desc'    => 'usage: %c list tasks [options] [PROJECT]',
        'order'         => 20,
        'class'         => 'App::curo::list::tasks',
        'abstract'      => 'List project tasks',
        'require_order' => 0,
        'getopt_conf'   => [ 'permute' ]
    },
    'App::curo::new::hub' => {
        'opt_spec' => [
            [ 'help|h',    'print usage message and exit' ],
            [ 'debug|d=s', 'Enable debugging output' ]
        ],
        'arg_spec' => [
            [ 'name=s',     'Name',     { 'required' => 1 } ],
            [ 'location=s', 'Location', { 'required' => 1 } ]
        ],
        'name'          => 'hub',
        'usage_desc'    => 'usage: %c new hub [options] NAME LOCATION',
        'order'         => 2147483647,
        'class'         => 'App::curo::new::hub',
        'abstract'      => 'insert a hub into the database',
        'require_order' => 0,
        'getopt_conf'   => [ 'permute' ]
    },
    'App::curo::update::project' => {
        'opt_spec' => [
            [ 'help|h',      'print usage message and exit' ],
            [ 'name|n=s',    'Name' ],
            [ 'phase|p=s',   'Phase' ],
            [ 'parent-id=s', 'Parent ID' ],
            [ 'author=s',    'Author' ],
            [ 'ctime=s',     'Created' ],
            [ 'email=s',     'Email' ],
            [ 'lang=s',      'Lang' ],
            [ 'locale=s',    'Locale' ],
            [ 'title=s',     'Title' ],
            [ 'comment|c=s', 'Comment' ],
            [ 'debug|d=s',   'Enable debugging output' ]
        ],
        'arg_spec' => [ [ 'project=s', 'Project name', { 'required' => 1 } ] ],
        'name'          => 'project',
        'usage_desc'    => 'usage: %c update project [options] PROJECT',
        'order'         => 2147483647,
        'class'         => 'App::curo::update::project',
        'abstract'      => 'comment or modify an project',
        'require_order' => 0,
        'getopt_conf'   => [ 'permute' ]
    },
    'App::curo::new::task' => {
        'opt_spec' => [
            [ 'help|h',        'print usage message and exit' ],
            [ 'status=s',      'Status' ],
            [ 't_id=s',        'ID' ],
            [ 'thread_type=s', 'Thread Type' ],
            [ 'author=s',      'Author' ],
            [ 'ctime=s',       'Created' ],
            [ 'email=s',       'Email' ],
            [ 'lang=s',        'Lang' ],
            [ 'locale=s',      'Locale' ],
            [ 'mtime=s',       'Modified' ],
            [ 'project|p=s',   'Project' ],
            [ 'thread_type=s', 'Thread Type' ],
            [ 'title=s',       'Title' ],
            [ 'comment|c=s',   'Comment' ],
            [ 'debug|d=s',     'Enable debugging output' ]
        ],
        'arg_spec' => [ [ 'project=s', 'Project', {} ] ],
        'name' => 'task',
        'usage_desc'    => 'usage: %c new task [options] [PROJECT]',
        'order'         => 2147483647,
        'class'         => 'App::curo::new::task',
        'abstract'      => 'insert a new task into the database',
        'require_order' => 0,
        'getopt_conf'   => [ 'permute' ]
    },
    'App::curo::new::issue' => {
        'opt_spec' => [
            [ 'help|h',        'print usage message and exit' ],
            [ 'status=s',      'Status' ],
            [ 't_id=s',        'ID' ],
            [ 'thread_type=s', 'Thread Type' ],
            [ 'author=s',      'Author' ],
            [ 'ctime=s',       'Created' ],
            [ 'email=s',       'Email' ],
            [ 'lang=s',        'Lang' ],
            [ 'locale=s',      'Locale' ],
            [ 'mtime=s',       'Modified' ],
            [ 'project|p=s',   'Project' ],
            [ 'thread_type=s', 'Thread Type' ],
            [ 'title=s',       'Title' ],
            [ 'comment|c=s',   'Comment' ],
            [ 'debug|d=s',     'Enable debugging output' ]
        ],
        'arg_spec' => [ [ 'project=s', 'Project', {} ] ],
        'name' => 'issue',
        'usage_desc'    => 'usage: %c new issue [options] [PROJECT]',
        'order'         => 2147483647,
        'class'         => 'App::curo::new::issue',
        'abstract'      => 'insert a new issue into the database',
        'require_order' => 0,
        'getopt_conf'   => [ 'permute' ]
    },
    'App::curo::init' => {
        'opt_spec' => [
            [ 'help|h',    'print usage message and exit' ],
            [ 'prompt|p',  'Prompt for configuration parameters' ],
            [ 'hub',       'Initialize a database \'hub\'' ],
            [ 'debug|d=s', 'Enable debugging output' ]
        ],
        'arg_spec' =>
          [ [ 'directory=s', 'location of the database or hub', {} ] ],
        'name'          => 'init',
        'usage_desc'    => 'usage: %c init [options] [DIRECTORY]',
        'order'         => 2,
        'class'         => 'App::curo::init',
        'abstract'      => 'Setup a new database or hub',
        'require_order' => 0,
        'getopt_conf'   => [ 'permute' ]
    },
    'App::curo' => {
        'opt_spec' => [ [ 'help|h', 'print usage message and exit' ] ],
        'arg_spec' =>
          [ [ 'command=s', 'command to run', { 'required' => 1 } ] ],
        'name'          => 'curo',
        'usage_desc'    => 'usage: %c [options] COMMAND [...]',
        'order'         => 2147483647,
        'class'         => 'App::curo',
        'abstract'      => 'Distributed Database Tool',
        'require_order' => 1,
        'getopt_conf'   => [ 'require_order' ]
    }
};

sub _commands {
    my $cmd = shift;
    require List::Util;

    my @commands =
      grep { $_->{class} =~ m/${cmd}::/ and not $_->{class} =~ m/${cmd}::.*:/ }
      values %$program;

    return unless @commands;

    my $max = 4 + List::Util::max( map { length $_->{name} } @commands );

    return
      map { sprintf( "    %-${max}s %s\n", $_->{name}, $_->{abstract} ) }
      sort { $a->{order} <=> $b->{order} } @commands;
}

sub _message {
    my ( $cmd, $usage, $abstract ) = @_;

    my $str = $usage->text;
    $str .= "\n($program->{$cmd}->{abstract})\n" if $abstract;

    my @arg_spec = @{ $program->{$cmd}->{arg_spec} };
    return unless @arg_spec;

    my @commands = _commands($cmd);

    if (@commands) {
        my $x = $arg_spec[0]->[0];
        $x =~ s/[\|=].*//;

        $str .= "\nValid values for " . ( uc $x ) . " include:\n";
        $str .= join( '', @commands );
    }
    return $str;
}

sub _usage {
    die _message(@_);
}

sub _help {
    print STDOUT _message( @_, 1 );
}

my $DEBUG = 0;
my %RAN   = ();

sub _dispatch {
    my $class = shift;
    if (@_) {
        @ARGV = @_;
    }

    my $cmd       = 'App::curo';
    my @ORIG_ARGV = @ARGV;

    # Look for a subcommand
    while ( @ARGV && exists $program->{ $cmd . '::' . $ARGV[0] } ) {
        $cmd = $cmd . '::' . shift @ARGV;
    }

    my ( $opt, $usage ) = describe_options(
        $program->{$cmd}->{usage_desc},
        @{ $program->{$cmd}->{opt_spec} },
        { getopt_conf => $program->{$cmd}->{getopt_conf} },
    );

    if ( $opt->can('help') && $opt->help ) {
        return _help( $cmd, $usage );
    }

    my @arg_spec = @{ $program->{$cmd}->{arg_spec} };

    # Missing a required argument?
    my @narg_spec = @arg_spec;
    while ( scalar @narg_spec > scalar @ARGV ) {

        my $arg = pop @narg_spec;
        next unless ( exists $arg->[2]->{required} );

        _usage( $cmd, $usage );
        return;
    }

    # Now rebuild the whole command line that includes options and
    # arguments together.
    my @newargv;
    my @remainder;

    my $i = 0;
    while (@ARGV) {
        my $val = shift @ARGV;
        if ( !@arg_spec ) {
            @remainder = ( $val, @ARGV );
            last;
        }
        my $arg = shift @arg_spec;
        my $x   = $arg->[0];
        $x =~ s/[|=].*//;
        push( @newargv, '--' . $x, $val );
    }

    @ARGV = @newargv;

    my ( $new_opt, $new_usage ) = describe_options(
        $program->{$cmd}->{usage_desc},
        @{ $program->{$cmd}->{arg_spec} },
        map { [ $_->[0], $_->[1] ] }    # ignore 'require', 'default'
          @{ $program->{$cmd}->{opt_spec} },
    );

    while ( my ( $key, $val ) = each %$opt ) {
        $new_opt->{$key} = $val;
    }
    $opt = $new_opt;

    @ARGV = @remainder;

    if ( !$RAN{$cmd} ) {

        eval "require $cmd";    ## no critic
        die $@ if $@;

        ( my $plugin_file = $cmd . '.pm' ) =~ s!::!/!g;
        my $file = $INC{$plugin_file};

        if ( -M $file < -M __FILE__ ) {
            warn "warning: "
              . __PACKAGE__
              . " is out of date:\n    "
              . scalar localtime( ( stat(__FILE__) )[9] ) . " "
              . __FILE__
              . "\n    "
              . scalar localtime( ( stat($file) )[9] )
              . " $file\n";
        }

        # FIXME move this check into App::Dispatcher?
        if ( !$cmd->can('run') ) {
            _usage( $cmd, $usage );
            die "$cmd missing run() method or 'required' attribute on arg 1\n";
        }

        {
            no strict 'refs';    ## no critic
            *{ $cmd . '::opt' } = sub { $opt };
            *{ $cmd . '::usage' } = sub { _message( $cmd, $usage ) };
            *{ $cmd . '::dispatch' } = sub {
                shift;
                $DEBUG = 1 if $opt->can('debug_dispatcher');
                $class->_dispatch(@_);
            };
        }
        $RAN{$cmd}++;
    }

    return $cmd->run($opt);

}

sub run {
    my $class = shift;
    $class->_dispatch(@_);
}

1;
__END__


=head1 NAME

App::curo::Dispatcher - Dispatcher for App::curo commands

=head1 SYNOPSIS

  use App::curo::Dispatcher;
  App::curo::Dispatcher->run;

=head1 DESCRIPTION

B<App::curo::Dispatcher> provides option checking, argument checking,
and command dispatching for commands implemented under the App::curo::*
namespace.

This class has a single method:

=over 4

=item run

Dispatch to a L<App::curo> command based on the contents of @ARGV.

=back

This module was automatically generated by L<App::Dispatcher>(3p).

=head1 SEE ALSO

L<App::Dispatcher>(3p), L<app-dispatcher>(1)

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Mark Lawrence E<lt>nomad@null.netE<gt>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

=cut

# vim: set tabstop=4 expandtab:
