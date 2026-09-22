import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/env.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class ApiClient {
  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        String friendlyMessage = 'Something went wrong. Please try again.';
        if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
          friendlyMessage = 'Connection timed out. Please check your internet connection.';
        } else if (e.type == DioExceptionType.connectionError) {
          friendlyMessage = 'No internet connection.';
        } else if (e.response != null) {
          final statusCode = e.response?.statusCode;
          if (statusCode == 401) {
            friendlyMessage = 'Your session has expired. Please sign in again.';
            await _storage.delete(key: 'jwt_token');
            // Notification or callback to log out user could be added here
          } else if (statusCode == 403) {
            friendlyMessage = 'You do not have permission to perform this action.';
          } else if (statusCode == 404) {
            friendlyMessage = 'Resource not found.';
          } else if (statusCode == 409) {
            friendlyMessage = e.response?.data?['message'] ?? 'Conflict occurred.';
          } else if (statusCode == 422) {
            friendlyMessage = e.response?.data?['message'] ?? 'Validation error.';
          } else if (statusCode == 429) {
            friendlyMessage = 'Too many requests. Please try again later.';
          } else if (statusCode! >= 500) {
            friendlyMessage = 'Server Error. Please try again later.';
          } else if (e.response?.data != null && e.response?.data['message'] != null) {
            friendlyMessage = e.response?.data['message'];
          }
        }
        
        // Attach friendly message to the error
        e = e.copyWith(message: friendlyMessage);
        
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<void> removeToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }
}
