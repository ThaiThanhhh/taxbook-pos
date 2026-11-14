import random

from may_chu_gia import MayChuGia, TOKEN_DUNG


def tao_don(device_id, bat_dau, so_luong):
    # Tao danh sach don ban offline cua mot thiet bi
    ds = []
    for seq in range(bat_dau, bat_dau + so_luong):
        ds.append({
            "client_op_id": "%s-%04d" % (device_id, seq),
            "device_id": device_id,
            "local_seq": seq,
            "total_vnd": 45_000 + seq,
        })
    return ds


def so_hoa_don(ket_qua):
    return [k["invoice_no"] for k in ket_qua["results"]]


def test_ban_offline_20_don():
    may = MayChuGia()
    ma, kq = may.dong_bo(TOKEN_DUNG, "dev-01", tao_don("dev-01", 1, 20))
    assert ma == 200
    assert all(k["status"] == "CREATED" for k in kq["results"])
    assert len(set(so_hoa_don(kq))) == 20, "co so hoa don bi trung"


def test_gui_lai_lo_khong_trung():
    may = MayChuGia()
    lo = tao_don("dev-01", 1, 20)
    _, lan1 = may.dong_bo(TOKEN_DUNG, "dev-01", lo)
    _, lan2 = may.dong_bo(TOKEN_DUNG, "dev-01", lo)
    assert all(k["status"] == "DUPLICATE" for k in lan2["results"])
    assert so_hoa_don(lan1) == so_hoa_don(lan2), "gui lai ma doi so hoa don"
    assert len(may.da_nhan) == 20, "gui lai ma tao them don"


def test_dung_thu_tu():
    may = MayChuGia()
    lo = tao_don("dev-01", 1, 10)
    random.Random(1).shuffle(lo)   # gui lon xon thu tu
    _, kq = may.dong_bo(TOKEN_DUNG, "dev-01", lo)
    dung = ["HD%07d" % i for i in range(1, 11)]
    assert so_hoa_don(kq) == dung, "so hoa don khong theo local_seq"


def test_hai_thiet_bi_khong_trung_so():
    may = MayChuGia()
    _, a = may.dong_bo(TOKEN_DUNG, "dev-A", tao_don("dev-A", 1, 10))
    _, b = may.dong_bo(TOKEN_DUNG, "dev-B", tao_don("dev-B", 1, 10))
    tat_ca = so_hoa_don(a) + so_hoa_don(b)
    assert len(set(tat_ca)) == 20, "hai thiet bi bi trung so hoa don"


def test_thieu_token():
    may = MayChuGia()
    ma, _ = may.dong_bo("sai-token", "dev-01", tao_don("dev-01", 1, 5))
    assert ma == 401
    assert len(may.da_nhan) == 0, "sai token ma van luu don"


def test_quan_com_mat_mang_80_don():
    # TC-SYNC-001: quan com mat mang 2 gio, ban 80 don, co mang gui lai
    may = MayChuGia()
    thiet_bi = "dev-quan-com-01"
    tat_ca = tao_don(thiet_bi, 1, 80)
    rng = random.Random(2026)
    cac_lo = [tat_ca[i:i + 20] for i in range(0, 80, 20)]

    for lo in cac_lo:
        rng.shuffle(lo)
        ma, _ = may.dong_bo(TOKEN_DUNG, thiet_bi, lo)
        assert ma == 200

    # Mang chap chon, may gui lai lo thu 2
    _, lai = may.dong_bo(TOKEN_DUNG, thiet_bi, cac_lo[1])
    assert all(k["status"] == "DUPLICATE" for k in lai["results"])

    assert len(may.da_nhan) == 80, "mat don hoac thua don"
    dung = ["HD%07d" % i for i in range(1, 81)]
    assert sorted(may.da_nhan.values()) == dung, "so hoa don khong lien tuc"
    for don in tat_ca:
        mong_doi = "HD%07d" % don["local_seq"]
        assert may.da_nhan[don["client_op_id"]] == mong_doi, "sai thu tu"


TAT_CA_TEST = [
    test_ban_offline_20_don,
    test_gui_lai_lo_khong_trung,
    test_dung_thu_tu,
    test_hai_thiet_bi_khong_trung_so,
    test_thieu_token,
    test_quan_com_mat_mang_80_don,
]

# Chay truc tiep: python tests/sync/test_dong_bo.py
if __name__ == "__main__":
    so_loi = 0
    for ham in TAT_CA_TEST:
        try:
            ham()
            print("OK   ", ham.__name__)
        except AssertionError as loi:
            so_loi += 1
            print("LOI  ", ham.__name__, "->", loi)
    print("Tong: %d dung, %d sai" % (len(TAT_CA_TEST) - so_loi, so_loi))