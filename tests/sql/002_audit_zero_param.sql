\set ON_ERROR_STOP on

BEGIN;
\ir ../../sql/02_memory_model.sql
\ir ../../sql/04_catalog_introspect.sql
\ir ../../sql/05_audit.sql

CREATE EXTENSION IF NOT EXISTS vector;
DROP TABLE IF EXISTS pgvector_bench.audit_zero_param_case;
CREATE TABLE pgvector_bench.audit_zero_param_case (
    id bigint PRIMARY KEY,
    embedding vector(3) NOT NULL
);

INSERT INTO pgvector_bench.audit_zero_param_case (id, embedding)
SELECT g, ARRAY[0.1, 0.2, 0.3]::vector
FROM generate_series(1, 1000) AS s(g);

ANALYZE pgvector_bench.audit_zero_param_case;

CREATE INDEX audit_zero_param_ivf_idx
ON pgvector_bench.audit_zero_param_case
USING ivfflat (embedding vector_l2_ops)
WITH (lists = 10);

CREATE INDEX audit_zero_param_hnsw_idx
ON pgvector_bench.audit_zero_param_case
USING hnsw (embedding vector_l2_ops)
WITH (m = 8, ef_construction = 32);

DO $$
DECLARE
    function_args integer;
    index_count integer;
    ivf_rows bigint;
    ivf_dims integer;
    ivf_lists integer;
    hnsw_count integer;
BEGIN
    SELECT p.pronargs
    INTO function_args
    FROM pg_catalog.pg_proc AS p
    JOIN pg_catalog.pg_namespace AS n ON n.oid = p.pronamespace
    WHERE n.nspname = 'pgvector_bench'
      AND p.proname = 'audit_all_vector_indexes';

    IF function_args <> 0 THEN
        RAISE EXCEPTION 'audit_all_vector_indexes must have zero arguments';
    END IF;

    IF pgvector_bench.recommend_ivfflat_lists(100000, 3) <> 100
       OR pgvector_bench.recommend_ivfflat_lists(2000000, 3) <> 1415
       OR pgvector_bench.recommend_ivfflat_lists(10000000000, 3) <> 32768 THEN
        RAISE EXCEPTION 'official IVFFlat lists recommendation changed unexpectedly';
    END IF;

    SELECT count(*)
    INTO index_count
    FROM pgvector_bench.audit_all_vector_indexes()
    WHERE table_name = 'audit_zero_param_case';

    IF index_count <> 2 THEN
        RAISE EXCEPTION 'expected two vector indexes, got %', index_count;
    END IF;

    SELECT row_count, dims, lists
    INTO ivf_rows, ivf_dims, ivf_lists
    FROM pgvector_bench.audit_all_vector_indexes()
    WHERE index_name = 'audit_zero_param_ivf_idx';

    IF ivf_rows <> 1000 OR ivf_dims <> 3 OR ivf_lists <> 10 THEN
        RAISE EXCEPTION 'catalog extraction mismatch: rows %, dims %, lists %', ivf_rows, ivf_dims, ivf_lists;
    END IF;

    SELECT count(*)
    INTO hnsw_count
    FROM pgvector_bench.audit_all_vector_indexes()
    WHERE index_name = 'audit_zero_param_hnsw_idx'
      AND index_type = 'hnsw'
      AND dims = 3;

    IF hnsw_count <> 1 THEN
        RAISE EXCEPTION 'HNSW catalog row missing';
    END IF;
END;
$$;

SELECT index_name, index_type, row_count, dims, lists,
       recommended_lists, risk_level, recommended_probes,
       possible_seqscan
FROM pgvector_bench.audit_all_vector_indexes()
WHERE table_name = 'audit_zero_param_case'
ORDER BY index_name;

ROLLBACK;
