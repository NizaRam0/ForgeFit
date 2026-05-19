import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../providers/user_provider.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Form data
  final _nameController = TextEditingController();
  // Use nickname field name kept for legacy, but treated as display name
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  String _gender = AppConstants.genders.first;
  String _goal = AppConstants.goals.first;
  String _fitnessLevel = 'Beginner';
  int _workoutsPerWeek = 3;
  final List<String> _equipment = ['Barbell', 'Dumbbells'];

  final List<String> _allEquipment = [
    'Barbell',
    'Dumbbells',
    'Pull-Up Bar',
    'Cable Machine',
    'Machine',
    'Dip Bar',
    'Leg Press Machine',
    'Bodyweight',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Prefill with server profile if present
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>().user;
      if (user != null) {
        _nameController.text = user.nickname;
        _ageController.text = user.age.toString();
        _weightController.text = user.weightKg.toString();
        _heightController.text = user.heightCm.toString();
        _gender = user.gender.isNotEmpty ? user.gender : _gender;
        _goal = user.goal;
        _fitnessLevel = user.fitnessLevel;
        _workoutsPerWeek = user.workoutsPerWeek;
        _equipment.clear();
        _equipment.addAll(user.availableEquipment);
      }
    });
  }

  void _nextPage() {
    if (!_validateCurrentPage()) {
      return;
    }

    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _saveAndContinue();
    }
  }

  bool _validateCurrentPage() {
    final messenger = ScaffoldMessenger.of(context);

    switch (_currentPage) {
      case 0:
        // If user already has a nickname from registration, allow empty here
        final existing = context.read<UserProvider>().user;
        if (existing != null && existing.nickname.isNotEmpty) return true;
        if (_nameController.text.trim().isEmpty) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Please enter a display name to continue.'),
              backgroundColor: AppTheme.error,
            ),
          );
          return false;
        }
        return true;
      case 1:
        final invalidFields = <String>[];

        final age = int.tryParse(_ageController.text);
        if (age == null || age < 10 || age > 100) {
          invalidFields.add('Age');
        }

        final weight = double.tryParse(_weightController.text);
        if (weight == null || weight < 20 || weight > 300) {
          invalidFields.add('Weight');
        }

        final height = double.tryParse(_heightController.text);
        if (height == null || height < 100 || height > 250) {
          invalidFields.add('Height');
        }

        if (_fitnessLevel.trim().isEmpty) {
          invalidFields.add('Fitness level');
        }

        if (invalidFields.isNotEmpty) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Please check: ${invalidFields.join(', ')}.'),
              backgroundColor: AppTheme.error,
            ),
          );
          return false;
        }
        return true;
      case 2:
        return true;
      case 3:
        if (_equipment.isEmpty) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Please select at least one equipment type.'),
              backgroundColor: AppTheme.error,
            ),
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _saveAndContinue() async {
    final profile = UserProfile(
      nickname: _nameController.text.trim().isEmpty
          ? 'Athlete'
          : _nameController.text.trim(),
      age: int.tryParse(_ageController.text) ?? 25,
      weightKg: double.tryParse(_weightController.text) ?? 75,
      heightCm: double.tryParse(_heightController.text) ?? 175,
      gender: _gender,
      goal: _goal,
      fitnessLevel: _fitnessLevel,
      availableEquipment: _equipment,
      workoutsPerWeek: _workoutsPerWeek,
    );

    final saved = await context.read<UserProvider>().saveUser(profile);

    if (mounted && saved) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else if (mounted && !saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save onboarding info. Please try again.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildWelcomePage(),
                  _buildPersonalInfoPage(),
                  _buildGoalsPage(),
                  _buildEquipmentPage(),
                ],
              ),
            ),
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: List.generate(4, (i) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 4,
              decoration: BoxDecoration(
                color: i <= _currentPage
                    ? AppTheme.primary
                    : AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryDark],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child:
                const Icon(Icons.fitness_center, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 32),
          const Text(
            'ForgeFit',
            style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Your AI-powered strength coach.\nTrack lifts. Beat PRs. Build muscle.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 18,
                color: Colors.white.withOpacity(0.7),
                height: 1.5),
          ),
          const SizedBox(height: 48),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: "Display name (nickname)",
              prefixIcon: Icon(Icons.person_outline, color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Stats',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Help us personalize your program',
              style: TextStyle(color: Colors.white.withOpacity(0.6))),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                      labelText: 'Age',
                      prefixIcon:
                          Icon(Icons.cake_outlined, color: AppTheme.primary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                      labelText: 'Weight (kg)',
                      prefixIcon: Icon(Icons.monitor_weight_outlined,
                          color: AppTheme.primary)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _heightController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
                labelText: 'Height (cm)',
                prefixIcon: Icon(Icons.height, color: AppTheme.primary)),
          ),
          const SizedBox(height: 24),
          const Text('Gender',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.genders.map((gender) {
              final selected = _gender == gender;
              return ChoiceChip(
                label: Text(gender),
                selected: selected,
                onSelected: (_) => setState(() => _gender = gender),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          const Text('Fitness Level',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: AppConstants.difficulties.map((level) {
              final selected = _fitnessLevel == level;
              return GestureDetector(
                onTap: () => setState(() => _fitnessLevel = level),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        selected ? AppTheme.primary : AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? AppTheme.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Text(level,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppTheme.textSecondary,
                      )),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Goal',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('What are you training for?',
              style: TextStyle(color: Colors.white.withOpacity(0.6))),
          const SizedBox(height: 32),
          ...AppConstants.goals.map((goal) {
            final selected = _goal == goal;
            return GestureDetector(
              onTap: () => setState(() => _goal = goal),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primary.withOpacity(0.15)
                      : AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? AppTheme.primary
                        : Colors.white.withOpacity(0.1),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color:
                          selected ? AppTheme.primary : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Text(goal,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? AppTheme.primary
                              : AppTheme.textPrimary,
                        )),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          const Text('Workouts per week',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(6, (i) {
              final n = i + 1;
              final selected = _workoutsPerWeek == n;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _workoutsPerWeek = n),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 48,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primary
                          : AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                        child: Text('$n',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                            ))),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Equipment',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('What do you have access to?',
              style: TextStyle(color: Colors.white.withOpacity(0.6))),
          const SizedBox(height: 32),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _allEquipment.map((equip) {
              final selected = _equipment.contains(equip);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _equipment.remove(equip);
                    } else {
                      _equipment.add(equip);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primary.withOpacity(0.2)
                        : AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? AppTheme.primary
                          : Colors.white.withOpacity(0.1),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected) ...[
                        const Icon(Icons.check_circle,
                            size: 16, color: AppTheme.primary),
                        const SizedBox(width: 6),
                      ],
                      Text(equip,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? AppTheme.primary
                                : AppTheme.textSecondary,
                          )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.tips_and_updates_outlined,
                    color: AppTheme.accent, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You can always add more equipment later in settings.',
                    style: TextStyle(color: AppTheme.accent, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _nextPage,
          child: Text(_currentPage < 3 ? 'Continue' : "Let's Forge →"),
        ),
      ),
    );
  }
}
