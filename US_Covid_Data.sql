
/* 

		Exploring Covid-19 Data with SQL

*/


-- Covid cases and death numbers
Select *
	From PortfolioProject..US_Covid_Cases


-- Covid vaccination numbers
Select *
	From PortfolioProject..US_Covid_Vaccinations
	


-- state population data we will join to other tables to perform calculations with
Select *
	From PortfolioProject..statepop



-- Total Covid cases and deaths per state

Select state, MAX(tot_cases) as total_cases, MAX(tot_deaths) as total_deaths
	From PortfolioProject..US_Covid_Cases
	Where state not in ('FSM', 'GU', 'MP', 'RMI', 'PR', 'AS', 'PW', 'VI')
	Group by state

-- Create a temp table containg the total cases and deaths

Drop Table if exists #deaths
Create Table #deaths
(
state nvarchar(255),
total_cases numeric,
total_deaths numeric,
)

Insert into #deaths
Select state, MAX(tot_cases) as total_cases, MAX(tot_deaths) as total_deaths
	From PortfolioProject..US_Covid_Cases
	Where state not in ('FSM', 'GU', 'MP', 'RMI', 'PR', 'AS', 'PW', 'VI')  -- omit the territories
	Group by state
	
select *
	From #deaths

-- For some reaon NYC is counted seperatly from the rest of the state
-- We'll update the NY row to show the combined total
-- and remove the NYC row

Update #deaths
SET total_cases = 6838769, total_deaths = 77522
Where state = 'NY'

Delete From #deaths Where state = 'NYC'


-- Need to sum cases and deaths for entire US to get nationwide stats
-- and creat a new row for that in our temp table

Select  SUM(total_cases) as nationwide_cases, SUM(total_deaths) as nationwide_deaths
	From #deaths


Insert into #deaths
	Values ('US', 103442801, 1127185)







-- Looking at vaccination data
-- Get totals for each state and store it in a temp table
-- we will use this to join that to our other tables to calculate vaccination rate


Drop Table if exists #vaccinations
Create Table #vaccinations
(
location nvarchar(255),
total_vaccinated numeric
)
Insert into #vaccinations
Select Location, MAX(Series_Complete_Cumulative) as total_vaccinated
	From PortfolioProject..US_Covid_Vaccinations
	Where Location not in ('GU', 'MP', 'VI', 'MH','AS', 'FM', 'PW', 'PR')
	Group By Location

Select * 
	From #vaccinations



-- Join with population data from statepop table and calcualte death rate by state
-- as well as deaths per 100K, and vaccination rate
-- rate = total_deaths/total_pop * popsize(100K)
-- will use this data for visual


Select Description, total_cases, total_deaths, population, (total_deaths/population)*100 as death_rate
	From #deaths as deaths
	 Right Join PortfolioProject..statepop as population
		ON deaths.state = population.state

	Order by death_rate desc




-- rate = total_deaths/total_pop * popsize(100K)
-- Save this table, will use for Tableau visual later


Select Description, total_cases, total_deaths, total_vaccinated, population, (total_deaths/population)*100 as death_rate, 
		(total_deaths/population*100000) as deaths_per_100K, ((total_vaccinated/population)*100) as vaccination_rate
	From #deaths as deaths
	Left Join PortfolioProject..statepop as population
		ON deaths.state = population.state
	Left Join #vaccinations as vaccinations
		ON deaths.state = vaccinations.location
	Order by vaccination_rate desc


-- Nationwide totals and averages only
Select Description, total_cases, total_deaths, total_vaccinated, population, (total_deaths/population)*100 as death_rate, 
		(total_deaths/population*100000) as deaths_per_100K, ((total_vaccinated/population)*100) as vaccination_rate
	From #deaths as deaths
	Left Join PortfolioProject..statepop as population
		ON deaths.state = population.state
	Left Join #vaccinations as vaccinations
		ON deaths.state = vaccinations.location
	Where Description like 'U.S.'



-- Total cases and deaths by date for US
-- The cases in this file were reported weekly

Select CAST(date_updated AS DATE) as date, SUM(new_cases) as daily_cases, SUM(new_deaths) as daily_deaths
	From PortfolioProject..US_Covid_Cases
	Group By date_updated
	Order By date 

