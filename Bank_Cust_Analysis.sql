-- Step 1: Confirm the dataset has 41,188 rows and 21 columns before cleaning
SELECT *
FROM [bank-additional-full]

-- Step 2: Check for any missing values in the dataset
SELECT *
FROM [bank-additional-full]
WHERE age IS NULL 
OR job IS NULL 
OR marital IS NULL 
OR education IS NULL 
OR [default] IS NULL 
OR housing IS NULL 
OR loan IS NULL 
OR contact IS NULL 
OR month IS NULL 
OR day_of_week IS NULL 
OR duration IS NULL 
OR campaign IS NULL 
OR pdays IS NULL 
OR previous IS NULL 
OR poutcome IS NULL 
OR emp_var_rate IS NULL 
OR cons_price_idx IS NULL 
OR cons_conf_idx IS NULL 
OR euribor3m IS NULL 
OR nr_employed IS NULL;

-- Step 3: Standardise column names for easier analysis
EXEC sp_rename 'bank-additional-full.age', 'Age', 'COLUMN';
EXEC sp_rename 'bank-additional-full.job', 'Job', 'COLUMN';
EXEC sp_rename 'bank-additional-full.marital', 'Marital_Status', 'COLUMN';
EXEC sp_rename 'bank-additional-full.education', 'Education', 'COLUMN';
EXEC sp_rename 'bank-additional-full.default', 'Default_Status', 'COLUMN';
EXEC sp_rename 'bank-additional-full.housing', 'Housing_Status', 'COLUMN';
EXEC sp_rename 'bank-additional-full.loan', 'Loan_Status', 'COLUMN';
EXEC sp_rename 'bank-additional-full.contact', 'Contact_Type', 'COLUMN';
EXEC sp_rename 'bank-additional-full.month', 'Month', 'COLUMN';
EXEC sp_rename 'bank-additional-full.day_of_week', 'Day_of_Week', 'COLUMN';
EXEC sp_rename 'bank-additional-full.duration', 'Duration', 'COLUMN';
EXEC sp_rename 'bank-additional-full.campaign', 'Campaign', 'COLUMN';
EXEC sp_rename 'bank-additional-full.pdays', 'Pdays', 'COLUMN';
EXEC sp_rename 'bank-additional-full.previous', 'Previous', 'COLUMN';
EXEC sp_rename 'bank-additional-full.poutcome', 'Poutcome', 'COLUMN';
EXEC sp_rename 'bank-additional-full.emp_var_rate', 'Emp_Var_Rate', 'COLUMN';
EXEC sp_rename 'bank-additional-full.cons_price_idx', 'Cons_Price_Idx', 'COLUMN';
EXEC sp_rename 'bank-additional-full.cons_conf_idx', 'Cons_Conf_Idx', 'COLUMN';
EXEC sp_rename 'bank-additional-full.euribor3m', 'Euribor3m', 'COLUMN';
EXEC sp_rename 'bank-additional-full.nr_employed', 'Nr_Employed', 'COLUMN';


-- Step 4:Review and handle the literal "unknown" values
SELECT *
FROM [bank-additional-full]
WHERE Job = 'unknown';

-- Step 5: Check for duplicate rows and remove them if necessary
-- Preview duplicates
WITH DuplicateRows AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY
                   Age, Job, Marital_Status, Education,
                   Default_Status, Housing_Status, Loan_Status,
                   Contact_Type, Month, Day_of_Week, Duration,
                   Campaign, Pdays, Previous, Poutcome,
                   Emp_Var_Rate, Cons_Price_Idx, Cons_Conf_Idx,
                   Euribor3m, Nr_Employed, y
               ORDER BY (SELECT NULL)
           ) AS RowNum
    FROM [bank-additional-full]
)
SELECT *
FROM DuplicateRows
WHERE RowNum > 1;


-- Delete duplicates
BEGIN TRANSACTION;
WITH DuplicateRows AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY
                   Age, Job, Marital_Status, Education,
                   Default_Status, Housing_Status, Loan_Status,
                   Contact_Type, Month, Day_of_Week, Duration,
                   Campaign, Pdays, Previous, Poutcome,
                   Emp_Var_Rate, Cons_Price_Idx, Cons_Conf_Idx,
                   Euribor3m, Nr_Employed, y
               ORDER BY (SELECT NULL)
           ) AS RowNum
    FROM [bank-additional-full]
)
DELETE FROM DuplicateRows
WHERE RowNum > 1;

-- Check the number of remaining rows after deletion
SELECT COUNT(*) AS RemainingRows
FROM [bank-additional-full];

COMMIT TRANSACTION;   

-- Step 6: Recode pdays = 999
-- Add a new column to indicate whether the client was previously contacted
ALTER TABLE [bank-additional-full]
ADD Previous_Contact VARCHAR(10);

-- Update the new column based on the value of pdays
UPDATE [bank-additional-full]
SET Previous_Contact = CASE
    WHEN Pdays = 999 THEN 'No'
    ELSE 'Yes'
END;

-- Replace the sentinel value 999 in the pdays column with NULL
BEGIN TRANSACTION;
UPDATE [bank-additional-full]
SET Pdays = NULL
WHERE Pdays = 999;

SELECT Pdays, Previous_Contact
FROM [bank-additional-full]
WHERE Pdays IS NOT NULL OR Previous_Contact = 'Yes';

COMMIT TRANSACTION;

-- Step 7:  Treat duration = 0 carefully
SELECT Duration 
FROM [bank-additional-full]
WHERE Duration != 0;

-- Step 8: Proper data format for analysis
BEGIN TRANSACTION;
UPDATE [bank-additional-full]
SET Job = UPPER(LEFT(Job, 1)) + LOWER(SUBSTRING(Job, 2, LEN(Job))),
    Marital_Status = UPPER(LEFT(Marital_Status, 1)) + LOWER(SUBSTRING(Marital_Status, 2, LEN(Marital_Status))),
    Education = UPPER(LEFT(Education, 1)) + LOWER(SUBSTRING(Education, 2, LEN(Education))),
    Default_Status = UPPER(LEFT(Default_Status, 1)) + LOWER(SUBSTRING(Default_Status, 2, LEN(Default_Status))),
    Housing_Status = UPPER(LEFT(Housing_Status, 1)) + LOWER(SUBSTRING(Housing_Status, 2, LEN(Housing_Status))),
    Loan_Status = UPPER(LEFT(Loan_Status, 1)) + LOWER(SUBSTRING(Loan_Status, 2, LEN(Loan_Status))),
    Contact_Type = UPPER(LEFT(Contact_Type, 1)) + LOWER(SUBSTRING(Contact_Type, 2, LEN(Contact_Type))),
    Month = UPPER(LEFT(Month, 1)) + LOWER(SUBSTRING(Month, 2, LEN(Month))),
    Day_of_Week = UPPER(LEFT(Day_of_Week, 1)) + LOWER(SUBSTRING(Day_of_Week, 2, LEN(Day_of_Week))),
    Poutcome = UPPER(LEFT(Poutcome, 1)) + LOWER(SUBSTRING(Poutcome, 2, LEN(Poutcome))),
    y = UPPER(LEFT(y, 1)) + LOWER(SUBSTRING(y, 2, LEN(y)));


COMMIT TRANSACTION;

BEGIN TRANSACTION;

UPDATE [bank-additional-full]
SET Job = REPLACE(REPLACE(Job, '-', ' '), '.', ''),
    Education = REPLACE(Education, '.', ' ');

COMMIT TRANSACTION;

-- Step 9: Convert data types
-- Whole-number fields
ALTER TABLE dbo.[bank-additional-full] ALTER COLUMN [Age] INT;
ALTER TABLE dbo.[bank-additional-full] ALTER COLUMN [Duration] INT;
ALTER TABLE dbo.[bank-additional-full] ALTER COLUMN [Campaign] INT;
ALTER TABLE dbo.[bank-additional-full] ALTER COLUMN [Pdays] INT NULL;
ALTER TABLE dbo.[bank-additional-full] ALTER COLUMN [Previous] INT;

-- Decimal fields
ALTER TABLE dbo.[bank-additional-full] ALTER COLUMN [Emp_Var_Rate] DECIMAL(4,1);
ALTER TABLE dbo.[bank-additional-full] ALTER COLUMN [Cons_Price_Idx] DECIMAL(5,3);
ALTER TABLE dbo.[bank-additional-full] ALTER COLUMN [Cons_Conf_Idx] DECIMAL(4,1);
ALTER TABLE dbo.[bank-additional-full] ALTER COLUMN [Euribor3m] DECIMAL(5,3);
ALTER TABLE dbo.[bank-additional-full] ALTER COLUMN [Nr_Employed] DECIMAL(6,1);

-- Calender fields
ALTER TABLE dbo.[bank-additional-full] ALTER COLUMN [Month] VARCHAR(10);
ALTER TABLE dbo.[bank-additional-full] ALTER COLUMN [Day_of_Week] VARCHAR(10);

-- Step 10: Create analysis-friendly fields 
-- Group customers into age bands for better analysis
ALTER TABLE dbo.[bank-additional-full] 
ADD [Age_Band] VARCHAR(20);

UPDATE dbo.[bank-additional-full]
SET Age_Band = CASE
    WHEN Age BETWEEN 17 AND 25 THEN '17-25'
    WHEN Age BETWEEN 26 AND 35 THEN '26-35'
    WHEN Age BETWEEN 36 AND 45 THEN '36-45'
    WHEN Age BETWEEN 46 AND 55 THEN '46-55'
    WHEN Age BETWEEN 56 AND 65 THEN '56-65'
    ELSE '66+'
END;

-- Categorize campaign contact frequency
ALTER TABLE dbo.[bank-additional-full] 
ADD [Campaign_Intensity] VARCHAR(20);

UPDATE dbo.[bank-additional-full]
SET Campaign_Intensity = CASE
    WHEN Campaign = 1 THEN '1 contact'
    WHEN Campaign BETWEEN 2 AND 3 THEN '2-3 contacts'
    WHEN Campaign BETWEEN 4 AND 6 THEN '4-6 contacts'
    ELSE '7+ contacts'
END;

-- Create a readable subscription label
ALTER TABLE dbo.[bank-additional-full] 
ADD [Subscription_Label] VARCHAR(20);

UPDATE dbo.[bank-additional-full]
SET Subscription_Label = CASE
    WHEN y = 'Yes' THEN 'Subscribed'
    WHEN y = 'No' THEN 'Not Subscribed'
    ELSE 'Unknown'
END;

SELECT *
FROM dbo.[bank-additional-full]

-- Step 11: Keep duration out of pre-contact targeting conclusions
ALTER TABLE dbo.[bank-additional-full]
ADD Call_Duration_Band VARCHAR(25);

UPDATE dbo.[bank-additional-full]
SET Call_Duration_Band =
    CASE
        WHEN Duration = 0 THEN 'No recorded duration'
        WHEN Duration BETWEEN 1 AND 120 THEN 'Up to 2 minutes'
        WHEN Duration BETWEEN 121 AND 300 THEN '2–5 minutes'
        WHEN Duration BETWEEN 301 AND 600 THEN '5–10 minutes'
        ELSE 'Over 10 minutes'
    END;

-- Step 12: Retain month as an ordered field
ALTER TABLE dbo.[bank-additional-full]
ADD Month_Number INT;

UPDATE dbo.[bank-additional-full]
SET Month_Number =
    CASE
        WHEN Month = 'jan' THEN 1
        WHEN Month = 'feb' THEN 2
        WHEN Month = 'mar' THEN 3
        WHEN Month = 'apr' THEN 4
        WHEN Month = 'may' THEN 5
        WHEN Month = 'jun' THEN 6
        WHEN Month = 'jul' THEN 7
        WHEN Month = 'aug' THEN 8
        WHEN Month = 'sep' THEN 9
        WHEN Month = 'oct' THEN 10
        WHEN Month = 'nov' THEN 11
        WHEN Month = 'dec' THEN 12
    END;

SELECT *
FROM dbo.[bank-additional-full]