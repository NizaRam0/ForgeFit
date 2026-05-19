import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
// ignore: unused_import
import '../utils/app_theme.dart';
import 'dashboard_screen.dart';
import 'exercise_library_screen.dart';
import 'workout_plans_screen.dart';
import 'progress_screen.dart';
import 'ai_coach_screen.dart';
import 'active_workout_screen.dart';
// edit profile screen is navigated from other places when needed

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    WorkoutPlansScreen(),
    ExerciseLibraryScreen(),
    ProgressScreen(),
    AiCoachScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (ctx, workoutProvider, _) {
        // If there's an active workout, show it
        if (workoutProvider.hasActiveWorkout) {
          return const ActiveWorkoutScreen();
        }

        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          bottomNavigationBar: _buildBottomNav(),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center_outlined),
              activeIcon: Icon(Icons.fitness_center),
              label: 'Workouts'),
          BottomNavigationBarItem(
              icon: Icon(Icons.library_books_outlined),
              activeIcon: Icon(Icons.library_books),
              label: 'Exercises'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Progress'),
          BottomNavigationBarItem(
              icon: Icon(Icons.smart_toy_outlined),
              activeIcon: Icon(Icons.smart_toy),
              label: 'AI Coach'),
        ],
      ),
    );
  }
}
