import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';

class UserRepository {
  final ApiClient _apiClient;

  UserRepository(this._apiClient);

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _apiClient.dio.get('/users/me');
      if (response.data['success']) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }

  Future<void> updateProfile(String name, String email) async {
    try {
      final response = await _apiClient.dio.patch('/users/me', data: {
        'name': name,
        'email': email,
      });
      if (!response.data['success']) {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> updateAvatar(String avatarUrl) async {
    try {
      final response = await _apiClient.dio.patch('/users/me/avatar', data: {
        'avatarUrl': avatarUrl,
      });
      if (!response.data['success']) {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Failed to update avatar: $e');
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await _apiClient.dio.patch('/auth/change-password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      if (!response.data['success']) {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }

  Future<void> deleteAccount() async {
    try {
      final response = await _apiClient.dio.delete('/auth/account');
      if (!response.data['success']) {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UserRepository(apiClient);
});
