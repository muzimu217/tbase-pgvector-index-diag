\set ON_ERROR_STOP on

BEGIN;
\ir ../../sql/02_memory_model.sql

DO $$
DECLARE
    allocation_count integer;
BEGIN
    SELECT count(*)
    INTO allocation_count
    FROM pgvector_bench.ivfflat_memory_breakdown(100000, 128, 1000);

    IF allocation_count <> 11 THEN
        RAISE EXCEPTION 'expected 11 allocations, got %', allocation_count;
    END IF;

    IF pgvector_bench.ivfflat_vector_array_size(10000, 520) <> 5200032 THEN
        RAISE EXCEPTION 'VECTOR_ARRAY_SIZE translation is incorrect';
    END IF;

    IF pgvector_bench.estimate_ivfflat_build_memory_mb(100000, 128, 100) <> 10 THEN
        RAISE EXCEPTION 'unexpected estimate for 100000/128/100';
    END IF;

    IF pgvector_bench.estimate_ivfflat_build_memory_mb(100000, 128, 1000) <> 222 THEN
        RAISE EXCEPTION 'unexpected estimate for 100000/128/1000';
    END IF;

    IF pgvector_bench.estimate_ivfflat_build_memory_mb(200000, 384, 8192) <> 7147 THEN
        RAISE EXCEPTION 'unexpected estimate for 200000/384/8192';
    END IF;
END;
$$;

ROLLBACK;
