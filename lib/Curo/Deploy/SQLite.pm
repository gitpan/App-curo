package Curo::Deploy::SQLite; our $VERSION = '0.01_02';
1;

=head1 NAME

Curo::Deploy::SQLite - curo deployment SQL

=head1 SYNOPSIS

  use SQL::DB;
  use SQL::DBx::Deploy;

  my $db = SQL::DB->connect($dsn, $username, $password);
  $db->deploy('Curo::Deploy');

=head1 DESCRIPTION

See L<SQL::DBx::Deploy> for details.

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Mark Lawrence E<lt>nomad@null.netE<gt>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

=cut

__DATA__

- sql: |
    CREATE TABLE threads (
      thread_id INTEGER PRIMARY KEY NOT NULL,
      thread_uuid varchar(80) NOT NULL UNIQUE,
      thread_type varchar NOT NULL,
      last_update_id INTEGER NOT NULL DEFAULT -1,
      ctime TIMESTAMP NOT NULL,
      mtime TIMESTAMP NOT NULL,
      lang varchar(8) NOT NULL DEFAULT 'en',
      locale varchar(8),
      title varchar(1024) NOT NULL
    );

- sql: |
    CREATE UNIQUE INDEX unique_threads_thread_uuid ON threads (thread_uuid);

- sql: |
    CREATE TABLE thread_updates (
      thread_update_id INTEGER PRIMARY KEY NOT NULL,
      thread_update_uuid varchar(80) NOT NULL UNIQUE,
      thread_id integer NOT NULL,
      thread_type varchar,
      itime TIMESTAMP NOT NULL,
      mtime TIMESTAMP NOT NULL,
      author varchar(255) NOT NULL,
      email varchar(255) NOT NULL,
      push_to varchar,
      lang varchar(8) NOT NULL DEFAULT 'en',
      title varchar(1024),
      comment text,
      s0 text,
      s1 text,
      s2 text,
      s3 text,
      s4 text,
      FOREIGN KEY(thread_id) REFERENCES threads(thread_id)
    );

- sql: |
    CREATE UNIQUE INDEX unique_thread_updates_thread_update_uuid ON
    thread_updates (thread_update_uuid);

- sql: |
    CREATE TABLE project_phases (
      phase varchar(40) NOT NULL DEFAULT 'definition',
      rank integer NOT NULL,
      PRIMARY KEY (phase)
    );

- sql: |
    CREATE TABLE projects (
      project_id INTEGER PRIMARY KEY NOT NULL,
      name varchar(40) NOT NULL,
      parent_id integer,
      phase varchar(40) NOT NULL,
      pref_id integer,
      ref_uuid varchar(36),
      path varchar collate nocase UNIQUE,
      FOREIGN KEY(phase) REFERENCES project_phases(phase),
      FOREIGN KEY(parent_id) REFERENCES projects(project_id),
      FOREIGN KEY(project_id) REFERENCES threads(thread_id)
    );

- sql: |
    CREATE TABLE projects_tree (
        treeid    INTEGER PRIMARY KEY,
        parent    integer NOT NULL REFERENCES projects(project_id)
            ON DELETE CASCADE,
        child     integer NOT NULL REFERENCES projects(project_id)
            ON DELETE CASCADE,
        depth     INTEGER NOT NULL,
        UNIQUE (parent, child)
    );

- sql: |
    -- --------------------------------------------------------------------
    -- INSERT:
    -- 1. Insert a matching row in projects_tree where both parent and child
    -- are set to the id of the newly inserted object. Depth is set to 0 as
    -- both child and parent are on the same level.
    --
    -- 2. Copy all rows that our parent had as its parents, but we modify
    -- the child id in these rows to be the id of currently inserted row,
    -- and increase depth by one.
    -- --------------------------------------------------------------------
    CREATE TRIGGER ai_projects_path_2 AFTER INSERT ON projects
    FOR EACH ROW WHEN NEW.parent_id IS NULL
    BEGIN
        UPDATE projects
        SET path = name
        WHERE project_id = NEW.project_id;
    END;

- sql: |
    CREATE TRIGGER ai_projects_path_1 AFTER INSERT ON projects
    FOR EACH ROW WHEN NEW.parent_id IS NOT NULL
    BEGIN
        UPDATE projects
        SET path = (
            SELECT path || '/' || NEW.name
            FROM projects
            WHERE project_id = NEW.parent_id
        )
        WHERE project_id = NEW.project_id;
    END;

- sql: |
    CREATE TRIGGER ai_projects_tree_1 AFTER INSERT ON projects
    FOR EACH ROW 
    BEGIN
        INSERT INTO projects_tree (parent, child, depth)
            VALUES (NEW.project_id, NEW.project_id, 0);
        INSERT INTO projects_tree (parent, child, depth)
            SELECT x.parent, NEW.project_id, x.depth + 1
                FROM projects_tree x
                WHERE x.child = NEW.parent_id;
    END;

- sql: |
    -- --------------------------------------------------------------------
    -- UPDATE:
    --
    -- Triggers in SQLite are apparently executed LIFO, so you need to read
    -- these trigger statements from the bottom up.
    -- --------------------------------------------------------------------
    CREATE TRIGGER au_projects_path_2 AFTER UPDATE ON projects
    FOR EACH ROW WHEN NEW.parent_id IS NOT NULL
    BEGIN
        UPDATE projects
        SET path = (
            SELECT path
            FROM projects
            WHERE project_id = NEW.parent_id
        ) || '/' || path
        WHERE project_id IN (
            SELECT child
            FROM projects_tree
            WHERE parent = NEW.parent_id AND depth > 0
        );
    END;

- sql: |
    CREATE TRIGGER au_projects_tree_5 AFTER UPDATE ON projects
    FOR EACH ROW WHEN NEW.parent_id IS NOT NULL
    BEGIN
        INSERT INTO projects_tree (parent, child, depth)
        SELECT r1.parent, r2.child, r1.depth + r2.depth + 1
        FROM
            projects_tree r1
        INNER JOIN
            projects_tree r2
        ON
            r2.parent = NEW.project_id
        WHERE
            r1.child = NEW.parent_id
        ;
    END;

- sql: |
    CREATE TRIGGER au_projects_tree_4 AFTER UPDATE ON projects
    FOR EACH ROW WHEN OLD.parent_id IS NOT NULL
    BEGIN
        DELETE FROM projects_tree WHERE treeid in (
            SELECT r2.treeid
            FROM
                projects_tree r1
            INNER JOIN
                projects_tree r2
            ON
                r1.child = r2.child AND r2.depth > r1.depth
            WHERE r1.parent = NEW.project_id
        );
    END;

- sql: |
    -- FIXME: Also trigger when column 'path_from' changes. For the
    -- moment, the user work-around is to temporarily re-parent the row.
    CREATE TRIGGER au_projects_path_1 AFTER UPDATE ON projects
    FOR EACH ROW WHEN OLD.parent_id IS NOT NULL
    BEGIN
        UPDATE projects
        SET path = substr(path, (
            SELECT length(path || '/') + 1
            FROM projects
            WHERE project_id = OLD.parent_id
        ))
        WHERE project_id IN (
            SELECT child
            FROM projects_tree
            WHERE parent = OLD.parent_id AND depth > 0
        );
    END;

- sql: |
    CREATE TRIGGER au_projects_tree_2 AFTER UPDATE ON projects
    FOR EACH ROW WHEN
        (OLD.parent_id IS NULL AND NEW.parent_id IS NULL) OR
        ((OLD.parent_id IS NOT NULL and NEW.parent_id IS NOT NULL) AND
         (OLD.parent_id = NEW.parent_id))
    BEGIN
        SELECT RAISE (IGNORE);
    END;

- sql: |
    -- If the from_path column has changed then update the path
    CREATE TRIGGER au_projects_tree_x2 AFTER UPDATE ON projects
    FOR EACH ROW WHEN OLD.name != NEW.name
    BEGIN
        UPDATE projects
        SET
            path = (SELECT path FROM projects WHERE project_id = OLD.project_id) ||
                SUBSTR(path, LENGTH(OLD.path)+1)
        WHERE
            project_id IN (
                SELECT child
                FROM projects_tree
                WHERE parent = OLD.project_id AND depth > 0
            )
        ;
    END;

- sql: |
    -- If the from_path column has changed then update the path
    CREATE TRIGGER au_projects_tree_x AFTER UPDATE ON projects
    FOR EACH ROW WHEN OLD.name != NEW.name
    BEGIN
        UPDATE projects
        SET path = 
            CASE WHEN
                NEW.parent_id IS NOT NULL
            THEN
                (SELECT path FROM projects WHERE project_id = NEW.parent_id) || '/' ||
                name
            ELSE
                name
            END
        WHERE
            project_id = OLD.project_id
        ;
    END;

- sql: |
    CREATE TRIGGER bu_projects_tree_2 BEFORE UPDATE ON projects
    FOR EACH ROW WHEN NEW.parent_id IS NOT NULL AND
        (SELECT
            COUNT(child)
         FROM projects_tree
         WHERE child = NEW.parent_id AND parent = NEW.project_id) > 0
    BEGIN
        SELECT RAISE (ABORT,
            'Update blocked, because it would create loop in tree.');
    END;

- sql: |
    CREATE TRIGGER bu_projects_tree_1 BEFORE UPDATE ON projects
    FOR EACH ROW WHEN OLD.project_id != NEW.project_id
    BEGIN
        SELECT RAISE (ABORT, 'Changing ids is forbidden.');
    END;

- sql: |
    CREATE TABLE project_updates (
      project_update_id INTEGER PRIMARY KEY NOT NULL,
      name varchar(40),
      parent_id integer,
      phase varchar(40),
      pref_id integer,
      ref_uuid varchar(36),
      project_id integer NOT NULL,
      path varchar,
      FOREIGN KEY(phase) REFERENCES project_phases(phase),
      FOREIGN KEY(project_update_id) REFERENCES thread_updates(thread_update_id),
      FOREIGN KEY(project_id) REFERENCES projects(project_id)
    );

- sql: |
    CREATE TABLE issue_status_types (
      status varchar(40) NOT NULL,
      progress varchar(40) NOT NULL,
      rank integer NOT NULL,
      PRIMARY KEY (status)
    );

- sql: |
    CREATE TABLE issues (
      issue_id INTEGER PRIMARY KEY NOT NULL,
      status varchar(40) NOT NULL DEFAULT 'open',
      FOREIGN KEY(status) REFERENCES issue_status_types(status),
      FOREIGN KEY(issue_id) REFERENCES threads(thread_id)
    );

- sql: |
    CREATE TABLE issue_updates (
      issue_update_id INTEGER PRIMARY KEY NOT NULL,
      issue_id integer NOT NULL,
      status varchar(40),
      project_id integer REFERENCES projects(project_id),
      rm_project_id integer REFERENCES projects(project_id),
      FOREIGN KEY(status) REFERENCES issue_status_types(status),
      FOREIGN KEY(issue_id) REFERENCES issues(issue_id),
      FOREIGN KEY(issue_update_id) REFERENCES thread_updates(thread_update_id)
    );

- sql: |
    CREATE TABLE task_status_types (
      status varchar(40) NOT NULL,
      progress varchar(40) NOT NULL,
      rank integer NOT NULL,
      PRIMARY KEY (status)
    );

- sql: |
    CREATE TABLE tasks (
      task_id INTEGER PRIMARY KEY NOT NULL,
      status varchar(40) NOT NULL DEFAULT 'open',
      FOREIGN KEY(status) REFERENCES task_status_types(status),
      FOREIGN KEY(task_id) REFERENCES threads(thread_id)
    );

- sql: |
    CREATE TABLE task_updates (
      task_update_id INTEGER PRIMARY KEY NOT NULL,
      task_id integer NOT NULL,
      status varchar(40),
      project_id integer REFERENCES projects(project_id),
      rm_project_id integer REFERENCES projects(project_id),
      FOREIGN KEY(status) REFERENCES task_status_types(status),
      FOREIGN KEY(task_id) REFERENCES tasks(task_id),
      FOREIGN KEY(task_update_id) REFERENCES thread_updates(thread_update_id)
    );

- sql: |
    CREATE TABLE project_threads (
      project_id integer NOT NULL REFERENCES projects(project_id),
      project_self integer REFERENCES projects(project_id),
      issue_id integer REFERENCES issues(issue_id),
      task_id integer REFERENCES tasks(task_id),
      thread_update_id integer NOT NULL 
        REFERENCES thread_updates(thread_update_id),
      UNIQUE (project_id, issue_id),
      UNIQUE (project_id, task_id),
      CHECK (
        (project_self IS NULL AND issue_id IS NULL AND task_id IS NOT NULL) OR
        (project_self IS NULL AND issue_id IS NOT NULL AND task_id IS NULL) OR
        (project_self IS NOT NULL AND issue_id IS NULL AND task_id IS NULL)
      )
    );

- sql: |
    CREATE TABLE hubs (
      name varchar(40) PRIMARY KEY NOT NULL,
      location varchar(255) NOT NULL,
      master integer
    );

- sql: |
    CREATE UNIQUE INDEX unique_hubs_name ON hubs (name);

- perl: $self->create_sequence("threads")

- perl: $self->create_sequence("thread_updates")

- sql: |
    INSERT INTO project_phases(phase,rank) VALUES('define',10);

- sql: |
    INSERT INTO project_phases(phase,rank) VALUES('plan',20);

- sql: |
    INSERT INTO project_phases(phase,rank) VALUES('run',30);

- sql: |
    INSERT INTO project_phases(phase,rank) VALUES('eval',40);

- sql: |
    INSERT INTO project_phases(phase,rank) VALUES('closed',50);

- sql: |
    INSERT INTO issue_status_types(progress,status,rank)
    VALUES('active','open',10);

- sql: |
    INSERT INTO issue_status_types(progress,status,rank)
    VALUES('stalled','needinfo',10);

- sql: |
    INSERT INTO issue_status_types(progress,status,rank)
    VALUES('stalled','depends',10);

- sql: |
    INSERT INTO issue_status_types(progress,status,rank)
    VALUES('resolved','testing',10);

- sql: |
    INSERT INTO issue_status_types(progress,status,rank)
    VALUES('resolved','fixed',10);

- sql: |
    INSERT INTO issue_status_types(progress,status,rank)
    VALUES('closed','duplicate',10);

- sql: |
    INSERT INTO issue_status_types(progress,status,rank)
    VALUES('closed','wontfix',10);

- sql: |
    INSERT INTO issue_status_types(progress,status,rank)
    VALUES('closed','noissue',10);

- sql: |
    INSERT INTO issue_status_types(progress,status,rank)
    VALUES('closed','norepeat',10);

- sql: |
    INSERT INTO task_status_types(progress,status,rank)
    VALUES('active','open',10);

- sql: |
    INSERT INTO task_status_types(progress,status,rank)
    VALUES('stalled','needinfo',10);

- sql: |
    INSERT INTO task_status_types(progress,status,rank)
    VALUES('stalled','depends',10);

- sql: |
    INSERT INTO task_status_types(progress,status,rank)
    VALUES('closed','done',10);

- sql: |
    INSERT INTO issue_status_types(progress,status,rank)
    VALUES('closed','notask',10);

- sql: |
    CREATE TRIGGER ai_thread_updates AFTER INSERT ON thread_updates
    FOR EACH ROW
    BEGIN
        UPDATE thread_updates
        SET
            s0 = substr(NEW.thread_update_uuid,1,1),
            s1 = substr(NEW.thread_update_uuid,1,2),
            s2 = substr(NEW.thread_update_uuid,1,3),
            s3 = substr(NEW.thread_update_uuid,1,4),
            s4 = substr(NEW.thread_update_uuid,1,5)
        WHERE thread_update_id = NEW.thread_update_id;
    END;

- sql: |
    CREATE TRIGGER ai_thread_updates2 AFTER INSERT ON thread_updates
    FOR EACH ROW
    BEGIN
        UPDATE threads
        SET
            title = (
                SELECT
                    title
                FROM
                    thread_updates
                WHERE
                    thread_id = NEW.thread_id AND title IS NOT NULL
                ORDER BY
                    thread_update_id DESC
                LIMIT 1
            )
        WHERE
            thread_id = NEW.thread_id
        ;
    END;

- sql: |
    CREATE TRIGGER ai_project_updates AFTER INSERT ON project_updates
    FOR EACH ROW
    BEGIN
        UPDATE projects
        SET
            name = (
                SELECT
                    name
                FROM
                    project_updates
                WHERE
                    project_id = NEW.project_id AND name IS NOT NULL
                ORDER BY
                    project_update_id DESC
                LIMIT 1
            ),
            phase = (
                SELECT
                    phase
                FROM
                    project_updates
                WHERE
                    project_id = NEW.project_id AND phase IS NOT NULL
                ORDER BY
                    project_update_id DESC
                LIMIT 1
            )
        WHERE
            project_id = NEW.project_id
        ;
    END;

- sql: |
    CREATE TRIGGER ai_task_updates AFTER INSERT ON task_updates
    FOR EACH ROW
    BEGIN
        UPDATE tasks
        SET
            status =
                (SELECT
                    status
                FROM
                    task_updates
                WHERE
                    task_id = NEW.task_id AND status IS NOT NULL
                ORDER BY
                    task_update_id DESC
                LIMIT 1
                )
        WHERE
            task_id = NEW.task_id
        ;
    END;

- sql: |
    CREATE TRIGGER ai_issue_updates AFTER INSERT ON issue_updates
    FOR EACH ROW
    BEGIN
        UPDATE issues
        SET
            status =
                (SELECT
                    status
                FROM
                    issue_updates
                WHERE
                    issue_id = NEW.issue_id AND status IS NOT NULL
                ORDER BY
                    issue_update_id DESC
                LIMIT 1
                )
        WHERE
            issue_id = NEW.issue_id
        ;

    END;

