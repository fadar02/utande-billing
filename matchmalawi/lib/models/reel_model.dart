import 'package:cloud_firestore/cloud_firestore.dart';

class ReelModel {
  final String id;
  final String userId;
  final String videoUrl;
  final String? thumbnailUrl;
  final String caption;
  final List<String> likes;
  final int commentCount;
  final int viewCount;
  final DateTime createdAt;
  final String? audio;
  final List<String> tags;

  ReelModel({
    required this.id,
    required this.userId,
    required this.videoUrl,
    this.thumbnailUrl,
    this.caption = '',
    this.likes = const [],
    this.commentCount = 0,
    this.viewCount = 0,
    required this.createdAt,
    this.audio,
    this.tags = const [],
  });

  factory ReelModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ReelModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      caption: data['caption'] ?? '',
      likes: List<String>.from(data['likes'] ?? []),
      commentCount: data['commentCount'] ?? 0,
      viewCount: data['viewCount'] ?? 0,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      audio: data['audio'],
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'caption': caption,
      'likes': likes,
      'commentCount': commentCount,
      'viewCount': viewCount,
      'createdAt': createdAt,
      'audio': audio,
      'tags': tags,
    };
  }

  bool isLikedBy(String userId) => likes.contains(userId);
}
