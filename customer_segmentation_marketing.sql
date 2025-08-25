use mini_project_erd;

# Q1. Which high-income customers show low spending scores, indicating untapped revenue potential?

SELECT avg(income), min(income), max(income) FROM customer_segmentation; #check min and max

SELECT avg(income) FROM customer_segmentation; #check avg income

-- spending score range



-- Do a frequency table to find out how many values per category 
CREATE VIEW spending AS
SELECT
	CASE          
     WHEN spending_score <= 25 THEN 'low'         
     WHEN spending_score <= 50 THEN 'mid-low'         
     WHEN spending_score <= 75 THEN 'mid-high'         
     ELSE 'high'     # this CASE is to create conditional logic like if/then/else
	END AS spending_category,     
    COUNT(*) AS customer_count 
FROM customer_segmentation
GROUP BY spending_category 
ORDER BY spending_category;

select *
from spending;
-- Create CTE for top 25 percentile for income

WITH cte AS(
	SELECT 
		id, 
		income, 
		NTILE(4) OVER (ORDER BY income) as income_quartile #NTILE(4) is dividing the info into 4 buckets
    FROM customer_segmentation
)
SELECT *
FROM cte
WHERE income_quartile = 4 # I am picking here which bucket to select
ORDER BY income DESC;

-- Stored procedure for getting quartiles of spending scores

DELIMITER $$

CREATE PROCEDURE GetQuartile(
    IN quartile INT
)
BEGIN
    SELECT *
    FROM (
        SELECT 
            id, 
            spending_score,
            NTILE(4) OVER (ORDER BY spending_score) AS spending_quartile
        FROM customer_segmentation
    ) AS cte
    WHERE spending_quartile = quartile
    ORDER BY spending_score DESC;
END$$

DELIMITER ;

CALL GetQuartile(1);

-- Create CTE for bottom 25 percentile for spending score

WITH cte AS(
	SELECT 
		id, 
		spending_score, 
		NTILE(4) OVER (ORDER BY spending_score) as spending_quartile #NTILE(4) is dividing the info into 4 buckets
    FROM customer_segmentation
)
SELECT *
FROM cte
WHERE spending_quartile = 1 # I am picking here which bucket to select
ORDER BY spending_score DESC;

-- Create a query to answer question

WITH cte AS(
	SELECT 
		id, 
		income, 
		NTILE(4) OVER (ORDER BY income) as income_quartile,
        NTILE(4) OVER (ORDER BY spending_score DESC) as spending_quartile  #NTILE(4) is dividing the info into 4 buckets
    FROM customer_segmentation
)
SELECT id, customer_segmentation.income, spending_score
FROM cte
JOIN customer_segmentation
USING (id)
WHERE income_quartile = 4 & spending_quartile = 1
ORDER BY id;

#Q3. Which product categories are most popular across different age groups and genders?

-- min age, max age and avg age.

select avg(age), min(age), max(age) from customer_segmentation;

-- explore gender

SELECT gender, COUNT(id) as customer_count
FROM customer_segmentation
GROUP BY gender;

-- cte to get age quartiles (not necessary)
WITH cte AS(
	SELECT 
		id, 
		age, 
		NTILE(4) OVER (ORDER BY age DESC) as age_quartile
	FROM customer_segmentation
)
SELECT age, age_quartile
FROM cte
GROUP BY age
HAVING age_quartile = 1;

-- Frequency table for different categories

SELECT preferred_category, COUNT(preferred_category)
FROM customer_segmentation
GROUP BY preferred_category;

select age from customer_segmentation;

-- Calculate the customer count across categories, segmented by age group.

WITH cte AS(
SELECT preferred_category,
	CASE          
     WHEN age <= 29 THEN 'young adults'         
     WHEN age <= 41 THEN 'adults'         
     WHEN age <= 55 THEN 'middle-aged adults'         
     ELSE 'seniors'    
	END AS age_categories,     
    COUNT(*) AS customer_count 
FROM customer_segmentation
GROUP BY preferred_category, age_categories
ORDER BY age_categories DESC)
select preferred_category, age_categories, customer_count,
	DENSE_RANK() OVER (PARTITION BY age_categories ORDER BY customer_count DESC) as top_categories
from cte;

-- Create a CTE to determine the customer rank within customer count categories, segmented by gender.
WITH cte AS(
SELECT gender, preferred_category, count(preferred_category) as customer_count_per_category
FROM customer_segmentation
GROUP BY gender, preferred_category
ORDER BY gender
)
SELECT gender, preferred_category, customer_count_per_category,
	DENSE_RANK() OVER (PARTITION BY gender ORDER BY customer_count_per_category DESC) as top_categories
FROM cte;

# Q4. Who are the most loyal customers (high purchase_frequency + high spending_score + long membership)?

-- Check purchase frequency ranges

select avg(purchase_frequency), min(purchase_frequency), max(purchase_frequency)
from customer_segmentation;

-- Check membership years ranges


select avg(membership_years), min(membership_years), max(membership_years)
from customer_segmentation;

-- answer
SELECT id,
	CASE          
     WHEN spending_score <= 25 THEN 'low'         
     WHEN spending_score <= 50 THEN 'mid-low'         
     WHEN spending_score <= 75 THEN 'mid-high'         
     ELSE 'high'    
	END AS spending_category, purchase_frequency, membership_years, spending_score
FROM customer_segmentation
WHERE purchase_frequency > 40 AND membership_years > 3 AND spending_score > 75
GROUP BY id, spending_category, purchase_frequency,membership_years, spending_score
ORDER BY spending_category;

-- Stored pro