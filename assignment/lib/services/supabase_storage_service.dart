import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String> _uploadBytes(String bucket, Uint8List bytes,
      {required String path, required String contentType}) async {
    await _client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(upsert: true, contentType: contentType),
        );
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  Future<String> uploadNoteImage(Uint8List bytes, {required String filename}) async {
    final uid = _client.auth.currentUser?.id ?? 'anon';
    final path = 'users/$uid/$filename';
    
    try {
      print('=== IMAGE UPLOAD DEBUG ===');
      print('User ID: $uid');
      print('Bucket: job-note-files');
      print('Path: $path');
      print('File size: ${bytes.length} bytes');
      print('Auth status: ${_client.auth.currentUser != null ? "Authenticated" : "Not authenticated"}');
      
      // Test bucket access first
      try {
        await _client.storage.from('job-note-files').list();
        print('Bucket access: SUCCESS');
      } catch (bucketError) {
        print('Bucket access test failed: $bucketError');
      }
      
      return await _uploadBytes('job-note-files', bytes, path: path, contentType: 'image/jpeg');
    } catch (e) {
      print('Detailed storage upload error: $e');
      print('Error type: ${e.runtimeType}');
      
      // More specific error handling
      if (e.toString().contains('Bucket not found') || e.toString().contains('404')) {
        throw Exception('Storage bucket "job-note-files" not found.');
      } else if (e.toString().contains('403') || e.toString().contains('unauthorized')) {
        throw Exception('Permission denied. Check bucket policies in Supabase Dashboard.');
      } else if (e.toString().contains('413') || e.toString().contains('too large')) {
        throw Exception('Image file too large. Try a smaller image.');
      } else if (e.toString().contains('duplicate') || e.toString().contains('already exists')) {
        // File already exists, try with different name
        final newFilename = 'img_${DateTime.now().millisecondsSinceEpoch}_retry.jpg';
        final newPath = 'users/$uid/$newFilename';
        print('File exists, retrying with: $newPath');
        return await _uploadBytes('job-note-files', bytes, path: newPath, contentType: 'image/jpeg');
      } else {
        throw Exception('Image upload failed: ${e.toString()}');
      }
    }
  }

  Future<String> uploadNoteAudio(Uint8List bytes, {required String filename, String contentType = 'audio/m4a'}) async {
    final uid = _client.auth.currentUser?.id ?? 'anon';
    final path = 'users/$uid/$filename';
    return _uploadBytes('job-note-files', bytes, path: path, contentType: contentType);
  }

  Future<String> uploadSignature(Uint8List bytes, {required String jobId}) async {
    // Store signatures under a dedicated folder within the same bucket
    final path = 'signatures/job_$jobId.png';
    return _uploadBytes('job-note-files', bytes, path: path, contentType: 'image/png');
  }
}
