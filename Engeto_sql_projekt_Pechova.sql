-- 1. VYTVOŘENÍ PRIMÁRNÍ FINÁLNÍ TABULKY (Mzdy a ceny potravin v ČR)

DROP TABLE IF EXISTS t_miroslava_pechova_project_SQL_primary_final;

CREATE TABLE t_miroslava_pechova_project_SQL_primary_final AS
WITH payroll AS (
    SELECT 
        cp.payroll_year AS date_year,
        cp.industry_branch_code,
        cpib.name AS industry_branch_name,
        ROUND(AVG(cp.value)::numeric, 2) AS avg_payroll
    FROM data_academy_content.czechia_payroll AS cp
    JOIN data_academy_content.czechia_payroll_industry_branch AS cpib 
        ON cp.industry_branch_code = cpib.code
    WHERE cp.value_type_code = '5958'
      AND cp.unit_code = '200'
      AND cp.calculation_code = '200'
      AND cp.industry_branch_code IS NOT NULL
    GROUP BY 
        cp.payroll_year, 
        cp.industry_branch_code, 
        cpib.name
),
prices AS (
    SELECT 
        EXTRACT(YEAR FROM cpr.date_from)::int AS date_year,
        cpr.category_code,
        cpc.name AS category_name,
        cpc.price_value,
        cpc.price_unit,
        ROUND(AVG(cpr.value)::numeric, 2) AS avg_price
    FROM data_academy_content.czechia_price AS cpr
    JOIN data_academy_content.czechia_price_category AS cpc 
        ON cpr.category_code = cpc.code
    GROUP BY 
        EXTRACT(YEAR FROM cpr.date_from), 
        cpr.category_code, 
        cpc.name, 
        cpc.price_value, 
        cpc.price_unit
)
SELECT 
    pay.date_year,
    pay.industry_branch_code,
    pay.industry_branch_name,
    pay.avg_payroll,
    pr.category_code,
    pr.category_name,
    pr.price_value,
    pr.price_unit,
    pr.avg_price
FROM payroll AS pay
JOIN prices AS pr 
    ON pay.date_year = pr.date_year;



-- 2. VYTVOŘENÍ SEKUNDÁRNÍ FINÁLNÍ TABULKY (HDP a makroekonomika států)

DROP TABLE IF EXISTS t_miroslava_pechova_project_SQL_secondary_final;

CREATE TABLE t_miroslava_pechova_project_SQL_secondary_final AS
SELECT 
    e.country,
    e.year AS date_year,
    e.gdp,
    e.gini,
    e.taxes
FROM data_academy_content.economies AS e
JOIN data_academy_content.countries AS c
    ON e.country = c.country
WHERE c.continent = 'Europe'
  AND e.year BETWEEN '2006' AND '2018';



-- Otázka 1: Rostou mzdy ve všech odvětvích, nebo v některých klesají?
SELECT 
    sub.industry_branch_name,
    sub.date_year,
    sub.avg_payroll,
    LAG(sub.avg_payroll) OVER (
        PARTITION BY sub.industry_branch_name 
        ORDER BY sub.date_year
    ) AS prev_payroll,
    ROUND(
        (sub.avg_payroll - LAG(sub.avg_payroll) OVER (
            PARTITION BY sub.industry_branch_name 
            ORDER BY sub.date_year
        )) / LAG(sub.avg_payroll) OVER (
            PARTITION BY sub.industry_branch_name 
            ORDER BY sub.date_year
        ) * 100, 
        2
    ) AS pct_change
FROM (
    SELECT DISTINCT 
        date_year, 
        industry_branch_name, 
        avg_payroll 
    FROM t_miroslava_pechova_project_SQL_primary_final AS pf
) AS sub
ORDER BY 
    sub.industry_branch_name, 
    sub.date_year;




-- Otázka 2: Kolik je možné si koupit litrů mléka a kg chleba za první a poslední období?
SELECT 
    pf.date_year,
    pf.category_name,
    ROUND(AVG(pf.avg_payroll), 2) AS overall_avg_payroll,
    pf.avg_price,
    ROUND(AVG(pf.avg_payroll) / pf.avg_price, 0) AS units_bought,
    pf.price_unit
FROM t_miroslava_pechova_project_SQL_primary_final AS pf
WHERE pf.category_name IN ('Chléb konzumní kmínový', 'Mléko polotučné pasterované')
  AND pf.date_year IN ('2006', '2018')
GROUP BY 
    pf.date_year, 
    pf.category_name, 
    pf.avg_price, 
    pf.price_unit
ORDER BY 
    pf.category_name, 
    pf.date_year;




-- Otázka 3: Která kategorie potravin zdražuje nejpomaleji?
WITH yearly_prices AS (
    SELECT DISTINCT 
        date_year, 
        category_name, 
        avg_price
    FROM t_miroslava_pechova_project_SQL_primary_final AS pf
),
price_changes AS (
    SELECT 
        yp.category_name,
        yp.date_year,
        yp.avg_price,
        LAG(yp.avg_price) OVER (
            PARTITION BY yp.category_name 
            ORDER BY yp.date_year
        ) AS prev_price,
        ROUND(
            (yp.avg_price - LAG(yp.avg_price) OVER (
                PARTITION BY yp.category_name 
                ORDER BY yp.date_year
            )) / LAG(yp.avg_price) OVER (
                PARTITION BY yp.category_name 
                ORDER BY yp.date_year
            ) * 100, 
            2
        ) AS yearly_pct_increase
    FROM yearly_prices AS yp
)
SELECT 
    pc.category_name,
    ROUND(AVG(pc.yearly_pct_increase), 2) AS avg_yearly_growth_pct
FROM price_changes AS pc
WHERE pc.yearly_pct_increase IS NOT NULL
GROUP BY pc.category_name
ORDER BY avg_yearly_growth_pct ASC;



-- Otázka 4: Meziroční srovnání nárůstu cen potravin vs mezd
WITH yearly_aggregates AS (
    SELECT 
        sub.date_year,
        ROUND(AVG(sub.avg_payroll), 2) AS avg_payroll,
        ROUND(AVG(sub.avg_price), 2) AS avg_price
    FROM (
        SELECT DISTINCT 
            date_year, 
            industry_branch_name, 
            avg_payroll, 
            category_name, 
            avg_price
        FROM t_miroslava_pechova_project_SQL_primary_final AS pf
    ) AS sub
    GROUP BY sub.date_year
),
yoy_growth AS (
    SELECT 
        ya.date_year,
        ROUND(
            (ya.avg_payroll - LAG(ya.avg_payroll) OVER (ORDER BY ya.date_year)) 
            / LAG(ya.avg_payroll) OVER (ORDER BY ya.date_year) * 100, 
            2
        ) AS payroll_growth_pct,
        ROUND(
            (ya.avg_price - LAG(ya.avg_price) OVER (ORDER BY ya.date_year)) 
            / LAG(ya.avg_price) OVER (ORDER BY ya.date_year) * 100, 
            2
        ) AS price_growth_pct
    FROM yearly_aggregates AS ya
)
SELECT 
    yg.date_year,
    yg.payroll_growth_pct,
    yg.price_growth_pct,
    (yg.price_growth_pct - yg.payroll_growth_pct) AS growth_diff_pct
FROM yoy_growth AS yg
WHERE yg.date_year IS NOT NULL
ORDER BY yg.date_year;




-- Otázka 5: Vliv HDP na mzdy a ceny potravin v ČR
WITH czech_gdp AS (
    SELECT 
        sf.date_year, 
        sf.gdp 
    FROM t_miroslava_pechova_project_SQL_secondary_final AS sf
    WHERE sf.country = 'Czech Republic'
),
czech_payroll_price AS (
    SELECT 
        sub.date_year,
        ROUND(AVG(sub.avg_payroll)::numeric, 2) AS avg_payroll,
        ROUND(AVG(sub.avg_price)::numeric, 2) AS avg_price
    FROM (
        SELECT DISTINCT 
            date_year, 
            industry_branch_name, 
            avg_payroll, 
            category_name, 
            avg_price
        FROM t_miroslava_pechova_project_SQL_primary_final AS pf
    ) AS sub
    GROUP BY sub.date_year
)
SELECT 
    g.date_year,
    g.gdp,
    ROUND(
        ((g.gdp - LAG(g.gdp) OVER (ORDER BY g.date_year)) 
        / LAG(g.gdp) OVER (ORDER BY g.date_year) * 100)::numeric, 
        2
    ) AS gdp_growth_pct,
    ROUND(
        ((cp.avg_payroll - LAG(cp.avg_payroll) OVER (ORDER BY cp.date_year)) 
        / LAG(cp.avg_payroll) OVER (ORDER BY cp.date_year) * 100)::numeric, 
        2
    ) AS payroll_growth_pct,
    ROUND(
        ((cp.avg_price - LAG(cp.avg_price) OVER (ORDER BY cp.date_year)) 
        / LAG(cp.avg_price) OVER (ORDER BY cp.date_year) * 100)::numeric, 
        2
    ) AS price_growth_pct
FROM czech_gdp AS g
JOIN czech_payroll_price AS cp 
    ON g.date_year = cp.date_year
ORDER BY g.date_year;












