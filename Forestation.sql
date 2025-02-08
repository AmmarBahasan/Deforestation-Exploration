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
WITH cte90 AS(
	SELECT ROUND(forest_area_sqkm) AS forest_area_sqkm_90
	FROM forestation
	WHERE region='World'
	AND year = 1990
),
 cte16 AS(
	SELECT ROUND(forest_area_sqkm) AS forest_area_sqkm_16
	FROM forestation
	WHERE region='World'
	AND year = 2016
)
SELECT (cte90.forest_area_sqkm_90 - cte16.forest_area_sqkm_16) diffrence
FROM cte90,cte16;
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
WHERE land_area_sqkm >=(
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
	ORDER BY land_area_sqkm
	LIMIT 1;
-- 1553560



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
