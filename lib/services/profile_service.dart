import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Data Model ---
class Doctor {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String category;
  final String? profilePictureUrl;
  final bool isAvailable;
  final DateTime createdAt;

  Doctor({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.category,
    this.profilePictureUrl,
    required this.isAvailable,
    required this.createdAt,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'N/A',
      email: json['email'] ?? 'N/A',
      phone: json['phone'] ?? 'N/A',
      category: json['category'] ?? 'N/A',
      profilePictureUrl: json['profilepicture'],
      isAvailable: json['avb_status'] ?? false,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

// --- Service Class ---
class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get the current user's email
  String? get _userEmail => _supabase.auth.currentUser?.email;
  // Get the current user's ID (for storage path)
  String? get _userId => _supabase.auth.currentUser?.id;

  /// Fetch the doctor's profile from the database
  Future<Doctor> getDoctorProfile() async {
    if (_userEmail == null) {
      throw Exception('User not logged in.');
    }
    try {
      final data = await _supabase
          .from('doctors')
          .select()
          .eq('email', _userEmail!)
          .single();
      return Doctor.fromJson(data);
    } catch (e) {
      debugPrint('Error fetching doctor profile: $e');
      throw Exception(
        'Could not fetch profile. Please ensure you are registered.',
      );
    }
  }

  /// Update phone number
  Future<void> updatePhone(String newPhone) async {
    if (_userEmail == null) throw Exception('User not logged in.');

    final cleanPhone = newPhone.trim();
    if (!RegExp(r'^\+?94\s?[0-9]{2}\s?[0-9]{7}$').hasMatch(cleanPhone)) {
      throw Exception(
        'Please enter a valid Sri Lankan phone number (+94 XX XXX XXXX)',
      );
    }

    try {
      await _supabase
          .from('doctors')
          .update({'phone': cleanPhone})
          .eq('email', _userEmail!);
    } catch (e) {
      debugPrint('Error updating phone number: $e');
      throw Exception('Could not update phone number. Please try again.');
    }
  }

  /// Update availability status
  Future<void> updateAvailability(bool isAvailable) async {
    if (_userEmail == null) throw Exception('User not logged in.');
    await _supabase
        .from('doctors')
        .update({'avb_status': isAvailable})
        .eq('email', _userEmail!);
  }

  /// Update profile picture URL in Supabase DB
  Future<void> _updateProfilePictureUrl(String newUrl) async {
    if (_userEmail == null) throw Exception('User not logged in.');
    await _supabase
        .from('doctors')
        .update({'profilepicture': newUrl})
        .eq('email', _userEmail!);
  }

  /// Pick, upload, and update the profile picture (Web + Mobile compatible)
  Future<String> pickAndUploadProfilePicture() async {
    if (_userId == null) throw Exception('User not logged in.');

    try {
      // Pick image
      final picker = ImagePicker();
      final xFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (xFile == null) throw Exception('No image selected.');

      // Validate and process the file
      String? mimeType = xFile.mimeType?.toLowerCase();

      // Standardize extension and content type
      String fileExtension;
      String contentType;

      if (mimeType != null) {
        if (mimeType == 'image/png') {
          fileExtension = 'png';
          contentType = 'image/png';
        } else if (mimeType == 'image/jpeg' || mimeType == 'image/jpg') {
          fileExtension = 'jpg';
          contentType = 'image/jpeg';
        } else {
          throw Exception('Please select a JPG or PNG image file');
        }
      } else {
        // Fallback to path extension if mimeType is not available
        final String originalPath = xFile.path.toLowerCase();
        final String originalExt = originalPath.split('.').last;

        if (originalExt == 'png') {
          fileExtension = 'png';
          contentType = 'image/png';
        } else if (originalExt == 'jpg' || originalExt == 'jpeg') {
          fileExtension = 'jpg';
          contentType = 'image/jpeg';
        } else {
          throw Exception('Please select a JPG or PNG image file');
        }
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${_userId}_$timestamp.$fileExtension';
      final storageFilePath = 'profiles/$fileName';

      // Upload depending on platform
      if (kIsWeb) {
        // Flutter Web — upload as bytes
        final bytes = await xFile.readAsBytes();
        await _supabase.storage
            .from('doctor_profiles')
            .uploadBinary(
              storageFilePath,
              bytes,
              fileOptions: FileOptions(
                cacheControl: '3600',
                upsert: true,
                contentType: contentType,
              ),
            );
      } else {
        // Mobile — upload as file
        final file = File(xFile.path);

        // Validate file size (max 5MB)
        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) {
          throw Exception('Image size must be less than 5MB');
        }

        await _supabase.storage
            .from('doctor_profiles')
            .upload(
              storageFilePath,
              file,
              fileOptions: FileOptions(
                cacheControl: '3600',
                upsert: true,
                contentType: contentType,
              ),
            );
      }

      // Get public URL and ensure it's properly formatted
      final publicUrl = _supabase.storage
          .from('doctor_profiles')
          .getPublicUrl(storageFilePath);

      // Update URL in DB
      await _updateProfilePictureUrl(publicUrl);

      // Clean up old images
      try {
        final oldFiles = await _supabase.storage
            .from('doctor_profiles')
            .list(path: 'profiles');

        // Find and remove old profile pictures for this user
        for (var file in oldFiles) {
          if (file.name.startsWith('${_userId}_') && file.name != fileName) {
            await _supabase.storage.from('doctor_profiles').remove([
              'profiles/${file.name}',
            ]);
          }
        }
      } catch (e) {
        debugPrint('Error cleaning up old profile pictures: $e');
        // Don't throw here as the upload was successful
      }

      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      throw Exception('Could not upload image: $e');
    }
  }
}
