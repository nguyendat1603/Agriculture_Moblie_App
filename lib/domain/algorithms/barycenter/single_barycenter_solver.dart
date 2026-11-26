import 'dart:math' as math;

import '../../../core/constants/agronomy_constants.dart';
import '../../entities/crop_bed.dart';
import '../../entities/optimization_result.dart';
import '../bio_loss/bio_loss_calculator.dart';

/// Bộ giải Tâm hình học Wasserstein tổng quát Đơn tâm (Generalized Wasserstein Barycenter).
class SingleBarycenterSolver {
  final BioLossCalculator bioLossCalculator;

  const SingleBarycenterSolver({
    this.bioLossCalculator = const BioLossCalculator(),
  });

  /// Giải nghiệm tối ưu toàn cục (x*, y*) cho một tập hợp luống cây.
  NutritionPoint solve({
    required List<CropBed> beds,
    required EffectiveBioWeights weights,
    List<double>? normalizedBedWeights,
  }) {
    if (beds.isEmpty || weights.isNightShutdown) {
      return const NutritionPoint(ph: 0.0, ec: 0.0);
    }

    final n = beds.length;
    final rawP = normalizedBedWeights != null &&
            normalizedBedWeights.length == n
        ? normalizedBedWeights
        : List<double>.filled(n, 1.0 / n);
    final sumP = rawP.fold<double>(0.0, (acc, v) => acc + v);
    final p = sumP > 0
        ? rawP.map((v) => v / sumP).toList()
        : List<double>.filled(n, 1.0 / n);

    final phStar = _solveOptimalPh(
      beds: beds,
      normalizedWeights: p,
      weights: weights,
    );
    final ecStar = _solveOptimalEcQuantile(
      beds: beds,
      normalizedWeights: p,
      safetyQuantileTau: weights.safetyQuantileTau,
    );

    return NutritionPoint(
      ph: _roundTo(phStar, 4),
      ec: _roundTo(ecStar, 4),
    );
  }

  /// Tính tâm Trung bình cộng Euclidean truyền thống [24] (\bar{x}, \bar{y}) để đối chiếu.
  NutritionPoint computeEuclideanMean({
    required List<CropBed> beds,
    List<double>? normalizedBedWeights,
  }) {
    if (beds.isEmpty) {
      return const NutritionPoint(ph: 0.0, ec: 0.0);
    }
    final n = beds.length;
    final rawP = normalizedBedWeights != null &&
            normalizedBedWeights.length == n
        ? normalizedBedWeights
        : List<double>.filled(n, 1.0 / n);
    final sumP = rawP.fold<double>(0.0, (acc, v) => acc + v);
    final p = sumP > 0
        ? rawP.map((v) => v / sumP).toList()
        : List<double>.filled(n, 1.0 / n);

    var meanPh = 0.0;
    var meanEc = 0.0;
    for (var i = 0; i < n; i++) {
      meanPh += p[i] * beds[i].targetPh;
      meanEc += p[i] * beds[i].targetEc;
    }

    return NutritionPoint(
      ph: _roundTo(meanPh, 4),
      ec: _roundTo(meanEc, 4),
    );
  }

  /// Đếm số luống cây bị vượt ngưỡng cháy rễ nếu áp dụng một điểm (x, y) cho toàn trang trại.
  int countBurnedBeds({
    required List<CropBed> beds,
    required NutritionPoint appliedPoint,
    required bool isNightShutdown,
  }) {
    if (isNightShutdown || beds.isEmpty) {
      return 0;
    }
    var burnedCount = 0;
    for (final bed in beds) {
      if (appliedPoint.ec - bed.targetEc >
          AgronomyConstants.rootBurnEcTolerance) {
        burnedCount++;
      }
    }
    return burnedCount;
  }

  double _solveOptimalPh({
    required List<CropBed> beds,
    required List<double> normalizedWeights,
    required EffectiveBioWeights weights,
  }) {
    var weightedMeanPh = 0.0;
    var hasAsymmetricPhPenalty = false;
    for (var i = 0; i < beds.length; i++) {
      weightedMeanPh += normalizedWeights[i] * beds[i].targetPh;
      if (beds[i].expertPhLowPenalty > 0 || beds[i].expertPhHighPenalty > 0) {
        hasAsymmetricPhPenalty = true;
      }
    }

    if (!hasAsymmetricPhPenalty) {
      return weightedMeanPh;
    }

    // Nếu chuyên gia cấu hình phạt lệch trên/dưới cho pH (chống bó rễ),
    // dùng tìm kiếm lát cắt vàng (Golden-Section Search) trên hàm lồi 1 chiều L_x(x).
    var left = beds.map((b) => b.targetPh).reduce(math.min) - 0.5;
    var right = beds.map((b) => b.targetPh).reduce(math.max) + 0.5;
    const gr = 0.618033988749895;

    double evalPhLoss(double candidatePh) {
      var total = 0.0;
      for (var i = 0; i < beds.length; i++) {
        total += normalizedWeights[i] *
            bioLossCalculator.computePhLoss(
              candidatePh: candidatePh,
              bed: beds[i],
              alphaPh: weights.alphaPh,
            );
      }
      return total;
    }

    var c = right - gr * (right - left);
    var d = left + gr * (right - left);
    for (var iter = 0; iter < 50; iter++) {
      if (evalPhLoss(c) < evalPhLoss(d)) {
        right = d;
      } else {
        left = c;
      }
      c = right - gr * (right - left);
      d = left + gr * (right - left);
    }
    return 0.5 * (left + right);
  }

  /// Giải nghiệm tối ưu nồng độ EC (y*) bằng bài toán Phân vị mẫu an toàn (\tau_t).
  double _solveOptimalEcQuantile({
    required List<CropBed> beds,
    required List<double> normalizedWeights,
    required double safetyQuantileTau,
  }) {
    final indexed = List<int>.generate(beds.length, (i) => i);
    indexed.sort((a, b) => beds[a].targetEc.compareTo(beds[b].targetEc));

    var cumulativeWeight = 0.0;
    for (final idx in indexed) {
      cumulativeWeight += normalizedWeights[idx];
      if (cumulativeWeight + 1e-12 >= safetyQuantileTau) {
        return beds[idx].targetEc;
      }
    }
    return beds[indexed.last].targetEc;
  }

  double _roundTo(double value, int decimals) {
    final factor = math.pow(10, decimals).toDouble();
    return (value * factor).round() / factor;
  }
}
