-- Create Database
CREATE DATABASE hotel_db;
USE hotel_db;

-- Users Table
CREATE TABLE users (
    user_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100),
    phone_number VARCHAR(20),
    mail_id VARCHAR(100),
    billing_address VARCHAR(255)
);

-- Bookings Table
CREATE TABLE bookings (
    booking_id VARCHAR(50) PRIMARY KEY,
    booking_date DATETIME,
    room_no VARCHAR(50),
    user_id VARCHAR(50),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Items Table
CREATE TABLE items (
    item_id VARCHAR(50) PRIMARY KEY,
    item_name VARCHAR(100),
    item_rate DECIMAL(10,2)
);

-- Booking Commercials Table
CREATE TABLE booking_commercials (
    id VARCHAR(50) PRIMARY KEY,
    booking_id VARCHAR(50),
    bill_id VARCHAR(50),
    bill_date DATETIME,
    item_id VARCHAR(50),
    item_quantity DECIMAL(10,2),
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),
    FOREIGN KEY (item_id) REFERENCES items(item_id)
);

-- Sample Data Insert

INSERT INTO users VALUES
('u1','John Doe','9999999999','john@example.com','Address1'),
('u2','Jane Smith','8888888888','jane@example.com','Address2');

INSERT INTO bookings VALUES
('b1','2021-11-10 10:00:00','101','u1'),
('b2','2021-10-15 12:00:00','102','u1'),
('b3','2021-11-20 14:00:00','103','u2');

INSERT INTO items VALUES
('i1','Paratha',20),
('i2','Curry',100);

INSERT INTO booking_commercials VALUES
('bc1','b1','bill1','2021-11-10','i1',2),
('bc2','b1','bill1','2021-11-10','i2',1),
('bc3','b2','bill2','2021-10-15','i2',15),
('bc4','b3','bill3','2021-11-20','i1',5);

-- Q1: Last booked room for each user
SELECT b.user_id, b.room_no
FROM bookings b
JOIN (
    SELECT user_id, MAX(booking_date) AS last_booking
    FROM bookings
    GROUP BY user_id
) t
ON b.user_id = t.user_id AND b.booking_date = t.last_booking;


-- Q2: Booking ID and total billing in Nov 2021
SELECT 
    booking_id,
    SUM(item_quantity * item_rate) AS total_amount
FROM booking_commercials bc
JOIN items i ON bc.item_id = i.item_id
WHERE MONTH(bill_date)=11 AND YEAR(bill_date)=2021
GROUP BY booking_id;


-- Q3: Bills in Oct 2021 > 1000
SELECT 
    bill_id,
    SUM(item_quantity * item_rate) AS bill_amount
FROM booking_commercials bc
JOIN items i ON bc.item_id = i.item_id
WHERE MONTH(bill_date)=10 AND YEAR(bill_date)=2021
GROUP BY bill_id
HAVING bill_amount > 1000;

-- Q4: Most & least ordered item per month
WITH temp AS (
    SELECT 
        MONTH(bill_date) AS month,
        item_id,
        SUM(item_quantity) qty,
        RANK() OVER (PARTITION BY MONTH(bill_date) ORDER BY SUM(item_quantity) DESC) r1,
        RANK() OVER (PARTITION BY MONTH(bill_date) ORDER BY SUM(item_quantity)) r2
    FROM booking_commercials
    WHERE YEAR(bill_date)=2021
    GROUP BY MONTH(bill_date), item_id
)
SELECT * FROM temp WHERE r1=1 OR r2=1;

-- Q5: 2nd highest bill per month
WITH temp AS (
    SELECT 
        MONTH(bill_date) AS month,
        bill_id,
        SUM(item_quantity * item_rate) amount,
        RANK() OVER (PARTITION BY MONTH(bill_date) ORDER BY SUM(item_quantity * item_rate) DESC) rnk
    FROM booking_commercials bc
    JOIN items i ON bc.item_id = i.item_id
    WHERE YEAR(bill_date)=2021
    
    
    GROUP BY MONTH(bill_date), bill_id
)
SELECT * FROM temp WHERE rnk=2;

CREATE DATABASE clinic_db;
USE clinic_db;

CREATE TABLE clinics (
    cid VARCHAR(50) PRIMARY KEY,
    clinic_name VARCHAR(100),
    city VARCHAR(50),
    state VARCHAR(50),
    country VARCHAR(50)
);

CREATE TABLE customer (
    uid VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100),
    mobile VARCHAR(20)
);

CREATE TABLE clinic_sales (
    oid VARCHAR(50) PRIMARY KEY,
    uid VARCHAR(50),
    cid VARCHAR(50),
    amount DECIMAL(10,2),
    datetime DATETIME,
    sales_channel VARCHAR(50)
);

CREATE TABLE expenses (
    eid VARCHAR(50) PRIMARY KEY,
    cid VARCHAR(50),
    description VARCHAR(255),
    amount DECIMAL(10,2),
    datetime DATETIME
);

-- Sample Data

INSERT INTO clinics VALUES
('c1','Clinic A','Hyderabad','Telangana','India'),
('c2','Clinic B','Mumbai','Maharashtra','India');

INSERT INTO customer VALUES
('u1','John','9999'),
('u2','Jane','8888');

INSERT INTO clinic_sales VALUES
('o1','u1','c1',1000,'2021-09-10','online'),
('o2','u2','c1',2000,'2021-09-12','offline'),
('o3','u1','c2',500,'2021-09-15','online');

INSERT INTO expenses VALUES
('e1','c1','rent',500,'2021-09-10'),
('e2','c2','equipment',300,'2021-09-15');

-- Q1: Revenue by channel
SELECT sales_channel, SUM(amount)
FROM clinic_sales
WHERE YEAR(datetime)=2021
GROUP BY sales_channel;

--------------------------------------------------

-- Q2: Top 10 customers
SELECT uid, SUM(amount) total
FROM clinic_sales
GROUP BY uid
ORDER BY total DESC
LIMIT 10;

--------------------------------------------------

-- Q3: Month-wise revenue, expense, profit
WITH r AS (
    SELECT MONTH(datetime) m, SUM(amount) revenue
    FROM clinic_sales
    GROUP BY MONTH(datetime)
),
e AS (
    SELECT MONTH(datetime) m, SUM(amount) expense
    FROM expenses
    GROUP BY MONTH(datetime)
)
SELECT 
    r.m,
    r.revenue,
    e.expense,
    r.revenue - e.expense profit,
    CASE WHEN r.revenue - e.expense > 0 THEN 'Profit' ELSE 'Loss' END status
FROM r JOIN e ON r.m=e.m;

--------------------------------------------------

-- Q4: Most profitable clinic per city
WITH temp AS (
    SELECT 
        c.city,
        cs.cid,
        SUM(cs.amount) - COALESCE(SUM(e.amount),0) profit,
        RANK() OVER (PARTITION BY c.city ORDER BY SUM(cs.amount) DESC) rnk
    FROM clinic_sales cs
    JOIN clinics c ON cs.cid=c.cid
    LEFT JOIN expenses e ON cs.cid=e.cid
    GROUP BY c.city, cs.cid
)
SELECT * FROM temp WHERE rnk=1;

-- Q5: 2nd least profitable clinic per state
WITH temp AS (
    SELECT 
        c.state,
        cs.cid,
        SUM(cs.amount) - COALESCE(SUM(e.amount),0) profit,
        RANK() OVER (PARTITION BY c.state ORDER BY SUM(cs.amount)) rnk
    FROM clinic_sales cs
    JOIN clinics c ON cs.cid=c.cid
    LEFT JOIN expenses e ON cs.cid=e.cid
    GROUP BY c.state, cs.cid
)
SELECT * FROM temp WHERE rnk=2;