import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.data['success']) {
        final token = response.data['data']['token'];
        await _apiClient.saveToken(token);
        return response.data['data']['user'];
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Failed to login: $e');
    }
  }

  Future<Map<String, dynamic>> signup(String name, String email, String password) async {
    try {
      final response = await _apiClient.dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
      });

      if (response.data['success']) {
        final token = response.data['data']['token'];
        await _apiClient.saveToken(token);
        return response.data['data']['user'];
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }

  Future<void> forgotPassword(String email) async {
    // Backend doesn't have forgot password yet, mocking for now
    await Future.delayed(const Duration(seconds: 1));
  }
  
  Future<void> logout() async {
    await _apiClient.removeToken();
  }

  Future<Map<String, dynamic>?> checkAuth() async {
    final token = await _apiClient.getToken();
    if (token != null) {
      try {
        final response = await _apiClient.dio.get('/users/me');
        if (response.data['success'] == true) {
          return response.data['data'];
        }
      } catch (e) {
        await _apiClient.removeToken();
        return null;
      }
    }
    return null;
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient);
});
