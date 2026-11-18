# May chu gia de test dong bo offline.
# Mo phong 3 luat cua he thong that:
#   1. Chong trung: gui lai cung client_op_id thi khong tao don moi
#   2. Dung thu tu: xu ly theo local_seq tang dan
#   3. So hoa don do server cap, tang dan, khong bao gio trung

TOKEN_DUNG = "test"


class MayChuGia:
    def __init__(self):
        self.da_nhan = {}   # client_op_id -> so hoa don
        self.so_cuoi = 0    # so hoa don vua cap

    def dong_bo(self, token, device_id, ds_don):
        if token != TOKEN_DUNG:
            return 401, {"error": "UNAUTHORIZED"}

        ket_qua = []
        for don in sorted(ds_don, key=lambda d: d["local_seq"]):
            ma = don["client_op_id"]
            if ma in self.da_nhan:
                trang_thai = "DUPLICATE"
            else:
                self.so_cuoi += 1
                self.da_nhan[ma] = "HD%07d" % self.so_cuoi
                trang_thai = "CREATED"
            ket_qua.append({
                "client_op_id": ma,
                "status": trang_thai,
                "invoice_no": self.da_nhan[ma],
            })
        return 200, {"results": ket_qua}