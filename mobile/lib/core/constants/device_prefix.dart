/// Mã thiết bị đứng đầu số phiếu tạm: `<device_prefix>-<yyMMdd>-<seq>`.
///
/// Cố định 'A1' cho máy bán duy nhất hiện tại. Không sinh ngẫu nhiên lúc mở
/// app: đổi giá trị này giữa chừng sẽ mở ra dãy số phiếu mới cho cùng ngày.
library;

const String kDevicePrefix = 'A1';
