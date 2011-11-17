package Curo::Deploy::Pg; our $VERSION = '0.01_02';
1;

=head1 NAME

Curo::Deploy::Pg - curo deployment SQL

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
    CREATE TABLE "project_phases" (
      "phase" character varying(40) DEFAULT 'definition' NOT NULL,
      "rank" integer NOT NULL,
      PRIMARY KEY ("phase")
    );

- sql: |
    CREATE TABLE "threads" (
      "thread_id" integer NOT NULL,
      "thread_uuid" character varying(80) NOT NULL,
      "thread_type" character varying NOT NULL,
      "ctime" timestamp NOT NULL,
      "mtime" timestamp NOT NULL,
      "last_update_id" integer NOT NULL DEFAULT -1,
      "lang" character varying(8) DEFAULT 'en' NOT NULL,
      "locale" character varying(8),
      "title" character varying(1024),
      PRIMARY KEY ("thread_id"),
      CONSTRAINT "unique_threads_thread_uuid" UNIQUE ("thread_uuid")
    );

- sql: |
    CREATE TABLE "issue_status_types" (
      "status" character varying(40) DEFAULT 'open' NOT NULL,
      "progress" character varying(40) NOT NULL,
      "rank" integer NOT NULL,
      PRIMARY KEY ("status")
    );

- sql: |
    CREATE TABLE "hubs" (
      "hub_id" integer NOT NULL,
      "location" character varying(255) NOT NULL,
      "master" integer,
      "name" character varying(40) NOT NULL,
      PRIMARY KEY ("hub_id"),
      CONSTRAINT "unique_hubs_name" UNIQUE ("name")
    );

- sql: |
    CREATE TABLE "prefs" (
      "pref_id" integer NOT NULL,
      "location" character varying(255) NOT NULL,
      "name" character varying(40) NOT NULL,
      "uuid" character varying(36) NOT NULL,
      PRIMARY KEY ("pref_id"),
      CONSTRAINT "unique_prefs_name" UNIQUE ("name")
    );

- sql: |
    CREATE TABLE "issues" (
      "issue_id" integer NOT NULL,
      "status" character varying(40) DEFAULT 'new' NOT NULL,
      "thread_type" character varying DEFAULT 'issues' NOT NULL,
      PRIMARY KEY ("issue_id")
    );

- sql: |
    CREATE TABLE "tasks" (
      "task_id" integer NOT NULL,
      "status" character varying(40) DEFAULT 'new' NOT NULL,
      "thread_type" character varying DEFAULT 'tasks' NOT NULL,
      PRIMARY KEY ("task_id")
    );

- sql: |
    CREATE TABLE "thread_updates" (
      "thread_update_id" integer NOT NULL,
      "thread_update_uuid" character varying(80) NOT NULL,
      "thread_id" integer NOT NULL,
      "thread_type" character varying,
      "mtime" timestamp NOT NULL,
      "itime" timestamp NOT NULL,
      "author" character varying(255) NOT NULL,
      "email" character varying(255) NOT NULL,
      "lang" character varying(8) DEFAULT 'en' NOT NULL,
      "title" character varying(1024),
      "comment" text,
      PRIMARY KEY ("thread_update_id"),
      CONSTRAINT "unique_thread_updates_thread_update_uuid" UNIQUE ("thread_update_uuid")
    );

- sql: |
    CREATE TABLE "projects" (
      "project_id" integer NOT NULL,
      "hub_id" integer,
      "name" character varying(40) NOT NULL,
      "parent_id" integer,
      "phase" character varying(40) NOT NULL,
      "pref_id" integer,
      "ref_uuid" character varying(36),
      "thread_type" character varying DEFAULT 'projects' NOT NULL,
      "path" citext UNIQUE, /* TODO: need CREATE EXTENSION citext -
      check the tree code stuff below for how to do this repeatedly safely */
      PRIMARY KEY ("project_id")
    );

- sql: |
    CREATE TABLE project_threads (
        project_id integer NOT NULL,
        issue_id integer,
        task_id integer,
        thread_update_id integer NOT NULL REFERENCES thread_updates(thread_update_id),
        CONSTRAINT project_threads_check
        CHECK ((((issue_id IS NULL) AND (task_id IS NOT NULL))
            OR ((task_id IS NULL) AND (issue_id IS NOT NULL))))
    );

- sql: |
    CREATE TABLE "issue_updates" (
      "issue_update_id" integer NOT NULL,
      "issue_id" integer NOT NULL,
      "status" character varying(40),
      "project_id" integer REFERENCES projects(project_id),
      "rm_project_id" integer REFERENCES projects(project_id),
      PRIMARY KEY ("issue_update_id")
    );

- sql: |
    CREATE TABLE "task_updates" (
      "task_update_id" integer NOT NULL,
      "task_id" integer NOT NULL,
      "status" character varying(40),
      "project_id" integer REFERENCES projects(project_id),
      "rm_project_id" integer REFERENCES projects(project_id),
      PRIMARY KEY ("task_update_id")
    );

- sql: |
    CREATE TABLE "project_updates" (
      "project_update_id" integer NOT NULL,
      "hub_id" integer,
      "name" character varying(40),
      "parent_id" integer,
      "phase" character varying(40),
      "pref_id" integer,
      "ref_uuid" character varying(36),
      "project_id" integer NOT NULL,
      "path" character varying,
      PRIMARY KEY ("project_update_id")
    );

- sql: |
    ALTER TABLE "issues" ADD FOREIGN KEY ("status")
      REFERENCES "issue_status_types" ("status") DEFERRABLE;

- sql: |
    ALTER TABLE "issues" ADD FOREIGN KEY ("issue_id")
      REFERENCES "threads" ("thread_id") DEFERRABLE;

- sql: |
    ALTER TABLE "tasks" ADD FOREIGN KEY ("status")
      REFERENCES "issue_status_types" ("status") DEFERRABLE;

- sql: |
    ALTER TABLE "tasks" ADD FOREIGN KEY ("task_id")
      REFERENCES "threads" ("thread_id") DEFERRABLE;

- sql: |
    ALTER TABLE "thread_updates" ADD FOREIGN KEY ("thread_id")
      REFERENCES "threads" ("thread_id") DEFERRABLE;

- sql: |
    ALTER TABLE "projects" ADD FOREIGN KEY ("phase")
      REFERENCES "project_phases" ("phase") DEFERRABLE;

- sql: |
    ALTER TABLE "projects" ADD FOREIGN KEY ("hub_id")
      REFERENCES "hubs" ("hub_id") DEFERRABLE;

- sql: |
    ALTER TABLE "projects" ADD FOREIGN KEY ("pref_id")
      REFERENCES "prefs" ("pref_id") DEFERRABLE;

- sql: |
    ALTER TABLE "projects" ADD FOREIGN KEY ("parent_id")
      REFERENCES "projects" ("project_id") DEFERRABLE;

- sql: |
    ALTER TABLE "projects" ADD FOREIGN KEY ("project_id")
      REFERENCES "threads" ("thread_id") DEFERRABLE;

- sql: |
    ALTER TABLE "issue_updates" ADD FOREIGN KEY ("status")
      REFERENCES "issue_status_types" ("status") DEFERRABLE;

- sql: |
    ALTER TABLE "issue_updates" ADD FOREIGN KEY ("issue_id")
      REFERENCES "issues" ("issue_id") DEFERRABLE;

- sql: |
    ALTER TABLE "issue_updates" ADD FOREIGN KEY ("issue_update_id")
      REFERENCES "thread_updates" ("thread_update_id") DEFERRABLE;

- sql: |
    ALTER TABLE "task_updates" ADD FOREIGN KEY ("status")
      REFERENCES "issue_status_types" ("status") DEFERRABLE;

- sql: |
    ALTER TABLE "task_updates" ADD FOREIGN KEY ("task_id")
      REFERENCES "tasks" ("task_id") DEFERRABLE;

- sql: |
    ALTER TABLE "task_updates" ADD FOREIGN KEY ("task_update_id")
      REFERENCES "thread_updates" ("thread_update_id") DEFERRABLE;

- sql: |
    ALTER TABLE ONLY project_threads
        ADD CONSTRAINT project_threads_project_id_key UNIQUE (project_id, issue_id);

- sql: |
    ALTER TABLE ONLY project_threads
        ADD CONSTRAINT project_threads_thread_id_key UNIQUE (project_id, task_id);

- sql: |
    ALTER TABLE ONLY project_threads
        ADD CONSTRAINT project_threads_issue_id_fkey
        FOREIGN KEY (issue_id) REFERENCES issues(issue_id);

- sql: |
    ALTER TABLE ONLY project_threads
        ADD CONSTRAINT project_threads_project_id_fkey
        FOREIGN KEY (project_id) REFERENCES projects(project_id);

- sql: |
    ALTER TABLE ONLY project_threads
        ADD CONSTRAINT project_threads_task_id_fkey
        FOREIGN KEY (task_id) REFERENCES tasks(task_id);

- sql: |
    ALTER TABLE "project_updates" ADD FOREIGN KEY ("phase")
      REFERENCES "project_phases" ("phase") DEFERRABLE;

- sql: |
    ALTER TABLE "project_updates" ADD FOREIGN KEY ("project_update_id")
      REFERENCES "thread_updates" ("thread_update_id") DEFERRABLE;

- sql: |
    ALTER TABLE "project_updates" ADD FOREIGN KEY ("project_id")
      REFERENCES "projects" ("project_id") DEFERRABLE;

- sql: |
    CREATE OR REPLACE FUNCTION make_plpgsql()
    RETURNS VOID
    LANGUAGE SQL
    AS $$
    CREATE LANGUAGE plpgsql;
    $$;

- sql: |
    SELECT
        CASE
        WHEN EXISTS(
            SELECT 1
            FROM pg_catalog.pg_language
            WHERE lanname='plpgsql'
        )
        THEN NULL
        ELSE make_plpgsql()
        END;

- sql: |
    DROP FUNCTION make_plpgsql();

- sql: |
    CREATE TABLE projects_tree (
        treeid    SERIAL PRIMARY KEY,
        parent    integer NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
        child     integer NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
        depth     INTEGER NOT NULL,
        UNIQUE (parent, child)
    );

- sql: |
    CREATE OR REPLACE FUNCTION ai_projects_tree_1() RETURNS TRIGGER AS
    $BODY$
    DECLARE
    BEGIN
        INSERT INTO projects_tree (parent, child, depth)
            VALUES (NEW.project_id, NEW.project_id, 0);
        INSERT INTO projects_tree (parent, child, depth)
            SELECT x.parent, NEW.project_id, x.depth + 1
                FROM projects_tree x
                WHERE x.child = NEW.parent_id;
        RETURN NEW;
    END;
    $BODY$
    LANGUAGE 'plpgsql';

- sql: |
    CREATE TRIGGER ai_projects_tree_1 AFTER INSERT ON projects
    FOR EACH ROW EXECUTE PROCEDURE ai_projects_tree_1();

- sql: |
    CREATE OR REPLACE FUNCTION bu_projects_tree_1() RETURNS TRIGGER AS
    $BODY$
    DECLARE
    BEGIN
        IF NEW.project_id <> OLD.project_id THEN
            RAISE EXCEPTION 'Changing ids is forbidden.';
        END IF;
        IF OLD.parent_id IS NOT DISTINCT FROM NEW.parent_id THEN
            RETURN NEW;
        END IF;
        IF NEW.parent_id IS NULL THEN
            RETURN NEW;
        END IF;
        PERFORM 1 FROM projects_tree
            WHERE ( parent, child ) = ( NEW.project_id, NEW.parent_id );
        IF FOUND THEN
            RAISE EXCEPTION 'Update blocked, because it would create loop in tree.';
        END IF;
        RETURN NEW;
    END;
    $BODY$
    LANGUAGE 'plpgsql';

- sql: |
    CREATE TRIGGER bu_projects_tree_1 BEFORE UPDATE ON projects
    FOR EACH ROW EXECUTE PROCEDURE bu_projects_tree_1();

- sql: |
    CREATE OR REPLACE FUNCTION au_projects_tree_1() RETURNS TRIGGER AS
    $BODY$
    DECLARE
    BEGIN
        IF OLD.parent_id IS NOT DISTINCT FROM NEW.parent_id THEN
            RETURN NEW;
        END IF;
        IF OLD.parent_id IS NOT NULL THEN
            DELETE FROM projects_tree WHERE treeid in (
                SELECT r2.treeid
                FROM projects_tree r1
                JOIN projects_tree r2 ON r1.child = r2.child
                WHERE r1.parent = NEW.project_id AND r2.depth > r1.depth
            );
        END IF;
        IF NEW.parent_id IS NOT NULL THEN
            INSERT INTO projects_tree (parent, child, depth)
                SELECT r1.parent, r2.child, r1.depth + r2.depth + 1
                FROM
                    projects_tree r1,
                    projects_tree r2
                WHERE
                    r1.child = NEW.parent_id AND
                    r2.parent = NEW.project_id;
        END IF;
        RETURN NEW;
    END;
    $BODY$
    LANGUAGE 'plpgsql';

- sql: |
    CREATE TRIGGER au_projects_tree_1 AFTER UPDATE ON projects
    FOR EACH ROW EXECUTE PROCEDURE au_projects_tree_1();

- sql: |
    CREATE OR REPLACE FUNCTION bi_projects_path_1()
    RETURNS TRIGGER AS
    $BODY$
    DECLARE
    BEGIN
        IF NEW.parent_id IS NULL THEN
            NEW.path := NEW.name;
        ELSE
            SELECT path || '/' || NEW.name INTO NEW.path
            FROM projects
            WHERE project_id = NEW.parent_id;
        END IF;
        RETURN NEW;
    END;
    $BODY$
    LANGUAGE 'plpgsql';

- sql: |
    CREATE TRIGGER bi_projects_path_1 BEFORE INSERT ON projects
    FOR EACH ROW EXECUTE PROCEDURE bi_projects_path_1();

- sql: |
    CREATE OR REPLACE FUNCTION bu_projects_path_1()
    RETURNS TRIGGER AS
    $BODY$
    DECLARE
        replace_from TEXT := '^';
        replace_to   TEXT := '';
    BEGIN
        IF OLD.parent_id IS NOT DISTINCT FROM NEW.parent_id THEN
            RETURN NEW;
        END IF;
        IF OLD.parent_id IS NOT NULL THEN
            SELECT '^' || path || '/' INTO replace_from
            FROM projects
            WHERE project_id = OLD.parent_id;
        END IF;
        IF NEW.parent_id IS NOT NULL THEN
            SELECT path || '/' INTO replace_to
            FROM projects
            WHERE project_id = NEW.parent_id;
        END IF;
        NEW.path := regexp_replace( NEW.path, replace_from, replace_to );
        UPDATE projects
        SET path = regexp_replace(path, replace_from, replace_to )
        WHERE project_id in (
            SELECT child
            FROM projects_tree
            WHERE parent = NEW.project_id AND depth > 0
        );
        RETURN NEW;
    END;
    $BODY$
    LANGUAGE 'plpgsql';

- sql: |
    CREATE TRIGGER bu_projects_path_1 BEFORE UPDATE ON projects
    FOR EACH ROW EXECUTE PROCEDURE bu_projects_path_1();

- perl: $self->create_sequence("project_phases")

- perl: $self->create_sequence("threads")

- perl: $self->create_sequence("issue_status_types")

- perl: $self->create_sequence("hubs")

- perl: $self->create_sequence("prefs")

- perl: $self->create_sequence("issues")

- perl: $self->create_sequence("tasks")

- perl: $self->create_sequence("thread_updates")

- perl: $self->create_sequence("projects")

- perl: $self->create_sequence("project_threads")

- perl: $self->create_sequence("issue_updates")

- perl: $self->create_sequence("task_updates")

- perl: $self->create_sequence("project_updates")

- perl: $self->create_sequence("projects_tree")

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
