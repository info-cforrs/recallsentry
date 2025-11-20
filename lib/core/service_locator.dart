/// Simple service locator for dependency injection
///
/// Provides a centralized place to configure and retrieve service instances.
/// Supports singleton and factory patterns for service registration.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service locator for managing dependencies
class ServiceLocator {
  ServiceLocator._(); // Private constructor

  static final ServiceLocator _instance = ServiceLocator._();
  static ServiceLocator get instance => _instance;

  final Map<Type, dynamic> _singletons = {};
  final Map<Type, Function> _factories = {};

  /// Register a singleton instance
  ///
  /// The instance will be created immediately and reused for all requests.
  ///
  /// Example:
  /// ```dart
  /// ServiceLocator.instance.registerSingleton<AuthService>(
  ///   AuthService(
  ///     storage: FlutterSecureStorage(),
  ///     httpClient: SecurityService().createSecureHttpClient(),
  ///   ),
  /// );
  /// ```
  void registerSingleton<T>(T instance) {
    _singletons[T] = instance;
  }

  /// Register a factory function
  ///
  /// The factory function will be called each time get() is called.
  ///
  /// Example:
  /// ```dart
  /// ServiceLocator.instance.registerFactory<ApiService>(
  ///   () => ApiService(httpClient: get<http.Client>()),
  /// );
  /// ```
  void registerFactory<T>(T Function() factory) {
    _factories[T] = factory;
  }

  /// Register a lazy singleton
  ///
  /// The instance will be created on first access and then reused.
  ///
  /// Example:
  /// ```dart
  /// ServiceLocator.instance.registerLazySingleton<RecallDataService>(
  ///   () => RecallDataService(
  ///     apiService: get<ApiService>(),
  ///     sheetsService: get<GoogleSheetsService>(),
  ///   ),
  /// );
  /// ```
  void registerLazySingleton<T>(T Function() factory) {
    _factories[T] = () {
      if (!_singletons.containsKey(T)) {
        _singletons[T] = factory();
      }
      return _singletons[T];
    };
  }

  /// Get an instance of type T
  ///
  /// Throws [StateError] if the type is not registered.
  ///
  /// Example:
  /// ```dart
  /// final authService = ServiceLocator.instance.get<AuthService>();
  /// ```
  T get<T>() {
    // Check singletons first
    if (_singletons.containsKey(T)) {
      return _singletons[T] as T;
    }

    // Check factories
    if (_factories.containsKey(T)) {
      return _factories[T]!() as T;
    }

    throw StateError(
      'Type $T is not registered in ServiceLocator. '
      'Please register it using registerSingleton, registerFactory, or registerLazySingleton.',
    );
  }

  /// Check if a type is registered
  bool isRegistered<T>() {
    return _singletons.containsKey(T) || _factories.containsKey(T);
  }

  /// Unregister a type
  ///
  /// Useful for testing or replacing implementations.
  void unregister<T>() {
    _singletons.remove(T);
    _factories.remove(T);
  }

  /// Reset all registrations
  ///
  /// Useful for testing.
  void reset() {
    _singletons.clear();
    _factories.clear();
  }

  /// Get an instance if registered, otherwise return null
  T? getOrNull<T>() {
    try {
      return get<T>();
    } catch (_) {
      return null;
    }
  }
}

/// Configure all application services
///
/// Call this once during app initialization.
///
/// Example:
/// ```dart
/// void main() {
///   setupServiceLocator();
///   runApp(MyApp());
/// }
/// ```
void setupServiceLocator() {
  final locator = ServiceLocator.instance;

  // Register core dependencies
  locator.registerSingleton<FlutterSecureStorage>(
    const FlutterSecureStorage(),
  );

  // HTTP clients can be registered here
  // Note: Services can also create their own clients as needed

  // Services will be registered when we refactor them to use DI
  // Example (to be implemented):
  // locator.registerLazySingleton<AuthService>(
  //   () => AuthService(
  //     storage: locator.get<FlutterSecureStorage>(),
  //     httpClient: SecurityService().createSecureHttpClient(),
  //   ),
  // );
}

/// Convenience function to get an instance from the service locator
///
/// Example:
/// ```dart
/// final authService = getIt<AuthService>();
/// ```
T getIt<T>() => ServiceLocator.instance.get<T>();

/// Convenience function to get an instance or null
T? getItOrNull<T>() => ServiceLocator.instance.getOrNull<T>();
