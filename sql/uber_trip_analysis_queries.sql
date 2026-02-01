-- Uber Trip Insights - Analysis Queries

WITH trips AS (
    SELECT
        "Trip ID"               AS trip_id,
        "Pickup Time"           AS pickup_time,
        "Drop Off Time"         AS dropoff_time,
        passenger_count,
        trip_distance,
        "PULocationID"          AS pu_location_id,
        "DOLocationID"          AS do_location_id,
        fare_amount,
        COALESCE("Surge Fee", 0) AS surge_fee,
        "Vehicle"               AS vehicle,
        "Payment_type"          AS payment_type,
        (fare_amount + COALESCE("Surge Fee", 0)) AS booking_value,
        EXTRACT(HOUR FROM "Pickup Time") AS pickup_hour,
        EXTRACT(DOW FROM "Pickup Time")  AS pickup_dow,
        CASE
            WHEN EXTRACT(HOUR FROM "Pickup Time") BETWEEN 6 AND 17 THEN 'Day'
            ELSE 'Night'
        END AS day_part,
        CASE
            WHEN EXTRACT(DOW FROM "Pickup Time") IN (0, 6) THEN 'Weekend'
            ELSE 'Weekday'
        END AS weekday_type,
        EXTRACT(EPOCH FROM ("Drop Off Time" - "Pickup Time")) / 60.0 AS trip_minutes
    FROM uber_trip_details
),
locations AS (
    SELECT
        "LocationID" AS location_id,
        "Location"   AS location_name,
        "City"       AS city
    FROM location_table
)

-- Booking & Revenue Analysis

-- 1) Total number of bookings
SELECT COUNT(*) AS total_bookings
FROM trips;

-- 2) Total booking value (revenue)
SELECT SUM(booking_value) AS total_booking_value
FROM trips;

-- 3) Average booking value per trip
SELECT AVG(booking_value) AS avg_booking_value
FROM trips;

-- 4) Booking value by day of week (0=Sun ... 6=Sat in Postgres)
SELECT
    pickup_dow,
    SUM(booking_value) AS booking_value
FROM trips
GROUP BY pickup_dow
ORDER BY pickup_dow;

-- 5) Top 5 revenue-generating days
SELECT
    DATE(pickup_time) AS trip_date,
    SUM(booking_value) AS booking_value
FROM trips
GROUP BY DATE(pickup_time)
ORDER BY booking_value DESC
LIMIT 5;

-- Time-Based Analysis

-- 6) Hour of day with highest booking value
SELECT
    pickup_hour,
    SUM(booking_value) AS booking_value
FROM trips
GROUP BY pickup_hour
ORDER BY booking_value DESC
LIMIT 1;

-- 7) Peak booking hours for weekdays vs weekends
SELECT
    weekday_type,
    pickup_hour,
    COUNT(*) AS bookings
FROM trips
GROUP BY weekday_type, pickup_hour
ORDER BY weekday_type, bookings DESC;

-- 8) Demand between day trips and night trips
SELECT
    day_part,
    COUNT(*) AS bookings,
    SUM(booking_value) AS booking_value
FROM trips
GROUP BY day_part
ORDER BY bookings DESC;

-- 9) Average trip duration by hour
SELECT
    pickup_hour,
    AVG(trip_minutes) AS avg_trip_minutes
FROM trips
GROUP BY pickup_hour
ORDER BY pickup_hour;

-- 10) Day-hour combination generating maximum revenue
SELECT
    pickup_dow,
    pickup_hour,
    SUM(booking_value) AS booking_value
FROM trips
GROUP BY pickup_dow, pickup_hour
ORDER BY booking_value DESC
LIMIT 1;

-- Location Analysis

-- 11) Most frequent pickup locations
SELECT
    l.location_name,
    l.city,
    COUNT(*) AS bookings
FROM trips t
JOIN locations l ON t.pu_location_id = l.location_id
GROUP BY l.location_name, l.city
ORDER BY bookings DESC;

-- 12) Most frequent drop-off locations
SELECT
    l.location_name,
    l.city,
    COUNT(*) AS bookings
FROM trips t
JOIN locations l ON t.do_location_id = l.location_id
GROUP BY l.location_name, l.city
ORDER BY bookings DESC;

-- 13) Locations generating highest booking value (pickup)
SELECT
    l.location_name,
    l.city,
    SUM(t.booking_value) AS booking_value
FROM trips t
JOIN locations l ON t.pu_location_id = l.location_id
GROUP BY l.location_name, l.city
ORDER BY booking_value DESC;

-- 14) Longest trip recorded and between which locations
SELECT
    t.trip_distance,
    pu.location_name AS pickup_location,
    pu.city          AS pickup_city,
    do.location_name AS dropoff_location,
    do.city          AS dropoff_city
FROM trips t
JOIN locations pu ON t.pu_location_id = pu.location_id
JOIN locations do ON t.do_location_id = do.location_id
ORDER BY t.trip_distance DESC
LIMIT 1;

-- 15) Locations with consistently high demand (top 10 pickup locations)
SELECT
    l.location_name,
    l.city,
    COUNT(*) AS bookings
FROM trips t
JOIN locations l ON t.pu_location_id = l.location_id
GROUP BY l.location_name, l.city
ORDER BY bookings DESC
LIMIT 10;

-- Vehicle & Payment Analysis

-- 16) Vehicle type with highest number of bookings
SELECT
    vehicle,
    COUNT(*) AS bookings
FROM trips
GROUP BY vehicle
ORDER BY bookings DESC
LIMIT 1;

-- 17) Vehicle type generating highest revenue
SELECT
    vehicle,
    SUM(booking_value) AS booking_value
FROM trips
GROUP BY vehicle
ORDER BY booking_value DESC
LIMIT 1;

-- 18) Average booking value by vehicle type
SELECT
    vehicle,
    AVG(booking_value) AS avg_booking_value
FROM trips
GROUP BY vehicle
ORDER BY avg_booking_value DESC;

-- 19) Distribution of payment methods
SELECT
    payment_type,
    COUNT(*) AS bookings
FROM trips
GROUP BY payment_type
ORDER BY bookings DESC;

-- 20) Payment type contributing most revenue
SELECT
    payment_type,
    SUM(booking_value) AS booking_value
FROM trips
GROUP BY payment_type
ORDER BY booking_value DESC
LIMIT 1;
