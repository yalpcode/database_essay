\set ON_ERROR_STOP on

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DROP SCHEMA IF EXISTS id_benchmark CASCADE;
CREATE SCHEMA id_benchmark;

SET search_path TO id_benchmark, public;

\echo 'Prepared schema id_benchmark and pgcrypto extension.'
