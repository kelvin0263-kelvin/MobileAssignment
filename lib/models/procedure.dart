import 'procedure_category.dart';
import 'procedure_step.dart';

class Procedure {
  final int id;
  final int categoryId;
  final String title;
  final String difficulty;
  final int? estimatedMinutes;
  final DateTime createdAt;
  final ProcedureCategory? category;
  final List<ProcedureStep>? steps;

  Procedure({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.difficulty,
    this.estimatedMinutes,
    required this.createdAt,
    this.category,
    this.steps,
  });

  factory Procedure.fromJson(Map<String, dynamic> json) {
    return Procedure(
      id: json['id'] as int,
      categoryId: json['category_id'] as int,
      title: json['title'] as String,
      difficulty: json['difficulty'] as String,
      estimatedMinutes: json['estimated_minutes'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      category: json['category'] != null 
          ? ProcedureCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      steps: json['steps'] != null
          ? (json['steps'] as List)
              .map((step) => ProcedureStep.fromJson(step as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'title': title,
      'difficulty': difficulty,
      'estimated_minutes': estimatedMinutes,
      'created_at': createdAt.toIso8601String(),
      'category': category?.toJson(),
      'steps': steps?.map((step) => step.toJson()).toList(),
    };
  }

  String get difficultyDisplay {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return 'Beginner';
      case 'intermediate':
        return 'Intermediate';
      case 'advanced':
        return 'Advanced';
      default:
        return difficulty;
    }
  }

  String get estimatedTimeDisplay {
    if (estimatedMinutes == null) return 'Not specified';
    if (estimatedMinutes! < 60) {
      return '$estimatedMinutes minutes';
    } else {
      final hours = estimatedMinutes! ~/ 60;
      final minutes = estimatedMinutes! % 60;
      if (minutes == 0) {
        return '$hours hour${hours > 1 ? 's' : ''}';
      } else {
        return '$hours hour${hours > 1 ? 's' : ''} $minutes minutes';
      }
    }
  }
}

