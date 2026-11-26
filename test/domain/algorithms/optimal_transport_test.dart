import 'package:flutter_test/flutter_test.dart';

import 'package:agro_ot_mobile/domain/entities/climate_condition.dart';
import 'package:agro_ot_mobile/domain/entities/crop_bed.dart';
import 'package:agro_ot_mobile/domain/entities/optimization_result.dart';
import 'package:agro_ot_mobile/domain/entities/time_block_config.dart';
import 'package:agro_ot_mobile/domain/usecases/calculate_farm_nutrition_usecase.dart';

void main() {
  const useCase = CalculateFarmNutritionUseCase();

  group('Kiểm chứng Thuật toán Độ đo Dinh dưỡng Tổng thể Vận tải Tối ưu (OT)', () {
    test(
      'Kịch bản 1 (Tài liệu sáng chế): N=2 (Xà lách & Cải ngọt) tại Khối 1 Sáng sớm ôn hòa -> Đơn tâm (x*=6.1, y*=1.2 mS/cm)',
      () {
        final beds = CropBed.patentScenarioBeds();
        final block1 = TimeBlockConfig.getBlock(1);

        final result = useCase.execute(
          beds: beds,
          timeBlock: block1,
          climate: ClimateCondition.mild,
        );

        expect(result.isNightShutdown, isFalse);
        expect(result.isMultiBarycenterActive, isFalse);
        expect(result.singleBarycenter.ph, closeTo(6.1, 1e-3));
        expect(result.singleBarycenter.ec, closeTo(1.2, 1e-3));

        // Đối chiếu với Trung bình cộng Euclidean (6.1, 1.5 mS/cm)
        expect(result.euclideanMean.ph, closeTo(6.1, 1e-3));
        expect(result.euclideanMean.ec, closeTo(1.5, 1e-3));
        expect(result.euclideanBurnedBedsCount, equals(1));
        expect(result.singleBarycenterTotalLoss,
            lessThan(result.euclideanTotalLoss));

        // Kiểm chứng tiết kiệm 5 chi phí điều khiển (giảm từ 4*2 = 8 lần pha xuống 1 lần)
        expect(result.costSavings.traditionalMixingCycles, equals(8));
        expect(result.costSavings.optimizedMixingCycles, equals(1));
        expect(result.costSavings.savedValveSwitchCycles, equals(7));
        expect(result.costSavings.savedCleanWaterLiters, greaterThan(0));
      },
    );

    test(
      'Kịch bản 2 (Tài liệu sáng chế): N=2 tại Khối 2 Trưa nắng gắt -> Tự động tách 2 cụm & Bơm bù vi phân (+0.6 pH, +0.6 mS/cm)',
      () {
        final beds = CropBed.patentScenarioBeds();
        final block2 = TimeBlockConfig.getBlock(2);

        final result = useCase.execute(
          beds: beds,
          timeBlock: block2,
          climate: ClimateCondition.extremeSunny,
        );

        expect(result.isNightShutdown, isFalse);
        expect(result.isMultiBarycenterActive, isTrue);
        expect(result.clusters.length, equals(2));

        // Cụm 1: Luống Xà lách (5.8, 1.2)
        expect(result.clusters[0].phStar, closeTo(5.8, 1e-3));
        expect(result.clusters[0].ecStar, closeTo(1.2, 1e-3));

        // Cụm 2: Luống Cải ngọt (6.4, 1.8)
        expect(result.clusters[1].phStar, closeTo(6.4, 1e-3));
        expect(result.clusters[1].ecStar, closeTo(1.8, 1e-3));

        // Kiểm chứng Hàng đợi Thủy lực & Bơm bù vi phân ở Kỳ 2
        expect(result.hydraulicSchedule.length, equals(2));
        final period2 = result.hydraulicSchedule[1];
        expect(
          period2.pipelineAction,
          equals(PipelineActionType.differentialInjection),
        );
        expect(period2.flushRequired, isFalse);
        expect(period2.waterSavedPercent, equals(100.0));
        expect(period2.deltaPh, closeTo(0.6, 1e-3));
        expect(period2.deltaEc, closeTo(0.6, 1e-3));

        // Kiểm chứng lệnh mở van 107 (A), 108 (B), 110 (D - Bazơ) > 0 và van 109 (C - Acid) == 0
        expect(period2.valveCommand.tankAVolumeMl, greaterThan(0));
        expect(period2.valveCommand.tankBVolumeMl, greaterThan(0));
        expect(period2.valveCommand.tankDBaseVolumeMl, greaterThan(0));
        expect(period2.valveCommand.tankCAcidVolumeMl, equals(0.0));
      },
    );

    test(
      'Kịch bản Khối 4 Ban đêm (Sau 18h): Đóng hoàn toàn (w_low=0, w_high=0) và ngắt cấp dịch',
      () {
        final beds = CropBed.patentScenarioBeds();
        final block4 = TimeBlockConfig.getBlock(4);

        final result = useCase.execute(
          beds: beds,
          timeBlock: block4,
          climate: ClimateCondition.mild,
        );

        expect(result.isNightShutdown, isTrue);
        expect(result.effectiveWLow, equals(0.0));
        expect(result.effectiveWHigh, equals(0.0));
        expect(
          result.hydraulicSchedule.first.pipelineAction,
          equals(PipelineActionType.nightShutdown),
        );
      },
    );

    test(
      'Kiểm chứng Bộ giải Nelder-Mead Simplex 2D và Hệ số phạt Chuyên gia chống Bó rễ (pH High Penalty)',
      () {
        final beds = CropBed.patentScenarioBeds();
        final block1 = TimeBlockConfig.getBlock(1);

        final result = useCase.execute(
          beds: beds,
          timeBlock: block1,
          climate: ClimateCondition.mild,
        );

        // Nelder-Mead hội tụ sát với nghiệm giải tích Vận tải tối ưu (6.1, 1.2)
        expect(result.nelderMeadBarycenter.ph, closeTo(6.1, 0.03));
        expect(result.nelderMeadBarycenter.ec, closeTo(1.2, 0.03));
        expect(result.nelderMeadTrajectory.length, greaterThanOrEqualTo(2));

        // Khi chuyên gia cấu hình phạt lệch trên cho pH của Xà lách (chống bó rễ), pH tối ưu dịch xuống < 6.1
        final expertBeds = [
          beds[0].copyWith(expertPhHighPenalty: 3.5),
          beds[1],
        ];
        final expertResult = useCase.execute(
          beds: expertBeds,
          timeBlock: block1,
          climate: ClimateCondition.mild,
        );
        expect(expertResult.singleBarycenter.ph, lessThan(6.1));
      },
    );

    test(
      'Kiểm chứng Trang trại Đa canh N=6 loại cây với Đa tâm M=3 cụm và Chế độ Trọng số Diện tích & Độ nhạy cảm',
      () {
        final beds = CropBed.multiCropFarmBeds();
        final block2 = TimeBlockConfig.getBlock(2);

        final result = useCase.execute(
          beds: beds,
          timeBlock: block2,
          climate: ClimateCondition.extremeSunny,
          weightingMode: WeightingMode.areaAndSensitivity,
        );

        expect(result.isMultiBarycenterActive, isTrue);
        expect(result.clusters.length, equals(3));
        // Hàng đợi thủy lực sắp xếp nồng độ EC tăng dần: y_1* <= y_2* <= y_3*
        expect(
          result.clusters[0].ecStar,
          lessThanOrEqualTo(result.clusters[1].ecStar),
        );
        expect(
          result.clusters[1].ecStar,
          lessThanOrEqualTo(result.clusters[2].ecStar),
        );
      },
    );
  });
}
