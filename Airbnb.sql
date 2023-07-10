/*

Cleaning Airbnb Data
Skills used: CTEs, aggregate functions, self-joins, string functions

*/
 ---------------------------------------------------------------------------------------------------------------------------

-- Creating table to import data

CREATE TABLE IF NOT EXISTS Airbnb
(
    id VARCHAR,
    name VARCHAR,
    host_id VARCHAR,
    host_identity_verified VARCHAR,
    host_name VARCHAR,
    neighborhood_group VARCHAR,
    neighborhood VARCHAR,
    lat FLOAT,
    long FLOAT,
    country VARCHAR,
    country_code VARCHAR,
    instant_bookable boolean,
    cancellation_policy VARCHAR,
    room_type VARCHAR,
    construction_year INT,
    price VARCHAR,
    service_fee VARCHAR,
    minimum_nights INT,
    number_of_reviews INT,
    last_review DATE,
    reviews_per_month FLOAT,
    review_rate_number INT,
    calculated_host_listings_count INT,
    availability_365 INT,
    house_rules VARCHAR,
    license VARCHAR
)

SELECT *
FROM airbnb;

 ---------------------------------------------------------------------------------------------------------------------------

-- Correct neighborhood_group typos

SELECT DISTINCT neighborhood_group
FROM airbnb;

UPDATE airbnb
SET neighborhood_group = 'Brooklyn'
WHERE neighborhood_group = 'brookln';

UPDATE airbnb
SET neighborhood_group = 'Manhattan'
WHERE neighborhood_group = 'manhatan';

 ---------------------------------------------------------------------------------------------------------------------------

-- Correct out of range values in minimum_nights

SELECT MIN(minimum_nights), MAX(minimum_nights)
FROM airbnb;

UPDATE airbnb
SET minimum_nights = 1
WHERE minimum_nights < 1;

UPDATE airbnb
SET minimum_nights = 90
WHERE minimum_nights > 90;

 ---------------------------------------------------------------------------------------------------------------------------

-- Correct out of range values in availability_365

SELECT MIN(availability_365), MAX(availability_365)
FROM airbnb;

UPDATE airbnb
SET availability_365 = 0
WHERE availability_365 < 0;

UPDATE airbnb
SET availability_365 = 365
WHERE availability_365 > 365;

 ---------------------------------------------------------------------------------------------------------------------------

-- Populate host_identity_verified nulls with 'unconfirmed'

SELECT *
FROM airbnb
WHERE host_identity_verified IS NULL;

UPDATE airbnb
SET host_identity_verified = 'unconfirmed'
WHERE host_identity_verified IS NULL;

 ---------------------------------------------------------------------------------------------------------------------------

-- Populate neighborhood_group nulls

SELECT *
FROM airbnb
WHERE neighborhood_group IS NULL;


SELECT DISTINCT a.id, a.neighborhood_group, a.neighborhood, b.neighborhood_group, b.neighborhood, COALESCE(a.neighborhood_group,b.neighborhood_group)
FROM  airbnb a 
JOIN airbnb b
	ON a.neighborhood = b.neighborhood
	AND a.id <> b.id
WHERE a.neighborhood_group IS NULL AND b.neighborhood_group IS NOT NULL;

UPDATE airbnb
SET neighborhood_group = c.fixed_neighborhood_group
FROM (
	SELECT DISTINCT a.id, a.neighborhood_group, a.neighborhood, 
	b.neighborhood_group, b.neighborhood, COALESCE(a.neighborhood_group,b.neighborhood_group) as fixed_neighborhood_group
	FROM  airbnb a 
	JOIN airbnb b
		ON a.neighborhood = b.neighborhood
		AND a.id <> b.id
	WHERE a.neighborhood_group IS NULL AND b.neighborhood_group IS NOT NULL) c
WHERE airbnb.neighborhood_group IS NULL;

 ---------------------------------------------------------------------------------------------------------------------------

-- Populate neighborhood nulls 

SELECT *
FROM airbnb
WHERE neighborhood IS NULL;

SELECT DISTINCT a.id, b.neighborhood AS fixed_neighborhood
FROM  airbnb a 
JOIN airbnb b
	ON a.neighborhood_group = b.neighborhood_group
	AND a.id <> b.id
WHERE a.neighborhood IS NULL AND b.neighborhood IS NOT NULL
	AND ABS(a.long - b.long) < .0004 AND ABS(a.lat - b.lat) < .00025
GROUP BY a.id, b.neighborhood;

UPDATE airbnb
SET neighborhood = c.fixed_neighborhood
FROM ( 
	SELECT DISTINCT a.id, b.neighborhood AS fixed_neighborhood
	FROM  airbnb a 
	JOIN airbnb b
		ON a.neighborhood_group = b.neighborhood_group
		AND a.id <> b.id
	WHERE a.neighborhood IS NULL AND b.neighborhood IS NOT NULL
		AND ABS(a.long - b.long) < .0004 AND ABS(a.lat - b.lat) < .00025
	GROUP BY a.id, b.neighborhood) c
WHERE airbnb.neighborhood IS NULL;

 ---------------------------------------------------------------------------------------------------------------------------

-- Populate Country nulls

SELECT *
FROM airbnb
WHERE country IS NULL;

UPDATE airbnb
SET country = 'United States'
WHERE country IS NULL;

 ---------------------------------------------------------------------------------------------------------------------------

-- Populate minimum_nights nulls with 1

SELECT *
FROM airbnb
WHERE minimum_nights IS NULL;

UPDATE airbnb
SET minimum_nights = 1
WHERE minimum_nights IS NULL;

 ---------------------------------------------------------------------------------------------------------------------------

-- Populate instant_bookable nulls based on minimum_nights

SELECT *
FROM airbnb
WHERE instant_bookable IS NULL;

UPDATE airbnb
SET instant_bookable = 'false'
WHERE cancellation_policy = 'strict' OR cancellation_policy = 'moderate' AND instant_bookable IS NULL;

UPDATE airbnb
SET instant_bookable = 'true'
WHERE cancellation_policy = 'flexible' AND instant_bookable IS NULL;

 ---------------------------------------------------------------------------------------------------------------------------

-- Populate cancellation_policy nulls

SELECT *
FROM airbnb
WHERE cancellation_policy IS NULL;

UPDATE airbnb
SET cancellation_policy = 'unspecified'
WHERE cancellation_policy IS NULL;

 ---------------------------------------------------------------------------------------------------------------------------

-- Populate construction_year nulls with average construction year

SELECT *
FROM airbnb
WHERE construction_year IS NULL;

UPDATE airbnb
SET construction_year = a.avg_construction_year
FROM (SELECT ROUND(AVG(construction_year), 0) as avg_construction_year
	 FROM airbnb) a
WHERE construction_year IS NULL;

 ---------------------------------------------------------------------------------------------------------------------------

-- Populate price and sevice fee nulls with $0

SELECT *
FROM airbnb
WHERE price IS NULL;

UPDATE airbnb
SET price = '$0'
WHERE price IS NULL;

SELECT *
FROM airbnb
WHERE service_fee IS NULL;

UPDATE airbnb
SET service_fee = '$0'
WHERE service_fee IS NULL;

 ---------------------------------------------------------------------------------------------------------------------------

-- Correct price data type

UPDATE airbnb
SET price = RIGHT(price, LENGTH(price) - 1);

UPDATE airbnb
SET price = REPLACE(price, ',','')::numeric;

ALTER TABLE airbnb
ADD fixed_price INT;

UPDATE airbnb
SET fixed_price = CAST(price AS INT);

ALTER TABLE airbnb
DROP COLUMN price;

ALTER TABLE airbnb
RENAME COLUMN fixed_price TO price;
	
 ---------------------------------------------------------------------------------------------------------------------------

-- Correct service fee data type

UPDATE airbnb
SET service_fee = RIGHT(service_fee, LENGTH(service_fee) - 1);

UPDATE airbnb
SET service_fee = REPLACE(service_fee, ',','')::numeric;

ALTER TABLE airbnb
ADD fixed_service_fee INT;

UPDATE airbnb
SET fixed_service_fee = CAST(service_fee AS INT);

ALTER TABLE airbnb
DROP COLUMN service_fee;

ALTER TABLE airbnb
RENAME COLUMN fixed_service_fee TO service_fee;

 ---------------------------------------------------------------------------------------------------------------------------

-- Populate 0 price with average price

SELECT *
FROM airbnb
WHERE price = 0;

UPDATE airbnb
SET price = a.avg_price
FROM (SELECT ROUND(AVG(price), 0) as avg_price
	 FROM airbnb) a
WHERE price = 0;

 ---------------------------------------------------------------------------------------------------------------------------

-- Populate number_of_reviews nulls

SELECT *
FROM airbnb
WHERE number_of_reviews IS NULL;

UPDATE airbnb
SET number_of_reviews = 0
WHERE number_of_reviews IS NULL AND last_review IS NULL;

UPDATE airbnb
SET number_of_reviews = 1
WHERE number_of_reviews IS NULL AND last_review IS NOT NULL;

 ---------------------------------------------------------------------------------------------------------------------------

-- Populate reviews_per_month nulls with 0

SELECT *
FROM airbnb
WHERE reviews_per_month IS NULL;

UPDATE airbnb
SET reviews_per_month = 0
WHERE number_of_reviews = 0;

 ---------------------------------------------------------------------------------------------------------------------------

-- Populate review_rate_number with average rating

SELECT *
FROM airbnb
WHERE review_rate_number IS NULL;

UPDATE airbnb
SET review_rate_number = a.avg_review_rate
FROM (SELECT ROUND(AVG(review_rate_number), 0) as avg_review_rate
	 FROM airbnb) a
WHERE review_rate_number IS NULL;

 ---------------------------------------------------------------------------------------------------------------------------

-- Populate calculated_host_listings_count nulls with 1

SELECT *
FROM airbnb
WHERE calculated_host_listings_count IS NULL;

UPDATE airbnb
SET calculated_host_listings_count = 1
WHERE calculated_host_listings_count IS NULL;

 ---------------------------------------------------------------------------------------------------------------------------

-- Populate availability_365 nulls

SELECT *
FROM airbnb
WHERE availability_365 IS NULL;

UPDATE airbnb
SET availability_365 = 0
WHERE availability_365 IS NULL;


 ---------------------------------------------------------------------------------------------------------------------------

-- Populate house_rules nulls with unspecified

SELECT *
FROM airbnb
WHERE house_rules IS NULL;

UPDATE airbnb
SET house_rules = 'unspecified'
WHERE house_rules IS NULL;

 ---------------------------------------------------------------------------------------------------------------------------

-- Populate lat and long nulls and combine long and lat columns into coordinates

SELECT *
FROM airbnb
WHERE long IS NULL OR lat IS NULL;

UPDATE airbnb
SET long = a.avg_long
FROM (SELECT AVG(long) as avg_long
	 FROM airbnb) a
WHERE long IS NULL;

UPDATE airbnb
SET lat = (SELECT AVG(lat) as avg_lat
	 FROM airbnb)
WHERE long IS NULL;

ALTER TABLE airbnb
ADD coordinates VARCHAR;

UPDATE airbnb
SET coordinates = CONCAT (lat,', ', long);

 ---------------------------------------------------------------------------------------------------------------------------

-- Delete duplicates (if desired)

SELECT DISTINCT *
FROM airbnb;

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY name,
				host_id, 
				host_name
				ORDER BY
					id
					) row_num
FROM airbnb
)
DELETE
FROM RowNumCTE
WHERE row_num > 1


 ---------------------------------------------------------------------------------------------------------------------------

-- Delete unnecessary columns (if desired)

ALTER TABLE airbnb
DROP COLUMN name, host_name, country_code, license;
