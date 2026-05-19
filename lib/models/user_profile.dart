class UserProfile {
  final String nickname;
  final String email;
  final String gender;
  final int age;
  final double weightKg;
  final double heightCm;
  final String goal;
  final String fitnessLevel;
  final List<String> availableEquipment;
  final int workoutsPerWeek;
  final bool profileComplete;

  UserProfile({
    required this.nickname,
    this.email = '',
    this.gender = '',
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.goal,
    required this.fitnessLevel,
    required this.availableEquipment,
    required this.workoutsPerWeek,
    this.profileComplete = false,
  });

  String get name => nickname;

  Map<String, dynamic> toJson() => {
        'nickname': nickname,
        'email': email,
        'gender': gender,
        'age': age,
        'weightKg': weightKg,
        'heightCm': heightCm,
        'goal': goal,
        'fitnessLevel': fitnessLevel,
        'availableEquipment': availableEquipment.join(','),
        'workoutsPerWeek': workoutsPerWeek,
        'profile_complete': profileComplete,
      };

  Map<String, dynamic> toApiJson() => {
        'nickname': nickname,
        'age': age,
        'gender': gender,
        'weight_kg': weightKg,
        'height_cm': heightCm,
        'goal': goal,
        'fitness_level': fitnessLevel,
        'available_equipment': availableEquipment,
        'workouts_per_week': workoutsPerWeek,
        'profile_complete': true,
      };

  factory UserProfile.fromJson(Map<String, dynamic> m) => UserProfile(
        nickname: (m['nickname'] ?? m['name'] ?? 'Athlete').toString(),
        email: (m['email'] ?? '').toString(),
        gender: (m['gender'] ?? '').toString(),
        age: (m['age'] as num?)?.toInt() ?? 20,
        weightKg: (m['weight_kg'] ?? m['weightKg'] ?? 70).toDouble(),
        heightCm: (m['height_cm'] ?? m['heightCm'] ?? 170).toDouble(),
        goal: m['goal'] ?? 'Build Muscle',
        fitnessLevel:
            (m['fitness_level'] ?? m['fitnessLevel'] ?? 'Beginner').toString(),
        availableEquipment: _readEquipment(m),
        workoutsPerWeek:
            ((m['workouts_per_week'] ?? m['workoutsPerWeek']) as num?)
                    ?.toInt() ??
                3,
        profileComplete:
          m['profile_complete'] == true || m['profileComplete'] == true,
      );

  static List<String> _readEquipment(Map<String, dynamic> m) {
    final raw = m['available_equipment'] ?? m['availableEquipment'] ?? '';
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    if (raw is String) {
      return raw.split(',').where((s) => s.isNotEmpty).toList();
    }
    return const [];
  }

  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));

  UserProfile copyWith({
    String? nickname,
    String? email,
    String? gender,
    int? age,
    double? weightKg,
    double? heightCm,
    String? goal,
    String? fitnessLevel,
    List<String>? availableEquipment,
    int? workoutsPerWeek,
    bool? profileComplete,
  }) =>
      UserProfile(
        nickname: nickname ?? this.nickname,
        email: email ?? this.email,
        gender: gender ?? this.gender,
        age: age ?? this.age,
        weightKg: weightKg ?? this.weightKg,
        heightCm: heightCm ?? this.heightCm,
        goal: goal ?? this.goal,
        fitnessLevel: fitnessLevel ?? this.fitnessLevel,
        availableEquipment: availableEquipment ?? this.availableEquipment,
        workoutsPerWeek: workoutsPerWeek ?? this.workoutsPerWeek,
        profileComplete: profileComplete ?? this.profileComplete,
      );
}
