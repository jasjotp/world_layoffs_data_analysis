-- Exploratory Data Analysis
SELECT *
FROM layoffs_staging_2;

-- The percentage of employees laid off = total_laid_off / staff_size so staff_size = total_laid_off / percentage of employees laid off. Find total staff size for each company where total laid off or percentange laid off is not null 
SELECT company,
	  location,
      total_laid_off,
      percentage_laid_off,
	  ROUND(total_laid_off / percentage_laid_off, 0) AS approx_staff_size
FROM layoffs_staging_2;

-- Add the approx_staff_size to the table beside percentage_laid_off
ALTER TABLE layoffs_staging_2
ADD approx_staff_size INT
AFTER total_laid_off;

UPDATE layoffs_staging_2
SET approx_staff_size = ROUND(total_laid_off / percentage_laid_off, 0)
WHERE total_laid_off IS NOT NULL AND total_laid_off != 0
	AND percentage_laid_off IS NOT NULL AND percentage_laid_off != 0; 

SELECT *
FROM layoffs_staging_2
ORDER BY percentage_laid_off DESC, company;

-- Find the top 5 companies with the highest number of lay offs annd their date 
SELECT company,
	   location,
       total_laid_off,
       `date`
FROM layoffs_staging_2
ORDER BY total_laid_off DESC
LIMIT 5;

-- Find companies where they laid off the entire staff (percentage laid off = 1/100%)/ completely went under, ordered by the total amount of staff laid off is descending order 
SELECT company,
	   location,
       industry,
       total_laid_off,
       percentage_laid_off,
       `date`,
       stage,
       country,
       funds_raised_millions
FROM layoffs_staging_2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;


-- Find companies where they laid off the entire staff, ordered by their funds rasied 
SELECT company,
	   location,
       industry,
       total_laid_off,
       percentage_laid_off,
       `date`,
       stage,
       country,
       funds_raised_millions
FROM layoffs_staging_2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- Find the total sum of employees laid off per company 
SELECT company, 
	    SUM(total_laid_off) AS total_layoffs,
        DENSE_RANK() OVER(ORDER BY SUM(total_laid_off) DESC) AS layoffs_rank
FROM layoffs_staging_2
GROUP BY company
ORDER BY layoffs_rank;

-- Check the date ranges 
SELECT MIN(`date`) AS min_date,
	   MAX(`date`) AS max_date
FROM layoffs_staging_2;

-- Find the top 5 industries that laid off employees
WITH industry_layoffs AS (
	SELECT 
			DENSE_RANK() OVER (ORDER BY SUM(total_laid_off) DESC) AS layoffs_rank,
			industry,
			SUM(total_laid_off) AS total_layoffs
	FROM layoffs_staging_2
	GROUP BY industry 
)

SELECT *
FROM industry_layoffs 
WHERE layoffs_rank BETWEEN 1 AND 5
ORDER BY layoffs_rank;

-- Get a running sum of all layoffs for each industry 
SELECT 
    DENSE_RANK() OVER (ORDER BY total_laid_off DESC) AS layoffs_rank,
    industry,
    total_laid_off,
    SUM(total_laid_off) OVER (PARTITION BY industry ORDER BY `date`) AS total_company_layoffs,
    `date`
FROM layoffs_staging_2
ORDER BY industry, `date`;

-- Rank each coutnry by total layoffs in descending order 
WITH country_totals AS (
  SELECT 
    country,
    SUM(total_laid_off) AS total_laid_off
  FROM layoffs_staging_2
  GROUP BY country
)

SELECT 
	  DENSE_RANK() OVER (ORDER BY total_laid_off DESC) AS country_rank,
	  country,
	  total_laid_off
FROM country_totals
ORDER BY country_rank;

-- Ramk the dates by highest layoff volume 
WITH date_totals AS (
	SELECT 
			`date` AS dt, 
            SUM(total_laid_off) AS total_laid_off
	FROM layoffs_staging_2
    GROUP BY dt
)

SELECT 
		DENSE_RANK() OVER(ORDER BY total_laid_off DESC) AS date_rank, 
        dt,
        total_laid_off
FROM date_totals
ORDER BY date_rank;

-- Rank the year and months with the highest number of layoffs 
-- Months 
WITH monthly_totals AS (
	SELECT MONTHNAME(`date`) AS dt_month,
    SUM(total_laid_off) AS total_laid_off
	FROM layoffs_staging_2
    GROUP BY dt_month
)

SELECT 
		DENSE_RANK() OVER(ORDER BY total_laid_off DESC) AS date_rank,
		dt_month,
        total_laid_off
FROM monthly_totals 
ORDER BY date_rank;

-- Months 
WITH yearly_totals AS (
	SELECT YEAR(`date`) AS dt_year,
    SUM(total_laid_off) AS total_laid_off
	FROM layoffs_staging_2
    GROUP BY dt_year
)

SELECT 
		DENSE_RANK() OVER(ORDER BY total_laid_off DESC) AS date_rank,
		dt_year,
        total_laid_off
FROM yearly_totals 
ORDER BY date_rank;

-- Rank the stages with the highest number of layoffs (We see that Post IPO companies had the most layoffs)
WITH stage_totals AS (
	SELECT stage,
		   SUM(total_laid_off) AS total_laid_off
	FROM layoffs_staging_2
    GROUP BY stage
)

SELECT 
		DENSE_RANK() OVER(ORDER BY total_laid_off DESC) AS stage_rank,
        stage,
        total_laid_off
FROM stage_totals
ORDER BY stage_rank;
		
-- Calculate rolling totals of layoffs based off of the month and year 
WITH date_month_totals AS (
	SELECT 	
			DATE_FORMAT(`date`, '%Y-%m-01') AS start_day_month, -- For sorting 
			DATE_FORMAT(`date`, '%M-%Y') AS month_year, 
            SUM(total_laid_off) AS monthly_total_laid_off
	FROM layoffs_staging_2
    WHERE DATE_FORMAT(`date`, '%M-%Y') IS NOT NULL
    GROUP BY start_day_month, month_year
)

SELECT 
	   month_year,
       monthly_total_laid_off,
       SUM(monthly_total_laid_off) OVER(ORDER BY start_day_month) AS running_layoff_total
FROM date_month_totals
ORDER BY start_day_month;

-- Find the running totals of layoffs per company
WITH company_layoff_totals AS (
	SELECT 
		company, 
		`date`,
		SUM(total_laid_off) AS total_layoffs
	FROM layoffs_staging_2
	GROUP BY company, `date`
)

SELECT company, 
	   `date`, 
       total_layoffs,
	   SUM(total_layoffs) OVER(PARTITION BY company ORDER BY `date`) AS running_total_layoffs
FROM company_layoff_totals
ORDER BY company;

-- Find the companies who laid off the most employees, ranked by year 
WITH layoffs_per_year AS (
	SELECT 
	    company,
		YEAR(`date`) AS years,
        SUM(total_laid_off) AS total_laid_off
	FROM layoffs_staging_2
	GROUP BY company, YEAR(`date`)
), 
company_year_rankings AS (
	SELECT *,
		   DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS layoff_amount_rank
	FROM layoffs_per_year
	WHERE years IS NOT NULL  
	ORDER BY layoff_amount_rank
)

SELECT *
FROM company_year_rankings
WHERE layoff_amount_rank <= 5;

-- Find the companies who had layoffs for at least 3 consecutive months
WITH monthly_layoffs AS (
  SELECT 
    company,
    DATE_FORMAT(`date`, '%Y-%m') AS yr_month,
    MIN(DATE_FORMAT(`date`, '%Y-%m-01')) AS month_start, 
    COUNT(*) AS layoff_events
  FROM layoffs_staging_2
  WHERE total_laid_off IS NOT NULL
  GROUP BY company, yr_month
),
ranked_months AS (
  SELECT *,
    ROW_NUMBER() OVER(PARTITION BY company ORDER BY month_start) AS rn
  FROM monthly_layoffs
),
consecutive_sequences AS (
  SELECT company, month_start,
         DATE_SUB(month_start, INTERVAL rn MONTH) AS grp
  FROM ranked_months
)
SELECT company, COUNT(*) AS consecutive_months
FROM consecutive_sequences
GROUP BY company, grp
HAVING COUNT(*) >= 3
ORDER BY consecutive_months DESC;

-- Find the companies who laid off the most workers per $million raised
SELECT 
  company,
  SUM(total_laid_off) AS total_layoffs,
  MAX(funds_raised_millions) AS total_funding,
  ROUND(SUM(total_laid_off) / NULLIF(MAX(funds_raised_millions), 0), 2) AS layoffs_per_million
FROM layoffs_staging_2
GROUP BY company
HAVING total_funding IS NOT NULL
ORDER BY layoffs_per_million DESC
LIMIT 10;

-- Find the companies with the highest risk, based off their stage (early vs IPO), layoffs, and funding
SELECT 
  company,
  MAX(stage) AS stage,
  SUM(total_laid_off) AS total_layoffs,
  MAX(funds_raised_millions) AS funds_raised,
  ROUND(SUM(total_laid_off) / NULLIF(MAX(funds_raised_millions), 0), 2) AS layoffs_per_million,
  CASE 
    WHEN MAX(stage) LIKE '%Seed%' OR MAX(stage) LIKE '%Early%' THEN 2
    WHEN MAX(stage) LIKE '%IPO%' THEN 0
    ELSE 1
  END AS stage_risk,
  CASE 
    WHEN ROUND(SUM(total_laid_off) / NULLIF(MAX(funds_raised_millions), 0), 2) > 5 THEN 2
    ELSE 0
  END AS funding_risk
FROM layoffs_staging_2
GROUP BY company
HAVING funds_raised IS NOT NULL
ORDER BY (stage_risk + funding_risk + (total_layoffs > 500)) DESC
LIMIT 10;



