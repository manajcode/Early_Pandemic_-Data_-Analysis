/*
Covid 19 Data Exploration 
Please note that the data was downloaded was already created by Alex from: https://github.com/AlexTheAnalyst/PortfolioProjects/blob/main/CovidDeaths.xlsx
and https://github.com/AlexTheAnalyst/PortfolioProjects/blob/main/CovidVaccinations.xlsx
To import the files into ssms 19.1 I turned files into csv files and use the import flat file tool.
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select *
From Covid_Project.dbo.[CovidDeaths _Alex_Version]
order by 3,4

Select *
From Covid_Project.dbo.CovidVaccinations_Alex_Version
order by 3,4


-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From Covid_Project..[CovidDeaths _Alex_Version]
Where continent is not null 
order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases,total_deaths, cast((total_deaths*100/total_cases)as decimal(18,2))as DeathPercentage--*100 as DeathPercentage
From Covid_Project..[CovidDeaths _Alex_Version]
Where location like '%states%'
and continent is not null 
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  cast((total_cases*100.00/ NULLIF(population,0)) as decimal(18,2)) as PercentPopulationInfected --*100 as PercentPopulationInfected
From Covid_Project..[CovidDeaths _Alex_Version]
Where location like '%states%'
order by 1,2


-- Countries with Highest Infection Rate compared to their Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount, Max(cast((total_cases*100.0/NULLIF(population,0)) AS DECIMAL(18,2))) as PercentPopulationInfected ---at max infection
From Covid_Project..[CovidDeaths _Alex_Version]
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc


--1/26/24 Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From Covid_Project..[CovidDeaths _Alex_Version]
--Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc



-- 1/26/24BREAKING THINGS DOWN BY CONTINENT showing continents  highest death counts. 1st hard query.
-- Showing contintents with the highest death count per population
--revised
Select location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From Covid_Project..[CovidDeaths _Alex_Version]
--Where location like '%states%'
Where continent is  null 
Group by location
order by TotalDeathCount desc



--1/26/24 GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, CAST(SUM(new_deaths) AS DECIMAL(18,2))/NULLIF(SUM(New_Cases),0)*100.00 as DeathPercentage
From Covid_Project..[CovidDeaths _Alex_Version]
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Covid_Project..[CovidDeaths _Alex_Version] as dea
Join  Covid_Project..CovidVaccinations_Alex_Version as vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3

---
-- Using CTE to perform Calculation on Partition By in previous query
--see code above noticed commented out cde it doesn't work if you include it
--the point of including it  was to create a percentage of the number of peoplw who had recieved at least one vaccine.
--- but you can't do that because you can't run a query on a table that is just created using a CTE creates the table and run a query
-- on it at the same time, Here a CTE would come in handy to create the table and create the querythe percentage.
---
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated

From Covid_Project..[CovidDeaths _Alex_Version] as dea
Join  Covid_Project..CovidVaccinations_Alex_Version as vac

	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *,( cast(RollingPeopleVaccinated AS DECIMAL(18,2))/NULLIF(Population,0) )*100.00 as Percentage_Vaccinated_in_Population
From PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query
--temp table is similar to cte in that it creates a table and allows you to run query on it in one go
--but also stores the table in memory so its accessabile when still connected to server.
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Covid_Project..[CovidDeaths _Alex_Version] as dea
Join  Covid_Project..CovidVaccinations_Alex_Version as vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100 AS Vaccination_percent_rate
From #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Covid_Project..[CovidDeaths _Alex_Version] as dea
Join  Covid_Project..CovidVaccinations_Alex_Version as vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 




---The temp table and CTE and View all do the same things calculate the percentage of vaccinated population. or who had at least one vaccine.
