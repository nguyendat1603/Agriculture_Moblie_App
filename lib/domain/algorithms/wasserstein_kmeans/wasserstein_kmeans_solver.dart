import 'dart:math' as math;

import '../../entities/crop_bed.dart';
import '../../entities/optimization_result.dart';
import '../../entities/time_block_config.dart';
import '../barycenter/single_barycenter_solver.dart';
import '../bio_loss/bio_loss_calculator.dart';

/// Bộ giải Phân cụm động trên không gian Vận tải tối ưu (Wasserstein K-Means - Tầng 2)
/// nhằm xác định Đa tâm hình học sinh học {(x_{j,t}^*, y_{j,t}^*)}_{j=1}^{M_t}.
class WassersteinKMeansSolver {
  final BioLossCalculator bioLossCalculator;
  final SingleBarycenterSolver singleBarycenterSolver;

  const WassersteinKMeansSolver({
    this.bioLossCalculator = const BioLossCalculator(),
    this.singleBarycenterSolver = const SingleBarycenterSolver(),
  });

  /// Kiểm tra xem tập N luống cây tại khối giờ t có phân hóa vượt ngưỡng sinh học
  /// để tự động chuyển từ Đơn tâm sang Đa tâm động hay không.
  bool shouldTriggerMultiBarycenter({
    required List<CropBed> beds,
    required TimeBlockConfig timeBlock,
    required EffectiveBioWeights weights,
    required NutritionPoint singleBarycenter,
    required double singleBarycenterTotalLoss,
  }) {
    if (beds.length <= 1 || weights.isNightShutdown) {
      return false;
    }

    final minEc = beds.map((b) => b.targetEc).reduce(math.min);
    final maxEc = beds.map((b) => b.targetEc).reduce(math.max);
    final ecSpread = maxEc - minEc;

    final averageLossPerBed = singleBarycenterTotalLoss / beds.length;

    return ecSpread > timeBlock.maxSpreadThresholdEc ||
        averageLossPerBed > timeBlock.maxBioLossThreshold;
  }

  /// Xác định số lượng cụm tối ưu M_t (thường M_t = 2 hoặc 3 theo Tài liệu sáng chế).
  int recommendClusterCount({
    required List<CropBed> beds,
    int? manualClusterCount,
  }) {
    if (beds.isEmpty) {
      return 0;
    }
    if (beds.length == 1) {
      return 1;
    }
    if (manualClusterCount != null && manualClusterCount >= 2) {
      return math.min(manualClusterCount, beds.length);
    }

    // Tự động chọn M_t = 2 cho quy mô nhỏ/vừa (N <= 4), hoặc M_t = 3 khi N >= 5 và biên độ EC rộng.
    final minEc = beds.map((b) => b.targetEc).reduce(math.min);
    final maxEc = beds.map((b) => b.targetEc).reduce(math.max);
    if (beds.length >= 5 && (maxEc - minEc) >= 1.0) {
      return 3;
    }
    return 2;
  }

  /// Thực thi thuật toán phân cụm Wasserstein K-Means để chia N luống cây thành M_t cụm
  /// và sắp xếp các cụm theo thứ tự nồng độ EC tăng dần (y_{1,t}^* <= y_{2,t}^* <= ... <= y_{M_t,t}^*).
  List<ClusterBarycenter> clusterBeds({
    required List<CropBed> beds,
    required EffectiveBioWeights weights,
    required WeightingMode weightingMode,
    required int clusterCount,
    int maxIterations = 25,
  }) {
    if (beds.isEmpty || weights.isNightShutdown) {
      return const [];
    }

    final m = clusterCount.clamp(1, beds.length);
    if (m == 1) {
      final normWeights = bioLossCalculator.computeNormalizedBedWeights(
        beds: beds,
        mode: weightingMode,
      );
      final center = singleBarycenterSolver.solve(
        beds: beds,
        weights: weights,
        normalizedBedWeights: normWeights,
      );
      final loss = bioLossCalculator.computeTotalBioLoss(
        candidatePh: center.ph,
        candidateEc: center.ec,
        beds: beds,
        weights: weights,
        normalizedBedWeights: normWeights,
      );
      return [
        ClusterBarycenter(
          clusterId: 1,
          phStar: center.ph,
          ecStar: center.ec,
          beds: beds,
          clusterBioLoss: loss,
        ),
      ];
    }

    // Sắp xếp các luống cây theo nồng độ EC mục tiêu tăng dần để khởi tạo M_t tâm phân vị
    final sortedBeds = List<CropBed>.from(beds)
      ..sort((a, b) {
        final cmp = a.targetEc.compareTo(b.targetEc);
        return cmp != 0 ? cmp : a.targetPh.compareTo(b.targetPh);
      });

    var centroids = List<NutritionPoint>.generate(m, (j) {
      final idx = ((j + 0.5) * sortedBeds.length / m)
          .floor()
          .clamp(0, sortedBeds.length - 1);
      return NutritionPoint(
        ph: sortedBeds[idx].targetPh,
        ec: sortedBeds[idx].targetEc,
      );
    });

    var assignments = List<int>.filled(sortedBeds.length, 0);

    for (var iter = 0; iter < maxIterations; iter++) {
      var changed = false;

      // Bước 1: Gán từng luống cây vào tâm có khoảng cách sinh học bất đối xứng D_bio nhỏ nhất
      for (var i = 0; i < sortedBeds.length; i++) {
        final bed = sortedBeds[i];
        var bestCluster = 0;
        var bestDist = double.infinity;

        for (var j = 0; j < m; j++) {
          final c = centroids[j];
          final dist = bioLossCalculator.computeSingleBedBioDistance(
            candidatePh: c.ph,
            candidateEc: c.ec,
            bed: bed,
            weights: weights,
          );
          if (dist < bestDist) {
            bestDist = dist;
            bestCluster = j;
          }
        }

        if (assignments[i] != bestCluster) {
          assignments[i] = bestCluster;
          changed = true;
        }
      }

      // Đảm bảo không có cụm rỗng bằng cách chia đều nếu xảy ra suy biến
      final buckets = List<List<CropBed>>.generate(m, (_) => <CropBed>[]);
      for (var i = 0; i < sortedBeds.length; i++) {
        buckets[assignments[i]].add(sortedBeds[i]);
      }
      if (buckets.any((b) => b.isEmpty)) {
        for (var j = 0; j < m; j++) {
          buckets[j].clear();
        }
        for (var i = 0; i < sortedBeds.length; i++) {
          final bucketIdx =
              ((i * m) / sortedBeds.length).floor().clamp(0, m - 1);
          buckets[bucketIdx].add(sortedBeds[i]);
          assignments[i] = bucketIdx;
        }
      }

      // Bước 2: Cập nhật tâm hình học Wasserstein Barycenter cho từng cụm
      final newCentroids = <NutritionPoint>[];
      for (var j = 0; j < m; j++) {
        final clusterBedsList = buckets[j];
        final normW = bioLossCalculator.computeNormalizedBedWeights(
          beds: clusterBedsList,
          mode: weightingMode,
        );
        final updatedCenter = singleBarycenterSolver.solve(
          beds: clusterBedsList,
          weights: weights,
          normalizedBedWeights: normW,
        );
        newCentroids.add(updatedCenter);
      }

      centroids = newCentroids;
      if (!changed && iter > 0) {
        break;
      }
    }

    // Gom nhóm kết quả và sắp xếp các cụm theo thứ tự ưu tiên thủy lực (nồng độ loãng -> đặc)
    final finalBuckets = List<List<CropBed>>.generate(m, (_) => <CropBed>[]);
    for (var i = 0; i < sortedBeds.length; i++) {
      finalBuckets[assignments[i]].add(sortedBeds[i]);
    }

    final rawClusters = <ClusterBarycenter>[];
    for (var j = 0; j < m; j++) {
      final groupBeds = finalBuckets[j];
      if (groupBeds.isEmpty) {
        continue;
      }
      final normW = bioLossCalculator.computeNormalizedBedWeights(
        beds: groupBeds,
        mode: weightingMode,
      );
      final center = singleBarycenterSolver.solve(
        beds: groupBeds,
        weights: weights,
        normalizedBedWeights: normW,
      );
      final loss = bioLossCalculator.computeTotalBioLoss(
        candidatePh: center.ph,
        candidateEc: center.ec,
        beds: groupBeds,
        weights: weights,
        normalizedBedWeights: normW,
      );
      rawClusters.add(
        ClusterBarycenter(
          clusterId: j + 1,
          phStar: center.ph,
          ecStar: center.ec,
          beds: groupBeds,
          clusterBioLoss: loss,
        ),
      );
    }

    rawClusters.sort((a, b) {
      final cmp = a.ecStar.compareTo(b.ecStar);
      return cmp != 0 ? cmp : a.phStar.compareTo(b.phStar);
    });

    return List<ClusterBarycenter>.generate(rawClusters.length, (index) {
      final c = rawClusters[index];
      return ClusterBarycenter(
        clusterId: index + 1,
        phStar: c.phStar,
        ecStar: c.ecStar,
        beds: c.beds,
        clusterBioLoss: c.clusterBioLoss,
      );
    });
  }
}
