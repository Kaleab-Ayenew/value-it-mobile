import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.compact = false, this.light = false});

  final bool compact;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final fg = light ? Colors.white : AppColors.ink;
    final accent = light ? AppColors.accentLight : AppColors.accent;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 36 : 44,
          height: compact ? 36 : 44,
          decoration: BoxDecoration(
            color: light ? Colors.white.withValues(alpha: 0.12) : AppColors.brandLight,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(
              color: light ? Colors.white.withValues(alpha: 0.2) : AppColors.brand.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(
            Icons.account_balance_outlined,
            size: compact ? 20 : 24,
            color: light ? Colors.white : AppColors.brand,
          ),
        ),
        SizedBox(width: compact ? AppSpacing.sm : AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ValueIt',
              style: TextStyle(
                fontSize: compact ? 18 : 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: fg,
                height: 1.1,
              ),
            ),
            if (!compact)
              Text(
                'Property valuation',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                  color: light ? Colors.white.withValues(alpha: 0.65) : accent,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
