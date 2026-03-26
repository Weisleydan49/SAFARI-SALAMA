-- ============================================================
-- MATATU TRACKING APP - POSTGRESQL DATABASE SCHEMA
-- ============================================================
-- Author: Almond Weisley
-- Date: December 2025
-- Description: Complete database schema for matatu tracking system(SafariSalama)
-- ============================================================

--Enable UUID extension for generating unique IDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

--Enable PostGIS for geographic data (location tracking)
CREATE EXTENSION IF NOT EXISTS postgis;


-- ============================================================
-- CORE TABLES
-- ============================================================

--Users Table
CREATE TABLE users(
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
phone VARCHAR(15) UNIQUE NOT NULL,
name VARCHAR(100) NOT NULL,
email VARCHAR(255) UNIQUE,
password_hash VARCHAR(255) NOT NULL,
user_type VARCHAR(20) NOT NULL CHECK (user_type in ('passenger', 'driver', 'admin', 'sacco_admin')),
profile_photo_url VARCHAR(500),
is_verified BOOLEAN DEFAULT FALSE,
is_active BOOLEAN DEFAULT TRUE,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
last_login TIMESTAMP
);

--SACCOS
CREATE TABLE saccos(
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
name VARCHAR(200) NOT NULL,
registration_number VARCHAR(50) NOT NULL,
contact_phone VARCHAR(15),
contact_email VARCHAR(255),
address TEXT,
admin_user_id UUID REFERENCES users(id),
is_active BOOLEAN DEFAULT TRUE,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

--Routes Table
CREATE TABLE routes(
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
name VARCHAR(100) NOT NULL,
route_number VARCHAR(20),
origin VARCHAR(200) NOT NULL,
destination VARCHAR(200) NOT NULL,
description TEXT,
estimated_duration_minutes INTEGER,
distance_km DECIMAL(10, 2),
fare_amount DECIMAL(10, 2),
is_active BOOLEAN DEFAULT TRUE,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

--Routes waypoints Table
CREATE TABLE route_waypoints(
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
route_id UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
waypoint_name VARCHAR(200) NOT NULL,
waypoint_order INTEGER NOT NULL,
latitude DECIMAL(10, 8) NOT NULL,
longitude DECIMAL(11, 8) NOT NULL,
location GEOGRAPHY(POINT, 4326),
is_major_stop BOOLEAN DEFAULT FALSE,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

--Vehicles Table
CREATE TABLE vehicles(
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
registration_number VARCHAR(20) UNIQUE NOT NULL,
sacco_id UUID REFERENCES saccos(id),
route_id UUID REFERENCES routes(id),
capacity INTEGER DEFAULT 14,
vehicle_type VARCHAR(50) DEFAULT 'matatu',
make VARCHAR(50),
model VARCHAR(50),
year_of_manufacture INTEGER,
current_latitude DECIMAL(10, 8),
current_longitude DECIMAL(11, 8),
current_location GEOGRAPHY(POINT, 4326),
last_location_update TIMESTAMP,
is_active BOOLEAN DEFAULT TRUE,
is_online BOOLEAN DEFAULT FALSE,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

--Drivers Table
CREATE TABLE drivers(
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
license_number VARCHAR(50) UNIQUE NOT NULL,
license_expiry_date DATE,
sacco_id UUID REFERENCES saccos(id),
current_vehicle_id UUID REFERENCES vehicles(id),
rating DECIMAL(3, 2) DEFAULT 5.00,
total_trips INTEGER DEFAULT 0,
is_verified BOOLEAN DEFAULT FALSE,
is_available BOOLEAN DEFAULT FALSE,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- TRIP & TRACKING TABLES
-- ============================================================

-- Trips Table
-- Stores individual passenger trips
CREATE TABLE trips (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    vehicle_id UUID NOT NULL REFERENCES vehicles(id),
    driver_id UUID REFERENCES drivers(id),
    route_id UUID REFERENCES routes(id),
    start_latitude DECIMAL(10, 8),
    start_longitude DECIMAL(11, 8),
    start_location GEOGRAPHY(POINT, 4326),
    end_latitude DECIMAL(10, 8),
    end_longitude DECIMAL(11, 8),
    end_location GEOGRAPHY(POINT, 4326),
    start_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP,
    duration_minutes INTEGER,
    distance_km DECIMAL(10, 2),
    fare_amount DECIMAL(10, 2),
    payment_status VARCHAR(20) DEFAULT 'pending' CHECK (payment_status IN ('pending', 'completed', 'failed', 'refunded')),
    trip_status VARCHAR(20) DEFAULT 'ongoing' CHECK (trip_status IN ('scheduled', 'ongoing', 'completed', 'cancelled')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Vehicle Location History Table
-- Stores historical location data for vehicles (for replay/analysis)
CREATE TABLE vehicle_location_history (
    id BIGSERIAL PRIMARY KEY,
    vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    location GEOGRAPHY(POINT, 4326),
    speed_kmh DECIMAL(5, 2),
    heading INTEGER, -- Direction in degrees (0-360)
    altitude_meters DECIMAL(8, 2),
    accuracy_meters DECIMAL(6, 2),
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index for efficient time-based queries
CREATE INDEX idx_vehicle_location_history_timestamp 
ON vehicle_location_history(vehicle_id, timestamp DESC);

-- ============================================================
-- PAYMENT TABLES
-- ============================================================

-- Payments Table
-- Stores payment transactions
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID REFERENCES trips(id),
    user_id UUID NOT NULL REFERENCES users(id),
    amount DECIMAL(10, 2) NOT NULL,
    payment_method VARCHAR(50) DEFAULT 'mpesa' CHECK (payment_method IN ('mpesa', 'card', 'cash', 'wallet')),
    transaction_id VARCHAR(100) UNIQUE,
    mpesa_receipt_number VARCHAR(50),
    phone_number VARCHAR(15),
    payment_status VARCHAR(20) DEFAULT 'pending' CHECK (payment_status IN ('pending', 'completed', 'failed', 'refunded')),
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Wallet Table
-- Stores user wallet balances for in-app payments
CREATE TABLE wallets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    balance DECIMAL(10, 2) DEFAULT 0.00,
    currency VARCHAR(3) DEFAULT 'KES',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Wallet Transactions Table
-- Stores all wallet transaction history
CREATE TABLE wallet_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    wallet_id UUID NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('credit', 'debit')),
    amount DECIMAL(10, 2) NOT NULL,
    balance_before DECIMAL(10, 2) NOT NULL,
    balance_after DECIMAL(10, 2) NOT NULL,
    description TEXT,
    reference_id UUID, -- Can reference trip_id or payment_id
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- EMERGENCY & SAFETY TABLES
-- ============================================================

-- Emergency Alerts Table
-- Stores emergency alerts from passengers
CREATE TABLE emergency_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    trip_id UUID REFERENCES trips(id),
    vehicle_id UUID REFERENCES vehicles(id),
    alert_type VARCHAR(50) DEFAULT 'general' CHECK (alert_type IN ('general', 'accident', 'harassment', 'theft', 'medical')),
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    location GEOGRAPHY(POINT, 4326),
    description TEXT,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'acknowledged', 'resolved', 'false_alarm')),
    acknowledged_by UUID REFERENCES users(id),
    acknowledged_at TIMESTAMP,
    resolved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Emergency Contacts Table
-- Stores user's emergency contacts
CREATE TABLE emergency_contacts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    contact_name VARCHAR(100) NOT NULL,
    contact_phone VARCHAR(15) NOT NULL,
    relationship VARCHAR(50),
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- RATING & FEEDBACK TABLES
-- ============================================================

-- Ratings Table
-- Stores passenger ratings for trips/drivers
CREATE TABLE ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES trips(id),
    user_id UUID NOT NULL REFERENCES users(id),
    driver_id UUID REFERENCES drivers(id),
    vehicle_id UUID REFERENCES vehicles(id),
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    categories JSONB, -- Store specific ratings: {"cleanliness": 5, "safety": 4, "punctuality": 5}
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(trip_id, user_id) -- One rating per user per trip
);

-- Reports Table
-- Stores user reports about vehicles, drivers, or routes
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_user_id UUID NOT NULL REFERENCES users(id),
    report_type VARCHAR(50) NOT NULL CHECK (report_type IN ('driver', 'vehicle', 'route', 'other')),
    reported_driver_id UUID REFERENCES drivers(id),
    reported_vehicle_id UUID REFERENCES vehicles(id),
    trip_id UUID REFERENCES trips(id),
    category VARCHAR(50), -- reckless_driving, overcharging, route_deviation, etc.
    description TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'investigating', 'resolved', 'dismissed')),
    resolution_notes TEXT,
    resolved_by UUID REFERENCES users(id),
    resolved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- NOTIFICATION TABLES
-- ============================================================

-- Notifications Table
-- Stores in-app notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    notification_type VARCHAR(50) DEFAULT 'general' CHECK (notification_type IN ('general', 'trip', 'payment', 'emergency', 'promotion')),
    reference_id UUID, -- Can reference trip_id, payment_id, etc.
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Push Notification Tokens Table
-- Stores device tokens for push notifications
CREATE TABLE push_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_token VARCHAR(500) NOT NULL,
    device_type VARCHAR(20) CHECK (device_type IN ('android', 'ios')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, device_token)
);

-- ============================================================
-- SCHEDULE & AVAILABILITY TABLES
-- ============================================================

-- Vehicle Schedules Table
-- Stores planned vehicle schedules
CREATE TABLE vehicle_schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    driver_id UUID REFERENCES drivers(id),
    route_id UUID NOT NULL REFERENCES routes(id),
    scheduled_start_time TIMESTAMP NOT NULL,
    scheduled_end_time TIMESTAMP NOT NULL,
    actual_start_time TIMESTAMP,
    actual_end_time TIMESTAMP,
    status VARCHAR(20) DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'active', 'completed', 'cancelled')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- ANALYTICS & LOGS TABLES
-- ============================================================

-- User Activity Logs Table
-- Stores user activity for analytics and debugging
CREATE TABLE user_activity_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    activity_type VARCHAR(50) NOT NULL,
    activity_description TEXT,
    ip_address INET,
    user_agent TEXT,
    metadata JSONB, -- Store additional data as JSON
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- API Logs Table
-- Stores API request logs for monitoring
CREATE TABLE api_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    endpoint VARCHAR(255) NOT NULL,
    method VARCHAR(10) NOT NULL,
    status_code INTEGER,
    request_body JSONB,
    response_body JSONB,
    duration_ms INTEGER,
    ip_address INET,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



-- Create index for efficient querying
CREATE INDEX idx_api_logs_created_at ON api_logs(created_at DESC);
CREATE INDEX idx_api_logs_user_id ON api_logs(user_id);

-- ============================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================

-- Users table indexes
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_user_type ON users(user_type);

-- Vehicles table indexes
CREATE INDEX idx_vehicles_registration ON vehicles(registration_number);
CREATE INDEX idx_vehicles_sacco ON vehicles(sacco_id);
CREATE INDEX idx_vehicles_route ON vehicles(route_id);
CREATE INDEX idx_vehicles_active ON vehicles(is_active, is_online);

-- Trips table indexes
CREATE INDEX idx_trips_user ON trips(user_id);
CREATE INDEX idx_trips_vehicle ON trips(vehicle_id);
CREATE INDEX idx_trips_status ON trips(trip_status);
CREATE INDEX idx_trips_start_time ON trips(start_time DESC);

-- Payments table indexes
CREATE INDEX idx_payments_user ON payments(user_id);
CREATE INDEX idx_payments_trip ON payments(trip_id);
CREATE INDEX idx_payments_status ON payments(payment_status);
CREATE INDEX idx_payments_date ON payments(payment_date DESC);

-- Emergency alerts indexes
CREATE INDEX idx_emergency_alerts_user ON emergency_alerts(user_id);
CREATE INDEX idx_emergency_alerts_status ON emergency_alerts(status);
CREATE INDEX idx_emergency_alerts_created ON emergency_alerts(created_at DESC);

-- Notifications indexes
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(is_read);

-- Spatial indexes for geographic queries (PostGIS)
CREATE INDEX idx_route_waypoints_location ON route_waypoints USING GIST(location);
CREATE INDEX idx_vehicles_location ON vehicles USING GIST(current_location);
CREATE INDEX idx_vehicle_location_history_location ON vehicle_location_history USING GIST(location);
CREATE INDEX idx_emergency_alerts_location ON emergency_alerts USING GIST(location);

-- ============================================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- ============================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to relevant tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_saccos_updated_at BEFORE UPDATE ON saccos
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_routes_updated_at BEFORE UPDATE ON routes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_vehicles_updated_at BEFORE UPDATE ON vehicles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_drivers_updated_at BEFORE UPDATE ON drivers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_trips_updated_at BEFORE UPDATE ON trips
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_wallets_updated_at BEFORE UPDATE ON wallets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_emergency_alerts_updated_at BEFORE UPDATE ON emergency_alerts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_emergency_contacts_updated_at BEFORE UPDATE ON emergency_contacts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- VIEWS FOR COMMON QUERIES
-- ============================================================

-- Active trips view
CREATE VIEW active_trips AS
SELECT 
    t.id,
    t.user_id,
    u.name as passenger_name,
    u.phone as passenger_phone,
    t.vehicle_id,
    v.registration_number,
    t.driver_id,
    d.user_id as driver_user_id,
    du.name as driver_name,
    t.route_id,
    r.name as route_name,
    t.start_time,
    t.fare_amount,
    t.payment_status
FROM trips t
JOIN users u ON t.user_id = u.id
JOIN vehicles v ON t.vehicle_id = v.id
LEFT JOIN drivers d ON t.driver_id = d.id
LEFT JOIN users du ON d.user_id = du.id
LEFT JOIN routes r ON t.route_id = r.id
WHERE t.trip_status = 'ongoing';

-- Vehicle status view
CREATE VIEW vehicle_status AS
SELECT 
    v.id,
    v.registration_number,
    v.route_id,
    r.name as route_name,
    v.sacco_id,
    s.name as sacco_name,
    v.is_online,
    v.current_latitude,
    v.current_longitude,
    v.last_location_update,
    d.user_id as driver_user_id,
    u.name as driver_name
FROM vehicles v
LEFT JOIN routes r ON v.route_id = r.id
LEFT JOIN saccos s ON v.sacco_id = s.id
LEFT JOIN drivers d ON v.id = d.current_vehicle_id
LEFT JOIN users u ON d.user_id = u.id
WHERE v.is_active = TRUE;

-- ============================================================
-- SAMPLE DATA (OPTIONAL - FOR TESTING)
-- ============================================================

-- Insert sample admin user
-- Password: 'admin123' (you should hash this properly in production)
INSERT INTO users (phone, name, email, password_hash, user_type, is_verified) 
VALUES ('+254712345678', 'Admin User', 'admin@matatu.app', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqpYF0j7Lu', 'admin', TRUE);

-- ============================================================
-- HELPFUL QUERIES FOR COMMON OPERATIONS
-- ============================================================

/*
-- Find vehicles near a location (within 5km)
SELECT v.id, v.registration_number, 
       ST_Distance(v.current_location::geography, ST_SetSRID(ST_MakePoint(36.8219, -1.2921), 4326)::geography) as distance_meters
FROM vehicles v
WHERE ST_DWithin(
    v.current_location::geography,
    ST_SetSRID(ST_MakePoint(36.8219, -1.2921), 4326)::geography,
    5000
)
ORDER BY distance_meters;

-- Get user's trip history
SELECT t.*, v.registration_number, r.name as route_name
FROM trips t
JOIN vehicles v ON t.vehicle_id = v.id
LEFT JOIN routes r ON t.route_id = r.id
WHERE t.user_id = 'user-uuid-here'
ORDER BY t.start_time DESC;

-- Get driver statistics
SELECT 
    d.id,
    u.name,
    d.rating,
    d.total_trips,
    COUNT(t.id) as trips_this_month,
    AVG(r.rating) as avg_rating_this_month
FROM drivers d
JOIN users u ON d.user_id = u.id
LEFT JOIN trips t ON t.driver_id = d.id AND t.start_time > NOW() - INTERVAL '30 days'
LEFT JOIN ratings r ON r.driver_id = d.id AND r.created_at > NOW() - INTERVAL '30 days'
GROUP BY d.id, u.name, d.rating, d.total_trips;
*/

-- ============================================================
-- END OF THE DATABASE SCHEMA
-- ============================================================
