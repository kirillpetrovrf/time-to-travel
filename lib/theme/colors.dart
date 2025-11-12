import 'package:flutter/cupertino.dart';

/// Цветовая схема приложения Time to Travel
class AppColors {
  // Основные цвета (из дизайна сайта клиента)
  static const Color primary = Color(0xFFE53E3E); // Ярко-красный основной
  static const Color primaryDark = Color(0xFFC53030); // Тёмно-красный
  static const Color primaryLight = Color(0xFFFC8181); // Светло-красный
  static const Color secondary = Color(0xFF2D3748); // Тёмно-серый
  static const Color accent = Color(0xFFED8936); // Оранжевый акцент

  // Системные цвета
  static const Color success = Color(0xFF38A169);
  static const Color warning = Color(0xFFED8936);
  static const Color danger = Color(0xFFE53E3E);

  // Нейтральные цвета
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray1 = Color(0xFF8E8E93);
  static const Color gray2 = Color(0xFFC7C7CC);
  static const Color gray3 = Color(0xFFD1D1D6);
  static const Color gray4 = Color(0xFFE5E5EA);
  static const Color gray5 = Color(0xFFF2F2F7);
  static const Color gray6 = Color(0xFFFAFAFA);

  // Time to Travel темная тема (основанная на дизайне сайта)
  static const Color darkBackground = Color(0xFF1A1A1A); // Основной тёмный фон
  static const Color darkBackgroundSecondary = Color(
    0xFF2D2D2D,
  ); // Вторичный тёмный фон
  static const Color darkBackgroundTertiary = Color(
    0xFF404040,
  ); // Третичный фон (карточки)
  static const Color darkSurface = Color(0xFF333333); // Поверхности
  static const Color darkBorder = Color(0xFF555555); // Границы

  // Системные цвета фона (светлая тема)
  static const Color systemBackground = Color(0xFFFFFFFF);
  static const Color secondarySystemBackground = Color(0xFFF2F2F7);
  static const Color tertiarySystemBackground = Color(0xFFFFFFFF);

  // Цвета для группированного фона
  static const Color systemGroupedBackground = Color(0xFFF2F2F7);
  static const Color secondarySystemGroupedBackground = Color(0xFFFFFFFF);
  static const Color tertiarySystemGroupedBackground = Color(0xFFF2F2F7);

  // Цвета текста (светлая тема)
  static const Color label = Color(0xFF000000);
  static const Color secondaryLabel = Color(0x99000000);
  static const Color tertiaryLabel = Color(0x4D000000);
  static const Color quaternaryLabel = Color(0x2D000000);
  static const Color placeholderText = Color(0x4D000000);

  // Цвета разделителей
  static const Color separator = Color(0x49000000);
  static const Color opaqueSeparator = Color(0xFFC6C6C8);

  // Time to Travel темная тема - цвета текста
  static const Color darkLabel = Color(0xFFFFFFFF); // Основной белый текст
  static const Color darkSecondaryLabel = Color(
    0xFFB0B0B0,
  ); // Вторичный серый текст
  static const Color darkTertiaryLabel = Color(
    0xFF808080,
  ); // Третичный серый текст
  static const Color darkQuaternaryLabel = Color(
    0xFF606060,
  ); // Четвертичный текст
  static const Color darkPlaceholderText = Color(
    0xFF808080,
  ); // Placeholder текст

  // Time to Travel темная тема - разделители
  static const Color darkSeparator = Color(0x33FFFFFF); // Полупрозрачный белый
  static const Color darkOpaqueSeparator = Color(
    0xFF555555,
  ); // Непрозрачный серый

  // Старые цвета темной темы (для совместимости)
  static const Color darkSystemBackground = Color(0xFF000000);
  static const Color darkSecondarySystemBackground = Color(0xFF1C1C1E);
  static const Color darkTertiarySystemBackground = Color(0xFF2C2C2E);
}

/// Размеры и отступы
class AppDimensions {
  // Отступы
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  static const double paddingXXL = 48.0;

  // Радиусы скругления
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusXXL = 24.0;

  // Размеры иконок
  static const double iconS = 16.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;

  // Размеры кнопок
  static const double buttonHeightS = 32.0;
  static const double buttonHeightM = 44.0;
  static const double buttonHeightL = 56.0;

  // Размеры изображений
  static const double avatarS = 32.0;
  static const double avatarM = 48.0;
  static const double avatarL = 64.0;
  static const double avatarXL = 96.0;
}

/// Типография
class AppTextStyles {
  // Размеры шрифтов
  static const double fontSizeXS = 12.0;
  static const double fontSizeS = 14.0;
  static const double fontSizeM = 16.0;
  static const double fontSizeL = 18.0;
  static const double fontSizeXL = 20.0;
  static const double fontSizeXXL = 24.0;
  static const double fontSizeXXXL = 32.0;

  // Веса шрифтов
  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemiBold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;

  // Стили текста
  static const TextStyle largeTitle = TextStyle(
    fontSize: fontSizeXXXL,
    fontWeight: weightBold,
    color: AppColors.label,
  );

  static const TextStyle title1 = TextStyle(
    fontSize: fontSizeXXL,
    fontWeight: weightBold,
    color: AppColors.label,
  );

  static const TextStyle title2 = TextStyle(
    fontSize: fontSizeXL,
    fontWeight: weightSemiBold,
    color: AppColors.label,
  );

  static const TextStyle title3 = TextStyle(
    fontSize: fontSizeL,
    fontWeight: weightSemiBold,
    color: AppColors.label,
  );

  static const TextStyle headline = TextStyle(
    fontSize: fontSizeM,
    fontWeight: weightSemiBold,
    color: AppColors.label,
  );

  static const TextStyle body = TextStyle(
    fontSize: fontSizeM,
    fontWeight: weightRegular,
    color: AppColors.label,
  );

  static const TextStyle callout = TextStyle(
    fontSize: fontSizeM,
    fontWeight: weightMedium,
    color: AppColors.label,
  );

  static const TextStyle subhead = TextStyle(
    fontSize: fontSizeS,
    fontWeight: weightRegular,
    color: AppColors.label,
  );

  static const TextStyle footnote = TextStyle(
    fontSize: fontSizeXS,
    fontWeight: weightRegular,
    color: AppColors.secondaryLabel,
  );

  static const TextStyle caption1 = TextStyle(
    fontSize: fontSizeXS,
    fontWeight: weightMedium,
    color: AppColors.secondaryLabel,
  );

  static const TextStyle caption2 = TextStyle(
    fontSize: 11.0,
    fontWeight: weightMedium,
    color: AppColors.secondaryLabel,
  );
}

/// Специальные цвета Time to Travel
class TimeToTravelColors {
  // Основная красная палитра (из дизайна сайта)
  static const Color redPrimary = Color(0xFFE53E3E); // Основной красный
  static const Color redDark = Color(0xFFC53030); // Тёмный красный
  static const Color redLight = Color(0xFFFC8181); // Светлый красный
  static const Color redAccent = Color(0xFFFF6B6B); // Акцентный красный

  // Градиенты как в дизайне сайта
  static const List<Color> redGradient = [Color(0xFFE53E3E), Color(0xFFFF6B6B)];

  static const List<Color> darkRedGradient = [
    Color(0xFFC53030),
    Color(0xFFE53E3E),
  ];

  // Тёмная тема - основные цвета
  static const Color darkBg = Color(0xFF1A1A1A); // Основной фон
  static const Color darkBgSecondary = Color(0xFF2D2D2D); // Карточки, блоки
  static const Color darkBgTertiary = Color(0xFF404040); // Поднятые элементы
  static const Color darkSurface = Color(0xFF333333); // Поверхности
  static const Color darkBorder = Color(0xFF555555); // Границы

  // Статистические блоки (как на сайте)
  static const Color statsBg = Color(0xFF2A2A2A); // Фон блоков статистики
  static const Color statsAccent = Color(0xFFE53E3E); // Акцент в статистике

  // Текст
  static const Color textPrimary = Color(0xFFFFFFFF); // Основной белый
  static const Color textSecondary = Color(0xFFB0B0B0); // Серый вторичный
  static const Color textMuted = Color(0xFF808080); // Приглушённый
  static const Color textAccent = Color(0xFFE53E3E); // Красный акцент

  // Создание LinearGradient для использования в виджетах
  static const LinearGradient primaryGradient = LinearGradient(
    colors: redGradient,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkPrimaryGradient = LinearGradient(
    colors: darkRedGradient,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
