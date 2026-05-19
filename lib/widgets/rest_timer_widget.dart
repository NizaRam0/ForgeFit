import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../providers/timer_provider.dart';

class RestTimerWidget extends StatelessWidget {
  final int durationSeconds;

  const RestTimerWidget({super.key, this.durationSeconds = 90});

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerProvider>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: CircularProgressIndicator(
                  value: timer.state == TimerState.idle
                      ? 1
                      : timer.progress.clamp(0, 1),
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timer.formattedTime,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (timer.state == TimerState.finished) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Rest Complete!',
                      style: TextStyle(
                        color: AppTheme.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => timer.startTimer(durationSeconds),
                icon: const Icon(Icons.play_arrow, color: AppTheme.success),
              ),
              IconButton(
                onPressed: timer.pauseTimer,
                icon: const Icon(Icons.pause, color: AppTheme.warning),
              ),
              IconButton(
                onPressed: timer.resetTimer,
                icon: const Icon(Icons.refresh, color: AppTheme.error),
              ),
              IconButton(
                onPressed: () => timer.addSeconds(15),
                icon: const Icon(Icons.add, color: AppTheme.accent),
              ),
              IconButton(
                onPressed: timer.remainingSeconds > 15
                    ? () => timer.addSeconds(-15)
                    : null,
                icon: const Icon(Icons.remove, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
