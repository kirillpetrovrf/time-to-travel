// Extension для cast операций
extension CastExtension<T> on T {
  U? castOrNull<U>() {
    return this is U ? this as U : null;
  }
}