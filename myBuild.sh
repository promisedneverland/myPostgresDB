#!/bin/bash
./configure --prefix=/home/lichengqi/pgsql
  make -j4
  make install
  /home/lichengqi/pgsql/bin/initdb -D /home/lichengqi/pgsql/data
  /home/lichengqi/pgsql/bin/pg_ctl -D /home/lichengqi/pgsql/data -l /home/lichengqi/pgsql/logfile start
  /home/lichengqi/pgsql/bin/createdb testHarmony