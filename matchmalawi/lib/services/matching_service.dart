import 'package:uuid/uuid.dart';
import '../models/like_model.dart';
import '../models/match_model.dart';
import '../models/notification_model.dart';
import 'firestore_service.dart';

class MatchingService {
  final FirestoreService _firestoreService;
  final _uuid = const Uuid();

  MatchingService(this._firestoreService);

  Future<MatchResult> handleLike({
    required String senderId,
    required String receiverId,
    required bool isSuperLike,
  }) async {
    final alreadyLiked = await _firestoreService.hasLiked(senderId, receiverId);
    if (alreadyLiked) return MatchResult.alreadyLiked;

    final like = LikeModel(
      id: _uuid.v4(),
      senderId: senderId,
      receiverId: receiverId,
      isSuperLike: isSuperLike,
      date: DateTime.now(),
    );
    await _firestoreService.addLike(like);

    final receiverLikedSender = await _firestoreService.hasLiked(receiverId, senderId);

    if (receiverLikedSender) {
      final existingMatch = await _firestoreService.checkForMatch(senderId, receiverId);
      if (existingMatch != null) return MatchResult.alreadyMatched;

      final match = MatchModel(
        id: _uuid.v4(),
        user1Id: senderId,
        user2Id: receiverId,
        date: DateTime.now(),
      );
      final createdMatch = await _firestoreService.createMatch(match);

      final sender = await _firestoreService.getUser(senderId);
      final receiver = await _firestoreService.getUser(receiverId);

      if (receiver != null) {
        await _firestoreService.addNotification(AppNotification(
          id: _uuid.v4(),
          userId: receiverId,
          title: "It's a Match! 🎉",
          message: 'You and ${sender?.name ?? "someone"} liked each other!',
          createdAt: DateTime.now(),
          type: 'match',
          referenceId: createdMatch.id,
        ));
      }
      if (sender != null) {
        await _firestoreService.addNotification(AppNotification(
          id: _uuid.v4(),
          userId: senderId,
          title: "It's a Match! 🎉",
          message: 'You and ${receiver?.name ?? "someone"} liked each other!',
          createdAt: DateTime.now(),
          type: 'match',
          referenceId: createdMatch.id,
        ));
      }

      return MatchResult.newMatch;
    }

    final receiver = await _firestoreService.getUser(receiverId);
    if (receiver != null && isSuperLike) {
      await _firestoreService.addNotification(AppNotification(
        id: _uuid.v4(),
        userId: receiverId,
        title: 'Super Like! ⭐',
        message: 'Someone super liked you!',
        createdAt: DateTime.now(),
        type: 'super_like',
      ));
    }

    return MatchResult.liked;
  }

  Future<void> handlePass({
    required String senderId,
    required String receiverId,
  }) async {
    // Pass - do nothing, the user is filtered out in discovery
  }
}

enum MatchResult {
  liked,
  newMatch,
  alreadyLiked,
  alreadyMatched,
}
