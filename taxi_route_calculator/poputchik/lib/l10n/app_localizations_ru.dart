// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Такси Попутчик';

  @override
  String get phoneNumber => 'Номер телефона';

  @override
  String get getCode => 'Получить код';

  @override
  String get enterCode => 'Введите код';

  @override
  String get verify => 'Проверить';

  @override
  String get cancel => 'Отмена';

  @override
  String get done => 'Готово';
}
