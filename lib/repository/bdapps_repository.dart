import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class BdAppsService {
  static const String appId = "APP_139070";
  static const String appPassword = "be919b81951ff4fce2c23e59c0e29f39";
  static const String _baseUrl = 'https://quiz.solobit.dev';
  late Dio _dio;

  BdAppsService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(responseBody: true, requestBody: true),
    );
  }

  /// রিপোজিটরি যেভাবে কল করছে: _service.requestOtp(mobileNumber: mobileNumber)
  Future<Map<String, dynamic>> requestOtp({required String mobileNumber}) async {
    try {
      final response = await _dio.post(
        '/send_otp.php',
        data: FormData.fromMap({
          'appId': appId,
          'password': appPassword,
          'user_mobile': mobileNumber,
        }),
      );
      return response.data;
    } catch (e) {
      debugPrint('Error requesting OTP: $e');
      throw Exception('Failed to request OTP: $e');
    }
  }

  /// রিপোজিটরি যেভাবে কল করছে: _service.verifyOtp(requestId: requestId, otpCode: otpCode)
  Future<Map<String, dynamic>> verifyOtp({
    required String requestId,
    required String otpCode,
  }) async {
    try {
      final response = await _dio.post(
        '/verify_otp.php',
        data: FormData.fromMap({
          'appId': appId,
          'password': appPassword,
          'referenceNo': requestId,
          'Otp': otpCode,
        }),
      );
      return response.data;
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      throw Exception('Failed to verify OTP: $e');
    }
  }

  /// রিপোজিটরি যেভাবে কল করছে: _service.status()
  Future<Map<String, dynamic>> status() async {
    try {
      final response = await _dio.post(
        '/check_subscription.php',
        data: FormData.fromMap({
          'appId': appId,
          'password': appPassword,
        }),
      );
      return response.data;
    } catch (e) {
      debugPrint('Error checking status: $e');
      throw Exception('Failed to check status: $e');
    }
  }

  /// রিপোজিটরি যেভাবে কল করছে: _service.callback(payload: payload)
  Future<Map<String, dynamic>> callback({required Map<String, dynamic> payload}) async {
    try {
      // যদি আপনার ব্যাকএন্ডে আলাদা কোনো callback রাউট না থাকে,
      // তবে এটি সরাসরি রেসপন্স বা পেমেন্ট/সাবস্ক্রিপশন ডাটা হ্যান্ডেল করবে।
      return payload;
    } catch (e) {
      debugPrint('Error in callback: $e');
      throw Exception('Failed to process callback: $e');
    }
  }
}