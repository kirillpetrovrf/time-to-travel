enum TripType {
  group, // Групповая поездка
  individual, // Индивидуальный трансфер
}

enum Direction {
  donetskToRostov, // Донецк → Ростов-на-Дону
  rostovToDonetsk, // Ростов-на-Дону → Донецк
}

enum VehicleClass {
  economy, // Эконом класс
  premium, // Премиум класс
  minivan, // Минивэн
}

class TripPricing {
  static const int groupTripPrice = 2000; // ₽ за место
  static const int individualTripPrice = 8000; // ₽ за машину
  static const int individualTripNightPrice = 10000; // ₽ за машину после 22:00
  static const int donetskToBorderPrice = 4000; // ₽ до границы

  static const List<String> groupDepartureTimes = [
    '06:00',
    '09:00',
    '13:00',
    '16:00',
  ];

  static const List<String> donetskPickupPoints = [
    'Южный автовокзал',
    'Крытый рынок',
    'Мотель',
  ];

  static const List<String> rostovPickupPoints = [
    'Центральный автовокзал',
    'ТЦ Горизонт',
    'Площадь Ленина',
  ];

  static const List<String> donetskDropoffPoints = [
    'Центральный автовокзал Донецка',
    'Площадь Ленина Донецк',
    'ТЦ Донбасс Арена',
  ];

  static const List<String> rostovDropoffPoints = [
    'Центральный автовокзал Ростов',
    'Аэропорт Платов',
    'ЖД вокзал Ростов-Главный',
  ];

  /// Проверяет, является ли время выезда ночным (после 22:00)
  static bool isNightTime(String departureTime) {
    final time = departureTime.split(':');
    final hour = int.parse(time[0]);
    return hour >= 22;
  }

  /// Возвращает стоимость индивидуального трансфера в зависимости от времени
  static int getIndividualTripPrice(String departureTime, Direction direction) {
    if (direction == Direction.donetskToRostov) {
      return isNightTime(departureTime)
          ? individualTripNightPrice
          : individualTripPrice;
    }
    return individualTripPrice; // Для обратного направления цена не меняется
  }
}
