Reports

- `domain/` chứa model theo schema OpenAPI và logic định dạng báo cáo text/CSV.
- `data/` tải báo cáo lãi/lỗ và sản phẩm bán chạy qua `ApiClient`, được cung cấp
  cho UI bằng Riverpod.
- `presentation/` hiển thị báo cáo, xem trước nội dung xuất và sao chép text/CSV
  vào clipboard.
