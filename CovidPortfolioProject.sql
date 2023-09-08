Select *
	From PortfolioProject..coviddeaths

Select *
	From PortfolioProject..CovidVaccinations

 -- Select Data we are going to be using

 Select location, date, total_cases, new_cases, total_deaths, population
	From PortfolioProject..coviddeaths
	order by 1,2
	
	
-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract Covid in your country

Select location, date, total_cases,total_deaths, 
(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS Deathpercentage
	From PortfolioProject..coviddeaths
	Where location like 'United States' and continent is not NULL
	Order BY 1,2

-- Total Cases vs Population

Select location, date, total_cases, population, 
(CONVERT(float, total_cases) / population) * 100 AS TotalCasepercent
	From PortfolioProject..coviddeaths
	Where location like 'United States' and continent is not NULL
	Order BY 1,2

-- What Percentage of the total population for a given country
-- has contracted Covid

Select location, MAX(total_cases) as HighestCaseCount, population, 
(CONVERT(float, MAX(total_cases)) / population) * 100 AS PercentPop
	From PortfolioProject..coviddeaths
	Where continent is not NULL
	Group By location, population
	Order BY 4 DESC


Select location, population, MAX(Cast(total_deaths as bigint)) as TotalDeathCount
	From PortfolioProject..coviddeaths
	Where continent is not NULL
	Group By location, population
	Order BY TotalDeathCount DESC

-- LETS BREAK THINGS DOWN BY CONTINENT

Select location, MAX(Cast(total_deaths as bigint)) as TotalDeathCount
	From PortfolioProject..coviddeaths
	Where continent is NULL AND location not like '%income%'
	Group By location
	Order BY TotalDeathCount DESC

-- Global Numbers

Select date, SUM(new_cases) as GlobalNewCases, SUM(new_deaths) as TotalGlobalDeaths
		,(SUM(new_deaths)/SUM(NULLIF(new_cases, 0))*100) as DeathPercentage
	From PortfolioProject..coviddeaths
	Where continent is not null
	Group BY date
	Order By 1


-- Total Population vs Vaccinations

Select *
	From PortfolioProject..coviddeaths AS deaths
	Join PortfolioProject..CovidVaccinations AS vacc
		ON deaths.location = vacc.location
		and deaths.date = vacc.date 

Select deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations
	From PortfolioProject..coviddeaths AS deaths
	Join PortfolioProject..CovidVaccinations AS vacc
		ON deaths.location = vacc.location
		and deaths.date = vacc.date 
	Where deaths.continent is not NULL 
	Order BY 2,3

-- Calculate rolling total vaccination count by country
-- Partition By function splits the rolling count by country and date
-- Without it, the totalrollingvacc count would total everything. 


Select deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations
	,SUM(Convert(bigint, vacc.new_vaccinations)) 
	OVER (Partition by deaths.location ORDER BY deaths.location, deaths.date) AS TotalRollingVacc
	--(TotalRollingVacc/population)*100 as PercentVaccinated
	From PortfolioProject..coviddeaths AS deaths
	Join PortfolioProject..CovidVaccinations AS vacc
		ON deaths.location = vacc.location
		and deaths.date = vacc.date 
	Where deaths.continent is not NULL 
	Order BY 2,3

 -- USE CTE
 -- Number of columns in the CTE need to match number of columns in the select statement
 -- The use of a CTE was necessary since we wanted to use a parameter(RollingFullyVaccinated)
 -- that we created in the Select statement, as a new parameter. So we ran the first query
 -- to get the first set of data we needed, then through the creation of a CTE, queried that first query

 With PopvsVacc (continent, location, date, population, new_vaccinations, RollingFullyVaccinated, people_fully_vaccinated)
 as 
 (
 Select deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations, vacc.people_fully_vaccinated
	,SUM(Convert(bigint, vacc.people_fully_vaccinated)) 
	OVER (Partition by deaths.location ORDER BY deaths.location, deaths.date) AS RollingFullyVaccinated
	--(TotalRollingVacc/population)*100 as PercentVaccinated
	From PortfolioProject..coviddeaths AS deaths
	Join PortfolioProject..CovidVaccinations AS vacc
		ON deaths.location = vacc.location
		and deaths.date = vacc.date 
	Where deaths.continent is not NULL 
	--Order BY 2,3
)
Select *, (RollingFullyVaccinated/population)*100 as VaccinationRate
From PopvsVacc
Order by 2,3

-- USING TEMP  TABLE
-- Below is an example of using a Temp Table to achieve the same results as above using the CTE

Create Table #PercentPopVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population float,
new_vaccinations nvarchar(255),
people_fully_vaccinated bigint,
RollingFullyVaccinated numeric
)

Insert into #PercentPopVaccinated
 Select deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations, vacc.people_fully_vaccinated
	,SUM(Convert(bigint, vacc.people_fully_vaccinated)) 
	OVER (Partition by deaths.location ORDER BY deaths.location, deaths.date) AS RollingFullyVaccinated
	--(TotalRollingVacc/population)*100 as PercentVaccinated
	From PortfolioProject..coviddeaths AS deaths
	Join PortfolioProject..CovidVaccinations AS vacc
		ON deaths.location = vacc.location
		and deaths.date = vacc.date 
	--Where deaths.continent is not NULL 
	--Order BY 2,3

Select *, (RollingFullyVaccinated/population)*100 
From #PercentPopVaccinated
Order by 2,3


--Creating View to store for later data visualization

Create View PercentPopVaccinates as
 Select deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations, vacc.people_fully_vaccinated
	,SUM(Convert(bigint, vacc.people_fully_vaccinated)) 
	OVER (Partition by deaths.location ORDER BY deaths.location, deaths.date) AS RollingFullyVaccinated
	--(TotalRollingVacc/population)*100 as PercentVaccinated
	From PortfolioProject..coviddeaths AS deaths
	Join PortfolioProject..CovidVaccinations AS vacc
		ON deaths.location = vacc.location
		and deaths.date = vacc.date 
	Where deaths.continent is not NULL