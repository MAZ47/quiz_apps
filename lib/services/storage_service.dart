import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _firebaseStorage;

  StorageService({FirebaseStorage? firebaseStorage})
      : _firebaseStorage = firebaseStorage ?? FirebaseStorage.instance;

  /// ফায়ারবেস ক্লাউড স্টোরেজে ফাইল আপলোড করে ডাউনলোড URL রিটার্ন করা
  Future<String> uploadFile(String path, File file) async {
    final ref = _firebaseStorage.ref().child(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }
}