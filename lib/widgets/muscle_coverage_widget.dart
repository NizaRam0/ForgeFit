import 'package:flutter/material.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';

class MuscleCoverageWidget extends StatelessWidget {
  final List<String> muscles;

  const MuscleCoverageWidget({
    super.key,
    required this.muscles,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Muscle Coverage",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: muscles.map((m) {
              final muscleColor =
                  Color(MuscleGroupColors.colors[m] ?? AppTheme.primary.value);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: muscleColor.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  m,
                  style: TextStyle(
                    color: muscleColor,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }
}
