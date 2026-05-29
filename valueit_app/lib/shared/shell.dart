import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design_tokens.dart';
import '../core/responsive.dart';
import '../features/auth/auth_provider.dart';
import 'widgets/brand_logo.dart';

class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final String subtitle;
  final Widget body;
  final List<NavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = ResponsiveLayout.isWide(context);
    final user = ref.watch(authProvider).valueOrNull;

    if (!wide) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          actions: [
            ...?actions,
            _UserMenu(userName: user?.fullName),
          ],
        ),
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onSelect,
          destinations: destinations,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Row(
        children: [
          _BrandedRail(
            destinations: destinations,
            selectedIndex: selectedIndex,
            onSelect: onSelect,
            userName: user?.fullName,
            role: user?.role,
            onLogout: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DesktopHeader(
                  title: title,
                  subtitle: subtitle,
                  actions: actions,
                  onLogout: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}

class _BrandedRail extends StatelessWidget {
  const _BrandedRail({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
    required this.onLogout,
    this.userName,
    this.role,
  });

  final List<NavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;
  final String? userName;
  final String? role;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: AppColors.brandDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: BrandLogo(light: true, compact: true),
          ),
          const Divider(color: Colors.white12, height: 1, indent: 16, endIndent: 16),
          const SizedBox(height: 8),
          Expanded(
            child: NavigationRail(
              extended: true,
              minExtendedWidth: 220,
              backgroundColor: Colors.transparent,
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelect,
              labelType: NavigationRailLabelType.none,
              destinations: destinations
                  .map(
                    (d) => NavigationRailDestination(
                      icon: d.icon,
                      label: Text(d.label),
                    ),
                  )
                  .toList(),
            ),
          ),
          if (userName != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName!,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (role != null)
                    Text(
                      role!,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextButton.icon(
              onPressed: onLogout,
              icon: Icon(Icons.logout, size: 18, color: Colors.white.withValues(alpha: 0.8)),
              label: Text('Sign out', style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader({
    required this.title,
    required this.subtitle,
    required this.onLogout,
    this.actions,
  });

  final String title;
  final String subtitle;
  final VoidCallback onLogout;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          ...?actions,
          IconButton(
            tooltip: 'Sign out',
            onPressed: onLogout,
            icon: const Icon(Icons.logout_outlined),
          ),
        ],
      ),
    );
  }
}

class _UserMenu extends StatelessWidget {
  const _UserMenu({this.userName});

  final String? userName;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<void>(
      icon: CircleAvatar(
        backgroundColor: AppColors.brandLight,
        child: Text(
          (userName?.isNotEmpty == true) ? userName![0].toUpperCase() : '?',
          style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w600),
        ),
      ),
      itemBuilder: (_) => [
        if (userName != null)
          PopupMenuItem(
            enabled: false,
            child: Text(userName!, style: Theme.of(context).textTheme.titleSmall),
          ),
      ],
    );
  }
}
