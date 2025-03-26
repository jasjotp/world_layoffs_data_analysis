# World Layoffs Data Analysis Project

## Overview
This project explores and cleans real-world layoff data using SQL, setting the foundation for a full data storytelling and insights pipeline. I started with raw, messy data and applied industry-standard data cleaning techniques to prepare it for effective EDA (Exploratory Data Analysis). The goal is to extract meaningful patterns around company layoffs across industries, countries, and time periods.

I treated this like a real-world analyst task: building a staging layer, cleaning the data step-by-step, and documenting everything along the way.

## Why I Built This
As someone who loves making data actually useful, I wanted to take a publicly available dataset that's relevant and emotional (people losing jobs) and make it clean, usable, and ready to tell a story. This project is a practical example of how I have approached a messy dataset in my previous professional analytics roles.

## Dataset Summary
The dataset tracks tech industry layoffs over time and includes:
- Company name  
- Location  
- Industry  
- Total laid off  
- Percentage laid off  
- Date  
- Stage (e.g., Seed, Series A, Public)  
- Country  
- Funds raised (in millions)  

It's a rich dataset for understanding which companies are cutting back, in which industries, and when. There's also potential to tie it into macroeconomic trends or investor behavior.

## Data Cleaning Highlights (in SQL)
Here's a breakdown of the key data cleaning steps I took:

### 1. Removed Duplicates
- Used `ROW_NUMBER()` and `COUNT()` to identify exact duplicates across key columns.  
- Created a second staging table and deleted rows with `row_num > 1`.

### 2. Standardized Text
- Trimmed whitespace in `company`, `industry`, and `country` columns.  
- Merged inconsistent values (e.g., "Crypto Currency", "Crpyotcurrency" → "Crypto").  
- Fixed cases like "United States." (with a period) → "United States".

### 3. Fixed Data Types
- Converted `date` from text to proper `DATE` format.

### 4. Handled Nulls and Blanks
- Replaced blank strings with `NULL`s.  
- Filled in missing `industry` and `funds_raised_millions` values by matching company/location pairs.  
- Removed rows with both `total_laid_off` and `percentage_laid_off` as `NULL` (non-informative rows).

### 5. Removed Unnecessary Columns
- Dropped helper columns like `duplicate_count` and `row_num` after cleanup.

## Exploratory Data Analysis (EDA)

### Layoff Patterns and Company Impact
- Identified the top 5 companies with the highest number of layoffs and their corresponding dates.
- Filtered companies that laid off **100% of their staff** (likely shut down or acquired).
- Ranked companies by total layoffs using `DENSE_RANK()`.

### Industry and Stage-Level Insights
- Analyzed total layoffs by industry and identified the **top 5 most affected industries**.
- Measured layoff frequency and cumulative layoffs using **time-series breakdowns** and running totals.
- Ranked companies by startup **stage** (e.g., Seed, Series A, Post-IPO) to identify funding stage patterns in layoffs.

### Country and Time-Based Trends
- Ranked countries by total number of layoffs.
- Analyzed layoffs by specific **dates, months, and years** to identify peak periods and seasonality.
- Calculated **rolling monthly totals** and **running sums** using `SUM(...) OVER(ORDER BY ...)`.

### Behavioral Patterns and Risk Assessment
- Detected companies with layoffs in **3 or more consecutive months** using date sequence logic and row number window functions.
- Calculated **layoffs per $1 million raised** to spot companies with inefficient capital deployment.
- Built a **risk score** combining company stage, funding amount, and layoffs to rank companies by potential instability or risk of collapse.
