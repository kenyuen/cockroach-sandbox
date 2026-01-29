-- GENERATED SQL equivalent of liquibase changelog 001-create-customer.xml
-- Creates schema `customers` and table `customers.customer` suitable for sharding by region

CREATE SCHEMA IF NOT EXISTS customers;

CREATE TABLE IF NOT EXISTS customers.customer (
  id UUID PRIMARY KEY NOT NULL,
  region VARCHAR(32) NOT NULL,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  email VARCHAR(255),
  phone VARCHAR(50),
  address VARCHAR(500),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_customer_region ON customers.customer (region);
CREATE UNIQUE INDEX IF NOT EXISTS idx_customer_email ON customers.customer (email);
