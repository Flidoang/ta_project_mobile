// Lokasi: lib/service/cloudinary_service.dart (BARU)

import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class ImageUploadService {
  // Buat instance Cloudinary dengan kredensial Anda
  static final CloudinaryPublic _cloudinary = CloudinaryPublic(
    'dk2yqgmqr', // Cloud Name
    'oofv0suk', // Upload Preset (dijelaskan di bawah)
    cache: false,
  );

  static Future<String?> uploadImage(File imageFile) async {
    try {
      // Buat request upload
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      // Kembalikan URL yang aman (secure_url)
      print('Upload ke Cloudinary berhasil. URL: ${response.secureUrl}');
      return response.secureUrl;
    } on CloudinaryException catch (e) {
      print('Error uploading to Cloudinary: ${e.message}');
      return null;
    }
  }
}
