import 'dart:math' as math;

import '../../../core/constants/agronomy_constants.dart';
import '../../entities/optimization_result.dart';

/// Bộ lập lịch Hàng đợi Thủy lực (Hydraulic Queue Scheduling),
/// Tính toán Bơm bù Vi phân tái sử dụng dung dịch nền (\Delta x, \Delta y),
/// Định lượng 4 Van A/B/C/D (107-110) và Tính tiết kiệm 5 Chi phí Điều khiển.
class HydraulicScheduler {
  const HydraulicScheduler();

  /// Lập lịch phối trộn tuần tự qua M_t cụm đã sắp xếp trong hàng đợi thủy lực.
  List<HydraulicSchedulePeriod> buildSchedule({
    required List<ClusterBarycenter> orderedClusters,
    required bool isNightShutdown,
    required int timeBlockIndex,
    double tankVolumeLiters = AgronomyConstants.defaultTankVolumeLiters,
    double filteredWaterPh = AgronomyConstants.defaultFilteredWaterPh,
    double filteredWaterEc = AgronomyConstants.defaultFilteredWaterEc,
    double valveFlowRateMlPerSec =
        AgronomyConstants.defaultValveFlowRateMlPerSec,
  }) {
    if (isNightShutdown || orderedClusters.isEmpty) {
      return const [
        HydraulicSchedulePeriod(
          periodIndex: 1,
          clusterId: 0,
          targetPh: 0.0,
          targetEc: 0.0,
          previousPipelinePh: 0.0,
          previousPipelineEc: 0.0,
          deltaPh: 0.0,
          deltaEc: 0.0,
          pipelineAction: PipelineActionType.nightShutdown,
          flushRequired: true,
          waterSavedPercent: 100.0,
          valveCommand: ValveDosingCommand.zero,
          openDistributionValveBedCodes: [],
          explanation:
              'Khối 4 (Ban đêm): Đóng toàn bộ cụm van định lượng 107–110 và van phân phối 113, xả sạch đường ống chính chống ngập úng vùng rễ và nấm bệnh.',
        ),
      ];
    }

    final schedule = <HydraulicSchedulePeriod>[];
    var currentPipelinePh = filteredWaterPh;
    var currentPipelineEc = filteredWaterEc;

    for (var i = 0; i < orderedClusters.length; i++) {
      final cluster = orderedClusters[i];
      final periodIdx = i + 1;
      final bedCodes = cluster.beds.map((b) => b.code).toList();

      if (i == 0) {
        // Kỳ phối trộn thứ 1: Hòa trộn mới từ nguồn nước đã lọc của bể trung gian 102
        final deltaPhFromWater = _roundTo(cluster.phStar - filteredWaterPh, 4);
        final deltaEcFromWater =
            _roundTo(math.max(0.0, cluster.ecStar - filteredWaterEc), 4);
        final cmd = computeValveDosing(
          deltaPh: deltaPhFromWater,
          deltaEc: deltaEcFromWater,
          tankVolumeLiters: tankVolumeLiters,
          valveFlowRateMlPerSec: valveFlowRateMlPerSec,
        );

        schedule.add(
          HydraulicSchedulePeriod(
            periodIndex: periodIdx,
            clusterId: cluster.clusterId,
            targetPh: cluster.phStar,
            targetEc: cluster.ecStar,
            previousPipelinePh: filteredWaterPh,
            previousPipelineEc: filteredWaterEc,
            deltaPh: deltaPhFromWater,
            deltaEc: deltaEcFromWater,
            pipelineAction: PipelineActionType.freshMix,
            flushRequired: false,
            waterSavedPercent: 100.0,
            valveCommand: cmd,
            openDistributionValveBedCodes: bedCodes,
            explanation:
                'Kỳ 1 (Cụm ${cluster.clusterId}): Bể phối trộn trung tâm 100 nhận nước lọc từ bể 102, mở van 107–110 pha dung dịch đạt tâm (${cluster.phStar.toStringAsFixed(2)} pH, ${cluster.ecStar.toStringAsFixed(2)} mS/cm) rồi mở van 113 cấp cho ${bedCodes.join(", ")}.',
          ),
        );
      } else {
        // Kỳ phối trộn tiếp theo (j -> j+1): Tính khoảng cách vận tải vi phân trên nền dung dịch tồn lưu
        final diffPh = _roundTo(cluster.phStar - currentPipelinePh, 4);
        final diffEc = _roundTo(cluster.ecStar - currentPipelineEc, 4);

        if (diffEc >= -1e-6) {
          // Dung dịch nền tồn lưu loãng hơn hoặc bằng cụm tiếp theo -> Tái sử dụng 100% dung dịch nền!
          final cmd = computeValveDosing(
            deltaPh: diffPh,
            deltaEc: math.max(0.0, diffEc),
            tankVolumeLiters: tankVolumeLiters,
            valveFlowRateMlPerSec: valveFlowRateMlPerSec,
          );
          final phActionText = diffPh > 0
              ? 'bơm bổ sung dung dịch Bazơ (Van 110) nâng pH thêm +${diffPh.toStringAsFixed(2)}'
              : (diffPh < 0
                  ? 'bơm bổ sung dung dịch Acid (Van 109) hạ pH ${diffPh.toStringAsFixed(2)}'
                  : 'giữ nguyên độ pH');

          schedule.add(
            HydraulicSchedulePeriod(
              periodIndex: periodIdx,
              clusterId: cluster.clusterId,
              targetPh: cluster.phStar,
              targetEc: cluster.ecStar,
              previousPipelinePh: currentPipelinePh,
              previousPipelineEc: currentPipelineEc,
              deltaPh: diffPh,
              deltaEc: diffEc,
              pipelineAction: PipelineActionType.differentialInjection,
              flushRequired: false,
              waterSavedPercent: 100.0,
              valveCommand: cmd,
              openDistributionValveBedCodes: bedCodes,
              explanation:
                  'Kỳ $periodIdx (Cụm ${cluster.clusterId} - Tái sử dụng dung dịch nền): Giữ nguyên dịch tồn lưu (${currentPipelinePh.toStringAsFixed(2)} pH; ${currentPipelineEc.toStringAsFixed(2)} mS/cm) trong ống chính, bỏ qua xả rửa nước sạch (tiết kiệm 100% nước xả). Bơm bù vi phân trực tiếp +${diffEc.toStringAsFixed(2)} mS/cm phân đặc (Van 107, 108) và $phActionText để biến đổi thành (${cluster.phStar.toStringAsFixed(2)} pH; ${cluster.ecStar.toStringAsFixed(2)} mS/cm) cấp cho ${bedCodes.join(", ")}.',
            ),
          );
        } else {
          // Dung dịch tồn lưu đặc hơn ngưỡng an toàn của cụm tiếp theo -> Kích hoạt xả nhanh đường ống (đặc biệt ở Khối 2)
          final deltaPhFromWater =
              _roundTo(cluster.phStar - filteredWaterPh, 4);
          final deltaEcFromWater =
              _roundTo(math.max(0.0, cluster.ecStar - filteredWaterEc), 4);
          final cmd = computeValveDosing(
            deltaPh: deltaPhFromWater,
            deltaEc: deltaEcFromWater,
            tankVolumeLiters: tankVolumeLiters,
            valveFlowRateMlPerSec: valveFlowRateMlPerSec,
          );

          schedule.add(
            HydraulicSchedulePeriod(
              periodIndex: periodIdx,
              clusterId: cluster.clusterId,
              targetPh: cluster.phStar,
              targetEc: cluster.ecStar,
              previousPipelinePh: currentPipelinePh,
              previousPipelineEc: currentPipelineEc,
              deltaPh: deltaPhFromWater,
              deltaEc: deltaEcFromWater,
              pipelineAction: PipelineActionType.rapidFlushAndMix,
              flushRequired: true,
              waterSavedPercent: 0.0,
              valveCommand: cmd,
              openDistributionValveBedCodes: bedCodes,
              explanation:
                  'Kỳ $periodIdx (Cụm ${cluster.clusterId} - Ràng buộc an toàn Khối $timeBlockIndex): Do dịch tồn lưu (${currentPipelineEc.toStringAsFixed(2)} mS/cm) vượt ngưỡng loãng an toàn (${cluster.ecStar.toStringAsFixed(2)} mS/cm), hệ thống tự động xả nhanh đường ống bằng nước lọc từ bể 102 trước khi pha kỳ mới.',
            ),
          );
        }
      }

      currentPipelinePh = cluster.phStar;
      currentPipelineEc = cluster.ecStar;
    }

    return schedule;
  }

  /// Quy đổi độ chênh lệch (\Delta x, \Delta y) ra Thể tích bơm (mL) và Thời gian mở van (giây)
  /// cho 4 Van định lượng 107 (Bể A), 108 (Bể B), 109 (Bể C - Acid), 110 (Bể D - Bazơ).
  ValveDosingCommand computeValveDosing({
    required double deltaPh,
    required double deltaEc,
    double tankVolumeLiters = AgronomyConstants.defaultTankVolumeLiters,
    double valveFlowRateMlPerSec =
        AgronomyConstants.defaultValveFlowRateMlPerSec,
  }) {
    final safeFlow = math.max(1.0, valveFlowRateMlPerSec);

    // Van 107 (Bể A - 103) & Van 108 (Bể B - 104): Tăng nồng độ dinh dưỡng EC (\Delta y > 0)
    final positiveDeltaEc = math.max(0.0, deltaEc);
    final volumeA = positiveDeltaEc *
        tankVolumeLiters *
        AgronomyConstants.stockAbMlPerLiterPerEc;
    final volumeB = volumeA;
    final openSec107 = volumeA / safeFlow;
    final openSec108 = volumeB / safeFlow;

    // Van 109 (Bể C - 105: Acid) khi cần hạ độ pH (\Delta x < 0)
    final volumeCAcid = deltaPh < 0
        ? (deltaPh.abs() *
            tankVolumeLiters *
            AgronomyConstants.acidMlPerLiterPerPhUnit)
        : 0.0;
    final openSec109 = volumeCAcid / safeFlow;

    // Van 110 (Bể D - 106: Bazơ) khi cần nâng độ pH (\Delta x > 0)
    final volumeDBase = deltaPh > 0
        ? (deltaPh *
            tankVolumeLiters *
            AgronomyConstants.baseMlPerLiterPerPhUnit)
        : 0.0;
    final openSec110 = volumeDBase / safeFlow;

    return ValveDosingCommand(
      tankAVolumeMl: _roundTo(volumeA, 2),
      valve107OpenSeconds: _roundTo(openSec107, 2),
      tankBVolumeMl: _roundTo(volumeB, 2),
      valve108OpenSeconds: _roundTo(openSec108, 2),
      tankCAcidVolumeMl: _roundTo(volumeCAcid, 2),
      valve109OpenSeconds: _roundTo(openSec109, 2),
      tankDBaseVolumeMl: _roundTo(volumeDBase, 2),
      valve110OpenSeconds: _roundTo(openSec110, 2),
    );
  }

  /// Tính toán mức tiết kiệm 5 Chi phí Điều khiển (Điện, Nước, Dinh dưỡng, Acid, Bazơ)
  /// theo Đề bài gốc (`Description of Độ đo tổng thể..docx`: giảm từ 4*N chu kỳ xuống số kỳ tối ưu).
  ControlCostSavings computeControlCostSavings({
    required int cropBedsCount,
    required List<HydraulicSchedulePeriod> schedule,
    required bool isNightShutdown,
  }) {
    final n = math.max(1, cropBedsCount);
    final traditionalCycles = 4 * n;
    final optimizedCycles = isNightShutdown ? 0 : schedule.length;
    final savedCycles = math.max(0, traditionalCycles - optimizedCycles);

    // Số lần xả rửa đường ống thực tế trong lịch tối ưu
    final actualFlushes = isNightShutdown
        ? 0
        : schedule.where((s) => s.flushRequired).length;
    final traditionalFlushes = math.max(1, traditionalCycles - 1);
    final savedFlushes = math.max(0, traditionalFlushes - actualFlushes);

    final savedElectricityWh =
        savedCycles * AgronomyConstants.electricityWhPerMixingCycle;
    final savedCleanWaterLiters =
        savedFlushes * AgronomyConstants.flushWaterLitersPerCycle;
    final savedNutrientsMl =
        savedFlushes * AgronomyConstants.nutrientLossMlPerFlush;
    final savedAcidMl =
        savedCycles * AgronomyConstants.acidAuxiliaryMlPerCycle;
    final savedBaseMl =
        savedCycles * AgronomyConstants.baseAuxiliaryMlPerCycle;

    final reductionPercent = traditionalCycles > 0
        ? ((savedCycles / traditionalCycles) * 100.0).clamp(0.0, 100.0)
        : 0.0;

    return ControlCostSavings(
      traditionalMixingCycles: traditionalCycles,
      optimizedMixingCycles: optimizedCycles,
      savedValveSwitchCycles: savedCycles,
      savedElectricityWh: _roundTo(savedElectricityWh, 1),
      savedCleanWaterLiters: _roundTo(savedCleanWaterLiters, 1),
      savedNutrientsMl: _roundTo(savedNutrientsMl, 1),
      savedAcidMl: _roundTo(savedAcidMl, 1),
      savedBaseMl: _roundTo(savedBaseMl, 1),
      overallCostReductionPercent: _roundTo(reductionPercent, 1),
    );
  }

  double _roundTo(double value, int decimals) {
    final factor = math.pow(10, decimals).toDouble();
    return (value * factor).round() / factor;
  }
}
