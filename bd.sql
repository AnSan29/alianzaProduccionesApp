-- ====================================================================
--  ALIANZA PRODUCCIONES - Esquema relacional normalizado (1NF/2NF/3NF)
--  Requisitos cubiertos: cotizaciones, reservas, eventos, pagos,
--  descuentos/cargos, ciudades múltiples, roles y fidelidad.
--  Motor y colación recomendados: InnoDB + utf8mb4
-- ====================================================================

-- 1) Creación y selección de base de datos
DROP DATABASE IF EXISTS alianza_producciones;
CREATE DATABASE alianza_producciones
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE alianza_producciones;

-- 2) Tablas maestras (lookups)
-- ------------------------------------------------

-- Marca única (por si a futuro hubiera más marcas/filiales)
CREATE TABLE brand (
  brand_id      BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT 'PK',
  name          VARCHAR(120) NOT NULL UNIQUE COMMENT 'Nombre de marca (único)',
  legal_name    VARCHAR(200) NULL COMMENT 'Razón social',
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB COMMENT='Marcas. V1: tendrá 1 fila: "Alianza Producciones"';

-- Ciudades operativas (escalable a más)
CREATE TABLE city (
  city_id       BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT 'PK',
  name          VARCHAR(120) NOT NULL UNIQUE COMMENT 'Nombre de ciudad (único)',
  state_region  VARCHAR(120) NULL,
  country       VARCHAR(120) NOT NULL DEFAULT 'Colombia'
) ENGINE=InnoDB COMMENT='Ciudades operativas';

-- Roles de usuario
CREATE TABLE role (
  role_id       TINYINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT 'PK',
  name          VARCHAR(40) NOT NULL UNIQUE COMMENT 'Admin | User'
) ENGINE=InnoDB COMMENT='Roles de usuario';

-- Niveles de fidelidad (para aplicar descuentos por cliente frecuente)
CREATE TABLE loyalty_level (
  loyalty_level_id TINYINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT 'PK',
  code             VARCHAR(40) NOT NULL UNIQUE COMMENT 'Ej: STANDARD, SILVER, GOLD',
  min_completed_reservations INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Umbral de reservas concretadas',
  discount_percent DECIMAL(5,2) NOT NULL DEFAULT 0.00 CHECK (discount_percent BETWEEN 0 AND 100)
) ENGINE=InnoDB COMMENT='Niveles de fidelidad y % descuento estándar';

-- Métodos de pago (catálogo)
CREATE TABLE payment_method (
  payment_method_id TINYINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT 'PK',
  name              VARCHAR(60) NOT NULL UNIQUE COMMENT 'Transferencia, Efectivo, etc.'
) ENGINE=InnoDB COMMENT='Catálogo de métodos de pago';

-- Estados de cotización
CREATE TABLE status_quote (
  status_quote_id TINYINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT 'PK',
  code            VARCHAR(30) NOT NULL UNIQUE COMMENT 'PENDING | ACCEPTED | REJECTED'
) ENGINE=InnoDB COMMENT='Estados de cotización';

-- Estados de evento
CREATE TABLE status_event (
  status_event_id TINYINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT 'PK',
  code            VARCHAR(30) NOT NULL UNIQUE COMMENT 'ACTIVE | CANCELED | FINISHED'
) ENGINE=InnoDB COMMENT='Estados de evento';

-- 3) Usuarios / Clientes
-- ------------------------------------------------
CREATE TABLE user (
  user_id        BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT 'PK',
  role_id        TINYINT UNSIGNED NOT NULL COMMENT 'FK -> role.role_id',
  loyalty_level_id TINYINT UNSIGNED NULL COMMENT 'FK -> loyalty_level.loyalty_level_id (derivado por actividad)',
  brand_id       BIGINT UNSIGNED NOT NULL COMMENT 'FK -> brand.brand_id (multi-marca, aquí fija)',
  email          VARCHAR(180) NOT NULL UNIQUE,
  phone          VARCHAR(30) NULL,
  full_name      VARCHAR(160) NOT NULL,
  hashed_password VARCHAR(255) NULL COMMENT 'Si se maneja autenticación local',
  is_active      BOOLEAN NOT NULL DEFAULT TRUE,
  created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_user_role
    FOREIGN KEY (role_id) REFERENCES role(role_id),
  CONSTRAINT fk_user_brand
    FOREIGN KEY (brand_id) REFERENCES brand(brand_id),
  CONSTRAINT fk_user_loyalty
    FOREIGN KEY (loyalty_level_id) REFERENCES loyalty_level(loyalty_level_id)
) ENGINE=InnoDB COMMENT='Usuarios y clientes (Admin/User)';

-- Direcciones de usuario (un usuario puede tener varias)
CREATE TABLE user_address (
  user_address_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT 'PK',
  user_id         BIGINT UNSIGNED NOT NULL COMMENT 'FK -> user.user_id',
  city_id         BIGINT UNSIGNED NOT NULL COMMENT 'FK -> city.city_id',
  street_address  VARCHAR(200) NOT NULL,
  reference_note  VARCHAR(200) NULL,
  is_primary      BOOLEAN NOT NULL DEFAULT FALSE,
  is_rural        BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Marca zona rural para cargos',
  latitude        DECIMAL(10,7) NULL,
  longitude       DECIMAL(10,7) NULL,
  CONSTRAINT fk_uaddr_user
    FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE,
  CONSTRAINT fk_uaddr_city
    FOREIGN KEY (city_id) REFERENCES city(city_id)
) ENGINE=InnoDB COMMENT='Direcciones del usuario/cliente';

-- 4) Catálogo de productos de alquiler
-- ------------------------------------------------
CREATE TABLE product (
  product_id     BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT 'PK',
  brand_id       BIGINT UNSIGNED NOT NULL COMMENT 'FK -> brand.brand_id',
  name           VARCHAR(160) NOT NULL,
  description    TEXT NULL,
  image_url      VARCHAR(400) NULL,
  base_price     DECIMAL(12,2) NOT NULL CHECK (base_price >= 0),
  sku            VARCHAR(80) NULL UNIQUE,
  is_active      BOOLEAN NOT NULL DEFAULT TRUE,
  created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_product_unique UNIQUE (brand_id, name),
  CONSTRAINT fk_product_brand
    FOREIGN KEY (brand_id) REFERENCES brand(brand_id)
) ENGINE=InnoDB COMMENT='Ítems de alquiler (precio base unitario)';

-- 5) Flujo de cotización
-- ------------------------------------------------

-- Cotización (encabezado)
CREATE TABLE quote (
  quote_id         BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT 'PK',
  status_quote_id  TINYINT UNSIGNED NOT NULL COMMENT 'FK -> status_quote',
  requester_user_id BIGINT UNSIGNED NOT NULL COMMENT 'FK -> user.user_id (cliente)',
  admin_owner_id   BIGINT UNSIGNED NULL COMMENT 'FK -> user.user_id (admin asignado)',
  brand_id         BIGINT UNSIGNED NOT NULL COMMENT 'FK -> brand.brand_id',
  event_title      VARCHAR(200) NOT NULL,
  service_address_id BIGINT UNSIGNED NULL COMMENT 'FK -> user_address.user_address_id (lugar del evento)',
  requested_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  notes_internal   VARCHAR(500) NULL,
  -- Totales denormalizados para rapidez de lectura (se pueden recalcular)
  subtotal_items   DECIMAL(12,2) NOT NULL DEFAULT 0.00 CHECK (subtotal_items >= 0),
  total_adjustments DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT 'Descuentos (-) y cargos (+)',
  total_amount     DECIMAL(12,2) NOT NULL DEFAULT 0.00 CHECK (total_amount >= 0),
  CONSTRAINT fk_quote_status
    FOREIGN KEY (status_quote_id) REFERENCES status_quote(status_quote_id),
  CONSTRAINT fk_quote_requester
    FOREIGN KEY (requester_user_id) REFERENCES user(user_id),
  CONSTRAINT fk_quote_admin
    FOREIGN KEY (admin_owner_id) REFERENCES user(user_id),
  CONSTRAINT fk_quote_brand
    FOREIGN KEY (brand_id) REFERENCES brand(brand_id),
  CONSTRAINT fk_quote_service_addr
    FOREIGN KEY (service_address_id) REFERENCES user_address(user_address_id)
) ENGINE=InnoDB COMMENT='Cotizaciones (PENDING/ACCEPTED/REJECTED)';

-- Múltiples horarios solicitados en la cotización (24/7)
CREATE TABLE quote_slot (
  quote_slot_id  BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT 'PK',
  quote_id       BIGINT UNSIGNED NOT NULL COMMENT 'FK -> quote.quote_id',
  start_datetime DATETIME NOT NULL,
  end_datetime   DATETIME NOT NULL,
  CHECK (end_datetime > start_datetime),
  CONSTRAINT fk_qslot_quote
    FOREIGN KEY (quote_id) REFERENCES quote(quote_id) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Bloques de tiempo solicitados en la cotización';

-- Detalle de ítems en la cotización (cantidad * precio_unitario)
CREATE TABLE quote_item (
  quote_item_id  BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT 'PK',
  quote_id       BIGINT UNSIGNED NOT NULL COMMENT 'FK -> quote.quote_id',
  product_id     BIGINT UNSIGNED NOT NULL COMMENT 'FK -> product.product_id',
  quantity       INT UNSIGNED NOT NULL CHECK (quantity > 0),
  unit_price     DECIMAL(12,2) NOT NULL CHECK (unit_price >= 0),
  line_total     DECIMAL(12,2) NOT NULL CHECK (line_total >= 0),
  CONSTRAINT uq_quote_product UNIQUE (quote_id, product_id),
  CONSTRAINT fk_qitem_quote
    FOREIGN KEY (quote_id) REFERENCES quote(quote_id) ON DELETE CASCADE,
  CONSTRAINT fk_qitem_product
    FOREIGN KEY (product_id) REFERENCES product(product_id)
) ENGINE=InnoDB COMMENT='Ítems de la cotización';

-- Ajustes de la cotización: descuentos o cargos (incluye cargo por zona rural)
CREATE TABLE quote_adjustment (
  quote_adjustment_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT 'PK',
  quote_id       BIGINT UNSIGNED NOT NULL COMMENT 'FK -> quote.quote_id',
  kind           ENUM('DISCOUNT','SURCHARGE') NOT NULL,
  reason         VARCHAR(200) NOT NULL COMMENT 'Ej: Fidelidad GOLD, Zona rural',
  amount         DECIMAL(12,2) NOT NULL COMMENT 'Valor (+cargo / -descuento)',
  CHECK ((kind = 'DISCOUNT' AND amount <= 0) OR (kind = 'SURCHARGE' AND amount >= 0)),
  CONSTRAINT fk_qadj_quote
    FOREIGN KEY (quote_id) REFERENCES quote(quote_id) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Ajustes monetarios de la cotización';

-- 6) Reserva (a partir de una cotización aceptada) y evento
-- ------------------------------------------------

-- Reserva: exige depósito (rastreo en payments). La lógica del 50% se valida a nivel app / vista.
CREATE TABLE reservation (
  reservation_id  BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT 'PK',
  quote_id        BIGINT UNSIGNED NOT NULL UNIQUE COMMENT 'FK -> quote.quote_id (1:1)',
  reserved_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  confirmed_by_admin_id BIGINT UNSIGNED NULL COMMENT 'FK -> user.user_id',
  CONSTRAINT fk_reservation_quote
    FOREIGN KEY (quote_id) REFERENCES quote(quote_id),
  CONSTRAINT fk_reservation_admin
    FOREIGN KEY (confirmed_by_admin_id) REFERENCES user(user_id)
) ENGINE=InnoDB COMMENT='Reserva creada desde una cotización ACCEPTED';

-- Evento operativo (si se cancela, depósito no reembolsable queda registrado en payments)
CREATE TABLE event (
  event_id        BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT 'PK',
  reservation_id  BIGINT UNSIGNED NOT NULL UNIQUE COMMENT 'FK -> reservation.reservation_id (1:1)',
  status_event_id TINYINT UNSIGNED NOT NULL COMMENT 'FK -> status_event.status_event_id',
  active_city_id  BIGINT UNSIGNED NOT NULL COMMENT 'FK -> city.city_id (ciudad operativa encargada)',
  created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  canceled_at     DATETIME NULL,
  CONSTRAINT fk_event_reservation
    FOREIGN KEY (reservation_id) REFERENCES reservation(reservation_id),
  CONSTRAINT fk_event_status
    FOREIGN KEY (status_event_id) REFERENCES status_event(status_event_id),
  CONSTRAINT fk_event_city
    FOREIGN KEY (active_city_id) REFERENCES city(city_id)
) ENGINE=InnoDB COMMENT='Evento asociado a la reserva (ACTIVE/CANCELED/FINISHED)';

-- Slots reales del evento (pueden diferir de lo solicitado en la cotización)
CREATE TABLE event_slot (
  event_slot_id   BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT 'PK',
  event_id        BIGINT UNSIGNED NOT NULL COMMENT 'FK -> event.event_id',
  start_datetime  DATETIME NOT NULL,
  end_datetime    DATETIME NOT NULL,
  CHECK (end_datetime > start_datetime),
  CONSTRAINT fk_eslot_event
    FOREIGN KEY (event_id) REFERENCES event(event_id) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Bloques de tiempo operativos del evento';

-- 7) Pagos (depósito 50% y saldo). No manejamos pasarela; solo registro contable.
-- ------------------------------------------------
CREATE TABLE payment (
  payment_id        BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT 'PK',
  reservation_id    BIGINT UNSIGNED NOT NULL COMMENT 'FK -> reservation.reservation_id',
  payment_method_id TINYINT UNSIGNED NOT NULL COMMENT 'FK -> payment_method.payment_method_id',
  kind              ENUM('DEPOSIT','BALANCE','ADJUSTMENT','REFUND') NOT NULL,
  amount            DECIMAL(12,2) NOT NULL CHECK (amount > 0),
  is_refundable     BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Depósito: FALSE (no reembolsable)',
  paid_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  reference_code    VARCHAR(120) NULL COMMENT 'Referencia interna/externa',
  notes             VARCHAR(300) NULL,
  CONSTRAINT fk_payment_reservation
    FOREIGN KEY (reservation_id) REFERENCES reservation(reservation_id) ON DELETE CASCADE,
  CONSTRAINT fk_payment_method
    FOREIGN KEY (payment_method_id) REFERENCES payment_method(payment_method_id)
) ENGINE=InnoDB COMMENT='Pagos asociados a una reserva';

-- 8) Datos iniciales básicos (seed)
-- ------------------------------------------------
INSERT INTO brand(name, legal_name) VALUES ('Alianza Producciones', 'Alianza Producciones S.A.S.');
INSERT INTO city(name, state_region, country) VALUES
  ('Barranquilla','Atlántico','Colombia'),
  ('Santa Marta','Magdalena','Colombia'),
  ('Cartagena','Bolívar','Colombia');

INSERT INTO role(name) VALUES ('Admin'), ('User');

INSERT INTO status_quote(code) VALUES ('PENDING'), ('ACCEPTED'), ('REJECTED');
INSERT INTO status_event(code) VALUES ('ACTIVE'), ('CANCELED'), ('FINISHED');

INSERT INTO payment_method(name) VALUES ('Transferencia'), ('Efectivo'), ('Tarjeta');

INSERT INTO loyalty_level(code, min_completed_reservations, discount_percent) VALUES
  ('STANDARD', 0, 0.00),
  ('SILVER',   3, 5.00),
  ('GOLD',     8, 10.00),
  ('PLATINUM', 15, 15.00);

-- 9) Vistas de apoyo (KPIs y validación de depósito)
-- ------------------------------------------------

-- KPI administrativos: cantidad de cotizaciones y eventos activos
CREATE OR REPLACE VIEW vw_admin_kpis AS
SELECT
  (SELECT COUNT(*) FROM quote)                                  AS total_quotes,
  (SELECT COUNT(*) FROM quote q WHERE q.status_quote_id =
      (SELECT status_quote_id FROM status_quote WHERE code='PENDING'))  AS quotes_pending,
  (SELECT COUNT(*) FROM quote q WHERE q.status_quote_id =
      (SELECT status_quote_id FROM status_quote WHERE code='ACCEPTED')) AS quotes_accepted,
  (SELECT COUNT(*) FROM event e WHERE e.status_event_id =
      (SELECT status_event_id FROM status_event WHERE code='ACTIVE'))   AS events_active;

-- Estado del depósito (>= 50% del total de la cotización) por reserva
CREATE OR REPLACE VIEW vw_reservation_deposit_status AS
SELECT
  r.reservation_id,
  q.total_amount,
  SUM(CASE WHEN p.kind='DEPOSIT' THEN p.amount ELSE 0 END) AS deposit_paid,
  CASE
    WHEN SUM(CASE WHEN p.kind='DEPOSIT' THEN p.amount ELSE 0 END) >= (q.total_amount * 0.50)
      THEN TRUE ELSE FALSE
  END AS has_minimum_deposit
FROM reservation r
JOIN quote q       ON q.quote_id = r.quote_id
LEFT JOIN payment p ON p.reservation_id = r.reservation_id
GROUP BY r.reservation_id, q.total_amount;

-- ====================================================================
-- Notas de normalización:
-- 1NF: Atributos atómicos; horarios separados en *_slot; items en quote_item.
-- 2NF: Todas las columnas no-clave dependen de la PK completa (p.ej., quote_item usa PK surrogate;
--      no hay atributos que dependan parcialmente de una clave compuesta).
-- 3NF: No hay dependencias transitivas entre no-claves (p.ej., estados/roles se aíslan en catálogos).
-- Totales en quote son campos derivados guardados por conveniencia (se pueden recalcular); no rompen 3NF
-- siempre que la app garantice su consistencia con triggers o lógica de aplicación.
-- ====================================================================
