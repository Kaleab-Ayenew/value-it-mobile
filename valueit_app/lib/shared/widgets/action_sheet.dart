import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';

class AppActionSheet extends StatelessWidget {
  const AppActionSheet({super.key, required this.title, required this.actions});

  final String title;
  final List<AppSheetAction> actions;

  static Future<T?> show<T>(BuildContext context, {required String title, required List<AppSheetAction> actions}) {
    return showModalBottomSheet<T>(
      context: context,
      builder: (_) => AppActionSheet(title: title, actions: actions),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            ...actions.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: ListTile(
                    leading: Icon(a.icon, color: AppColors.brand),
                    title: Text(a.label),
                    subtitle: a.subtitle != null ? Text(a.subtitle!) : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      a.onTap();
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class AppSheetAction {
  const AppSheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
}
