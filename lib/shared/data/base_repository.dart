import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Base Repository with Smart Caching Strategy
/// Implements "Network-First, Cache-Fallback" strategy
abstract class BaseRepository {
  final Box? _cacheBox;

  BaseRepository([this._cacheBox]);

  /// Execute a request with smart caching
  /// [key]: Unique cache key (e.g. 'student_attendance_123')
  /// [request]: The async network request to execute
  /// [fromJson]: Function to convert JSON to Model/Data
  /// [toJson]: Function to convert Data to JSON (for caching)
  /// [ttl]: Time-to-live for cache (default: 1 day)
  Future<T> smartRequest<T>({
    required String key,
    required Future<T> Function() request,
    required T Function(dynamic json) fromJson,
    required dynamic Function(T data) toJson,
    Duration ttl = const Duration(days: 1),
    bool forceRefresh = false,
  }) async {
    // 1. Check Connectivity
    final connectivity = await Connectivity().checkConnectivity();
    final hasInternet = connectivity != ConnectivityResult.none;

    // 2. Try Network if Online
    if (hasInternet && !forceRefresh) {
      try {
        final data = await request();
        // Save to cache asynchronously
        _saveToCache(key, toJson(data));
        return data;
      } catch (e) {
        debugPrint('⚠️ Network request failed: $e. Falling back to cache...');
      }
    }

    // 3. Fallback to Cache
    final cachedData = _getFromCache(key, ttl);
    if (cachedData != null) {
      debugPrint('📦 Serving from cache: $key');
      return fromJson(cachedData);
    }

    // 4. If forced refresh or no cache, try network again (and fail if needed)
    if (forceRefresh || !hasInternet) {
      // If we're here, we either wanted fresh data and network failed above (or we skipped it),
      // OR we have no internet and no cache.
      // Try network one last time if we have internet, otherwise throw
      if (hasInternet) {
        final data = await request();
        _saveToCache(key, toJson(data));
        return data;
      }
    }

    throw Exception('No internet connection and no cached data available.');
  }

  void _saveToCache(String key, dynamic data) {
    if (_cacheBox == null) return;
    _cacheBox.put(key, {
      'timestamp': DateTime.now().toIso8601String(),
      'data': data,
    });
  }

  dynamic _getFromCache(String key, Duration ttl) {
    if (_cacheBox == null) return null;
    final cached = _cacheBox.get(key);
    if (cached == null) return null;

    final timestamp = DateTime.parse(cached['timestamp']);
    final age = DateTime.now().difference(timestamp);

    if (age > ttl) {
      _cacheBox.delete(key); // Expired
      return null;
    }

    return cached['data'];
  }
}
