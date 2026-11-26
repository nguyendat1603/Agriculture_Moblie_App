/// Chế độ chu kỳ điều khiển:
/// - [dailySingleMix]: Tìm bộ tham số đặc trưng (x*, y*) chung hàng ngày (1 lần pha/ngày thay cho 4*N lần) theo Đề bài gốc.
/// - [biologicalFourBlocks]: Điều phối thích ứng theo 4 khối giờ sinh học trong ngày (t = 1..4) theo Sáng chế mở rộng.
enum ControlCycleType {
  dailySingleMix('Chu kỳ Hàng ngày (1 lần/ngày)'),
  biologicalFourBlocks('Chu kỳ 4 Khối giờ sinh học (t = 1..4)');

  final String label;
  const ControlCycleType(this.label);
}

/// Cấu hình toán - sinh học cho một Khối giờ vận hành t (hoặc Chu kỳ Hàng ngày).
class TimeBlockConfig {
  /// Chỉ số khối giờ:
  /// - 0: Chu kỳ Hàng ngày (Daily Single-Mix theo Đề bài gốc)
  /// - 1: Khối 1 (Sáng sớm 06:00 - 08:00)
  /// - 2: Khối 2 (Trưa nắng gắt 10:00 - 14:00)
  /// - 3: Khối 3 (Chiều mát 15:00 - 17:00)
  /// - 4: Khối 4 (Ban đêm sau 18:00 - Ngắt cấp dịch)
  final int blockIndex;
  final String name;
  final String timeRange;
  final bool isActive;

  /// Hệ số chuẩn hóa thang đo độ pH (\alpha_t).
  final double alphaPh;

  /// Trọng số phạt lệch dưới cơ sở đối với nồng độ EC (w_{low,t}^{base}).
  final double baseWLow;

  /// Hệ số tỷ lệ phạt cực đoan bắt buộc (k_t >= 5, w_{high,t} >= k_t * w_{low,t}).
  final double extremeRatioK;

  /// Trọng số phạt lệch trên cơ sở đối với nồng độ EC (w_{high,t}^{base}).
  final double baseWHigh;

  /// Ngưỡng độ phân hóa EC tối đa (\Delta y_{max}) trước khi tự động tách Đa tâm Wasserstein K-Means.
  final double maxSpreadThresholdEc;

  /// Ngưỡng tổn thất sinh học trung bình tối đa trước khi tự động tách Đa tâm.
  final double maxBioLossThreshold;

  final String biologicalDescription;

  const TimeBlockConfig({
    required this.blockIndex,
    required this.name,
    required this.timeRange,
    required this.isActive,
    required this.alphaPh,
    required this.baseWLow,
    required this.extremeRatioK,
    required this.baseWHigh,
    required this.maxSpreadThresholdEc,
    required this.maxBioLossThreshold,
    required this.biologicalDescription,
  });

  TimeBlockConfig copyWith({
    double? alphaPh,
    double? baseWLow,
    double? extremeRatioK,
    double? baseWHigh,
    double? maxSpreadThresholdEc,
    double? maxBioLossThreshold,
  }) {
    final newWLow = baseWLow ?? this.baseWLow;
    final newK = extremeRatioK ?? this.extremeRatioK;
    final rawWHigh = baseWHigh ?? (newWLow * newK);
    final enforcedWHigh = rawWHigh < newWLow * newK ? newWLow * newK : rawWHigh;

    return TimeBlockConfig(
      blockIndex: blockIndex,
      name: name,
      timeRange: timeRange,
      isActive: isActive,
      alphaPh: alphaPh ?? this.alphaPh,
      baseWLow: newWLow,
      extremeRatioK: newK,
      baseWHigh: isActive ? enforcedWHigh : 0.0,
      maxSpreadThresholdEc: maxSpreadThresholdEc ?? this.maxSpreadThresholdEc,
      maxBioLossThreshold: maxBioLossThreshold ?? this.maxBioLossThreshold,
      biologicalDescription: biologicalDescription,
    );
  }

  /// Cấu hình cho Chu kỳ Hàng ngày (1 lần pha/ngày thay cho 4*N lần) theo Đề bài gốc.
  static const TimeBlockConfig dailySingleMixBlock = TimeBlockConfig(
    blockIndex: 0,
    name: 'Chu kỳ Hàng ngày (Đơn kỳ 24h)',
    timeRange: 'Cả ngày (1 lần phối trộn)',
    isActive: true,
    alphaPh: 1.0,
    baseWLow: 1.5,
    extremeRatioK: 6.0,
    baseWHigh: 9.0,
    maxSpreadThresholdEc: 0.85,
    maxBioLossThreshold: 1.5,
    biologicalDescription:
        'Xác định bộ tham số đặc trưng dinh dưỡng chung (x*, y*) hàng ngày cho N luống cây, chỉ thực hiện hòa trộn 1 lần duy nhất thay vì 4*N lần.',
  );

  /// Danh sách 4 Khối giờ sinh học chuẩn trong ngày theo Tài liệu sáng chế.
  static const List<TimeBlockConfig> standardFourBlocks = [
    TimeBlockConfig(
      blockIndex: 1,
      name: 'Khối 1: Sáng sớm',
      timeRange: '06:00 – 08:00',
      isActive: true,
      alphaPh: 1.0,
      baseWLow: 1.5,
      extremeRatioK: 6.0,
      baseWHigh: 9.0,
      maxSpreadThresholdEc: 0.75,
      maxBioLossThreshold: 1.2,
      biologicalDescription:
          'Tăng nhẹ w_low để kích hoạt bộ rễ đầu ngày, cấp đủ khoáng chất mở đầu chu trình quang hợp mà vẫn bảo vệ cây nhạy cảm.',
    ),
    TimeBlockConfig(
      blockIndex: 2,
      name: 'Khối 2: Trưa nắng gắt',
      timeRange: '10:00 – 14:00',
      isActive: true,
      alphaPh: 1.2,
      baseWLow: 0.8,
      extremeRatioK: 15.0,
      baseWHigh: 12.0,
      maxSpreadThresholdEc: 0.40,
      maxBioLossThreshold: 0.45,
      biologicalDescription:
          'Bức xạ cao, thoát hơi nước mạnh. Đẩy w_high lên mức cực đoan (k_2 = 15) và hạ w_low để ưu tiên cấp nước, chống cháy rễ tuyệt đối.',
    ),
    TimeBlockConfig(
      blockIndex: 3,
      name: 'Khối 3: Chiều mát',
      timeRange: '15:00 – 17:00',
      isActive: true,
      alphaPh: 1.0,
      baseWLow: 2.5,
      extremeRatioK: 5.0,
      baseWHigh: 12.5,
      maxSpreadThresholdEc: 0.65,
      maxBioLossThreshold: 1.1,
      biologicalDescription:
          'Giai đoạn cây tăng cường hấp thụ và tích lũy chất hữu cơ, khoáng chất chuẩn bị cho ban đêm. Đẩy w_low lên cao.',
    ),
    TimeBlockConfig(
      blockIndex: 4,
      name: 'Khối 4: Ban đêm',
      timeRange: 'Sau 18:00',
      isActive: false,
      alphaPh: 0.0,
      baseWLow: 0.0,
      extremeRatioK: 0.0,
      baseWHigh: 0.0,
      maxSpreadThresholdEc: 0.0,
      maxBioLossThreshold: 0.0,
      biologicalDescription:
          'Đưa (w_low, w_high) về trạng thái đóng (0, 0). Ngắt hoàn toàn cấp dịch và xả sạch đường ống nhằm triệt tiêu nguy cơ ngập úng rễ và nấm bệnh.',
    ),
  ];

  static TimeBlockConfig getBlock(int index) {
    if (index == 0) {
      return dailySingleMixBlock;
    }
    return standardFourBlocks.firstWhere(
      (b) => b.blockIndex == index,
      orElse: () => standardFourBlocks.first,
    );
  }
}
