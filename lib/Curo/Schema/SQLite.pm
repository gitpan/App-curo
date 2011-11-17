package Curo::Schema::SQLite;
use strict;
require SQL::DB::Schema;

my $VAR1 = [
    [
        undef, 'main', '_deploy', 'id',  undef, 'INTEGER',
        undef, undef,  undef,     undef, 1,     undef,
        undef, undef,  undef,     undef, 1,     'YES'
    ],
    [
        undef, 'main', '_deploy', 'app', undef, 'VARCHAR',
        '40',  undef,  undef,     undef, 0,     undef,
        undef, undef,  undef,     undef, 2,     'NO'
    ],
    [
        undef,               'main',      '_deploy', 'ctime',
        undef,               'TIMESTAMP', undef,     undef,
        undef,               undef,       0,         undef,
        'CURRENT_TIMESTAMP', undef,       undef,     undef,
        3,                   'NO'
    ],
    [
        undef, 'main', '_deploy', 'type', undef, 'VARCHAR',
        '20',  undef,  undef,     undef,  1,     undef,
        undef, undef,  undef,     undef,  4,     'YES'
    ],
    [
        undef, 'main', '_deploy', 'data', undef, 'VARCHAR',
        undef, undef,  undef,     undef,  1,     undef,
        undef, undef,  undef,     undef,  5,     'YES'
    ],
    [
        undef, 'main', 'hubs', 'name', undef, 'varchar',
        '40',  undef,  undef,  undef,  0,     undef,
        undef, undef,  undef,  undef,  1,     'NO'
    ],
    [
        undef, 'main', 'hubs', 'location', undef, 'varchar',
        '255', undef,  undef,  undef,      0,     undef,
        undef, undef,  undef,  undef,      2,     'NO'
    ],
    [
        undef, 'main', 'hubs', 'master', undef, 'integer',
        undef, undef,  undef,  undef,    1,     undef,
        undef, undef,  undef,  undef,    3,     'YES'
    ],
    [
        undef, 'main', 'issue_status_types', 'status', undef, 'varchar', '40',
        undef, undef, undef, 0, undef, undef, undef, undef, undef, 1, 'NO'
    ],
    [
        undef, 'main',    'issue_status_types', 'progress',
        undef, 'varchar', '40',                 undef,
        undef, undef,     0,                    undef,
        undef, undef,     undef,                undef,
        2,     'NO'
    ],
    [
        undef, 'main', 'issue_status_types', 'rank', undef, 'integer', undef,
        undef, undef, undef, 0, undef, undef, undef, undef, undef, 3, 'NO'
    ],
    [
        undef,           'main',
        'issue_updates', 'issue_update_id',
        undef,           'INTEGER',
        undef,           undef,
        undef,           undef,
        0,               undef,
        undef,           undef,
        undef,           undef,
        1,               'NO'
    ],
    [
        undef, 'main', 'issue_updates', 'issue_id', undef, 'integer', undef,
        undef, undef, undef, 0, undef, undef, undef, undef, undef, 2, 'NO'
    ],
    [
        undef, 'main', 'issue_updates', 'status', undef, 'varchar', '40', undef,
        undef, undef, 1, undef, undef, undef, undef, undef, 3, 'YES'
    ],
    [
        undef, 'main', 'issue_updates', 'project_id', undef, 'integer', undef,
        undef, undef, undef, 1, undef, undef, undef, undef, undef, 4, 'YES'
    ],
    [
        undef, 'main',    'issue_updates', 'rm_project_id',
        undef, 'integer', undef,           undef,
        undef, undef,     1,               undef,
        undef, undef,     undef,           undef,
        5,     'YES'
    ],
    [
        undef, 'main', 'issues', 'issue_id', undef, 'INTEGER',
        undef, undef,  undef,    undef,      0,     undef,
        undef, undef,  undef,    undef,      1,     'NO'
    ],
    [
        undef,      'main', 'issues', 'status', undef, 'varchar',
        '40',       undef,  undef,    undef,    0,     undef,
        '\'open\'', undef,  undef,    undef,    2,     'NO'
    ],
    [
        undef,            'main',    'project_phases', 'phase',
        undef,            'varchar', '40',             undef,
        undef,            undef,     0,                undef,
        '\'definition\'', undef,     undef,            undef,
        1,                'NO'
    ],
    [
        undef, 'main', 'project_phases', 'rank', undef, 'integer', undef, undef,
        undef, undef, 0, undef, undef, undef, undef, undef, 2, 'NO'
    ],
    [
        undef, 'main',    'project_threads', 'project_id',
        undef, 'integer', undef,             undef,
        undef, undef,     0,                 undef,
        undef, undef,     undef,             undef,
        1,     'NO'
    ],
    [
        undef, 'main',    'project_threads', 'project_self',
        undef, 'integer', undef,             undef,
        undef, undef,     1,                 undef,
        undef, undef,     undef,             undef,
        2,     'YES'
    ],
    [
        undef, 'main', 'project_threads', 'issue_id', undef, 'integer', undef,
        undef, undef, undef, 1, undef, undef, undef, undef, undef, 3, 'YES'
    ],
    [
        undef, 'main', 'project_threads', 'task_id', undef, 'integer', undef,
        undef, undef, undef, 1, undef, undef, undef, undef, undef, 4, 'YES'
    ],
    [
        undef,             'main',
        'project_threads', 'thread_update_id',
        undef,             'integer',
        undef,             undef,
        undef,             undef,
        0,                 undef,
        undef,             undef,
        undef,             undef,
        5,                 'NO'
    ],
    [
        undef,             'main',
        'project_updates', 'project_update_id',
        undef,             'INTEGER',
        undef,             undef,
        undef,             undef,
        0,                 undef,
        undef,             undef,
        undef,             undef,
        1,                 'NO'
    ],
    [
        undef, 'main', 'project_updates', 'name', undef, 'varchar', '40', undef,
        undef, undef, 1, undef, undef, undef, undef, undef, 2, 'YES'
    ],
    [
        undef, 'main',    'project_updates', 'parent_id',
        undef, 'integer', undef,             undef,
        undef, undef,     1,                 undef,
        undef, undef,     undef,             undef,
        3,     'YES'
    ],
    [
        undef, 'main', 'project_updates', 'phase', undef, 'varchar', '40',
        undef, undef, undef, 1, undef, undef, undef, undef, undef, 4, 'YES'
    ],
    [
        undef, 'main', 'project_updates', 'pref_id', undef, 'integer', undef,
        undef, undef, undef, 1, undef, undef, undef, undef, undef, 5, 'YES'
    ],
    [
        undef, 'main', 'project_updates', 'ref_uuid', undef, 'varchar', '36',
        undef, undef, undef, 1, undef, undef, undef, undef, undef, 6, 'YES'
    ],
    [
        undef, 'main',    'project_updates', 'project_id',
        undef, 'integer', undef,             undef,
        undef, undef,     0,                 undef,
        undef, undef,     undef,             undef,
        7,     'NO'
    ],
    [
        undef, 'main', 'project_updates', 'path', undef, 'varchar', undef,
        undef, undef, undef, 1, undef, undef, undef, undef, undef, 8, 'YES'
    ],
    [
        undef, 'main', 'projects', 'project_id', undef, 'INTEGER', undef, undef,
        undef, undef, 0, undef, undef, undef, undef, undef, 1, 'NO'
    ],
    [
        undef, 'main', 'projects', 'name', undef, 'varchar',
        '40',  undef,  undef,      undef,  0,     undef,
        undef, undef,  undef,      undef,  2,     'NO'
    ],
    [
        undef, 'main',    'projects', 'parent_id',
        undef, 'integer', undef,      undef,
        undef, undef,     1,          undef,
        undef, undef,     undef,      undef,
        3,     'YES'
    ],
    [
        undef, 'main', 'projects', 'phase', undef, 'varchar',
        '40',  undef,  undef,      undef,   0,     undef,
        undef, undef,  undef,      undef,   4,     'NO'
    ],
    [
        undef, 'main', 'projects', 'pref_id', undef, 'integer',
        undef, undef,  undef,      undef,     1,     undef,
        undef, undef,  undef,      undef,     5,     'YES'
    ],
    [
        undef, 'main',    'projects', 'ref_uuid',
        undef, 'varchar', '36',       undef,
        undef, undef,     1,          undef,
        undef, undef,     undef,      undef,
        6,     'YES'
    ],
    [
        undef, 'main', 'projects', 'path', undef, 'varchar',
        undef, undef,  undef,      undef,  1,     undef,
        undef, undef,  undef,      undef,  7,     'YES'
    ],
    [
        undef, 'main', 'projects_tree', 'treeid', undef, 'INTEGER', undef,
        undef, undef, undef, 1, undef, undef, undef, undef, undef, 1, 'YES'
    ],
    [
        undef, 'main', 'projects_tree', 'parent', undef, 'integer', undef,
        undef, undef, undef, 0, undef, undef, undef, undef, undef, 2, 'NO'
    ],
    [
        undef, 'main', 'projects_tree', 'child', undef, 'integer', undef, undef,
        undef, undef, 0, undef, undef, undef, undef, undef, 3, 'NO'
    ],
    [
        undef, 'main', 'projects_tree', 'depth', undef, 'INTEGER', undef, undef,
        undef, undef, 0, undef, undef, undef, undef, undef, 4, 'NO'
    ],
    [
        undef, 'main', 'task_status_types', 'status', undef, 'varchar', '40',
        undef, undef, undef, 0, undef, undef, undef, undef, undef, 1, 'NO'
    ],
    [
        undef, 'main', 'task_status_types', 'progress', undef, 'varchar', '40',
        undef, undef, undef, 0, undef, undef, undef, undef, undef, 2, 'NO'
    ],
    [
        undef, 'main', 'task_status_types', 'rank', undef, 'integer', undef,
        undef, undef, undef, 0, undef, undef, undef, undef, undef, 3, 'NO'
    ],
    [
        undef, 'main',    'task_updates', 'task_update_id',
        undef, 'INTEGER', undef,          undef,
        undef, undef,     0,              undef,
        undef, undef,     undef,          undef,
        1,     'NO'
    ],
    [
        undef, 'main', 'task_updates', 'task_id', undef, 'integer', undef,
        undef, undef, undef, 0, undef, undef, undef, undef, undef, 2, 'NO'
    ],
    [
        undef, 'main', 'task_updates', 'status', undef, 'varchar', '40', undef,
        undef, undef, 1, undef, undef, undef, undef, undef, 3, 'YES'
    ],
    [
        undef, 'main', 'task_updates', 'project_id', undef, 'integer', undef,
        undef, undef, undef, 1, undef, undef, undef, undef, undef, 4, 'YES'
    ],
    [
        undef, 'main',    'task_updates', 'rm_project_id',
        undef, 'integer', undef,          undef,
        undef, undef,     1,              undef,
        undef, undef,     undef,          undef,
        5,     'YES'
    ],
    [
        undef, 'main', 'tasks', 'task_id', undef, 'INTEGER',
        undef, undef,  undef,   undef,     0,     undef,
        undef, undef,  undef,   undef,     1,     'NO'
    ],
    [
        undef,      'main', 'tasks', 'status', undef, 'varchar',
        '40',       undef,  undef,   undef,    0,     undef,
        '\'open\'', undef,  undef,   undef,    2,     'NO'
    ],
    [
        undef,            'main',
        'thread_updates', 'thread_update_id',
        undef,            'INTEGER',
        undef,            undef,
        undef,            undef,
        0,                undef,
        undef,            undef,
        undef,            undef,
        1,                'NO'
    ],
    [
        undef,            'main',
        'thread_updates', 'thread_update_uuid',
        undef,            'varchar',
        '80',             undef,
        undef,            undef,
        0,                undef,
        undef,            undef,
        undef,            undef,
        2,                'NO'
    ],
    [
        undef, 'main', 'thread_updates', 'thread_id', undef, 'integer', undef,
        undef, undef, undef, 0, undef, undef, undef, undef, undef, 3, 'NO'
    ],
    [
        undef, 'main',    'thread_updates', 'thread_type',
        undef, 'varchar', undef,            undef,
        undef, undef,     1,                undef,
        undef, undef,     undef,            undef,
        4,     'YES'
    ],
    [
        undef, 'main', 'thread_updates', 'itime', undef, 'TIMESTAMP', undef,
        undef, undef, undef, 0, undef, undef, undef, undef, undef, 5, 'NO'
    ],
    [
        undef, 'main', 'thread_updates', 'mtime', undef, 'TIMESTAMP', undef,
        undef, undef, undef, 0, undef, undef, undef, undef, undef, 6, 'NO'
    ],
    [
        undef, 'main', 'thread_updates', 'author', undef, 'varchar', '255',
        undef, undef, undef, 0, undef, undef, undef, undef, undef, 7, 'NO'
    ],
    [
        undef, 'main', 'thread_updates', 'email', undef, 'varchar', '255',
        undef, undef, undef, 0, undef, undef, undef, undef, undef, 8, 'NO'
    ],
    [
        undef, 'main', 'thread_updates', 'push_to', undef, 'varchar', undef,
        undef, undef, undef, 1, undef, undef, undef, undef, undef, 9, 'YES'
    ],
    [
        undef, 'main', 'thread_updates', 'lang', undef, 'varchar', '8', undef,
        undef, undef, 0, undef, '\'en\'', undef, undef, undef, 10, 'NO'
    ],
    [
        undef, 'main', 'thread_updates', 'title', undef, 'varchar', '1024',
        undef, undef, undef, 1, undef, undef, undef, undef, undef, 11, 'YES'
    ],
    [
        undef, 'main', 'thread_updates', 'comment', undef, 'text', undef, undef,
        undef, undef, 1, undef, undef, undef, undef, undef, 12, 'YES'
    ],
    [
        undef, 'main', 'thread_updates', 's0', undef, 'text', undef, undef,
        undef, undef, 1, undef, undef, undef, undef, undef, 13, 'YES'
    ],
    [
        undef, 'main', 'thread_updates', 's1', undef, 'text', undef, undef,
        undef, undef, 1, undef, undef, undef, undef, undef, 14, 'YES'
    ],
    [
        undef, 'main', 'thread_updates', 's2', undef, 'text', undef, undef,
        undef, undef, 1, undef, undef, undef, undef, undef, 15, 'YES'
    ],
    [
        undef, 'main', 'thread_updates', 's3', undef, 'text', undef, undef,
        undef, undef, 1, undef, undef, undef, undef, undef, 16, 'YES'
    ],
    [
        undef, 'main', 'thread_updates', 's4', undef, 'text', undef, undef,
        undef, undef, 1, undef, undef, undef, undef, undef, 17, 'YES'
    ],
    [
        undef, 'main',    'threads', 'thread_id',
        undef, 'INTEGER', undef,     undef,
        undef, undef,     0,         undef,
        undef, undef,     undef,     undef,
        1,     'NO'
    ],
    [
        undef, 'main', 'threads', 'thread_uuid', undef, 'varchar', '80', undef,
        undef, undef, 0, undef, undef, undef, undef, undef, 2, 'NO'
    ],
    [
        undef, 'main', 'threads', 'thread_type', undef, 'varchar', undef, undef,
        undef, undef, 0, undef, undef, undef, undef, undef, 3, 'NO'
    ],
    [
        undef, 'main', 'threads', 'last_update_id', undef, 'INTEGER', undef,
        undef, undef, undef, 0, undef, '-1', undef, undef, undef, 4, 'NO'
    ],
    [
        undef, 'main',      'threads', 'ctime',
        undef, 'TIMESTAMP', undef,     undef,
        undef, undef,       0,         undef,
        undef, undef,       undef,     undef,
        5,     'NO'
    ],
    [
        undef, 'main',      'threads', 'mtime',
        undef, 'TIMESTAMP', undef,     undef,
        undef, undef,       0,         undef,
        undef, undef,       undef,     undef,
        6,     'NO'
    ],
    [
        undef,    'main', 'threads', 'lang', undef, 'varchar',
        '8',      undef,  undef,     undef,  0,     undef,
        '\'en\'', undef,  undef,     undef,  7,     'NO'
    ],
    [
        undef, 'main', 'threads', 'locale', undef, 'varchar',
        '8',   undef,  undef,     undef,    1,     undef,
        undef, undef,  undef,     undef,    8,     'YES'
    ],
    [
        undef,  'main', 'threads', 'title', undef, 'varchar',
        '1024', undef,  undef,     undef,   0,     undef,
        undef,  undef,  undef,     undef,   9,     'NO'
    ]
];
SQL::DB::Schema->new( name => 'Curo::Schema::SQLite' )->define($VAR1);

undef $VAR1;
1;
__END__

=head1 NAME

Curo::Schema::SQLite - An SQL::DB::Schema definition

=head1 SYNOPSIS

    use SQL::DB; # or anything that extends SQL::DB

    my $db = SQL::DB->connect(
        dsn      => $dsn,
        username => $username,
        password => $password,
        schema   => 'Curo::Schema',
    );

=head1 DESCRIPTION

See L<sqldb-schema>(1) for details.

Generated by App::sqldb_schema version 0.19_11 on Fri Nov 18 10:21:37 2011 from dbi:SQLite:dbname=.curo/curo.sqlite.

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Mark Lawrence E<lt>nomad@null.netE<gt>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

=cut