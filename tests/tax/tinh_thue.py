# Hàm tính thuế độc lập, dùng để đối chiếu với backend (oracle).
# Dùng số nguyên VND, không dùng số thực để khỏi lệch đồng.
# Tỷ lệ lấy từ config/tax/tax-params.v1-draft.json (bản nháp, chưa xác minh).

NGUONG_1_TY = 1_000_000_000
NGUONG_3_TY = 3_000_000_000
NGUONG_50_TY = 50_000_000_000

# Tỷ lệ viết dạng (tử, mẫu). Ví dụ 1% = (1, 100)
TY_LE = {
    "GOODS_DISTRIBUTION": {"gtgt": (1, 100), "tncn": (5, 1000)},
    "SERVICE": {"gtgt": (5, 100), "tncn": (2, 100)},
    "PRODUCTION_TRANSPORT": {"gtgt": (3, 100), "tncn": (15, 1000)},
    
}


def nhan_ty_le(so_tien, ty_le):
    tu, mau = ty_le
    # Dùng // để làm tròn xuống (theo TV-05). Chờ Thái chốt quy tắc làm tròn.
    return so_tien * tu // mau


def thue_suat_loi_nhuan(doanh_thu):
    if doanh_thu <= NGUONG_3_TY:
        return 15
    if doanh_thu <= NGUONG_50_TY:
        return 17
    return 20


def tinh_thue(nhom, doanh_thu, chi_phi):
    # Doanh thu từ 1 tỷ trở xuống: không chịu GTGT và TNCN (BR-06)
    if doanh_thu <= NGUONG_1_TY:
        return {"gtgt": 0, "tncn_cach1": 0, "tncn_loi_nhuan": 0}

    ty_le = TY_LE[nhom]
    gtgt = nhan_ty_le(doanh_thu, ty_le["gtgt"])

    # Cách 1 (theo tỷ lệ phần vượt 1 tỷ) chỉ áp dụng khi doanh thu từ 1 đến 3 tỷ
    if doanh_thu <= NGUONG_3_TY:
        tncn_cach1 = nhan_ty_le(doanh_thu - NGUONG_1_TY, ty_le["tncn"])
    else:
        tncn_cach1 = None

    # Cách lợi nhuận: (doanh thu - chi phí) nhân thuế suất 15/17/20%
    loi_nhuan = max(0, doanh_thu - chi_phi)
    tncn_loi_nhuan = loi_nhuan * thue_suat_loi_nhuan(doanh_thu) // 100

    return {"gtgt": gtgt, "tncn_cach1": tncn_cach1, "tncn_loi_nhuan": tncn_loi_nhuan}