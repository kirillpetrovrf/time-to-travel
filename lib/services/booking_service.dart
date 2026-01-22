import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/booking.dart';
import '../models/trip_type.dart';
import '../models/route_stop.dart';
import '../models/passenger_info.dart';
import '../models/baggage.dart'; // Содержит BaggageItem
import '../models/pet_info_v3.dart'; // Содержит PetInfo
import 'auth_service.dart';
import 'notification_service.dart';
import 'offline_orders_service.dart';
import 'api/orders_api_service.dart'; // ✅ НОВОЕ: API для синхронизации заказов

/// ✅ ОБНОВЛЕНО: Теперь синхронизируется с backend API (https://titotr.ru)
/// Заказы сохраняются локально (SharedPreferences) + отправляются на сервер
class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  // ✅ НОВОЕ: API сервис для работы с backend
  final OrdersApiService _ordersApi = OrdersApiService();

  // Ключи для локального хранения (используется как fallback при отсутствии сети)
  static const String _offlineBookingsKey = 'offline_bookings';

  /// Создание нового бронирования (гибридный режим: API + локальное хранение)
  /// ✅ ОБНОВЛЕНО: Сначала отправка на backend, затем локальное сохранение
  Future<String> createBooking(Booking booking) async {
    debugPrint('📤 Создание бронирования: сначала отправка на backend API...');
    
    try {
      // 1. Парсим дату и время в DateTime для API
      DateTime departureDateTime;
      try {
        final timeComponents = booking.departureTime.split(':');
        final hour = int.parse(timeComponents[0]);
        final minute = int.parse(timeComponents[1]);
        
        departureDateTime = DateTime(
          booking.departureDate.year,
          booking.departureDate.month,
          booking.departureDate.day,
          hour,
          minute,
        );
      } catch (e) {
        debugPrint('⚠️ Ошибка парсинга времени: $e');
        departureDateTime = booking.departureDate;
      }

      // 2. Подготавливаем метаданные (багаж, животные, пассажиры, класс авто)
      final metadata = <String, dynamic>{};
      
      if (booking.baggage.isNotEmpty) {
        metadata['baggage'] = booking.baggage.map((b) => {
          'size': b.size.toString().split('.').last,
          'quantity': b.quantity,
          'pricePerExtraItem': b.pricePerExtraItem,
          'customDescription': b.customDescription,
        }).toList();
      }
      
      if (booking.pets.isNotEmpty) {
        metadata['pets'] = booking.pets.map((p) => {
          'category': p.category.toString().split('.').last,
          'breed': p.breed,
          'cost': p.cost,
        }).toList();
      }
      
      if (booking.passengers.isNotEmpty) {
        metadata['passengers'] = booking.passengers.map((p) => {
          'type': p.type.toString().split('.').last,
        }).toList();
      }
      
      if (booking.vehicleClass != null) {
        metadata['vehicleClass'] = booking.vehicleClass;
      }
      
      metadata['tripType'] = booking.tripType.toString().split('.').last;
      metadata['direction'] = booking.direction.toString().split('.').last;

      // 3. Пытаемся отправить на backend
      final createdOrder = await _ordersApi.createOrder(
        fromAddress: booking.pickupAddress ?? 'Не указан',
        toAddress: booking.dropoffAddress ?? 'Не указан',
        departureTime: departureDateTime,
        passengerCount: booking.passengerCount,
        basePrice: booking.totalPrice.toDouble(),
        totalPrice: booking.totalPrice.toDouble(),
        notes: booking.notes,
        metadata: metadata,
      );
      
      debugPrint('✅ Заказ успешно создан на backend с ID: ${createdOrder.id}');
      
      // 4. Сохраняем локально с реальным ID от сервера
      final bookingId = createdOrder.id;
      final bookingWithId = Booking(
        id: bookingId,
        clientId: booking.clientId,
        tripType: booking.tripType,
        direction: booking.direction,
        departureDate: booking.departureDate,
        departureTime: booking.departureTime,
        passengerCount: booking.passengerCount,
        pickupPoint: booking.pickupPoint,
        pickupAddress: booking.pickupAddress,
        dropoffAddress: booking.dropoffAddress,
        fromStop: booking.fromStop,
        toStop: booking.toStop,
        totalPrice: booking.totalPrice,
        status: booking.status,
        createdAt: booking.createdAt,
        notes: booking.notes,
        trackingPoints: booking.trackingPoints,
        baggage: booking.baggage,
        pets: booking.pets,
        passengers: booking.passengers,
        vehicleClass: booking.vehicleClass,
      );
      
      await _saveBookingToSharedPreferences(bookingWithId);
      
      // 5. Планируем уведомления
      await _planBookingNotifications(bookingWithId);
      
      return bookingId;
    } catch (e) {
      debugPrint('⚠️ Ошибка отправки на backend: $e');
      debugPrint('📱 Сохраняем заказ локально для последующей синхронизации');
      
      // Fallback: сохраняем локально, если сервер недоступен
      return _createOfflineBooking(booking);
    }
  }

  /// Сохранение бронирования в SharedPreferences
  Future<void> _saveBookingToSharedPreferences(Booking booking) async {
    final prefs = await SharedPreferences.getInstance();
    final existingBookingsJson = prefs.getString(_offlineBookingsKey);
    List<Map<String, dynamic>> bookingsList = [];

    if (existingBookingsJson != null) {
      final decoded = jsonDecode(existingBookingsJson) as List<dynamic>;
      bookingsList = decoded.cast<Map<String, dynamic>>();
    }

    bookingsList.add(booking.toJson());
    await prefs.setString(_offlineBookingsKey, jsonEncode(bookingsList));
    debugPrint('💾 Бронирование ${booking.id} сохранено локально');
  }

  /// Планирование уведомлений для бронирования
  Future<void> _planBookingNotifications(Booking booking) async {
    debugPrint('🔔 Планирование уведомлений для заказа ${booking.id}');
    
    final notificationService = NotificationService.instance;
    final notificationsScheduled = 
        await notificationService.scheduleAllBookingNotifications(booking);

    if (notificationsScheduled) {
      debugPrint('✅ Уведомления успешно запланированы');
    } else {
      debugPrint('⚠️ Не все уведомления были запланированы');
    }

    final pending = await notificationService.getPendingNotifications();
    debugPrint('📋 Всего запланировано уведомлений: ${pending.length}');
  }

  /// Создание локального бронирования
  Future<String> _createOfflineBooking(Booking booking) async {
    final prefs = await SharedPreferences.getInstance();

    // Генерируем уникальный ID
    final bookingId = 'offline_${DateTime.now().millisecondsSinceEpoch}';

    // Создаем бронирование с ID
    final bookingWithId = Booking(
      id: bookingId,
      clientId: booking.clientId,
      tripType: booking.tripType,
      direction: booking.direction,
      departureDate: booking.departureDate,
      departureTime: booking.departureTime,
      passengerCount: booking.passengerCount,
      pickupPoint: booking.pickupPoint,
      pickupAddress: booking.pickupAddress,
      dropoffAddress: booking.dropoffAddress,
      fromStop: booking.fromStop,
      toStop: booking.toStop,
      totalPrice: booking.totalPrice,
      status: booking.status,
      createdAt: booking.createdAt,
      notes: booking.notes,
      trackingPoints: booking.trackingPoints,
      baggage: booking.baggage,
      pets: booking.pets,
      passengers: booking.passengers,
      vehicleClass: booking.vehicleClass, // ← ДОБАВЛЯЕМ ПОЛЕ vehicleClass!
    );

    print('🚗 [SERVICE] Исходный booking.vehicleClass: ${booking.vehicleClass}');
    print('🚗 [SERVICE] bookingWithId.vehicleClass: ${bookingWithId.vehicleClass}');

    // Получаем существующие бронирования
    final existingBookingsJson = prefs.getString(_offlineBookingsKey);
    List<Map<String, dynamic>> bookingsList = [];

    if (existingBookingsJson != null) {
      final decoded = jsonDecode(existingBookingsJson) as List<dynamic>;
      bookingsList = decoded.cast<Map<String, dynamic>>();
    }

    // Добавляем новое бронирование
    final bookingJson = bookingWithId.toJson();
    print('💾 JSON бронирования: ${jsonEncode(bookingJson)}');
    print('💾 Багаж в JSON: ${bookingJson['baggage']}');
    print('🚗 [JSON] vehicleClass в JSON: ${bookingJson['vehicleClass']}');
    print('🚗 [JSON] booking.vehicleClass: ${bookingWithId.vehicleClass}');
    bookingsList.add(bookingJson);

    // Сохраняем обратно
    await prefs.setString(_offlineBookingsKey, jsonEncode(bookingsList));

    print('📱 Создано оффлайн бронирование: $bookingId');

    // 🔔 ПЛАНИРУЕМ УВЕДОМЛЕНИЯ СРАЗУ ПОСЛЕ СОЗДАНИЯ ЗАКАЗА
    debugPrint('🔔 ========================================');
    debugPrint('🔔 ПЛАНИРОВАНИЕ УВЕДОМЛЕНИЙ ДЛЯ ЗАКАЗА');
    debugPrint('🔔 ID заказа: $bookingId');
    debugPrint('🔔 Дата поездки: ${bookingWithId.departureDate}');
    debugPrint('🔔 Время поездки: ${bookingWithId.departureTime}');
    debugPrint('🔔 ========================================');

    final notificationService = NotificationService.instance;
    final notificationsScheduled = await notificationService
        .scheduleAllBookingNotifications(bookingWithId);

    if (notificationsScheduled) {
      debugPrint('✅ Уведомления успешно запланированы для заказа $bookingId');
    } else {
      debugPrint(
        '⚠️ Не все уведомления были запланированы для заказа $bookingId',
      );
    }

    // Показать список запланированных уведомлений
    final pending = await notificationService.getPendingNotifications();
    debugPrint(
      '📋 Всего запланировано уведомлений в системе: ${pending.length}',
    );
    for (final notification in pending) {
      debugPrint(
        '   - ID: ${notification.id}, Title: ${notification.title}, Payload: ${notification.payload}',
      );
    }

    return bookingId;
  }

  /// Получение бронирования по ID (локально)
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<Booking?> getBookingById(String bookingId) async {
    debugPrint('ℹ️ Поиск бронирования по ID локально (Firebase не подключен)');
    return _getOfflineBookingById(bookingId);
  }

  /// Получение локального бронирования по ID
  Future<Booking?> _getOfflineBookingById(String bookingId) async {
    final prefs = await SharedPreferences.getInstance();
    final bookingsJson = prefs.getString(_offlineBookingsKey);

    print('🔍 [BOOKING] Поиск заказа по ID: $bookingId');

    if (bookingsJson != null) {
      final bookingsList = jsonDecode(bookingsJson) as List<dynamic>;
      print('🔍 [BOOKING] Найдено заказов в SharedPreferences: ${bookingsList.length}');

      for (final bookingData in bookingsList) {
        final jsonData = bookingData as Map<String, dynamic>;
        
        // Отладка: показываем vehicleClass в JSON ПЕРЕД парсингом
        print('🔍 [BOOKING] JSON данные заказа ${jsonData['id']}: vehicleClass = ${jsonData['vehicleClass']}');
        
        final booking = Booking.fromJson(jsonData);
        
        // Отладка: показываем vehicleClass ПОСЛЕ парсинга
        print('🔍 [BOOKING] ПОСЛЕ fromJson заказа ${booking.id}: vehicleClass = ${booking.vehicleClass}');
        
        if (booking.id == bookingId) {
          print('✅ [BOOKING] Найден заказ с ID: $bookingId, vehicleClass: ${booking.vehicleClass}');
          return booking;
        }
      }
    } else {
      print('❌ [BOOKING] SharedPreferences пуст, заказы не найдены');
    }
    print('❌ [BOOKING] Заказ с ID $bookingId не найден');
    return null;
  }

  /// Получение всех бронирований текущего клиента
  Future<List<Booking>> getCurrentClientBookings() async {
    // Получаем ID текущего пользователя через AuthService
    final currentUserId = await AuthService.instance.getCurrentUserId();

    if (currentUserId == null || currentUserId.isEmpty) {
      debugPrint('⚠️ ID текущего пользователя не найден');
      return [];
    }

    debugPrint('✅ Загрузка заказов для пользователя: $currentUserId');
    return getClientBookings(currentUserId);
  }

  /// Получение всех бронирований клиента (гибридный режим: API + локальные данные)
  /// ✅ ОБНОВЛЕНО: Загружает заказы с backend + локальные несинхронизированные заказы
  Future<List<Booking>> getClientBookings(String clientId) async {
    debugPrint('📥 Загрузка бронирований: сначала с backend, затем локальные...');
    
    List<Booking> allBookings = [];
    
    try {
      // 1. Пытаемся загрузить с backend
      debugPrint('🌐 Загрузка заказов с backend API...');
      final ordersResponse = await _ordersApi.getOrders();
      
      debugPrint('✅ Получено ${ordersResponse.orders.length} заказов с backend');
      
      // Конвертируем ApiOrder → Booking
      final backendBookings = ordersResponse.orders.map((apiOrder) {
        return Booking(
          id: apiOrder.id,
          clientId: apiOrder.userId,
          tripType: TripType.customRoute, // TODO: извлечь из metadata
          direction: Direction.donetskToRostov, // TODO: извлечь из metadata
          departureDate: apiOrder.departureTime,
          departureTime: '${apiOrder.departureTime.hour.toString().padLeft(2, '0')}:${apiOrder.departureTime.minute.toString().padLeft(2, '0')}',
          passengerCount: apiOrder.passengerCount,
          pickupPoint: null,
          pickupAddress: apiOrder.fromAddress,
          dropoffAddress: apiOrder.toAddress,
          fromStop: null,
          toStop: null,
          totalPrice: apiOrder.totalPrice.toInt(),
          status: _convertApiStatus(apiOrder.status),
          createdAt: apiOrder.createdAt,
          notes: apiOrder.notes,
          trackingPoints: const [],
          baggage: const [],
          pets: const [],
          passengers: const [],
          vehicleClass: apiOrder.metadata?['vehicleClass'] as String?,
        );
      }).toList();
      
      allBookings.addAll(backendBookings);
      debugPrint('✅ Конвертировано ${backendBookings.length} заказов с backend');
      
    } catch (e) {
      debugPrint('⚠️ Ошибка загрузки с backend: $e');
      debugPrint('📱 Загружаем только локальные данные');
    }
    
    // 2. Загружаем локальные данные (индивидуальные трансферы)
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookingsJson = prefs.getString(_offlineBookingsKey);
      
      if (bookingsJson != null) {
        final decoded = jsonDecode(bookingsJson) as List<dynamic>;
        final localBookings = decoded
            .map((json) => Booking.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('📦 Загружено ${localBookings.length} локальных индивидуальных трансферов');
        allBookings.addAll(localBookings);
      }
    } catch (e) {
      debugPrint('⚠️ Ошибка загрузки локальных данных: $e');
    }
    
    // 3. Загружаем заказы такси из SQLite
    try {
      final taxiBookings = await _getTaxiOrdersAsBookings(clientId);
      debugPrint('📦 Загружено ${taxiBookings.length} заказов такси из SQLite');
      allBookings.addAll(taxiBookings);
    } catch (e) {
      debugPrint('⚠️ Ошибка загрузки такси из SQLite: $e');
    }
    
    // 4. Удаляем дубликаты (по ID) - backend данные в приоритете
    final uniqueBookings = <String, Booking>{};
    for (final booking in allBookings) {
      uniqueBookings[booking.id] = booking;
    }
    
    final result = uniqueBookings.values.toList();
    
    // 5. Сортируем по дате (новые сначала)
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    debugPrint('✅ Всего загружено ${result.length} уникальных бронирований');
    return result;
  }

  /// Конвертация статуса API → BookingStatus
  BookingStatus _convertApiStatus(OrderStatus apiStatus) {
    switch (apiStatus) {
      case OrderStatus.pending:
        return BookingStatus.pending;
      case OrderStatus.confirmed:
        return BookingStatus.confirmed;
      case OrderStatus.inProgress:
        return BookingStatus.inProgress;
      case OrderStatus.completed:
        return BookingStatus.completed;
      case OrderStatus.cancelled:
        return BookingStatus.cancelled;
    }
  }

  /// Конвертация TaxiOrder из SQLite в Booking для отображения
  Future<List<Booking>> _getTaxiOrdersAsBookings(String clientId) async {
    try {
      // Загружаем все заказы из SQLite
      final taxiOrders = await OfflineOrdersService.instance.getAllOrders();
      debugPrint('📦 [BOOKING] Загружено ${taxiOrders.length} заказов из SQLite');

      // Конвертируем TaxiOrder → Booking
      final bookings = taxiOrders.map((order) {
        // ✅ Декодируем JSON данные о пассажирах
        List<PassengerInfo> passengers = [];
        if (order.passengersJson != null && order.passengersJson!.isNotEmpty) {
          try {
            final passengersData = jsonDecode(order.passengersJson!) as List;
            passengers = passengersData
                .map((json) => PassengerInfo.fromJson(json as Map<String, dynamic>))
                .toList();
          } catch (e) {
            debugPrint('⚠️ [BOOKING] Ошибка декодирования пассажиров: $e');
          }
        }

        // ✅ Декодируем JSON данные о багаже
        List<BaggageItem> baggage = [];
        if (order.baggageJson != null && order.baggageJson!.isNotEmpty) {
          try {
            final baggageData = jsonDecode(order.baggageJson!) as List;
            baggage = baggageData
                .map((json) => BaggageItem.fromJson(json as Map<String, dynamic>))
                .toList();
          } catch (e) {
            debugPrint('⚠️ [BOOKING] Ошибка декодирования багажа: $e');
          }
        }

        // ✅ Декодируем JSON данные о животных
        List<PetInfo> pets = [];
        if (order.petsJson != null && order.petsJson!.isNotEmpty) {
          try {
            final petsData = jsonDecode(order.petsJson!) as List;
            pets = petsData
                .map((json) => PetInfo.fromJson(json as Map<String, dynamic>))
                .toList();
          } catch (e) {
            debugPrint('⚠️ [BOOKING] Ошибка декодирования животных: $e');
          }
        }

        // Создаём RouteStop объекты из координат и адресов TaxiOrder
        final fromStop = RouteStop(
          id: 'taxi_from_${order.orderId}',
          name: order.fromAddress,
          order: 0,
          latitude: order.fromPoint.latitude,
          longitude: order.fromPoint.longitude,
          priceFromStart: 0,
        );
        
        final toStop = RouteStop(
          id: 'taxi_to_${order.orderId}',
          name: order.toAddress,
          order: 1,
          latitude: order.toPoint.latitude,
          longitude: order.toPoint.longitude,
          priceFromStart: order.finalPrice.round(),
        );
        
        return Booking(
          id: order.orderId,
          clientId: clientId,
          tripType: TripType.customRoute, // ✅ Свободный маршрут (такси)
          direction: Direction.donetskToRostov, // Для customRoute не используется
          departureDate: order.timestamp, // Уже DateTime
          departureTime: 
              '${order.timestamp.hour.toString().padLeft(2, '0')}:${order.timestamp.minute.toString().padLeft(2, '0')}',
          passengerCount: passengers.length, // ✅ Реальное количество пассажиров
          pickupAddress: order.fromAddress,
          dropoffAddress: order.toAddress,
          totalPrice: order.finalPrice.round(), // Округляем до int для Booking
          status: _convertOrderStatusToBookingStatus(order.status),
          createdAt: order.timestamp, // Уже DateTime
          baggage: baggage,        // ✅ Декодированный багаж
          pets: pets,              // ✅ Декодированные животные
          passengers: passengers,  // ✅ Декодированные пассажиры
          pickupPoint: null,
          fromStop: fromStop,  // ✅ Добавляем fromStop с адресом
          toStop: toStop,      // ✅ Добавляем toStop с адресом
          vehicleClass: order.vehicleClass, // ✅ Класс транспорта
          notes: order.notes,      // ✅ Комментарии
          distanceKm: order.distanceKm,     // ✅ Расстояние
          baseCost: order.baseCost,         // ✅ Базовая стоимость
          costPerKm: order.costPerKm,       // ✅ Стоимость за км
        );
      }).toList();

      // Сортируем по дате (новые сначала)
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      debugPrint('✅ [BOOKING] Конвертировано в ${bookings.length} Booking объектов');
      return bookings;
    } catch (e) {
      debugPrint('❌ [BOOKING] Ошибка загрузки заказов: $e');
      return [];
    }
  }

  /// Конвертация статуса TaxiOrder → BookingStatus
  BookingStatus _convertOrderStatusToBookingStatus(String orderStatus) {
    switch (orderStatus.toLowerCase()) {
      case 'pending':
        return BookingStatus.pending;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'in_progress':
        return BookingStatus.inProgress;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.pending;
    }
  }

  /// Получение всех активных бронирований
  /// ✅ ОБНОВЛЕНО: Загружает заказы с backend API (https://titotr.ru)
  Future<List<Booking>> getActiveBookings() async {
    debugPrint('🔍 Получение активных бронирований с backend API...');
    
    try {
      // Получаем все заказы с сервера (без фильтра статуса пока)
      final response = await _ordersApi.getOrders();
      
      debugPrint('📥 Получено ${response.orders.length} заказов с сервера');
      
      // Конвертируем ApiOrder → Booking и фильтруем активные
      final bookings = <Booking>[];
      for (final apiOrder in response.orders) {
        try {
          // Фильтруем только активные статусы
          if (apiOrder.status == OrderStatus.pending ||
              apiOrder.status == OrderStatus.confirmed ||
              apiOrder.status == OrderStatus.inProgress) {
            bookings.add(_convertApiOrderToBooking(apiOrder));
          }
        } catch (e) {
          debugPrint('⚠️ Ошибка конвертации заказа ${apiOrder.id}: $e');
        }
      }
      
      debugPrint('✅ Успешно загружено ${bookings.length} активных заказов');
      return bookings;
    } catch (e) {
      debugPrint('❌ Ошибка загрузки заказов с сервера: $e');
      debugPrint('⚠️ Fallback: загружаем локальные заказы');
      return _getOfflineActiveBookings();
    }
  }
  
  /// Конвертация ApiOrder → Booking
  Booking _convertApiOrderToBooking(ApiOrder apiOrder) {
    final metadata = apiOrder.metadata ?? {};
    
    return Booking(
      id: apiOrder.id,
      clientId: apiOrder.userId,
      tripType: TripType.customRoute, // По умолчанию свободный маршрут
      direction: Direction.donetskToRostov, // По умолчанию (можно из metadata)
      departureDate: apiOrder.departureTime,
      departureTime: '${apiOrder.departureTime.hour.toString().padLeft(2, '0')}:${apiOrder.departureTime.minute.toString().padLeft(2, '0')}',
      passengerCount: apiOrder.passengerCount,
      pickupAddress: apiOrder.fromAddress,
      dropoffAddress: apiOrder.toAddress,
      totalPrice: apiOrder.totalPrice.toInt(),
      status: _convertApiStatusToBookingStatus(apiOrder.status),
      createdAt: apiOrder.createdAt,
      notes: apiOrder.notes,
      vehicleClass: metadata['vehicleClass'] as String? ?? 'sedan',
      passengers: _parsePassengers(metadata['passengers']),
      baggage: _parseBaggage(metadata['baggage']),
      pets: _parsePets(metadata['pets']),
      trackingPoints: [],
      distanceKm: (metadata['distance'] as num?)?.toDouble(),
      baseCost: (metadata['base_cost'] as num?)?.toDouble(),
      costPerKm: (metadata['cost_per_km'] as num?)?.toDouble(),
    );
  }
  
  /// Конвертация статуса API → Booking
  BookingStatus _convertApiStatusToBookingStatus(OrderStatus apiStatus) {
    switch (apiStatus) {
      case OrderStatus.pending:
        return BookingStatus.pending;
      case OrderStatus.confirmed:
        return BookingStatus.confirmed;
      case OrderStatus.inProgress:
        return BookingStatus.inProgress;
      case OrderStatus.completed:
        return BookingStatus.completed;
      case OrderStatus.cancelled:
        return BookingStatus.cancelled;
    }
  }
  
  /// Парсинг пассажиров из JSON
  List<PassengerInfo> _parsePassengers(dynamic passengersData) {
    if (passengersData == null) return [];
    
    try {
      final List<dynamic> list = passengersData is String 
          ? jsonDecode(passengersData) 
          : passengersData as List<dynamic>;
      
      return list.map((e) => PassengerInfo.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Парсинг багажа из JSON
  List<BaggageItem> _parseBaggage(dynamic baggageData) {
    if (baggageData == null) return [];
    
    try {
      final List<dynamic> list = baggageData is String 
          ? jsonDecode(baggageData) 
          : baggageData as List<dynamic>;
      
      return list.map((e) => BaggageItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Парсинг животных из JSON
  List<PetInfo> _parsePets(dynamic petsData) {
    if (petsData == null) return [];
    
    try {
      final List<dynamic> list = petsData is String 
          ? jsonDecode(petsData) 
          : petsData as List<dynamic>;
      
      return list.map((e) => PetInfo.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Получение локальных активных бронирований
  Future<List<Booking>> _getOfflineActiveBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final bookingsJson = prefs.getString(_offlineBookingsKey);

    if (bookingsJson == null) return [];

    final bookingsList = jsonDecode(bookingsJson) as List<dynamic>;
    final activeBookings = <Booking>[];

    for (final bookingData in bookingsList) {
      final booking = Booking.fromJson(bookingData as Map<String, dynamic>);

      // Фильтруем активные статусы
      if ([
        BookingStatus.pending,
        BookingStatus.confirmed,
        BookingStatus.assigned,
        BookingStatus.inProgress,
      ].contains(booking.status)) {
        activeBookings.add(booking);
      }
    }

    // Сортируем по дате отправления
    activeBookings.sort((a, b) => a.departureDate.compareTo(b.departureDate));

    return activeBookings;
  }

  /// Получение бронирований по дате (локально)
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<List<Booking>> getBookingsByDate(DateTime date) async {
    debugPrint(
      'ℹ️ Получение бронирований по дате локально (Firebase не подключен)',
    );
    // В будущем здесь будет запрос к Firebase
    return [];
  }

  /// Обновление статуса бронирования (локально)
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    debugPrint(
      'ℹ️ Обновление статуса бронирования локально (Firebase не подключен)',
    );
    // В будущем здесь будет обновление в Firebase
  }

  /// Назначение транспорта на бронирование (локально)
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<void> assignVehicle(String bookingId, String vehicleId) async {
    debugPrint('ℹ️ Назначение транспорта локально (Firebase не подключен)');
    // В будущем здесь будет обновление в Firebase
  }

  /// Добавление точки отслеживания (локально)
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<void> addTrackingPoint(String bookingId, TrackingPoint point) async {
    debugPrint(
      'ℹ️ Добавление точки отслеживания локально (Firebase не подключен)',
    );
    // В будущем здесь будет обновление в Firebase
  }

  /// Обновление бронирования (локально)
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<void> updateBooking(Booking booking) async {
    debugPrint('ℹ️ Обновление бронирования локально (Firebase не подключен)');
    // В будущем здесь будет обновление в Firebase
  }

  /// Отмена бронирования (локально)
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<void> cancelBooking(String bookingId, [String? reason]) async {
    debugPrint('ℹ️ Отмена бронирования локально (Firebase не подключен)');
    await _cancelOfflineBooking(bookingId, reason);
  }

  /// НОВОЕ: Отмена оффлайн бронирования
  Future<void> _cancelOfflineBooking(String bookingId, [String? reason]) async {
    final prefs = await SharedPreferences.getInstance();
    final bookingsJson = prefs.getString(_offlineBookingsKey);

    if (bookingsJson != null) {
      final bookingsList = jsonDecode(bookingsJson) as List<dynamic>;

      // Находим и обновляем статус бронирования
      for (int i = 0; i < bookingsList.length; i++) {
        final bookingData = bookingsList[i] as Map<String, dynamic>;
        if (bookingData['id'] == bookingId) {
          bookingData['status'] = BookingStatus.cancelled.toString();
          bookingData['updatedAt'] = DateTime.now().toIso8601String();
          if (reason != null) {
            bookingData['notes'] = reason;
          }
          break;
        }
      }

      // Сохраняем обновленный список
      await prefs.setString(_offlineBookingsKey, jsonEncode(bookingsList));
      print('📱 Бронирование $bookingId отменено в оффлайн режиме');
    }
  }

  /// Получение статистики по бронированиям (локально)
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<Map<String, int>> getBookingStats() async {
    debugPrint(
      'ℹ️ Получение статистики бронирований локально (Firebase не подключен)',
    );
    // В будущем здесь будет запрос к Firebase
    final stats = <String, int>{};
    for (final status in BookingStatus.values) {
      stats[status.toString()] = 0;
    }
    return stats;
  }
}
