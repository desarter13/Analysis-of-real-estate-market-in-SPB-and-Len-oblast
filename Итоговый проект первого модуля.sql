-- Задача 1: Время активности объявлений
-- Определим аномальные значения (выбросы) по значению перцентилей:

-- Найдём id объявлений, которые не содержат выбросы, также оставим пропущенные данные:

-- Продолжите запрос здесь
-- Используйте id объявлений (СТЕ filtered_id), которые не содержат выбросы при анализе данных
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats
),

filtered_id AS (
    SELECT id
    FROM real_estate.flats f
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND (
            (ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
             AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits))
            OR ceiling_height IS NULL
        )
),

base AS (
    SELECT 
        a.id,
        a.first_day_exposition,
        a.days_exposition,
        a.last_price,
        f.total_area,
        f.rooms,
        f.balcony,
        f.ceiling_height,
        c.city,
        t.type
    FROM real_estate.advertisement a
    JOIN real_estate.flats f ON f.id = a.id
    JOIN real_estate.city c ON c.city_id = f.city_id
    JOIN real_estate.type t ON t.type_id = f.type_id
    WHERE a.id IN (SELECT id FROM filtered_id)
      AND EXTRACT(YEAR FROM a.first_day_exposition) BETWEEN 2015 AND 2018
      AND t.type = 'город'
),

prepared AS (
    SELECT *,
        CASE 
            WHEN city = 'Санкт-Петербург' THEN 'SPB'
            ELSE 'Leningrad_region'
        END AS region,

        CASE
            WHEN days_exposition BETWEEN 1 AND 30 THEN '1-30 days'
            WHEN days_exposition BETWEEN 31 AND 90 THEN '31-90 days'
            WHEN days_exposition BETWEEN 91 AND 180 THEN '91-180 days'
            WHEN days_exposition >= 181 THEN '181+ days'
            ELSE 'non category'
        END AS activity_category,

        last_price / NULLIF(total_area, 0) AS price_per_sqm
    FROM base
)

SELECT 
    region,
    activity_category,
    COUNT(*) AS ads_cnt,
    AVG(price_per_sqm) AS avg_price_per_sqm,
    AVG(total_area) AS avg_area,
    AVG(rooms) AS avg_rooms,
    AVG(balcony) AS avg_balcony
FROM prepared
GROUP BY region, activity_category
ORDER BY region, activity_category;
/*
|region          |activity_category|ads_cnt|avg_price_per_sqm |avg_area     |avg_rooms   |avg_balcony |
|----------------|-----------------|-------|------------------|-------------|------------|------------|
|Leningrad_region|1-30 days        |340    |71 907,6290383732 |48,7518824353|1,7441176471|1,0297029703|
|Leningrad_region|181+ days        |873    |68 215,10521594   |55,0257960819|2,0103092784|0,9102296451|
|Leningrad_region|31-90 days       |864    |67 423,8001042119 |50,8535185081|1,8888888889|0,9395348837|
|Leningrad_region|91-180 days      |553    |69 809,295059618  |51,8291500912|1,896925859 |0,9161490683|
|Leningrad_region|non category     |198    |72 925,8939147333 |62,7750000328|2,202020202 |1,6071428571|
|SPB             |1-30 days        |1 794  |108 919,7815679   |54,656137097 |1,8745819398|1,000893655 |
|SPB             |181+ days        |3 506  |114 981,0719063079|65,7635881459|2,1665715916|0,9185737094|
|SPB             |31-90 days       |3 020  |110 874,3192906664|56,5837814438|1,9139072848|0,9903381643|
|SPB             |91-180 days      |2 244  |111 973,6725625975|60,5463145863|2,0298573975|0,9443585781|
|SPB             |non category     |653    |136 107,6621662041|81,3822204274|2,4762633997|1,6134969325|

 */

-- Задача 2: Сезонность объявлений
-- Определим аномальные значения (выбросы) по значению перцентилей:

-- Найдём id объявлений, которые не содержат выбросы, также оставим пропущенные данные:

-- Продолжите запрос здесь
-- Используйте id объявлений (СТЕ filtered_id), которые не содержат выбросы при анализе данных
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats
),

filtered_id AS (
    SELECT id
    FROM real_estate.flats f
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND (
            (ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
             AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits))
            OR ceiling_height IS NULL
        )
),

base AS (
    SELECT 
        a.id,
        a.first_day_exposition,
        a.days_exposition,
        f.total_area,
        a.last_price,
        c.city,
        t.type
    FROM real_estate.advertisement a
    JOIN real_estate.flats f ON f.id = a.id
    JOIN real_estate.city c ON c.city_id = f.city_id
    JOIN real_estate.type t ON t.type_id = f.type_id
    WHERE a.id IN (SELECT id FROM filtered_id)
      AND EXTRACT(YEAR FROM a.first_day_exposition) BETWEEN 2015 AND 2018
      AND t.type = 'город'
),

prep AS (
    SELECT *,
        (first_day_exposition + days_exposition * INTERVAL '1 day') AS close_date
    FROM base
),

pub AS (
    SELECT
        EXTRACT(MONTH FROM first_day_exposition) AS month,
        COUNT(*) AS ads_cnt,
        AVG(last_price / NULLIF(total_area, 0)) AS avg_price_per_sqm,
        AVG(total_area) AS avg_area
    FROM prep
    GROUP BY EXTRACT(MONTH FROM first_day_exposition)
),

close AS (
    SELECT
        EXTRACT(MONTH FROM close_date) AS month,
        COUNT(*) AS sold_cnt,
        AVG(last_price / NULLIF(total_area, 0)) AS avg_price_per_sqm,
        AVG(total_area) AS avg_area
    FROM prep
    WHERE days_exposition IS NOT NULL
    GROUP BY EXTRACT(MONTH FROM close_date)
)

SELECT 
    p.month,
    p.ads_cnt AS published_ads,
    c.sold_cnt AS closed_ads,
    p.avg_price_per_sqm AS pub_price,
    c.avg_price_per_sqm AS close_price
FROM pub p
LEFT JOIN close c USING (month)
ORDER BY p.month;


/* 
|month|published_ads|closed_ads|pub_price         |close_price       |
|-----|-------------|----------|------------------|------------------|
|1    |735          |1 225     |106 106,2447305485|104 947,3093510842|
|2    |1 369        |1 048     |103 058,5104126244|103 883,7231594406|
|3    |1 119        |1 071     |102 429,9471818448|106 832,4013744821|
|4    |1 021        |1 031     |102 632,4143064015|102 444,2380207702|
|5    |891          |729       |102 465,1220461998|99 724,0659079218 |
|6    |1 224        |771       |104 802,1513823466|101 863,6873467392|
|7    |1 149        |1 108     |104 488,9585543135|102 290,7235570143|
|8    |1 166        |1 137     |107 034,700534513 |100 036,5131908943|
|9    |1 341        |1 238     |107 563,1201390345|104 070,065600862 |
|10   |1 437        |1 360     |104 065,1092601503|104 317,3305613798|
|11   |1 569        |1 301     |105 048,8016501354|103 791,359654983 |
|12   |1 024        |1 175     |104 775,3931875229|105 504,5233469082|

*/