import 'package:flutter/foundation.dart';

@immutable
class ProcedureCategory {
  final int id;
  final String name;
  final DateTime createdAt;

  const ProcedureCategory({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory ProcedureCategory.fromJson(Map<String, dynamic> json) {
    return ProcedureCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'ProcedureCategory(id: $id, name: $name, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProcedureCategory &&
        other.id == id &&
        other.name == name &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ createdAt.hashCode;
}