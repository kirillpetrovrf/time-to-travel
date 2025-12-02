import 'package:flutter_test/flutter_test.dart';
import '../lib/models/trip_type.dart';

void main() {
  group('Локальные маршруты (8000₽ без КПП)', () {
    test('Донецк-Кутейниково должен быть локальным маршрутом (простые названия)', () {
      expect(TripPricing.isLocalRoute('Донецк', 'Кутейниково'), isTrue);
      expect(TripPricing.isLocalRoute('Кутейниково', 'Донецк'), isTrue);
      expect(TripPricing.isLocalRoute('донецк', 'кутейниково'), isTrue);
      expect(TripPricing.isLocalRoute('кутейниково', 'донецк'), isTrue);
    });

    test('Донецк-Кутейниково должен быть локальным маршрутом (полные названия из API)', () {
      // Тестируем с реальным названием, которое приходит из API
      expect(TripPricing.isLocalRoute('Донецк', 'муниципальный округ Амвросиевский, посёлок городского типа Кутейниково'), isTrue);
      expect(TripPricing.isLocalRoute('муниципальный округ Амвросиевский, посёлок городского типа Кутейниково', 'Донецк'), isTrue);
    });

    test('Донецк-Кутейниково должен иметь фиксированную цену 8000₽ (простые названия)', () {
      expect(TripPricing.getFixedRoutePrice('Донецк', 'Кутейниково'), equals(8000));
      expect(TripPricing.getFixedRoutePrice('Кутейниково', 'Донецк'), equals(8000));
      expect(TripPricing.getFixedRoutePrice('донецк', 'кутейниково'), equals(8000));
      expect(TripPricing.getFixedRoutePrice('кутейниково', 'донецк'), equals(8000));
    });

    test('Донецк-Кутейниково должен иметь фиксированную цену 8000₽ (полные названия из API)', () {
      // Тестируем с реальным названием, которое приходит из API  
      expect(TripPricing.getFixedRoutePrice('Донецк', 'муниципальный округ Амвросиевский, посёлок городского типа Кутейниково'), equals(8000));
      expect(TripPricing.getFixedRoutePrice('муниципальный округ Амвросиевский, посёлок городского типа Кутейниково', 'Донецк'), equals(8000));
    });

    test('Все новые локальные пары работают корректно', () {
      final localPairs = [
        ['донецк', 'амвросиевка'],
        ['донецк', 'иловайск'],
        ['донецк', 'кутейниково'],
      ];

      for (final pair in localPairs) {
        final from = pair[0];
        final to = pair[1];
        
        // Проверяем что маршрут считается локальным
        expect(TripPricing.isLocalRoute(from, to), isTrue, reason: '$from → $to должен быть локальным');
        expect(TripPricing.isLocalRoute(to, from), isTrue, reason: '$to → $from должен быть локальным (обратно)');
        
        // Проверяем цену 8000₽
        expect(TripPricing.getFixedRoutePrice(from, to), equals(8000), reason: '$from → $to должен стоить 8000₽');
        expect(TripPricing.getFixedRoutePrice(to, from), equals(8000), reason: '$to → $from должен стоить 8000₽ (обратно)');
      }
    });

    test('Неместные маршруты НЕ должны быть локальными', () {
      expect(TripPricing.isLocalRoute('Донецк', 'Ростов'), isFalse);
      expect(TripPricing.isLocalRoute('Донецк', 'Луганск'), isFalse);
      expect(TripPricing.isLocalRoute('Москва', 'Питер'), isFalse);
    });
  });
}