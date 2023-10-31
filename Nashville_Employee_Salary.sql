

/*
			Nashville Public Employee Salary Analysis Fiscal Year 2023

	The Nashville_Dept2023 table contains employee base salary and department info. The 
	main thing we want from this table is the department each employee belongs to so we 
	can sort by department later( ex. Police, Fire, Parks, Health, etc)


	The Nashville_Pay2023 table contains detailed salary and compensation data for Metro Nashville Employees 
	for fiscal year 2023. This table does contain data for MNPS, MDHA, MTA and NES, and piecework 
	employees(poll workers, sports officials) that we will not use in this analysis.

	Data Sources:
	https://data.nashville.gov/General-Government/General-Government-Employees-Titles-and-Base-Annua/2hu7-5kjq

	https://data.nashville.gov/Budget-Finance/Metro-Government-Employee-Earnings/7saa-4q7b

*/

SELECT *
	FROM PortfolioProject..Nashville_Dept2023

SELECT *
	FROM PortfolioProject..Nashville_pay2023

/*
	Check for duplicate entries in each table. It does appear that some employees are listed multiple times,
	typically if they moved between Home_Business_Unit, like police officers switching precincts. There might
	be a few who changed job titles during the year and there may even be a couple who just have the same name but are
	not actually the same person. 
*/

SELECT *
FROM PortfolioProject..Nashville_Dept2023
WHERE Name IN(
		SELECT Name
			FROM PortfolioProject..Nashville_Dept2023
			GROUP BY Name
			HAVING COUNT(Name) > 1)
	

SELECT *
FROM PortfolioProject..Nashville_pay2023
WHERE Employee_Name IN(
		SELECT Employee_Name
			FROM PortfolioProject..Nashville_pay2023
			GROUP BY Employee_Name
			HAVING COUNT(Employee_Name) > 1)
ORDER BY Employee_Name

/*
	Ideally what we want to to is keep only those employees listed in BOTH tables and then sort out any duplicate values. 
	We will take all salary and total compensation from the Nashville_Pay2023 table and the corresponding Department info from the 
	Nashville_Dept2023 table. We'll store this in a temp table to querry off of later.
*/


DROP TABLE IF EXISTS #salarysummary
CREATE TABLE #salarysummary
(
employee_name nvarchar(255),
title nvarchar(255),
home_business_unit nvarchar(255),
base_pay float,
total_pay float,
department nvarchar(255),
employment_status nvarchar(255)
)
INSERT INTO #salarysummary
SELECT pay.Employee_Name, dept.Title, pay.Home_Business_Unit, pay.Regular_Pay, pay.Total_Pay, dept.Department, dept.[Employment Status]
	FROM PortfolioProject..Nashville_pay2023 AS pay
	INNER JOIN PortfolioProject..Nashville_Dept2023 AS dept
		ON dept.Name = pay.Employee_Name
	ORDER BY Employee_Name	

SELECT *
	FROM #salarysummary
	ORDER BY employee_name


-- Check duplicate values of our new temp table

SELECT employee_name, COUNT(employee_name)
	FROM #salarysummary
	GROUP BY employee_name
	HAVING COUNT(employee_name) > 1

/*
	Check our new temp table for duplicates. We know from earlier there are some
	duplicate entries for employees. We'll also use base salary to check for
	real duplicates. It looks like these employees may have been entered twice under
	different job titles or home_business_unit. 
*/

SELECT *
	FROM (SELECT *, COUNT(*) OVER (PARTITION BY employee_name, base_pay) AS cnt
			FROM #salarysummary) AS x
WHERE cnt > 1



-- Assign rows a number. 1 is unique, anything > 1 is a duplicate
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY employee_name,
				  base_pay
				 ORDER BY
					employee_name) row_num

	FROM #salarysummary
)
SELECT *
	FROM RowNumCTE
	WHERE row_num > 1

-- Delete rows with a row number > 1, the duplicates

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY employee_name,
				  base_pay
				 ORDER BY
					employee_name) row_num

	FROM #salarysummary
)
DELETE
	FROM RowNumCTE
	WHERE row_num > 1

-- Can run this again to check that delete worked. Shouldn't return any values
SELECT *
	FROM (SELECT *, COUNT(*) OVER (PARTITION BY employee_name, base_pay) AS cnt
			FROM #salarysummary) AS x
WHERE cnt > 1

-- Moving on to multiple employee entries with different pay values

SELECT *
FROM #salarysummary
WHERE employee_name IN(
		SELECT employee_name
			FROM #salarysummary
			GROUP BY employee_name
			HAVING COUNT(employee_name) > 1)
ORDER BY employee_name

/*
	Create a new table and handle the rest of our duplicates. We are going to sum total_pay and
	base_pay for each employee that has the same name, title, and department and store this in our
	new table. 
*/

DROP TABLE IF EXISTS PortfolioProject..Nashville_Salary_2023
CREATE TABLE PortfolioProject..Nashville_Salary_2023
(
employee_name nvarchar(255),
title nvarchar(255),
department nvarchar(255),
employment_status nvarchar(255),
base_pay float,
total_pay float,
)
INSERT INTO PortfolioProject..Nashville_Salary_2023
SELECT employee_name, title, department, employment_status, SUM(base_pay) AS base_pay, SUM(total_pay) AS total_pay
	FROM #salarysummary
	GROUP BY employee_name, title, department, employment_status
	ORDER BY total_pay DESC

-- Check for duplicates. If there are no more duplicates this will be blank
-- I am actually going to leave these remaining few duplicates alone. Most are from 
-- different departments and I want to preserve the salary amount for each department
-- for analysis. Also, one set could actually be 2 different people with the same name. 

SELECT *
FROM PortfolioProject..Nashville_Salary_2023
WHERE employee_name IN(
		SELECT employee_name
			FROM PortfolioProject..Nashville_Salary_2023
			GROUP BY employee_name
			HAVING COUNT(employee_name) > 1)

------------------------------------------------------------------------------------------------------------------

/* 
	This section will be a bit of exploratory analysis of our new Nashville_Salary_2023 table

*/

-- Top earners

SELECT *
	FROM PortfolioProject..Nashville_Salary_2023
	ORDER BY total_pay DESC

-- Number of employees for each department

SELECT department, COUNT(*) AS num_employees
	FROM Nashville_Salary_2023
	GROUP BY department
	ORDER BY num_employees DESC

-- Total compensation by department

SELECT department, ROUND(SUM(total_pay), 0) AS total_compensation
	FROM Nashville_Salary_2023
	GROUP BY department
	ORDER BY total_compensation DESC

-- Avg pay per employee in each department

SELECT department, ROUND(AVG(base_pay),0) AS avg_base, ROUND(AVG(total_pay),0) AS avg_total, COUNT(*) AS num_employees
	FROM Nashville_Salary_2023
	GROUP BY department
	ORDER BY avg_total DESC

-- Most Common Job Titles and their average pay
SELECT title, ROUND(AVG(total_pay), 0) AS avg_compensation, COUNT(*)
	FROM Nashville_Salary_2023
	GROUP BY title
	ORDER BY COUNT(*) DESC


-- Looking at titles within each department
-- Might be interesting to seperate pay for police officers from admin and other
-- roles lumped into the 'Police' department. Could do same with fire, judges, treatment plant operators

SELECT title, COUNT(*)
	FROM Nashville_Salary_2023
	WHERE department = 'Water Services'
	GROUP BY title

-- Total and average amount of 'Other_pay' per department
SELECT department, ROUND((SUM(total_pay)-SUM(base_pay)), 0) AS other_pay, SUM(total_pay) AS total_compensation
	FROM Nashville_Salary_2023
	GROUP BY department
	ORDER BY other_pay DESC

SELECT department, ROUND((AVG(total_pay)-AVG(base_pay)), 0) AS avg_other_pay, ROUND(AVG(total_pay), 0) AS avg_compensation
	FROM Nashville_Salary_2023
	GROUP BY department
	ORDER BY avg_other_pay DESC


-- Total and average amount of 'Other_pay' per title 
SELECT title, department, ROUND((SUM(total_pay)-SUM(base_pay)), 0) AS other_pay, ROUND(SUM(total_pay), 0) AS total_compensation
	FROM Nashville_Salary_2023
	GROUP BY title, department
	ORDER BY other_pay DESC

SELECT title, department, ROUND(AVG((total_pay)-(base_pay)), 0) AS avg_other_pay, ROUND(AVG(total_pay), 0) AS avg_compensation
	FROM Nashville_Salary_2023
	GROUP BY title, department
	ORDER BY avg_other_pay DESC


-- Use a CTE to calculate other_pay, then use that to calculate the percentage of total pay that
-- other pay makes up

WITH OtherPercent (title, department, base_pay, other_pay, total_pay)
AS
(
	SELECT title, department, base_pay, ROUND((total_pay - base_pay), 0) AS other_pay, total_pay	
		FROM Nashville_Salary_2023	
)
SELECT *, ROUND(((other_pay/total_pay) * 100), 0) AS other_percent
	FROM OtherPercent
	
	


-- Let's actually add 'other_pay' as a new column in this table to make future calculations easier
ALTER TABLE Nashville_Salary_2023
ADD other_pay float;

UPDATE Nashville_Salary_2023 SET other_pay = ROUND((total_pay - base_pay), 0)

SELECT *
	FROM Nashville_Salary_2023

-- Calculate percentage of 'other_pay' as a part of total_pay. Sort by department and position title

SELECT department, ROUND(AVG(((other_pay / total_pay) * 100)), 0) AS percent_other, COUNT(*) AS num_employees
	FROM Nashville_Salary_2023
	GROUP BY department
	HAVING COUNT(*) > 1
	ORDER BY percent_other DESC


SELECT title, ROUND(AVG(((other_pay / total_pay) * 100)), 0) AS percent_other, COUNT(*) AS num_employees
	FROM Nashville_Salary_2023
	GROUP BY title
	HAVING COUNT(*) > 1
	ORDER BY percent_other DESC


---------------------------------------------------------------------------------------------------

/* 
			Creating tables to use in Tableau Dashboard
*/

-- Top Earners
SELECT TOP 15 *
	FROM PortfolioProject..Nashville_Salary_2023
	ORDER BY total_pay DESC

/*
	I want to create a table for the avg pay in the 20 largest departments, but I also want to include a new row
	with the average pay for all other departments outside the top 20. Create a temnp table to store the first
	top 20 in , then append a row with the all other average
*/

DROP TABLE IF EXISTS #LargestDepts
CREATE TABLE #LargestDepts
(
department nvarchar(255),
avg_base float,
avg_other float,
avg_total float,
num_employees float,
)
INSERT INTO #LargestDepts
SELECT TOP 20 department, ROUND(AVG(base_pay), 0) AS avg_base, ROUND(AVG(other_pay), 0) AS avg_other,  ROUND(AVG(total_pay), 0) AS total_compensation, COUNT(*) AS num_employees
	FROM Nashville_Salary_2023
	GROUP BY department
	ORDER BY num_employees DESC
SELECT *
	FROM #LargestDepts

-- Create a temp table for smallest depts to get averages from  
DROP TABLE IF EXISTS #smallestdepts
CREATE TABLE #smallestdepts
(
department nvarchar(255),
avg_base float,
avg_other float,
avg_total float,
num_employees float,
)
INSERT INTO #smallestdepts
SELECT department, ROUND(AVG(base_pay), 0) AS avg_base, ROUND(AVG(other_pay), 0) AS avg_other, ROUND(AVG(total_pay), 0) AS total_compensation, COUNT(*)
		FROM Nashville_Salary_2023
		GROUP BY department
		HAVING COUNT(*) < 90

-- Add new row with averages for all other depts
INSERT INTO #LargestDepts (department, avg_base, avg_other, avg_total, num_employees)

SELECT 'All Others', ROUND(AVG(avg_base), 0) AS avg_base, ROUND(AVG(avg_other), 0) AS avg_other, ROUND(AVG(avg_total), 0) AS avg_total, SUM(num_employees) AS num_employees
	FROM #smallestdepts

SELECT *
	FROM #LargestDepts
	ORDER BY num_employees DESC
		
-- Average pay by position title

SELECT title, department, ROUND(AVG(base_pay), 0) AS avg_base, ROUND(AVG(other_pay), 0) as avg_other,
				ROUND(AVG(total_pay), 0) AS avg_total, COUNT(*) AS num_employees
	FROM Nashville_Salary_2023
	GROUP BY title, department
	ORDER BY COUNT(*) DESC

-- Total Spending for each department

SELECT department, ROUND(SUM(total_pay), 0) as total_payroll
	FROM PortfolioProject..Nashville_Salary_2023
	GROUP BY department
	ORDER BY total_payroll DESC
