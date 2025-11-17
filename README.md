# Otus-DB__2
Анализ таблиц, индексы и логические ограничения для БД labels_datamatrix

1. Анализ таблицы entities
Используется для хранения всех организаций (клиентов, поставщиков, производителей).

Возможные запросы / ограничения
| Поле        | Описание запроса               | Кардинальность      | Ограничения     |
| ----------- | ------------------------------ | ------------------- | --------------- |
| id          | Поиск по id сущности           | Высокая             | PRIMARY KEY     |
| entity_type | Поиск всех customers/suppliers | Низкая (3 значения) | CHECK, NOT NULL |
| ref_id      | Привязка к исходной таблице    | Высокая             | NOT NULL        |
| name        | Поиск по имени                 | Высокая             | NOT NULL        |
| inn         | Поиск по ИНН                   | Средняя             | UNIQUE          |
| is_active   | Фильтр активных сущностей      | Средняя             | BOOLEAN         |

Индексы
- CREATE INDEX idx_entities_type ON entities(entity_type);
- CREATE INDEX idx_entities_ref ON entities(ref_id);
- CREATE UNIQUE INDEX idx_entities_inn ON entities(inn);

Огранияения
- ALTER TABLE entities
    ADD CONSTRAINT uq_entities_type_ref UNIQUE (entity_type, ref_id);

2. Анализ таблицы contacts

Возможные запросы / ограничения
| Поле       | Описание запроса           | Кардинальность | Ограничения |
| ---------- | -------------------------- | -------------- | ----------- |
| id         | Поиск контакта             | Высокая        | PRIMARY KEY |
| entity_id  | Выборка контактов сущности | Высокая        | FK NOT NULL |
| full_name  | Поиск по ФИО               | Высокая        | NOT NULL    |
| is_primary | Поиск главных контактов    | Низкая         | BOOLEAN     |
| position   | Фильтр по должности        | Средняя        | —           |

Индексы
- CREATE INDEX idx_contacts_entity ON contacts(entity_id);
- CREATE INDEX idx_contacts_primary ON contacts(entity_id) WHERE is_primary = TRUE;

Ограничения
- ALTER TABLE contacts
    ADD CONSTRAINT uq_contacts_primary UNIQUE (entity_id, is_primary)
    DEFERRABLE INITIALLY DEFERRED;

3. Анализ таблицы contact_channels

Возможные запросы / ограничения
| Поле         | Описание запроса            | Кардинальность | Ограничения |
| ------------ | --------------------------- | -------------- | ----------- |
| id           | Поиск канала                | Высокая        | PRIMARY KEY |
| contact_id   | Выбор всех каналов контакта | Высокая        | FK NOT NULL |
| channel_type | Поиск по типу канала        | Низкая         | CHECK       |
| value        | Поиск по e-mail/телу/TG     | Высокая        | NOT NULL    |

Индексы

- CREATE INDEX idx_channels_type ON contact_channels(channel_type);
- CREATE INDEX idx_channels_contact ON contact_channels(contact_id);

Ограничения 
- ALTER TABLE contact_channels
    ADD CONSTRAINT chk_channel_value CHECK (length(value) > 0);
- ALTER TABLE contact_channels
    ADD CONSTRAINT uq_channel_primary UNIQUE (contact_id, channel_type, is_primary)
    DEFERRABLE INITIALLY DEFERRED;

4. Анализ таблицы product_categories

Возможные запросы / ограничения
| Поле      | Описание запроса           | Кардинальность | Ограничения |
| --------- | -------------------------- | -------------- | ----------- |
| id        | Поиск категории            | Средняя        | PRIMARY KEY |
| name      | Поиск по наименованию      | Средняя        | NOT NULL    |
| parent_id | Выборка дочерних категорий | Средняя        | FK          |

Индексы
- CREATE INDEX idx_category_name ON product_categories(name);
- CREATE INDEX idx_category_parent ON product_categories(parent_id);

Ограничения
- ALTER TABLE product_categories
    ADD CONSTRAINT uq_category_name_parent UNIQUE (name, parent_id);

5. Анализ таблицы materials

Возможные запросы / ограничения

| Поле        | Запрос                          | Кардинальность | Ограничения |
| ----------- | ------------------------------- | -------------- | ----------- |
| id          | Поиск материала                 | Высокая        | PRIMARY KEY |
| name        | Поиск по названию               | Средняя        | NOT NULL    |
| type        | Фильтр по типу (бумага/пластик) | Низкая         | —           |
| supplier_id | Поиск материалов поставщика     | Средняя        | FK          |

Индексы

- CREATE INDEX idx_material_type_supplier 
    ON materials(type, supplier_id);
- CREATE INDEX idx_material_supplier ON materials(supplier_id);

Ограничения
- ALTER TABLE materials
    ADD CONSTRAINT chk_material_thickness CHECK (thickness_microns >= 0);
- ALTER TABLE materials
    ADD CONSTRAINT uq_material_sku UNIQUE (sku);


6. Анализ таблицы products

Возможные запросы / ограничения

| Поле        | Запрос                     | Кардинальность | Ограничения |
| ----------- | -------------------------- | -------------- | ----------- |
| id          | Поиск по id                | Высокая        | PRIMARY KEY |
| name        | Поиск по названию          | Высокая        | NOT NULL    |
| category_id | Поиск по категории         | Средняя        | FK          |
| material_id | Поиск по материалу         | Высокая        | FK          |
| code        | Поиск продукта по артикулу | Высокая        | UNIQUE      |

Индексы

- CREATE INDEX idx_products_name ON products(name);
- CREATE INDEX idx_products_cat_mat ON products(category_id, material_id);
- CREATE INDEX idx_products_material ON products(material_id);

Ограничения
- ALTER TABLE products
    ADD CONSTRAINT chk_product_width CHECK (width_mm > 0);
- ALTER TABLE products
    ADD CONSTRAINT chk_product_height CHECK (height_mm > 0);
- ALTER TABLE products
    ADD CONSTRAINT uq_product_name_dims UNIQUE (name, width_mm, height_mm);
  
7. Анализ таблицы prices

Возможные запросы / ограничения

| Поле                  | Запрос                  | Кардинальность | Ограничения      |
| --------------------- | ----------------------- | -------------- | ---------------- |
| id                    | Поиск цены              | Высокая        | PRIMARY KEY      |
| product_id            | История цен по продукту | Высокая        | FK               |
| customer_id           | Индивидуальная цена     | Средняя        | FK               |
| value                 | Поиск по цене           | Высокая        | CHECK(value ≥ 0) |
| valid_from / valid_to | Поиск актуальных цен    | Высокая        | NOT NULL         |

Индексы

- CREATE INDEX idx_prices_product_period 
    ON prices(product_id, valid_from, valid_to);

- CREATE INDEX idx_prices_value ON prices(value);

- CREATE INDEX idx_prices_active
    ON prices(valid_from, valid_to)
    WHERE valid_to IS NULL OR valid_to >= CURRENT_DATE;

Ограничения
- ALTER TABLE prices
    ADD CONSTRAINT uq_price_period UNIQUE (product_id, customer_id, valid_from); 

8. Анализ таблицы orders
   
Возможные запросы / ограничения

| Поле         | Запрос                  | Кардинальность | Ограничения |
| ------------ | ----------------------- | -------------- | ----------- |
| id           | Поиск заказа            | Высокая        | PRIMARY KEY |
| customer_id  | История заказов клиента | Высокая        | FK          |
| order_date   | Поиск по дате           | Высокая        | NOT NULL    |
| status       | Фильтрация заказов      | Низкая         | CHECK       |
| total_amount | Аналитика по суммам     | Высокая        | CHECK ≥0    |

Индексы
- CREATE INDEX idx_orders_customer_date 
    ON orders(customer_id, order_date DESC);
Ограничения
- ALTER TABLE orders
    ADD CONSTRAINT chk_order_delivery_date CHECK (delivery_date IS NULL OR delivery_date >= order_date);

9. Анализ таблицы order_items

Возможные запросы / ограничения
| Поле        | Запрос                 | Кардинальность | Ограничения |
| ----------- | ---------------------- | -------------- | ----------- |
| id          | Поиск позиции          | Высокая        | PRIMARY KEY |
| order_id    | Позиции заказа         | Высокая        | FK          |
| product_id  | Аналитика продаж       | Высокая        | FK          |
| dm_required | Фильтр “с DM / без DM” | Низкая         | —           |

Индексы
- CREATE INDEX idx_order_items_product ON order_items(product_id);
- CREATE INDEX idx_order_items_dm ON order_items(dm_required);

Ограничения
- ALTER TABLE order_items
    ADD CONSTRAINT uq_order_item UNIQUE (order_id, product_id);
  
10. Анализ таблицы purchase_orders

| Поле        | Запрос             | Кардинальность | Ограничения |
| ----------- | ------------------ | -------------- | ----------- |
| id          | Поиск закупки      | Высокая        | PRIMARY KEY |
| supplier_id | Закупки поставщика | Высокая        | FK          |
| status      | Статус закупки     | Низкая         | —           |

Индексы
- CREATE INDEX idx_purchase_supplier_status 
    ON purchase_orders(supplier_id, status);

11. Анализ таблицы production_orders

| Поле          | Запрос               | Кардинальность | Ограничения |
| ------------- | -------------------- | -------------- | ----------- |
| id            | Поиск произв. заказа | Высокая        | PRIMARY KEY |
| status        | Фильтр по статусу    | Низкая         | —           |
| order_item_id | Связанные позиции    | Высокая        | FK          |

Индексы
- CREATE INDEX idx_production_status 
    ON production_orders(status);

 Ограничения

 - ALTER TABLE production_orders
    ADD CONSTRAINT chk_production_qty CHECK (produced_qty IS NULL OR produced_qty <= planned_qty);
- ALTER TABLE production_orders
    ADD CONSTRAINT chk_production_scrap CHECK (scrap_qty >= 0);


12. Анализ таблицы datamatrix_batches

| Поле       | Запрос                | Кардинальность | Ограничения |
| ---------- | --------------------- | -------------- | ----------- |
| id         | Поиск партии          | Высокая        | PRIMARY KEY |
| status     | Фильтрация по статусу | Низкая         | —           |
| printed_at | Последние партии      | Высокая        | —           |

Индексы
- CREATE INDEX idx_datamatrix_status_date
    ON datamatrix_batches(status, printed_at DESC);

Ограничения 
- ALTER TABLE datamatrix_batches
    ADD CONSTRAINT chk_dm_range CHECK (range_end >= range_start AND range_start > 0);
- ALTER TABLE datamatrix_batches
    ADD CONSTRAINT uq_dm_range UNIQUE (code_prefix, range_start, range_end);
