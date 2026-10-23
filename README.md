# Engeto SQL Projekt – Analýza mezd a cen potravin v ČR

Tento projekt se zabývá analýzou vývoje mezd a cen vybraných potravinářských kategorií v České republice na základě dat z databáze PostgreSQL.

## Výzkumné otázky a zjištění

1. **Rostou mzdy ve všech odvětvích, nebo v některých klesají?**
   * Mzdy v dlouhodobém horizontu ve většině odvětví rostou, nicméně v některých letech došlo k přechodnému poklesu (např. v letech 2009 a 2013).

2. **Kolik kg chleba a litrů mléka si lze koupit za první a poslední srovnatelné období?**
   * Na základě porovnání prvního a posledního dostupného období srovnávacího souboru byla vypočtena přesná kupní síla pro tyto základní potraviny.

3. **Která kategorie potravin zdražuje nejpomaleji (má nejnižší procentuální meziroční nárůst)?**
   * Cukr se ukázal jako kategorie potravin s nejnižším procentuálním meziročním nárůstem ceny.

4. **Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?**
   * Analýza potvrdila konkrétní meziroční výkyvy a identifikovala období, kdy růst cen potravin překročil tempo růstu průměrných mezd.

5. **Má výška HDP vliv na změny ve mzdách a cenách potravin?**
   * Vývoj HDP ukazuje korelace s vývojem mezd i cen potravin, s mírným časovým zpožděním u spotřebitelských cen.

## Soubory v repozitáři
* `projekt_sql.sql` – Finální SQL skript obsahující všechny potřebné dotazy a transformace nad tabulkami `czechia_payroll` a `czechia_price`.