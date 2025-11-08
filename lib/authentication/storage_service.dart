import 'dart:io';
 import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Upload document to Supabase Storage
  Future<String?> uploadDocument({
    required File file,
    required String userId,
    required String documentType, // 'license' or 'qualification'
  }) async {
    try {
      final fileExtension = file.path.split('.').last;
      final fileName = '$documentType-$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final filePath = '$userId/$fileName';

      // Upload file to Supabase Storage
      await _supabase.storage
          .from('documents')
          .upload(filePath, file);

      // Get public URL (you might want to sign this URL for security)
      final String publicUrl = _supabase.storage
          .from('documents')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('Error uploading document: $e');
      return null;
    }
  }

  // Upload document from file picker
  Future<String?> pickAndUploadDocument({
    required String userId,
    required String documentType,
  }) async {
    // You'll need to implement file picker logic
    // This is a placeholder for the file picking functionality
    return null;
  }
}
