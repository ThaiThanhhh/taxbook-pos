
-- Chỉ cho phép tạo bảng trong database thử nghiệm.
DO $$
BEGIN
  IF current_database() <> 'taxbook_sales_test' THEN
    RAISE EXCEPTION
      'Sai database! Chi duoc chay tren taxbook_sales_test';
  END IF;

  IF to_regclass('public.ledger_entry') IS NOT NULL
     OR to_regclass('public.ledger_household_lock') IS NOT NULL
     OR to_regclass('public.tax_period') IS NOT NULL THEN
    RAISE EXCEPTION
      'Bang Ledger/Tax da ton tai. Dung lai de kiem tra';
  END IF;
END
$$;
