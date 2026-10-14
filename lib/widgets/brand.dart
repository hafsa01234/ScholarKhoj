import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Green rounded square with the scholarship hat.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 52});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: AppColors.forest.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(Icons.school_rounded, color: Colors.white, size: size * 0.58),
    );
  }
}

/// "Scholar" in dark green + "Khoj" in bright green.
class BrandName extends StatelessWidget {
  const BrandName({super.key, this.size = 26});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      const TextSpan(
        children: [
          TextSpan(text: 'Scholar', style: TextStyle(color: AppColors.forest)),
          TextSpan(text: 'Khoj', style: TextStyle(color: AppColors.accent)),
        ],
      ),
      style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, letterSpacing: -0.5),
    );
  }
}

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [BrandMark(size: 46), SizedBox(width: 10), BrandName(size: 26)],
        ),
        SizedBox(height: 6),
        Text(
          'Tomar Shopner Scholarship',
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
      ],
    );
  }
}
