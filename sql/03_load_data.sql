\set ON_ERROR_STOP on

\if :{?rows}
\else
\set rows 500000
\endif

SET search_path TO id_benchmark, public;

\echo 'Loading benchmark data. Row count per event_log table:' :rows
\timing on

TRUNCATE TABLE
    event_note_bigserial,
    event_note_uuid,
    event_log_bigserial,
    event_log_uuid
RESTART IDENTITY;

\echo 'Inserting BIGSERIAL event_log rows...'
INSERT INTO event_log_bigserial (
    tenant_id,
    actor_id,
    event_type,
    created_at,
    payload
)
SELECT
    (g % 1000) + 1 AS tenant_id,
    ((g * 17) % 1000000) + 1 AS actor_id,
    (ARRAY['login', 'view', 'purchase', 'export', 'delete'])[1 + ((g - 1) % 5)] AS event_type,
    clock_timestamp() - ((:rows - g) * interval '1 millisecond') AS created_at,
    jsonb_build_object(
        'sequence', g,
        'source', 'benchmark',
        'checksum', md5(g::text),
        'amount', ((g % 100000)::numeric / 100)
    ) AS payload
FROM generate_series(1, :rows) AS g;

\echo 'Inserting UUID event_log rows...'
INSERT INTO event_log_uuid (
    tenant_id,
    actor_id,
    event_type,
    created_at,
    payload
)
SELECT
    (g % 1000) + 1 AS tenant_id,
    ((g * 17) % 1000000) + 1 AS actor_id,
    (ARRAY['login', 'view', 'purchase', 'export', 'delete'])[1 + ((g - 1) % 5)] AS event_type,
    clock_timestamp() - ((:rows - g) * interval '1 millisecond') AS created_at,
    jsonb_build_object(
        'sequence', g,
        'source', 'benchmark',
        'checksum', md5(g::text),
        'amount', ((g % 100000)::numeric / 100)
    ) AS payload
FROM generate_series(1, :rows) AS g;

\echo 'Inserting child rows for BIGSERIAL variant...'
INSERT INTO event_note_bigserial (
    event_id,
    note_type,
    created_at,
    body
)
SELECT
    id,
    'audit',
    created_at,
    'deterministic note for event ' || id::text
FROM event_log_bigserial
WHERE (payload->>'sequence')::bigint % 10 = 0;

\echo 'Inserting child rows for UUID variant...'
INSERT INTO event_note_uuid (
    event_id,
    note_type,
    created_at,
    body
)
SELECT
    id,
    'audit',
    created_at,
    'deterministic note for event ' || id::text
FROM event_log_uuid
WHERE (payload->>'sequence')::bigint % 10 = 0;

ANALYZE event_log_bigserial;
ANALYZE event_log_uuid;
ANALYZE event_note_bigserial;
ANALYZE event_note_uuid;

\echo 'Data load finished.'
