import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/brand.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7FCFA), Color(0xFFE3F4EC)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, child) => Opacity(
                      opacity: v,
                      child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: child),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BrandMark(size: 88),
                        SizedBox(height: 22),
                        BrandName(size: 34),
                        SizedBox(height: 8),
                        Text(
                          'Your Future, Your Scholarship',
                          style: TextStyle(fontSize: 14, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 32),
                child: Text(
                  'Find opportunities. Build your future.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}