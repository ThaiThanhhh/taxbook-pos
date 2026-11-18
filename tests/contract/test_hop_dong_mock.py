import json
import os
import sys
import urllib.error
import urllib.request

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from cau_hinh import TOKEN, duong_dan

try:
    import pytest
except ImportError:
    pytest = None


class MockChuaChay(Exception):
    pass


def goi_api(phuong_thuc, duong, token=None, du_lieu=None):
    # Tra ve (ma trang thai, noi dung chu)
    body = None
    headers = {}
    if du_lieu is not None:
        body = json.dumps(du_lieu).encode("utf-8")
        headers["Content-Type"] = "application/json"
    if token:
        headers["Authorization"] = "Bearer " + token
    req = urllib.request.Request(duong_dan(duong), data=body,
                                 headers=headers, method=phuong_thuc)
    try:
        with urllib.request.urlopen(req, timeout=5) as r:
            return r.status, r.read().decode("utf-8")
    except urllib.error.HTTPError as loi:
        return loi.code, loi.read().decode("utf-8")


def can_mock():
    # Mock chua bat thi bo qua test, khong tinh la loi
    try:
        goi_api("GET", "/tax/periods", TOKEN)
    except OSError:
        if pytest:
            pytest.skip("mock chua chay")
        raise MockChuaChay()


# Cac duong GET khong can tham so bat buoc
DUONG_GET = ["/tax/periods", "/reminders"]


def test_khong_token_bi_tu_choi():
    can_mock()
    for duong in DUONG_GET:
        ma, _ = goi_api("GET", duong)
        assert ma == 401, "%s khong token ma tra %s" % (duong, ma)


def test_co_token_tra_200():
    can_mock()
    for duong in DUONG_GET:
        ma, noi_dung = goi_api("GET", duong, TOKEN)
        assert ma == 200, "%s co token ma tra %s" % (duong, ma)
        json.loads(noi_dung)   # phai la JSON hop le


def test_ky_thue_co_truong_can_thiet():
    can_mock()
    _, noi_dung = goi_api("GET", "/tax/periods", TOKEN)
    ky = json.loads(noi_dung)["items"][0]
    for truong in ["id", "label", "revenue_vnd", "vat_vnd", "pit_vnd", "status"]:
        assert truong in ky, "thieu truong " + truong


TAT_CA_TEST = [
    test_khong_token_bi_tu_choi,
    test_co_token_tra_200,
    test_ky_thue_co_truong_can_thiet,
]

# Chay truc tiep: python tests/contract/test_hop_dong_mock.py
if __name__ == "__main__":
    so_loi = 0
    for ham in TAT_CA_TEST:
        try:
            ham()
            print("OK   ", ham.__name__)
        except MockChuaChay:
            print("BO QUA", ham.__name__, "(mock chua chay)")
        except AssertionError as loi:
            so_loi += 1
            print("LOI  ", ham.__name__, "->", loi)
    print("Tong: %d sai" % so_loi)