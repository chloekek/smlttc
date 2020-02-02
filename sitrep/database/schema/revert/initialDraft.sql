START TRANSACTION;

DROP POLICY journal_acl ON sitrep.log_messages;
DROP POLICY journal_acl ON sitrep.journals;
DROP TABLE sitrep.journal_acl;
DROP TABLE sitrep.log_messages_extracted_from;
DROP TABLE sitrep.log_messages_in_need_of_extraction;
DROP TABLE sitrep.log_messages;
DROP TABLE sitrep.journals;
DROP POLICY expiry ON sitrep.authentication_tokens;
DROP POLICY self ON sitrep.authentication_tokens;
DROP TABLE sitrep.authentication_tokens;
DROP POLICY self ON sitrep.identities;
DROP TABLE sitrep.identities;
DROP FUNCTION sitrep.set_identity_id(uuid);
DROP FUNCTION sitrep.current_identity_id();
DROP SCHEMA sitrep;

COMMIT WORK;
