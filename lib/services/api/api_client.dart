import 'package:dio/dio.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        // Placeholder for future API base URL, ideally from .env
        baseUrl: 'https://api.remindly.placeholder/v1',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Setup interceptors for future use (e.g. logging, auth token injection)
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Future: Inject token here
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          // Future: Handle global errors (e.g., 401 refresh token)
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;
}

// Global instance for now, can be provided via Riverpod later if needed
final apiClient = ApiClient();
