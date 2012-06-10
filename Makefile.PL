use inc::Module::Install;

name 'App-curo';
abstract 'Distributed Project Management System';
author 'Mark Lawrence <nomad@null.net>';
license 'gpl3';
readme_from 'bin/curo';
perl_version '5.006';
version '0.0.2_01';

feature 'core' => (
    -default           => 1,
    'Carp'             => 0,
    'Digest::SHA1'     => 0,
    'DBD::SQLite'      => '1.37',
    'Log::Any'         => 0,
    'Moo'              => 0,
    'SQL::DB'          => '0.191.0',
    'SQL::DBx::Deploy' => 0,
    'SQL::DBx::SQLite' => 0,
    'Time::Piece'      => 0,
);

feature 'sync' => (
    -default           => 1,
    'AnyEvent'         => 0,
    'AnyEvent::Handle' => 0,
    'JSON::XS'         => 0,
    'Sys::Cmd'         => '0.08',
);

feature 'cmdline' => (
    -default             => 1,
    'Cwd'                => 0,
    'Exporter::Tidy'     => 0,
    'File::Basename'     => 0,
    'File::chdir'        => 0,
    'File::HomeDir'      => 0,
    'File::Temp'         => 0,
    'IO::Pager'          => '0.24',
    'Log::Dispatch'      => 0,
    'OptArgs'            => 0,
    'Path::Class'        => 0,
    'Proc::InvokeEditor' => 0,
    'Term::ANSIColor'    => 0,
    'Term::Prompt'       => 0,
    'Term::Size'         => 0,
    'Text::Autoformat'   => 0,
    'Text::FormatTable'  => 0,
    'Time::Duration'     => 0,
    'Try::Tiny'          => 0,
);

test_requires 'IO::Capture::Stdout' => 0;
test_requires 'Test::More'          => 0;
test_requires 'Test::Exception'     => 0;
test_requires 'Test::Database'      => '1.11';
test_requires 'FindBin'             => 0;

author_tests 'xt';

install_script 'bin/curo';
install_script 'bin/curo-sync';

repository 'https://github.com/mlawren/curo';

auto_install;

WriteAll;

