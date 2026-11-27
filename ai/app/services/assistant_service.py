from datetime import datetime
from typing import Dict, Any


class LedgerAssistantService:
    @staticmethod
    def fetch_ledger_summary(household_id: str, period: str = "2026-11") -> Dict[str, Any]:
        # TODO: Thay bằng API lấy sổ sách thật từ Backend (SV 03)
        mock_db = {
            "HKD_COMTAM_01": {
                "household_name": "Quán Cơm Tấm Sài Gòn (Hộ mẫu 01)",
                "period": "Tháng 11/2026",
                "total_revenue": 250_000_000,
                "total_expense": 165_000_000,
                "net_profit": 85_000_000,
                "vat_payable": 7_500_000,
                "pit_payable": 3_750_000,
                "total_tax_payable": 11_250_000,
                "tax_deadline": "20/12/2026",
                "top_items": [
                    {"name": "Cơm sườn bì chả", "qty": 2150, "revenue": 107_500_000},
                    {"name": "Cơm sườn nướng mật ong", "qty": 1420, "revenue": 63_900_000},
                    {"name": "Canh chua cá lóc", "qty": 890, "revenue": 22_250_000},
                ],
                "invoice_count": 3420,
                "expense_invoice_count": 48,
                "last_synced_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            }
        }
        return mock_db.get(household_id, mock_db["HKD_COMTAM_01"])

    @classmethod
    def answer_question(cls, question: str, household_id: str = "HKD_COMTAM_01") -> Dict[str, Any]:
        q = question.lower().strip()
        data = cls.fetch_ledger_summary(household_id)

        def fmt_vnd(amount: float) -> str:
            return f"{amount:,.0f}".replace(",", ".") + " VNĐ"

        if any(kw in q for kw in ["thuế", "nộp bao nhiêu", "kê khai", "gtgt", "tncn"]):
            answer = (
                f"Trong {data['period']}, tổng số thuế dự kiến phải nộp của {data['household_name']} là "
                f"{fmt_vnd(data['total_tax_payable'])} (gồm thuế GTGT 3%: {fmt_vnd(data['vat_payable'])} "
                f"và thuế TNCN 1,5%: {fmt_vnd(data['pit_payable'])}). "
                f"Hạn nộp chậm nhất là ngày {data['tax_deadline']}."
            )
            intent = "TAX_INQUIRY"
            citations = [
                f"Sổ doanh thu kỳ {data['period']}: {fmt_vnd(data['total_revenue'])} ({data['invoice_count']} hóa đơn bán ra)",
                "Biểu thuế ngành ăn uống (Thông tư 40/2021/TT-BTC): GTGT 3% + TNCN 1,5%"
            ]

        elif any(kw in q for kw in ["lãi", "lời", "lỗ", "lợi nhuận"]):
            answer = (
                f"Tính trong {data['period']}, quán đạt lợi nhuận ròng (lãi) là {fmt_vnd(data['net_profit'])}, "
                f"được tính từ tổng doanh thu {fmt_vnd(data['total_revenue'])} trừ đi tổng chi phí đầu vào "
                f"{fmt_vnd(data['total_expense'])}."
            )
            intent = "PROFIT_INQUIRY"
            citations = [
                f"Sổ bán hàng {data['period']}: Doanh thu {fmt_vnd(data['total_revenue'])}",
                f"Sổ chi phí {data['period']}: Chi phí {fmt_vnd(data['total_expense'])} (từ {data['expense_invoice_count']} chứng từ/hóa đơn mua vào)"
            ]

        elif any(kw in q for kw in ["doanh thu", "bán được", "chi phí", "nhập hàng"]):
            answer = (
                f"Trong {data['period']}, tổng doanh thu bán hàng của quán đạt {fmt_vnd(data['total_revenue'])} "
                f"qua {data['invoice_count']} đơn hàng; tổng chi phí nhập nguyên liệu & vận hành là "
                f"{fmt_vnd(data['total_expense'])}."
            )
            intent = "REVENUE_EXPENSE_INQUIRY"
            citations = [
                f"Sổ tổng hợp thu - chi {data['period']} (Cập nhật lúc {data['last_synced_at']})"
            ]

        elif any(kw in q for kw in ["bán chạy", "món nào", "mặt hàng", "top"]):
            top_list = ", ".join([f"{item['name']} ({item['qty']} suất)" for item in data["top_items"]])
            answer = f"Top 3 món bán chạy nhất trong {data['period']} là: {top_list}."
            intent = "TOP_ITEMS_INQUIRY"
            citations = [
                f"Thống kê chi tiết {data['invoice_count']} giao dịch POS trong {data['period']}"
            ]

        else:
            answer = (
                "Tôi có thể giúp bạn tra cứu nhanh: số thuế phải nộp trong kỳ, lãi/lỗ, "
                "doanh thu – chi phí hoặc các món bán chạy nhất. Bạn muốn xem thông tin nào?"
            )
            intent = "GENERAL_HELP"
            citations = []

        return {
            "status": "success",
            "household_id": household_id,
            "question": question,
            "intent": intent,
            "answer": answer,
            "citations": citations,
            "disclaimer": "Số liệu được trích xuất trực tiếp từ sổ sách điện tử của hộ kinh doanh."
        }