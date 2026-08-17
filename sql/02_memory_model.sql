\set ON_ERROR_STOP on

CREATE SCHEMA IF NOT EXISTS pgvector_bench;

CREATE TABLE IF NOT EXISTS pgvector_bench.schema_version (
    version integer PRIMARY KEY,
    applied_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    description text NOT NULL
);

INSERT INTO pgvector_bench.schema_version (version, applied_at, description)
VALUES (2, clock_timestamp(), 'Source-derived IVFFlat build memory model')
ON CONFLICT (version) DO UPDATE
SET description = EXCLUDED.description;

CREATE OR REPLACE FUNCTION pgvector_bench.ivfflat_vector_array_size(
    array_length bigint,
    item_size bigint
)
RETURNS bigint
LANGUAGE plpgsql
IMMUTABLE
STRICT
SET search_path = pg_catalog, pg_temp
AS $$
BEGIN
    IF array_length < 0 THEN
        RAISE EXCEPTION 'array_length must not be negative';
    END IF;
    IF item_size <= 0 THEN
        RAISE EXCEPTION 'item_size must be positive';
    END IF;

    RETURN 32 + array_length * ((item_size + 7) / 8 * 8);
END;
$$;

CREATE OR REPLACE FUNCTION pgvector_bench.ivfflat_memory_breakdown(
    row_count bigint,
    dims integer,
    lists integer
)
RETURNS TABLE (
    allocation_name text,
    bytes bigint
)
LANGUAGE plpgsql
IMMUTABLE
STRICT
SET search_path = pg_catalog, pg_temp
AS $$
DECLARE
    target_samples bigint;
    actual_samples bigint;
    item_size bigint;
BEGIN
    IF row_count <= 0 THEN
        RAISE EXCEPTION 'row_count must be positive';
    END IF;
    IF dims <= 0 OR dims > 16000 THEN
        RAISE EXCEPTION 'dims must be in [1, 16000] for vector';
    END IF;
    IF lists <= 0 OR lists > 32768 THEN
        RAISE EXCEPTION 'lists must be in [1, 32768]';
    END IF;

    target_samples := GREATEST(10000::bigint, lists::bigint * 50);
    actual_samples := LEAST(row_count, target_samples);
    item_size := 8 + dims::bigint * 4;

    RETURN QUERY VALUES
        ('samplesSize'::text, pgvector_bench.ivfflat_vector_array_size(target_samples, item_size)),
        ('centersSize'::text, pgvector_bench.ivfflat_vector_array_size(lists, item_size)),
        ('newCentersSize'::text, pgvector_bench.ivfflat_vector_array_size(lists, item_size)),
        ('aggSize'::text, 4::bigint * lists * dims),
        ('centerCountsSize'::text, 4::bigint * lists),
        ('closestCentersSize'::text, 4::bigint * actual_samples),
        ('lowerBoundSize'::text, 4::bigint * actual_samples * lists),
        ('upperBoundSize'::text, 4::bigint * actual_samples),
        ('sSize'::text, 4::bigint * lists),
        ('halfcdistSize'::text, 4::bigint * lists * lists),
        ('newcdistSize'::text, 4::bigint * lists);
END;
$$;

CREATE OR REPLACE FUNCTION pgvector_bench.estimate_ivfflat_build_memory_bytes(
    row_count bigint,
    dims integer,
    lists integer
)
RETURNS bigint
LANGUAGE sql
IMMUTABLE
STRICT
SET search_path = pg_catalog, pg_temp
AS $$
    SELECT sum(bytes)::bigint
    FROM pgvector_bench.ivfflat_memory_breakdown(row_count, dims, lists)
$$;

CREATE OR REPLACE FUNCTION pgvector_bench.estimate_ivfflat_build_memory_mb(
    row_count bigint,
    dims integer,
    lists integer
)
RETURNS numeric
LANGUAGE sql
IMMUTABLE
STRICT
SET search_path = pg_catalog, pg_temp
AS $$
    SELECT floor(
        pgvector_bench.estimate_ivfflat_build_memory_bytes(row_count, dims, lists)::numeric
        / (1024 * 1024)
    ) + 1
$$;

COMMENT ON FUNCTION pgvector_bench.ivfflat_memory_breakdown(bigint, integer, integer)
IS 'Eleven allocations from pgvector src/ivfkmeans.c:277-288 for vector IVFFlat builds';

COMMENT ON FUNCTION pgvector_bench.estimate_ivfflat_build_memory_mb(bigint, integer, integer)
IS 'Matches pgvector ivfkmeans.c error-message rounding: totalSize / MiB + 1';
