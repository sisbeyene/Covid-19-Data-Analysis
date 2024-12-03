select *
from CovidDeaths
order by 3

select *
from Covid_vacine
order by 3

select location,date, total_cases,new_cases,total_deaths,population
from CovidDeaths
order by 1

--total death per total cases in percentage
--for countries who recorded more than 1million cases, the highest death percentage ratio is about 11.12270-- which is recorded in European Union with 0.8278-- being lowest recorded in turkey

select location,date, total_cases,total_deaths, (total_deaths/total_cases)*100 as death_rate
from CovidDeaths
where total_cases>'1000000'
order by death_rate desc

--total cases per total population
--shows the percentage of people affected in covid-19
--maximum percentage being 17.12+ in Andorra recorded on 2021-04-30

select location,date, total_cases,population, (total_cases/population)*100 as affection_rate
from CovidDeaths
order by affection_rate desc

 --showing maximum percentage of cases grouping by location and population

 select location,population, max(total_cases) as maximum, max((total_cases/population)*100) as affection_rate
from CovidDeaths
where continent is not null
group by location,population 
order by affection_rate desc

--highest death percentage per population

select location,max(cast(total_deaths as int)) as maximum_deaths,population, max(total_deaths/population) as population_death_ratio
from CovidDeaths
where continent is not null
group by location,population
order by population_death_ratio desc

--maximum deaths per continent

select location,max(cast(total_deaths as int)) as maximum_deaths
from CovidDeaths
where continent is null
group by location
order by maximum_deaths desc

--total deaths per conitnents

select location,sum(cast(total_deaths as int)) as total_deaths
from CovidDeaths
where continent is null
group by location
order by total_deaths desc

--global numbers
--sum of new cases per day
--sum of new deaths per day
--percentage death per new cases per day

select date,sum(new_cases) as total_new_cases,sum(cast(new_deaths as int)) as total_new_deaths,(sum(cast(new_deaths as int))/sum(new_cases))*100 as percentage_death
from CovidDeaths
where continent is not null
group by date
order by total_new_cases desc

--total new cases
--total new deaths and percentage death per cases

select sum(new_cases) as total_new_cases,sum(cast(new_deaths as int)) as total_new_deaths,(sum(cast(new_deaths as int))/sum(new_cases))*100 as percentage_death
from CovidDeaths
where continent is not null
order by total_new_cases desc

--looking at total number of vacinations  

select dea.date,dea.population,dea.location,vac.new_vaccinations
from CovidDeaths dea
join covidvaccine vac
on dea.location=vac.location and dea.date=vac.date

--looking at total number of vacinations partition by location 

select dea.date,dea.population,dea.location,vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int))  over(partition by dea.location) as people_vaccinated
from CovidDeaths dea
join covidvaccine vac
on dea.location=vac.location and dea.date=vac.date

--use CTE
--finding people_vaccinated_to_population_ratio from popvsvac

with popvsvac(date,population,location,new_vaccinations,people_vaccinated)
as(
select dea.date,dea.population,dea.location,vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int))  over(partition by dea.location) as people_vaccinated
from CovidDeaths dea
join covidvaccine vac
on dea.location=vac.location and dea.date=vac.date
where dea.continent is not null
)
select *,(people_vaccinated/population) as people_vaccinated_to_population_ratio from popvsvac

--use temp table
--peperpor(percentage per population ratio)

drop table if exists #peperpor
create table #peperpor(date datetime,
population numeric,
location nvarchar(255),
new_vaccinations numeric,
people_vaccinated numeric)
insert into #peperpor
select dea.date,dea.population,dea.location,vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int))  over(partition by dea.location) as people_vaccinated
from CovidDeaths dea
join covidvaccine vac
on dea.location=vac.location and dea.date=vac.date
where dea.continent is not null

select * from #peperpor

--creating view for later to store data for visualization

create view peperpor as
select dea.date,dea.population,dea.location,vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int))  over(partition by dea.location) as people_vaccinated
from CovidDeaths dea
join covidvaccine vac
on dea.location=vac.location and dea.date=vac.date
where dea.continent is not null

