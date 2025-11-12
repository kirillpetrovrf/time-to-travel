// Модель информации о маршруте
class RouteInfo {
  final double distanceKm;
  final int durationMinutes;
  final double estimatedPrice;
  
  const RouteInfo({
    required this.distanceKm,
    required this.durationMinutes,
    required this.estimatedPrice,
  });
  
  String get distanceText => '${distanceKm.toStringAsFixed(1)} км';
  
  String get durationText {
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    if (hours > 0) {
      return '$hours ч $mins мин';
    }
    return '$mins мин';
  }
  
  String get priceText => '${estimatedPrice.toStringAsFixed(0)} ₽';
  
  @override
  String toString() => 'RouteInfo($distanceText, $durationText, $priceText)';
}
