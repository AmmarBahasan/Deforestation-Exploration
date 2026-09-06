CREATE VIEW forestation AS(
 SELECT f.country_code,
    f.country_name,
    f.year,
    f.forest_area_sqkm,
    l.total_area_sq_mi * 2.59::double precision AS land_area_sqkm,
    r.region,
    r.income_group,
    f.forest_area_sqkm / (l.total_area_sq_mi * 2.59::double precision) * 100::double precision AS forest_area
   FROM forest_area f
     JOIN land_area l ON f.country_code::text = l.country_code::text AND f.year = l.year
     JOIN regions r ON f.country_code::text = r.country_code::text
  ORDER BY f.country_code, f.year)
/*
Part 1 - Global Situation
*/


/*
a. What was the total forest area (in sq km) of the world in 1990? 
   Please keep in mind that you can use the country record denoted as “World" in the region table.
*/
SELECT ROUND(forest_area_sqkm) AS forest_sqkm_1990
FROM forestation
WHERE region ='World'
AND year = 1990;
-- 41,282,695


/*
b. What was the total forest area (in sq km) of the world in 2016?
   Please keep in mind that you can use the country record in the table is denoted as “World.”
*/
SELECT ROUND(forest_area_sqkm) AS forest_sqkm_1990
FROM forestation
WHERE region ='World'
AND year = 2016;
-- 39,958,246


/*
c. What was the change (in sq km) in the forest area of the world from 1990 to 2016?
*/

SELECT (ROUND(a.forest_area_sqkm) - ROUND(b.forest_area_sqkm)) AS diffrence
FROM forestation a
JOIN forestation b
ON a.region = b.region
WHERE a.region = 'World'
AND a.year = 1990
AND b.year=2016
 -- 1,324,449

/*
d. What was the percent change in forest area of the world between 1990 and 2016?
*/
WITH cte90 AS(
	SELECT ROUND(forest_area_sqkm) AS forest_area_sqkm_90
	FROM forestation
	WHERE region='World'
	AND year = 1990
),
cte16 AS (
SELECT ROUND(forest_area_sqkm) AS forest_area_sqkm_16
	FROM forestation
	WHERE region='World'
	AND year = 2016
)

SELECT 
ROUND(CAST(
(
(cte16.forest_area_sqkm_16 - cte90.forest_area_sqkm_90) / cte90.forest_area_sqkm_90
)*100 AS NUMERIC),2) || '%' AS forest_area_change
FROM cte90,cte16;
-- -3.21%


/*
e. If you compare the amount of forest area lost between 1990 and 2016, 
   to which country's total area in 2016 is it closest to?
*/
SELECT DISTINCT country_name,
	   ROUND(land_area_sqkm) AS land_area_sqkm
FROM forestation
WHERE land_area_sqkm <=(
	WITH cte90 AS(
		SELECT forest_area_sqkm
		FROM forestation 
		WHERE year = 1990
		AND country_name ='World'
	),
	cte16 AS(
		SELECT forest_area_sqkm 
		FROM forestation 
		WHERE year = 2016
		AND country_name = 'World'
	)
	SELECT (cte90.forest_area_sqkm - cte16.forest_area_sqkm) AS forest_area_change
	FROM cte90,cte16
	)
	ORDER BY land_area_sqkm desc
	LIMIT 1;
-- 1280000

-----------------------------------------------------------------------------------------
/*
Part 2 - Regional Outlook
*/

/*
Create a table that shows the Regions and their percent forest area 
(sum of forest area divided by the sum of land area) in 1990 and 2016. 
(Note that 1 sq mi = 2.59 sq km).
*/
CREATE VIEW  forest_to_land as(
SELECT region, 
	   year,
	   (sum(forest_area_sqkm) / sum(land_area_sqkm)*100) forest_to_land_percent
FROM forestation
--WHERE YEAR IN (2016,1990)
GROUP BY region,year
ORDER BY year,forest_to_land_percent desc);


/*
a. What was the percent forest of the entire world in 2016? 
Which region had the HIGHEST percent forest in 2016, and which had the LOWEST, to 2 decimal places?
*/
SELECT region , ROUND(CAST(forest_to_land_percent AS NUMERIC),2)
FROM forest_to_land
where year= 2016;

/*
b. What was the percent forest of the entire world in 1990? 
   Which region had the HIGHEST percent forest in 1990, and which had the LOWEST, to 2 decimal places?
*/
SELECT region , ROUND(CAST(forest_to_land_percent AS NUMERIC),2)
FROM forest_to_land
where year= 1990;

/*
c. Based on the table you created, which regions of the world DECREASED in forest area from 1990 to 2016?
*/
WITH t90 AS(
SELECT sub.*,
	   (sub.forest_area / sub.land_area) * 100 AS forest_percentage
FROM
		(SELECT region,
	   		ROUND(CAST(SUM(forest_area_sqkm) AS NUMERIC),2) AS forest_area,
	   		ROUND(CAST(SUM(land_area_sqkm) AS NUMERIC),2) AS land_area,
	   		year
		 FROM forestation
		 GROUP BY region, year
		 HAVING year =1990
) as sub
ORDER BY forest_percentage
) ,
t16 AS(
SELECT sub.*,
	   (sub.forest_area / sub.land_area) * 100 AS forest_percentage
FROM
		(SELECT region,
	   		ROUND(CAST(SUM(forest_area_sqkm) AS NUMERIC),2) AS forest_area,
	   		ROUND(CAST(SUM(land_area_sqkm) AS NUMERIC),2) AS land_area,
	   		year
		 FROM forestation
		 GROUP BY region, year
		 HAVING year =2016
) as sub
ORDER BY forest_percentage
)

SELECT t90.region,
	   ROUND((t16.forest_percentage - t90.forest_percentage),2) AS change_percentage
FROM t90
JOIN t16
ON t90.region = t16.region 
AND t90.forest_area > t16.forest_area
ORDER BY change_percentage;

-----------------------------------------------------------------------------------------
/*
Part 3 - Country-Level Detail
*/

/*
a. Which 5 countries saw the largest amount decrease in forest area from 1990 to 2016? What was the difference in forest area for each?
*/
WITH t90 AS(
	SELECT country_name,
		   CAST(forest_area_sqkm AS NUMERIC) AS forest90,
		   forest_area AS forest_area90,
		   region	   
	FROM forestation
	WHERE year =1990
	AND country_name <> 'World'

) , 
 t16 AS(
	SELECT country_name,
		   CAST(forest_area_sqkm AS NUMERIC) AS forest16,
		   forest_area AS forest_area16,
		   region
	FROM forestation
	WHERE year =2016
	AND country_name <> 'World'
	

)
SELECT t90.country_name,
	   t90.region,
	   ROUND(CAST(t90.forest90 AS NUMERIC),2) AS forest_sqkm90,
	   ROUND(CAST(t16.forest16 AS NUMERIC),2) AS forest_sqkm16,
	   ROUND(COALESCE((t16.forest16 / t90.forest90)*100,0),2) AS diffrence_Percentage,
	   COALESCE((t16.forest16 - t90.forest90),0) AS diffrence_km

FROM t90 
JOIN t16 
ON t90.country_name = t16.country_name
ORDER BY diffrence_km 
LIMIT 5;

/*
b. Which 5 countries saw the largest percent decrease in forest area from 1990 to 2016? What was the percent change to 2 decimal places for each?
*/
WITH t90 AS(
	SELECT country_name,
		   CAST(forest_area_sqkm AS NUMERIC) AS forest90,
		   forest_area AS forest_area90,
		   region	   
	FROM forestation
	WHERE year =1990
	AND country_name <> 'World'
) , 
 t16 AS(
	SELECT country_name,
		   CAST(forest_area_sqkm AS NUMERIC) AS forest16,
		   forest_area AS forest_area16,
		   region
	FROM forestation
	WHERE year =2016
	AND country_name <> 'World'
)
SELECT t90.country_name,
	   t90.region,
	   ROUND(CAST(t90.forest90 AS NUMERIC),2) AS forest_sqkm90,
	   ROUND(CAST(t16.forest16 AS NUMERIC),2) AS forest_sqkm16,
	   ROUND(COALESCE(((t16.forest16 - t90.forest90)/t90.forest90)*100,0),2) AS diffrence_Percentage
	   --COALESCE((t16.forest16 - t90.forest90),0) AS diffrence_km

FROM t90 
JOIN t16 
ON t90.country_name = t16.country_name
ORDER BY diffrence_Percentage
LIMIT 5;

/*
c. If countries were grouped by percent forestation in quartiles, which group had the most countries in it in 2016?
*/

WITH sub AS(
	SELECT country_name,
	CASE 
		WHEN forest_area	 < 25 THEN '0-25%'
		WHEN forest_area >= 25 
			AND 
			 forest_area < 50
		THEN '25-50%'
		WHEN forest_area >= 50
			AND
			 forest_area < 75 
		THEN '50-75%'
		ELSE '75-100%' 
		END AS quartiles
	FROM forestation
	WHERE year = 2016
		 AND
		  forest_area IS NOT NULL
)
SELECT  DISTINCT quartiles,
	   COUNT(country_name) OVER (PARTITION BY quartiles) AS number_of_countries
FROM sub
ORDER BY quartiles ;

/*
d. List all of the countries that were in the 4th quartile (percent forest > 75%) in 2016.
*/
WITH sub AS(
	SELECT country_name,region,forest_area,
	CASE 
		WHEN forest_area	 < 25 THEN '0-25%'
		WHEN forest_area >= 25 
			AND 
			 forest_area < 50
		THEN '25-50%'
		WHEN forest_area >= 50
			AND
			 forest_area < 75 
		THEN '50-75%'
		ELSE '75-100%' 
		END AS quartiles
	FROM forestation
	WHERE year = 2016
		 AND
		  forest_area IS NOT NULL
)
SELECT country_name,
	   region,
       ROUND(CAST(forest_area AS NUMERIC),2) AS percentage,
	   quartiles
FROM sub
WHERE quartiles = '75-100%';

/*
e. How many countries had a percent forestation higher than the United States in 2016?
*/
SELECT COUNT(*)
FROM (
	select DISTINCT country_name 
	FROM forestation
	WHERE forest_area >(
			SELECT forest_area 
			FROM forestation
			WHERE country_name ='United States'
			AND year =2016
	)
) AS sub	
