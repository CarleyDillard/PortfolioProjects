/*
Sephora Products Data Exploration 

Skills used: JOIN, Case Statement, CTE's, Subqueries, Aggregate Functions, Creating Views

*/
--important note: only reviews 750 - 1000, and 1500 to end would import


--Creating products table to import the products csv file
CREATE TABLE  IF NOT EXISTS products 
(
	product_id VARCHAR PRIMARY KEY,
	product_name VARCHAR,
	brand_id INT,
	brand_name VARCHAR,
	loves_count INT,
	rating FLOAT,
	reviews INT,
	size VARCHAR,
	variation_type VARCHAR,
	variation_value VARCHAR,
	variation_desc VARCHAR,
	ingredients VARCHAR,
	price_usd FLOAT,
	value_price_usd FLOAT,
	sale_price_usd FLOAT,
	limited_edition INT,
	new INT,
	online_only INT,
	out_of_stock INT,
	sephora_exclusive INT,
	highlights VARCHAR,
	primary_category VARCHAR,
	secondary_category VARCHAR,
	tertiary_category VARCHAR,
	child_count INT,
	child_max_price FLOAT,
	child_min_price FLOAT
);

--Creating reviews table
CREATE TABLE  IF NOT EXISTS reviews
(rating_id INT,
 author_id VARCHAR,
 rating INT,
 is_recommended FLOAT,
 helpfulness FLOAT,
 total_feedback_count INT,
 total_neg_feedback_count INT,
 total_pos_feedback_count INT,
 submission_time DATE,
 review_text VARCHAR,
 review_title VARCHAR,
 skin_tone VARCHAR,
 eye_color VARCHAR,
 skin_type VARCHAR,
 hair_color VARCHAR,
 product_id VARCHAR,
 product_name VARCHAR,
 brand_name VARCHAR,
 price_usd FLOAT
 )

--Previewing the data
SELECT *
FROM products
LIMIT 100;

SELECT *
FROM reviews;

--Ranking products by average rating
SELECT product_name, brand_name, rating, reviews
FROM products
WHERE rating is not null
ORDER BY rating desc;

--Important to note that high ratings doesn't necessarily equate to popularity or quality.
--It's common for products with a small amount of reviews to have high ratings.
--So this may not be the best method for determing which products cusomers like the most.

--To determine popularity of a product, we will include loves and reviews
--Ranking products by populariy
SELECT product_name, brand_name, (loves_count + reviews) AS popularity
FROM products
WHERE reviews is not null
ORDER BY popularity desc;

--This is likely a better indication of product performance than rating
--Important note: users can 'love' a product without purchasing it, so adding reviews is helpful

--Considering potential trends for top 25 most popular products
SELECT product_name, brand_name,(loves_count + reviews) AS popularity, rating, price_usd, primary_category, secondary_category, tertiary_category
FROM products
WHERE reviews is not null
ORDER BY popularity desc
LIMIT 25;

--Seeing how sephora exclusivity affects avg product popularity
SELECT AVG(loves_count + reviews) AS avg_popularity,
CASE sephora_exclusive
	WHEN 0 THEN 'not exclusive'
	ELSE 'sephora exclusive'
END as exclusivity
FROM products
GROUP BY exclusivity
--on average, sephora exclusive products have more popularity than non-exclusive products





--Ranking primary product categories
--creating CTE with total loves and reviews by primary category
WITH primary_categories AS (
SELECT primary_category, SUM(loves_count) AS total_loves, SUM(reviews) AS total_reviews
FROM products
GROUP BY primary_category)
--Using totals from cte to calculate popularity for each primary category
SELECT primary_category, (total_loves + total_reviews) AS popularity
FROM primary_categories
ORDER BY popularity desc;
--Makeup and skincare are top performing categories, whereas men and gifts are the worst performing

--Ranking tertiary product categories
--creating CTE with total loves and reviews by tertiary category
WITH tertiary_categories AS (
SELECT tertiary_category, SUM(loves_count) AS total_loves, SUM(reviews) AS total_reviews
FROM products
GROUP BY tertiary_category)
--Using totals from cte to calculate popularity for each secondary category
SELECT tertiary_category, (total_loves + total_reviews) AS popularity
FROM tertiary_categories
WHERE tertiary_category is not null
ORDER BY popularity desc;
--Face serums, foundation, and lipstick are most popular products, whereas manicure tools and shampoo and conditioner are at the bottom

--Price distribution for primary product categories
SELECT primary_category, AVG(price_usd) AS avg_price, MIN(price_usd) AS min_price, MAX(price_usd) AS max_price
FROM products
GROUP BY primary_category
ORDER BY avg_price desc

--Ranking brands by popularity and calculating average product price
SELECT brand_name, SUM(loves_count + reviews) AS total_popularity, AVG(price_usd) AS avg_price
FROM products
WHERE reviews is not null
GROUP BY brand_name
ORDER BY total_popularity desc;

--Finding the brand with the highest average product price
SELECT brand_name, avg_price
FROM (
	SELECT brand_name, AVG(price_usd) AS avg_price
	FROM products
	GROUP BY brand_name) x
WHERE avg_price = (SELECT max(avg_price)
				   FROM (
				   	SELECT brand_name, AVG(price_usd) AS avg_price
					FROM products
					GROUP BY brand_name)y)
--the brand with the highest average product price is iluminage, with the average price at 449
--Finding the brand with the lowest average product price
SELECT brand_name, avg_price
FROM (
	SELECT brand_name, AVG(price_usd) AS avg_price
	FROM products
	GROUP BY brand_name) x
WHERE avg_price = (SELECT min(avg_price)
				   FROM (
				   	SELECT brand_name, AVG(price_usd) AS avg_price
					FROM products
					GROUP BY brand_name)y)
--rosebud perfume co, average price of 7.5

--Finding avg ratings for skin care products by skin type
SELECT r.product_name,r.skin_type, AVG(r.rating) AS avg_rating
FROM reviews r
JOIN products p
ON p.product_id = r.product_id
GROUP BY r.product_name, r.skin_type, p.primary_category
HAVING r.skin_type is not null AND primary_category = 'Skincare'
ORDER BY r.product_name, r.skin_type, p.primary_category
;


--Creating views to store data for later use for visualizations
CREATE VIEW ProductsRankedByPopularity AS
SELECT product_name, brand_name, (loves_count + reviews) AS popularity
FROM products
WHERE reviews is not null
ORDER BY popularity desc;

CREATE VIEW PrimaryCategoriesRankedByPopularity AS
WITH primary_categories AS 
(
SELECT primary_category, SUM(loves_count) AS total_loves, SUM(reviews) AS total_reviews
FROM products
GROUP BY primary_category
)
SELECT primary_category, (total_loves + total_reviews) AS popularity
FROM primary_categories
ORDER BY popularity desc;

CREATE VIEW TertiaryCategoriesRankedByPopularity
WITH tertiary_categories AS 
(
SELECT tertiary_category, SUM(loves_count) AS total_loves, SUM(reviews) AS total_reviews
FROM products
GROUP BY tertiary_category
)
SELECT tertiary_category, (total_loves + total_reviews) AS popularity
FROM tertiary_categories
WHERE tertiary_category is not null
ORDER BY popularity desc;

CREATE VIEW PrimaryCategoriesPriceDistribution AS
SELECT primary_category, AVG(price_usd) AS avg_price, MIN(price_usd) AS min_price, MAX(price_usd) AS max_price
FROM products
GROUP BY primary_category
ORDER BY avg_price desc

CREATE VIEW BrandsRankedByPopularity AS
SELECT brand_name, SUM(loves_count + reviews) AS total_popularity, AVG(price_usd) AS avg_price
FROM products
WHERE reviews is not null
GROUP BY brand_name
ORDER BY total_popularity desc
LIMIT 10;

CREATE VIEW SkinTypeSkincareRatings
SELECT  p.primary_category,r.product_name,r.skin_type, AVG(r.rating) AS avg_rating
FROM reviews r
JOIN products p
ON p.product_id = r.product_id
GROUP BY r.product_name, r.skin_type, p.primary_category
HAVING r.skin_type is not null AND primary_category = 'Skincare'
ORDER BY r.product_name, r.skin_type, p.primary_category
;