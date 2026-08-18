\set ON_ERROR_STOP on
DROP VIEW IF EXISTS pgvector_bench.ivfflat_index_inventory;
DROP VIEW IF EXISTS pgvector_bench.vector_index_catalog;
\ir ../../../sql/02_memory_model.sql
\ir ../../../sql/04_catalog_introspect.sql
\ir ../../../sql/05_audit.sql
CREATE EXTENSION IF NOT EXISTS vector;
BEGIN;
DROP TABLE IF EXISTS pgvector_bench.audit_figure_case;
CREATE TABLE pgvector_bench.audit_figure_case (id integer, embedding vector(3));
INSERT INTO pgvector_bench.audit_figure_case
SELECT g, ARRAY[sin(g::double precision), cos(g::double precision), (g % 17)::double precision]::vector
FROM generate_series(1, 1000) AS g;
ANALYZE pgvector_bench.audit_figure_case;
CREATE INDEX audit_figure_ivf_idx ON pgvector_bench.audit_figure_case USING ivfflat (embedding vector_l2_ops) WITH (lists = 10);
CREATE INDEX audit_figure_hnsw_idx ON pgvector_bench.audit_figure_case USING hnsw (embedding vector_l2_ops);
SELECT schema_name, table_name, index_name, index_type, row_count, dims, lists,
       recommended_lists, predicted_build_memory_mb, maintenance_work_mem_mb,
       risk_level, recommended_probes, possible_seqscan, audit_note
FROM pgvector_bench.audit_all_vector_indexes()
WHERE table_name = 'audit_figure_case'
ORDER BY index_name;
ROLLBACK;
