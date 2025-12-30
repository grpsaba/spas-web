import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/pointage_exception.dart';

/// Manager for caching data with TTL (Time To Live) support
/// 
/// Uses SharedPreferences for persistent storage
/// Requirements: 9.1, 9.2, 9.3
class CacheManager {
  static const String _cachePrefix = 'pointage_cache_';
  static const String _metaPrefix = 'pointage_meta_';
  static const int _maxCacheSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const Duration _defaultTTL = Duration(minutes: 5);

  SharedPreferences? _prefs;
  bool _initialized = false;

  /// Custom encoder for non-JSON-serializable types
  dynamic _toEncodable(dynamic object) {
    if (object is DateTime) {
      return object.toIso8601String();
    }
    if (object is Duration) {
      return object.inMilliseconds;
    }
    // For objects with toJson method
    if (object != null) {
      try {
        return (object as dynamic).toJson();
      } catch (_) {
        // If toJson doesn't exist, return string representation
        return object.toString();
      }
    }
    return object;
  }

  /// Initialize the cache manager
  /// Must be called before using any other methods
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
      
      // Clean up expired entries on initialization
      await _cleanupExpiredEntries();
    } catch (e) {
      debugPrint('Error initializing CacheManager: $e');
      throw PointageException.cache(
        message: 'Impossible d\'initialiser le cache',
        originalError: e,
      );
    }
  }

  /// Ensure the cache manager is initialized
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  /// Get a cached value by key
  /// 
  /// Returns null if the key doesn't exist or has expired
  /// Requirements: 9.1
  Future<T?> get<T>(String key) async {
    try {
      await _ensureInitialized();
      
      final cacheKey = _cachePrefix + key;
      final metaKey = _metaPrefix + key;

      // Check if entry exists
      if (!_prefs!.containsKey(cacheKey)) {
        return null;
      }

      // Check if entry has expired
      final metaJson = _prefs!.getString(metaKey);
      if (metaJson != null) {
        final meta = jsonDecode(metaJson) as Map<String, dynamic>;
        final expiryTime = DateTime.parse(meta['expiry'] as String);
        
        if (DateTime.now().isAfter(expiryTime)) {
          // Entry has expired, remove it
          await invalidate(key);
          return null;
        }
      }

      // Get the cached value
      final cachedJson = _prefs!.getString(cacheKey);
      if (cachedJson == null) {
        return null;
      }

      // Deserialize based on type
      final data = jsonDecode(cachedJson);
      
      // Return the data (caller is responsible for casting)
      return data as T;
    } catch (e) {
      debugPrint('Error getting cached value for key $key: $e');
      // Don't throw, just return null and let the caller fetch fresh data
      return null;
    }
  }

  /// Set a cached value with optional TTL
  /// 
  /// Requirements: 9.1, 9.2
  Future<void> set<T>(
    String key,
    T value, {
    Duration? ttl,
  }) async {
    try {
      await _ensureInitialized();
      
      final cacheKey = _cachePrefix + key;
      final metaKey = _metaPrefix + key;

      // Serialize the value with custom DateTime handling
      final jsonString = jsonEncode(value, toEncodable: _toEncodable);
      
      // Check cache size before adding
      final estimatedSize = jsonString.length;
      await _ensureCacheSize(estimatedSize);

      // Calculate expiry time
      final expiryTime = DateTime.now().add(ttl ?? _defaultTTL);
      
      // Store metadata
      final meta = {
        'expiry': expiryTime.toIso8601String(),
        'size': estimatedSize,
        'created': DateTime.now().toIso8601String(),
      };
      
      await _prefs!.setString(metaKey, jsonEncode(meta));
      await _prefs!.setString(cacheKey, jsonString);
      
      debugPrint('Cached $key with TTL ${ttl ?? _defaultTTL}');
    } catch (e) {
      debugPrint('Error setting cached value for key $key: $e');
      throw PointageException.cache(
        message: 'Impossible de mettre en cache les données',
        originalError: e,
      );
    }
  }

  /// Invalidate (remove) a cached entry
  /// 
  /// Requirements: 9.2
  Future<void> invalidate(String key) async {
    try {
      await _ensureInitialized();
      
      final cacheKey = _cachePrefix + key;
      final metaKey = _metaPrefix + key;

      await _prefs!.remove(cacheKey);
      await _prefs!.remove(metaKey);
      
      debugPrint('Invalidated cache for key: $key');
    } catch (e) {
      debugPrint('Error invalidating cache for key $key: $e');
      // Don't throw, invalidation failure is not critical
    }
  }

  /// Invalidate all entries matching a pattern
  /// 
  /// Pattern matching uses simple string contains logic
  /// Requirements: 9.2
  Future<void> invalidatePattern(String pattern) async {
    try {
      await _ensureInitialized();
      
      final keys = _prefs!.getKeys();
      final keysToRemove = keys.where((key) => 
        key.startsWith(_cachePrefix) && key.contains(pattern)
      ).toList();

      for (var key in keysToRemove) {
        final originalKey = key.substring(_cachePrefix.length);
        await invalidate(originalKey);
      }
      
      debugPrint('Invalidated ${keysToRemove.length} entries matching pattern: $pattern');
    } catch (e) {
      debugPrint('Error invalidating pattern $pattern: $e');
    }
  }

  /// Clear all cached entries
  /// 
  /// Requirements: 9.2
  Future<void> clear() async {
    try {
      await _ensureInitialized();
      
      final keys = _prefs!.getKeys();
      final cacheKeys = keys.where((key) => 
        key.startsWith(_cachePrefix) || key.startsWith(_metaPrefix)
      ).toList();

      for (var key in cacheKeys) {
        await _prefs!.remove(key);
      }
      
      debugPrint('Cleared all cache entries (${cacheKeys.length} items)');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
      throw PointageException.cache(
        message: 'Impossible de vider le cache',
        originalError: e,
      );
    }
  }

  /// Check if a cached entry is still valid (not expired)
  /// 
  /// Requirements: 9.1
  Future<bool> isValid(String key) async {
    try {
      await _ensureInitialized();
      
      final metaKey = _metaPrefix + key;
      final metaJson = _prefs!.getString(metaKey);
      
      if (metaJson == null) {
        return false;
      }

      final meta = jsonDecode(metaJson) as Map<String, dynamic>;
      final expiryTime = DateTime.parse(meta['expiry'] as String);
      
      return DateTime.now().isBefore(expiryTime);
    } catch (e) {
      debugPrint('Error checking cache validity for key $key: $e');
      return false;
    }
  }

  /// Get the current cache size in bytes
  /// 
  /// Requirements: 9.3
  Future<int> getCacheSize() async {
    try {
      await _ensureInitialized();
      
      int totalSize = 0;
      final keys = _prefs!.getKeys();
      
      for (var key in keys) {
        if (key.startsWith(_metaPrefix)) {
          final metaJson = _prefs!.getString(key);
          if (metaJson != null) {
            final meta = jsonDecode(metaJson) as Map<String, dynamic>;
            totalSize += (meta['size'] as int?) ?? 0;
          }
        }
      }
      
      return totalSize;
    } catch (e) {
      debugPrint('Error calculating cache size: $e');
      return 0;
    }
  }

  /// Get cache statistics
  Future<CacheStats> getStats() async {
    try {
      await _ensureInitialized();
      
      final keys = _prefs!.getKeys();
      final cacheKeys = keys.where((key) => key.startsWith(_cachePrefix)).toList();
      
      int validEntries = 0;
      int expiredEntries = 0;
      int totalSize = 0;
      
      for (var cacheKey in cacheKeys) {
        final originalKey = cacheKey.substring(_cachePrefix.length);
        final metaKey = _metaPrefix + originalKey;
        final metaJson = _prefs!.getString(metaKey);
        
        if (metaJson != null) {
          final meta = jsonDecode(metaJson) as Map<String, dynamic>;
          final expiryTime = DateTime.parse(meta['expiry'] as String);
          final size = (meta['size'] as int?) ?? 0;
          
          totalSize += size;
          
          if (DateTime.now().isBefore(expiryTime)) {
            validEntries++;
          } else {
            expiredEntries++;
          }
        }
      }
      
      return CacheStats(
        totalEntries: cacheKeys.length,
        validEntries: validEntries,
        expiredEntries: expiredEntries,
        totalSizeBytes: totalSize,
        maxSizeBytes: _maxCacheSizeBytes,
      );
    } catch (e) {
      debugPrint('Error getting cache stats: $e');
      return CacheStats(
        totalEntries: 0,
        validEntries: 0,
        expiredEntries: 0,
        totalSizeBytes: 0,
        maxSizeBytes: _maxCacheSizeBytes,
      );
    }
  }

  /// Clean up expired entries
  /// 
  /// Requirements: 9.2, 9.3
  Future<void> _cleanupExpiredEntries() async {
    try {
      final keys = _prefs!.getKeys();
      final metaKeys = keys.where((key) => key.startsWith(_metaPrefix)).toList();
      
      int removedCount = 0;
      
      for (var metaKey in metaKeys) {
        final metaJson = _prefs!.getString(metaKey);
        if (metaJson != null) {
          final meta = jsonDecode(metaJson) as Map<String, dynamic>;
          final expiryTime = DateTime.parse(meta['expiry'] as String);
          
          if (DateTime.now().isAfter(expiryTime)) {
            final originalKey = metaKey.substring(_metaPrefix.length);
            await invalidate(originalKey);
            removedCount++;
          }
        }
      }
      
      if (removedCount > 0) {
        debugPrint('Cleaned up $removedCount expired cache entries');
      }
    } catch (e) {
      debugPrint('Error cleaning up expired entries: $e');
    }
  }

  /// Ensure cache size doesn't exceed maximum
  /// 
  /// Removes oldest entries if needed
  /// Requirements: 9.3
  Future<void> _ensureCacheSize(int newEntrySize) async {
    try {
      final currentSize = await getCacheSize();
      
      if (currentSize + newEntrySize <= _maxCacheSizeBytes) {
        return; // We have enough space
      }

      // Need to free up space - remove oldest entries
      final keys = _prefs!.getKeys();
      final metaKeys = keys.where((key) => key.startsWith(_metaPrefix)).toList();
      
      // Sort by creation time (oldest first)
      final entries = <MapEntry<String, DateTime>>[];
      
      for (var metaKey in metaKeys) {
        final metaJson = _prefs!.getString(metaKey);
        if (metaJson != null) {
          final meta = jsonDecode(metaJson) as Map<String, dynamic>;
          final created = DateTime.parse(meta['created'] as String);
          final originalKey = metaKey.substring(_metaPrefix.length);
          entries.add(MapEntry(originalKey, created));
        }
      }
      
      entries.sort((a, b) => a.value.compareTo(b.value));
      
      // Remove oldest entries until we have enough space
      int freedSpace = 0;
      int targetSpace = newEntrySize + (currentSize - _maxCacheSizeBytes);
      
      for (var entry in entries) {
        if (freedSpace >= targetSpace) break;
        
        final metaKey = _metaPrefix + entry.key;
        final metaJson = _prefs!.getString(metaKey);
        if (metaJson != null) {
          final meta = jsonDecode(metaJson) as Map<String, dynamic>;
          freedSpace += (meta['size'] as int?) ?? 0;
        }
        
        await invalidate(entry.key);
      }
      
      debugPrint('Freed $freedSpace bytes by removing old cache entries');
    } catch (e) {
      debugPrint('Error ensuring cache size: $e');
    }
  }
}

/// Cache statistics model
class CacheStats {
  final int totalEntries;
  final int validEntries;
  final int expiredEntries;
  final int totalSizeBytes;
  final int maxSizeBytes;

  CacheStats({
    required this.totalEntries,
    required this.validEntries,
    required this.expiredEntries,
    required this.totalSizeBytes,
    required this.maxSizeBytes,
  });

  /// Get cache usage percentage
  double get usagePercentage {
    if (maxSizeBytes == 0) return 0.0;
    return (totalSizeBytes / maxSizeBytes) * 100;
  }

  /// Get human-readable size
  String get totalSizeFormatted {
    if (totalSizeBytes < 1024) {
      return '$totalSizeBytes B';
    } else if (totalSizeBytes < 1024 * 1024) {
      return '${(totalSizeBytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  @override
  String toString() {
    return 'CacheStats(total: $totalEntries, valid: $validEntries, expired: $expiredEntries, size: $totalSizeFormatted, usage: ${usagePercentage.toStringAsFixed(1)}%)';
  }
}
