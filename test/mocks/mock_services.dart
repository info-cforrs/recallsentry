/// Mock Services for Testing
///
/// This file defines mock annotations for all services that need to be mocked
/// during testing. Run `dart run build_runner build` to generate mock implementations.
library;

import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Services to mock
import 'package:rs_flutter/services/auth_service.dart';
import 'package:rs_flutter/services/api_service.dart';
import 'package:rs_flutter/services/subscription_service.dart';
import 'package:rs_flutter/services/iap_service.dart';
import 'package:rs_flutter/services/consent_service.dart';
import 'package:rs_flutter/services/filter_state_service.dart';
import 'package:rs_flutter/services/saved_recalls_service.dart';
import 'package:rs_flutter/services/security_service.dart';
import 'package:rs_flutter/services/fcm_service.dart';
import 'package:rs_flutter/services/gamification_service.dart';

/// Generate mocks for all services
/// Run: dart run build_runner build
@GenerateNiceMocks([
  // Core services
  MockSpec<AuthService>(),
  MockSpec<ApiService>(),
  MockSpec<SubscriptionService>(),
  MockSpec<IAPService>(),
  MockSpec<ConsentService>(),

  // Data services
  MockSpec<FilterStateService>(),
  MockSpec<SavedRecallsService>(),

  // Infrastructure services
  MockSpec<SecurityService>(),
  MockSpec<FCMService>(),
  MockSpec<GamificationService>(),

  // External dependencies
  MockSpec<http.Client>(),
  MockSpec<FlutterSecureStorage>(),
])
void main() {}
