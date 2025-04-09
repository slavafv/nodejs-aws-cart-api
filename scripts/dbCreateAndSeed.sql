-- First, clean up existing tables and types
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS cart_items CASCADE;
DROP TABLE IF EXISTS carts CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TYPE IF EXISTS order_status CASCADE;
DROP TYPE IF EXISTS cart_status CASCADE;

CREATE TYPE order_status AS ENUM ('CREATED', 'PAID', 'SHIPPED', 'DELIVERED', 'CANCELLED');
CREATE TYPE cart_status AS ENUM ('OPEN', 'ORDERED');

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_DATE,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_DATE
);

-- Create carts table with user foreign key
CREATE TABLE carts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_DATE,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_DATE,
    status cart_status NOT NULL DEFAULT 'OPEN',
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE cart_items (
    cart_id UUID NOT NULL,
    product_id UUID NOT NULL,
    count INTEGER NOT NULL CHECK (count > 0),
    PRIMARY KEY (cart_id, product_id),
    FOREIGN KEY (cart_id) REFERENCES carts(id)
);

CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    cart_id UUID NOT NULL,
    payment JSONB NOT NULL,
    delivery JSONB NOT NULL,
    comments TEXT,
    status order_status NOT NULL DEFAULT 'CREATED',
    total DECIMAL(10,2) NOT NULL CHECK (total >= 0),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_DATE,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_DATE,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (cart_id) REFERENCES carts(id)
);

-- Insert test data
INSERT INTO users (id, email, password) VALUES
(
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'user1@example.com',
    'hashed_password_1'
),
(
    'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22',
    'user2@example.com',
    'hashed_password_2'
),
(
    'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a33',
    'user3@example.com',
    'hashed_password_3'
);

INSERT INTO carts (id, user_id, created_at, updated_at, status) VALUES
(
    'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380a44',
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    CURRENT_DATE,
    CURRENT_DATE,
    'OPEN'
),
(
    'e0eebc99-9c0b-4ef8-bb6d-6bb9bd380a55',
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    CURRENT_DATE - 2,
    CURRENT_DATE - 1,
    'ORDERED'
),
(
    'f0eebc99-9c0b-4ef8-bb6d-6bb9bd380a66',
    'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22',
    CURRENT_DATE - 5,
    CURRENT_DATE - 5,
    'ORDERED'
);

INSERT INTO cart_items (cart_id, product_id, count) VALUES
(
    'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380a44',
    '10eebc99-9c0b-4ef8-bb6d-6bb9bd380a77',
    2
),
(
    'e0eebc99-9c0b-4ef8-bb6d-6bb9bd380a55',
    '20eebc99-9c0b-4ef8-bb6d-6bb9bd380a88',
    3
),
(
    'f0eebc99-9c0b-4ef8-bb6d-6bb9bd380a66',
    '30eebc99-9c0b-4ef8-bb6d-6bb9bd380a99',
    5
);

-- Insert orders for the ORDERED carts
INSERT INTO orders (
    id,
    user_id,
    cart_id,
    payment,
    delivery,
    comments,
    status,
    total
) VALUES
(
    '40eebc99-9c0b-4ef8-bb6d-6bb9bd380aa1',
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'e0eebc99-9c0b-4ef8-bb6d-6bb9bd380a55',
    '{"method": "credit_card", "card_last4": "4242", "amount": 150.00}'::jsonb,
    '{"address": "123 Main St", "city": "Boston", "zip": "02101"}'::jsonb,
    'Please deliver in the morning',
    'PAID',
    150.00
),
(
    '50eebc99-9c0b-4ef8-bb6d-6bb9bd380aa2',
    'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22',
    'f0eebc99-9c0b-4ef8-bb6d-6bb9bd380a66',
    '{"method": "paypal", "email": "user2@example.com", "amount": 299.99}'::jsonb,
    '{"address": "456 Oak St", "city": "New York", "zip": "10001"}'::jsonb,
    NULL,
    'SHIPPED',
    299.99
);

-- Verify the data
SELECT * FROM users ORDER BY created_at DESC;

SELECT 
    c.id as cart_id,
    c.status as cart_status,
    u.email as user_email,
    c.created_at,
    c.updated_at
FROM carts c
JOIN users u ON c.user_id = u.id
ORDER BY c.created_at DESC;

SELECT 
    o.id as order_id,
    u.email as user_email,
    o.status as order_status,
    o.total,
    ci.product_id,
    ci.count,
    o.payment->>'method' as payment_method,
    o.delivery->>'address' as delivery_address
FROM orders o
JOIN users u ON o.user_id = u.id
JOIN cart_items ci ON ci.cart_id = o.cart_id
ORDER BY o.created_at DESC;