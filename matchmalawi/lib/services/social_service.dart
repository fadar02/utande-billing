import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/story_model.dart';
import '../models/post_model.dart';
import '../models/reel_model.dart';

class SocialService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference get _stories => _firestore.collection('stories');
  CollectionReference get _posts => _firestore.collection('posts');
  CollectionReference get _reels => _firestore.collection('reels');

  // ─── STORIES ───────────────────────────────────────────
  Future<void> createStory(StoryModel story) async {
    await _stories.doc(story.id).set(story.toFirestore());
  }

  Stream<List<StoryModel>> getStories(List<String> userIds) {
    return _stories
        .where('userId', whereIn: userIds.isEmpty ? ['__none__'] : userIds)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      final stories = snap.docs
          .map((doc) => StoryModel.fromFirestore(doc))
          .where((s) => !s.isExpired)
          .toList();
      return stories;
    });
  }

  Future<void> viewStory(String storyId, String userId) async {
    await _stories.doc(storyId).update({
      'viewers': FieldValue.arrayUnion([userId]),
      'viewCount': FieldValue.increment(1),
    });
  }

  Future<void> deleteStory(String storyId) async {
    await _stories.doc(storyId).delete();
  }

  // ─── POSTS / FEED ──────────────────────────────────────
  Future<void> createPost(PostModel post) async {
    await _posts.doc(post.id).set(post.toFirestore());
  }

  Stream<List<PostModel>> getFeedPosts({int limit = 20}) {
    return _posts
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PostModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<PostModel>> getUserPosts(String userId) {
    return _posts
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PostModel.fromFirestore(doc))
            .toList());
  }

  Future<void> likePost(String postId, String userId) async {
    await _posts.doc(postId).update({
      'likes': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> unlikePost(String postId, String userId) async {
    await _posts.doc(postId).update({
      'likes': FieldValue.arrayRemove([userId]),
    });
  }

  Future<void> addComment(String postId, CommentModel comment) async {
    await _posts.doc(postId).update({
      'comments': FieldValue.arrayUnion([comment.toMap()]),
    });
  }

  Future<void> deletePost(String postId) async {
    await _posts.doc(postId).delete();
  }

  // ─── REELS ─────────────────────────────────────────────
  Future<void> createReel(ReelModel reel) async {
    await _reels.doc(reel.id).set(reel.toFirestore());
  }

  Stream<List<ReelModel>> getReels({int limit = 30}) {
    return _reels
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ReelModel.fromFirestore(doc))
            .toList());
  }

  Future<void> likeReel(String reelId, String userId) async {
    await _reels.doc(reelId).update({
      'likes': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> unlikeReel(String reelId, String userId) async {
    await _reels.doc(reelId).update({
      'likes': FieldValue.arrayRemove([userId]),
    });
  }

  Future<void> incrementReelViews(String reelId) async {
    await _reels.doc(reelId).update({
      'viewCount': FieldValue.increment(1),
    });
  }

  Future<void> deleteReel(String reelId) async {
    await _reels.doc(reelId).delete();
  }

  // ─── EXPLORE ───────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getExploreData({
    required String district,
    int limit = 20,
  }) async {
    final results = <Map<String, dynamic>>[];

    final trendingPosts = await _posts
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    for (final doc in trendingPosts.docs) {
      results.add({
        'type': 'post',
        'data': PostModel.fromFirestore(doc),
      });
    }

    final trendingReels = await _reels
        .orderBy('viewCount', descending: true)
        .limit(limit ~/ 2)
        .get();

    for (final doc in trendingReels.docs) {
      results.add({
        'type': 'reel',
        'data': ReelModel.fromFirestore(doc),
      });
    }

    return results;
  }
}
