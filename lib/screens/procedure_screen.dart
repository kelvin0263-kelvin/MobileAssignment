import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/procedure_provider.dart';
import '../models/procedure.dart';
import '../models/procedure_category.dart';
import '../utils/app_utils.dart';
import 'procedure_detail_screen.dart';

class ProcedureScreen extends StatefulWidget {
  const ProcedureScreen({super.key});

  @override
  State<ProcedureScreen> createState() => _ProcedureScreenState();
}

class _ProcedureScreenState extends State<ProcedureScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProcedureProvider>(context, listen: false).initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<ProcedureProvider>(
          builder: (context, procedureProvider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with WorkShop Pro branding
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.build, color: AppColors.primary, size: 28),
                          const SizedBox(width: 8),
                          Text('WorkShop Pro', style: AppTextStyles.headline1),
                          const Spacer(),
                          // User profile icon (AT)
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                'AT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 16),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Repair Manual & Guidelines', style: AppTextStyles.headline2),
                      const SizedBox(height: 4),
                      Text('Step-by-step procedures for common repairs', style: AppTextStyles.body2),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2))],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search procedures...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (value) {
                        procedureProvider.searchProcedures(value);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Horizontal Category Row
                _buildCategoriesRow(procedureProvider),
                 const SizedBox(height: 16),

                 // Filter Options
                 _buildFilterOptions(procedureProvider),
                 const SizedBox(height: 16),

                 // Procedures List
                 Expanded(
                   child: _buildProceduresList(procedureProvider),
                 ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoriesRow(ProcedureProvider procedureProvider) {
    final categoryCounts = procedureProvider.getCategoryCounts();
    final totalProcedures = procedureProvider.procedures.length;
    
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: procedureProvider.categories.length + 1, // +1 for "All Categories"
        itemBuilder: (context, index) {
          if (index == 0) {
            // "All Categories" card
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _AllCategoriesCard(
                procedureCount: totalProcedures,
                isSelected: procedureProvider.selectedCategoryId == null,
                onTap: () => procedureProvider.filterByCategory(null),
              ),
            );
          }
          
          final category = procedureProvider.categories[index - 1];
          final count = categoryCounts[category.id] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _CategoryCard(
              category: category,
              procedureCount: count,
              isSelected: procedureProvider.selectedCategoryId == category.id,
              onTap: () => procedureProvider.filterByCategory(category.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterOptions(ProcedureProvider procedureProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Difficulty Filter
          Expanded(
            child: _PillDropdown<String>(
              value: procedureProvider.difficultyFilter ?? 'all',
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Difficulty')),
                DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
                DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
              ],
              onChanged: (value) => procedureProvider.setDifficultyFilter(value),
            ),
          ),
          const SizedBox(width: 12),
          // Time Filter
          Expanded(
            child: _PillDropdown<String>(
              value: procedureProvider.timeFilter ?? 'all',
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Time')),
                DropdownMenuItem(value: 'quick', child: Text('Quick (< 30min)')),
                DropdownMenuItem(value: 'medium', child: Text('Medium (30-60min)')),
                DropdownMenuItem(value: 'long', child: Text('Long (> 60min)')),
              ],
              onChanged: (value) => procedureProvider.setTimeFilter(value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProceduresList(ProcedureProvider procedureProvider) {
    if (procedureProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredProcedures = procedureProvider.filteredProcedures;

    if (filteredProcedures.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.book_outlined, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text('No procedures found', style: AppTextStyles.headline3),
              const SizedBox(height: 8),
              Text('Try adjusting your search or filters', style: AppTextStyles.body2),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => procedureProvider.initialize(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredProcedures.length,
        itemBuilder: (context, index) {
          final procedure = filteredProcedures[index];
          return _ProcedureCard(
            procedure: procedure,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProcedureDetailScreen(procedureId: procedure.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AllCategoriesCard extends StatelessWidget {
  final int procedureCount;
  final bool isSelected;
  final VoidCallback onTap;

  const _AllCategoriesCard({
    required this.procedureCount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 110,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.category, color: Colors.white, size: 18),
              ),
              const SizedBox(height: 6),
              // Title
              Text(
                'All Categories',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // Procedure count
              Text(
                '$procedureCount procedures',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final ProcedureCategory category;
  final int procedureCount;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.procedureCount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 110,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _getCategoryColor(category.name),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(_getCategoryIcon(category.name), color: Colors.white, size: 18),
              ),
              const SizedBox(height: 6),
              // Title
              Text(
                category.name,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // Procedure count
              Text(
                '$procedureCount procedures',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'engine & transmission':
        return Colors.blue;
      case 'brake system':
        return Colors.red;
      case 'electrical system':
        return Colors.orange;
      case 'suspension & steering':
        return Colors.green;
      case 'cooling system':
        return Colors.cyan;
      default:
        return AppColors.primary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'engine & transmission':
        return Icons.settings;
      case 'brake system':
        return Icons.warning;
      case 'electrical system':
        return Icons.flash_on;
      case 'suspension & steering':
        return Icons.directions_car;
      case 'cooling system':
        return Icons.water_drop;
      default:
        return Icons.build;
    }
  }
}

class _ProcedureCard extends StatelessWidget {
  final Procedure procedure;
  final VoidCallback onTap;

  const _ProcedureCard({
    required this.procedure,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon, title, and badges
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(procedure.category?.name ?? ''),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_getCategoryIcon(procedure.category?.name ?? ''), color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(procedure.title, style: AppTextStyles.headline3),
                        const SizedBox(height: 4),
                        Text(
                          procedure.category?.name ?? 'Unknown Category',
                          style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Difficulty badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(procedure.difficulty).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getDifficultyColor(procedure.difficulty)),
                    ),
                    child: Text(
                      procedure.difficultyDisplay,
                      style: TextStyle(
                        color: _getDifficultyColor(procedure.difficulty),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Time badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          procedure.estimatedTimeDisplay,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'engine & transmission':
        return Colors.blue;
      case 'brake system':
        return Colors.red;
      case 'electrical system':
        return Colors.orange;
      case 'suspension & steering':
        return Colors.green;
      case 'cooling system':
        return Colors.cyan;
      default:
        return AppColors.primary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'engine & transmission':
        return Icons.settings;
      case 'brake system':
        return Icons.warning;
      case 'electrical system':
        return Icons.flash_on;
      case 'suspension & steering':
        return Icons.directions_car;
      case 'cooling system':
        return Icons.water_drop;
      default:
        return Icons.build;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return AppColors.textSecondary;
    }
  }
}

// Simple pill-styled dropdown used in the filter row
class _PillDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _PillDropdown({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          items: items,
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down),
          style: AppTextStyles.body2,
        ),
      ),
    );
  }
}
