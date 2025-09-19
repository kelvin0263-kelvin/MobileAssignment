import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../utils/app_utils.dart';

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
        final signatureData = await _signatureController.toPngBytes();
        if (signatureData != null) {
          // TODO: Save signature data to backend
          // For now, we'll just show a success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Signature saved successfully!'),
              backgroundColor: AppColors.primary,
            ),
          );
          widget.onSignatureComplete();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving signature: $e'),
            backgroundColor: AppColors.error,
          ),
        );
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
