# Sinh dữ liệu giả lập cho DT13: 50 hộ, 5 ngành, 20.000 giao dịch.
# Chạy: python tools/seed/sinh_du_lieu.py
# Dùng seed cố định nên chạy lại ra đúng y kết quả.
# Tiền là số nguyên VND, thời gian lưu UTC (BR-01).

import csv
import os
import random
import uuid
from datetime import datetime, timedelta, timezone

SEED = 2026
NAM = 2026
SO_HO = 50
SO_GIAO_DICH = 20_000
THU_MUC_RA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out")

# 5 nhóm ngành giả lập, mỗi nhóm ứng với một nhóm thuế trong config/tax (bảng của BA).
# Danh sách có thể đổi khi BA chốt.
NGANH = {
    "tap_hoa": "GOODS_DISTRIBUTION",
    "sua_xe": "SERVICE",
    "quan_com": "PRODUCTION_TRANSPORT",
    "noi_dung_so": "DIGITAL_CONTENT",
    "cho_thue": "RENTAL_AGENT",
}

# 3 hộ đại diện theo đề bài: (tên, ngành, doanh thu năm)
HO_DAI_DIEN = [
    ("Quán cơm tấm (đại diện)", "quan_com", 3_000_000_000),
    ("Tiệm tạp hóa (đại diện)", "tap_hoa", 1_200_000_000),
    ("Tiệm sửa xe (đại diện)", "sua_xe", 600_000_000),
]

# Các khoảng doanh thu của 47 hộ còn lại, để có đủ các mức thuế
KHOANG_DOANH_THU = [
    (300_000_000, 990_000_000),      # dưới 1 tỷ: không chịu thuế
    (1_100_000_000, 2_900_000_000),  # từ 1 đến 3 tỷ
    (3_200_000_000, 6_000_000_000),  # trên 3 tỷ
]

PHUONG_THUC = ["tien_mat", "chuyen_khoan", "the"]
TRONG_SO_PHUONG_THUC = [60, 30, 10]


def uuid_moi(rng):
    # Tự tạo uuid từ rng để chạy lại vẫn ra cùng giá trị
    return str(uuid.UUID(int=rng.getrandbits(128), version=4))


def dinh_dang_gio(thoi_diem):
    return thoi_diem.strftime("%Y-%m-%dT%H:%M:%SZ")


def mot_ho(rng, ten, nganh, doanh_thu):
    # Chi phí bằng 60-90% doanh thu, làm tròn nghìn đồng
    chi_phi = int(doanh_thu * rng.uniform(0.6, 0.9)) // 1000 * 1000
    return {
        "ho_id": uuid_moi(rng),
        "ten": ten,
        "nganh": nganh,
        "nhom_thue": NGANH[nganh],
        "doanh_thu_nam": doanh_thu,
        "chi_phi_nam": chi_phi,
    }


def tao_ho_kinh_doanh(rng):
    ds = []
    for ten, nganh, doanh_thu in HO_DAI_DIEN:
        ds.append(mot_ho(rng, ten, nganh, doanh_thu))
    ds_nganh = list(NGANH)
    for i in range(len(ds), SO_HO):
        nganh = ds_nganh[i % len(ds_nganh)]
        thap, cao = KHOANG_DOANH_THU[i % len(KHOANG_DOANH_THU)]
        doanh_thu = rng.randrange(thap, cao, 1000)
        ds.append(mot_ho(rng, "Hộ %02d (%s)" % (i + 1, nganh), nganh, doanh_thu))
    return ds


def tao_giao_dich(rng, ds_ho):
    moi_ho = SO_GIAO_DICH // len(ds_ho)
    dau_nam = datetime(NAM, 1, 1, tzinfo=timezone.utc)
    giay_ca_nam = 365 * 24 * 3600
    ket_qua = []
    for ho in ds_ho:
        # Chia doanh thu năm thành moi_ho đơn có giá trị ngẫu nhiên
        trong_so = [rng.uniform(0.5, 1.5) for _ in range(moi_ho)]
        tong = sum(trong_so)
        tien = [int(ho["doanh_thu_nam"] * t / tong) for t in trong_so]
        tien[-1] += ho["doanh_thu_nam"] - sum(tien)  # bù cho đủ từng đồng
        for so_tien in tien:
            luc = dau_nam + timedelta(seconds=rng.randrange(giay_ca_nam))
            ket_qua.append({
                "giao_dich_id": uuid_moi(rng),
                "ho_id": ho["ho_id"],
                "ngay_gio_utc": dinh_dang_gio(luc),
                "tong_tien": so_tien,
                "phuong_thuc": rng.choices(PHUONG_THUC, TRONG_SO_PHUONG_THUC)[0],
            })
    ket_qua.sort(key=lambda g: g["ngay_gio_utc"])
    return ket_qua


def tao_sao_ke(rng, ds_ho, giao_dich):
    dong = []
    for g in giao_dich:
        if g["phuong_thuc"] == "tien_mat":
            continue
        dong.append({
            "ho_id": g["ho_id"],
            "ngay_gio_utc": g["ngay_gio_utc"],
            "so_tien": g["tong_tien"],
            "noi_dung": "CK BAN HANG",
            "giao_dich_id_khop": g["giao_dich_id"],  # đáp án, không đưa cho app
        })
    # Thêm khoảng 5% dòng nhiễu, không khớp đơn nào
    dau_nam = datetime(NAM, 1, 1, tzinfo=timezone.utc)
    for _ in range(len(dong) // 20):
        luc = dau_nam + timedelta(seconds=rng.randrange(365 * 24 * 3600))
        dong.append({
            "ho_id": rng.choice(ds_ho)["ho_id"],
            "ngay_gio_utc": dinh_dang_gio(luc),
            "so_tien": rng.randrange(10_000, 500_000, 1000),
            "noi_dung": "CK KHAC",
            "giao_dich_id_khop": "",
        })
    dong.sort(key=lambda d: d["ngay_gio_utc"])
    return dong


def tao_kich_ban_mat_mang(rng, ho):
    # Quán cơm mất mạng 2 giờ giữa trưa, bán 80 đơn (kịch bản của đề bài)
    thiet_bi = "dev-quan-com-01"
    bat_dau = datetime(NAM, 6, 15, 4, 0, 0, tzinfo=timezone.utc)  # 11h giờ VN
    dong = []
    for stt in range(1, 81):
        luc = bat_dau + timedelta(seconds=(stt - 1) * 90)
        dong.append({
            "client_op_id": uuid_moi(rng),
            "device_id": thiet_bi,
            "local_seq": stt,
            "ma_tam": "TMP-%s-%04d" % (thiet_bi, stt),
            "client_created_at": dinh_dang_gio(luc),
            "ho_id": ho["ho_id"],
            "tong_tien": rng.randrange(30_000, 120_000, 1000),
            "phuong_thuc": rng.choices(PHUONG_THUC, TRONG_SO_PHUONG_THUC)[0],
        })
    return dong


def ghi_csv(ten_file, dong):
    os.makedirs(THU_MUC_RA, exist_ok=True)
    duong_dan = os.path.join(THU_MUC_RA, ten_file)
    # utf-8-sig để Excel mở không bị lỗi tiếng Việt
    with open(duong_dan, "w", newline="", encoding="utf-8-sig") as f:
        w = csv.DictWriter(f, fieldnames=list(dong[0].keys()))
        w.writeheader()
        w.writerows(dong)
    print("Da ghi %s (%d dong)" % (duong_dan, len(dong)))


def main():
    rng = random.Random(SEED)
    ds_ho = tao_ho_kinh_doanh(rng)
    giao_dich = tao_giao_dich(rng, ds_ho)
    sao_ke = tao_sao_ke(rng, ds_ho, giao_dich)
    kich_ban = tao_kich_ban_mat_mang(rng, ds_ho[0])

    # Kiểm tra: tổng các đơn của từng hộ phải bằng đúng doanh thu năm
    tong = {}
    for g in giao_dich:
        tong[g["ho_id"]] = tong.get(g["ho_id"], 0) + g["tong_tien"]
    for ho in ds_ho:
        assert tong[ho["ho_id"]] == ho["doanh_thu_nam"], ho["ten"]
    assert len(giao_dich) == SO_GIAO_DICH

    ghi_csv("ho_kinh_doanh.csv", ds_ho)
    ghi_csv("giao_dich.csv", giao_dich)
    ghi_csv("sao_ke.csv", sao_ke)
    ghi_csv("kich_ban_mat_mang_80_don.csv", kich_ban)


if __name__ == "__main__":
    main()