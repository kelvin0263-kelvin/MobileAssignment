import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/procedure_provider.dart';
import '../models/procedure_step.dart';
import '../utils/app_utils.dart';

class ProcedureDetailScreen extends StatefulWidget {
  final int procedureId;

  const ProcedureDetailScreen({super.key, required this.procedureId});

  @override
  State<ProcedureDetailScreen> createState() => _ProcedureDetailScreenState();
}

class _ProcedureDetailScreenState extends State<ProcedureDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProcedureProvider>().loadProcedureDetails(widget.procedureId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Procedure Details'),
        elevation: 0,
      ),
      body: Consumer<ProcedureProvider>(
        builder: (context, procedureProvider, child) {
          final procedure = procedureProvider.selectedProcedure;
          if (procedure == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Procedure Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    // Category Icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(procedure.category?.name ?? ''),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCategoryIcon(procedure.category?.name ?? ''),
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Procedure Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            procedure.title,
                            style: AppTextStyles.headline1,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            procedure.category?.name ?? 'Unknown Category',
                            style: AppTextStyles.body2,
                          ),
                        ],
                      ),
                    ),
                    // Difficulty and Time Badges
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(procedure.difficulty),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            procedure.difficultyDisplay,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                procedure.estimatedTimeDisplay,
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Tab Bar
              Container(
                color: AppColors.surface,
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  tabs: const [
                    Tab(text: 'Steps'),
                    Tab(text: 'Tools'),
                    Tab(text: 'Safety'),
                    Tab(text: 'Video'),
                  ],
                ),
              ),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStepsTab(procedureProvider.procedureSteps),
                    _buildToolsTab(procedureProvider.procedureSteps),
                    _buildSafetyTab(procedureProvider.procedureSteps),
                    _buildVideoTab(procedureProvider.procedureSteps),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepsTab(List<ProcedureStep> steps) {
    if (steps.isEmpty) {
      return _buildEmptyState('No steps available', Icons.list_alt);
    }

    // Sort steps by step number in ascending order
    final sortedSteps = List<ProcedureStep>.from(steps)
      ..sort((a, b) => a.stepNumber.compareTo(b.stepNumber));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedSteps.length,
      itemBuilder: (context, index) {
        final step = sortedSteps[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    '${step.stepNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  step.description,
                  style: AppTextStyles.body1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolsTab(List<ProcedureStep> steps) {
    final allTools = <String>{};
    for (final step in steps) {
      // Use the toolsList getter which properly splits the string
      allTools.addAll(step.toolsList);
    }

    if (allTools.isEmpty) {
      return _buildEmptyState('No tools specified', Icons.build);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allTools.length,
      itemBuilder: (context, index) {
        final tool = allTools.elementAt(index);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.build, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  tool,
                  style: AppTextStyles.body1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSafetyTab(List<ProcedureStep> steps) {
    final allSafetyNotes = <String>{};
    for (final step in steps) {
      // Use the safetyList getter which properly splits the string
      allSafetyNotes.addAll(step.safetyList);
    }

    if (allSafetyNotes.isEmpty) {
      return _buildEmptyState('No safety notes available', Icons.warning);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allSafetyNotes.length,
      itemBuilder: (context, index) {
        final safetyNote = allSafetyNotes.elementAt(index);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.warning, color: Colors.red, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  safetyNote,
                  style: AppTextStyles.body1.copyWith(color: Colors.red.shade700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoTab(List<ProcedureStep> steps) {
    // Find the first step that has a video URL
    ProcedureStep? stepWithVideo;
    for (final step in steps) {
      if (step.videoUrl != null && step.videoUrl!.isNotEmpty) {
        stepWithVideo = step;
        break; // Take only the first video found
      }
    }

    if (stepWithVideo == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200,
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider, style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.video_library, size: 64, color: AppColors.textSecondary),
                    const SizedBox(height: 8),
                    Text('No video tutorial available', style: AppTextStyles.body2),
                    const SizedBox(height: 4),
                    Text('for this procedure', style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_circle_outline, size: 64, color: AppColors.primary),
              const SizedBox(height: 8),
              Text('Video Tutorial Available', style: AppTextStyles.body2),
              const SizedBox(height: 8),
              Text('Click to watch on YouTube', style: AppTextStyles.caption),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _launchVideo(stepWithVideo!.videoUrl!),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Watch Tutorial'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(message, style: AppTextStyles.body2),
          ],
        ),
      ),
    );
  }

  Future<void> _launchVideo(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch video: $url')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching video: $e')),
        );
      }
    }
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
        return AppColors.primary;
    }
  }
}