import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ImagePickerUtil {
  final ImagePicker _picker = ImagePicker();

  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];

  /// ক্যামেরা বা গ্যালারি থেকে ছবি নিয়ে সাইজ ও ফরম্যাট ভ্যালিডেশন করা
  Future<File?> pickImage({required ImageSource source}) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      final file = File(pickedFile.path);

      // ফাইল সাইজ চেক করা (সর্বোচ্চ ১০MB)
      final fileSize = await file.length();
      if (fileSize > maxFileSize) {
        throw Exception('File size exceeds the 10MB limit.');
      }

      // ফাইল ফরম্যাট সাপোর্ট চেক করা
      final extension = path.extension(file.path).toLowerCase();
      if (!allowedExtensions.contains(extension)) {
        throw Exception('Unsupported file format. Please use JPEG, PNG, or WEBP.');
      }

      return file;
    }
    return null;
  }
}