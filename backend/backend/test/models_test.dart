import 'package:test/test.dart';
import 'package:backend/models/user.dart';
import 'package:backend/models/route.dart';
import 'package:backend/models/order.dart';

void main() {
  group('User Model Tests', () {
    test('User.fromDb creates valid user', () {
      final dbRow = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'email': 'test@example.com',
        'password_hash': '\$2a\$10\$abcdefg',
        'name': 'Test User',
        'phone': '+79001234567',
        'is_verified': true,
        'is_active': true,
        'created_at': '2026-01-21T10:00:00Z',
        'updated_at': '2026-01-21T10:00:00Z',
      };

      final user = User.fromDb(dbRow);

      expect(user.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(user.email, 'test@example.com');
      expect(user.name, 'Test User');
      expect(user.phone, '+79001234567');
      expect(user.isVerified, true);
      expect(user.isActive, true);
    });

    test('User.toJson does not include password', () {
      final user = User(
        id: '123',
        email: 'test@example.com',
        passwordHash: 'secret',
        name: 'Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final json = user.toJson();

      expect(json.containsKey('password_hash'), false);
      expect(json.containsKey('passwordHash'), false);
      expect(json['email'], 'test@example.com');
    });
  });

  group('Route Model Tests', () {
    test('PredefinedRoute.fromDb creates valid route', () {
      final dbRow = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'from_city': 'Ростов-на-Дону',
        'to_city': 'Таганрог',
        'price': 2500.50,
        'group_id': '456e7890-e89b-12d3-a456-426614174000',
        'is_active': true,
        'created_at': '2026-01-21T10:00:00Z',
        'updated_at': '2026-01-21T10:00:00Z',
      };

      final route = PredefinedRoute.fromDb(dbRow);

      expect(route.fromCity, 'Ростов-на-Дону');
      expect(route.toCity, 'Таганрог');
      expect(route.price, 2500.50);
      expect(route.isActive, true);
    });
  });

  group('Order Model Tests', () {
    test('OrderStatus.fromDb converts correctly', () {
      expect(OrderStatus.fromDb('pending'), OrderStatus.pending);
      expect(OrderStatus.fromDb('confirmed'), OrderStatus.confirmed);
      expect(OrderStatus.fromDb('in_progress'), OrderStatus.inProgress);
      expect(OrderStatus.fromDb('completed'), OrderStatus.completed);
      expect(OrderStatus.fromDb('cancelled'), OrderStatus.cancelled);
    });

    test('OrderStatus.toDb converts correctly', () {
      expect(OrderStatus.pending.toDb(), 'pending');
      expect(OrderStatus.confirmed.toDb(), 'confirmed');
      expect(OrderStatus.inProgress.toDb(), 'in_progress');
      expect(OrderStatus.completed.toDb(), 'completed');
      expect(OrderStatus.cancelled.toDb(), 'cancelled');
    });

    test('VehicleClass.fromDb converts correctly', () {
      expect(VehicleClass.fromDb('economy'), VehicleClass.economy);
      expect(VehicleClass.fromDb('comfort'), VehicleClass.comfort);
      expect(VehicleClass.fromDb('business'), VehicleClass.business);
      expect(VehicleClass.fromDb('minivan'), VehicleClass.minivan);
      expect(VehicleClass.fromDb(null), null);
    });

    test('Passenger JSON serialization works', () {
      final passenger = Passenger(name: 'Иван Иванов', age: 35);
      final json = passenger.toJson();

      expect(json['name'], 'Иван Иванов');
      expect(json['age'], 35);

      final restored = Passenger.fromJson(json);
      expect(restored.name, 'Иван Иванов');
      expect(restored.age, 35);
    });

    test('Baggage JSON serialization works', () {
      final baggage = Baggage(type: 'suitcase', size: 'large', count: 2);
      final json = baggage.toJson();

      expect(json['type'], 'suitcase');
      expect(json['size'], 'large');
      expect(json['count'], 2);

      final restored = Baggage.fromJson(json);
      expect(restored.type, 'suitcase');
      expect(restored.size, 'large');
      expect(restored.count, 2);
    });

    test('Pet JSON serialization works', () {
      final pet = Pet(type: 'dog', name: 'Бобик', weight: 15.5);
      final json = pet.toJson();

      expect(json['type'], 'dog');
      expect(json['name'], 'Бобик');
      expect(json['weight'], 15.5);

      final restored = Pet.fromJson(json);
      expect(restored.type, 'dog');
      expect(restored.name, 'Бобик');
      expect(restored.weight, 15.5);
    });
  });

  group('DTO Tests', () {
    test('RegisterUserDto serialization works', () {
      final dto = RegisterUserDto(
        email: 'new@example.com',
        password: 'Password123!',
        name: 'New User',
        phone: '+79001234567',
      );

      final json = dto.toJson();
      expect(json['email'], 'new@example.com');
      expect(json['password'], 'Password123!');
      expect(json['name'], 'New User');
      expect(json['phone'], '+79001234567');

      final restored = RegisterUserDto.fromJson(json);
      expect(restored.email, 'new@example.com');
      expect(restored.password, 'Password123!');
    });

    test('CreateOrderDto serialization works', () {
      final dto = CreateOrderDto(
        fromLat: 47.2357,
        fromLon: 39.7015,
        toLat: 47.2361,
        toLon: 38.8975,
        fromAddress: 'Ростов-на-Дону',
        toAddress: 'Таганрог',
        distanceKm: 68.5,
        rawPrice: 2300.00,
        finalPrice: 2500.00,
        baseCost: 500.00,
        costPerKm: 30.00,
        clientName: 'Петров Иван',
        clientPhone: '+79001112233',
        vehicleClass: 'comfort',
      );

      final json = dto.toJson();
      expect(json['fromLat'], 47.2357);
      expect(json['toAddress'], 'Таганрог');
      expect(json['finalPrice'], 2500.00);
      expect(json['vehicleClass'], 'comfort');
    });
  });
}
