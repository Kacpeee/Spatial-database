-- Tworzenie rastrów z istniejących rastrów i interakcja z wektorami
CREATE TABLE pilecki.intersects AS
SELECT a.rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

ALTER TABLE pilecki.intersects
ADD COLUMN rid SERIAL PRIMARY KEY;

CREATE INDEX idx_intersects_rast_gist ON pilecki.intersects
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('pilecki'::name,
'intersects'::name,'rast'::name);

CREATE TABLE pilecki.clip AS
SELECT ST_Clip(a.rast, b.geom, true), b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO';

CREATE TABLE pilecki.union AS
SELECT ST_Union(ST_Clip(a.rast, b.geom, true))
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' AND ST_Intersects(b.geom,a.rast);


-- Tworzenie rastrów z wektorów (rastrowanie)
CREATE TABLE pilecki.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

DROP TABLE IF EXISTS pilecki.porto_parishes;
CREATE TABLE pilecki.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

DROP TABLE IF EXISTS pilecki.porto_parishes;
CREATE TABLE pilecki.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1 )
SELECT st_tile(st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-
32767)),128,128,true,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';


-- Konwertowanie rastrów na wektory (wektoryzowanie)
CREATE TABLE pilecki.intersection AS
SELECT
a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)
).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' AND ST_Intersects(b.geom,a.rast);

CREATE TABLE pilecki.dumppolygons AS
SELECT
a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,(ST_DumpAsPolygons(
ST_Clip(a.rast,b.geom))).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' AND ST_Intersects(b.geom,a.rast);


-- Analiza rastrów
CREATE TABLE pilecki.landsat_nir AS
SELECT rid, ST_Band(rast,4) AS rast
FROM rasters.landsat8;

CREATE TABLE pilecki.paranhos_dem AS
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' AND ST_Intersects(b.geom,a.rast);

CREATE TABLE pilecki.paranhos_slope AS
SELECT a.rid,ST_Slope(a.rast,1,'32BF','PERCENTAGE') AS rast
FROM pilecki.paranhos_dem AS a;

CREATE TABLE pilecki.paranhos_slope_reclass AS
SELECT a.rid,ST_Reclass(a.rast,1,']0-15]:1, (15-30]:2, (30-9999:3',
'32BF',0)
FROM pilecki.paranhos_slope AS a;

SELECT st_summarystats(a.rast) AS stats
FROM pilecki.paranhos_dem AS a;

SELECT st_summarystats(ST_Union(a.rast))
FROM pilecki.paranhos_dem AS a;

WITH t AS (
SELECT st_summarystats(ST_Union(a.rast)) AS stats
FROM pilecki.paranhos_dem AS a
)
SELECT (stats).min,(stats).max,(stats).mean FROM t;

WITH t AS (
SELECT b.parish AS parish, st_summarystats(ST_Union(ST_Clip(a.rast,
b.geom,true))) AS stats
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' AND ST_Intersects(b.geom,a.rast)
GROUP BY b.parish
)
SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;

SELECT b.name,st_value(a.rast,(ST_Dump(b.geom)).geom)
FROM
rasters.dem a, vectors.places AS b
WHERE ST_Intersects(a.rast,b.geom)
ORDER BY b.name;

CREATE TABLE pilecki.tpi30 AS
SELECT ST_TPI(a.rast,1) AS rast
FROM rasters.dem a;

CREATE INDEX idx_tpi30_rast_gist ON pilecki.tpi30
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('pilecki'::name,
'tpi30'::name,'rast'::name);

CREATE TABLE pilecki.tpi30_porto AS
SELECT ST_TPI(a.rast,1) AS rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';


-- Algebra map
CREATE TABLE pilecki.porto_ndvi AS
WITH r AS (
	SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
	FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' AND ST_Intersects(b.geom,a.rast)
	)
SELECT
	r.rid,ST_MapAlgebra(
	r.rast, 1,
	r.rast, 4,
	'([rast2.val] - [rast1.val]) / ([rast2.val] +
	[rast1.val])::float','32BF'
) AS rast
FROM r;

CREATE INDEX idx_porto_ndvi_rast_gist ON pilecki.porto_ndvi
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('pilecki'::name,
'porto_ndvi'::name,'rast'::name);

CREATE OR REPLACE FUNCTION pilecki.ndvi(
value double precision [] [] [],
pos integer [][],
VARIADIC userargs text []
)
RETURNS double precision AS
$$
BEGIN
RETURN (value [2][1][1] - value [1][1][1])/(value [2][1][1]+value
[1][1][1]);
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE COST 1000;

CREATE TABLE pilecki.porto_ndvi2 AS
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' AND ST_Intersects(b.geom,a.rast)
)
SELECT
r.rid,ST_MapAlgebra(
r.rast, ARRAY[1,4],
'pilecki.ndvi(double precision[],
integer[],text[])'::regprocedure,
'32BF'::text
) AS rast
FROM r;

CREATE INDEX idx_porto_ndvi2_rast_gist ON pilecki.porto_ndvi2
USING gist (ST_ConvexHull(rast));
SELECT AddRasterConstraints('pilecki'::name,
'porto_ndvi2'::name,'rast'::name);


-- Eksport rastrów
SELECT ST_AsTiff(ST_Union(rast))
FROM pilecki.porto_ndvi;

SELECT ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=0'])
FROM pilecki.porto_ndvi;
SELECT ST_GDALDrivers();

CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
		ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=9'])
		) AS loid
FROM pilecki.porto_ndvi;

SELECT lo_export(loid, 'C:\Windows\Temp\myraster.tiff')
FROM tmp_out;