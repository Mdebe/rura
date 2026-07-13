import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  static final cloudinary = CloudinaryPublic(
    'k03hka2f', // REPLACE: from Cloudinary dashboard
    'georura_unsigned', // REPLACE: your preset name
    cache: false,
  );

  static Future<String?> uploadImage(File imageFile, String s) async {
    try {
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'georura/sites',
        ),
      );

      print('Cloudinary URL: ${response.secureUrl}');
      return response.secureUrl; // https://res.cloudinary.com/...
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }
}
