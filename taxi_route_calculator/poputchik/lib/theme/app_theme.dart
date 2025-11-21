import 'package:flutter/cupertino.dart';
import 'colors.dart';

/// Настраиваемая тема приложения
class CustomTheme {
  final String id;
  final String name;
  final bool isDark;

  // Основные цвета
  final Color primary;
  final Color secondary;
  final Color success;
  final Color warning;
  final Color danger;

  // Цвета фона
  final Color systemBackground;
  final Color secondarySystemBackground;
  final Color tertiarySystemBackground;

  // Цвета текста
  final Color label;
  final Color secondaryLabel;
  final Color tertiaryLabel;

  // Цвета разделителей
  final Color separator;
  final Color opaqueSeparator;

  // Размеры
  final double buttonHeight;
  final double borderRadius;
  final double iconSize;

  // Шрифты
  final double baseFontSize;
  final FontWeight baseFontWeight;

  // Видимость элементов
  final bool showShadows;
  final bool showBorders;
  final bool showIcons;
  final bool compactMode;

  const CustomTheme({
    required this.id,
    required this.name,
    required this.isDark,
    required this.primary,
    required this.secondary,
    required this.success,
    required this.warning,
    required this.danger,
    required this.systemBackground,
    required this.secondarySystemBackground,
    required this.tertiarySystemBackground,
    required this.label,
    required this.secondaryLabel,
    required this.tertiaryLabel,
    required this.separator,
    required this.opaqueSeparator,
    required this.buttonHeight,
    required this.borderRadius,
    required this.iconSize,
    required this.baseFontSize,
    required this.baseFontWeight,
    required this.showShadows,
    required this.showBorders,
    required this.showIcons,
    required this.compactMode,
  });

  /// Копирование темы с изменениями
  CustomTheme copyWith({
    String? id,
    String? name,
    bool? isDark,
    Color? primary,
    Color? secondary,
    Color? success,
    Color? warning,
    Color? danger,
    Color? systemBackground,
    Color? secondarySystemBackground,
    Color? tertiarySystemBackground,
    Color? label,
    Color? secondaryLabel,
    Color? tertiaryLabel,
    Color? separator,
    Color? opaqueSeparator,
    double? buttonHeight,
    double? borderRadius,
    double? iconSize,
    double? baseFontSize,
    FontWeight? baseFontWeight,
    bool? showShadows,
    bool? showBorders,
    bool? showIcons,
    bool? compactMode,
  }) {
    return CustomTheme(
      id: id ?? this.id,
      name: name ?? this.name,
      isDark: isDark ?? this.isDark,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      systemBackground: systemBackground ?? this.systemBackground,
      secondarySystemBackground:
          secondarySystemBackground ?? this.secondarySystemBackground,
      tertiarySystemBackground:
          tertiarySystemBackground ?? this.tertiarySystemBackground,
      label: label ?? this.label,
      secondaryLabel: secondaryLabel ?? this.secondaryLabel,
      tertiaryLabel: tertiaryLabel ?? this.tertiaryLabel,
      separator: separator ?? this.separator,
      opaqueSeparator: opaqueSeparator ?? this.opaqueSeparator,
      buttonHeight: buttonHeight ?? this.buttonHeight,
      borderRadius: borderRadius ?? this.borderRadius,
      iconSize: iconSize ?? this.iconSize,
      baseFontSize: baseFontSize ?? this.baseFontSize,
      baseFontWeight: baseFontWeight ?? this.baseFontWeight,
      showShadows: showShadows ?? this.showShadows,
      showBorders: showBorders ?? this.showBorders,
      showIcons: showIcons ?? this.showIcons,
      compactMode: compactMode ?? this.compactMode,
    );
  }

  /// Конвертация в Map для сохранения
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isDark': isDark,
      'primary': primary.toARGB32(),
      'secondary': secondary.toARGB32(),
      'success': success.toARGB32(),
      'warning': warning.toARGB32(),
      'danger': danger.toARGB32(),
      'systemBackground': systemBackground.toARGB32(),
      'secondarySystemBackground': secondarySystemBackground.toARGB32(),
      'tertiarySystemBackground': tertiarySystemBackground.toARGB32(),
      'label': label.toARGB32(),
      'secondaryLabel': secondaryLabel.toARGB32(),
      'tertiaryLabel': tertiaryLabel.toARGB32(),
      'separator': separator.toARGB32(),
      'opaqueSeparator': opaqueSeparator.toARGB32(),
      'buttonHeight': buttonHeight,
      'borderRadius': borderRadius,
      'iconSize': iconSize,
      'baseFontSize': baseFontSize,
      'baseFontWeight': baseFontWeight.index,
      'showShadows': showShadows,
      'showBorders': showBorders,
      'showIcons': showIcons,
      'compactMode': compactMode,
    };
  }

  /// Создание темы из Map
  factory CustomTheme.fromJson(Map<String, dynamic> json) {
    return CustomTheme(
      id: json['id'],
      name: json['name'],
      isDark: json['isDark'],
      primary: Color(json['primary']),
      secondary: Color(json['secondary']),
      success: Color(json['success']),
      warning: Color(json['warning']),
      danger: Color(json['danger']),
      systemBackground: Color(json['systemBackground']),
      secondarySystemBackground: Color(json['secondarySystemBackground']),
      tertiarySystemBackground: Color(json['tertiarySystemBackground']),
      label: Color(json['label']),
      secondaryLabel: Color(json['secondaryLabel']),
      tertiaryLabel: Color(json['tertiaryLabel']),
      separator: Color(json['separator']),
      opaqueSeparator: Color(json['opaqueSeparator']),
      buttonHeight: json['buttonHeight'],
      borderRadius: json['borderRadius'],
      iconSize: json['iconSize'],
      baseFontSize: json['baseFontSize'],
      baseFontWeight: FontWeight.values[json['baseFontWeight']],
      showShadows: json['showShadows'],
      showBorders: json['showBorders'],
      showIcons: json['showIcons'],
      compactMode: json['compactMode'],
    );
  }
}

/// Основная система тем приложения
class AppTheme {
  /// Светлая тема по умолчанию
  static const CustomTheme defaultLight = CustomTheme(
    id: 'default_light',
    name: 'Светлая тема',
    isDark: false,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    success: AppColors.success,
    warning: AppColors.warning,
    danger: AppColors.danger,
    systemBackground: AppColors.systemBackground,
    secondarySystemBackground: AppColors.secondarySystemBackground,
    tertiarySystemBackground: AppColors.tertiarySystemBackground,
    label: AppColors.label,
    secondaryLabel: AppColors.secondaryLabel,
    tertiaryLabel: AppColors.tertiaryLabel,
    separator: AppColors.separator,
    opaqueSeparator: AppColors.opaqueSeparator,
    buttonHeight: AppDimensions.buttonHeightM,
    borderRadius: AppDimensions.radiusM,
    iconSize: AppDimensions.iconM,
    baseFontSize: AppTextStyles.fontSizeM,
    baseFontWeight: AppTextStyles.weightRegular,
    showShadows: true,
    showBorders: true,
    showIcons: true,
    compactMode: false,
  );

  /// Темная тема по умолчанию
  static const CustomTheme defaultDark = CustomTheme(
    id: 'default_dark',
    name: 'Темная тема',
    isDark: true,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    success: AppColors.success,
    warning: AppColors.warning,
    danger: AppColors.danger,
    systemBackground: AppColors.darkSystemBackground,
    secondarySystemBackground: AppColors.darkSecondarySystemBackground,
    tertiarySystemBackground: AppColors.darkTertiarySystemBackground,
    label: AppColors.darkLabel,
    secondaryLabel: AppColors.darkSecondaryLabel,
    tertiaryLabel: AppColors.darkTertiaryLabel,
    separator: AppColors.separator,
    opaqueSeparator: AppColors.opaqueSeparator,
    buttonHeight: AppDimensions.buttonHeightM,
    borderRadius: AppDimensions.radiusM,
    iconSize: AppDimensions.iconM,
    baseFontSize: AppTextStyles.fontSizeM,
    baseFontWeight: AppTextStyles.weightRegular,
    showShadows: true,
    showBorders: true,
    showIcons: true,
    compactMode: false,
  );

  /// Компактная тема
  static const CustomTheme compact = CustomTheme(
    id: 'compact',
    name: 'Компактная',
    isDark: false,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    success: AppColors.success,
    warning: AppColors.warning,
    danger: AppColors.danger,
    systemBackground: AppColors.systemBackground,
    secondarySystemBackground: AppColors.secondarySystemBackground,
    tertiarySystemBackground: AppColors.tertiarySystemBackground,
    label: AppColors.label,
    secondaryLabel: AppColors.secondaryLabel,
    tertiaryLabel: AppColors.tertiaryLabel,
    separator: AppColors.separator,
    opaqueSeparator: AppColors.opaqueSeparator,
    buttonHeight: AppDimensions.buttonHeightS,
    borderRadius: AppDimensions.radiusS,
    iconSize: AppDimensions.iconS,
    baseFontSize: AppTextStyles.fontSizeS,
    baseFontWeight: AppTextStyles.weightRegular,
    showShadows: false,
    showBorders: false,
    showIcons: true,
    compactMode: true,
  );

  /// Получение CupertinoThemeData из CustomTheme
  static CupertinoThemeData getCurrentTheme(CustomTheme theme) {
    return CupertinoThemeData(
      brightness: theme.isDark ? Brightness.dark : Brightness.light,
      primaryColor: theme.primary,
      scaffoldBackgroundColor: theme.systemBackground,
      barBackgroundColor: theme.secondarySystemBackground,
      textTheme: CupertinoTextThemeData(
        primaryColor: theme.label,
        textStyle: TextStyle(
          color: theme.label,
          fontSize: theme.baseFontSize,
          fontWeight: theme.baseFontWeight,
          inherit: false,
        ),
        actionTextStyle: TextStyle(
          color: theme.primary,
          fontSize: theme.baseFontSize,
          fontWeight: theme.baseFontWeight,
          inherit: false,
        ),
        tabLabelTextStyle: TextStyle(
          color: theme.secondaryLabel,
          fontSize: theme.baseFontSize - 2,
          fontWeight: theme.baseFontWeight,
          inherit: false,
        ),
        navTitleTextStyle: TextStyle(
          color: theme.label,
          fontSize: theme.baseFontSize + 2,
          fontWeight: FontWeight.w600,
          inherit: false,
        ),
        navLargeTitleTextStyle: TextStyle(
          color: theme.label,
          fontSize: theme.baseFontSize + 16,
          fontWeight: FontWeight.bold,
          inherit: false,
        ),
      ),
    );
  }

  /// Список всех доступных тем
  static List<CustomTheme> get allThemes => [
    defaultLight,
    defaultDark,
    compact,
  ];

  /// Получение темы по ID
  static CustomTheme? getThemeById(String id) {
    try {
      return allThemes.firstWhere((theme) => theme.id == id);
    } catch (e) {
      return null;
    }
  }
}
