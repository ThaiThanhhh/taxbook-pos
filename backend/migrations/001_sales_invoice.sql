-- Active: 1794407350093@@127.0.0.1@5432@dt13
-- DRAFT: Chua chay tren database chung
-- Can review schema voi nhom truoc khi ap dung

CREATE TABLE sales (
    id TEXT PRIMARY KEY
        DEFAULT gen_random_uuid()::text,

    client_op_id UUID NOT NULL UNIQUE,

    device_id TEXT NOT NULL,
    local_seq INTEGER NOT NULL
        CHECK (local_seq > 0),

    tmp_number TEXT,

    total_vnd BIGINT NOT NULL
        CHECK (total_vnd >= 0),

    discount_vnd BIGINT NOT NULL DEFAULT 0
        CHECK (discount_vnd >= 0),

    status VARCHAR(20) NOT NULL
        DEFAULT 'SYNCED'
        CHECK (
            status IN (
                'PENDING_SYNC',
                'SYNCED',
                'INVOICED',
                'CANCELED'
            )
        ),

    client_created_at TIMESTAMPTZ NOT NULL,

    created_at TIMESTAMPTZ NOT NULL
        DEFAULT NOW(),

    UNIQUE (device_id, local_seq)
);
-- ==========================================
-- 2. BANG CHI TIET DON HANG
-- ==========================================

CREATE TABLE sale_items (
    id TEXT PRIMARY KEY
        DEFAULT gen_random_uuid()::text,

    sale_id TEXT NOT NULL,

    line_no INTEGER NOT NULL
        CHECK (line_no > 0),

    product_id TEXT NOT NULL,

    qty INTEGER NOT NULL
        CHECK (qty > 0),

    unit_price_vnd BIGINT NOT NULL
        CHECK (unit_price_vnd >= 0),

    line_total_vnd BIGINT GENERATED ALWAYS AS
        (qty::BIGINT * unit_price_vnd) STORED,

    CONSTRAINT fk_sale_items_sale
        FOREIGN KEY (sale_id)
        REFERENCES sales(id)
        ON DELETE RESTRICT,

    CONSTRAINT uq_sale_items_line
        UNIQUE (sale_id, line_no)
);
-- ==========================================
-- 3. BANG THANH TOAN
-- ==========================================

CREATE TABLE payments (
    id TEXT PRIMARY KEY
        DEFAULT gen_random_uuid()::text,

    sale_id TEXT NOT NULL,

    method VARCHAR(20) NOT NULL
        CHECK (
            method IN (
                'CASH',
                'QR_TRANSFER',
                'CARD'
            )
        ),

    amount_vnd BIGINT NOT NULL
        CHECK (amount_vnd >= 0),

    reference TEXT,

    created_at TIMESTAMPTZ NOT NULL
        DEFAULT NOW(),

    CONSTRAINT fk_payments_sale
        FOREIGN KEY (sale_id)
        REFERENCES sales(id)
        ON DELETE RESTRICT
);
-- ==========================================
-- 4. BANG HOA DON
-- ==========================================

CREATE TABLE invoices (
    id TEXT PRIMARY KEY
        DEFAULT gen_random_uuid()::text,

    sale_id TEXT NOT NULL,

    series VARCHAR(50) NOT NULL,
    number VARCHAR(50) NOT NULL,

    status VARCHAR(20) NOT NULL
        CHECK (
            status IN (
                'ISSUED',
                'SENT',
                'REJECTED',
                'CANCELED'
            )
        ),

    provider_ref TEXT,

    issued_at TIMESTAMPTZ,

    attempts INTEGER NOT NULL DEFAULT 0
        CHECK (attempts >= 0),

    last_error TEXT,

    created_at TIMESTAMPTZ NOT NULL
        DEFAULT NOW(),

    CONSTRAINT fk_invoices_sale
        FOREIGN KEY (sale_id)
        REFERENCES sales(id)
        ON DELETE RESTRICT,

    CONSTRAINT uq_invoices_number
        UNIQUE (series, number)
);
-- ==========================================
-- 5. INDEX PHUC VU TRUY VAN
-- ==========================================

CREATE INDEX idx_sales_status
    ON sales(status);

CREATE INDEX idx_sales_created_at
    ON sales(created_at);

CREATE INDEX idx_sale_items_sale_id
    ON sale_items(sale_id);

CREATE INDEX idx_payments_sale_id
    ON payments(sale_id);

CREATE INDEX idx_invoices_sale_id
    ON invoices(sale_id);

CREATE INDEX idx_invoices_status
    ON invoices(status);