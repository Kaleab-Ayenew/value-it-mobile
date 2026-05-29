import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/design_tokens.dart';
import '../../shared/widgets/brand_logo.dart';
import '../../shared/widgets/feedback.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController(text: 'manager@valueit.com');
  final _password = TextEditingController(text: 'manager123');
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).login(_email.text.trim(), _password.text);
      if (!mounted) return;
      final user = ref.read(authProvider).value;
      context.go(homeRouteFor(user));
    } on DioException catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;

    return Scaffold(
      body: wide ? _wideLayout(context) : _narrowLayout(context),
    );
  }

  Widget _narrowLayout(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.xl),
                const BrandLogo(),
                const SizedBox(height: AppSpacing.xxl),
                _loginCard(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _wideLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            color: AppColors.brandDark,
            padding: const EdgeInsets.all(48),
            child: SingleChildScrollView(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const BrandLogo(light: true),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Cost-based valuation,\nstructured end to end.',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        height: 1.25,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Coordinate inspections, material pricing, and reports in one workflow built for valuers and field teams.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.72),
                        height: 1.5,
                      ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _featureRow(Icons.assignment_outlined, 'Project & client tracking'),
                _featureRow(Icons.photo_camera_outlined, 'Site inspection capture'),
                _featureRow(Icons.analytics_outlined, 'Standardized valuation reports'),
              ],
            ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _loginCard(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _featureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accentLight, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Sign in', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('Access your valuation workspace', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'Work email',
                prefixIcon: Icon(Icons.mail_outline, size: 20),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _password,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              obscureText: _obscure,
              onSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              InlineErrorBanner(message: _error!),
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Sign in'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => context.push('/register'),
              child: const Text('Request an account'),
            ),
          ],
        ),
      ),
    );
  }
}
