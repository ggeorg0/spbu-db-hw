CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    surname VARCHAR(255),
    patronym VARCHAR(255),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash CHAR(128) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);


-- create type for admin permissions
CREATE TYPE ADMIN_PERM_T AS ENUM ('read_only', 'dev');
-- Table of service admins. Separated from users.
CREATE TABLE admins (
    admin_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    surname VARCHAR(255),
    patronym VARCHAR(255),
    email VARCHAR(255) UNIQUE NOT NULL,
    admin_permissions ADMIN_PERM_T NOT NULL DEFAULT 'read_only',
    is_super_admin BOOLEAN DEFAULT FALSE
);


-- Prices and currencies
CREATE TABLE currencies (
    cur_id SERIAL PRIMARY KEY,
    label CHAR(3) UNIQUE NOT NULL,
    usd_price MONEY NOT NULL CHECK (usd_price > 0::MONEY)
);


CREATE TABLE subscriptions (
    subscription_id SERIAL PRIMARY KEY,
    tier INTEGER NOT NULL CHECK (tier > 0),
    plan_name VARCHAR(255) NOT NULL,
    plan_desc VARCHAR(1023) NOT NULL,
    price_value MONEY NOT NULL CHECK (price_value >= 0::MONEY),
    currency_id INTEGER REFERENCES currencies(cur_id), 
    is_active BOOLEAN DEFAULT TRUE
);


-- users with subsctiptions. If someone delete user, it will delete from this table too, 
-- and if someone delete subscription the subscription_id will have NULL value.
CREATE TABLE user_subscriptions (
    subscription_id INTEGER REFERENCES subscriptions (subscription_id) ON DELETE SET NULL,
    user_id INTEGER NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    PRIMARY KEY (subscription_id, user_id)
);


CREATE TABLE locations (
    loc_id SERIAL PRIMARY KEY,
    label VARCHAR (1023),
    lat DOUBLE PRECISION,
    lon DOUBLE PRECISION,
    -- default NULL for clarity
    owner_id INTEGER REFERENCES users(user_id) DEFAULT NULL,
    -- Some locations could be publicly visible to all users, like Moscow or Paris,
    --  but some locations like user's home address should be hidden for others.
    public_visible BOOLEAN DEFAULT FALSE NOT NULL,
    UNIQUE(owner_id, lat, lon),
    UNIQUE(owner_id, label)
);


CREATE TYPE PERIOD_T AS ENUM ('daily', 'weekly', 'monthly', 'year');

CREATE TYPE STATUS_T AS ENUM ('pending', 'confirmed', 'declined');

-- meetings created by some users
CREATE TABLE meetings (
    meeting_id SERIAL PRIMARY KEY,
    -- parent_meeting_id: in case of a periodic meeting that happened before
    parent_meeting_id INTEGER REFERENCES meetings(meeting_id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    meet_desc TEXT,
    meet_host INTEGER REFERENCES users (user_id) ON DELETE SET NULL,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    repeat_period PERIOD_T DEFAULT NULL,
    loc_id INTEGER REFERENCES locations(loc_id),
    public BOOLEAN DEFAULT FALSE NOT NULL,
    is_canceled BOOLEAN DEFAULT FALSE NOT NULL
);


-- user-meetings connections
CREATE TABLE users_meetings (
    user_id INTEGER NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    meeting_id INTEGER NOT NULL REFERENCES meetings (meeting_id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'pending',
    response_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, meeting_id)
);


-- overall service logs
CREATE TABLE service_logs (
    log_id SERIAL PRIMARY KEY,
    log_message TEXT NOT NULL,
    log_level INTEGER CHECK (log_level > 0),
    log_time TIMESTAMP NOT NULL
);


-- user actions for analytics
CREATE TABLE actions (
    action_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users (user_id),
    action_name VARCHAR(255) NOT NULL,
    action_data JSONB,
    record_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- NOTE: md5 is not secure. I'am not going to use it in production code. 
INSERT INTO users (name, surname, email, password_hash) VALUES
    ('Ivan', ' Ivanov', 'ivan.ivanov@example.com', MD5('password1')),
    ('Maria', 'Petrova', 'maria.petrova@example.com', MD5('password2')),
    ('Sergey', 'Sidorov', 'sergey.sidorov@example.com', MD5('password3')),
    ('Olga', 'Volkova', 'olga.volkova@example.com', MD5('password4')),
    ('Pavel', 'Vasin', 'pavel.vasin@example.com', MD5('password5')),
    ('Elena', 'Zhukova', 'elena.zhukova@example.com', MD5('password6')),
    ('Dmitriy', 'Morozov', 'dmitriy.morozov@example.com', MD5('password7')),
    ('Anna', 'Smirnova', 'anna.smirnova@example.com', MD5('password8')),
    ('Alexey', 'Kuznetsov', 'alexey.kuznetsov@example.com', MD5('password9')),
    ('Tatyana', 'Levina', 'tatyana.levina@example.com', MD5('password10')),
    ('Nikolay', 'Borisov', 'nikolay.borisov@example.com', MD5('password11')),
    ('Ekaterina', 'Andreyeva', 'ekaterina.andreyeva@example.com', MD5('password12')),
    ('Vladimir', 'Makarov', 'vladimir.makarov@example.com', MD5('password13')),
    ('Svetlana', 'Volkova', 'svetlana.volkova@example.com', MD5('password14')),
    ('Petr', 'Tikhonov', 'petr.tikhonov@example.com', MD5('password15'));

INSERT INTO admins (name, email, admin_permissions, is_super_admin) VALUES
    ('Admin1', 'admin1@example.com', 'read_only', FALSE),
    ('Admin2', 'admin2@example.com', 'dev', TRUE);

INSERT INTO currencies (label, usd_price) VALUES
    ('RUB', 90),
    ('USD', 1),
    ('BYN', 0.31);

INSERT INTO subscriptions 
    (tier, plan_name, plan_desc, price_value, currency_id, is_active)
    VALUES
    (1, 'Base', 'Basic subscription. You have a right to make meeting private', 99, 1, TRUE),
    (2, 'Base+', 'Basic subscription with advanced customer support', 199, 1, TRUE),
    (3, 'Platinum', 'Depricated subscription', 0, 2, FALSE),
    (3, 'Gold', 'Gold subscription. You can create more than 30 meetengs per week, make meetengs private and access to advinced support', 399, 1, TRUE);

INSERT INTO user_subscriptions (subscription_id, user_id) VALUES
    (1, 2),
    (1, 5),
    (2, 3),
    (2, 4),
    (2, 8),
    (2, 11),
    (3, 12),
    (1, 15),
    (4, 13);


INSERT INTO locations (label, lat, lon, owner_id, public_visible) VALUES
    ('Moscow', 55.7558, 37.6173, NULL, TRUE),
    ('Paris', 48.8566, 2.3522, NULL, TRUE),
    ('London', 51.5074, -0.1278, NULL, TRUE),
    ('Lisbon', 38.7169, -9.1399, NULL, TRUE),
    ('Prague', 50.0755, 14.4378, NULL, TRUE),
    ('Ruzovskaya st., 10-12, Saint Petersburg, Russia, 190013', 59.9213, 30.3480, 1, FALSE),
    ('Home addr', 59.8813, 30.2479, 2, FALSE),
    ('28. pluku 1533, 100 00 Praha 10-Vrsovice, Czechia', 50.0686, 14.4639, 3, FALSE);


INSERT INTO meetings (parent_meeting_id, title, meet_desc, meet_host, start_time, end_time, repeat_period, loc_id, public, is_canceled) VALUES
    (NULL, 'Weekly Team Sync', 'Weekly meeting to sync on team progress and tasks.', 1, '2024-12-14 10:00:00', '2024-12-14 11:00:00', 'weekly', 1, TRUE, FALSE),
    (NULL, 'Project Kickoff', 'Kickoff meeting for the new project with stakeholders.', 2, '2024-12-15 14:00:00', '2024-12-15 15:30:00', NULL, 2, FALSE, FALSE),
    (1, 'Monthly Review', 'Review of the monthly performance and KPIs.', 3, '2024-12-20 09:00:00', '2024-12-20 10:30:00', 'monthly', 3, TRUE, FALSE),
    (NULL, 'Client Presentation', 'Presentation of the project updates to the client.', 4, '2024-12-18 16:00:00', '2024-12-18 17:00:00', NULL, 4, FALSE, FALSE),
    (NULL, 'Training Session', 'Training session for the new software tool.', 5, '2024-12-22 13:00:00', '2024-12-22 15:00:00', 'daily', 5, TRUE, FALSE),
    (NULL, 'Annual Planning', 'Annual planning session for the upcoming year.', 6, '2024-12-29 09:00:00', '2024-12-29 17:00:00', 'year', 6, FALSE, FALSE),
    (NULL, 'Coffee Chat', 'Casual coffee chat to catch up with colleagues.', 7, '2024-12-12 15:00:00', '2024-12-12 16:00:00', NULL, 7, TRUE, FALSE),
    (3, 'Emergency Meeting', 'Urgent meeting to address a critical issue.', 8, '2024-12-13 12:00:00', '2024-12-13 12:30:00', NULL, 8, FALSE, TRUE);


-- Insert sample user-meeting connections
INSERT INTO users_meetings (user_id, meeting_id, status, response_time) VALUES
    (1, 1, 'confirmed', '2024-12-10 09:00:00'),
    (2, 1, 'pending', NULL),
    (3, 2, 'confirmed', '2024-12-12 14:30:00'),
    (4, 2, 'declined', '2024-12-12 15:00:00'),
    (5, 3, 'confirmed', '2024-12-13 08:45:00'),
    (6, 4, 'confirmed', '2024-12-14 16:30:00'),
    (7, 5, 'pending', NULL),
    (8, 5, 'declined', '2024-12-15 13:00:00'),
    (9, 6, 'confirmed', '2024-12-16 09:15:00'),
    (10, 7, 'confirmed', '2024-12-11 14:00:00'),
    (11, 8, 'pending', NULL),
    (12, 8, 'declined', '2024-12-12 11:15:00'),
    (13, 1, 'pending', NULL),
    (14, 3, 'confirmed', '2024-12-13 09:00:00'),
    (15, 6, 'declined', '2024-12-16 10:00:00');


INSERT INTO service_logs (log_message, log_level, log_time) VALUES
    ('User logged in', 1, '2024-12-05 08:00:00'),
    ('Database backup completed', 2, '2024-12-05 09:00:00'),
    ('Service restarted', 3, '2024-12-05 10:00:00');


INSERT INTO actions (user_id, action_name, action_data) VALUES
    (1, 'Login', '{"ip": "175.162.24.7"}'),
    (2, 'Viewed Page', '{"page": "dashboard"}'),
    (3, 'Updated Profile', '{"fields_updated": ["name", "email"]}');




-- View for not canceled meeteings with location and host info
CREATE VIEW meeting_overview_view AS
    SELECT 
        m.meeting_id AS "Meeting ID",
        m.title AS "Title",
        m.start_time AS "Starts",
        u.name AS "Host name",
        u.surname AS "Host surname",
        loc.label AS "Place",
        COUNT(um.user_id) AS "Number of participants"
    FROM meetings m
        LEFT JOIN users u ON m.meet_host = u.user_id
        LEFT JOIN locations loc ON m.loc_id = loc.loc_id
        LEFT JOIN users_meetings um ON m.meeting_id = um.meeting_id
    WHERE m.is_canceled IS FALSE
    GROUP BY m.meeting_id, u.name, u.surname, loc.label;
    
SELECT * FROM meeting_overview_view LIMIT 100;

-- Select all active users from and show their subscriptions
CREATE TEMPORARY TABLE active_users_TEMP AS
    SELECT 
        u.user_id,
        COUNT(us.subscription_id) AS "Number of active subscriptions",
        MAX(s.tier) AS "Max subscription tier"
    FROM users u
        LEFT JOIN user_subscriptions us ON u.user_id = us.user_id
        LEFT JOIN subscriptions s ON us.subscription_id = s.subscription_id
    WHERE u.is_active IS TRUE 
        AND s.is_active IS TRUE
    GROUP BY u.user_id
    ORDER BY u.user_id;

SELECT * FROM active_users_TEMP LIMIT 100;


-- Show all parent meetengs for meeting id = 8
WITH RECURSIVE meeting_hierarchy AS (
    SELECT 
        meeting_id,
        parent_meeting_id,
        title,
        start_time,
        end_time
    FROM meetings
    WHERE meeting_id = 1
    
    UNION ALL
    
    SELECT 
        m.meeting_id,
        m.parent_meeting_id,
        m.title,
        m.start_time,
        m.end_time
    FROM meetings m
        INNER JOIN meeting_hierarchy mh ON m.meeting_id = mh.parent_meeting_id
)
SELECT * FROM meeting_hierarchy LIMIT 100;


-- Show query planning and execution
EXPLAIN ANALYZE
SELECT * 
    FROM meeting_overview_view 
    WHERE "Starts" > CURRENT_TIMESTAMP
        AND "Host name" LIKE 'O%' OR "Host name" LIKE 'M%'
    ORDER BY "Meeting ID";

-- GroupAggregate  (cost=27.56..27.66 rows=4 width=2084) (actual time=0.076..0.078 rows=2 loops=1)
--   Group Key: m.meeting_id, u.name, u.surname, loc.label
--   ->  Sort  (cost=27.56..27.57 rows=4 width=2080) (actual time=0.073..0.074 rows=3 loops=1)
--         Sort Key: m.meeting_id, u.name, u.surname, loc.label
--         Sort Method: quicksort  Memory: 25kB
--         ->  Nested Loop Left Join  (cost=10.75..27.52 rows=4 width=2080) (actual time=0.045..0.050 rows=3 loops=1)
--               ->  Nested Loop Left Join  (cost=10.61..22.84 rows=1 width=2076) (actual time=0.026..0.029 rows=2 loops=1)
--                     ->  Hash Join  (cost=10.46..21.93 rows=1 width=1564) (actual time=0.016..0.018 rows=2 loops=1)
--                           Hash Cond: (m.meet_host = u.user_id)
--                           Join Filter: (((m.start_time > CURRENT_TIMESTAMP) AND ((u.name)::text ~~ 'O%'::text)) OR ((u.name)::text ~~ 'M%'::text))
--                           ->  Seq Scan on meetings m  (cost=0.00..11.30 rows=65 width=536) (actual time=0.004..0.005 rows=7 loops=1)
--                                 Filter: (is_canceled IS FALSE)
--                                 Rows Removed by Filter: 1
--                           ->  Hash  (cost=10.45..10.45 rows=1 width=1036) (actual time=0.006..0.006 rows=2 loops=1)
--                                 Buckets: 1024  Batches: 1  Memory Usage: 9kB
--                                 ->  Seq Scan on users u  (cost=0.00..10.45 rows=1 width=1036) (actual time=0.003..0.004 rows=2 loops=1)
--                                       Filter: (((name)::text ~~ 'O%'::text) OR ((name)::text ~~ 'M%'::text))
--                                       Rows Removed by Filter: 13
--                     ->  Index Scan using locations_pkey on locations loc  (cost=0.14..0.90 rows=1 width=520) (actual time=0.005..0.005 rows=1 loops=2)
--                           Index Cond: (loc_id = m.loc_id)
--               ->  Index Only Scan using users_meetings_pkey on users_meetings um  (cost=0.15..4.66 rows=2 width=8) (actual time=0.009..0.010 rows=2 loops=2)
--                     Index Cond: (meeting_id = m.meeting_id)
--                     Heap Fetches: 3
-- Planning Time: 2.218 ms
-- Execution Time: 0.113 ms




-- clean up
DROP TABLE IF EXISTS active_users_TEMP;
DROP VIEW IF EXISTS meeting_overview_view;
DROP TABLE IF EXISTS actions;
DROP TABLE IF EXISTS service_logs;
DROP TABLE IF EXISTS users_meetings;
DROP TABLE IF EXISTS meetings;
DROP TABLE IF EXISTS locations;
DROP TABLE IF EXISTS user_subscriptions;
DROP TABLE IF EXISTS subscriptions;
DROP TABLE IF EXISTS currencies;
DROP TABLE IF EXISTS admins;
DROP TABLE IF EXISTS users;
DROP TYPE IF EXISTS ADMIN_PERM_T;
DROP TYPE IF EXISTS PERIOD_T;
DROP TYPE IF EXISTS STATUS_T;
