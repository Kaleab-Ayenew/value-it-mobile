import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api_client.dart';
import '../../core/design_tokens.dart';
import '../../features/auth/auth_provider.dart';
import '../../shared/api_service.dart';
import '../../shared/models.dart';
import '../../shared/widgets/feedback.dart';

final _chatProvider = FutureProvider.autoDispose.family<List<ChatMessageModel>, int>((ref, id) {
  return ref.watch(apiServiceProvider).chatMessages(id);
});

class ProjectChatScreen extends ConsumerStatefulWidget {
  const ProjectChatScreen({super.key, required this.projectId});

  final int projectId;

  @override
  ConsumerState<ProjectChatScreen> createState() => _ProjectChatScreenState();
}

class _ProjectChatScreenState extends ConsumerState<ProjectChatScreen> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(apiServiceProvider).sendChatMessage(widget.projectId, text);
      _controller.clear();
      ref.invalidate(_chatProvider(widget.projectId));
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_chatProvider(widget.projectId));
    final me = ref.watch(authProvider).valueOrNull?.userId;
    final fmt = DateFormat.Hm();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Project chat')),
      body: Column(
        children: [
          Expanded(
            child: async.when(
              loading: () => const LoadingState(),
              error: (e, _) => ErrorState(message: '$e'),
              data: (msgs) => ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: msgs.length,
                itemBuilder: (_, i) {
                  final m = msgs[i];
                  final mine = m.senderId == me;
                  return Align(
                    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
                      decoration: BoxDecoration(
                        color: mine ? AppColors.brandLight : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.senderName, style: Theme.of(context).textTheme.labelSmall),
                          Text(m.messageContent),
                          Text(fmt.format(m.sentAt), style: Theme.of(context).textTheme.labelSmall),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'Message…', isDense: true),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
