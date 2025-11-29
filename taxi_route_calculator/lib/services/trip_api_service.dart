import 'dart:core';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yandex_maps_mapkit/mapkit.dart' hide Map, Uri;

/// HTTP клиент для взаимодействия с backend API отслеживания поездок
/// 
/// ВАЖНО: Замените BASE_URL на адрес вашего реального backend!
class TripApiService {
  // Для локальной разработки (измените в зависимости от платформы):
  static const String BASE_URL = 'http://10.0.2.2:3000/api'; // Android emulator
  // static const String BASE_URL = 'http://localhost:3000/api'; // iOS simulator
  // static const String BASE_URL = 'http://192.168.1.XXX:3000/api'; // Real device
  
  // Для продакшна:
  // static const String BASE_URL = 'https://your-production-api.com/api';
  
  final http.Client _client;
  
  TripApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Создать новую поездку
  /// Возвращает tripId для отслеживания
  Future<String> createTrip({
    required Point from,
    required Point to,
    required String driverId,
    required String customerId,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$BASE_URL/trips'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'from': {
            'latitude': from.latitude,
            'longitude': from.longitude,
          },
          'to': {
            'latitude': to.latitude,
            'longitude': to.longitude,
          },
          'driverId': driverId,
          'customerId': customerId,
          'status': 'created',
          'createdAt': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['tripId'] ?? data['id'];
      } else {
        throw Exception('Failed to create trip: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error creating trip: $e');
      rethrow;
    }
  }

  /// Начать поездку (изменить статус на "in_progress")
  Future<void> startTrip(String tripId) async {
    try {
      final response = await _client.patch(
        Uri.parse('$BASE_URL/trips/$tripId/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': 'in_progress',
          'startedAt': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to start trip: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error starting trip: $e');
      rethrow;
    }
  }

  /// Отправить текущую локацию водителя на backend
  /// Вызывается каждые 3-5 секунд с телефона водителя
  Future<void> sendDriverLocation({
    required String tripId,
    required double latitude,
    required double longitude,
    double? bearing,
    double? speed,
    double? accuracy,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$BASE_URL/trips/$tripId/location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          'bearing': bearing ?? 0.0,
          'speed': speed ?? 0.0,
          'accuracy': accuracy ?? 0.0,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        print('⚠️ Failed to send location: ${response.statusCode}');
      }
    } catch (e) {
      // Не бросаем ошибку, чтобы не прерывать отслеживание
      print('⚠️ Error sending location: $e');
    }
  }

  /// Получить текущую локацию такси для клиента
  /// Вызывается клиентом каждые 3 секунды для обновления карты
  Future<TaxiLocationData?> fetchTaxiLocation(String tripId) async {
    try {
      final response = await _client.get(
        Uri.parse('$BASE_URL/trips/$tripId/location'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TaxiLocationData.fromJson(data);
      } else if (response.statusCode == 404) {
        print('⚠️ Trip not found or location not available');
        return null;
      } else {
        throw Exception('Failed to fetch location: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching taxi location: $e');
      return null;
    }
  }

  /// Получить полную информацию о поездке
  Future<TripData?> fetchTripDetails(String tripId) async {
    try {
      final response = await _client.get(
        Uri.parse('$BASE_URL/trips/$tripId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TripData.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      print('❌ Error fetching trip details: $e');
      return null;
    }
  }

  /// Завершить поездку
  Future<void> completeTrip(String tripId) async {
    try {
      final response = await _client.patch(
        Uri.parse('$BASE_URL/trips/$tripId/complete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': 'completed',
          'completedAt': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to complete trip: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error completing trip: $e');
      rethrow;
    }
  }

  /// Отменить поездку
  Future<void> cancelTrip(String tripId, String reason) async {
    try {
      final response = await _client.patch(
        Uri.parse('$BASE_URL/trips/$tripId/cancel'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': 'cancelled',
          'reason': reason,
          'cancelledAt': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to cancel trip: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error cancelling trip: $e');
      rethrow;
    }
  }

  void dispose() {
    _client.close();
  }
}

/// Модель данных локации такси
class TaxiLocationData {
  final double latitude;
  final double longitude;
  final double bearing;
  final double speed;
  final double accuracy;
  final DateTime timestamp;

  TaxiLocationData({
    required this.latitude,
    required this.longitude,
    required this.bearing,
    required this.speed,
    required this.accuracy,
    required this.timestamp,
  });

  factory TaxiLocationData.fromJson(Map<String, dynamic> json) {
    return TaxiLocationData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      bearing: (json['bearing'] as num?)?.toDouble() ?? 0.0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Point toPoint() => Point(latitude: latitude, longitude: longitude);
}

/// Модель данных поездки
class TripData {
  final String tripId;
  final Point from;
  final Point to;
  final String driverId;
  final String customerId;
  final String status; // created, in_progress, completed, cancelled
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  TripData({
    required this.tripId,
    required this.from,
    required this.to,
    required this.driverId,
    required this.customerId,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
  });

  factory TripData.fromJson(Map<String, dynamic> json) {
    return TripData(
      tripId: json['tripId'] ?? json['id'],
      from: Point(
        latitude: (json['from']['latitude'] as num).toDouble(),
        longitude: (json['from']['longitude'] as num).toDouble(),
      ),
      to: Point(
        latitude: (json['to']['latitude'] as num).toDouble(),
        longitude: (json['to']['longitude'] as num).toDouble(),
      ),
      driverId: json['driverId'],
      customerId: json['customerId'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      startedAt: json['startedAt'] != null 
          ? DateTime.parse(json['startedAt']) 
          : null,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
    );
  }
}
