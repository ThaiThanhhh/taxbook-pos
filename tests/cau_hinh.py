# Cau hinh dung chung cho cac test goi API.
# Doi moi truong bang bien moi truong, khong can sua code:
#   PowerShell:  $env:BASE_URL = "http://localhost:4010"
import os

BASE_URL = os.environ.get("BASE_URL", "http://localhost:4010")
TOKEN = os.environ.get("API_TOKEN", "test")


def duong_dan(phan_duoi):
    return BASE_URL.rstrip("/") + phan_duoi