import 'crop_bed.dart';

/// Chế độ tính trọng số giữa N luống cây trong hàm mục tiêu Vận tải tối ưu.
enum WeightingMode {
  equalWeights('Đồng đều (1/N - Chuẩn ví dụ tài liệu)'),
  areaAndSensitivity('Theo Diện tích (m²) & Độ nhạy cảm giống cây');

  final String label;
  const WeightingMode(this.label);
}

/// Chế độ điều khiển phân cụm Đơn tâm vs. Đa tâm động.
enum ClusteringControlMode {
  autoDetect('Tự động thông minh (Auto-Detect)'),
  forceSingle('Đơn tâm toàn cục (1 lần pha)'),
  forceMulti('Đa tâm động (Wasserstein K-Means)');

  final String label;
  const ClusteringControlMode(this.label);
}

/// Trạng thái an toàn sinh học của bộ rễ từng luống cây sau khi áp dụng (x*, y*).
enum RootSafetyStatus {
  optimalSafe('An toàn tối ưu'),
  mildSubOptimal('Thiếu hụt nhẹ (An toàn rễ)'),
  rootBurnDanger('Nguy cơ cháy rễ (Quá ngưỡng EC)'),
  nutrientLockoutDanger('Nguy cơ bó rễ (Lệch trên pH)'),
  nightResting('Ngắt cấp dịch ban đêm (Chống úng rễ)');

  final String label;
  const RootSafetyStatus(this.label);
}

/// Hành động thủy lực trên đường ống trục chính khi chuyển kỳ phối trộn.
enum PipelineActionType {
  freshMix('Hòa trộn mới từ bể nước lọc 102'),
  differentialInjection('Bơm bù vi phân trực tiếp vào dòng tồn lưu (Tiết kiệm 100% nước xả)'),
  rapidFlushAndMix('Xả nhanh đường ống bằng nước lọc 102 chống cháy rễ trước khi pha'),
  nightShutdown('Đóng van định lượng 107-110 & Xả sạch đường ống nghỉ đêm');

  final String label;
  const PipelineActionType(this.label);
}

/// Điểm tọa độ 2D trên không gian trạng thái dinh dưỡng (x = pH, y = EC mS/cm).
class NutritionPoint {
  final double ph;
  final double ec;

  const NutritionPoint({
    required this.ph,
    required this.ec,
  });
}

/// Kết quả đánh giá tác động sinh học trên một luống cây thứ i.
class BedBiologicalEvaluation {
  final CropBed bed;
  final double normalizedWeight;
  final double appliedPh;
  final double appliedEc;
  final double deltaPh;
  final double deltaEc;
  final double phLoss;
  final double ecLoss;
  final double totalBioLoss;
  final RootSafetyStatus safetyStatus;
  final int assignedClusterId;

  const BedBiologicalEvaluation({
    required this.bed,
    required this.normalizedWeight,
    required this.appliedPh,
    required this.appliedEc,
    required this.deltaPh,
    required this.deltaEc,
    required this.phLoss,
    required this.ecLoss,
    required this.totalBioLoss,
    required this.safetyStatus,
    this.assignedClusterId = 1,
  });
}

/// Lệnh định lượng điều khiển 4 van thành phần A, B, C, D (107, 108, 109, 110).
class ValveDosingCommand {
  /// Thể tích dung dịch gốc A (Bể 103 - Van 107) cần bơm (mL).
  final double tankAVolumeMl;
  final double valve107OpenSeconds;

  /// Thể tích dung dịch gốc B (Bể 104 - Van 108) cần bơm (mL).
  final double tankBVolumeMl;
  final double valve108OpenSeconds;

  /// Thể tích dung dịch Acid pH Down (Bể 105 - Van 109) cần bơm (mL).
  final double tankCAcidVolumeMl;
  final double valve109OpenSeconds;

  /// Thể tích dung dịch Bazơ pH Up (Bể 106 - Van 110) cần bơm (mL).
  final double tankDBaseVolumeMl;
  final double valve110OpenSeconds;

  const ValveDosingCommand({
    required this.tankAVolumeMl,
    required this.valve107OpenSeconds,
    required this.tankBVolumeMl,
    required this.valve108OpenSeconds,
    required this.tankCAcidVolumeMl,
    required this.valve109OpenSeconds,
    required this.tankDBaseVolumeMl,
    required this.valve110OpenSeconds,
  });

  static const ValveDosingCommand zero = ValveDosingCommand(
    tankAVolumeMl: 0.0,
    valve107OpenSeconds: 0.0,
    tankBVolumeMl: 0.0,
    valve108OpenSeconds: 0.0,
    tankCAcidVolumeMl: 0.0,
    valve109OpenSeconds: 0.0,
    tankDBaseVolumeMl: 0.0,
    valve110OpenSeconds: 0.0,
  );
}

/// Thông tin một tâm cụm sinh học (x_{j,t}^*, y_{j,t}^*) trong chế độ Đa tâm Wasserstein K-Means.
class ClusterBarycenter {
  final int clusterId;
  final double phStar;
  final double ecStar;
  final List<CropBed> beds;
  final double clusterBioLoss;

  const ClusterBarycenter({
    required this.clusterId,
    required this.phStar,
    required this.ecStar,
    required this.beds,
    required this.clusterBioLoss,
  });
}

/// Một kỳ phối trộn trong Hàng đợi thủy lực cuốn chiếu (Hydraulic Queue Schedule).
class HydraulicSchedulePeriod {
  final int periodIndex;
  final int clusterId;
  final double targetPh;
  final double targetEc;
  final double previousPipelinePh;
  final double previousPipelineEc;

  /// Khoảng cách vận tải vi phân (\Delta x = x_{j}^* - x_{j-1}^*, \Delta y = y_{j}^* - y_{j-1}^*).
  final double deltaPh;
  final double deltaEc;

  final PipelineActionType pipelineAction;
  final bool flushRequired;
  final double waterSavedPercent;
  final ValveDosingCommand valveCommand;
  final List<String> openDistributionValveBedCodes;
  final String explanation;

  const HydraulicSchedulePeriod({
    required this.periodIndex,
    required this.clusterId,
    required this.targetPh,
    required this.targetEc,
    required this.previousPipelinePh,
    required this.previousPipelineEc,
    required this.deltaPh,
    required this.deltaEc,
    required this.pipelineAction,
    required this.flushRequired,
    required this.waterSavedPercent,
    required this.valveCommand,
    required this.openDistributionValveBedCodes,
    required this.explanation,
  });
}

/// Thống kê tiết kiệm 5 Chi phí Điều khiển (Điện, Nước, Dinh dưỡng, Acid, Bazơ)
/// so với phương pháp hòa trộn rời rạc truyền thống (4 * N lần/ngày).
class ControlCostSavings {
  final int traditionalMixingCycles;
  final int optimizedMixingCycles;
  final int savedValveSwitchCycles;

  /// 1. Điện năng tiết kiệm được (Wh).
  final double savedElectricityWh;

  /// 2. Nước sạch xả rửa đường ống tiết kiệm được (Lít).
  final double savedCleanWaterLiters;

  /// 3. Dung dịch dinh dưỡng A+B không bị xả bỏ lãng phí (mL).
  final double savedNutrientsMl;

  /// 4. Dung dịch Acid (Bể C - 105) tiết kiệm được (mL).
  final double savedAcidMl;

  /// 5. Dung dịch Bazơ (Bể D - 106) tiết kiệm được (mL).
  final double savedBaseMl;

  /// Tỷ lệ giảm chi phí vận hành tổng thể (%).
  final double overallCostReductionPercent;

  const ControlCostSavings({
    required this.traditionalMixingCycles,
    required this.optimizedMixingCycles,
    required this.savedValveSwitchCycles,
    required this.savedElectricityWh,
    required this.savedCleanWaterLiters,
    required this.savedNutrientsMl,
    required this.savedAcidMl,
    required this.savedBaseMl,
    required this.overallCostReductionPercent,
  });
}

/// Kết quả toàn diện của thuật toán Độ đo dinh dưỡng tổng thể Vận tải tối ưu.
class OptimizationResult {
  final int timeBlockIndex;
  final bool isNightShutdown;
  final bool isMultiBarycenterActive;
  final String activeModeBadge;

  /// Trọng số phạt thực tế sau khi hiệu chỉnh vi khí hậu Tầng 1.
  final double effectiveAlphaPh;
  final double effectiveWLow;
  final double effectiveWHigh;

  /// Tỷ lệ phân vị an toàn sinh học \tau_t = w_{low,t} / (w_{low,t} + w_{high,t}).
  final double safetyQuantileTau;

  /// Nghiệm Đơn tâm Vận tải tối ưu (x*, y*) và tổng tổn thất sinh học.
  final NutritionPoint singleBarycenter;
  final double singleBarycenterTotalLoss;

  /// Nghiệm tìm bằng thuật toán quét không gian Nelder-Mead Simplex 2D và quỹ đạo hội tụ.
  final NutritionPoint nelderMeadBarycenter;
  final List<NutritionPoint> nelderMeadTrajectory;

  /// Điểm Trung bình cộng Euclidean truyền thống [24] để đối chiếu.
  final NutritionPoint euclideanMean;
  final double euclideanTotalLoss;
  final int euclideanBurnedBedsCount;

  /// Danh sách các cụm trong chế độ Đa tâm động (M_t cụm; nếu Đơn tâm thì có 1 cụm).
  final List<ClusterBarycenter> clusters;

  /// Tổng tổn thất sinh học thực tế của chế độ đang kích hoạt (Đơn tâm hoặc Đa tâm).
  final double activeTotalBioLoss;

  /// Đánh giá chi tiết trên từng luống cây i = 1..N.
  final List<BedBiologicalEvaluation> bedEvaluations;

  /// Lịch trình hàng đợi thủy lực và bơm bù vi phân qua các kỳ.
  final List<HydraulicSchedulePeriod> hydraulicSchedule;

  /// Thống kê tiết kiệm 5 nguồn lực điều khiển (Điện, Nước, Dinh dưỡng, Acid, Bazơ).
  final ControlCostSavings costSavings;

  /// Lời khuyên chẩn đoán bằng ngôn ngữ tự nhiên phong cách "Bác sĩ Cây trồng Plantix".
  final String plantixAdvisoryTitle;
  final String plantixAdvisoryMessage;

  const OptimizationResult({
    required this.timeBlockIndex,
    required this.isNightShutdown,
    required this.isMultiBarycenterActive,
    required this.activeModeBadge,
    required this.effectiveAlphaPh,
    required this.effectiveWLow,
    required this.effectiveWHigh,
    required this.safetyQuantileTau,
    required this.singleBarycenter,
    required this.singleBarycenterTotalLoss,
    required this.nelderMeadBarycenter,
    required this.nelderMeadTrajectory,
    required this.euclideanMean,
    required this.euclideanTotalLoss,
    required this.euclideanBurnedBedsCount,
    required this.clusters,
    required this.activeTotalBioLoss,
    required this.bedEvaluations,
    required this.hydraulicSchedule,
    required this.costSavings,
    required this.plantixAdvisoryTitle,
    required this.plantixAdvisoryMessage,
  });
}
