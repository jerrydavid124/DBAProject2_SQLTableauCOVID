--- Checking out my CovidDeaths DB 

SELECT * FROM CovidDeaths;

SELECT continent, location FROM CovidDeaths GROUP BY continent,location ORDER BY continent;


--- Checking out What percentage of the population has died from COVID over time: Total Deaths / Total Cases 

CREATE VIEW PercentTotalDeaths AS 
SELECT 
	total_cases,
	total_deaths,
	(total_deaths/total_cases)*100 AS PercentTotalDeath,
	Date
FROM
	CovidDeaths
WHERE
	location = 'United States' AND Continent IS NOT NULL
ORDER BY 
	Date;



--- Checking out how much of the US has been infected over time 

CREATE VIEW PercentTotalInfection AS 
SELECT 
	population,
	total_cases,
	(total_cases/population)*100 AS PercentTotalInfection,
	Date
FROM
	CovidDeaths
WHERE
	location = 'United States' AND Continent IS NOT NULL
ORDER BY 
	Date;


--- Now what country has had the largest portion of people infected based on population [re-infection included]

CREATE VIEW TotalInfectionPercent AS
SELECT 
	MAX(population) AS Population,
	MAX(total_cases) AS TotalInfections,
	MAX(total_cases/population)*100 AS TotalInfectionPercent,
	Location

FROM
	CovidDeaths
WHERE
	Continent IS NOT NULL
GROUP BY
	Location
ORDER BY 
	TotalInfectionPercent DESC;

--- Now what percentage of the population has died from COVID By Country

CREATE VIEW TotalDeathPercent AS 
SELECT 
	MAX(population) AS Population,
	MAX(cast(total_deaths as int)) AS TotalDeaths,
	MAX(cast(total_deaths as int)/population)*100 AS TotalDeathPercent,
	Location

FROM
	CovidDeaths
WHERE 
	Continent IS NOT NULL
GROUP BY
	Location
ORDER BY 
	TotalDeathPercent DESC;


---  Ok, now for the major regions of the world cases deaths and those percentages of the population 

CREATE VIEW Major_Regions AS
SELECT 
	location,
	MAX(population) AS Population,
	MAX(total_cases) AS TotalCases,
		MAX(total_cases/population)*100 AS TotalInfectionPercent,
	MAX(cast(total_deaths as int)) AS TotalDeaths,
	MAX(cast(total_deaths as int)/population)*100 AS TotalDeathPercent
FROM
	CovidDeaths
WHERE 
	continent IS NULL
GROUP BY
	location
ORDER BY 
	Population DESC;


--- Now looking at my CovidVaccinations table

SELECT * FROM CovidVaccinations;


--- Wanting to get Joins going 

SELECT 
	CovidDeaths.continent,
	CovidDeaths.location,
	CovidDeaths.date,
	CovidDeaths.population,
	CovidVaccinations.new_vaccinations,
	CovidVaccinations.gdp_per_capita,
	CovidVaccinations.handwashing_facilities
	
FROM 
	CovidDeaths
JOIN 
	CovidVaccinations ON CovidDeaths.location = CovidVaccinations.location AND CovidDeaths.date = CovidVaccinations.date
WHERE
	CovidDeaths.continent IS NOT NULL
ORDER BY 
	CAST(CovidVaccinations.new_vaccinations as int) DESC;


--- Now trying to do a rolling total of New_Vaccinations ordering by Location/Date 


SELECT 
	CovidDeaths.continent,
	CovidDeaths.location,
	CovidDeaths.date,
	CovidVaccinations.new_vaccinations,
	SUM(CONVERT(float,CovidVaccinations.new_vaccinations)) OVER (Partition by CovidDeaths.location ORDER BY CovidDeaths.location, CovidDeaths.date) AS RollingVaccinations
FROM 
	CovidDeaths
JOIN 
	CovidVaccinations ON CovidDeaths.location = CovidVaccinations.location AND CovidDeaths.date = CovidVaccinations.date
WHERE
	CovidDeaths.continent IS NOT NULL AND CovidDeaths.Location = 'United States'
ORDER BY 
	CovidDeaths.Location,CovidDeaths.date;


--- Now use the rolling total to find percent of vaccinated population over time using a CTE 

CREATE VIEW RollingUSVaccinations AS
WITH CTE AS 
(
SELECT 
	CovidDeaths.continent AS Continent,
	CovidDeaths.location AS Location,
	CovidDeaths.date AS Date,
	CovidDeaths.population AS Population,
	CovidVaccinations.new_vaccinations AS New_Vaccinations,
	SUM(CONVERT(float,CovidVaccinations.new_vaccinations)) OVER (Partition by CovidDeaths.location ORDER BY CovidDeaths.location, CovidDeaths.date) AS RollingVaccinations
FROM 
	CovidDeaths
JOIN 
	CovidVaccinations ON CovidDeaths.location = CovidVaccinations.location AND CovidDeaths.date = CovidVaccinations.date
WHERE
	CovidDeaths.continent IS NOT NULL
) 
SELECT *, (RollingVaccinations/Population) * 100 AS RollingPercentVaccinated
FROM CTE
WHERE Location = 'United States'
ORDER BY Location, Date; 


