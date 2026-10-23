import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadListingImage(File imageFile, String sellerId) async {
    final fileName =
        'listings/${sellerId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child(fileName);
    final uploadTask = await ref.putFile(imageFile);
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    return downloadUrl;
  }
}
