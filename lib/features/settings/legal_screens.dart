import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Privacy Policy', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            const Text(
              '[Placeholder] This is a placeholder for the actual Privacy Policy.\n\n'
              'Remindly does not claim legal compliance with this text. '
              'Please replace this with a real privacy policy before publishing.',
            ),
          ],
        ),
      ),
    );
  }
}

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Terms of Service', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            const Text(
              '[Placeholder] This is a placeholder for the actual Terms of Service.\n\n'
              'Remindly does not claim legal compliance with this text. '
              'Please replace this with real terms of service before publishing.',
            ),
          ],
        ),
      ),
    );
  }
}
