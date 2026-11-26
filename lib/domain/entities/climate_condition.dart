/// Các kịch bản vi khí hậu thực địa tại cánh đồng mở (Tầng 1: Adaptive Climate-Driven Weights).
enum WeatherScenario {
  mild('Thời tiết ôn hòa'),
  extremeSunny('Nắng gắt / Bức xạ PAR cao'),
  heavyRain('Mưa lớn / Độ ẩm đất cao');

  final String label;
  const WeatherScenario(this.label);
}

/// Thực thể biểu diễn điều kiện vi khí hậu tại khối giờ t đang xét.
class ClimateCondition {
  final WeatherScenario scenario;

  /// Hệ số nhân phạt lệch trên khi trời nắng gắt (K_sunny >= 1.0).
  /// w_{high,t}^{new} = K_sunny * w_{high,t}
  final double kSunny;

  /// Hệ số nhân phạt lệch dưới khi trời mưa lớn làm loãng phân (K_rainy >= 1.0).
  /// w_{low,t}^{new} = K_rainy * w_{low,t}
  final double kRainy;

  /// Cường độ bức xạ quang hợp PAR (\mu mol/m²/s) minh họa trên Dashboard.
  final double solarPar;

  /// Độ ẩm tương đối của không khí/thổ nhưỡng (%).
  final double humidityPercent;

  final String description;

  const ClimateCondition({
    required this.scenario,
    required this.kSunny,
    required this.kRainy,
    this.solarPar = 650.0,
    this.humidityPercent = 65.0,
    required this.description,
  });

  static const ClimateCondition mild = ClimateCondition(
    scenario: WeatherScenario.mild,
    kSunny: 1.0,
    kRainy: 1.0,
    solarPar: 600.0,
    humidityPercent: 65.0,
    description:
        'Điều kiện vi khí hậu ôn hòa tiêu chuẩn (K_sunny = 1.0, K_rainy = 1.0).',
  );

  static const ClimateCondition extremeSunny = ClimateCondition(
    scenario: WeatherScenario.extremeSunny,
    kSunny: 2.0,
    kRainy: 1.0,
    solarPar: 1450.0,
    humidityPercent: 40.0,
    description:
        'Nắng gắt, bức xạ PAR và tốc độ bốc thoát hơi nước cao (K_sunny = 2.0). Tăng gấp đôi hàng rào phạt lệch trên w_high để chống sốc chất tan và cháy rễ.',
  );

  static const ClimateCondition heavyRain = ClimateCondition(
    scenario: WeatherScenario.heavyRain,
    kSunny: 1.0,
    kRainy: 1.8,
    solarPar: 250.0,
    humidityPercent: 92.0,
    description:
        'Mưa lớn cục bộ làm rửa trôi và pha loãng ion khoáng trong đất (K_rainy = 1.8). Tăng trọng số phạt lệch dưới w_low để bù nồng độ EC y*, giữ nguyên biên độ pH x*.',
  );
}
