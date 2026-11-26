import 'dart:math' as math;

import '../../entities/crop_bed.dart';
import '../../entities/optimization_result.dart';
import '../bio_loss/bio_loss_calculator.dart';

/// Kết quả quét không gian giải pháp 2D bằng thuật toán tìm cực tiểu Nelder-Mead Simplex.
class NelderMeadSolution {
  final NutritionPoint optimum;
  final List<NutritionPoint> trajectory;
  final double minimumLoss;
  final int iterations;

  const NelderMeadSolution({
    required this.optimum,
    required this.trajectory,
    required this.minimumLoss,
    required this.iterations,
  });
}

/// Bộ giải tìm cực tiểu phi đạo hàm Nelder-Mead (Simplex Search 2D)
/// theo Bước 3 của Đề bài gốc (`Description of Độ đo tổng thể..docx`).
class NelderMeadSolver {
  final BioLossCalculator bioLossCalculator;

  const NelderMeadSolver({
    this.bioLossCalculator = const BioLossCalculator(),
  });

  /// Quét không gian giải pháp 2D (x = pH, y = EC) từ điểm khởi tạo (thường là tâm Euclidean)
  /// để hội tụ về điểm có tổng Khoảng cách Sinh học nhỏ nhất.
  NelderMeadSolution solve({
    required List<CropBed> beds,
    required EffectiveBioWeights weights,
    List<double>? normalizedBedWeights,
    NutritionPoint? initialGuess,
    int maxIterations = 250,
    double tolerance = 1e-6,
  }) {
    if (beds.isEmpty || weights.isNightShutdown) {
      return const NelderMeadSolution(
        optimum: NutritionPoint(ph: 0.0, ec: 0.0),
        trajectory: [],
        minimumLoss: 0.0,
        iterations: 0,
      );
    }

    final startPh = initialGuess?.ph ??
        (beds.fold<double>(0.0, (acc, b) => acc + b.targetPh) / beds.length);
    final startEc = initialGuess?.ec ??
        (beds.fold<double>(0.0, (acc, b) => acc + b.targetEc) / beds.length);

    double objective(NutritionPoint pt) {
      return bioLossCalculator.computeTotalBioLoss(
        candidatePh: pt.ph,
        candidateEc: pt.ec,
        beds: beds,
        weights: weights,
        normalizedBedWeights: normalizedBedWeights,
      );
    }

    // Khởi tạo đơn hình 3 đỉnh (Tam giác trên mặt phẳng (pH, EC))
    final simplex = <NutritionPoint>[
      NutritionPoint(ph: startPh, ec: startEc),
      NutritionPoint(ph: startPh + 0.35, ec: math.max(0.1, startEc - 0.35)),
      NutritionPoint(ph: math.max(3.5, startPh - 0.35), ec: startEc + 0.25),
    ];

    const alphaReflection = 1.0;
    const gammaExpansion = 2.0;
    const rhoContraction = 0.5;
    const sigmaShrink = 0.5;

    final trajectory = <NutritionPoint>[];
    var iter = 0;

    for (; iter < maxIterations; iter++) {
      simplex.sort((a, b) => objective(a).compareTo(objective(b)));
      final best = simplex[0];
      final second = simplex[1];
      final worst = simplex[2];

      if (trajectory.isEmpty ||
          _distance(trajectory.last, best) > 1e-3) {
        trajectory.add(
          NutritionPoint(
            ph: _roundTo(best.ph, 4),
            ec: _roundTo(best.ec, 4),
          ),
        );
      }

      final diameter = math.max(
        _distance(best, second),
        _distance(best, worst),
      );
      if (diameter < tolerance) {
        break;
      }

      // Tâm trọng lực của 2 đỉnh tốt nhất
      final centroid = NutritionPoint(
        ph: 0.5 * (best.ph + second.ph),
        ec: 0.5 * (best.ec + second.ec),
      );

      // 1. Phép Phản xạ (Reflection)
      final reflected = _clampPoint(
        NutritionPoint(
          ph: centroid.ph + alphaReflection * (centroid.ph - worst.ph),
          ec: centroid.ec + alphaReflection * (centroid.ec - worst.ec),
        ),
      );
      final fBest = objective(best);
      final fSecond = objective(second);
      final fWorst = objective(worst);
      final fReflected = objective(reflected);

      if (fReflected >= fBest && fReflected < fSecond) {
        simplex[2] = reflected;
        continue;
      }

      // 2. Phép Giãn nở (Expansion)
      if (fReflected < fBest) {
        final expanded = _clampPoint(
          NutritionPoint(
            ph: centroid.ph + gammaExpansion * (reflected.ph - centroid.ph),
            ec: centroid.ec + gammaExpansion * (reflected.ec - centroid.ec),
          ),
        );
        simplex[2] = objective(expanded) < fReflected ? expanded : reflected;
        continue;
      }

      // 3. Phép Co rút ngoài / trong (Contraction)
      if (fReflected < fWorst) {
        final outsideContracted = _clampPoint(
          NutritionPoint(
            ph: centroid.ph + rhoContraction * (reflected.ph - centroid.ph),
            ec: centroid.ec + rhoContraction * (reflected.ec - centroid.ec),
          ),
        );
        if (objective(outsideContracted) <= fReflected) {
          simplex[2] = outsideContracted;
          continue;
        }
      } else {
        final insideContracted = _clampPoint(
          NutritionPoint(
            ph: centroid.ph + rhoContraction * (worst.ph - centroid.ph),
            ec: centroid.ec + rhoContraction * (worst.ec - centroid.ec),
          ),
        );
        if (objective(insideContracted) < fWorst) {
          simplex[2] = insideContracted;
          continue;
        }
      }

      // 4. Phép Thu nhỏ đơn hình (Shrink)
      for (var i = 1; i < simplex.length; i++) {
        simplex[i] = _clampPoint(
          NutritionPoint(
            ph: best.ph + sigmaShrink * (simplex[i].ph - best.ph),
            ec: best.ec + sigmaShrink * (simplex[i].ec - best.ec),
          ),
        );
      }
    }

    simplex.sort((a, b) => objective(a).compareTo(objective(b)));
    final finalOptimum = NutritionPoint(
      ph: _roundTo(simplex.first.ph, 4),
      ec: _roundTo(simplex.first.ec, 4),
    );
    if (trajectory.isEmpty ||
        _distance(trajectory.last, finalOptimum) > 1e-4) {
      trajectory.add(finalOptimum);
    }

    return NelderMeadSolution(
      optimum: finalOptimum,
      trajectory: trajectory,
      minimumLoss: objective(finalOptimum),
      iterations: iter,
    );
  }

  NutritionPoint _clampPoint(NutritionPoint pt) {
    return NutritionPoint(
      ph: pt.ph.clamp(3.5, 9.0),
      ec: pt.ec.clamp(0.1, 6.0),
    );
  }

  double _distance(NutritionPoint a, NutritionPoint b) {
    final dx = a.ph - b.ph;
    final dy = a.ec - b.ec;
    return math.sqrt(dx * dx + dy * dy);
  }

  double _roundTo(double value, int decimals) {
    final factor = math.pow(10, decimals).toDouble();
    return (value * factor).round() / factor;
  }
}
