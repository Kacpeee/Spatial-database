create extension postgis;
create extension postgis_raster;


Select count(*) from uk_250k;


Select * from national_parks;



-- Zadanie 6
CREATE TABLE uk_lake_district AS
SELECT
    ST_Clip(r.rast, p.geom, true) AS rast
FROM
    uk_250k AS r,
    national_parks AS p
WHERE
    p.id = 1  -- ID:1 to Lake District
    AND ST_Intersects(r.rast, p.geom);

Select * from uk_lake_district



UPDATE national_parks SET geom = ST_SetSRID(geom, 27700)
WHERE ST_SRID(geom) = 0 OR ST_SRID(geom) IS NULL;






-- Zadanie 10
-- Stworzenie B03 obciętego do obszaru Lake District
-- KROK 1: PRZYCIĘCIE PASM DO GRANIC LAKE DISTRICT

UPDATE sentinel_green SET rast = ST_SetSRID(rast, 32630)
WHERE ST_SRID(rast) = 0 OR ST_SRID(rast) IS NULL;

-- 2. Ustawienie poprawnego SRID dla pasma Podczerwieni (B8)
UPDATE sentinel_nir SET rast = ST_SetSRID(rast, 32630)
WHERE ST_SRID(rast) = 0 OR ST_SRID(rast) IS NULL;




CREATE TABLE sentinel_green_clip AS
SELECT
    ST_Clip(r.rast, ST_Transform(p.geom, ST_SRID(r.rast)), true) AS rast
FROM
    sentinel_green r,
    national_parks p
WHERE
    p.id = 1
    AND ST_Intersects(r.rast, ST_Transform(p.geom, ST_SRID(r.rast)));

SELECT AddRasterConstraints('sentinel_green_clip', 'rast');
CREATE INDEX sentinel_green_clip_idx ON sentinel_green_clip USING GIST (ST_ConvexHull(rast));


CREATE TABLE sentinel_nir_clip AS
SELECT
    ST_Clip(r.rast, ST_Transform(p.geom, ST_SRID(r.rast)), true) AS rast
FROM
    sentinel_nir r,
    national_parks p
WHERE
    p.id = 1
    AND ST_Intersects(r.rast, ST_Transform(p.geom, ST_SRID(r.rast)));

SELECT AddRasterConstraints('sentinel_nir_clip', 'rast');
CREATE INDEX sentinel_nir_clip_idx ON sentinel_nir_clip USING GIST (ST_ConvexHull(rast));


-- KROK 2: OBLICZENIE NDWI (Punkt 10)

CREATE TABLE lake_district_ndwi_finalll AS
SELECT
    ST_SetSRID(
        ST_MapAlgebra(
            a.rast,
            b.rast,
            '([rast1] - [rast2]) / NULLIF([rast1] + [rast2], 0)::float'
        ),
        ST_SRID(a.rast)
    ) AS rast
FROM
    sentinel_green_clip a,
    sentinel_nir_clip b
WHERE
    ST_Intersects(a.rast, b.rast);

SELECT AddRasterConstraints('lake_district_ndwi_finalll', 'rast');

















