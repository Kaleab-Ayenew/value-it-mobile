import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, this.tone = ProjectStatusTone.neutral});

  final String label;
  final ProjectStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (tone) {
      ProjectStatusTone.pending => (AppColors.warningBg, AppColors.warning, Icons.schedule),
      ProjectStatusTone.inProgress => (AppColors.infoBg, AppColors.info, Icons.sync),
      ProjectStatusTone.completed => (AppColors.successBg, AppColors.success, Icons.check_circle_outline),
      ProjectStatusTone.neutral => (AppColors.canvas, AppColors.inkMuted, Icons.circle_outlined),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
