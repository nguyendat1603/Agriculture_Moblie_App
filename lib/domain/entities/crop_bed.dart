/// 4 giai đoạn sinh trưởng sinh lý của cây trồng theo chuẩn Plantix Crop Library.
enum GrowthStage {
  seedling('Cây con (Kiến thiết cơ bản)'),
  vegetative('Sinh trưởng thân lá'),
  flowering('Giai đoạn ra hoa'),
  fruiting('Nuôi quả / Thu hoạch');

  final String label;
  const GrowthStage(this.label);
}

/// Thực thể đại diện cho một luống cây trồng biệt lập thứ i (117_i, i = 1..N).
class CropBed {
  final String id;
  final String code;
  final String name;
  final String cropType;
  final String icon;
  final GrowthStage growthStage;

  /// Chỉ số độ pH mục tiêu (x_{i,t}^{target}).
  final double targetPh;

  /// Chỉ số nồng độ dinh dưỡng / độ dẫn điện EC mục tiêu (y_{i,t}^{target}, mS/cm).
  final double targetEc;

  /// Diện tích canh tác của luống cây (m²).
  final double areaM2;

  /// Hệ số nhạy cảm sinh học của giống cây (s_i >= 0.5).
  final double sensitivityFactor;

  /// Hệ số phạt lệch dưới chuyên gia đối với độ pH (x < x_target).
  final double expertPhLowPenalty;

  /// Hệ số phạt lệch trên chuyên gia đối với độ pH (x > x_target -> nguy cơ bó rễ / khóa dinh dưỡng).
  final double expertPhHighPenalty;

  final String agronomicNote;

  const CropBed({
    required this.id,
    required this.code,
    required this.name,
    required this.cropType,
    required this.icon,
    required this.growthStage,
    required this.targetPh,
    required this.targetEc,
    this.areaM2 = 100.0,
    this.sensitivityFactor = 1.0,
    this.expertPhLowPenalty = 0.0,
    this.expertPhHighPenalty = 0.0,
    this.agronomicNote = '',
  });

  CropBed copyWith({
    String? id,
    String? code,
    String? name,
    String? cropType,
    String? icon,
    GrowthStage? growthStage,
    double? targetPh,
    double? targetEc,
    double? areaM2,
    double? sensitivityFactor,
    double? expertPhLowPenalty,
    double? expertPhHighPenalty,
    String? agronomicNote,
  }) {
    return CropBed(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      cropType: cropType ?? this.cropType,
      icon: icon ?? this.icon,
      growthStage: growthStage ?? this.growthStage,
      targetPh: targetPh ?? this.targetPh,
      targetEc: targetEc ?? this.targetEc,
      areaM2: areaM2 ?? this.areaM2,
      sensitivityFactor: sensitivityFactor ?? this.sensitivityFactor,
      expertPhLowPenalty: expertPhLowPenalty ?? this.expertPhLowPenalty,
      expertPhHighPenalty: expertPhHighPenalty ?? this.expertPhHighPenalty,
      agronomicNote: agronomicNote ?? this.agronomicNote,
    );
  }

  /// Bộ dữ liệu kiểm chứng chuẩn trong Tài liệu sáng chế (N = 2: Rau xà lách & Rau cải ngọt).
  static List<CropBed> patentScenarioBeds() {
    return const [
      CropBed(
        id: 'bed_117_1',
        code: '117_1',
        name: 'Luống 1 - Rau Xà Lách',
        cropType: 'Rau xà lách',
        icon: '🥬',
        growthStage: GrowthStage.vegetative,
        targetPh: 5.8,
        targetEc: 1.2,
        areaM2: 100.0,
        sensitivityFactor: 2.0,
        agronomicNote:
            'Rau ăn lá thân mềm, nhạy cảm cao với nồng độ khoáng; quá liều EC > 1.2 mS/cm dưới nắng gắt gây cháy lá, thối rễ.',
      ),
      CropBed(
        id: 'bed_117_2',
        code: '117_2',
        name: 'Luống 2 - Rau Cải Ngọt',
        cropType: 'Rau cải ngọt',
        icon: '🌿',
        growthStage: GrowthStage.vegetative,
        targetPh: 6.4,
        targetEc: 1.8,
        areaM2: 100.0,
        sensitivityFactor: 1.0,
        agronomicNote:
            'Rau cần lượng dinh dưỡng đậm đặc (1.8 mS/cm) để phát triển lá lớn, chịu đựng thiếu hụt ngắn hạn tốt.',
      ),
    ];
  }

  /// Bộ dữ liệu mẫu trang trại đa canh N = 6 loại cây trồng ở các giai đoạn khác nhau.
  static List<CropBed> multiCropFarmBeds() {
    return const [
      CropBed(
        id: 'bed_117_1',
        code: '117_1',
        name: 'Luống 1 - Rau Xà Lách',
        cropType: 'Rau xà lách',
        icon: '🥬',
        growthStage: GrowthStage.vegetative,
        targetPh: 5.8,
        targetEc: 1.2,
        areaM2: 120.0,
        sensitivityFactor: 2.0,
        agronomicNote: 'Nhạy cảm muối khoáng cao, cần ưu tiên chống cháy rễ.',
      ),
      CropBed(
        id: 'bed_117_2',
        code: '117_2',
        name: 'Luống 2 - Dâu Tây',
        cropType: 'Dâu tây',
        icon: '🍓',
        growthStage: GrowthStage.flowering,
        targetPh: 5.8,
        targetEc: 1.3,
        areaM2: 80.0,
        sensitivityFactor: 2.2,
        agronomicNote: 'Bộ rễ cực kỳ nhạy cảm với EC cao vào buổi trưa.',
      ),
      CropBed(
        id: 'bed_117_3',
        code: '117_3',
        name: 'Luống 3 - Rau Cải Ngọt',
        cropType: 'Rau cải ngọt',
        icon: '🌿',
        growthStage: GrowthStage.vegetative,
        targetPh: 6.4,
        targetEc: 1.8,
        areaM2: 150.0,
        sensitivityFactor: 1.0,
        agronomicNote: 'Cần nồng độ dinh dưỡng trung bình - đặc để phát triển bẹ lá.',
      ),
      CropBed(
        id: 'bed_117_4',
        code: '117_4',
        name: 'Luống 4 - Dưa Chuột',
        cropType: 'Dưa chuột',
        icon: '🥒',
        growthStage: GrowthStage.flowering,
        targetPh: 5.9,
        targetEc: 1.9,
        areaM2: 100.0,
        sensitivityFactor: 1.5,
        agronomicNote: 'Thoát hơi nước mạnh vào buổi trưa, cần cân đối nước và khoáng.',
      ),
      CropBed(
        id: 'bed_117_5',
        code: '117_5',
        name: 'Luống 5 - Ớt Chuông',
        cropType: 'Ớt chuông',
        icon: '🫑',
        growthStage: GrowthStage.fruiting,
        targetPh: 6.2,
        targetEc: 2.4,
        areaM2: 110.0,
        sensitivityFactor: 1.4,
        agronomicNote: 'Giai đoạn nuôi quả cần Canxi và Kali cao, giữ pH ổn định tránh bó rễ.',
      ),
      CropBed(
        id: 'bed_117_6',
        code: '117_6',
        name: 'Luống 6 - Cà Chua',
        cropType: 'Cà chua',
        icon: '🍅',
        growthStage: GrowthStage.fruiting,
        targetPh: 6.3,
        targetEc: 2.6,
        areaM2: 140.0,
        sensitivityFactor: 1.3,
        agronomicNote: 'Cần EC đậm đặc (2.6 mS/cm) để tích lũy đường và chất khô cho quả.',
      ),
    ];
  }
}
