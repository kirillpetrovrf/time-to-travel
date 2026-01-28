import '../models/order_model.dart';

/// In-Memory Cache Data Source for Orders
/// 
/// Provides simple TTL-based caching WITHOUT SQLite.
/// Cache entries expire after 30 seconds.
class OrdersCacheDataSource {
  final Map<String, OrderModel> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  /// Cache duration (5 minutes for optimal balance)
  static const _cacheDuration = Duration(minutes: 5);

  /// Save orders to cache
  void cacheOrders(List<OrderModel> orders) {
    final now = DateTime.now();
    for (final order in orders) {
      _cache[order.id] = order;
      _cacheTimestamps[order.id] = now;
    }
  }

  /// Get all cached orders (if fresh)
  List<OrderModel>? getCachedOrders() {
    if (_cache.isEmpty) return null;

    // Check cache freshness
    final oldestTimestamp = _cacheTimestamps.values.reduce(
      (a, b) => a.isBefore(b) ? a : b,
    );

    final age = DateTime.now().difference(oldestTimestamp);
    if (age > _cacheDuration) {
      clearCache(); // Cache expired
      return null;
    }

    return _cache.values.toList();
  }

  /// Get cached order by ID
  OrderModel? getCachedOrderById(String id) {
    final timestamp = _cacheTimestamps[id];
    if (timestamp == null) return null;

    final age = DateTime.now().difference(timestamp);
    if (age > _cacheDuration) {
      _cache.remove(id);
      _cacheTimestamps.remove(id);
      return null;
    }

    return _cache[id];
  }

  /// Update single order in cache
  void cacheOrder(OrderModel order) {
    _cache[order.id] = order;
    _cacheTimestamps[order.id] = DateTime.now();
  }

  /// Remove order from cache
  void removeOrderFromCache(String id) {
    _cache.remove(id);
    _cacheTimestamps.remove(id);
  }

  /// Clear all cache
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// Check if cache is fresh
  bool get isCacheFresh {
    if (_cache.isEmpty) return false;

    final oldestTimestamp = _cacheTimestamps.values.reduce(
      (a, b) => a.isBefore(b) ? a : b,
    );

    final age = DateTime.now().difference(oldestTimestamp);
    return age <= _cacheDuration;
  }

  /// Get cache size
  int get cacheSize => _cache.length;

  /// Get cache age
  Duration? get cacheAge {
    if (_cache.isEmpty) return null;

    final oldestTimestamp = _cacheTimestamps.values.reduce(
      (a, b) => a.isBefore(b) ? a : b,
    );

    return DateTime.now().difference(oldestTimestamp);
  }
}
