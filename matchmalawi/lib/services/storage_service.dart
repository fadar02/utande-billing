import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  FirebaseStorage get _storage => FirebaseStorage.instance;
  final _uuid = const Uuid();

  Future<String> uploadProfilePhoto({
    required String userId,
    required File imageFile,
    int? photoIndex,
  }) async {
    final ext = imageFile.path.split('.').last;
    final fileName = photoIndex != null
        ? '${userId}_photo_$photoIndex.$ext'
        : '${userId}_${_uuid.v4()}.$ext';
    final ref = _storage.ref().child('profile_photos/$userId/$fileName');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<List<String>> uploadMultiplePhotos({
    required String userId,
    required List<File> imageFiles,
  }) async {
    final urls = <String>[];
    for (int i = 0; i < imageFiles.length; i++) {
      final url = await uploadProfilePhoto(
        userId: userId,
        imageFile: imageFiles[i],
        photoIndex: i,
      );
      urls.add(url);
    }
    return urls;
  }

  Future<String> uploadVideo({
    required String userId,
    required File videoFile,
  }) async {
    final ext = videoFile.path.split('.').last;
    final fileName = '${userId}_intro.${_uuid.v4()}.$ext';
    final ref = _storage.ref().child('videos/$userId/$fileName');
    await ref.putFile(videoFile);
    return await ref.getDownloadURL();
  }

  Future<String> uploadChatImage({
    required String matchId,
    required File imageFile,
  }) async {
    final ext = imageFile.path.split('.').last;
    final fileName = '${_uuid.v4()}.$ext';
    final ref = _storage.ref().child('chat_images/$matchId/$fileName');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<String> uploadVoiceMessage({
    required String matchId,
    required File voiceFile,
  }) async {
    final fileName = '${_uuid.v4()}.m4a';
    final ref = _storage.ref().child('voice_messages/$matchId/$fileName');
    await ref.putFile(voiceFile);
    return await ref.getDownloadURL();
  }

  Future<void> deleteFile(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {}
  }
}
