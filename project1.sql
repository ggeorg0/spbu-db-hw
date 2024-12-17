CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
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
    email VARCHAR(255) UNIQUE NOT NULL,
    admin_permissions ADMIN_PERM_T NOT NULL DEFAULT 'read_only',
    is_super_admin BOOLEAN DEFAULT FALSE
);

CREATE TABLE prices (
    price_id SERIAL PRIMARY KEY,
        -- I found that PosgreSQL have a `MONEY` type
    price_value MONEY NOT NULL CHECK (price_value > 0::MONEY),
    currency CHAR(3) DEFAULT 'RUB'
);

CREATE TABLE subscriptions (
    subscription_id SERIAL PRIMARY KEY,
    subscription_tier INT NOT NULL CHECK (subscription_tier > 0),
    plan_name VARCHAR(255) NOT NULL,
    plan_desc VARCHAR(1023) NOT NULL,
    price_id INT NOT NULL REFERENCES prices (price_id),
    is_active BOOLEAN DEFAULT TRUE
);

-- users with subsctiptions. If someone delete user, it will delete from this table too, 
-- and if someone delete subscription the subscription_id will have NULL value.
CREATE TABLE user_subscriptions (
    subscription_id INT REFERENCES subscriptions (subscription_id) ON DELETE SET NULL,
    user_id INT NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    PRIMARY KEY (subscription_id, user_id)
);

CREATE TYPE PERIOD_T AS ENUM ('daily', 'weekly', 'monthly', 'year');


-- meetings created by some users
CREATE TABLE meetings (
    meeting_id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    meet_desc TEXT,
    meet_host INT REFERENCES users (user_id) ON DELETE SET NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    repeat_period PERIOD_T DEFAULT NULL,
    location VARCHAR(511),
    is_canceled BOOLEAN DEFAULT FALSE
);

CREATE TYPE STATUS_T AS ENUM ('pending', 'confirmed', 'declined');

-- user-meetings connections
CREATE TABLE users_meetings (
    user_id INT NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    meeting_id INT NOT NULL REFERENCES meetings (meeting_id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'pending',
    response_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, meeting_id)
);

-- overall service logs
CREATE TABLE service_logs (
    log_id SERIAL PRIMARY KEY,
    log_message TEXT NOT NULL,
    log_level INT CHECK (log_level > 0),
    log_time TIMESTAMP NOT NULL
);

-- user actions for analytics
CREATE TABLE actions (
    action_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users (user_id),
    action_name VARCHAR(255) NOT NULL,
    action_data JSONB,
    record_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- Some data generated with help of GPT-4o, because the luck of time.
INSERT INTO users (name, email, password_hash) VALUES
    ('Alice Smith', 'alice.smith@example.com', md5('password1')),
    ('Bob Johnson', 'bob.johnson@example.com', md5('password2')),
    ('Charlie Brown', 'charlie.brown@example.com', md5('password3'));

INSERT INTO admins (name, email, admin_permissions, is_super_admin) VALUES
    ('Admin1', 'admin1@example.com', 'read_only', FALSE),
    ('Admin2', 'admin2@example.com', 'dev', TRUE);

INSERT INTO prices (price_value, currency) VALUES
    (10.00, 'USD'),
    (750.00, 'RUB'),
    (8.99, 'EUR');

INSERT INTO subscriptions (subscription_tier, plan_name, plan_desc, price_id) VALUES
    (1, 'Basic Plan', 'Access to basic features', 1),
    (2, 'Pro Plan', 'Access to premium features', 2),
    (3, 'Enterprise Plan', 'Access to all features', 3);

INSERT INTO user_subscriptions (subscription_id, user_id) VALUES
    (1, 1),
    (2, 2),
    (3, 3);

INSERT INTO meetings (title, meet_desc, meet_host, start_time, end_time, repeat_period, location) VALUES
    ('Project Kickoff', 'Initial project discussion', 1, '2024-12-06 10:00:00', '2024-12-06 11:00:00', 'weekly', 'Conference Room A'),
    ('Monthly Review', 'Review of monthly performance', 2, '2024-12-10 14:00:00', '2024-12-10 15:30:00', 'monthly', 'Online'),
    ('Team Lunch', 'Casual lunch with team', NULL, '2024-12-15 12:00:00', '2024-12-15 13:30:00', NULL, 'Local Restaurant');

INSERT INTO users_meetings (user_id, meeting_id, status) VALUES
    (1, 1, 'confirmed'),
    (2, 2, 'pending'),
    (3, 3, 'declined');

INSERT INTO service_logs (log_message, log_level, log_time) VALUES
    ('User logged in', 1, '2024-12-05 08:00:00'),
    ('Database backup completed', 2, '2024-12-05 09:00:00'),
    ('Service restarted', 3, '2024-12-05 10:00:00');


INSERT INTO actions (user_id, action_name, action_data) VALUES
    (1, 'Login', '{"ip": "192.168.1.1"}'),
    (2, 'Viewed Page', '{"page": "dashboard"}'),
    (3, 'Updated Profile', '{"fields_updated": ["name", "email"]}');


-- count users
SELECT COUNT(*) AS total_users FROM users;

-- active subscriptions 
SELECT COUNT(*) AS active_subscriptions 
    FROM subscriptions
    WHERE is_active = TRUE;

-- total_revenue
-- actually not true because of different currencies.
SELECT SUM(prices.price_value) AS total_revenue
    FROM user_subscriptions usub
    JOIN subscriptions sub ON usub.subscription_id = sub.subscription_id
    JOIN prices ON prices.price_id = sub.price_id
    WHERE sub.is_active = TRUE;



-- clean up
DROP TABLE IF EXISTS actions;
DROP TABLE IF EXISTS service_logs;
DROP TABLE IF EXISTS users_meetings;
DROP TABLE IF EXISTS meetings;
DROP TABLE IF EXISTS user_subscriptions;
DROP TABLE IF EXISTS subscriptions;
DROP TABLE IF EXISTS prices;
DROP TABLE IF EXISTS admins;
DROP TABLE IF EXISTS users;
DROP TYPE IF EXISTS ADMIN_PERM_T;
DROP TYPE IF EXISTS PERIOD_T;
DROP TYPE IF EXISTS STATUS_T;
