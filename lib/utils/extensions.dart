/// Utility extensions из common пакета taxi_route_calculator
/// Заменяет зависимость от package:common/common.dart

extension LetExtension<T> on T {
  R let<R>(R Function(T it) block) => block(this);
}

extension AlsoExtension<T> on T {
  T also(void Function(T it) block) {
    block(this);
    return this;
  }
}

extension TakeIf<T> on T {
  T? takeIf(bool Function(T it) condition) {
    return condition(this) ? this : null;
  }
}

extension Cast on dynamic {
  T? castOrNull<T>() => this is T ? this : null;
}

extension IsBlank on String? {
  bool get isBlank => this?.trim().isEmpty == true;
  bool get isNotBlank => this?.trim().isNotEmpty == true;
}
