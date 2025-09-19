import 'package:flutter/material.dart';
import '../models/procedure.dart';
import '../models/procedure_category.dart';
import '../models/procedure_step.dart';
import '../services/procedure_service.dart';
import '../services/procedure_cache_service.dart';
import '../services/connectivity_service.dart';

class ProcedureProvider extends ChangeNotifier {
  final ProcedureService _procedureService = ProcedureService();

  List<ProcedureCategory> _categories = [];
  List<Procedure> _procedures = [];
  Procedure? _selectedProcedure;
  List<ProcedureStep> _procedureSteps = [];
  bool _isLoading = false;
  String _searchQuery = '';
  int? _selectedCategoryId;
  String? _difficultyFilter;
  String? _timeFilter;

  // Getters
  List<ProcedureCategory> get categories => _categories;
  List<Procedure> get procedures => _procedures;
  Procedure? get selectedProcedure => _selectedProcedure;
  List<ProcedureStep> get procedureSteps => _procedureSteps;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  int? get selectedCategoryId => _selectedCategoryId;
  String? get difficultyFilter => _difficultyFilter;
  String? get timeFilter => _timeFilter;

  // Initialize data
  Future<void> initialize() async {
    final online = ConnectivityService.instance.isOnline;
    if (online) {
      await loadCategories();
      await loadProcedures();
      // Prefetch full catalog for offline
      await prefetchAllProceduresForOffline();
    } else {
      // Load from cache for offline startup
      _isLoading = true;
      notifyListeners();
      _categories = await ProcedureCacheService.instance.loadCategories();
      _procedures = await ProcedureCacheService.instance.loadProcedures();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load categories
  Future<void> loadCategories() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      _categories = await _procedureService.getCategories();
      // Save for offline
      await ProcedureCacheService.instance.saveCategories(_categories);
    } catch (e) {
      print('Error loading categories: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load procedures
  Future<void> loadProcedures({int? categoryId}) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      _procedures = await _procedureService.getProcedures(categoryId: categoryId);
      // Save latest list for offline browsing
      await ProcedureCacheService.instance.saveProcedures(_procedures);
    } catch (e) {
      print('Error loading procedures: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search procedures
  Future<void> searchProcedures(String query) async {
    try {
      _isLoading = true;
      _searchQuery = query;
      notifyListeners();
      
      if (query.isEmpty) {
        await loadProcedures(categoryId: _selectedCategoryId);
      } else {
        _procedures = await _procedureService.searchProcedures(query);
      }
    } catch (e) {
      print('Error searching procedures: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter by category
  void filterByCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  // Set difficulty filter
  void setDifficultyFilter(String? difficulty) {
    _difficultyFilter = difficulty;
    notifyListeners();
  }

  // Set time filter
  void setTimeFilter(String? time) {
    _timeFilter = time;
    notifyListeners();
  }

  // Get filtered procedures count for each category
  Map<int, int> getCategoryCounts() {
    Map<int, int> counts = {};
    for (var procedure in _procedures) {
      counts[procedure.categoryId] = (counts[procedure.categoryId] ?? 0) + 1;
    }
    return counts;
  }

  // Load procedure details with steps
  Future<void> loadProcedureDetails(int procedureId) async {
    try {
      _isLoading = true;
      notifyListeners();
      final online = ConnectivityService.instance.isOnline;
      if (online) {
        _selectedProcedure = await _procedureService.getProcedureById(procedureId);
        if (_selectedProcedure != null) {
          _procedureSteps = await _procedureService.getProcedureSteps(procedureId);
          await ProcedureCacheService.instance.saveProcedureDetails(
            procedure: _selectedProcedure!,
            steps: _procedureSteps,
          );
        }
      } else {
        // Offline: try cache
        _selectedProcedure = await ProcedureCacheService.instance.loadProcedure(procedureId);
        _procedureSteps = await ProcedureCacheService.instance.loadProcedureSteps(procedureId);
      }
    } catch (e) {
      // Try cache on error as well
      final cached = await ProcedureCacheService.instance.loadProcedure(procedureId);
      if (cached != null) {
        _selectedProcedure = cached;
        _procedureSteps = await ProcedureCacheService.instance.loadProcedureSteps(procedureId);
      } else {
        print('Error loading procedure details: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Prefetch and cache all procedures and their steps for offline use
  Future<void> prefetchAllProceduresForOffline() async {
    try {
      final online = ConnectivityService.instance.isOnline;
      if (!online) return;

      // Load full list (already cached in loadProcedures), but ensure we have the latest
      final list = await _procedureService.getProcedures();
      await ProcedureCacheService.instance.saveProcedures(list);

      // Fetch details and steps for each and cache
      for (final p in list) {
        final proc = await _procedureService.getProcedureById(p.id);
        final steps = await _procedureService.getProcedureSteps(p.id);
        if (proc != null) {
          await ProcedureCacheService.instance.saveProcedureDetails(
            procedure: proc,
            steps: steps,
          );
        }
      }
    } catch (e) {
      // Best-effort: ignore errors; some items might still be cached
      print('Prefetch procedures failed: $e');
    }
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    loadProcedures(categoryId: _selectedCategoryId);
  }

  // Clear filters
  void clearFilters() {
    _selectedCategoryId = null;
    _searchQuery = '';
    loadProcedures();
  }

  // Get filtered procedures based on all active filters
  List<Procedure> get filteredProcedures {
    List<Procedure> filtered = List.from(_procedures);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((procedure) {
        return procedure.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               procedure.category?.name.toLowerCase().contains(_searchQuery.toLowerCase()) == true;
      }).toList();
    }

    // Apply category filter
    if (_selectedCategoryId != null) {
      filtered = filtered.where((procedure) => procedure.categoryId == _selectedCategoryId).toList();
    }

    // Apply difficulty filter
    if (_difficultyFilter != null && _difficultyFilter != 'all') {
      filtered = filtered.where((procedure) => procedure.difficulty.toLowerCase() == _difficultyFilter!.toLowerCase()).toList();
    }

    // Apply time filter
    if (_timeFilter != null && _timeFilter != 'all') {
      filtered = filtered.where((procedure) {
        final minutes = procedure.estimatedMinutes ?? 0;
        switch (_timeFilter) {
          case 'quick':
            return minutes < 30;
          case 'medium':
            return minutes >= 30 && minutes <= 60;
          case 'long':
            return minutes > 60;
          default:
            return true;
        }
      }).toList();
    }

    return filtered;
  }

  // Create new procedure
  Future<bool> createProcedure({
    required int categoryId,
    required String title,
    required String difficulty,
    int? estimatedMinutes,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _procedureService.createProcedure(
        categoryId: categoryId,
        title: title,
        difficulty: difficulty,
        estimatedMinutes: estimatedMinutes,
      );
      
      await loadProcedures(categoryId: _selectedCategoryId);
      return true;
    } catch (e) {
      print('Error creating procedure: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new procedure step
  Future<bool> createProcedureStep({
    required int procedureId,
    required int stepNumber,
    required String description,
    String? tools,
    String? safety,
    String? videoUrl,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _procedureService.createProcedureStep(
        procedureId: procedureId,
        stepNumber: stepNumber,
        description: description,
        tools: tools,
        safety: safety,
        videoUrl: videoUrl,
      );
      
      if (_selectedProcedure?.id == procedureId) {
        await loadProcedureDetails(procedureId);
      }
      return true;
    } catch (e) {
      print('Error creating procedure step: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update procedure
  Future<bool> updateProcedure({
    required int id,
    int? categoryId,
    String? title,
    String? difficulty,
    int? estimatedMinutes,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _procedureService.updateProcedure(
        id: id,
        categoryId: categoryId,
        title: title,
        difficulty: difficulty,
        estimatedMinutes: estimatedMinutes,
      );
      
      await loadProcedures(categoryId: _selectedCategoryId);
      return true;
    } catch (e) {
      print('Error updating procedure: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete procedure
  Future<bool> deleteProcedure(int id) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _procedureService.deleteProcedure(id);
      
      await loadProcedures(categoryId: _selectedCategoryId);
      return true;
    } catch (e) {
      print('Error deleting procedure: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}