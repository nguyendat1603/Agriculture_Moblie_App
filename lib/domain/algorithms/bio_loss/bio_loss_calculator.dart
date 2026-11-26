import 'dart:math' as math;

import '../../../core/constants/agronomy_constants.dart';
import '../../entities/climate_condition.dart';
import '../../entities/crop_bed.dart';
import '../../entities/optimization_result.dart';
import '../../entities/time_block_config.dart';

/// Kết quả hiệu chỉnh trọng số phạt sinh học Tầng 1 theo Khối giờ t và Vi khí hậu.
class EffectiveBioWeights {
  final double alphaPh;
  final double wLow;
  final double wHigh;
  final double safetyQuantileTau;
  final bool isNightShutdown;

  const EffectiveBioWeights({
    required this.alphaPh,
    required this.wLow,
    required this.wHigh,
    required this.safetyQuantileTau,
    required this.isNightShutdown,
  });
}

/// Bộ tính toán Hàm chi phí tổn thất sinh học bất đối xứng (D_bio = L_x + L_y)
/// và Hiệu chỉnh trọng số thích ứng vi khí hậu (Tầng 1).
class BioLossCalculator {
  const BioLossCalculator();

  /// Tầng 1: Hiệu chỉnh cặp trọng số (w_{low,t}, w_{high,t}) theo Khối giờ t và Thời tiết.
  /// Đảm bảo ràng buộc biên kỹ thuật bắt buộc: w_{high,t} >= k_t * w_{low,t}.
  EffectiveBioWeights computeEffectiveWeights({
    required TimeBlockConfig timeBlock,
    required ClimateCondition climate,
  }) {
    if (!timeBlock.isActive || timeBlock.blockIndex == 4) {
      return const EffectiveBioWeights(
        alphaPh: 0.0,
        wLow: 0.0,
        wHigh: 0.0,
        safetyQuantileTau: 0.0,
        isNightShutdown: true,
      );
    }

    final adjustedWLow = timeBlock.baseWLow * math.max(1.0, climate.kRainy);
    final rawAdjustedWHigh =
        timeBlock.baseWHigh * math.max(1.0, climate.kSunny);
    final minimumBarrierWHigh =
        math.max(5.0, timeBlock.extremeRatioK) * adjustedWLow;
    final adjustedWHigh = math.max(rawAdjustedWHigh, minimumBarrierWHigh);

    final denominator = adjustedWLow + adjustedWHigh;
    final tau = denominator > 0 ? (adjustedWLow / denominator) : 0.0;

    return EffectiveBioWeights(
      alphaPh: timeBlock.alphaPh,
      wLow: adjustedWLow,
      wHigh: adjustedWHigh,
      safetyQuantileTau: tau,
      isNightShutdown: false,
    );
  }

  /// Tính mảng trọng số xác suất chuẩn hóa p_i (với \sum p_i = 1) cho danh sách luống cây.
  List<double> computeNormalizedBedWeights({
    required List<CropBed> beds,
    required WeightingMode mode,
  }) {
    if (beds.isEmpty) {
      return const [];
    }
    final n = beds.length;
    if (mode == WeightingMode.equalWeights) {
      final equalW = 1.0 / n;
      return List<double>.filled(n, equalW);
    }

    final rawWeights = beds
        .map((b) => math.max(1.0, b.areaM2) * math.max(0.5, b.sensitivityFactor))
        .toList();
    final sumW = rawWeights.fold<double>(0.0, (acc, v) => acc + v);
    if (sumW <= 0) {
      return List<double>.filled(n, 1.0 / n);
    }
    return rawWeights.map((w) => w / sumW).toList();
  }

  /// Hàm tổn thất đối với chỉ số độ pH (L_{x,i,t}) tích hợp hệ số phạt chuyên gia chống bó rễ.
  double computePhLoss({
    required double candidatePh,
    required CropBed bed,
    required double alphaPh,
  }) {
    final diff = candidatePh - bed.targetPh;
    final quadraticLoss = alphaPh * diff * diff;
    final asymmetricPenalty = diff <= 0
        ? bed.expertPhLowPenalty * (bed.targetPh - candidatePh)
        : bed.expertPhHighPenalty * (candidatePh - bed.targetPh);
    return quadraticLoss + asymmetricPenalty;
  }

  /// Hàm tổn thất bất đối xứng đối với chỉ số dẫn điện EC (L_{y,i,t}) chống cháy rễ.
  double computeEcLoss({
    required double candidateEc,
    required CropBed bed,
    required double wLow,
    required double wHigh,
  }) {
    if (candidateEc <= bed.targetEc) {
      return wLow * (bed.targetEc - candidateEc);
    } else {
      return wHigh * (candidateEc - bed.targetEc);
    }
  }

  /// Khoảng cách toán - sinh học hiệu chỉnh D_bio từ điểm (x, y) tới luống cây thứ i.
  double computeSingleBedBioDistance({
    required double candidatePh,
    required double candidateEc,
    required CropBed bed,
    required EffectiveBioWeights weights,
  }) {
    if (weights.isNightShutdown) {
      return 0.0;
    }
    final lx = computePhLoss(
      candidatePh: candidatePh,
      bed: bed,
      alphaPh: weights.alphaPh,
    );
    final ly = computeEcLoss(
      candidateEc: candidateEc,
      bed: bed,
      wLow: weights.wLow,
      wHigh: weights.wHigh,
    );
    return lx + ly;
  }

  /// Tổng chi phí tổn thất sinh học trên tập hợp N luống cây cho một điểm ứng viên (x, y).
  double computeTotalBioLoss({
    required double candidatePh,
    required double candidateEc,
    required List<CropBed> beds,
    required EffectiveBioWeights weights,
    List<double>? normalizedBedWeights,
  }) {
    if (beds.isEmpty || weights.isNightShutdown) {
      return 0.0;
    }
    final scaleFactor = normalizedBedWeights == null
        ? List<double>.filled(beds.length, 1.0)
        : normalizedBedWeights.map((p) => p * beds.length).toList();

    var total = 0.0;
    for (var i = 0; i < beds.length; i++) {
      final dBio = computeSingleBedBioDistance(
        candidatePh: candidatePh,
        candidateEc: candidateEc,
        bed: beds[i],
        weights: weights,
      );
      total += scaleFactor[i] * dBio;
    }
    return total;
  }

  /// Chẩn đoán trạng thái an toàn sinh học của rễ cho một luống cây khi áp dụng (appliedPh, appliedEc).
  RootSafetyStatus diagnoseRootSafety({
    required double appliedPh,
    required double appliedEc,
    required CropBed bed,
    required bool isNightShutdown,
  }) {
    if (isNightShutdown) {
      return RootSafetyStatus.nightResting;
    }
    final deltaEc = appliedEc - bed.targetEc;
    final deltaPh = appliedPh - bed.targetPh;

    if (deltaEc > AgronomyConstants.rootBurnEcTolerance) {
      return RootSafetyStatus.rootBurnDanger;
    }
    if (deltaPh > AgronomyConstants.nutrientLockoutPhTolerance &&
        bed.expertPhHighPenalty > 0) {
      return RootSafetyStatus.nutrientLockoutDanger;
    }
    if (deltaEc < -AgronomyConstants.rootBurnEcTolerance) {
      return RootSafetyStatus.mildSubOptimal;
    }
    return RootSafetyStatus.optimalSafe;
  }

  /// Đánh giá chi tiết toàn bộ N luống cây dưới một cấu hình cấp dịch (Đơn tâm hoặc Đa tâm).
  List<BedBiologicalEvaluation> evaluateBeds({
    required List<CropBed> beds,
    required List<double> normalizedWeights,
    required EffectiveBioWeights weights,
    required Map<String, NutritionPoint> assignedPointByBedId,
    required Map<String, int> assignedClusterByBedId,
  }) {
    final evaluations = <BedBiologicalEvaluation>[];
    for (var i = 0; i < beds.length; i++) {
      final bed = beds[i];
      final p = i < normalizedWeights.length
          ? normalizedWeights[i]
          : (1.0 / math.max(1, beds.length));
      final applied = assignedPointByBedId[bed.id] ??
          NutritionPoint(ph: bed.targetPh, ec: bed.targetEc);
      final clusterId = assignedClusterByBedId[bed.id] ?? 1;

      final lx = weights.isNightShutdown
          ? 0.0
          : computePhLoss(
              candidatePh: applied.ph,
              bed: bed,
              alphaPh: weights.alphaPh,
            );
      final ly = weights.isNightShutdown
          ? 0.0
          : computeEcLoss(
              candidateEc: applied.ec,
              bed: bed,
              wLow: weights.wLow,
              wHigh: weights.wHigh,
            );
      final safety = diagnoseRootSafety(
        appliedPh: applied.ph,
        appliedEc: applied.ec,
        bed: bed,
        isNightShutdown: weights.isNightShutdown,
      );

      evaluations.add(
        BedBiologicalEvaluation(
          bed: bed,
          normalizedWeight: p,
          appliedPh: applied.ph,
          appliedEc: applied.ec,
          deltaPh: applied.ph - bed.targetPh,
          deltaEc: applied.ec - bed.targetEc,
          phLoss: lx,
          ecLoss: ly,
          totalBioLoss: lx + ly,
          safetyStatus: safety,
          assignedClusterId: clusterId,
        ),
      );
    }
    return evaluations;
  }
}
