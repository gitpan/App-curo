use inc::Module::Install;

name 'App-curo';
abstract 'Distributed Project Management Database';
author 'Mark Lawrence <nomad@null.net>';
license 'gpl3';
perl_version '5.006';
version '0.01_02';

requires 'AnyEvent'                  => 0;
requires 'AnyEvent::Handle'          => 0;
requires 'Carp'                      => 0;
requires 'Cwd'                       => 0;
requires 'Data::UUID'                => 0;
requires 'EV'                        => 0;
requires 'File::HomeDir'             => 0;
requires 'File::Spec::Functions'     => 0;
requires 'Getopt::Long::Descriptive' => 0;
requires 'JSON::XS'                  => 0;
requires 'Log::Any'                  => 0;
requires 'Moo'                       => 0;
requires 'SQL::DB'                   => '0.19_11';
requires 'SQL::DBx::Deploy'          => 0;
requires 'SQL::DBx::Sequence'        => 0;
requires 'SQL::DBx::Simple'          => 0;
requires 'Sub::Exporter'             => 0;
requires 'Sys::Cmd'                  => '0.07_2';
requires 'Try::Tiny'                 => 0;
requires 'Term::ANSIColor'           => 0;
requires 'Term::Prompt'              => 0;
requires 'Time::Duration'            => 0;
requires 'Time::Local'               => 0;

test_requires 'Test::More'      => 0;
test_requires 'Test::Exception' => 0;
test_requires 'Test::Database'  => 1.11;
test_requires 'File::Temp'      => 0;
test_requires 'FindBin'         => 0;

install_script 'bin/curo';
install_script 'bin/curo-sync';

repository 'git://github.com/mlawren/curo.git';

WriteAll;

