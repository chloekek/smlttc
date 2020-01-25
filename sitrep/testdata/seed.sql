START TRANSACTION;

INSERT INTO sitrep.identities (id, name)
VALUES ('a37bbf27-2fb1-4436-a96a-44acb462bf4d', 'Identity 1'),
       ('3c8df33e-0abd-40ca-a117-13aa27c54153', 'Identity 2');

INSERT INTO sitrep.journals (id, name)
VALUES ('23ab1d03-24a4-4cf6-9c49-f26da8862d79', 'Journal 1');

INSERT INTO sitrep.journal_acl (identity_id, journal_id, can_record_log_message)
VALUES ('a37bbf27-2fb1-4436-a96a-44acb462bf4d',
        '23ab1d03-24a4-4cf6-9c49-f26da8862d79',
        TRUE);

COMMIT WORK;
