-- ============================================
-- Smart Office Queue & Token Management System
-- Database Schema
-- PostgreSQL
-- ============================================

-- 1. Departments
CREATE TABLE departments (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(10) NOT NULL UNIQUE,
    is_paused BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. Users
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role VARCHAR(20) NOT NULL
        CHECK (role IN ('ADMIN', 'STAFF')),
    department_id INTEGER REFERENCES departments(id),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 3. Department Settings
CREATE TABLE department_settings (
    id SERIAL PRIMARY KEY,
    department_id INTEGER NOT NULL UNIQUE
        REFERENCES departments(id) ON DELETE CASCADE,
    avg_service_minutes INTEGER NOT NULL DEFAULT 10,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 4. Tokens
CREATE TABLE tokens (
    id BIGSERIAL PRIMARY KEY,
    token_number VARCHAR(20) NOT NULL,
    department_id INTEGER NOT NULL
        REFERENCES departments(id),

    visitor_name VARCHAR(100),

    priority BOOLEAN NOT NULL DEFAULT FALSE,

    status VARCHAR(30) NOT NULL
        CHECK (
            status IN (
                'WAITING',
                'SERVING',
                'COMPLETED',
                'CANCELLED',
                'NO_SHOW'
            )
        ),

    no_show_count INTEGER NOT NULL DEFAULT 0,

    queue_date DATE NOT NULL DEFAULT CURRENT_DATE,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    called_at TIMESTAMP,
    completed_at TIMESTAMP,
    cancelled_at TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE department_token_counters (
    id SERIAL PRIMARY KEY,
    department_id INTEGER NOT NULL
        REFERENCES departments(id) ON DELETE CASCADE,
    queue_date DATE NOT NULL,
    last_number INTEGER NOT NULL DEFAULT 0,
    UNIQUE (department_id, queue_date)
);
-- 5. Token Events
CREATE TABLE token_events (
    id BIGSERIAL PRIMARY KEY,

    token_id BIGINT NOT NULL
        REFERENCES tokens(id) ON DELETE CASCADE,

    event_type VARCHAR(30) NOT NULL,

    from_department_id INTEGER
        REFERENCES departments(id),

    to_department_id INTEGER
        REFERENCES departments(id),

    performed_by INTEGER
        REFERENCES users(id),

    notes TEXT,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- Indexes
-- ============================================

CREATE INDEX idx_tokens_department_status
ON tokens(department_id, status);

CREATE INDEX idx_tokens_queue
ON tokens(department_id, queue_date, status);

CREATE INDEX idx_token_events_token
ON token_events(token_id);

CREATE INDEX idx_token_counters_department_date
ON department_token_counters(department_id, queue_date);
-- ============================================
-- Seed Departments
-- ============================================

INSERT INTO departments (name, code)
VALUES
    ('IT Support', 'IT'),
    ('HR', 'HR'),
    ('Accounts', 'ACC'),
    ('Administration', 'ADM');

-- ============================================
-- Department Settings
-- ============================================

INSERT INTO department_settings (
    department_id,
    avg_service_minutes
)
SELECT
    id,
    10
FROM departments;
