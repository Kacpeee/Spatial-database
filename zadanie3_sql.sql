CREATE EXTENSION postgis;

SET search_path TO zadanie3;


--#1 laczy sie z baza danych 2019 z 2018 LEFT JOIN zstawia te ktore sa z 2019 i maja odpowinik z 2018 i nie wystapily w 2018
CREATE TABLE zadanie3.new_buildings AS
SELECT b19.*
FROM zadanie3.t2019_kar_buildings AS b19
LEFT JOIN zadanie3.t2018_kar_buildings AS b18
ON ST_Equals(b19.geom, b18.geom)
WHERE b18.geom IS NULL;

--#2 laczy sie z baza danych 2019 poi z wczesniej utworzana tabalea new_buildings i sprawdza punkty w promienu 500 od nowych budynkow
CREATE TABLE zadanie3.new_pois AS
SELECT 
    b.gid AS building_id,
    p.type AS category,
    COUNT(*) AS poi_count
FROM zadanie3.new_buildings b
JOIN zadanie3.t2019_kar_poi_table p
  ON ST_DWithin(b.geom , p.geom, 500.0)
GROUP BY b.gid, p.type
ORDER BY b.gid, poi_count DESC;


--#3 DHDN / 3-degree Gauss-Krüger zone 4 (Berlin/Cassini)

SELECT ST_SRID(geom)
FROM zadanie3.t2019_kar_streets
LIMIT 5;



CREATE TABLE zadanie3.streets_reprojected AS
SELECT
    gid,
    ST_Transform(geom,  3068) AS geom 
FROM zadanie3.t2019_kar_streets;

SELECT ST_AsText(geom) FROM zadanie3.streets_reprojected;


--#4 nowa tabela z 2 punktami St_SetSRID ustala ukadl wspolczenych ,ST_MakePoint towrz punkt gemoetryczny
CREATE TABLE zadanie3.input_points (
    id SERIAL PRIMARY KEY,
    geom geometry(Point, 4326)
);


INSERT INTO zadanie3.input_points (geom)
VALUES
(ST_SetSRID(ST_MakePoint(8.36093, 49.03174), 4326)),
(ST_SetSRID(ST_MakePoint(8.39876, 49.00644), 4326));


--#5 aktualizacja puntkow do nowego ukaldu wspolrzednych ALTER- modyfikacja
ALTER TABLE zadanie3.input_points
ALTER COLUMN geom TYPE geometry(Point, 3068)
USING ST_Transform(geom, 3068);

SELECT id, ST_AsText(geom)
FROM zadanie3.input_points;

--#6 wszystkie skrzyżowania dróg (t2019_kar_street_node) w odległości 200 m od punktów z tabeli input_points


CREATE TABLE zadanie3.nearby_nodes AS
SELECT DISTINCT n.*
FROM zadanie3.streets_reprojected n
JOIN zadanie3.input_points p
ON ST_DWithin(
	n.geom,
	p.geom,
	200
);
SELECT COUNT(*) AS total_nearby_nodes
FROM zadanie3.nearby_nodes;


--#7 Sklepy sportowe w odległości do 300 m od parków
CREATE TABLE zadanie3.sport_shops_near_parks AS
SELECT COUNT(*) AS total_sport_shops
FROM zadanie3.t2019_kar_poi_table AS poi
JOIN zadanie3.t2019_kar_land_use_a AS park
  ON ST_DWithin(poi.geom, park.geom, 300)
WHERE poi.type = 'Sporting Goods Store';

SELECT * FROM zadanie3.sport_shops_near_parks;

--#8 ST_Intersects Sprawdza, czy geometrie się przecinają — czyli mają wspólny punkt.
--   Znajdź punkty przecięcia torów kolejowych (RAILWAYS) z ciekami (WATER_LINES)
CREATE TABLE zadanie3.t2019_kar_bridges AS
SELECT 
    ST_Intersection(r.geom, w.geom) AS geom --tutaj zliczam
FROM zadanie3.t2019_kar_railways AS r
JOIN zadanie3.t2019_kar_water_lines AS w
  ON ST_Intersects(r.geom, w.geom); -- tutaj filtruje

SELECT COUNT(*) AS total_bridges
FROM zadanie3.t2019_kar_bridges;
