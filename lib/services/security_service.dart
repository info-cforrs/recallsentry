import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:crypto/crypto.dart';
import '../config/app_config.dart';

/// Security service for SSL/TLS certificate pinning and validation
///
/// IMPORTANT: Certificate pinning protects against man-in-the-middle attacks
/// by validating that the server's certificate matches expected fingerprints.
///
/// Setup Instructions:
/// 1. Get your server's certificate SHA-256 fingerprint:
///    openssl s_client -connect 18.218.174.62:443 < /dev/null | openssl x509 -fingerprint -sha256 -noout
/// 2. Add the fingerprint to _allowedCertificates below
/// 3. For production, add production domain certificate fingerprints
class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  // Certificate fingerprints (SHA-256) for pinning
  // Retrieved: November 2025
  // Issuer: Let's Encrypt (E7)
  // Valid until: Feb 3, 2026
  static const List<String> _allowedCertificates = [
    // api.centerforrecallsafety.com (currently staging & production)
    // Retrieved via: openssl s_client -connect api.centerforrecallsafety.com:443 < /dev/null | openssl x509 -fingerprint -sha256 -noout
    '4C:54:CC:31:A6:9E:95:CB:7F:FE:27:E4:EF:2B:9A:3B:4A:C1:EC:4B:5A:20:85:45:AF:2B:E3:48:49:21:33:59',
  ];

  // Enable/disable certificate pinning
  // WARNING: Set to false during development if testing with self-signed certificates
  // PRODUCTION: Must be true for app store submission
  static const bool _enableCertificatePinning = true;

  /// Create HTTP client with certificate pinning
  http.Client createSecureHttpClient() {
    if (!_enableCertificatePinning || _allowedCertificates.isEmpty) {
      // Return default client if pinning is disabled or no certificates configured
      return http.Client();
    }

    final httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // CRITICAL: This callback validates the certificate
        // Return false to reject the connection if certificate doesn't match

        if (_enableCertificatePinning) {
          final certFingerprint = _getCertificateFingerprint(cert);

          if (!_allowedCertificates.contains(certFingerprint)) {
            // Certificate not in allowed list - reject connection
            return false;
          }
        }

        // Certificate is valid
        return true;
      };

    return IOClient(httpClient);
  }

  /// Get SHA-256 fingerprint of certificate
  String _getCertificateFingerprint(X509Certificate cert) {
    // Get DER-encoded certificate bytes
    final der = cert.der;

    // Calculate SHA-256 hash
    final digest = sha256.convert(der);

    // Convert to colon-separated hex format matching OpenSSL output
    // e.g., "4C:54:CC:31:A6:9E:95:CB:..."
    final fingerprint = digest.bytes
        .map((byte) => byte.toRadixString(16).toUpperCase().padLeft(2, '0'))
        .join(':');

    return fingerprint;
  }

  /// Validate hostname matches certificate
  bool validateHostname(String hostname) {
    final apiUrl = AppConfig.apiBaseUrl;
    return apiUrl.contains(hostname);
  }

  /// Check if SSL/TLS is properly configured
  static bool get isSecureConnectionConfigured {
    final apiUrl = AppConfig.apiBaseUrl;
    return apiUrl.startsWith('https://');
  }

  /// Get security warnings for current configuration
  static List<String> getSecurityWarnings() {
    final warnings = <String>[];

    if (!isSecureConnectionConfigured) {
      warnings.add('CRITICAL: API is using HTTP instead of HTTPS');
    }

    if (_allowedCertificates.isEmpty) {
      warnings.add('WARNING: Certificate pinning not configured');
    }

    if (!_enableCertificatePinning && _allowedCertificates.isNotEmpty) {
      warnings.add('WARNING: Certificate pinning is disabled');
    }

    return warnings;
  }
}

/// Instructions for implementing full certificate pinning:
///
/// 1. Add crypto dependency to pubspec.yaml:
///    dependencies:
///      crypto: ^3.0.3
///
/// 2. Get certificate fingerprints from your servers:
///    # For staging server
///    openssl s_client -connect 18.218.174.62:443 < /dev/null | \
///      openssl x509 -fingerprint -sha256 -noout
///
///    # For production server
///    openssl s_client -connect api.centerforrecallsafety.com:443 < /dev/null | \
///      openssl x509 -fingerprint -sha256 -noout
///
/// 3. Update _allowedCertificates with actual fingerprints
///
/// 4. Set _enableCertificatePinning = true for production builds
///
/// 5. Update all HTTP services to use SecurityService().createSecureHttpClient()
///    instead of default http.Client()
///
/// Example usage in services:
/// ```dart
/// class AuthService {
///   final http.Client _client = SecurityService().createSecureHttpClient();
///
///   Future<void> login() async {
///     final response = await _client.post(Uri.parse('$baseUrl/token/'));
///   }
/// }
/// ```
