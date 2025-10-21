-- 1. Włącz rozszerzenie PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;

-- 2. Utwórz tabele
DROP TABLE IF EXISTS buildings, roads, poi;

CREATE TABLE buildings (
    id serial PRIMARY KEY,
    name varchar(50),
    geom geometry(Polygon, 0)
);

CREATE TABLE roads (
    id serial PRIMARY KEY,
    name varchar(50),
    geom geometry(LineString, 0)
);

CREATE TABLE poi (
    id serial PRIMARY KEY,
    name varchar(50),
    geom geometry(Point, 0)
);

-- 3. Wstaw dane z mapki

-- Budynki
INSERT INTO buildings (name, geom) VALUES
('BuildingA', ST_GeomFromText('POLYGON((10 0, 12 0, 12 4, 10 4, 10 0))', 0)),
('BuildingB', ST_GeomFromText('POLYGON((4 5, 6 5, 6 9, 4 9, 4 5))', 0)),
('BuildingC', ST_GeomFromText('POLYGON((6 5, 9 5, 9 9, 6 9, 6 5))', 0)),
('BuildingD', ST_GeomFromText('POLYGON((0 0, 3 0, 3 3, 0 3, 0 0))', 0));

-- Drogi
INSERT INTO roads (name, geom) VALUES
('RoadX', ST_GeomFromText('LINESTRING(0 5, 12 5)', 0)),
('RoadY', ST_GeomFromText('LINESTRING(6 0, 6 10)', 0));

-- Punkt K
INSERT INTO poi (name, geom) VALUES
('K', ST_GeomFromText('POINT(8 3)', 0));

-- 4. Zapytania

-- a) Całkowita długość dróg
SELECT SUM(ST_Length(geom)) AS total_road_length FROM roads;

-- b) Geometria, pole i obwód BuildingA
SELECT
    name,
    ST_AsText(geom) AS wkt,
    ST_Area(geom) AS area,
    ST_Perimeter(geom) AS perimeter
FROM buildings
WHERE name = 'BuildingA';

-- c) Nazwy i pola powierzchni wszystkich budynków (alfabetycznie)
SELECT
    name,
    ST_Area(geom) AS area
FROM buildings
ORDER BY name;

-- d) Dwa budynki o największej powierzchni
SELECT name, ST_Area(geom) AS area
FROM buildings
ORDER BY area DESC
LIMIT 2;

-- e) Najkrótsza odległość między BuildingC a punktem K
SELECT
    ST_Distance(
        (SELECT geom FROM buildings WHERE name='BuildingC'),
        (SELECT geom FROM poi WHERE name='K')
    ) AS min_distance;

-- f) Pole części BuildingC w odległości większej niż 0.5 od BuildingB
SELECT
    ST_Area(
        ST_Difference(
            (SELECT geom FROM buildings WHERE name='BuildingC'),
            ST_Buffer((SELECT geom FROM buildings WHERE name='BuildingB'), 0.5)
        )
    ) AS area_diff;

-- g) Budynki, których centroid leży powyżej drogi RoadX
SELECT
    b.name
FROM buildings b, roads r
WHERE r.name = 'RoadX'
AND ST_Y(ST_Centroid(b.geom)) > ST_Y(ST_StartPoint(r.geom));

-- h) Pole części wspólnej BuildingC i poligonu o wierzchołkach (4 7, 6 7, 6 8, 4 8, 4 7)
SELECT
    ST_Area(
        ST_Intersection(
            (SELECT geom FROM buildings WHERE name='BuildingC'),
            ST_GeomFromText('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))', 0)
        )
    ) AS intersection_area;
