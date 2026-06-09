\set ON_ERROR_STOP on

SET search_path TO id_benchmark, public;

\echo 'Relation sizes'
SELECT
    c.relname AS relation_name,
    c.reltuples::bigint AS estimated_rows,
    pg_size_pretty(pg_relation_size(c.oid)) AS heap_size,
    pg_size_pretty(pg_indexes_size(c.oid)) AS indexes_size,
    pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size
FROM pg_class AS c
JOIN pg_namespace AS n ON n.oid = c.relnamespace
WHERE n.nspname = 'id_benchmark'
  AND c.relkind = 'r'
  AND c.relname IN (
      'event_log_bigserial',
      'event_log_uuid',
      'event_note_bigserial',
      'event_note_uuid'
  )
ORDER BY c.relname;

\echo 'Index sizes'
SELECT
    schemaname,
    tablename,
    indexrelname AS index_name,
    idx_scan,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE schemaname = 'id_benchmark'
ORDER BY tablename, indexrelname;

\echo 'Average stored identifier width'
SELECT
    'event_log_bigserial.id' AS column_name,
    avg(pg_column_size(id))::numeric(10, 2) AS avg_bytes
FROM event_log_bigserial
UNION ALL
SELECT
    'event_log_uuid.id' AS column_name,
    avg(pg_column_size(id))::numeric(10, 2) AS avg_bytes
FROM event_log_uuid
UNION ALL
SELECT
    'event_note_bigserial.event_id' AS column_name,
    avg(pg_column_size(event_id))::numeric(10, 2) AS avg_bytes
FROM event_note_bigserial
UNION ALL
SELECT
    'event_note_uuid.event_id' AS column_name,
    avg(pg_column_size(event_id))::numeric(10, 2) AS avg_bytes
FROM event_note_uuid
ORDER BY column_name;

\echo 'Primary key lookup: BIGSERIAL'
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM event_log_bigserial
WHERE id = (SELECT max(id) / 2 FROM event_log_bigserial);

\echo 'Primary key lookup: UUID'
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM event_log_uuid
WHERE id = (
    SELECT id
    FROM event_log_uuid
    ORDER BY created_at
    OFFSET 1000
    LIMIT 1
);

\echo 'Recent events by tenant: BIGSERIAL'
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, tenant_id, event_type, created_at
FROM event_log_bigserial
WHERE tenant_id = 42
ORDER BY created_at DESC
LIMIT 50;

\echo 'Recent events by tenant: UUID'
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, tenant_id, event_type, created_at
FROM event_log_uuid
WHERE tenant_id = 42
ORDER BY created_at DESC
LIMIT 50;
