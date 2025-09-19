import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../utils/app_utils.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import '../services/supabase_storage_service.dart';
import '../services/connectivity_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../providers/job_provider.dart';

class SignatureWidget extends StatefulWidget {
  final String jobId;
  final VoidCallback onSignatureComplete;

  const SignatureWidget({
    super.key,
    required this.jobId,
    required this.onSignatureComplete,
  });

  @override
  State<SignatureWidget> createState() => _SignatureWidgetState();
}

class _SignatureWidgetState extends State<SignatureWidget> {
  late SignatureController _signatureController;
  final SupabaseStorageService _storage = SupabaseStorageService();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      exportBackgroundColor: Colors.white,
      exportPenColor: Colors.black,
    );
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Text(
                'Digital Signature',
                style: AppTextStyles.headline2,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Signature Area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Signature(
                  controller: _signatureController,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Instructions
          Text(
            'Please sign above to confirm job completion',
            style: AppTextStyles.body2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _clearSignature,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveSignature,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _clearSignature() {
    _signatureController.clear();
  }

  Future<void> _saveSignature() async {
    if (_signatureController.isNotEmpty) {
      try {
        setState(() => _saving = true);
        final Uint8List? signatureData = await _signatureController.toPngBytes();
        if (signatureData == null) throw 'No signature data';

        final online = ConnectivityService.instance.isOnline;
        if (online) {
          // Upload now
          final url = await _storage.uploadSignature(signatureData, jobId: widget.jobId);
          final ok = await Provider.of<JobProvider>(context, listen: false)
              .saveJobSignature(widget.jobId, url);
          if (!ok) throw 'Failed to persist signature';
        } else {
          // Save locally and queue for sync
          final dir = await getApplicationDocumentsDirectory();
          final folder = Directory('${dir.path}/offline_uploads/signatures');
          if (!await folder.exists()) {
            await folder.create(recursive: true);
          }
          final filename = 'sig_${widget.jobId}_${DateTime.now().millisecondsSinceEpoch}.png';
          final path = '${folder.path}/$filename';
          final file = File(path);
          await file.writeAsBytes(signatureData, flush: true);
          await Provider.of<JobProvider>(context, listen: false)
              .saveJobSignatureOffline(widget.jobId, path);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ConnectivityService.instance.isOnline
              ? 'Signature saved successfully!'
              : 'Signature saved for upload when back online'),
          backgroundColor: AppColors.primary,
        ));
        widget.onSignatureComplete();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving signature: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a signature first'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }
}
