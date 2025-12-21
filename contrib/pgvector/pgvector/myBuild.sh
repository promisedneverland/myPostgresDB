#!/bin/bash
# rebuild.sh - 快速重编译脚本

# 1. 停止出错就退出
set -e

# 2. 重新编译安装
echo "🔧 Rebuilding pgvector..."
# make clean
make PG_CONFIG=/home/lichengqi/pgsql/bin/pg_config
make install PG_CONFIG=/home/lichengqi/pgsql/bin/pg_config

# 3. 重启数据库
echo "🔄 Restarting PostgreSQL..."
# ⚠️ 注意：请确认这里的数据目录路径是否正确
/home/lichengqi/pgsql/bin/pg_ctl -D /home/lichengqi/pgsql/data -m fast restart

echo "✅ Done!"