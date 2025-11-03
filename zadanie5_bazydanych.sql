CREATE EXTENSION postgis;

CREATE TABLE obiekty (
  id SERIAL PRIMARY KEY,
  nazwa TEXT,
  geom GEOMETRY
);



INSERT INTO obiekty (nazwa, geom) VALUES
('obiekt1',
 ST_GeomFromText(
   'COMPOUNDCURVE(
      (0 1, 1 1),
      CIRCULARSTRING(1 1, 2 0, 3 1),  
      CIRCULARSTRING(3 1, 4 2, 5 1),
      (5 1, 6 1)
   )'
 )-- tworzy polkola circularsting
);

INSERT INTO obiekty (nazwa, geom)
VALUES (
  'obiekt2',
  ST_Difference(
    ST_GeomFromText('POLYGON((10 6, 14 6, 16 4, 14 2, 12 0, 10 2, 10 6))'),
    ST_Buffer(ST_Point(12, 2), 1)
  ) -- jedynym sposobem jest wycięcie otowru w poligonie za pomocą ST_Difference
);

--c
INSERT INTO obiekty (nazwa, geom) VALUES
('obiekt3',
 ST_GeomFromText('POLYGON((7 15, 10 17, 12 13, 7 15))')
);

--d LINESTRING poniewaz to lina a nie domnkniety poligon
INSERT INTO obiekty (nazwa, geom) VALUES
('obiekt4',
 ST_GeomFromText('LINESTRING(20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5)')
);

--e
INSERT INTO obiekty (nazwa, geom)
VALUES (
  'obiekt5',
  ST_GeomFromText('MULTIPOINT Z ((38 32 234), (30 30 59))')
);


--f laczy w jeden obiekt GEOMETRYCOLLECTION
INSERT INTO obiekty (nazwa, geom) 
VALUES (
  'obiekt6',
  ST_GeomFromText(
    'GEOMETRYCOLLECTION(           
        LINESTRING(1 1, 3 2),     
        POINT(4 2)
    )'
  )
)

-- Zadanie 2
SELECT 
    ST_Area(
       ST_Buffer(
		  	ST_ShortestLine(a.geom,b.geom),
			  5
	   )
     ) AS  pole_bufora
FROM obiekty a , obiekty b
WHERE a.nazwa = 'obiekt3' AND b.nazwa = 'obiekt4';

-- Zadanie3

UPDATE obiekty
SET geom = ST_MakePolygon(ST_AddPoint(geom,ST_StartPoint(geom)))
WHERE nazwa = 'obiekt4';

-- Zadanie 4 ST_Union - laczy dwie geometrie

INSERT INTO obiekty (nazwa,geom)
SELECT 
	'obiekt7',
	ST_Union(a.geom,b.geom)
FROM obiekty a, obiekty b
WHERE a.nazwa = 'obiekt3' AND b.nazwa = 'obiekt4';

-- Zadanie 5 ST_HasArc(geom) = false sprawdza ktore obiekty nie maja luków
SELECT 
	nazwa,
	ST_Area(ST_Buffer(geom,5)) AS pole_bufora
FROM obiekty
WHERE ST_HasArc(geom) = false;










