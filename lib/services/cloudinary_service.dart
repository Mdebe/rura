// ignore_for_file: avoid_print

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  final Dio _dio = Dio();
  final String cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME']!;
  final String uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET']!;

  Future<String> uploadImage(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    final fileName = file.path.split('/').last;

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
      'upload_preset': uploadPreset,
      'folder': 'georura_sites',
    });

    final response = await _dio.post(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      data: formData,
      options: Options(
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );

    if (response.statusCode == 200) {
      return response.data['secure_url'] as String;
    } else {
      throw Exception('Upload failed: ${response.statusMessage}');
    }
  }

  /// Upload multiple images and return list of Cloudinary URLs
  /// Continues even if individual uploads fail
  Future<List<String>> uploadMultipleImages(List<String> filePaths) async {
    final urls = <String>[];
    for (final path in filePaths) {
      try {
        final url = await uploadImage(path);
        urls.add(url);
      } catch (e) {
        // Log error but continue with other images
        print('Failed to upload $path: $e');
      }
    }
    return urls;
  }

  /// Upload with progress callback
  Future<String> uploadImageWithProgress(
    String filePath, {
    void Function(int sent, int total)? onProgress,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    final fileName = file.path.split('/').last;

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
      'upload_preset': uploadPreset,
      'folder': 'georura_sites',
    });

    final response = await _dio.post(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      data: formData,
      onSendProgress: onProgress,
      options: Options(
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );

    if (response.statusCode == 200) {
      return response.data['secure_url'] as String;
    } else {
      throw Exception('Upload failed: ${response.statusMessage}');
    }
  }
}
