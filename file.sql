CREATE TABLE "ticks" ("time" timestamp with time zone not null, "symbol" text, "price" decimal, "volume" float);

SELECT create_hypertable('ticks', 'time', chunk_time_interval => INTERVAL '1 day');

CREATE MATERIALIZED VIEW candlestick_1m
WITH (timescaledb.continuous) AS
SELECT time_bucket('1m', time),
       "ticks"."symbol",
       candlestick_agg(time, price, volume) as candlestick
FROM "ticks"
GROUP BY 1, 2
ORDER BY 1
WITH DATA;

CREATE MATERIALIZED VIEW candlestick_1h
WITH (timescaledb.continuous ) AS
SELECT time_bucket('1 hour', "time_bucket"),
       symbol,
       rollup(candlestick) as candlestick 
FROM "candlestick_1m"
GROUP BY 1, 2
ORDER BY 1
WITH NO DATA;

