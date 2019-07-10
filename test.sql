CREATE extension plpython3u;

CREATE or REPLACE FUNCTION py_ver() RETURNS setof text as $$
import sys
import requests
import yaml
import functools
import more_itertools as mi
import pyparsing
import furl
import numpy as np
import cachetools
import subprocess as subp
m = sys.modules
yield sys.version
yield '--------'
for i in m.keys():
    yield i
$$ LANGUAGE plpython3u;

SELECT py_ver();


-- ## rum
CREATE extension rum;


-- ## timescaledb
-- Do not forget to create timescaledb extension
CREATE EXTENSION timescaledb;

-- We start by creating a regular SQL table
CREATE TABLE conditions (
  time        TIMESTAMPTZ       NOT NULL,
  location    TEXT              NOT NULL,
  temperature DOUBLE PRECISION  NULL,
  humidity    DOUBLE PRECISION  NULL
);

-- Then we convert it into a hypertable that is partitioned by time
SELECT create_hypertable('conditions', 'time');

INSERT INTO conditions(time, location, temperature, humidity)
  VALUES (NOW(), 'office', 70.0, 50.0);

SELECT * FROM conditions ORDER BY time DESC LIMIT 100;

SELECT time_bucket('15 minutes', time) AS fifteen_min,
    location, COUNT(*),
    MAX(temperature) AS max_temp,
    MAX(humidity) AS max_hum
  FROM conditions
  WHERE time > NOW() - interval '3 hours'
  GROUP BY fifteen_min, location
  ORDER BY fifteen_min DESC, max_temp DESC;

-- pg_test requests
CREATE or REPLACE FUNCTION py_requests_get(url TEXT) RETURNS setof text as $$
import requests
yield requests.get(url).text
$$ LANGUAGE plpython3u;

SELECT  py_requests_get('http://www.baidu.com');

-- ## pg_jieba
CREATE extension pg_jieba;
select * from to_tsquery('jiebacfg', '小明硕士毕业于中国科学院计算所，后在日本京都大学深造');
select * from to_tsquery('jiebaqry', '小明硕士毕业于中国科学院计算所，后在日本京都大学深造');