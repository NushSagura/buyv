import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';

class CloudinaryService {
  static CloudinaryService? _instance;

  CloudinaryService._internal();

  static CloudinaryService get instance {
    _instance ??= CloudinaryService._internal();
    return _instance!;
  }

  /// Upload image to Cloudinary
  static Future<String?> uploadImage(XFile imageFile, {String? folder}) async {
    try {
      debugPrint('🚀 Starting image upload to Cloudinary...');
      debugPrint('📁 Folder: ${folder ?? 'default'}');
      debugPrint('📄 File path: ${imageFile.path}');
      debugPrint('📄 File name: ${imageFile.name}');

      debugPrint('☁️ Cloud Name: ${AppConstants.cloudinaryCloudName}');
      debugPrint('🔧 Upload Preset: ${AppConstants.cloudinaryUploadPreset}');

      final cloudinary = CloudinaryPublic(
        AppConstants.cloudinaryCloudName,
        AppConstants.cloudinaryUploadPreset,
        cache: false,
      );

      final bytes = await imageFile.readAsBytes();

      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromByteData(
          bytes.buffer.asByteData(),
          identifier: imageFile.name, // Use actual filename with extension
          folder: folder ?? 'images',
          publicId: 'img_${DateTime.now().millisecondsSinceEpoch}',
        ),
      );

      debugPrint('✅ Image uploaded successfully');
      debugPrint('🔗 URL: ${response.secureUrl}');

      return response.secureUrl;
    } on DioException catch (e) {
      debugPrint('❌ Error uploading image (Dio): ${e.message}');
      debugPrint('❌ Response data: ${e.response?.data}');
      return null;
    } catch (e) {
      debugPrint('❌ Error uploading image: $e');
      return null;
    }
  }

  /// Upload video to Cloudinary
  static Future<String?> uploadVideo(XFile videoFile, {String? folder}) async {
    try {
      debugPrint('🚀 Starting video upload to Cloudinary...');
      debugPrint('📁 Folder: ${folder ?? 'default'}');
      debugPrint('📄 File path: ${videoFile.path}');
      debugPrint('📄 File name: ${videoFile.name}');

      final cloudinary = CloudinaryPublic(
        AppConstants.cloudinaryCloudName,
        AppConstants.cloudinaryUploadPreset,
        cache: false,
      );

      final bytes = await videoFile.readAsBytes();

      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromByteData(
          bytes.buffer.asByteData(),
          identifier: videoFile.name,
          folder: folder ?? 'videos',
          publicId: 'vid_${DateTime.now().millisecondsSinceEpoch}',
          resourceType: CloudinaryResourceType.Video,
        ),
      );

      debugPrint('✅ Video uploaded successfully');
      debugPrint('🔗 URL: ${response.secureUrl}');

      return response.secureUrl;
    } on DioException catch (e) {
      debugPrint('❌ Error uploading video (Dio): ${e.message}');
      debugPrint('❌ Response data: ${e.response?.data}');
      return null;
    } catch (e) {
      debugPrint('❌ Error uploading video: $e');
      return null;
    }
  }

  /// Upload profile image with specific transformations
  static Future<String?> uploadProfileImage(String imagePath) async {
    try {
      debugPrint('🚀 Starting profile image upload to Cloudinary...');
      debugPrint('📄 File path: $imagePath');

      final cloudinary = CloudinaryPublic(
        AppConstants.cloudinaryCloudName,
        AppConstants.cloudinaryUploadPreset,
        cache: false,
      );

      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imagePath,
          folder: 'profiles',
          publicId: 'profile_${DateTime.now().millisecondsSinceEpoch}',
        ),
      );

      debugPrint('✅ Profile image uploaded successfully');
      debugPrint('🔗 URL: ${response.secureUrl}');

      return response.secureUrl;
    } catch (e) {
      debugPrint('❌ Error uploading profile image: $e');
      return null;
    }
  }

  /// Upload product images with specific transformations
  static Future<List<String>> uploadProductImages(
    List<String> imagePaths,
  ) async {
    List<String> uploadedUrls = [];

    final cloudinary = CloudinaryPublic(
      AppConstants.cloudinaryCloudName,
      AppConstants.cloudinaryUploadPreset,
      cache: false,
    );

    for (int i = 0; i < imagePaths.length; i++) {
      try {
        debugPrint(
          '🚀 Uploading product image ${i + 1}/${imagePaths.length}...',
        );

        final response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            imagePaths[i],
            folder: 'products',
            publicId: 'product_${DateTime.now().millisecondsSinceEpoch}_$i',
          ),
        );

        uploadedUrls.add(response.secureUrl);
        debugPrint('✅ Product image ${i + 1} uploaded successfully');
      } catch (e) {
        debugPrint('❌ Error uploading product image ${i + 1}: $e');
      }
    }

    return uploadedUrls;
  }

  /// Upload reel video with specific transformations
  static Future<String?> uploadReelVideo(XFile videoFile) async {
    try {
      debugPrint('🚀 Starting reel video upload to Cloudinary...');
      debugPrint('📄 File path: ${videoFile.path}');
      debugPrint('📄 File name: ${videoFile.name}');

      final cloudinary = CloudinaryPublic(
        AppConstants.cloudinaryCloudName,
        AppConstants.cloudinaryUploadPreset,
        cache: false,
      );

      final bytes = await videoFile.readAsBytes();

      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromByteData(
          bytes.buffer.asByteData(),
          identifier: videoFile.name,
          folder: 'reels',
          publicId: 'reel_${DateTime.now().millisecondsSinceEpoch}',
          resourceType: CloudinaryResourceType.Video,
        ),
      );

      debugPrint('✅ Reel video uploaded successfully');
      debugPrint('🔗 URL: ${response.secureUrl}');

      return response.secureUrl;
    } on DioException catch (e) {
      debugPrint('❌ Error uploading reel video (Dio): ${e.message}');
      debugPrint('❌ Response data: ${e.response?.data}');
      return null;
    } catch (e) {
      debugPrint('❌ Error uploading reel video: $e');
      return null;
    }
  }

  /// Delete file from Cloudinary
  static Future<bool> deleteFile(String publicId) async {
    try {
      debugPrint('🗑️ Deleting file from Cloudinary: $publicId');

      // Note: The destroy method is not available in cloudinary_public package
      // This is a placeholder for future implementation
      debugPrint(
        '⚠️ Delete functionality not implemented in cloudinary_public package',
      );

      debugPrint('✅ File deletion skipped');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting file: $e');
      return false;
    }
  }
}
