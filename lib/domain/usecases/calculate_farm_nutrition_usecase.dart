import '../algorithms/barycenter/single_barycenter_solver.dart';
import '../algorithms/bio_loss/bio_loss_calculator.dart';
import '../algorithms/hydraulic_scheduler/hydraulic_scheduler.dart';
import '../algorithms/nelder_mead/nelder_mead_solver.dart';
import '../algorithms/wasserstein_kmeans/wasserstein_kmeans_solver.dart';
import '../entities/climate_condition.dart';
import '../entities/crop_bed.dart';
import '../entities/optimization_result.dart';
import '../entities/time_block_config.dart';

/// UseCase trung tâm điều phối toàn bộ quy trình 4 bước xác định Độ đo dinh dưỡng tổng thể
/// cho trang trại có N luống cây theo cả Đề bài gốc và Tài liệu sáng chế.
class CalculateFarmNutritionUseCase {
  final BioLossCalculator bioLossCalculator;
  final SingleBarycenterSolver singleBarycenterSolver;
  final NelderMeadSolver nelderMeadSolver;
  final WassersteinKMeansSolver wassersteinKMeansSolver;
  final HydraulicScheduler hydraulicScheduler;

  const CalculateFarmNutritionUseCase({
    this.bioLossCalculator = const BioLossCalculator(),
    this.singleBarycenterSolver = const SingleBarycenterSolver(),
    this.nelderMeadSolver = const NelderMeadSolver(),
    this.wassersteinKMeansSolver = const WassersteinKMeansSolver(),
    this.hydraulicScheduler = const HydraulicScheduler(),
  });

  OptimizationResult execute({
    required List<CropBed> beds,
    required TimeBlockConfig timeBlock,
    required ClimateCondition climate,
    WeightingMode weightingMode = WeightingMode.equalWeights,
    ClusteringControlMode clusteringMode = ClusteringControlMode.autoDetect,
    int? manualClusterCount,
    double tankVolumeLiters = 500.0,
  }) {
    // Bước 1 & 2: Cấu hình hàm chi phí tổn thất sinh học bất đối xứng & hiệu chỉnh thời tiết Tầng 1
    final weights = bioLossCalculator.computeEffectiveWeights(
      timeBlock: timeBlock,
      climate: climate,
    );
    final normalizedBedWeights =
        bioLossCalculator.computeNormalizedBedWeights(
      beds: beds,
      mode: weightingMode,
    );

    final euclideanMean = singleBarycenterSolver.computeEuclideanMean(
      beds: beds,
      normalizedBedWeights: normalizedBedWeights,
    );

    // Xử lý Khối 4 (Ban đêm - Ngắt hoàn toàn cấp dịch)
    if (weights.isNightShutdown || beds.isEmpty) {
      final nightSchedule = hydraulicScheduler.buildSchedule(
        orderedClusters: const [],
        isNightShutdown: true,
        timeBlockIndex: timeBlock.blockIndex,
        tankVolumeLiters: tankVolumeLiters,
      );
      final nightSavings = hydraulicScheduler.computeControlCostSavings(
        cropBedsCount: beds.length,
        schedule: nightSchedule,
        isNightShutdown: true,
      );
      final nightEvals = bioLossCalculator.evaluateBeds(
        beds: beds,
        normalizedWeights: normalizedBedWeights,
        weights: weights,
        assignedPointByBedId: const {},
        assignedClusterByBedId: const {},
      );

      return OptimizationResult(
        timeBlockIndex: timeBlock.blockIndex,
        isNightShutdown: true,
        isMultiBarycenterActive: false,
        activeModeBadge: 'NGẮT VẬN HÀNH BAN ĐÊM (KHỐI 4)',
        effectiveAlphaPh: 0.0,
        effectiveWLow: 0.0,
        effectiveWHigh: 0.0,
        safetyQuantileTau: 0.0,
        singleBarycenter: const NutritionPoint(ph: 0.0, ec: 0.0),
        singleBarycenterTotalLoss: 0.0,
        nelderMeadBarycenter: const NutritionPoint(ph: 0.0, ec: 0.0),
        nelderMeadTrajectory: const [],
        euclideanMean: euclideanMean,
        euclideanTotalLoss: 0.0,
        euclideanBurnedBedsCount: 0,
        clusters: const [],
        activeTotalBioLoss: 0.0,
        bedEvaluations: nightEvals,
        hydraulicSchedule: nightSchedule,
        costSavings: nightSavings,
        plantixAdvisoryTitle: 'Chế độ Bảo vệ Rễ Ban đêm (Khối 4 - Sau 18h)',
        plantixAdvisoryMessage:
            'Hệ thống đã đưa cặp hệ số phạt (w_low, w_high) về trạng thái đóng (0, 0), ngắt hoàn toàn các van định lượng 107–110 và xả sạch đường ống để ngăn ngừa ngập úng vùng rễ và nấm bệnh.',
      );
    }

    // Bước 3A: Giải bài toán Đơn tâm Vận tải tối ưu (Generalized Wasserstein Barycenter)
    final singleStar = singleBarycenterSolver.solve(
      beds: beds,
      weights: weights,
      normalizedBedWeights: normalizedBedWeights,
    );
    final singleLoss = bioLossCalculator.computeTotalBioLoss(
      candidatePh: singleStar.ph,
      candidateEc: singleStar.ec,
      beds: beds,
      weights: weights,
      normalizedBedWeights: normalizedBedWeights,
    );

    // Bước 3B: Giải bài toán bằng thuật toán quét không gian Nelder-Mead Simplex 2D
    final nelderMeadSol = nelderMeadSolver.solve(
      beds: beds,
      weights: weights,
      normalizedBedWeights: normalizedBedWeights,
      initialGuess: euclideanMean,
    );

    // Tính chi phí tổn thất nếu dùng Trung bình cộng Euclidean [24] để đối chiếu
    final euclideanLoss = bioLossCalculator.computeTotalBioLoss(
      candidatePh: euclideanMean.ph,
      candidateEc: euclideanMean.ec,
      beds: beds,
      weights: weights,
      normalizedBedWeights: normalizedBedWeights,
    );
    final burnedUnderEuclidean = singleBarycenterSolver.countBurnedBeds(
      beds: beds,
      appliedPoint: euclideanMean,
      isNightShutdown: false,
    );

    // Bước 3C (Tầng 2): Quyết định Đơn tâm hay Đa tâm động (Wasserstein K-Means)
    final bool useMultiBarycenter;
    if (clusteringMode == ClusteringControlMode.forceSingle ||
        beds.length <= 1) {
      useMultiBarycenter = false;
    } else if (clusteringMode == ClusteringControlMode.forceMulti) {
      useMultiBarycenter = true;
    } else {
      useMultiBarycenter =
          wassersteinKMeansSolver.shouldTriggerMultiBarycenter(
        beds: beds,
        timeBlock: timeBlock,
        weights: weights,
        singleBarycenter: singleStar,
        singleBarycenterTotalLoss: singleLoss,
      );
    }

    final targetClusterCount = useMultiBarycenter
        ? wassersteinKMeansSolver.recommendClusterCount(
            beds: beds,
            manualClusterCount: manualClusterCount,
          )
        : 1;

    final clusters = wassersteinKMeansSolver.clusterBeds(
      beds: beds,
      weights: weights,
      weightingMode: weightingMode,
      clusterCount: targetClusterCount,
    );

    final activeTotalLoss = clusters.fold<double>(
      0.0,
      (acc, c) => acc + c.clusterBioLoss,
    );

    // Ánh xạ từng luống cây vào tâm cụm được gán
    final assignedPointByBedId = <String, NutritionPoint>{};
    final assignedClusterByBedId = <String, int>{};
    for (final cluster in clusters) {
      final pt = NutritionPoint(ph: cluster.phStar, ec: cluster.ecStar);
      for (final bed in cluster.beds) {
        assignedPointByBedId[bed.id] = pt;
        assignedClusterByBedId[bed.id] = cluster.clusterId;
      }
    }

    final bedEvaluations = bioLossCalculator.evaluateBeds(
      beds: beds,
      normalizedWeights: normalizedBedWeights,
      weights: weights,
      assignedPointByBedId: assignedPointByBedId,
      assignedClusterByBedId: assignedClusterByBedId,
    );

    // Bước 4: Lập lịch Hàng đợi Thủy lực, Bơm bù Vi phân & Định lượng 5 Chi phí tiết kiệm
    final schedule = hydraulicScheduler.buildSchedule(
      orderedClusters: clusters,
      isNightShutdown: false,
      timeBlockIndex: timeBlock.blockIndex,
      tankVolumeLiters: tankVolumeLiters,
    );
    final costSavings = hydraulicScheduler.computeControlCostSavings(
      cropBedsCount: beds.length,
      schedule: schedule,
      isNightShutdown: false,
    );

    final modeBadge = useMultiBarycenter
        ? 'ĐA TÂM ĐỘNG WASSERSTEIN (${clusters.length} CỤM CUỐN CHIẾU)'
        : 'ĐƠN TÂM TOÀN CỤC (1 KỲ PHỐI TRỘN DUY NHẤT)';

    final advisory = _buildPlantixAdvisory(
      beds: beds,
      singleStar: singleStar,
      euclideanMean: euclideanMean,
      burnedUnderEuclidean: burnedUnderEuclidean,
      useMultiBarycenter: useMultiBarycenter,
      clusters: clusters,
      weights: weights,
      costSavings: costSavings,
    );

    return OptimizationResult(
      timeBlockIndex: timeBlock.blockIndex,
      isNightShutdown: false,
      isMultiBarycenterActive: useMultiBarycenter,
      activeModeBadge: modeBadge,
      effectiveAlphaPh: weights.alphaPh,
      effectiveWLow: weights.wLow,
      effectiveWHigh: weights.wHigh,
      safetyQuantileTau: weights.safetyQuantileTau,
      singleBarycenter: singleStar,
      singleBarycenterTotalLoss: singleLoss,
      nelderMeadBarycenter: nelderMeadSol.optimum,
      nelderMeadTrajectory: nelderMeadSol.trajectory,
      euclideanMean: euclideanMean,
      euclideanTotalLoss: euclideanLoss,
      euclideanBurnedBedsCount: burnedUnderEuclidean,
      clusters: clusters,
      activeTotalBioLoss: activeTotalLoss,
      bedEvaluations: bedEvaluations,
      hydraulicSchedule: schedule,
      costSavings: costSavings,
      plantixAdvisoryTitle: advisory.$1,
      plantixAdvisoryMessage: advisory.$2,
    );
  }

  (String, String) _buildPlantixAdvisory({
    required List<CropBed> beds,
    required NutritionPoint singleStar,
    required NutritionPoint euclideanMean,
    required int burnedUnderEuclidean,
    required bool useMultiBarycenter,
    required List<ClusterBarycenter> clusters,
    required EffectiveBioWeights weights,
    required ControlCostSavings costSavings,
  }) {
    if (!useMultiBarycenter) {
      final title =
          'An toàn Sinh học Toàn cục: Pha 1 lần duy nhất tại (${singleStar.ph.toStringAsFixed(2)} pH; ${singleStar.ec.toStringAsFixed(2)} mS/cm)';
      final msg =
          'Thay vì lấy trung bình cộng Euclidean (${euclideanMean.ec.toStringAsFixed(2)} mS/cm) làm $burnedUnderEuclidean/${beds.length} luống cây nhạy cảm bị cháy rễ, thuật toán Vận tải tối ưu (w_high = ${weights.wHigh.toStringAsFixed(1)} >> w_low = ${weights.wLow.toStringAsFixed(1)}) đã kéo nồng độ EC về ngưỡng an toàn ${singleStar.ec.toStringAsFixed(2)} mS/cm. Giảm từ ${costSavings.traditionalMixingCycles} lần pha xuống 1 lần duy nhất, tiết kiệm ${costSavings.savedCleanWaterLiters.toStringAsFixed(0)} L nước và ${costSavings.savedElectricityWh.toStringAsFixed(0)} Wh điện.';
      return (title, msg);
    } else {
      final title =
          'Phân hóa Sinh học Cao: Kích hoạt Đa tâm động (${clusters.length} kỳ cuốn chiếu & Bơm bù vi phân)';
      final clusterSummary = clusters
          .map(
            (c) =>
                'Kỳ ${c.clusterId} (${c.phStar.toStringAsFixed(2)} pH; ${c.ecStar.toStringAsFixed(2)} mS/cm)',
          )
          .join(' → ');
      final msg =
          'Do nhu cầu giữa ${beds.length} luống cây phân hóa sâu dưới hàng rào phạt w_high = ${weights.wHigh.toStringAsFixed(1)}, hệ thống tự động tách thành ${clusters.length} cụm: $clusterSummary. Tận dụng 100% dung dịch nền tồn lưu trong đường ống bằng bơm bù vi phân, không tốn nước xả rửa trung gian.';
      return (title, msg);
    }
  }
}
