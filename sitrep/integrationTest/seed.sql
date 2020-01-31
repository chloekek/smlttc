\set ON_ERROR_STOP on

START TRANSACTION;

INSERT INTO sitrep.identities (id, name)
VALUES ('0000000a-0000-0000-0000-000000000001', 'Identity 1'),
       ('0000000a-0000-0000-0000-000000000002', 'Identity 2');

INSERT INTO sitrep.authentication_tokens (id, owner_id, name, key, expires)
VALUES ('0000000b-0000-0000-0000-000000000001',
        '0000000a-0000-0000-0000-000000000001',
        'Authentication token 1',
        '0000000c-0000-0000-0001-000000000001',
        now() + INTERVAL '1 year'),
       ('0000000b-0000-0000-0000-000000000002',
        '0000000a-0000-0000-0000-000000000001',
        'Authentication token 1',
        '0000000c-0000-0000-0002-000000000001',
        now() - INTERVAL '1 year');

/*
INSERT INTO sitrep.journals (id, name)
VALUES ('23ab1d03-24a4-4cf6-9c49-f26da8862d79', 'Journal 1');

INSERT INTO sitrep.journal_acl (identity_id, journal_id, can_record_log_message)
VALUES ('a37bbf27-2fb1-4436-a96a-44acb462bf4d',
        '23ab1d03-24a4-4cf6-9c49-f26da8862d79',
        TRUE);
*/

COMMIT WORK;
