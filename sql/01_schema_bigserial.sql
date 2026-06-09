\set ON_ERROR_STOP on

SET search_path TO id_benchmark, public;

CREATE TABLE event_log_bigserial (
    id BIGSERIAL PRIMARY KEY,
    tenant_id integer NOT NULL,
    actor_id bigint NOT NULL,
    event_type text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    payload jsonb NOT NULL
);

CREATE INDEX event_log_bigserial_tenant_created_idx
    ON event_log_bigserial (tenant_id, created_at DESC);

CREATE INDEX event_log_bigserial_type_created_idx
    ON event_log_bigserial (event_type, created_at DESC);

CREATE TABLE event_note_bigserial (
    id BIGSERIAL PRIMARY KEY,
    event_id bigint NOT NULL REFERENCES event_log_bigserial (id) ON DELETE CASCADE,
    note_type text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    body text NOT NULL
);

CREATE INDEX event_note_bigserial_event_id_idx
    ON event_note_bigserial (event_id);

COMMENT ON TABLE event_log_bigserial IS
    'Event log variant with sequential BIGSERIAL primary key.';

COMMENT ON TABLE event_note_bigserial IS
    'Child table used to show how primary key width affects foreign keys and their indexes.';
