
-- CHỈ DÀNH CHO DATABASE THỬ NGHIỆM
-- Chưa phải migration production được nhóm phê duyệt.

BEGIN;

DO $$
BEGIN
  IF current_database() <> 'taxbook_sales_test' THEN
    RAISE EXCEPTION
      'Không được chạy ngoài taxbook_sales_test';
  END IF;

  IF EXISTS (SELECT 1 FROM public.sales LIMIT 1) THEN
    RAISE EXCEPTION
      'Bảng sales còn dữ liệu, cần kiểm tra trước';
  END IF;
END
$$;

-- Gắn mỗi đơn bán với hộ kinh doanh
ALTER TABLE public.sales
ADD COLUMN household_id TEXT NOT NULL
CHECK (length(btrim(household_id)) BETWEEN 1 AND 200);

-- Hỗ trợ tra cứu đơn theo hộ kinh doanh
CREATE INDEX idx_sales_household_created_at
ON public.sales (household_id, created_at DESC);

COMMIT;
