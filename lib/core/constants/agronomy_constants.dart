/// Các hằng số nông học, thủy lực và chi phí điều khiển cho hệ thống
/// Bể phối trộn dinh dưỡng trung tâm (100) và các van định lượng (107-113).
class AgronomyConstants {
  AgronomyConstants._();

  // --- Thông số mặc định của Bể phối trộn trung tâm (100) & Nguồn nước lọc (102) ---
  static const double defaultTankVolumeLiters = 500.0;
  static const double defaultFilteredWaterPh = 7.0;
  static const double defaultFilteredWaterEc = 0.10;

  // --- Thông số định lượng 4 Bể A, B, C, D (103-106) & 4 Van (107-110) ---
  /// Lưu lượng định mức của van điện từ 107-110 khi mở 100% (mL/giây).
  static const double defaultValveFlowRateMlPerSec = 25.0;

  /// Hệ số dung dịch phân gốc A (103) và B (104): cần 2.0 mL/L để tăng 1.0 mS/cm EC.
  static const double stockAbMlPerLiterPerEc = 2.0;

  /// Hệ số dung dịch Acid (Bể C - 105, Van 109): cần 0.5 mL/L để hạ 1.0 độ pH.
  static const double acidMlPerLiterPerPhUnit = 0.5;

  /// Hệ số dung dịch Bazơ (Bể D - 106, Van 110): cần 0.5 mL/L để nâng 1.0 độ pH.
  static const double baseMlPerLiterPerPhUnit = 0.5;

  // --- Thông số định lượng 5 Chi phí Điều khiển cho mỗi chu kỳ pha trộn truyền thống (4*N lần/ngày) ---
  /// Điện năng tiêu thụ cho mỗi chu kỳ sục khuấy, bơm định lượng & đóng/ngắt van (Wh).
  static const double electricityWhPerMixingCycle = 45.0;

  /// Lượng nước sạch từ bể 102 tiêu tốn cho mỗi lần xả rửa đường ống chính (Lít).
  static const double flushWaterLitersPerCycle = 35.0;

  /// Lượng dung dịch dinh dưỡng A+B thất thoát theo nước xả rửa mỗi chu kỳ (mL).
  static const double nutrientLossMlPerFlush = 70.0;

  /// Lượng dung dịch Acid (Bể C - 105) tiêu hao phụ trợ mỗi chu kỳ chuyển đổi rời rạc (mL).
  static const double acidAuxiliaryMlPerCycle = 18.0;

  /// Lượng dung dịch Bazơ (Bể D - 106) tiêu hao phụ trợ mỗi chu kỳ chuyển đổi rời rạc (mL).
  static const double baseAuxiliaryMlPerCycle = 18.0;

  // --- Ngưỡng an toàn sinh học mặc định ---
  /// Độ dư thừa EC tối đa cho phép trước khi cảnh báo nguy cơ cháy rễ (mS/cm).
  static const double rootBurnEcTolerance = 0.05;

  /// Độ lệch trên pH tối đa cho phép trước khi cảnh báo nguy cơ bó rễ / khóa dinh dưỡng.
  static const double nutrientLockoutPhTolerance = 0.45;
}
