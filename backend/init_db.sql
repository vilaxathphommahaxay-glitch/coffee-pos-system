-- 📜 ILa HomeBar&Coffee - Optimized Database Script
-- Run this script in PostgreSQL on your Dell Server (192.168.1.50)

-- 1. Create Employee Table
CREATE TABLE IF NOT EXISTS employees (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role VARCHAR(20) DEFAULT 'cashier'
);

-- 2. Create Product Table
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    price FLOAT NOT NULL,
    cost FLOAT DEFAULT 0,
    image_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    stock INTEGER DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);

-- 3. Create Order Table
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    total_amount FLOAT NOT NULL,
    payment_method VARCHAR(20) NOT NULL,
    employee_id INTEGER REFERENCES employees(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    sync_status VARCHAR(20) DEFAULT 'synced'
);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);

-- 4. Create Order Item Table
CREATE TABLE IF NOT EXISTS order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products(id),
    quantity INTEGER NOT NULL,
    price_at_sale FLOAT NOT NULL,
    sweetness VARCHAR(20),
    item_type VARCHAR(20),
    note TEXT
);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
