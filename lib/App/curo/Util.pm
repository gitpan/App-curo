package App::curo::Util; our $VERSION = '0.01_02';
use strict;
use warnings;
use Cwd qw/abs_path/;
use File::Spec::Functions qw/splitdir catdir catfile/;
use Log::Any qw/$log/;
use Sub::Exporter -setup => {
    exports => [
        qw/
          find_conf
          find_db
          check_project
          start_pager
          end_pager
          render_table
          prompt_edit
          add_debug
          spin
          clear_spin
          color
          /
    ],
    groups => {
        default => [
            qw/
              find_conf
              find_db
              check_project
              start_pager
              end_pager
              render_table
              prompt_edit
              add_debug
              spin
              clear_spin
              color
              /
        ],
    }
};

binmode STDIN,  ':encoding(utf8)';
binmode STDOUT, ':encoding(utf8)';

my $db;
my $dispatcher;

my $added;

sub add_debug {
    my $what = shift || return;
    return if $added;

    if ( $what eq 'all' ) {
        $what = qr/.*/;
    }

    require Log::Any::Adapter;
    require Log::Dispatch;
    require Log::Dispatch::Screen;

    $dispatcher = Log::Dispatch->new;
    Log::Any::Adapter->set( { category => $what },
        'Dispatch', dispatcher => $dispatcher );

    $dispatcher->add(
        Log::Dispatch::Screen->new(
            name      => 'screendebug',
            min_level => 'debug',

            #            max_level => 'debug',
            stderr  => 0,
            newline => 1,
        )
    );
    $added++;
}

sub find_conf {
    require Curo::Config;
    my $opt = shift;
    my $app = shift || 'curo';

    return $db if $db;

    if ( my $what = $opt->{debug} ) {
        add_debug($what);
    }

    my $dir = _next_dir_up( '.' . $app );
    if ( !$dir ) {
        die "Directory not found (or any parent directories): .$app\n";
    }

    return Curo::Config->read( catfile( $dir, 'config' ) );
}

sub find_db {
    my $opt = shift;
    my $app = shift || 'curo';

    return $db if $db;

    if ( my $what = $opt->{debug} ) {
        add_debug($what);
    }

    my $dir = _next_dir_up( '.' . $app );
    if ( !$dir ) {
        die "Directory not found (or any parent directories): .$app\n";
    }

    require Curo;
    return $db = Curo->new( dir => $dir, );
}

sub _next_dir_up {
    my $dir = shift || die 'next_dir_up($dir)';

    my $oldmatch = '';
    my $match    = abs_path($dir);

    $log->debug( "next_dir_up: start:", $match );
    while ( !-d $match ) {
        $oldmatch = $match;

        my @dirs = splitdir($match);
        pop @dirs;
        pop @dirs;
        $match = catdir( @dirs, $dir );

        $log->debug( "next_dir_up: trying ", $match );

        if ( $match eq $oldmatch or $match eq $dir ) {
            $log->debug("next_dir_up: giving up");
            return;
        }
    }

    $log->debug( "next_dir_up: returning ", $match );
    return $match;
}

sub check_project {
    my $path         = shift;
    my $parent_check = shift;
    my $db           = find_db;

    $db->path2project_id($path) || do {
        die "fatal: parent project not found: $path\n" if $parent_check;
        die "fatal: project not found: $path\n";
    };
    return 1;
}

sub prompt_edit {
    my %args = (
        opt            => {},
        name           => '',
        abort_on_empty => 1,
        val            => '',
        txt            => "

# Please enter your message. Lines starting with '#'
# will be ignored. Empty content aborts the change.
#
# Attributes are as follows:
",
        @_,
    );
    my $ref = shift;

    use Term::Prompt;

    print color('dark') . "(\"/e\" to edit)\n" . color('reset');

    # Undocumented feature of Term::Prompt - uppercase X means a simple
    # return is ok.
    my $val = prompt( 'X', $args{name} . ':', '', $args{val} );
    $val = undef if $val eq '';

    if ( defined $val && $val eq '/e' ) {
        while ( my ( $k, $val ) = each %{ $args{opt} } ) {
            no warnings 'uninitialized';
            $args{txt} .= "#     $k: $val\n";
        }

        require Proc::InvokeEditor;
        $val = Proc::InvokeEditor->edit( $args{txt} );
        utf8::decode($val);
        $val =~ s/^#.*//gm;

        if ( $args{abort_on_empty} and $val ne '.' ) {
            error("Aborting due to empty content.") if $val =~ m/^[\s\n]*$/;
        }
    }

    $val =~ s/^\n+//s   if defined $val;
    $val =~ s/\n*$/\n/s if defined $val;
    return $val;
}

my $pager;

sub start_pager {
    return if $ENV{CURO_NO_PAGER};
    local $ENV{'LESS'} = '-FSXeR';
    local $ENV{'MORE'} = '-FXer' unless $^O =~ /^MSWin/;

    require IO::Pager;
    $pager = IO::Pager->new;
    binmode( $pager->[1], ':encoding(utf8)' ) if $pager;
}

sub end_pager {
    undef $pager;
    return;
}

sub render_table {
    my $format = shift;
    my $header = shift;
    my $data   = shift;

    require Text::FormatTable;
    require Term::Size;

    my $table = Text::FormatTable->new($format);

    if ($header) {
        $table->head( color('bold') . ( shift @$header ), @$header );
        $table->rule( color('bold') . '-' );
    }

    foreach my $row (@$data) {
        $table->row(@$row);
    }

    return $table->render( ( Term::Size::chars() )[0] );
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

1;

__END__

=head1 NAME

App::curo::Util - Curo command-line functions

=head1 DESCRIPTION

=over 4

=item check_project($path, $parent_check) -> Bool

=item promptedit -> str

=item is_interactive -> bool

=item get_pager -> str

=item start_pager -> bool

=item in_pager -> bool

=item end_pager -> undef

=item render_table -> Str

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
