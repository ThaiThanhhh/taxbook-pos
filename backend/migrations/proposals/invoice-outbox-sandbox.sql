
-- CHI SU DUNG CHO DATABASE THU NGHIEM
-- Chua phai migration production.

DO $$
BEGIN
    IF current_database() <> 'taxbook_sales_test' THEN
        RAISE EXCEPTION
            'Chi duoc chay tren taxbook_sales_test';
    END IF;

    IF to_regclass('public.sales') IS NULL
       OR to_regclass('public.invoices') IS NULL THEN
        RAISE EXCEPTION
            'Chua co bang sales hoac invoices';
    END IF;

    IF to_regclass('public.invoice_outbox') IS NOT NULL THEN
        RAISE EXCEPTION
            'Bang invoice_outbox da ton tai';
    END IF;
END
$$;

CREATE TABLE public.invoice_outbox (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    household_id TEXT NOT NULL
        CHECK (length(btrim(household_id)) BETWEEN 1 AND 200),

    sale_id TEXT NOT NULL UNIQUE
        REFERENCES public.sales(id) ON DELETE RESTRICT,

    -- Co dinh invoice_id de gui lai khong doi ma.
    invoice_id TEXT NOT NULL UNIQUE
        DEFAULT gen_random_uuid()::text,

    amount_vnd BIGINT NOT NULL
        CHECK (amount_vnd BETWEEN 1 AND 9007199254740991),

    status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
        CHECK (
            status IN (
                'PENDING',
                'PROCESSING',
                'RETRY',
                'ISSUED',
                'FAILED'
            )
        ),

    attempts INTEGER NOT NULL DEFAULT 0
        CHECK (attempts >= 0),

    next_retry_at TIMESTAMPTZ DEFAULT NOW(),

    lease_until TIMESTAMPTZ,

    last_error TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_invoice_outbox_retry
ON public.invoice_outbox(next_retry_at, created_at)
WHERE status IN ('PENDING', 'RETRY');

CREATE INDEX idx_invoice_outbox_household
ON public.invoice_outbox(household_id, created_at DESC);
