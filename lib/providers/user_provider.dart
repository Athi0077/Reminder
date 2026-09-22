import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/user_repository.dart';

class UserState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? profile;

  UserState({
    this.isLoading = false,
    this.error,
    this.profile,
  });

  UserState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? profile,
  }) {
    return UserState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      profile: profile ?? this.profile,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  final UserRepository _repository;

  UserNotifier(this._repository) : super(UserState()) {
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = await _repository.getProfile();
      state = state.copyWith(isLoading: false, profile: profile);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> updateProfile(String name, String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.updateProfile(name, email);
      await fetchProfile();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateAvatar(String avatarUrl) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.updateAvatar(avatarUrl);
      await fetchProfile();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.changePassword(currentPassword, newPassword);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteAccount();
      state = state.copyWith(isLoading: false, profile: null);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return UserNotifier(repository);
});
