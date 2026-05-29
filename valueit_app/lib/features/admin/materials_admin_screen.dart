import 'package:dio/dio.dart' show DioException, MultipartFile;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api_client.dart';
import '../../core/design_tokens.dart';
import '../../shared/api_service.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/feedback.dart';
import '../valuation/materials_screen.dart';

class MaterialsAdminScreen extends ConsumerWidget {
  const MaterialsAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(materialsProvider);
    final currency = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);

    return async.when(
      loading: () => const LoadingState(),
      error: (e, _) => ErrorState(
        message: e is DioException ? apiErrorMessage(e) : '$e',
        onRetry: () => ref.invalidate(materialsProvider),
      ),
      data: (materials) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                FilledButton.icon(
                  onPressed: () => _addMaterial(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () => _importCsv(context, ref),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Import CSV'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: materials.length,
              itemBuilder: (_, i) {
                final m = materials[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.materialName, style: Theme.of(context).textTheme.titleMedium),
                              Text('Per ${m.unit}', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        Text(currency.format(m.unitPrice)),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await ref.read(apiServiceProvider).deleteMaterial(m.materialId);
                            ref.invalidate(materialsProvider);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addMaterial(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final unit = TextEditingController(text: 'm²');
    final price = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New material'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: unit, decoration: const InputDecoration(labelText: 'Unit')),
            TextField(controller: price, decoration: const InputDecoration(labelText: 'Unit price'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(apiServiceProvider).createMaterial({
      'material_name': name.text.trim(),
      'unit': unit.text.trim(),
      'unit_price': double.tryParse(price.text) ?? 0,
    });
    ref.invalidate(materialsProvider);
  }

  Future<void> _importCsv(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (result == null || result.files.single.path == null) return;
    final file = await MultipartFile.fromFile(result.files.single.path!, filename: result.files.single.name);
    try {
      final n = await ref.read(apiServiceProvider).importMaterialsCsv(file);
      ref.invalidate(materialsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported $n rows')));
      }
    } on DioException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      }
    }
  }
}
