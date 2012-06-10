package App::curo::Util; our $VERSION = '0.0.2';
use strict;
use warnings;
use utf8;
use Carp qw/croak/;
use Exporter::Tidy default => [
    qw/ find_repo find_conf find_db short check_project check_thread check_hub
      start_pager end_pager render_table prompt_edit is_debug add_debug
      spin clear_spin color line_print not_implemented/
];
use Log::Any qw/$log/;
use Log::Any::Adapter;
use Path::Class;

binmode STDIN, ':encoding(utf8)';
binmode STDOUT, ':encoding(utf8)' unless ref( \*STDOUT );

my $conf;
my $db;

my $entry = Log::Any::Adapter->set(
    { category => qr/.*/ },
    'Dispatch',
    outputs => [
        [
            'Screen',
            name      => 'screen',
            min_level => 'error',
            stderr    => 1,
            newline   => 1,
        ],
    ]
);

my $is_debug;
sub is_debug { $is_debug }

sub add_debug {
    my $thread = shift || return;

    $is_debug++;

    start_pager() if $ENV{CURO_DEBUG_PAGER};

    Log::Any::Adapter->remove($entry);

    Log::Any::Adapter->set(
        { category => $thread eq 'all' ? qr/.*/ : qr/$thread/ },
        'Dispatch',
        outputs => [
            [
                'Screen',
                name      => 'debug',
                min_level => 'debug',
                stderr    => 0,
                newline   => 1,
            ],
        ]
    );
}

sub find_repo {
    my $match = dir()->absolute;

    until ( -d $match->subdir('.curo') ) {
        my $oldmatch = $match;
        $match = $match->parent;

        die "fatal: directory not found "
          . "(or any parent directories): .curo\n"
          if $match eq $oldmatch;
    }

    return $match->subdir('.curo');
}

sub find_conf {
    my $opt = shift;

    return $conf if $conf;

    add_debug( $opt->{debug} ) if $opt->{debug};

    my $repo = find_repo;

    require App::curo::Config;
    require File::HomeDir;

    $conf = App::curo::Config->read( $repo->file('config'), 'UTF-8' )
      || confess $App::curo::Config::errstr;

    my $gitconfig = App::curo::Config->read(
        dir( File::HomeDir->my_home )->file('.gitconfig'), 'UTF-8' )
      || confess $App::curo::Config::errstr;

    $gitconfig->{user}->{name}  =~ s/(^")|("$)//g;
    $gitconfig->{user}->{email} =~ s/(^")|("$)//g;

    $conf->{user}->{name}  ||= $gitconfig->{user}->{name};
    $conf->{user}->{email} ||= $gitconfig->{user}->{email};

    $conf->{_}->{dsn} ||= 'dbi:SQLite:dbname=' . $repo->file('curo.sqlite');

    return $conf;
}

sub find_db {
    my $opt = shift;

    return $db if $db;
    croak 'find_db($opts) when called first time' unless $opt;

    my $config = find_conf($opt);

    require Curo;
    $db = Curo->new(
        dsn      => $conf->{_}->{dsn},
        username => $conf->{_}->{username},
        password => $conf->{_}->{password},
    );

    $db->sqlite_create_function_debug if $opt->{debug};

    return $db;
}

sub short {
    $_[0] || return '*undef*';
    ( my $x = shift @_ ) =~ s/^(........).*/$1/g;
    return $x;
}

sub check_project {
    my $path         = shift;
    my $parent_check = shift;
    my $db           = find_db;

    return $db->path2project_id($path) || do {
        die "fatal: parent project not found: $path\n" if $parent_check;
        die "fatal: project not found: $path\n";
    };
}

sub check_thread {
    my $opts = shift           || croak 'missing $opts';
    my $id   = $opts->{thread} || '';
    my $db   = find_db;

    if ( $id =~ m/^\d+$/ and my $type = $db->id2thread_type($id) ) {
        $opts->{id} = $id;
        $log->debugf( 'check_thread(%s) -> %s', $id, $type );
        return $type;
    }
    elsif ( my $pid = check_project($id) ) {
        $opts->{id} = $pid;
        $log->debugf( 'check_thread(%s) -> %s (%d)', $id, 'project', $pid );
        return 'project';
    }
    else {
        die "fatal: WHAT not found: $id\n";
    }
    return;
}

sub check_hub {
    my $opts = shift;
    my $db   = find_db;
    my $hub;

    delete $opts->{location};

    if ( $hub = $db->name2hub( $opts->{hub} ) ) {
        $opts->{location} = $hub->location;
    }
    elsif ( $hub = $db->location2hub( $opts->{hub} ) ) {
        $opts->{location} = $hub->location;
    }
    elsif ( $hub = $db->location2hub( dir( $opts->{hub} )->absolute ) ) {
        $opts->{location} = $hub->location;
    }
    elsif ( $opts->{hub} =~ m!^ssh://! ) {
        $opts->{location} = $opts->{hub};
    }

    my $dir = dir( $opts->{hub} )->absolute;

    if ( -d ( my $subdir = $dir->subdir('.curo') ) ) {
        $opts->{location} = $subdir;
    }
    elsif ( -d $dir ) {
        $opts->{location} = $dir;
    }

    return if exists $opts->{location};
    die "fatal: hub (or directory) not found: $opts->{hub}\n";
}

sub prompt_edit {
    my %args = (
        opts           => {},
        abort_on_empty => 1,
        val            => '',
        txt            => "

# Please enter your message. Lines starting with '#'
# are ignored. Empty content aborts.
#
",
        @_,
    );

    foreach my $key ( sort keys %{ $args{opts} } ) {
        next unless defined $args{opts}->{$key};
        $args{txt} .= "#     $key: $args{opts}->{$key}\n";
    }

    my $val;

    if ( -t STDIN ) {
        require Proc::InvokeEditor;
        $val = Proc::InvokeEditor->edit( $args{txt} );
        utf8::decode($val);
    }
    else {
        $val = join( '', <STDIN> );
    }

    $val =~ s/^#.*//gm;

    if ( $args{abort_on_empty} ) {
        die "aborting due to empty content.\n"
          if $val =~ m/^[\s\n]*$/s;
    }

    $val =~ s/^\n+//s;
    $val =~ s/\n*$/\n/s;
    return $val;
}

my $pager;

sub start_pager {
    return if $pager;
    local $ENV{'LESS'} = '-FSXeR';
    local $ENV{'MORE'} = '-FXer' unless $^O =~ /^MSWin/;

    require IO::Pager;
    $pager = IO::Pager->new(*STDOUT);

    $pager->binmode(':encoding(utf8)') if ref $pager;
}

sub end_pager {
    undef $pager;
    return;
}

sub render_table {
    my $format = shift;
    my $header = shift;
    my $data   = shift;
    my $indent = shift || 0;

    require Text::FormatTable;
    require Term::Size;

    my $table = Text::FormatTable->new($format);

    if ($header) {
        $header->[0] = color('bold') . $header->[0];
        push( @$header, ( pop @$header ) . color('reset') );
        $table->head(@$header);
        if ( -t STDOUT ) {
            $table->rule('–');
        }
        else {
            $table->rule('-');
        }
    }

    foreach my $row (@$data) {
        $table->row(@$row);
    }

    return $table->render( ( Term::Size::chars() )[0] ) unless $indent;

    my $prefix = ' ' x $indent;
    my $str = $table->render( ( Term::Size::chars() )[0] - $indent );

    $str =~ s/^/$prefix/gm;
    return $str;
}

my $drawn;

sub spin {
    if ($drawn) {
        print "\b ";
        $drawn = 0;
    }
    else {
        print "\b" if defined $drawn;
        print ".";
        $drawn = 1;
    }
}

sub clear_spin {
    print "\b" if defined $drawn;
}

sub color {
    require Term::ANSIColor;
    return Term::ANSIColor::color(@_) if -t STDOUT;
    return '';
}

my $msg = "";

sub line_print {
    $|++;

    print ' ' x length($msg), "\b" x length($msg), $_[0], "\r";
    $msg = $_[0];
}

sub not_implemented {
    die "fatal: sorry, not implemented yet: $_[0]\n";
}

1;

__END__

=head1 NAME

App::curo::Util - Curo command-line functions

=head1 SYNOPSIS

    use App::curo::Util;

=head1 DESCRIPTION

Utility functions for App::curo::* scripts.

=over 4

=item find_repo -> Str

Return the path to the first '.curo' directory found starting from the
current working directory and searching upwards. Dies on failure.

=item find_conf -> App::curo::Config

Undocumented.


=item find_db -> Curo


Undocumented.

=item short($str) -> Str

Return the first 8 characters of $str or the string '*undef*' if $str
is undefined.

=item check_project {


Undocumented.

=item prompt_edit {


Undocumented.

=item start_pager {


Undocumented.

=item end_pager {


Undocumented.

=item render_table {


Undocumented.

=item spin {


Undocumented.

=item clear_spin {

Undocumented.


=item color {

Undocumented.

=back

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

=cut
