#!/usr/bin/env bash

# 连接配置
# PSQL_CMD=(/home/lichengqi/pgsql/bin/psql -h /tmp/pg5437 pgvector-test -X -q -P pager=off)
PSQL_CMD=(/home/lichengqi/pgsql/bin/psql testHarmony -X -q -P pager=off)

OUTFILE="bench_hnsw_100.log"

# 清空旧结果
: > "$OUTFILE"

for i in $(seq 1 100); do
  echo "================ RUN $i ================" >> "$OUTFILE"
  "${PSQL_CMD[@]}" >> "$OUTFILE" 2>&1 <<'SQL'
SET client_min_messages = info;

EXPLAIN (ANALYZE, BUFFERS)
SELECT q.id AS qid, b.id AS nid, b.category, b.price
FROM (
    SELECT *
    FROM sift_query
    LIMIT 10
) AS q
CROSS JOIN LATERAL (
    SELECT id, category, price
    FROM sift_base b
    WHERE b.category IN (3, 5, 7)
      AND b.price BETWEEN 100 AND 500
    ORDER BY b.v <-> q.v
    LIMIT 5
) AS b;
SQL
done
