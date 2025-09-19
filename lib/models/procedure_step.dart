class ProcedureStep {
  final int id;
  final int procedureId;
  final int stepNumber;
  final String description;
  final String? tools;
  final String? safety;
  final String? videoUrl;
  final DateTime createdAt;

  ProcedureStep({
    required this.id,
    required this.procedureId,
    required this.stepNumber,
    required this.description,
    this.tools,
    this.safety,
    this.videoUrl,
    required this.createdAt,
  });

  factory ProcedureStep.fromJson(Map<String, dynamic> json) {
    return ProcedureStep(
      id: json['id'] as int,
      procedureId: json['procedure_id'] as int,
      stepNumber: json['step_number'] as int,
      description: json['description'] as String,
      tools: json['tools'] as String?,
      safety: json['safety'] as String?,
      videoUrl: json['video_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'procedure_id': procedureId,
      'step_number': stepNumber,
      'description': description,
      'tools': tools,
      'safety': safety,
      'video_url': videoUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  List<String> get toolsList {
    if (tools == null || tools!.isEmpty) return [];
    // Handle both literal \n and actual newlines
    return tools!.replaceAll('\\n', '\n').split('\n').where((tool) => tool.trim().isNotEmpty).toList();
  }

  List<String> get safetyList {
    if (safety == null || safety!.isEmpty) return [];
    // Handle both literal \n and actual newlines
    return safety!.replaceAll('\\n', '\n').split('\n').where((note) => note.trim().isNotEmpty).toList();
  }
}
