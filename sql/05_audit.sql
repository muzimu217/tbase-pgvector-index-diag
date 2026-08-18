\set ON_ERROR_STOP on

CREATE SCHEMA IF NOT EXISTS pgvector_bench;

INSERT INTO pgvector_bench.schema_version (version, applied_at, description)
VALUES (4, clock_timestamp(), 'Zero-parameter vector index audit')
ON CONFLICT (version) DO UPDATE
SET description = EXCLUDED.description;

CREATE OR REPLACE FUNCTION pgvector_bench.audit_all_vector_indexes()
RETURNS TABLE (
    schema_name text,
    table_name text,
    index_name text,
    index_type text,
    row_count bigint,
    dims integer,
    lists integer,
    recommended_lists integer,
    lists_deviation numeric,
    predicted_build_memory_mb numeric,
    maintenance_work_mem_mb numeric,
    risk_level text,
    recommended_probes integer,
    possible_seqscan boolean,
    index_size_bytes bigint,
    index_definition text,
    audit_note text
)
LANGUAGE sql
STABLE
SET search_path = pg_catalog, pg_temp
AS $$
WITH prepared AS (
    SELECT
        c.*,
        pgvector_bench.parse_memory_mb(
            pg_catalog.current_setting('maintenance_work_mem')
        ) AS maintenance_mb,
        CASE
            WHEN c.index_type <> 'ivfflat' OR c.row_count <= 0 THEN NULL::integer
            ELSE pgvector_bench.recommend_ivfflat_lists(c.row_count, c.dims)
        END AS recommended,
        CASE
            WHEN c.index_type = 'ivfflat' AND c.lists IS NOT NULL AND c.lists > 0
                THEN GREATEST(
                    1,
                    LEAST(
                        c.lists,
                        pg_catalog.ceil(pg_catalog.sqrt(c.lists::numeric))::integer
                    )
                )
            ELSE NULL::integer
        END AS suggested_probes
    FROM pgvector_bench.vector_index_catalog AS c
), measured AS (
    SELECT
        p.*,
        CASE
            WHEN p.index_type = 'ivfflat'
             AND p.row_count > 0
             AND p.dims IS NOT NULL
             AND p.lists IS NOT NULL
             AND p.lists > 0
                THEN pgvector_bench.estimate_ivfflat_build_memory_mb(
                    p.row_count, p.dims, p.lists
                )
            ELSE NULL::numeric
        END AS predicted_mb,
        CASE
            WHEN p.recommended IS NULL OR p.recommended = 0 OR p.lists IS NULL
                THEN NULL::numeric
            ELSE pg_catalog.round(
                p.lists::numeric / p.recommended::numeric,
                4
            )
        END AS deviation
    FROM prepared AS p
)
SELECT
    schema_name::text,
    table_name::text,
    index_name::text,
    index_type::text,
    row_count,
    dims,
    lists,
    recommended,
    deviation,
    predicted_mb,
    maintenance_mb,
    CASE
        WHEN NOT index_valid THEN 'risk'
        WHEN row_count <= 0 OR dims IS NULL THEN 'info'
        WHEN index_type = 'ivfflat' AND lists IS NULL THEN 'risk'
        WHEN index_type = 'ivfflat' AND lists > row_count THEN 'risk'
        WHEN index_type = 'ivfflat' AND maintenance_mb < predicted_mb THEN 'risk'
        WHEN index_type = 'ivfflat'
         AND (deviation < 0.25 OR deviation > 4.0) THEN 'warn'
        ELSE 'ok'
    END AS risk_level,
    suggested_probes,
    (
        NOT index_valid
        OR (
            index_type = 'ivfflat'
            AND (lists IS NULL OR row_count <= 0 OR lists > row_count)
        )
    ) AS possible_seqscan,
    index_size_bytes,
    index_definition,
    CASE
        WHEN NOT index_valid
            THEN 'catalog marks the index invalid or not ready'
        WHEN row_count <= 0
            THEN 'pg_class.reltuples is unavailable or stale; run ANALYZE before relying on this row count'
        WHEN index_type = 'hnsw'
            THEN 'HNSW is inventoried; IVFFlat-only memory and probes checks are not applied'
        WHEN maintenance_mb < predicted_mb
            THEN pg_catalog.format(
                'maintenance_work_mem=%sMB is below predicted build memory=%sMB',
                maintenance_mb, predicted_mb
            )
        WHEN lists IS NULL
            THEN 'lists was not present in pg_class.reloptions'
        ELSE 'catalog-derived parameters are available; validate with representative EXPLAIN and recall tests'
    END AS audit_note
FROM measured
ORDER BY schema_name, table_name, index_name;
$$;

COMMENT ON FUNCTION pgvector_bench.audit_all_vector_indexes()
IS 'Zero-parameter catalog audit for vector indexes; possible_seqscan is a static catalog risk, not an EXPLAIN result';
