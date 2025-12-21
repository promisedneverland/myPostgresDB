CREATE EXTENSION IF NOT EXISTS vector;

-- base 表：带标量字段 + 向量
DROP TABLE IF EXISTS sift_base;
CREATE TABLE sift_base (
  id        bigint PRIMARY KEY,
  category  smallint,
  price     integer,
  v         vector(128)  -- SIFT1M 是 128 维
);

-- query 表：只有向量
DROP TABLE IF EXISTS sift_query;
CREATE TABLE sift_query (
  id bigint PRIMARY KEY,
  v  vector(128)
);

COPY sift_base (id, category, price, v)
FROM '/home/pg172/vector_data/sift1m/sift_base_pg.csv'
WITH (FORMAT csv);

COPY sift_query (id, v)
FROM '/home/pg172/vector_data/sift1m/sift_query_pg.csv'
WITH (FORMAT csv);

DROP INDEX IF EXISTS sift_base_v_ivfflat;
DROP INDEX IF EXISTS sift_base_v_hnsw;



-- 向量索引：ivfflat + L2 距离
CREATE INDEX sift_base_v_ivfflat
ON sift_base USING ivfflat (v vector_l2_ops)
WITH (lists = 1000);   -- 1M 数据量，lists 可以先设 1000

-- hnsw + l2 距离
CREATE INDEX sift_base_v_hnsw
ON sift_base
USING hnsw (v vector_l2_ops)
WITH (m = 16, ef_construction = 200);

-- SET hnsw.ef_search = 10;
                          
-- SET hnsw.ef_search = 40;

-- 标量索引（可选，但有助于标量过滤）
CREATE INDEX sift_base_category_idx ON sift_base (category);
CREATE INDEX sift_base_price_idx    ON sift_base (price);

ANALYZE sift_base;
ANALYZE sift_query;

-- 单条 query，纯向量 Top-10
EXPLAIN (ANALYZE, BUFFERS)
WITH probe AS (
  SELECT v AS qv FROM sift_query WHERE id = 0
)
SELECT id, v <-> (SELECT qv FROM probe) AS distance
FROM sift_base
ORDER BY distance
LIMIT 10;


EXPLAIN (ANALYZE, BUFFERS)
 SELECT q.id AS qid, s.id AS nid
 FROM sift_query q 
 CROSS JOIN LATERAL (
  SELECT id
  FROM sift_base
  ORDER BY v <-> q.v
  LIMIT 1
) AS s;

EXPLAIN (ANALYZE, BUFFERS)
 SELECT q.id AS qid, s.id AS nid
 FROM (
     SELECT *
     FROM sift_query
     LIMIT 10
 ) q
CROSS JOIN LATERAL (
     SELECT id
     FROM sift_base
     ORDER BY v <-> q.v
     LIMIT 1
 ) AS s;




