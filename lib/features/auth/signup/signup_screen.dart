import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../widgets/common/app_button.dart';
import '../../../../widgets/common/app_card.dart';
import '../../../../widgets/common/app_text_field.dart';
import '../../../../widgets/common/password_text_field.dart';
import '../../../../widgets/common/error_message.dart';
import '../../../../widgets/common/app_avatar.dart';
import '../../../../core/utils/validators.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSignup() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authProvider.notifier).signup(
            _nameController.text,
            _emailController.text,
            _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStateStatus.authenticated) {
        context.go('/home');
      }
    });

    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStateStatus.loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create your account'),
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
                  const Center(
                    child: AppAvatar(
                      radius: 48,
                      onTap: null, // Future: Add image picker
                    ),
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
                            label: 'Full Name',
                            hint: 'Enter your full name',
                            controller: _nameController,
                            validator: Validators.validateName,
                          ),
                          const SizedBox(height: 16),
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
                          ),
                          const SizedBox(height: 16),
                          PasswordTextField(
                            label: 'Confirm Password',
                            hint: 'Confirm your password',
                            controller: _confirmPasswordController,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _onSignup(),
                            validator: (val) => Validators.validateConfirmPassword(
                              val,
                              _passwordController.text,
                            ),
                          ),
                          const SizedBox(height: 32),
                          AppButton(
                            text: 'Create Account',
                            isLoading: isLoading,
                            onPressed: _onSignup,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?"),
                      TextButton(
                        onPressed: () => context.push('/login'),
                        child: const Text('Sign In'),
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
