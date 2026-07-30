import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Configuration for the `v1` PHP gateway folder.
///
/// Drop these endpoints in a folder named `v1/` on your server:
///   - send_otp.php
///   - verify_otp.php
///   - check_subscription.php
///   - unsubscribe.php
///   - app_auth.php        (middleware)
///   - app_credentials.php (credential map)
///   - sdk_file.php        (BDApps SDK, optional)
class BdAppsConfig {
  BdAppsConfig._();

  /// Base URL of the PHP gateway. NO trailing slash. Always use https://.
  /// The `v1/` segment is appended automatically by [BdAppsService].
  /// Production location: `/NADB26066/` directory on `bdappsdigitalapps.com`.
  static const String gatewayBaseUrl = 'https://bdappsdigitalapps.com/NADB26066';

  /// Folder containing the PHP endpoints (left empty because files are at
  /// the gateway root in the production deployment at `bdappsdigitalapps.com`).
  static const String apiVersion = '';

  /// `appName` key registered in `app_credentials.php`. The frontend must
  /// send this in every JSON body so the middleware can pick the right
  /// BDApps credentials. Must match the key in the deployed
  /// `app_credentials.php` exactly (server does case-insensitive lookup).
  /// Confirmed live key on `bdappsdigitalapps.com/NADB26066`: `quiz36`.
  static const String appName = 'quiz36';

  /// Per-endpoint paths (relative to baseUrl).
  static String get _base =>
      apiVersion.isEmpty ? gatewayBaseUrl : '$gatewayBaseUrl/$apiVersion';

  static String get sendOtpPath => '$_base/send_otp.php';
  static String get verifyOtpPath => '$_base/verify_otp.php';
  static String get statusPath => '$_base/check_subscription.php';
  static String get unsubscribePath => '$_base/unsubscribe.php';
}

/// Thin client for the `v1` PHP gateway.
///
/// Every call posts a JSON body that includes an `appName` field. The
/// `app_auth.php` middleware uses that field to look up the real BDApps
/// `applicationId` / `password` from `app_credentials.php` before
/// forwarding to `developer.bdapps.com`.
///
/// No HMAC signing is needed on the client side — credentials are
/// looked up server-side based on `appName`.
class BdAppsService {
  BdAppsService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 20),
                sendTimeout: const Duration(seconds: 15),
                headers: const {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                },
                responseType: ResponseType.json,
              ),
            );

  final Dio _dio;

  /// Posts a JSON body to one of the v1 PHP endpoints. The `appName`
  /// field is injected automatically before the request goes out.
  Future<Map<String, dynamic>> _post(
    String url,
    Map<String, dynamic> body,
  ) async {
    final payload = <String, dynamic>{
      'appName': BdAppsConfig.appName,
      ...body,
    };

    if (kDebugMode) {
      // Don't log the whole body in production — it may contain OTPs.
      debugPrint('BdApps POST $url');
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        data: jsonEncode(payload),
      );
      return response.data ?? <String, dynamic>{};
    } on DioException catch (e) {
      debugPrint('BdApps POST $url failed: ${e.message}');
      throw Exception(
        'Network error while calling ${url.split('/').last}: ${e.message}',
      );
    }
  }

  /// `send_otp.php` — request an OTP for the given mobile number.
  ///
  /// Server returns:
  ///   `{ success: true, referenceNo: '<id>', statusCode: 'S1000' }`
  /// or `{ success: false, statusCode: 'E1351', message: 'user already registered' }`
  Future<Map<String, dynamic>> sendOtp(String mobileNumber) {
    return _post(BdAppsConfig.sendOtpPath, {
      'userMobile': mobileNumber,
    });
  }

  /// `verify_otp.php` — verify the OTP the user entered.
  ///
  /// Server returns:
  ///   `{ statusCode: 'S1000', subscriptionStatus: 'REGISTERED', subscriberId: '...' }`
  Future<Map<String, dynamic>> verifyOtp(
    String referenceNo,
    String otp,
  ) {
    return _post(BdAppsConfig.verifyOtpPath, {
      'referenceNo': referenceNo,
      'otp': otp,
    });
  }

  /// `check_subscription.php` — ask BDApps whether the user is currently
  /// subscribed. Returns `{ isSubscribed: true|false, subscriptionStatus: 'REGISTERED'|'UNREGISTERED' }`.
  Future<Map<String, dynamic>> checkSubscription(String mobileNumber) {
    return _post(BdAppsConfig.statusPath, {
      // Send every key the v1 PHP endpoints recognise so we're compatible
      // regardless of which one the deployed server happens to read.
      // 'userMobile': mobileNumber,
      'user_mobile': mobileNumber,
      'subscriberId': mobileNumber,
    });
  }

  /// `unsubscribe.php` — tell BDApps to stop the user's subscription.
  /// S1000 = success, E1356 = was already unregistered (also treated as success).
  Future<Map<String, dynamic>> unsubscribe(String mobileNumber) {
    return _post(BdAppsConfig.unsubscribePath, {
      'userMobile': mobileNumber,
      'user_mobile': mobileNumber,
      'subscriberId': mobileNumber,
    });
  }
}