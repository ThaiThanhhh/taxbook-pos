from tinh_thue import tinh_thue

# 6 vector lấy từ docs/test-plan/tax-test-vectors.csv (nhánh ngoc-thai/BA-lead)
# Mỗi dòng: mã test, hộ, nhóm ngành, doanh thu năm, chi phí, GTGT, TNCN cách 1, TNCN lợi nhuận
VECTORS = [
    ("TC-TAX-001", "TV-01 Tạp hóa", "GOODS_DISTRIBUTION", 2_400_000_000, 2_200_000_000, 24_000_000, 7_000_000, 30_000_000),
    ("TC-TAX-002", "TV-02 Quán cơm", "PRODUCTION_TRANSPORT", 1_800_000_000, 1_500_000_000, 54_000_000, 12_000_000, 45_000_000),
    ("TC-TAX-003", "TV-03 Sửa xe", "SERVICE", 1_200_000_000, 900_000_000, 60_000_000, 4_000_000, 45_000_000),
    ("TC-TAX-004", "TV-04 Sửa xe đúng 1 tỷ", "SERVICE", 1_000_000_000, 0, 0, 0, 0),
    ("TC-TAX-005", "TV-05 Sửa xe 1 tỷ + 1đ", "SERVICE", 1_000_000_001, 900_000_000, 50_000_000, 0, 15_000_000),
    ("TC-TAX-006", "TV-06 Tạp hóa trên 3 tỷ", "GOODS_DISTRIBUTION", 4_000_000_000, 3_500_000_000, 40_000_000, None, 85_000_000),
]


def kiem_tra_mot_vector(vector):
    ma_tc, ten, nhom, doanh_thu, chi_phi, gtgt, cach1, loi_nhuan = vector
    kq = tinh_thue(nhom, doanh_thu, chi_phi)
    assert kq["gtgt"] == gtgt, "GTGT sai: ra %s, cần %s" % (kq["gtgt"], gtgt)
    assert kq["tncn_cach1"] == cach1, "TNCN cách 1 sai: ra %s, cần %s" % (kq["tncn_cach1"], cach1)
    assert kq["tncn_loi_nhuan"] == loi_nhuan, "TNCN lợi nhuận sai: ra %s, cần %s" % (kq["tncn_loi_nhuan"], loi_nhuan)


# Hàm này pytest cũng chạy được (dùng cho CI sau này)
def test_thue_theo_vector():
    for v in VECTORS:
        kiem_tra_mot_vector(v)


# Chạy trực tiếp: python tests/tax/test_tax_vectors.py
if __name__ == "__main__":
    so_loi = 0
    for v in VECTORS:
        try:
            kiem_tra_mot_vector(v)
            print("OK   ", v[0], v[1])
        except AssertionError as loi:
            so_loi += 1
            print("LOI  ", v[0], v[1], "->", loi)
    print("Tong: %d dung, %d sai" % (len(VECTORS) - so_loi, so_loi))