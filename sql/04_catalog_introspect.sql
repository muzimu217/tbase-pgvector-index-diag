\set ON_ERROR_STOP on

CREATE SCHEMA IF NOT EXISTS pgvector_bench;

INSERT INTO pgvector_bench.schema_version (version, applied_at, description)
VALUES (3, clock_timestamp(), 'Catalog introspection for vector indexes')
ON CONFLICT (version) DO UPDATE
SET description = EXCLUDED.description;

CREATE OR REPLACE FUNCTION pgvector_bench.ivfflat_lists_from_options(
    options text[]
)
RETURNS integer
LANGUAGE sql
IMMUTABLE
STRICT
SET search_path = pg_catalog, pg_temp
AS $$
    SELECT NULLIF(
        (pg_catalog.regexp_match(
            pg_catalog.array_to_string(options, ','),
            '(^|,)lists=([0-9]+)(,|$)'
        ))[2],
        ''
    )::integer
$$;

DROP VIEW IF EXISTS pgvector_bench.ivfflat_index_inventory;

CREATE VIEW pgvector_bench.vector_index_catalog AS
SELECT
    table_ns.nspname AS schema_name,
    table_class.relname AS table_name,
    index_class.relname AS index_name,
    index_class.oid AS index_oid,
    table_class.oid AS table_oid,
    access_method.amname AS index_type,
    vector_attr.attname AS column_name,
    vector_type.typname AS vector_type,
    CASE
        WHEN table_class.reltuples < 0 THEN 0::bigint
        ELSE pg_catalog.floor(table_class.reltuples::numeric)::bigint
    END AS row_count,
    NULLIF(vector_attr.atttypmod, -1) AS dims,
    pgvector_bench.ivfflat_lists_from_options(index_class.reloptions) AS lists,
    pg_catalog.pg_relation_size(index_class.oid) AS index_size_bytes,
    index_class.reloptions AS index_options,
    index_entry.indisvalid AND index_entry.indisready AS index_valid,
    pg_catalog.pg_get_indexdef(index_class.oid) AS index_definition
FROM pg_catalog.pg_class AS index_class
JOIN pg_catalog.pg_index AS index_entry
  ON index_entry.indexrelid = index_class.oid
JOIN pg_catalog.pg_class AS table_class
  ON table_class.oid = index_entry.indrelid
JOIN pg_catalog.pg_namespace AS table_ns
  ON table_ns.oid = table_class.relnamespace
JOIN pg_catalog.pg_am AS access_method
  ON access_method.oid = index_class.relam
JOIN pg_catalog.pg_attribute AS vector_attr
  ON vector_attr.attrelid = table_class.oid
 AND vector_attr.attnum = index_entry.indkey[0]
 AND vector_attr.attnum > 0
JOIN pg_catalog.pg_type AS vector_type
  ON vector_type.oid = vector_attr.atttypid
WHERE index_class.relkind = 'i'
  AND access_method.amname IN ('ivfflat', 'hnsw')
  AND vector_type.typname = 'vector';

CREATE VIEW pgvector_bench.ivfflat_index_inventory AS
SELECT
    schema_name,
    table_name,
    index_name,
    index_size_bytes AS index_bytes,
    index_definition,
    index_type AS index_kind,
    row_count,
    dims,
    lists,
    index_valid
FROM pgvector_bench.vector_index_catalog
WHERE index_type = 'ivfflat';

COMMENT ON VIEW pgvector_bench.vector_index_catalog
IS 'Catalog-derived vector index parameters; row_count comes from pg_class.reltuples';

COMMENT ON VIEW pgvector_bench.ivfflat_index_inventory
IS 'IVFFlat inventory backed by vector_index_catalog';
