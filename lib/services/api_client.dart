import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/question.dart';

class ApiClient {
  // কুইজের প্রশ্ন নিয়ে আসার জন্য বেজ ইউআরএল (Base URL)
  static const String _baseUrl = 'https://opentdb.com/api.php';
  late Dio _dio;

  ApiClient({Dio? dio}) {
    _dio = dio ?? Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10), // কানেক্ট হওয়ার জন্য ১০ সেকেন্ড ওয়েট করবে
        receiveTimeout: const Duration(seconds: 10), // রেসপন্স রিসিভ করার জন্য ১০ সেকেন্ড ওয়েট করবে
      ),
    );

    // রিকোয়েস্ট, রেসপন্স এবং এররগুলো সহজে ট্র্যাকিং বা ডিবাগ করার জন্য ইন্টারসেপ্টর অ্যাড করা
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('API Requesting: ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('API Response Status: ${response.statusCode}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          debugPrint('API Error Occurred: ${e.message}');
          return handler.next(e);
        },
      ),
    );
  }

  /// ব্যাকএন্ড/API থেকে প্রশ্নের লিস্ট নিয়ে আসা এবং অফলাইনের জন্য ক্যাশ করে রাখা
  Future<List<Question>> fetchQuestions({
    int amount = 10,
    String difficulty = 'medium',
  }) async {
    try {
      final response = await _dio.get(
        '',
        queryParameters: {'amount': amount, 'difficulty': difficulty},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // JSON লিস্টকে Question মডেল অবজেক্টের লিস্টে কনভার্ট করা
        final List<Question> questions = (data['results'] as List)
            .map((json) => Question.fromJson(json))
            .toList();
        debugPrint('Fetched ${questions.length} questions from API');

        // ইন্টারনেট সাকসেসফুল থাকলে ডাটাগুলো অফলাইন ব্যাকআপের জন্য SharedPreferences-এ সেভ করা
        final prefs = await SharedPreferences.getInstance();
        final jsonString = jsonEncode(
          questions.map((q) => q.toJson()).toList(),
        );
        await prefs.setString('cached_questions', jsonString);

        return questions;
      } else {
        throw Exception('Failed to fetch questions');
      }
    } catch (e) {
      // ইন্টারনেট না থাকলে বা কোনো এরর হলে SharedPreferences-এর ক্যাশ থেকে ডাটা লোড করার চেষ্টা করা
      debugPrint('Network error, attempting to load from cache: $e');
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString('cached_questions');

      if (cachedString != null && cachedString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(cachedString);
        final cachedQuestions = decoded
            .map((json) => Question.fromJson(json))
            .toList();
        debugPrint('Loaded ${cachedQuestions.length} questions from cache');
        return cachedQuestions;
      }

      // যদি ইন্টারনেটও না থাকে এবং ক্যাশ মেমোরিও খালি থাকে
      throw Exception('Failed to fetch questions and cache is empty');
    }
  }
}