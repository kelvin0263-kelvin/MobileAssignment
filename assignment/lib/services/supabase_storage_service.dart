import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Uploads bytes to the `notes-photos` bucket and returns a public or signed URL.
  /// Assumes a public bucket for simplicity; change to signed if private.
  Future<String> uploadNoteImage(Uint8List bytes, {required String filename}) async {
    final uid = _client.auth.currentUser!.id;
    final path = 'users/$uid/$filename';
    await _client.storage.from('notes-photos').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
    // For public bucket
    return _client.storage.from('notes-photos').getPublicUrl(path);
  }
}

