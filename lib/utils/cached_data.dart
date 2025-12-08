/// Generic cached data utility class
///
/// Provides a reusable caching pattern to replace duplicated caching code
/// across services. Supports time-based expiration and forced refresh.
///
/// Example usage:
/// ```dart
/// final _cache = CachedData<UserProfile>(duration: Duration(minutes: 15));
///
/// Future<UserProfile> getUserProfile({bool forceRefresh = false}) async {
///   final cached = _cache.get(forceRefresh: forceRefresh);
///   if (cached != null) return cached;
///
///   final profile = await _fetchFromApi();
///   _cache.set(profile);
///   return profile;
/// }
/// ```
class CachedData<T> {
  T? _data;
  DateTime? _timestamp;
  final Duration _duration;

  /// Creates a cached data instance with the specified cache duration.
  ///
  /// [duration] - How long cached data remains valid (default: 15 minutes)
  CachedData({Duration duration = const Duration(minutes: 15)})
      : _duration = duration;

  /// Gets cached data if available and not expired.
  ///
  /// [forceRefresh] - If true, always returns null (forcing a refresh)
  ///
  /// Returns the cached data or null if:
  /// - forceRefresh is true
  /// - No data has been cached
  /// - Cached data has expired
  T? get({bool forceRefresh = false}) {
    if (forceRefresh) return null;
    if (_data == null || _timestamp == null) return null;
    if (DateTime.now().difference(_timestamp!) > _duration) return null;
    return _data;
  }

  /// Stores data in the cache with current timestamp.
  ///
  /// [data] - The data to cache
  void set(T data) {
    _data = data;
    _timestamp = DateTime.now();
  }

  /// Clears all cached data.
  void clear() {
    _data = null;
    _timestamp = null;
  }

  /// Checks if cache has valid (non-expired) data.
  bool get hasValidData {
    if (_data == null || _timestamp == null) return false;
    return DateTime.now().difference(_timestamp!) <= _duration;
  }

  /// Gets the age of the cached data, or null if no data cached.
  Duration? get age {
    if (_timestamp == null) return null;
    return DateTime.now().difference(_timestamp!);
  }

  /// Gets the remaining time until cache expires, or null if no data cached.
  Duration? get timeUntilExpiry {
    if (_timestamp == null) return null;
    final expiry = _timestamp!.add(_duration);
    final remaining = expiry.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

/// Generic cached data with key support for multiple cached values.
///
/// Useful when you need to cache different variations of the same data type,
/// such as recalls filtered by different agencies.
///
/// Example usage:
/// ```dart
/// final _cache = KeyedCachedData<List<Article>>(duration: Duration(hours: 12));
///
/// Future<List<Article>> getArticles({String? tag, bool forceRefresh = false}) async {
///   final cacheKey = tag ?? 'all';
///   final cached = _cache.get(cacheKey, forceRefresh: forceRefresh);
///   if (cached != null) return cached;
///
///   final articles = await _fetchFromApi(tag: tag);
///   _cache.set(cacheKey, articles);
///   return articles;
/// }
/// ```
class KeyedCachedData<T> {
  final Map<String, T> _data = {};
  final Map<String, DateTime> _timestamps = {};
  final Duration _duration;

  /// Creates a keyed cached data instance with the specified cache duration.
  ///
  /// [duration] - How long cached data remains valid (default: 15 minutes)
  KeyedCachedData({Duration duration = const Duration(minutes: 15)})
      : _duration = duration;

  /// Gets cached data for a key if available and not expired.
  ///
  /// [key] - The cache key to look up
  /// [forceRefresh] - If true, always returns null (forcing a refresh)
  ///
  /// Returns the cached data or null if not available or expired.
  T? get(String key, {bool forceRefresh = false}) {
    if (forceRefresh) return null;
    if (!_data.containsKey(key) || !_timestamps.containsKey(key)) return null;
    if (DateTime.now().difference(_timestamps[key]!) > _duration) return null;
    return _data[key];
  }

  /// Stores data in the cache under the specified key.
  ///
  /// [key] - The cache key
  /// [data] - The data to cache
  void set(String key, T data) {
    _data[key] = data;
    _timestamps[key] = DateTime.now();
  }

  /// Clears cached data for a specific key.
  void clearKey(String key) {
    _data.remove(key);
    _timestamps.remove(key);
  }

  /// Clears all cached data.
  void clear() {
    _data.clear();
    _timestamps.clear();
  }

  /// Checks if cache has valid data for a key.
  bool hasValidData(String key) {
    if (!_data.containsKey(key) || !_timestamps.containsKey(key)) return false;
    return DateTime.now().difference(_timestamps[key]!) <= _duration;
  }

  /// Gets all currently cached keys (including expired ones).
  Iterable<String> get keys => _data.keys;

  /// Gets all valid (non-expired) cached keys.
  Iterable<String> get validKeys => _data.keys.where((key) => hasValidData(key));
}
