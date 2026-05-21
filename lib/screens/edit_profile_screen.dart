import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_profile.dart';
import '../providers/user_provider.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  bool _didPrefillFromUser = false;

  String _gender = AppConstants.genders.first;
  String _goal = AppConstants.goals.first;
  String _fitnessLevel = AppConstants.difficulties.first;
  int _workoutsPerWeek = 3;
  List<String> _equipment = [];
  bool _isSaving = false;

  final List<String> _allEquipment = const [
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
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didPrefillFromUser) return;

    final user = context.read<UserProvider>().user;
    if (user == null) return;

    _prefillFromUser(user);
    _didPrefillFromUser = true;
  }

  void _prefillFromUser(UserProfile user) {
    _nicknameController.text = user.nickname;
    _ageController.text = user.age.toString();
    _weightController.text = user.weightKg.toStringAsFixed(1);
    _heightController.text = user.heightCm.toStringAsFixed(0);
    _gender = user.gender.isNotEmpty ? user.gender : _gender;
    _goal = user.goal.isNotEmpty ? user.goal : _goal;
    _fitnessLevel =
        user.fitnessLevel.isNotEmpty ? user.fitnessLevel : _fitnessLevel;
    _workoutsPerWeek = user.workoutsPerWeek;
    _equipment = List.from(user.availableEquipment);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  bool get _hasMinimumEquipment => _equipment.isNotEmpty;

  double get _completionScore {
    final filledFields = [
      _nicknameController.text.trim().isNotEmpty,
      int.tryParse(_ageController.text) != null,
      double.tryParse(_weightController.text) != null,
      double.tryParse(_heightController.text) != null,
      _gender.isNotEmpty,
      _goal.isNotEmpty,
      _fitnessLevel.isNotEmpty,
      _workoutsPerWeek > 0,
      _equipment.isNotEmpty,
    ].where((filled) => filled).length;

    return filledFields / 9;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_hasMinimumEquipment) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one equipment type.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final existingUser = context.read<UserProvider>().user;
    final profile = (existingUser ?? _buildFallbackProfile()).copyWith(
      nickname: _nicknameController.text.trim().isNotEmpty
          ? _nicknameController.text.trim()
          : (existingUser?.nickname.isNotEmpty == true
              ? existingUser!.nickname
              : 'Athlete'),
      age: int.tryParse(_ageController.text) ?? existingUser?.age ?? 25,
      weightKg: double.tryParse(_weightController.text) ??
          existingUser?.weightKg ??
          75,
      heightCm: double.tryParse(_heightController.text) ??
          existingUser?.heightCm ??
          175,
      gender: _gender.isNotEmpty
          ? _gender
          : (existingUser?.gender.isNotEmpty == true
              ? existingUser!.gender
              : AppConstants.genders.first),
      goal: _goal.isNotEmpty ? _goal : (existingUser?.goal ?? _goal),
      fitnessLevel: _fitnessLevel.isNotEmpty
          ? _fitnessLevel
          : (existingUser?.fitnessLevel ?? AppConstants.difficulties.first),
      availableEquipment: _equipment.isNotEmpty
          ? _equipment
          : (existingUser?.availableEquipment ?? const <String>[]),
      workoutsPerWeek: _workoutsPerWeek > 0
          ? _workoutsPerWeek
          : (existingUser?.workoutsPerWeek ?? 3),
      profileComplete: true,
    );

    setState(() => _isSaving = true);
    try {
      final saved = await context.read<UserProvider>().updateUser(profile);
      if (!mounted) return;
      if (saved) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile could not be saved. Please try again.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  UserProfile _buildFallbackProfile() {
    return UserProfile(
      nickname: 'Athlete',
      age: 25,
      weightKg: 75,
      heightCm: 175,
      goal: AppConstants.goals.first,
      fitnessLevel: AppConstants.difficulties.first,
      availableEquipment: const <String>[],
      workoutsPerWeek: 3,
      profileComplete: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    if (!_didPrefillFromUser && user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _didPrefillFromUser) return;
        _prefillFromUser(user);
        setState(() => _didPrefillFromUser = true);
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppTheme.bg(context),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check, size: 18),
            label: const Text('Save'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          const Positioned(
            top: -70,
            right: -50,
            child: _GlowBlob(color: AppTheme.primary, size: 180),
          ),
          const Positioned(
            bottom: 120,
            left: -80,
            child: _GlowBlob(color: AppTheme.accent, size: 220),
          ),
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _HeroCard(
                    completion: _completionScore,
                    userName: _nicknameController.text),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Display',
                  subtitle: 'How your profile appears across the app',
                  child: TextFormField(
                    controller: _nicknameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Display name',
                      hintText: 'Athlete',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Enter a display name';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Body metrics',
                  subtitle: 'The numbers used by your training analytics',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _MetricField(
                              controller: _ageController,
                              label: 'Age',
                              icon: Icons.cake_outlined,
                              suffix: 'yrs',
                              onChanged: (_) => setState(() {}),
                              validator: (value) {
                                final age = int.tryParse((value ?? '').trim());
                                if (age == null || age < 10 || age > 100) {
                                  return '10 - 100';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricField(
                              controller: _weightController,
                              label: 'Weight',
                              icon: Icons.monitor_weight_outlined,
                              suffix: 'kg',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              onChanged: (_) => setState(() {}),
                              validator: (value) {
                                final parsed =
                                    double.tryParse((value ?? '').trim());
                                if (parsed == null ||
                                    parsed < 20 ||
                                    parsed > 300) {
                                  return '20 - 300';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _MetricField(
                        controller: _heightController,
                        label: 'Height',
                        icon: Icons.height_outlined,
                        suffix: 'cm',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (_) => setState(() {}),
                        validator: (value) {
                          final parsed = double.tryParse((value ?? '').trim());
                          if (parsed == null || parsed < 100 || parsed > 250) {
                            return '100 - 250';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Gender',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: AppTheme.onText(context),
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 10),
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
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Training goal',
                  subtitle: 'Select the primary outcome you want to chase',
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: AppConstants.goals.map((goal) {
                      final selected = _goal == goal;
                      return ChoiceChip(
                        label: Text(goal),
                        selected: selected,
                        onSelected: (_) => setState(() => _goal = goal),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Fitness level',
                  subtitle: 'Used to tune AI plans and recommendations',
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: AppConstants.difficulties.map((level) {
                      final selected = _fitnessLevel == level;
                      return ChoiceChip(
                        label: Text(level),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _fitnessLevel = level),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Weekly cadence',
                  subtitle: 'How many sessions you want the app to plan for',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Workouts per week',
                            style: TextStyle(
                              color: AppTheme.onSubtext(context),
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '$_workoutsPerWeek',
                            style: TextStyle(
                              color: AppTheme.onText(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: _workoutsPerWeek.toDouble(),
                        min: 1,
                        max: 6,
                        divisions: 5,
                        activeColor: AppTheme.primary,
                        label: '$_workoutsPerWeek',
                        onChanged: (value) {
                          setState(() => _workoutsPerWeek = value.round());
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Available equipment',
                  subtitle: 'Used to filter exercises and AI generated plans',
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _allEquipment.map((item) {
                      final selected = _equipment.contains(item);
                      return FilterChip(
                        label: Text(item),
                        selected: selected,
                        onSelected: (isSelected) {
                          setState(() {
                            if (isSelected) {
                              _equipment.add(item);
                            } else {
                              _equipment.remove(item);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_isSaving ? 'Saving...' : 'Save changes'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final double completion;
  final String userName;

  const _HeroCard({required this.completion, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: CircularProgressIndicator(
                  value: completion.clamp(0.0, 1.0),
                  strokeWidth: 6,
                  backgroundColor: AppTheme.elevated(context),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withOpacity(0.14),
                ),
                child: const Icon(
                  Icons.person,
                  color: AppTheme.primary,
                  size: 30,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName.isEmpty ? 'Athlete' : userName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onText(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(completion * 100).round()}% profile complete',
                  style: TextStyle(color: AppTheme.onSubtext(context)),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: completion.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: AppTheme.elevated(context),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.onText(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.onSubtext(context),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _MetricField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String suffix;
  final String? Function(String?) validator;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;

  const _MetricField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.suffix,
    required this.validator,
    this.keyboardType = TextInputType.number,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixText: suffix,
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withOpacity(0.22),
              color.withOpacity(0.08),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}
