import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/procedure.dart';
import '../models/procedure_category.dart';
import '../models/procedure_step.dart';

class ProcedureService {
  final SupabaseClient _client = Supabase.instance.client;

  // Get all procedure categories
  Future<List<ProcedureCategory>> getCategories() async {
    try {
      final response = await _client
          .from('procedure_categories')
          .select()
          .order('name');

      return (response as List)
          .map((json) => ProcedureCategory.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching categories: $e');
      throw Exception('Failed to fetch categories');
    }
  }

  // Get all procedures with optional category filter
  Future<List<Procedure>> getProcedures({int? categoryId}) async {
    try {
      var query = _client
          .from('procedures')
          .select('''
            *,
            category:procedure_categories(*)
          ''');

      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }

      final response = await query.order('title');

      return (response as List)
          .map((json) => Procedure.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching procedures: $e');
      throw Exception('Failed to fetch procedures');
    }
  }

  // Search procedures by title
  Future<List<Procedure>> searchProcedures(String query) async {
    try {
      final response = await _client
          .from('procedures')
          .select('''
            *,
            category:procedure_categories(*)
          ''')
          .ilike('title', '%$query%')
          .order('title');

      return (response as List)
          .map((json) => Procedure.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error searching procedures: $e');
      throw Exception('Failed to search procedures');
    }
  }

  // Get procedure by ID with steps
  Future<Procedure?> getProcedureById(int id) async {
    try {
      final response = await _client
          .from('procedures')
          .select('''
            *,
            category:procedure_categories(*),
            steps:procedure_steps(*)
          ''')
          .eq('id', id)
          .single();

      return Procedure.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching procedure: $e');
      return null;
    }
  }

  // Get steps for a procedure
  Future<List<ProcedureStep>> getProcedureSteps(int procedureId) async {
    try {
      final response = await _client
          .from('procedure_steps')
          .select()
          .eq('procedure_id', procedureId)
          .order('step_number');

      return (response as List)
          .map((json) => ProcedureStep.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching procedure steps: $e');
      throw Exception('Failed to fetch procedure steps');
    }
  }

  // Create a new procedure
  Future<Procedure> createProcedure({
    required int categoryId,
    required String title,
    required String difficulty,
    int? estimatedMinutes,
  }) async {
    try {
      final response = await _client
          .from('procedures')
          .insert({
            'category_id': categoryId,
            'title': title,
            'difficulty': difficulty,
            'estimated_minutes': estimatedMinutes,
          })
          .select('''
            *,
            category:procedure_categories(*)
          ''')
          .single();

      return Procedure.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error creating procedure: $e');
      throw Exception('Failed to create procedure');
    }
  }

  // Create a new procedure step
  Future<ProcedureStep> createProcedureStep({
    required int procedureId,
    required int stepNumber,
    required String description,
    String? tools,
    String? safety,
    String? videoUrl,
  }) async {
    try {
      final response = await _client
          .from('procedure_steps')
          .insert({
            'procedure_id': procedureId,
            'step_number': stepNumber,
            'description': description,
            'tools': tools,
            'safety': safety,
            'video_url': videoUrl,
          })
          .select()
          .single();

      return ProcedureStep.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error creating procedure step: $e');
      throw Exception('Failed to create procedure step');
    }
  }

  // Update procedure
  Future<Procedure> updateProcedure({
    required int id,
    int? categoryId,
    String? title,
    String? difficulty,
    int? estimatedMinutes,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (categoryId != null) updates['category_id'] = categoryId;
      if (title != null) updates['title'] = title;
      if (difficulty != null) updates['difficulty'] = difficulty;
      if (estimatedMinutes != null) updates['estimated_minutes'] = estimatedMinutes;

      final response = await _client
          .from('procedures')
          .update(updates)
          .eq('id', id)
          .select('''
            *,
            category:procedure_categories(*)
          ''')
          .single();

      return Procedure.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error updating procedure: $e');
      throw Exception('Failed to update procedure');
    }
  }

  // Delete procedure
  Future<void> deleteProcedure(int id) async {
    try {
      await _client
          .from('procedures')
          .delete()
          .eq('id', id);
    } catch (e) {
      print('Error deleting procedure: $e');
      throw Exception('Failed to delete procedure');
    }
  }
}
