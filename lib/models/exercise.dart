class Exercise {
  final String id;
  final String name;
  final String muscleGroup;
  final String secondaryMuscles;
  final String difficulty;
  final String equipment;
  final String instructions;
  final String formTips;
  final String? gifUrl;
  final bool isCustom;

  Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    this.secondaryMuscles = '',
    required this.difficulty,
    this.equipment = 'Barbell',
    required this.instructions,
    required this.formTips,
    this.gifUrl,
    this.isCustom = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'muscleGroup': muscleGroup,
        'secondaryMuscles': secondaryMuscles,
        'difficulty': difficulty,
        'equipment': equipment,
        'instructions': instructions,
        'formTips': formTips,
        'gifUrl': gifUrl,
        'isCustom': isCustom ? 1 : 0,
      };

  factory Exercise.fromMap(Map<String, dynamic> map) => Exercise(
        id: map['id'],
        name: map['name'],
        muscleGroup: map['muscleGroup'],
        secondaryMuscles: map['secondaryMuscles'] ?? '',
        difficulty: map['difficulty'],
        equipment: map['equipment'] ?? 'Barbell',
        instructions: map['instructions'],
        formTips: map['formTips'],
        gifUrl: map['gifUrl'],
        isCustom: (map['isCustom'] ?? 0) == 1,
      );

  factory Exercise.fromApi(Map<String, dynamic> map) => Exercise(
        id: map['id'].toString(),
        name: (map['name'] ?? '').toString(),
        muscleGroup: (map['muscle_group'] ?? '').toString(),
        secondaryMuscles: (map['secondary_muscles'] ?? '').toString(),
        difficulty: (map['difficulty'] ?? 'Beginner').toString(),
        equipment: (map['equipment'] ?? 'Barbell').toString(),
        instructions: (map['instructions'] ?? '').toString(),
        formTips: (map['form_tips'] ?? '').toString(),
        gifUrl: map['gif_url']?.toString(),
        isCustom: map['is_custom'] == true || map['is_custom'] == 1,
      );

  Map<String, dynamic> toApiCreate() => {
        'name': name,
        'muscle_group': muscleGroup,
        'secondary_muscles': secondaryMuscles,
        'difficulty': difficulty,
        'equipment': equipment,
        'instructions': instructions,
        'form_tips': formTips,
        'gif_url': gifUrl,
      };

  Exercise copyWith({
    String? id,
    String? name,
    String? muscleGroup,
    String? secondaryMuscles,
    String? difficulty,
    String? equipment,
    String? instructions,
    String? formTips,
    String? gifUrl,
    bool? isCustom,
  }) =>
      Exercise(
        id: id ?? this.id,
        name: name ?? this.name,
        muscleGroup: muscleGroup ?? this.muscleGroup,
        secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
        difficulty: difficulty ?? this.difficulty,
        equipment: equipment ?? this.equipment,
        instructions: instructions ?? this.instructions,
        formTips: formTips ?? this.formTips,
        gifUrl: gifUrl ?? this.gifUrl,
        isCustom: isCustom ?? this.isCustom,
      );
}
