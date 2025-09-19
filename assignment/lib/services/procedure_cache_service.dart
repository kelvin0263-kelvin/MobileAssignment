import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/procedure.dart';
import '../models/procedure_step.dart';
import '../models/procedure_category.dart';

class ProcedureCacheService {
  ProcedureCacheService._internal();
  static final ProcedureCacheService instance = ProcedureCacheService._internal();

  static String _procedureKey(int id) => 'procedure_cache_v1_$id';
  static const String _categoriesKey = 'procedure_categories_v1';
  static const String _proceduresKey = 'procedures_catalog_v1';

  Future<void> saveProcedureDetails({
    required Procedure procedure,
    required List<ProcedureStep> steps,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final map = procedure.toJson();
    map['steps'] = steps.map((e) => e.toJson()).toList();
    await prefs.setString(_procedureKey(procedure.id), jsonEncode(map));
  }

  Future<Procedure?> loadProcedure(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_procedureKey(id));
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return Procedure.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<List<ProcedureStep>> loadProcedureSteps(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_procedureKey(id));
    if (raw == null || raw.isEmpty) return <ProcedureStep>[];
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final steps = (map['steps'] as List?) ?? const [];
      return steps
          .map((e) => ProcedureStep.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return <ProcedureStep>[];
    }
  }

  // Catalog cache: categories
  Future<void> saveCategories(List<ProcedureCategory> categories) async {
    final prefs = await SharedPreferences.getInstance();
    final list = categories.map((c) => c.toJson()).toList();
    await prefs.setString(_categoriesKey, jsonEncode(list));
  }

  Future<List<ProcedureCategory>> loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_categoriesKey);
    if (raw == null || raw.isEmpty) return <ProcedureCategory>[];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ProcedureCategory.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return <ProcedureCategory>[];
    }
  }

  // Catalog cache: procedures list
  Future<void> saveProcedures(List<Procedure> procedures) async {
    final prefs = await SharedPreferences.getInstance();
    final list = procedures.map((p) => p.toJson()).toList();
    await prefs.setString(_proceduresKey, jsonEncode(list));
  }

  Future<List<Procedure>> loadProcedures() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_proceduresKey);
    if (raw == null || raw.isEmpty) return <Procedure>[];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Procedure.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return <Procedure>[];
    }
  }
}


