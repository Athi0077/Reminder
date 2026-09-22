import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/common/app_button.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 768;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: isDesktop
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: _buildIllustration(),
                        ),
                      ),
                      const SizedBox(width: 48),
                      Expanded(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: _buildContent(context),
                        ),
                      ),
                    ],
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildIllustration(),
                        const SizedBox(height: 48),
                        _buildContent(context),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    return Container(
      constraints: const BoxConstraints(minHeight: 300),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 64,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.notifications_none,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.person_outline,
                  size: 64,
                  color: AppColors.secondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_none, color: AppColors.primary, size: 28),
            const SizedBox(width: 8),
            Text(
              'Remindly',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          'Together\nNothing is Forgotten 💙',
          style: Theme.of(context).textTheme.displayMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Plan Together. Stay on Track.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 18,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        AppButton(
          text: 'Get Started',
          onPressed: () => context.push('/signup'),
        ),
        const SizedBox(height: 16),
        AppButton(
          text: 'I already have an account',
          isSecondary: true,
          onPressed: () => context.push('/login'),
        ),
      ],
    );
  }
}
