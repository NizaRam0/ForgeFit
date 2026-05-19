import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // Muscle groups
  static const List<String> muscleGroups = [
    'Chest',
    'Back',
    'Shoulders',
    'Biceps',
    'Triceps',
    'Legs',
    'Glutes',
    'Core',
    'Calves',
    'Full Body',
  ];

  // Difficulty levels
  static const List<String> difficulties = [
    'Beginner',
    'Intermediate',
    'Advanced'
  ];

  // Gender options
  static const List<String> genders = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];

  // Goals
  static const List<String> goals = [
    'Build Muscle',
    'Lose Weight',
    'Increase Strength',
    'Improve Endurance',
    'General Fitness',
  ];

  // Default rest times (seconds)
  static const Map<String, int> defaultRestTimes = {
    'Strength': 180,
    'Hypertrophy': 90,
    'Endurance': 45,
  };

  // Wrist-side muscle emoji map
  static const Map<String, String> muscleEmoji = {
    'Chest': '💪',
    'Back': '🏋️',
    'Shoulders': '🔝',
    'Biceps': '💪',
    'Triceps': '🔱',
    'Legs': '🦵',
    'Glutes': '🍑',
    'Core': '⚡',
    'Calves': '🦴',
    'Full Body': '🔥',
  };

  // Progressive overload suggestion thresholds
  static const double overloadThresholdPercent = 0.025; // 2.5% increase
  static const int overloadMinSessions = 3; // needs 3 sessions at same weight

  // Anthropic API — key loaded from .env file at startup via flutter_dotenv
  static const String anthropicBaseUrl = 'https://api.anthropic.com/v1';
  static String get anthropicApiKey =>
      dotenv.env['ANTHROPIC_API_KEY'] ?? '';
}

class MuscleGroupColors {
  static const Map<String, int> colors = {
    'Chest': 0xFFFF6B35,
    'Back': 0xFF00D4AA,
    'Shoulders': 0xFFFFB74D,
    'Biceps': 0xFF7C4DFF,
    'Triceps': 0xFF26C6DA,
    'Legs': 0xFFEC407A,
    'Glutes': 0xFFFF7043,
    'Core': 0xFF66BB6A,
    'Calves': 0xFFFFA726,
    'Full Body': 0xFF42A5F5,
  };
}
