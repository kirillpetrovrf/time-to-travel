// Let extension for nullable objects
extension LetExtension<T> on T? {
  R? let<R>(R Function(T) operation) {
    if (this != null) {
      return operation(this!);
    }
    return null;
  }
}