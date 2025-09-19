import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/connectivity_service.dart';
import '../providers/job_provider.dart';
import '../utils/app_utils.dart';
import '../models/job.dart';
import '../services/supabase_storage_service.dart';

class NotesWidget extends StatefulWidget {
  final String jobId;
  final bool readOnly;

  const NotesWidget({super.key, required this.jobId, this.readOnly = false});

  @override
  State<NotesWidget> createState() => _NotesWidgetState();
}

class _NotesWidgetState extends State<NotesWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final SupabaseStorageService _storage = SupabaseStorageService();
  final List<XFile> _selectedImages = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() {}); // 每次输入变化时刷新按钮状态
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 650, // Fixed height to prevent layout issues
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [Text('Notes', style: AppTextStyles.headline2)],
            ),
          ),
          const Divider(height: 1),
          // Messages list
          Expanded(
            child: Consumer<JobProvider>(
              builder: (context, jobProvider, child) {
                final job = jobProvider.selectedJob;
                final notes = job?.notes ?? const <JobNote>[];
                if (notes.isEmpty) {
                  return Center(
                    child: Text('No messages yet', style: AppTextStyles.body2),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[notes.length - 1 - index];
                    return _buildMessageBubble(note);
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          // Composer
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Selected images preview
                if (_selectedImages.isNotEmpty) ...[
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: FutureBuilder<Uint8List>(
                                  future: _selectedImages[index].readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Image.memory(
                                        snapshot.data!,
                                        height: 100,
                                        width: 100,
                                        fit: BoxFit.cover,
                                      );
                                    }
                                    return Container(
                                      height: 100,
                                      width: 100,
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // Text input
                TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Add a note about the repair...',
                  ),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 8),
                // Action buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: widget.readOnly
                          ? null
                          : (_isUploading
                              ? null
                              : () => _selectImage(ImageSource.camera)),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                    ),
                    OutlinedButton.icon(
                      onPressed: widget.readOnly
                          ? null
                          : (_isUploading
                              ? null
                              : () => _selectImage(ImageSource.gallery)),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Upload Photo'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(
                          double.infinity,
                          48,
                        ), // 按钮占满宽度，高度 48
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // 圆角
                        ),
                      ),
                      onPressed: widget.readOnly
                          ? null
                          : (_isUploading || _messageController.text.trim().isEmpty
                              ? null
                              : _addNoteWithMedia),
                      child: _isUploading
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Adding...'),
                              ],
                            )
                          : const Text('Add Note'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(JobNote note) {
    final hasImage =
        note.files.any((f) => f.fileType == 'photo') ||
        (note.imagePath != null);
    final images = note.files.where((f) => f.fileType == 'photo').toList();
    // Audio messages are no longer supported in this simplified UI
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((note.content).trim().isNotEmpty)
              Text(note.content, style: AppTextStyles.body2),
            if (hasImage) const SizedBox(height: 8),
            if (images.isNotEmpty)
              ...images.map(
                (img) => GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        insetPadding: const EdgeInsets.all(10), // 四周留一点边距
                        child: InteractiveViewer(
                          // 可以缩放、拖动
                          child: Image.network(
                            img.filePath,
                            fit: BoxFit.contain, // 原比例显示
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[300],
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image, size: 50),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      img.filePath,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover, // 缩略图还是裁剪显示
                      errorBuilder: (_, __, ___) => Container(
                        width: double.infinity,
                        height: 200,
                        color: AppColors.divider,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // No audio attachments in this simplified UI
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                DateHelper.formatDateTime(note.createdAt),
                style: AppTextStyles.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file != null) {
        setState(() {
          _selectedImages.add(file);
        });
      }
    } catch (e) {
      _showError('Failed to select image: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _addNoteWithMedia() async {
    final text = _messageController.text.trim();

    // Allow text-only notes - don't require images
    if (text.isEmpty) {
      _showError('Please enter a note before adding.');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final online = ConnectivityService.instance.isOnline;
      if (online) {
        final List<NoteFile> uploadedFiles = [];
        if (_selectedImages.isNotEmpty) {
          for (int i = 0; i < _selectedImages.length; i++) {
            try {
              final bytes = await _selectedImages[i].readAsBytes();
              final filename = 'img_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
              final url = await _storage.uploadNoteImage(bytes, filename: filename);
              uploadedFiles.add(NoteFile(
                id: 'tmp_$i',
                noteId: 'tmp',
                fileType: 'photo',
                filePath: url,
              ));
            } catch (_) {}
          }
        }
        await Provider.of<JobProvider>(context, listen: false)
            .addJobNote(widget.jobId, text, files: uploadedFiles);
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final uploadsDir = Directory('${dir.path}/offline_uploads');
        if (!await uploadsDir.exists()) {
          await uploadsDir.create(recursive: true);
        }
        final List<String> localPaths = [];
        for (int i = 0; i < _selectedImages.length; i++) {
          try {
            final filename = 'img_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
            final path = '${uploadsDir.path}/$filename';
            await _selectedImages[i].saveTo(path);
            localPaths.add(path);
          } catch (_) {}
        }
        await Provider.of<JobProvider>(context, listen: false)
            .addJobNoteOffline(widget.jobId, text, localPaths);
      }

      _messageController.clear();
      setState(() {
        _selectedImages.clear();
      });
    } catch (e) {
      _showError('Failed to add note: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // Keep old methods for backward compatibility
  Future<void> _handlePickImage(ImageSource src) async {
    _selectImage(src);
  }

  Future<void> _sendMessage() async {
    _addNoteWithMedia();
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
