import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_tokens.dart';
import '../../shared/widgets/feedback.dart';
import 'auth_provider.dart';

class PendingScreen extends ConsumerWidget {
  const PendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: EmptyState(
        icon: Icons.hourglass_top_outlined,
        title: 'Awaiting approval',
        message:
            'Your account is pending review by a manager. You will receive access once approved.',
        action: Column(
          children: [
            FilledButton(
              onPressed: () => ref.read(authProvider.notifier).refresh(),
              child: const Text('Check status'),
            ),
            TextButton(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
