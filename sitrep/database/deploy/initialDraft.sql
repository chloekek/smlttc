START TRANSACTION;

--------------------------------------------------------------------------------
-- Schema sitrep

CREATE SCHEMA sitrep;

GRANT USAGE
    ON SCHEMA sitrep
    TO sitrep_receive;

--------------------------------------------------------------------------------
-- Function sitrep.current_identity_id

CREATE FUNCTION sitrep.current_identity_id() RETURNS uuid
    AS $$ SELECT CAST(current_setting('sitrep.identity_id') AS uuid) $$
    LANGUAGE SQL
    PARALLEL SAFE
    STABLE;

--------------------------------------------------------------------------------
-- Function sitrep.set_identity_id

CREATE FUNCTION sitrep.set_identity_id(uuid) RETURNS void
    AS $$ SELECT set_config('sitrep.identity_id', CAST($1 AS TEXT), TRUE) $$
    LANGUAGE SQL;

--------------------------------------------------------------------------------
-- Table sitrep.identities

CREATE TABLE sitrep.identities (
    id uuid,
    CONSTRAINT identities_pk
        PRIMARY KEY (id),

    name TEXT NOT NULL
);

GRANT SELECT, INSERT, UPDATE, DELETE
    ON TABLE sitrep.identities
    TO sitrep_receive;

ALTER TABLE sitrep.identities
    ENABLE ROW LEVEL SECURITY;

CREATE POLICY self
    ON sitrep.identities
    AS PERMISSIVE
    USING (
        identities.id = sitrep.current_identity_id()
    );

--------------------------------------------------------------------------------
-- Table sitrep.journals

CREATE TABLE sitrep.journals (
    id uuid,
    CONSTRAINT journals_pk
        PRIMARY KEY (id),

    name TEXT NOT NULL
);

GRANT SELECT, INSERT, UPDATE, DELETE
    ON TABLE sitrep.journals
    TO sitrep_receive;

--------------------------------------------------------------------------------
-- Table sitrep.log_messages

CREATE TABLE sitrep.log_messages
    (
        id BIGINT NOT NULL
            GENERATED BY DEFAULT AS IDENTITY,

        journal_id uuid NOT NULL,
        CONSTRAINT log_messages_journal_fk
            FOREIGN KEY (journal_id)
            REFERENCES sitrep.journals (id)
            ON DELETE CASCADE,

        message bytea NOT NULL,

        was_extracted_from boolean NOT NULL
            DEFAULT FALSE
    )
    PARTITION BY LIST (was_extracted_from);

CREATE TABLE sitrep.log_messages_in_need_of_extraction
    PARTITION OF sitrep.log_messages (
        CONSTRAINT log_messages_in_need_of_extraction_pk
            PRIMARY KEY (id)
    ) FOR VALUES IN (FALSE)
    TABLESPACE sitrep_log_messages_in_need_of_extraction;

CREATE TABLE sitrep.log_messages_extracted_from
    PARTITION OF sitrep.log_messages (
        CONSTRAINT log_messages_extracted_from_pk
            PRIMARY KEY (id)
    ) FOR VALUES IN (TRUE)
    TABLESPACE sitrep_log_messages_extracted_from;

GRANT SELECT, INSERT, UPDATE, DELETE
    ON TABLE sitrep.log_messages
    TO sitrep_receive;

--------------------------------------------------------------------------------
-- Table sitrep.journal_acl

CREATE TABLE sitrep.journal_acl (
    identity_id uuid,
    journal_id uuid,
    CONSTRAINT journal_acl_pk
        PRIMARY KEY (identity_id, journal_id),
    CONSTRAINT journal_acl_identity_fk
        FOREIGN KEY (identity_id)
        REFERENCES sitrep.identities (id)
        ON DELETE CASCADE,
    CONSTRAINT journal_acl_journal_fk
        FOREIGN KEY (journal_id)
        REFERENCES sitrep.journals (id)
        ON DELETE CASCADE
        DEFERRABLE,

    can_record_log_message boolean NOT NULL
);

GRANT SELECT, INSERT, UPDATE, DELETE
    ON TABLE sitrep.journal_acl
    TO sitrep_receive;

ALTER TABLE sitrep.journals
    ENABLE ROW LEVEL SECURITY;

CREATE POLICY journal_acl
    ON sitrep.journals
    AS PERMISSIVE
    USING (
        EXISTS (
            SELECT
            FROM sitrep.journal_acl
            WHERE journal_acl.identity_id = sitrep.current_identity_id() AND
                  journal_acl.journal_id  = journals.id
        )
    );

ALTER TABLE sitrep.log_messages
    ENABLE ROW LEVEL SECURITY;

CREATE POLICY journal_acl
    ON sitrep.log_messages
    AS PERMISSIVE
    USING (
        EXISTS (
            SELECT
            FROM sitrep.journal_acl
            WHERE journal_acl.identity_id = sitrep.current_identity_id() AND
                  journal_acl.journal_id  = log_messages.journal_id
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT
            FROM sitrep.journal_acl
            WHERE journal_acl.identity_id = sitrep.current_identity_id() AND
                  journal_acl.journal_id  = log_messages.journal_id AND
                  journal_acl.can_record_log_message
        )
    );

COMMIT WORK;
