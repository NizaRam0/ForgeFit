import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'providers/workout_provider.dart';
import 'providers/exercise_provider.dart';
import 'providers/user_provider.dart';
import 'providers/timer_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth_screen.dart';
import 'utils/app_theme.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await ApiService.instance.loadToken();
  ApiService.instance.warmUp(); // wake server from hibernation, fire-and-forget
  runApp(const ForgeFitApp());
}

class ForgeFitApp extends StatelessWidget {
  const ForgeFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()..loadUser()),
        ChangeNotifierProvider(
            create: (_) => ExerciseProvider()..loadExercises()),
        ChangeNotifierProvider(
            create: (_) => WorkoutProvider()..loadWorkouts()),
        ChangeNotifierProvider(create: (_) => TimerProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'ForgeFit',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AppEntry(),
            routes: {
              '/home': (ctx) => const HomeScreen(),
              '/onboarding': (ctx) => const OnboardingScreen(),
              '/auth': (ctx) => const AuthScreen(),
            },
          );
        },
      ),
    );
  }
}

/// Decides routing: AuthScreen (no token) -> HomeScreen (token)
class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool _isCheckingAuth = true;
  bool _hasToken = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final token = await ApiService.instance.getToken();
    setState(() {
      _hasToken = token != null && token.isNotEmpty;
      _isCheckingAuth = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasToken) {
      return const AuthScreen();
    }

    return Consumer<UserProvider>(
      builder: (ctx, userProvider, _) {
        if (userProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Token was stale (backend returned 401 and cleared it) — send to auth
        if (userProvider.user == null) {
          return const AuthScreen();
        }

        if (!userProvider.isSetup) {
          return const OnboardingScreen();
        }

        return const HomeScreen();
      },
    );
  }
}
