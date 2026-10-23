# SQL Projekt – Životní úroveň občanů v ČR

Tento projekt je mým výstupem v rámci kurzu datové analytiky Engeto. Cílem bylo propojit rozsáhlá data o mzdách a cenách potravin v České republice, vytvořit dvě čisté výstupní tabulky v databázi a odpovědět na pět výzkumných otázek týkajících se kupní síly a makroekonomického vývoje.

---

## 1. Moje cesta a zpracování projektu

Když jsem se do projektu pustila, byla to pro mě obrovská výzva a zkušenost. Ze začátku jsem si nebyla zcela jistá postupem, zkoušela jsem různé přístupy a chvílemi bojovala i se správným použitím příkazů jako `DROP TABLE` nebo s tím, jak přesně tabulky usadit do databáze, aby v systému držením nevznikaly chyby.

Díky postupnému zkoušení, ladění dotazů a opravám se mi podařilo data správně transformovat, vyčistit a vytvořit dvě pevné finální tabulky:
* `t_miroslava_pechova_project_SQL_primary_final` – sjednocená data o mzdách a cenách potravin v ČR za společná porovnatelná období.
* `t_miroslava_pechova_project_SQL_secondary_final` – doplňující makroekonomická data (HDP, GINI koeficient, daňová zátěž) pro evropské státy.

---

## 2. Výzkumné otázky – Metodika a výsledky

### Otázka 1: Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?

#### Jak jsem k tomu dospěla (Postup v SQL):
1. Vycházela jsem z primární tabulky `t_miroslava_pechova_project_SQL_primary_final` (vzniklé propojením tabulek `czechia_payroll` a `czechia_payroll_industry_branch` přes `industry_branch_code = code`).
2. Vyfiltrovala jsem data pro průměrné hrubé mzdy (`value_type_code = 5958`) a kalkulaci na přepočtené osoby.
3. Pomocí analytické funkce `LAG()` jsem pro každé odvětví spočítala průměrnou mzdu v předchozím roce a vypočítala meziroční percentuální změnu: `((mzda_aktualni - mzda_predchozi) / mzda_predchozi) * 100`.
4. Výsledky jsem seřadila podle odvětví a let, abych identifikovala roky se záporným růstem.

#### Výsledek z dat:
Většina odvětví zaznamenala v celkovém součtu mezi lety 2006 a 2018 růst mezd. **Neplatí však, že by mzdy rostly nepřetržitě každý rok ve všech odvětvích.** 

V průběhu sledovaných let došlo k meziročním poklesům mezd v několika odvětvích (nejčastěji v krizových letech 2009–2010 a 2013):
* **Peněžnictví a pojišťovnictví:** v roce 2013 zaznamenalo největší propad o **-8,83 %** (z 50 800,50 Kč na 46 316,50 Kč).
* **Výroba a rozvod elektřiny, plynu, tepla a klimatiz. vzduchu:** propad v roce 2013 o **-4,44 %** a v roce 2015 o **-1,56 %**.
* **Těžba a dobývání:** poklesy v letech 2009 (**-3,12 %**), 2013 (**-3,24 %**) a 2016 (**-0,57 %**).
* **Profesní, vědecké a technické činnosti:** pokles v roce 2013 o **-3,02 %** a v roce 2010 o **-0,60 %**.
* **Veřejná správa a obrana; povinné sociální zabezpečení:** poklesy v letech 2010 (**-0,34 %**) a 2011 (**-2,27 %**).
* **Stavebnictví:** pokles v roce 2013 o **-2,06 %**.
* Poklesy se v jednotlivých letech objevily i v odvětvích *Vzdělávání* (2010: -1,68 %), *Činnosti v oblasti nemovitostí* (2013: -1,78 %), *Kulturní, zábavní a rekreační činnosti* (2013: -1,43 %), *Administrativní a podpůrné činnosti* (2013: -1,24 %) či *Ubytování, stravování a pohostinství* (2009: -1,11 %).

---

### Otázka 2: Kolik je možné si koupit litrů mléka a kg chleba za první a poslední srovnatelné období?

#### Jak jsem k tomu dospěla (Postup v SQL):
1. Určila jsem první (rok 2006) a poslední (rok 2018) společný srovnatelný rok pro ceny potravin a mzdy.
2. Vyfiltrovala jsem průměrné průměrné mzdy za celou ČR v daných letech (agregací přes odvětví).
3. Vyfiltrovala jsem průměrné ceny pro konkrétní kategorie potravin z `czechia_price` (Chléb konzumní kmínový – kód 111301 a Mléko polotučné pasterované – kód 114201).
4. Vypočítala jsem kupní sílu podílem: `průměrná_mzda / průměrná_cena_potraviny`.

#### Výsledek z dat:
* **Chléb konzumní kmínový:** V roce 2006 si bylo možné za průměrnou mzdu koupit **1 313 kg**, zatímco v roce 2018 to bylo **1 365 kg**.
* **Mléko polotučné pasterované:** V roce 2006 bylo možné koupit **1 466 l**, v roce 2018 pak **1 670 l**.
* **Závěr:** Kupní síla obyvatel u obou základních potravin mezi lety 2006 a 2018 mírně vzrostla.

---

### Otázka 3: Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?

#### Jak jsem k tomu dospěla (Postup v SQL):
1. Pro každou kategorii potravin (`czechia_price_category`) jsem vypočítala průměrnou cenu v jednotlivých letech.
2. Pomocí `LAG()` jsem změřila meziroční percentuální změnu ceny pro každý rok a každou potravinu.
3. Spočítala jsem průměrnou meziroční změnu ceny za celé období 2006–2018 pro každou potravinu zvlášť.
4. Výsledky jsem seřadila vzestupně (`ORDER BY prumerny_narust ASC`), čímž se na prvním místě zobrazila potravina s nejnižším (případně nejvíce záporným) nárůstem.

#### Výsledek z dat:
Nejpomaleji zdražující potravinou je **Cukr krystalový** s průměrným meziročním nárůstem **-1,92 %** (jeho cena tedy v průměru meziročně klesala). Druhou potravinou s poklesem ceny byla **Rajská jablka červená kulatá** (-0,74 %). Naopak nejrychleji ze všech sledovaných potravin zdražovaly **Papriky** (+7,29 %) a **Máslo** (+6,68 %).

---

### Otázka 4: Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (o více než 10 %)?

#### Jak jsem k tomu dospěla (Postup v SQL):
1. Vypočítala jsem celkový průměrný meziroční růst mezd v ČR pro každý rok.
2. Vypočítala jsem celkový průměrný meziroční růst cen všech potravin pro každý rok.
3. Propojila jsem tyto dva roční růsty a spočítala jejich rozdíl: `procento_rustu_cen - procento_rustu_mezd`.
4. Filtrovala jsem roky, kde by tento rozdíl byl větší než 10 procentních bodů.

#### Výsledek z dat:
**Ne, takový rok v datech neexistuje.** 

Nejvyšší rozdíl v neprospěch mezd nastal v roce 2017, kdy ceny potravin vzrostly o **9,63 %** a mzdy o **6,17 %** (rozdíl 3,46 %). Hranice 10 % rozdílu nebyla ani v jednom roce překročena.

---

### Otázka 5: Má výška HDP vliv na změny ve mzdách a cenách potravin?

#### Jak jsem k tomu dospěla (Postup v SQL):
1. Z tabulky `economies` (zahrnuté v mé sekundární tabulce `t_miroslava_pechova_project_SQL_secondary_final`) jsem vytáhla roční HDP pro Českou republiku.
2. Pomocí `LAG()` jsem spočítala meziroční percentuální růst HDP v ČR.
3. Propojila jsem meziroční růst HDP, meziroční růst mezd a meziroční růst cen potravin do jedné přehledné tabulky podle let.
4. Porovnala jsem vývoj HDP a jeho projevy na mzdy a ceny ve stejném roce i v roce následujícím.

#### Výsledek z dat:
**Ano, vliv HDP je v datech jasně patrný.** 

* **Krizový rok 2009:** HDP kleslo o **-4,66 %**, na což s mírným odstupem zareagovaly ceny potravin prudkým poklesem o **-6,41 %** a růst mezd výrazně zpomalil na **3,07 %**.
* **Období růstu (2015–2017):** V roce 2015 HDP silně vzrostlo o **5,39 %**. Tento ekonomický růst se s odstupem 1 roku naplno promítl do zrychlení růstu mezd (v letech 2017–2018 rostly o **6,17 % až 7,70 %**) a v roce 2017 i do růstu cen potravin o **9,63 %**.
* **Závěr:** Výraznější skok v HDP podporuje kupní sílu a zrychluje jak mzdový růst, tak následně i růst cen potravin s odstupem přibližně 1 roku.
