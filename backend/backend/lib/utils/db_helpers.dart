/// Хелперы для работы с БД
DateTime parseDbDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  throw ArgumentError('Expected DateTime or String, got ${value.runtimeType}');
}
