import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../providers/workout_provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final workoutProvider = context.watch<WorkoutProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final totalVolume = workoutProvider.logs
        .fold<double>(0, (sum, log) => sum + log.totalVolume);

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppTheme.bg(context),
        actions: [
          IconButton(
            tooltip: 'Edit profile',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EditProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.card(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: AppTheme.primary.withOpacity(0.15),
                    child: const Icon(
                      Icons.person,
                      size: 42,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.nickname.isNotEmpty == true ? user!.nickname : 'Athlete',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onText(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email.isNotEmpty == true
                        ? user!.email
                        : 'No email available',
                    style: TextStyle(color: AppTheme.onSubtext(context)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _InfoCard(
              children: [
                _InfoRow(label: 'Nickname', value: user?.nickname ?? 'Athlete'),
                _InfoRow(
                    label: 'Email',
                    value: user?.email.isNotEmpty == true
                        ? user!.email
                        : 'Not set'),
                _InfoRow(
                    label: 'Gender',
                    value: user?.gender.isNotEmpty == true
                        ? user!.gender
                        : 'Not set'),
                _InfoRow(
                    label: 'Age',
                    value: user != null ? '${user.age}' : 'Not set'),
                _InfoRow(
                    label: 'Weight',
                    value: user != null
                        ? '${user.weightKg.toStringAsFixed(1)} kg'
                        : 'Not set'),
                _InfoRow(
                    label: 'Height',
                    value: user != null
                        ? '${user.heightCm.toStringAsFixed(0)} cm'
                        : 'Not set'),
                _InfoRow(
                    label: 'Goal',
                    value: user?.goal.isNotEmpty == true
                        ? user!.goal
                        : 'Not set'),
                _InfoRow(
                    label: 'Fitness level',
                    value: user?.fitnessLevel.isNotEmpty == true
                        ? user!.fitnessLevel
                        : 'Not set'),
              ],
            ),
            const SizedBox(height: 16),
            // Theme toggle card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.card(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: Row(
                children: [
                  Icon(
                    themeProvider.isDark
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    themeProvider.isDark ? 'Dark Mode' : 'Light Mode',
                    style: TextStyle(
                      color: AppTheme.onText(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: !themeProvider.isDark,
                    onChanged: (_) => themeProvider.toggleTheme(),
                    activeColor: AppTheme.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _InfoCard(
              children: [
                Text(
                  'Total Training Volume',
                  style: TextStyle(
                    color: AppTheme.onSubtext(context),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  totalVolume.toStringAsFixed(0),
                  style: TextStyle(
                    color: AppTheme.onText(context),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Since your first recorded session',
                  style: TextStyle(color: AppTheme.onSubtext(context)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Log Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {
                  await AuthService.instance.logout();
                  if (!context.mounted) return;
                  await context.read<UserProvider>().clearUser();
                  if (!context.mounted) return;
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/auth',
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [...children],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.onSubtext(context),
              fontSize: 13,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppTheme.onText(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
