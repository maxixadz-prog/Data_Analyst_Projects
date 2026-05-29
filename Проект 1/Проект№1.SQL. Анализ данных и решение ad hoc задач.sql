/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Захаров Максим 
 * Дата: 10.10.2025
*/

-- Часть 1. Исследовательский анализ данных


---------------------------------------Задача 1. Исследование доли платящих игроков--------------------------------------


-- 1.1. Доля платящих пользователей по всем данным:
SELECT
COUNT(payer) AS total_users, -- общее количество игроков
SUM(payer) AS total_payers, -- количество платящих (сумма единичек)
AVG(payer) AS payers_share -- доля платящих (среднее значение)
FROM fantasy.users;
-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
SELECT
r.race,--раса персонажа
SUM(u.payer) as payer_sum,--кол-во платящих игроков этой расы
COUNT(*) as total_users,--общее кол-во зарегистрированных игроков этой расы
ROUND(SUM(u.payer)*100.0/COUNT(*),2) as dolia_payers_race --доля платящих игроков среди всех зарегистрированных игроков этой расы
FROM fantasy.users as u
JOIN fantasy.race as r 
ON  u.race_id = r.race_id 
GROUP BY  r.race
ORDER BY dolia_payers_race;










------------------------------------- Задача 2. Исследование внутриигровых покупок-----------------------------------------------------------------------------------

-- 2.1. Статистические показатели по полю amount:
SELECT 
    COUNT(*) AS total_purchases,--Общее ко-во покупок 
    SUM(amount) AS total_amount,--Суммарная стоимость всех покупок
    MIN(amount) AS min_amount, --Минимальная стоимость покупки
    MAX(amount) AS max_amount, --Максимальная стоимость покупки
    ROUND(AVG(amount) ::numeric, 2) AS avg_amount, -- Среднее значение
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY amount) AS median_amount, --Медиана
    ROUND(STDDEV(amount) ::numeric, 2) AS stddev_amount --Стандартное отклонение стоимости покупки
FROM fantasy.events;

-- 2.2: Аномальные нулевые покупки:
SELECT 
COUNT(CASE WHEN amount = 0 THEN 1 END) AS zero_amount_count,--Абсолютное кол-во покупок 
COUNT(CASE WHEN amount = 0 THEN 1 END) *100.0/ COUNT(*) AS dolia_ot_amount --Находим долю от общего числа покупок
FROM fantasy.events;

-- 2.3: Популярные эпические предметы:
WITH popular_epic_items AS ( --Игроки,которые совершают ненулевые покупки
    SELECT 
        COUNT(DISTINCT id) AS total_unique_buyers,
        COUNT(*) AS total_pokupki
    FROM fantasy.events 
    WHERE amount > 0
)
SELECT --Игроки,которые предмет покупают
    i.item_code,
    i.game_items AS item_name,
    COUNT(*) AS sales_count,
    ROUND(COUNT(*) * 100.0 / pei.total_pokupki, 2) AS sales_otnos,
    COUNT(DISTINCT e.id) AS unique_buyers_count,  
    ROUND(COUNT(DISTINCT e.id) * 100.0 / pei.total_unique_buyers, 2) AS buyers_percentage  
FROM fantasy.events AS e 
JOIN fantasy.items AS i ON e.item_code = i.item_code 
CROSS JOIN popular_epic_items AS pei 
WHERE amount > 0 
GROUP BY i.item_code, i.game_items, pei.total_unique_buyers, pei.total_pokupki
ORDER BY buyers_percentage DESC, sales_count DESC;


---------------------------------------- --------------Задача: Зависимость активности игроков от расы персонажа:-------------------------------------------------------------------
-- Задача: Зависимость активности игроков от расы персонажа
WITH players AS (
    -- Считаем общее кол-во зарегистрированных игроков 
    SELECT  
        race_id,  
        COUNT(*) AS total_players 
    FROM fantasy.users 
    GROUP BY race_id  
),
buyers AS (
    -- Считаем кол-во игроков, совершающих внутриигровые покупки
    SELECT
        u.race_id,
        COUNT(DISTINCT u.id) AS buyers_count 
    FROM fantasy.users AS u  
    JOIN fantasy.events AS e  
    ON u.id = e.id 
    WHERE e.amount > 0
    GROUP BY u.race_id 
),
paying_buyers AS (
    SELECT 
        u.race_id,
        COUNT(DISTINCT u.id) AS paying_buyers_count 
    FROM fantasy.users AS u 
    JOIN fantasy.events AS e 
    ON u.id = e.id 
    WHERE e.amount > 0 AND u.payer = 1  
    GROUP BY u.race_id
),
purchase_stats AS (
    SELECT 
        u.race_id,
        COUNT(*) AS total_purchases,  
        SUM(e.amount) AS total_amount 
    FROM fantasy.users AS u
    JOIN fantasy.events AS e ON u.id = e.id  
    WHERE e.amount > 0  
    GROUP BY u.race_id  
)
SELECT 
    r.race AS race_name,
    p.total_players AS total_players,
    b.buyers_count,
    ROUND((b.buyers_count * 100.0 / p.total_players)::numeric, 2) AS buyers_percent,
    ROUND((pb.paying_buyers_count * 100.0 / b.buyers_count)::numeric, 2) AS paying_buyers_percent,
    ROUND((ps.total_purchases * 1.0 / b.buyers_count)::numeric, 2) AS avg_purchases_per_buyer,
    ROUND((ps.total_amount * 1.0 / ps.total_purchases)::numeric, 2) AS avg_purchase_amount,
    ROUND((ps.total_amount * 1.0 / b.buyers_count)::numeric, 2) AS avg_total_spent_per_buyer
FROM fantasy.race r
JOIN players p ON r.race_id = p.race_id
JOIN buyers b ON r.race_id = b.race_id
LEFT JOIN paying_buyers pb ON r.race_id = pb.race_id 
JOIN purchase_stats ps ON r.race_id = ps.race_id
ORDER BY avg_total_spent_per_buyer DESC;



























)







