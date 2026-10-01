/*
    COVID-19 Global Data Analysis
    --------------------------------
    Exploratory SQL analysis of cases, deaths, population, and vaccinations.

    Main techniques demonstrated:
      - filtering and aggregation
      - joins
      - window functions
      - CTEs
      - temporary tables
      - views for visualization

    Note: table names below reflect the names used in the original SQL Server project.
*/

-- 1. Core case/death fields
SELECT
    location,
    date,
    total_cases,
    new_cases,
    total_deaths,
    population
FROM CovidDeaths
ORDER BY location, date;


-- 2. Case fatality percentage by location and date
SELECT
    location,
    date,
    total_cases,
    total_deaths,
    (CAST(total_deaths AS float) / NULLIF(total_cases, 0)) * 100 AS case_fatality_pct
FROM CovidDeaths
WHERE total_cases >= 1000000
ORDER BY case_fatality_pct DESC;


-- 3. Share of population with recorded cases
SELECT
    location,
    date,
    total_cases,
    population,
    (CAST(total_cases AS float) / NULLIF(population, 0)) * 100 AS population_infected_pct
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY population_infected_pct DESC;


-- 4. Highest recorded infection percentage by location
SELECT
    location,
    population,
    MAX(total_cases) AS highest_recorded_cases,
    MAX((CAST(total_cases AS float) / NULLIF(population, 0)) * 100) AS highest_infected_pct
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY highest_infected_pct DESC;


-- 5. Highest recorded deaths and deaths as a share of population
SELECT
    location,
    population,
    MAX(CAST(total_deaths AS int)) AS highest_recorded_deaths,
    MAX((CAST(total_deaths AS float) / NULLIF(population, 0)) * 100) AS population_death_pct
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY population_death_pct DESC;


-- 6. Aggregate rows such as continents / world regions in the source data
SELECT
    location,
    MAX(CAST(total_deaths AS int)) AS highest_recorded_deaths
FROM CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY highest_recorded_deaths DESC;


-- 7. Global daily cases, deaths, and case fatality percentage
SELECT
    date,
    SUM(new_cases) AS new_cases,
    SUM(CAST(new_deaths AS int)) AS new_deaths,
    (CAST(SUM(CAST(new_deaths AS int)) AS float) / NULLIF(SUM(new_cases), 0)) * 100
        AS daily_case_fatality_pct
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;


-- 8. Global totals across the observation period
SELECT
    SUM(new_cases) AS total_cases,
    SUM(CAST(new_deaths AS int)) AS total_deaths,
    (CAST(SUM(CAST(new_deaths AS int)) AS float) / NULLIF(SUM(new_cases), 0)) * 100
        AS overall_case_fatality_pct
FROM CovidDeaths
WHERE continent IS NOT NULL;


-- 9. Join deaths/cases data to vaccination data
SELECT
    dea.date,
    dea.location,
    dea.population,
    vac.new_vaccinations
FROM CovidDeaths AS dea
INNER JOIN covidvaccine AS vac
    ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date;


-- 10. Running vaccination count by location
SELECT
    dea.date,
    dea.location,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS bigint)) OVER (
        PARTITION BY dea.location
        ORDER BY dea.date
        ROWS UNBOUNDED PRECEDING
    ) AS rolling_vaccinations
FROM CovidDeaths AS dea
INNER JOIN covidvaccine AS vac
    ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date;


-- 11. CTE: rolling vaccinations as a percentage of population
WITH PopulationVsVaccination AS (
    SELECT
        dea.date,
        dea.location,
        dea.population,
        vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS bigint)) OVER (
            PARTITION BY dea.location
            ORDER BY dea.date
            ROWS UNBOUNDED PRECEDING
        ) AS rolling_vaccinations
    FROM CovidDeaths AS dea
    INNER JOIN covidvaccine AS vac
        ON dea.location = vac.location
       AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT
    *,
    (CAST(rolling_vaccinations AS float) / NULLIF(population, 0)) * 100
        AS rolling_vaccinations_per_population_pct
FROM PopulationVsVaccination
ORDER BY location, date;


-- 12. Temporary table version for downstream exploration
DROP TABLE IF EXISTS #PopulationVaccination;

CREATE TABLE #PopulationVaccination (
    date datetime,
    population numeric,
    location nvarchar(255),
    new_vaccinations numeric,
    rolling_vaccinations numeric
);

INSERT INTO #PopulationVaccination
SELECT
    dea.date,
    dea.population,
    dea.location,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS bigint)) OVER (
        PARTITION BY dea.location
        ORDER BY dea.date
        ROWS UNBOUNDED PRECEDING
    )
FROM CovidDeaths AS dea
INNER JOIN covidvaccine AS vac
    ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT
    *,
    (CAST(rolling_vaccinations AS float) / NULLIF(population, 0)) * 100
        AS rolling_vaccinations_per_population_pct
FROM #PopulationVaccination
ORDER BY location, date;


-- 13. View for reuse in visualization / dashboard work
CREATE VIEW PopulationVaccinationProgress AS
SELECT
    dea.date,
    dea.population,
    dea.location,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS bigint)) OVER (
        PARTITION BY dea.location
        ORDER BY dea.date
        ROWS UNBOUNDED PRECEDING
    ) AS rolling_vaccinations
FROM CovidDeaths AS dea
INNER JOIN covidvaccine AS vac
    ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;
