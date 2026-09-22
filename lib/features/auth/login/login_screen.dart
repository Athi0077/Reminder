import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../widgets/common/app_button.dart';
import '../../../../widgets/common/app_card.dart';
import '../../../../widgets/common/app_text_field.dart';
import '../../../../widgets/common/password_text_field.dart';
import '../../../../widgets/common/error_message.dart';
import '../../../../core/utils/validators.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authProvider.notifier).login(
            _emailController.text,
            _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth success to navigate
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStateStatus.authenticated) {
        context.go('/home');
      }
    });

    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStateStatus.loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Welcome Back 👋',
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Let's make sure nothing gets forgotten.",
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  AppCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (authState.status == AuthStateStatus.error &&
                              authState.errorMessage != null) ...[
                            ErrorMessage(message: authState.errorMessage!),
                            const SizedBox(height: 16),
                          ],
                          AppTextField(
                            label: 'Email',
                            hint: 'Enter your email',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: Validators.validateEmail,
                          ),
                          const SizedBox(height: 16),
                          PasswordTextField(
                            controller: _passwordController,
                            validator: Validators.validatePassword,
                            onSubmitted: (_) => _onLogin(),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.push('/forgot-password'),
                              style: TextButton.styleFrom(
                                minimumSize: Size.zero,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                              child: const Text('Forgot Password?'),
                            ),
                          ),
                          const SizedBox(height: 24),
                          AppButton(
                            text: 'Sign In',
                            isLoading: isLoading,
                            onPressed: _onLogin,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () => context.push('/signup'),
                        child: const Text('Create Account'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
