import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/user_provider.dart';
import '../providers/workout_provider.dart';
import 'profile_screen.dart';

import '../utils/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/recent_workout_card.dart';
import '../widgets/muscle_coverage_widget.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final workoutProvider = context.watch<WorkoutProvider>();

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            actions: [
              IconButton(
                tooltip: 'Profile',
                icon: const Icon(Icons.person_outline),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileScreen(),
                    ),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting, ${user?.name ?? 'Athlete'} 👊',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    DateFormat('EEEE, MMMM d').format(DateTime.now()),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.onSubtext(context),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // QUICK STATS
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'This Week',
                        value: '${workoutProvider.workoutsThisWeek}',
                        icon: Icons.calendar_today,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        title: 'Streak',
                        value: '${workoutProvider.currentStreak}',
                        icon: Icons.local_fire_department,
                        color: AppTheme.warning,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        title: 'Volume',
                        value: _formatVolume(workoutProvider.volumeThisWeek),
                        icon: Icons.trending_up,
                        color: AppTheme.accent,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // MUSCLE COVERAGE
                const Text(
                  'Weekly Coverage',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),

                MuscleCoverageWidget(
                  muscles: workoutProvider.recentMuscles(),
                ),

                const SizedBox(height: 20),

                // RECENT WORKOUTS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Workouts',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    if (workoutProvider.logs.isNotEmpty)
                      Text(
                        '${workoutProvider.logs.length} total',
                        style: TextStyle(
                          color: AppTheme.onSubtext(context),
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                if (workoutProvider.logs.isEmpty)
                  _buildEmptyState(context)
                else
                  ...workoutProvider.logs.take(3).map(
                        (log) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: RecentWorkoutCard(
                            title: log.templateName,
                            subtitle:
                                DateFormat('yyyy-MM-dd').format(log.date),
                            time: '${log.duration.inMinutes} min',
                          ),
                        ),
                      ),

                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _formatVolume(double vol) {
    if (vol >= 1000) return '${(vol / 1000).toStringAsFixed(1)}k';
    return vol.toStringAsFixed(0);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        children: [
          const Icon(Icons.fitness_center, size: 48, color: AppTheme.primary),
          const SizedBox(height: 16),
          const Text(
            'No workouts yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Head to the Workouts tab to start your first session!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.onSubtext(context)),
          ),
        ],
      ),
    );
  }
}
