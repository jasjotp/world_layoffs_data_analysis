-- Data Cleaning Project 
CREATE DATABASE world_layoffs;

USE world_layoffs; 

SELECT *
FROM layoffs;

-- Create a staging table to make changes on, so we still have the raw data aviable - we work on a staging table in the real word so we don't affect the original table 
CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging 
SELECT *
FROM layoffs;

-- 1. Remove duplicates 

-- Identify duplucates - Since we partition by most of the columns that identifiy a unique entry, all row_nums should be 1 - if any are > 1, they are duplciates
WITH duplicate_rows AS (
	SELECT *,
	   COUNT(*) OVER (
						PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS duplicate_count,
	   ROW_NUMBER() OVER(
						PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
	FROM layoffs_staging
)

SELECT *
FROM duplicate_rows dr
WHERE duplicate_count > 1;

-- Cretea another staging table so that you can remove the duplcates
CREATE TABLE `layoffs_staging_2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `duplicate_count` int,
  `row_num` int
  
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM layoffs_staging_2;

-- Insert the above CTEs data into the second layoff staging stable
INSERT layoffs_staging_2
SELECT *,
COUNT(*) OVER (
				PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS duplicate_count,
ROW_NUMBER() OVER(
				  PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Delete the duplicates from the staging table (where row_num is greater than 1, as that signifies duplicates)
DELETE
FROM layoffs_staging_2
WHERE row_num > 1;

-- Check that no rows return a row number greater than 1 (meaning they were deleted successfully)
SELECT *
FROM layoffs_staging_2
WHERE row_num > 1;

-- 2. Standardize the data ex) Fix spelling mistakes 

SELECT company, TRIM(company)
FROM layoffs_staging_2;

-- Fix the company names so there are no whitespaces before or after each company name 
UPDATE layoffs_staging_2
SET company = TRIM(company);

-- Check if company names were trimmed 
SELECT company, TRIM(company)
FROM layoffs_staging_2;

-- Fix the company industries so there are no whitespaces before or after each company name 
SELECT DISTINCT industry
FROM layoffs_staging_2
ORDER BY industry;

-- Crpyto industry has a few duplicates with different names 
SELECT DISTINCT industry
FROM layoffs_staging_2 
WHERE industry LIKE '%Crypto%';

-- Update the inuudstries Crypto, Crpyotcurrency, and Crypto Currency to all be the Crpyto industry 
UPDATE layoffs_staging_2 
SET industry = 'Crypto'
WHERE industry LIKE '%Crypto%';

-- Check if the industry was updated to Crypto for all Crpyo-like industries 
SELECT DISTINCT industry
FROM layoffs_staging_2 
ORDER BY industry;

-- Explore the location column and see if there are any chagnes needed 
SELECT DISTINCT location
FROM layoffs_staging_2;

-- Explore the coutrny column and see if there are any chagnes needed 
SELECT DISTINCT country 
FROM layoffs_staging_2
ORDER BY country;

-- There is a duplicate United States row as one row says: United States. 
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging_2
WHERE country LIKE '%United States%';

UPDATE layoffs_staging_2 
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE '%United States%';

-- Check if the period was removed from after United States
SELECT DISTINCT country
FROM layoffs_staging_2
WHERE country LIKE '%United States%';

-- The date is in text format - chagne it to a date format in MM DD YYYY
SELECT `date`,
       STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging_2;

-- Update the date to date format 
UPDATE layoffs_staging_2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

SELECT `date`
FROM layoffs_staging_2;

-- Modify the date column to a date data type 
ALTER TABLE layoffs_staging_2
MODIFY COLUMN `date` DATE;

-- 3. Fix Null values or blank values 

-- find the rows wherhe the industry is null 
SELECT *
FROM layoffs_staging_2
WHERE industry IS NULL 
OR industry = '';

-- The only null value for industry is Bally, which does not have any populated values for industry, so leave it as null
SELECT *
FROM layoffs_staging_2 
WHERE company = '%Balley%';

-- If a company has a populated row for industry and is blank in another, fill the blank rows with the populated industry name 
SELECT stg1.industry, stg2.industry
FROM layoffs_staging_2 stg1 
INNER JOIN layoffs_staging_2 stg2
	ON stg1.company = stg2.company 
    AND stg1.location = stg2.location 
WHERE (stg1.industry IS NULL OR stg1.industry = '')
AND stg2.industry IS NOT NULL;

-- Before updating the industries for each company, change their blanks to nulls
UPDATE layoffs_staging_2
SET industry = NULL 
WHERE industry = '';

-- For the companies that have a non null industry in one of their rows, update all rows of that company so that the industry is consistent
UPDATE layoffs_staging_2 stg1
INNER JOIN layoffs_staging_2 stg2
	ON stg1.company = stg2.company 
    AND stg1.location = stg2.location 
SET stg1.industry = stg2.industry 
WHERE (stg1.industry IS NULL OR stg1.industry = '')
AND stg2.industry IS NOT NULL;

-- For the companies that have a non null funds_raised amount, fill in the other null rows for that company if the company and location match 
SELECT t1.company, t1.funds_raised_millions, t2.company, t2.funds_raised_millions
FROM layoffs_staging_2 t1
INNER JOIN layoffs_staging_2 t2
ON t1.company = t2.company 
AND t1.location = t2.location
WHERE (t1.funds_raised_millions IS NULL OR t1.funds_raised_millions = '')
AND t2.funds_raised_millions IS NOT NULL;

UPDATE layoffs_staging_2 t1
INNER JOIN layoffs_staging_2 t2
	ON t1.company = t2.company 
	AND t1.location = t2.location 
SET t1.funds_raised_millions = t2.funds_raised_millions
WHERE (t1.funds_raised_millions IS NULL OR t1.funds_raised_millions = '')
AND t2.funds_raised_millions IS NOT NULL;

-- 4. Remove any columns and rows that are not needed

-- Find rows where the total laid off and percentage laid off are both null to possibly remove
SELECT *
FROM layoffs_staging_2
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

-- Deleate all rows where the total laid off and percentage laid off are both NULL
DELETE FROM layoffs_staging_2
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

-- Delete the duplicate_count and row num column you made above
SELECT *
FROM layoffs_staging_2;

ALTER TABLE layoffs_staging_2
DROP COLUMN duplicate_count,
DROP COLUMN row_num;

SELECT *
FROM layoffs_staging_2;

-- 