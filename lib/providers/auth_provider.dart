import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import '../services/notification_service.dart';
import '../services/socket_service.dart';

enum AuthStateStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  final AuthStateStatus status;
  final String? errorMessage;
  final String? userId;

  const AuthState({
    this.status = AuthStateStatus.initial,
    this.errorMessage,
    this.userId,
  });

  AuthState copyWith({
    AuthStateStatus? status,
    String? errorMessage,
    String? userId,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      userId: userId ?? this.userId,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final SocketService _socketService;

  AuthNotifier(this._repository, this._socketService) : super(const AuthState(status: AuthStateStatus.initial)) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    state = state.copyWith(status: AuthStateStatus.loading);
    final user = await _repository.checkAuth();
    if (user != null) {
      state = state.copyWith(status: AuthStateStatus.authenticated, userId: user['id']);
      _socketService.connect();
    } else {
      state = state.copyWith(status: AuthStateStatus.unauthenticated, userId: null);
      _socketService.disconnect();
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStateStatus.loading, errorMessage: null);
    try {
      final user = await _repository.login(email, password);
      state = state.copyWith(status: AuthStateStatus.authenticated, userId: user['id']);
      _socketService.connect();
    } catch (e) {
      state = state.copyWith(
        status: AuthStateStatus.error,
        errorMessage: e.toString(),
      );
      // Reset to unauthenticated after showing error
      await Future.delayed(const Duration(seconds: 3));
      if (state.status == AuthStateStatus.error) {
        state = state.copyWith(status: AuthStateStatus.unauthenticated);
      }
    }
  }

  Future<void> signup(String name, String email, String password) async {
    state = state.copyWith(status: AuthStateStatus.loading, errorMessage: null);
    try {
      final user = await _repository.signup(name, email, password);
      state = state.copyWith(status: AuthStateStatus.authenticated, userId: user['id']);
      _socketService.connect();
    } catch (e) {
      state = state.copyWith(
        status: AuthStateStatus.error,
        errorMessage: e.toString(),
      );
      // Reset to unauthenticated after showing error
      await Future.delayed(const Duration(seconds: 3));
      if (state.status == AuthStateStatus.error) {
        state = state.copyWith(status: AuthStateStatus.unauthenticated);
      }
    }
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStateStatus.loading);
    await _repository.logout();
    await NotificationService().cancelAll();
    _socketService.disconnect();
    state = state.copyWith(status: AuthStateStatus.unauthenticated, userId: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final socketService = ref.watch(socketServiceProvider);
  return AuthNotifier(repository, socketService);
});
