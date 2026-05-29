import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/design_tokens.dart';
import '../../shared/api_service.dart';
import '../../shared/widgets/feedback.dart';
import 'manager_home.dart';

class ProjectFormScreen extends ConsumerStatefulWidget {
  const ProjectFormScreen({super.key});

  @override
  ConsumerState<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends ConsumerState<ProjectFormScreen> {
  final _name = TextEditingController();
  final _location = TextEditingController();
  final _purpose = TextEditingController();
  final _clientName = TextEditingController();
  final _clientEmail = TextEditingController();
  final _clientPhone = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _purpose.dispose();
    _clientName.dispose();
    _clientEmail.dispose();
    _clientPhone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Project name is required');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiServiceProvider);
      int? clientId;
      if (_clientName.text.trim().isNotEmpty) {
        final client = await api.createClient({
          'full_name': _clientName.text.trim(),
          'email': _clientEmail.text.trim().isEmpty ? null : _clientEmail.text.trim(),
          'phone_number': _clientPhone.text.trim().isEmpty ? null : _clientPhone.text.trim(),
        });
        clientId = client.clientId;
      }
      await api.createProject({
        'project_name': _name.text.trim(),
        'location': _location.text.trim().isEmpty ? null : _location.text.trim(),
        'valuation_purpose': _purpose.text.trim().isEmpty ? null : _purpose.text.trim(),
        'client_id': clientId,
      });
      ref.invalidate(projectsProvider);
      if (mounted) context.pop();
    } on DioException catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('New valuation project')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FormSection(
                  title: 'Property & purpose',
                  children: [
                    TextField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'Project name *',
                        hintText: 'e.g. Bole residential valuation',
                      ),
                    ),
                    TextField(
                      controller: _location,
                      decoration: const InputDecoration(labelText: 'Location'),
                    ),
                    TextField(
                      controller: _purpose,
                      decoration: const InputDecoration(
                        labelText: 'Valuation purpose',
                        hintText: 'Loan security, insurance, sale…',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                FormSection(
                  title: 'Client (optional)',
                  children: [
                    TextField(controller: _clientName, decoration: const InputDecoration(labelText: 'Client name')),
                    TextField(
                      controller: _clientEmail,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    TextField(controller: _clientPhone, decoration: const InputDecoration(labelText: 'Phone')),
                  ],
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
                      : const Text('Create project'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
