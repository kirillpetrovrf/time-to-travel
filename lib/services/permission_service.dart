import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

/// Сервис для управления разрешениями приложения
/// Проверяет и запрашивает разрешения на геолокацию и уведомления
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  static PermissionService get instance => _instance;

  /// Проверка статуса разрешения на геолокацию
  Future<bool> isLocationEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      print('❌ Ошибка проверки геолокации: $e');
      return false;
    }
  }

  /// Проверка разрешения на геолокацию
  Future<bool> hasLocationPermission() async {
    try {
      final permission = await Permission.location.status;
      return permission.isGranted;
    } catch (e) {
      print('❌ Ошибка проверки разрешения на геолокацию: $e');
      return false;
    }
  }

  /// Запрос разрешения на геолокацию
  Future<bool> requestLocationPermission() async {
    try {
      final permission = await Permission.location.request();
      if (permission.isGranted) {
        print('✅ Разрешение на геолокацию получено');
        return true;
      } else if (permission.isPermanentlyDenied) {
        print('⚠️ Разрешение на геолокацию отклонено навсегда');
        return false;
      } else {
        print('⚠️ Разрешение на геолокацию отклонено');
        return false;
      }
    } catch (e) {
      print('❌ Ошибка запроса разрешения на геолокацию: $e');
      return false;
    }
  }

  /// Проверка разрешения на уведомления
  Future<bool> hasNotificationPermission() async {
    try {
      final permission = await Permission.notification.status;
      return permission.isGranted;
    } catch (e) {
      print('❌ Ошибка проверки разрешения на уведомления: $e');
      return false;
    }
  }

  /// Запрос разрешения на уведомления
  Future<bool> requestNotificationPermission() async {
    try {
      final permission = await Permission.notification.request();
      if (permission.isGranted) {
        print('✅ Разрешение на уведомления получено');
        return true;
      } else if (permission.isPermanentlyDenied) {
        print('⚠️ Разрешение на уведомления отклонено навсегда');
        return false;
      } else {
        print('⚠️ Разрешение на уведомления отклонено');
        return false;
      }
    } catch (e) {
      print('❌ Ошибка запроса разрешения на уведомления: $e');
      return false;
    }
  }

  /// Открытие настроек приложения
  Future<bool> openAppSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      print('❌ Ошибка открытия настроек: $e');
      return false;
    }
  }

  /// Проверка всех необходимых разрешений
  Future<Map<String, bool>> checkAllPermissions() async {
    return {
      'location_enabled': await isLocationEnabled(),
      'location_permission': await hasLocationPermission(),
      'notification_permission': await hasNotificationPermission(),
    };
  }

  /// Запрос всех необходимых разрешений при первом запуске
  Future<bool> requestAllPermissions() async {
    bool locationGranted = await requestLocationPermission();
    bool notificationGranted = await requestNotificationPermission();

    print('📱 Результаты запроса разрешений:');
    print('  - Геолокация: $locationGranted');
    print('  - Уведомления: $notificationGranted');

    return locationGranted && notificationGranted;
  }

  /// Проверка, нужно ли показывать диалог с объяснением
  Future<bool> shouldShowPermissionRationale() async {
    try {
      final locationStatus = await Permission.location.status;
      final notificationStatus = await Permission.notification.status;

      // Показываем диалог, если разрешения не даны, но и не отклонены навсегда
      return (!locationStatus.isGranted &&
              !locationStatus.isPermanentlyDenied) ||
          (!notificationStatus.isGranted &&
              !notificationStatus.isPermanentlyDenied);
    } catch (e) {
      print('❌ Ошибка проверки необходимости диалога: $e');
      return false;
    }
  }
}
