import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api_client.dart';
import '../../core/design_tokens.dart';
import '../../shared/api_service.dart';
import '../../shared/models.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/feedback.dart';

final materialsProvider = FutureProvider.autoDispose<List<MaterialModel>>((ref) {
  return ref.watch(apiServiceProvider).materials();
});

class MaterialsScreen extends ConsumerWidget {
  const MaterialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(materialsProvider);
    final currency = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);

    return async.when(
      loading: () => const LoadingState(message: 'Loading price list…'),
      error: (e, _) => ErrorState(
        message: e is DioException ? apiErrorMessage(e) : '$e',
        onRetry: () => ref.invalidate(materialsProvider),
      ),
      data: (materials) => ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
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
                  Text(
                    currency.format(m.unitPrice),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.brand,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
