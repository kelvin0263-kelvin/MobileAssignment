import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/job.dart';
import '../providers/job_provider.dart';
import '../utils/app_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_storage_service.dart';

class NotesPhotosCard extends StatefulWidget {
  final Job job;

  const NotesPhotosCard({super.key, required this.job});

  @override
  State<NotesPhotosCard> createState() => _NotesPhotosCardState();
}

class _NotesPhotosCardState extends State<NotesPhotosCard> {
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();
  bool _isPicking = false;

  @override
  void dispose() {
    _noteController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    return Column(
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notes (${job.notes.length})', style: AppTextStyles.headline2),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Add a note about this job...',
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final text = _noteController.text.trim();
                      if (text.isEmpty) return;
                      await Provider.of<JobProvider>(context, listen: false)
                          .addJobNote(job.id, text, null);
                      if (!mounted) return;
                      _noteController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Note'),
                  ),
                ),
                if (job.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Previous Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...job.notes.map((n) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (n.imagePath != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildImageWidget(n.imagePath!),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(n.content, style: AppTextStyles.body2),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('ID ${n.id}', style: AppTextStyles.caption),
                            Text(DateHelper.formatDateTime(n.createdAt), style: AppTextStyles.caption),
                          ],
                        )
                      ],
                    ),
                  )),
                ]
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Photos (${job.notes.where((n) => n.imagePath != null).length})', style: AppTextStyles.headline2),
                const SizedBox(height: 12),
                TextField(
                  controller: _captionController,
                  decoration: const InputDecoration(
                    hintText: 'Photo caption (optional)',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isPicking ? null : () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera),
                        label: const Text('Take Photo'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isPicking ? null : () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('From Gallery'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isPicking = true;
    });
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 85);
      if (file == null) return;
      final caption = _captionController.text.trim().isEmpty ? 'Workshop photo' : _captionController.text.trim();
      String? pathOrUrl;
      if (_supabaseReady) {
        try {
          final Uint8List bytes = await file.readAsBytes();
          final url = await SupabaseStorageService().uploadNoteImage(
            bytes,
            filename: 'note-${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
          pathOrUrl = url;
        } catch (e) {
          // Fallback to local path if upload fails
          pathOrUrl = file.path;
        }
      } else {
        pathOrUrl = file.path;
      }
      await Provider.of<JobProvider>(context, listen: false)
          .addJobNote(widget.job.id, caption, pathOrUrl);
      if (!mounted) return;
      _captionController.clear();
      setState(() {});
    } finally {
      if (mounted) {
        setState(() {
          _isPicking = false;
        });
      }
    }
  }

  bool get _supabaseReady {
    try {
      final c = Supabase.instance.client;
      return c.auth.currentUser != null; // must be logged in to upload
    } catch (_) {
      return false;
    }
  }

  Widget _buildImageWidget(String path) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
    return Image.file(
      File(path),
      height: 160,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }
}


