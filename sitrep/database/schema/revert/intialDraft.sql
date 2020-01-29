START TRANSACTION;

DROP TABLE sitrep.journal_acl;
DROP TABLE sitrep.log_messages;
DROP TABLE sitrep.journals;
DROP TABLE sitrep.authentication_tokens;
DROP TABLE sitrep.identities;
DROP FUNCTION sitrep.set_identity_id(uuid);
DROP FUNCTION sitrep.current_identity_id();
DROP SCHEMA sitrep;

COMMIT WORK;
