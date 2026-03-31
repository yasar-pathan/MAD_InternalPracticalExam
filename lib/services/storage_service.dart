import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  Future<List<String>> uploadListingImages(List<File> files) async {
    final listingId = _uuid.v4();
    final urls = <String>[];

    for (final file in files) {
      final filename = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = _storage.ref().child('listings/$listingId/$filename');
      await ref.putFile(file);
      urls.add(await ref.getDownloadURL());
    }

    return urls;
  }

  Future<void> deleteImage(String url) async {
    await _storage.refFromURL(url).delete();
  }

  Future<String> uploadUserAvatar(String uid, File file) async {
    final ref = _storage.ref().child('users/$uid/avatar.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}
