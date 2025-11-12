// Константы приложения Taxi Route Calculator
import 'package:flutter/material.dart';

/// API ключ Yandex MapKit
const String kYandexMapKitApiKey = '2f1d6a75-b751-4077-b305-c6abaea0b542';

/// Цвета iOS Cupertino дизайна
class AppColors {
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color gray = Color(0xFF8E8E93);
  static const Color lightGray = Color(0xFFF2F2F7);
  static const Color darkGray = Color(0xFF3A3A3C);
  static const Color separator = Color(0xFFC6C6C8);
  static const Color systemBlue = Color(0xFF007AFF);
  
  // Для пульсирующих волн
  static const Color waveGray = Color(0xFF8E8E93);
}

/// Радиусы скругления
class AppRadius {
  static const double small = 10.0;
  static const double medium = 12.0;
  static const double large = 16.0;
}

/// Отступы
class AppPadding {
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
}

/// Параметры анимации пульсирующих волн
class WaveAnimation {
  static const Duration longPressDuration = Duration(milliseconds: 1500);
  static const Duration waveDuration = Duration(milliseconds: 1500);
  static const int waveCount = 4;
  static const double minRadius = 20.0;
  static const double maxRadius = 60.0;
  static const double startOpacity = 0.4;
  static const double endOpacity = 0.0;
}

/// Настройки маршрутизации
class RoutingSettings {
  static const double defaultPricePerKm = 15.0; // руб/км
  static const double defaultBaseFare = 100.0; // базовый тариф
}
