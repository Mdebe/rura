// lib/services/cloudinary_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  final Dio _dio = Dio();
  final String cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME']!;
  final String uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET']!;

  Future<String> uploadImage(String filePath) async {
    final file = File(filePath);
    final fileName = file.path.split('/').last;

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
      'upload_preset': uploadPreset,
      'folder': 'georura_sites',
    });

    final response = await _dio.post(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      data: formData,
    );

    if (response.statusCode == 200) {
      return response.data['secure_url']; // Return Cloudinary URL
    } else {
      throw Exception('Upload failed: ${response.statusMessage}');
    }
  }
}
