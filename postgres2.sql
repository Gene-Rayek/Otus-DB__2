CREATE TABLE entities (
  id BIGSERIAL PRIMARY KEY,
  entity_type VARCHAR(30) NOT NULL CHECK (
    entity_type IN ('customer', 'supplier', 'manufacturer')
  ),
  ref_id BIGINT NOT NULL,
  name VARCHAR(150) NOT NULL,
  inn VARCHAR(20),
  is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_entities_type ON entities (entity_type);

CREATE INDEX idx_entities_ref ON entities (ref_id);

CREATE UNIQUE INDEX idx_entities_inn ON entities (inn);

ALTER TABLE entities
ADD CONSTRAINT uq_entities_type_ref UNIQUE (entity_type, ref_id);

CREATE TABLE contacts (
  id BIGSERIAL PRIMARY KEY,
  entity_id BIGINT NOT NULL REFERENCES entities (id) ON UPDATE CASCADE ON DELETE CASCADE,
  full_name VARCHAR(100) NOT NULL,
  position VARCHAR(100),
  comment TEXT,
  is_primary BOOLEAN DEFAULT FALSE
);

CREATE INDEX idx_contacts_entity ON contacts (entity_id);

CREATE INDEX idx_contacts_primary ON contacts (entity_id)
WHERE
  is_primary = TRUE;

ALTER TABLE contacts
ADD CONSTRAINT chk_contacts_fullname CHECK (full_name <> '');

ALTER TABLE contacts
ADD CONSTRAINT uq_contacts_primary UNIQUE (entity_id, is_primary) DEFERRABLE INITIALLY DEFERRED;

CREATE TABLE contact_channels (
  id BIGSERIAL PRIMARY KEY,
  contact_id BIGINT NOT NULL REFERENCES contacts (id) ON UPDATE CASCADE ON DELETE CASCADE,
  channel_type VARCHAR(30) NOT NULL CHECK (
    channel_type IN (
      'phone',
      'email',
      'address',
      'telegram',
      'website'
    )
  ),
  label VARCHAR(50),
  value TEXT NOT NULL,
  is_primary BOOLEAN DEFAULT FALSE
);

CREATE INDEX idx_channels_contact ON contact_channels (contact_id);

CREATE INDEX idx_channels_type ON contact_channels (channel_type);

ALTER TABLE contact_channels
ADD CONSTRAINT chk_channel_value CHECK (length(value) > 0);

ALTER TABLE contact_channels
ADD CONSTRAINT uq_channel_primary UNIQUE (contact_id, channel_type, is_primary) DEFERRABLE INITIALLY DEFERRED;

CREATE TABLE product_categories (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  parent_id BIGINT REFERENCES product_categories (id) ON UPDATE CASCADE ON DELETE SET NULL,
  description TEXT
);

CREATE INDEX idx_category_name ON product_categories (name);

CREATE INDEX idx_category_parent ON product_categories (parent_id);

ALTER TABLE product_categories
ADD CONSTRAINT uq_category_name_parent UNIQUE (name, parent_id);

CREATE TABLE suppliers (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  inn VARCHAR(20),
  contact_name VARCHAR(100),
  phone VARCHAR(30),
  email VARCHAR(100),
  address VARCHAR(255),
  is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_suppliers_name ON suppliers (name);

CREATE INDEX idx_suppliers_email ON suppliers (email);

CREATE INDEX idx_suppliers_phone ON suppliers (phone);

CREATE UNIQUE INDEX idx_suppliers_inn ON suppliers (inn);

ALTER TABLE suppliers
ADD CONSTRAINT uq_suppliers_inn UNIQUE (inn);

CREATE TABLE manufacturers (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  inn VARCHAR(20),
  address VARCHAR(255),
  contact_name VARCHAR(100),
  phone VARCHAR(30),
  email VARCHAR(100),
  is_internal BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_manufacturers_name ON manufacturers (name);

CREATE INDEX idx_manufacturers_inn ON manufacturers (inn);

CREATE INDEX idx_manufacturers_phone ON manufacturers (phone);

ALTER TABLE manufacturers
ADD CONSTRAINT uq_manufacturer_inn UNIQUE (inn);

CREATE TABLE customers (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  type VARCHAR(20) DEFAULT 'b2b',
  inn VARCHAR(20),
  contact_name VARCHAR(100),
  phone VARCHAR(30),
  email VARCHAR(100),
  address VARCHAR(255),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_customers_name ON customers (name);

CREATE INDEX idx_customers_type ON customers (type);

CREATE INDEX idx_customers_inn ON customers (inn);

CREATE INDEX idx_customers_phone ON customers (phone);

ALTER TABLE customers
ADD CONSTRAINT uq_customer_inn UNIQUE (inn);

CREATE TABLE materials (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  type VARCHAR(50),
  thickness_microns NUMERIC(6, 2),
  supplier_id BIGINT REFERENCES suppliers (id) ON UPDATE CASCADE ON DELETE SET NULL,
  unit VARCHAR(20) DEFAULT 'm2',
  sku VARCHAR(50),
  is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_material_name ON materials (name);

CREATE INDEX idx_material_supplier ON materials (supplier_id);

CREATE INDEX idx_material_type_supplier ON materials (type, supplier_id);

ALTER TABLE materials
ADD CONSTRAINT chk_material_thickness CHECK (thickness_microns >= 0);

ALTER TABLE materials
ADD CONSTRAINT uq_material_sku UNIQUE (sku);

CREATE TABLE products (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  category_id BIGINT REFERENCES product_categories (id) ON UPDATE CASCADE ON DELETE RESTRICT,
  material_id BIGINT REFERENCES materials (id) ON UPDATE CASCADE ON DELETE SET NULL,
  code VARCHAR(50) NOT NULL UNIQUE,
  width_mm NUMERIC(5, 2),
  height_mm NUMERIC(5, 2),
  is_datamatrix BOOLEAN DEFAULT TRUE,
  dm_encoding_standard VARCHAR(50),
  dm_module_size_mm NUMERIC(4, 3),
  description TEXT,
  is_custom BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_products_name ON products (name);

CREATE INDEX idx_products_category ON products (category_id);

CREATE INDEX idx_products_material ON products (material_id);

CREATE INDEX idx_products_cat_mat ON products (category_id, material_id);

ALTER TABLE products
ADD CONSTRAINT chk_product_width CHECK (width_mm > 0);

ALTER TABLE products
ADD CONSTRAINT chk_product_height CHECK (height_mm > 0);

ALTER TABLE products
ADD CONSTRAINT uq_product_name_dims UNIQUE (name, width_mm, height_mm);

CREATE TABLE prices (
  id BIGSERIAL PRIMARY KEY,
  product_id BIGINT NOT NULL REFERENCES products (id) ON UPDATE CASCADE ON DELETE CASCADE,
  customer_id BIGINT REFERENCES customers (id) ON UPDATE CASCADE ON DELETE CASCADE,
  price_type VARCHAR(20) DEFAULT 'retail',
  currency VARCHAR(3) DEFAULT 'RUB',
  value NUMERIC(12, 2) NOT NULL CHECK (value >= 0),
  min_qty INT DEFAULT 1,
  valid_from DATE NOT NULL,
  valid_to DATE
);

CREATE INDEX idx_prices_value ON prices (value);

CREATE INDEX idx_prices_product_period ON prices (product_id, valid_from, valid_to);

CREATE INDEX idx_prices_active ON prices (valid_from, valid_to)
WHERE
  valid_to IS NULL
  OR valid_to >= CURRENT_DATE;

ALTER TABLE prices
ADD CONSTRAINT uq_price_period UNIQUE (product_id, customer_id, valid_from);

CREATE TABLE orders (
  id BIGSERIAL PRIMARY KEY,
  customer_id BIGINT NOT NULL REFERENCES customers (id) ON UPDATE CASCADE ON DELETE RESTRICT,
  order_date DATE DEFAULT CURRENT_DATE,
  status VARCHAR(20) DEFAULT 'new',
  total_amount NUMERIC(14, 2) DEFAULT 0,
  currency VARCHAR(3) DEFAULT 'RUB',
  payment_status VARCHAR(20) DEFAULT 'unpaid',
  delivery_date DATE,
  comment TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_orders_customer_date ON orders (customer_id, order_date DESC);

ALTER TABLE orders
ADD CONSTRAINT chk_order_delivery_date CHECK (
  delivery_date IS NULL
  OR delivery_date >= order_date
);

CREATE TABLE order_items (
  id BIGSERIAL PRIMARY KEY,
  order_id BIGINT NOT NULL REFERENCES orders (id) ON UPDATE CASCADE ON DELETE CASCADE,
  product_id BIGINT NOT NULL REFERENCES products (id) ON UPDATE CASCADE ON DELETE RESTRICT,
  quantity INT NOT NULL CHECK (quantity > 0),
  unit_price NUMERIC(12, 2) NOT NULL,
  discount_percent NUMERIC(5, 2) DEFAULT 0 CHECK (discount_percent BETWEEN 0 AND 100),
  line_total NUMERIC(14, 2),
  dm_required BOOLEAN DEFAULT TRUE,
  dm_standard VARCHAR(50),
  comment TEXT
);

CREATE INDEX idx_order_items_product ON order_items (product_id);

CREATE INDEX idx_order_items_dm ON order_items (dm_required);

ALTER TABLE order_items
ADD CONSTRAINT uq_order_item UNIQUE (order_id, product_id);

CREATE TABLE purchase_orders (
  id BIGSERIAL PRIMARY KEY,
  supplier_id BIGINT NOT NULL REFERENCES suppliers (id) ON UPDATE CASCADE ON DELETE RESTRICT,
  order_date DATE DEFAULT CURRENT_DATE,
  status VARCHAR(20) DEFAULT 'new',
  total_amount NUMERIC(14, 2) DEFAULT 0,
  currency VARCHAR(3) DEFAULT 'RUB',
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_purchase_supplier_status ON purchase_orders (supplier_id, status);

CREATE TABLE purchase_order_items (
  id BIGSERIAL PRIMARY KEY,
  purchase_order_id BIGINT NOT NULL REFERENCES purchase_orders (id) ON UPDATE CASCADE ON DELETE CASCADE,
  material_id BIGINT NOT NULL REFERENCES materials (id) ON UPDATE CASCADE ON DELETE RESTRICT,
  quantity NUMERIC(12, 3) NOT NULL CHECK (quantity > 0),
  unit_price NUMERIC(12, 2) NOT NULL CHECK (unit_price >= 0),
  line_total NUMERIC(14, 2)
);

CREATE INDEX idx_purchase_item_material ON purchase_order_items (material_id);

ALTER TABLE purchase_order_items
ADD CONSTRAINT uq_purchase_item UNIQUE (purchase_order_id, material_id);

CREATE TABLE production_orders (
  id BIGSERIAL PRIMARY KEY,
  order_item_id BIGINT NOT NULL REFERENCES order_items (id) ON UPDATE CASCADE ON DELETE RESTRICT,
  manufacturer_id BIGINT NOT NULL REFERENCES manufacturers (id) ON UPDATE CASCADE ON DELETE RESTRICT,
  planned_qty INT NOT NULL CHECK (planned_qty > 0),
  produced_qty INT,
  scrap_qty INT,
  status VARCHAR(20) DEFAULT 'planned',
  planned_start_date DATE,
  planned_end_date DATE,
  actual_start_date DATE,
  actual_end_date DATE
);

CREATE INDEX idx_production_status ON production_orders (status);

ALTER TABLE production_orders
ADD CONSTRAINT chk_production_qty CHECK (
  produced_qty IS NULL
  OR produced_qty <= planned_qty
);

ALTER TABLE production_orders
ADD CONSTRAINT chk_production_scrap CHECK (scrap_qty >= 0);

CREATE TABLE datamatrix_batches (
  id BIGSERIAL PRIMARY KEY,
  production_order_id BIGINT NOT NULL REFERENCES production_orders (id) ON UPDATE CASCADE ON DELETE CASCADE,
  code_prefix VARCHAR(50),
  range_start BIGINT NOT NULL,
  range_end BIGINT NOT NULL,
  printed_at TIMESTAMP DEFAULT NOW(),
  status VARCHAR(20) DEFAULT 'generated',
  CHECK (range_end >= range_start)
);

CREATE INDEX idx_datamatrix_status_date ON datamatrix_batches (status, printed_at DESC);

ALTER TABLE datamatrix_batches
ADD CONSTRAINT chk_dm_range CHECK (
  range_end >= range_start
  AND range_start > 0
);

ALTER TABLE datamatrix_batches
ADD CONSTRAINT uq_dm_range UNIQUE (code_prefix, range_start, range_end);