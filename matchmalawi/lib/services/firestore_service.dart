import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/like_model.dart';
import '../models/match_model.dart';
import '../models/message_model.dart';
import '../models/report_model.dart';
import '../models/notification_model.dart';
import '../models/subscription_model.dart';

class FirestoreService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // ─── USERS ─────────────────────────────────────────────
  CollectionReference get _users => _firestore.collection('users');
  CollectionReference get _likes => _firestore.collection('likes');
  CollectionReference get _matches => _firestore.collection('matches');
  CollectionReference get _messages => _firestore.collection('messages');
  CollectionReference get _reports => _firestore.collection('reports');
  CollectionReference get _notifications => _firestore.collection('notifications');
  CollectionReference get _subscriptions => _firestore.collection('subscriptions');

  Future<void> createUser(UserModel user) async {
    await _users.doc(user.id).set(user.toFirestore());
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _users.doc(userId).update(data);
  }

  Future<UserModel?> getUser(String userId) async {
    final doc = await _users.doc(userId).get();
    if (doc.exists) return UserModel.fromFirestore(doc);
    return null;
  }

  Future<List<UserModel>> getUsersByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final snapshot = await _users.where(FieldPath.documentId, whereIn: ids).get();
    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  Stream<UserModel?> userStream(String userId) {
    return _users.doc(userId).snapshots().map((doc) {
      if (doc.exists) return UserModel.fromFirestore(doc);
      return null;
    });
  }

  // ─── DISCOVERY / SWIPE ─────────────────────────────────
  Future<List<UserModel>> getDiscoveryUsers({
    required String currentUserId,
    required String gender,
    required int minAge,
    required int maxAge,
    required String district,
    int limit = 20,
  }) async {
    Query query = _users
        .where('gender', isEqualTo: gender)
        .where('age', isGreaterThanOrEqualTo: minAge)
        .where('age', isLessThanOrEqualTo: maxAge)
        .where('banned', isEqualTo: false)
        .where('blocked', isEqualTo: false)
        .limit(limit * 2);

    if (district != 'Anywhere in Malawi') {
      query = query.where('district', isEqualTo: district);
    }

    final snapshot = await query.get();
    final users = snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .where((u) => u.id != currentUserId)
        .toList();

    final likedIds = await _getLikedUserIds(currentUserId);
    final blockedIds = await _getBlockedUserIds(currentUserId);

    return users
        .where((u) => !likedIds.contains(u.id) && !blockedIds.contains(u.id))
        .take(limit)
        .toList();
  }

  Future<List<String>> _getLikedUserIds(String userId) async {
    final snapshot = await _likes.where('sender', isEqualTo: userId).get();
    return snapshot.docs.map((doc) => doc['receiver'] as String).toList();
  }

  Future<List<String>> _getBlockedUserIds(String userId) async {
    final blockedByMe = await _reports
        .where('reportedBy', isEqualTo: userId)
        .where('reason', isEqualTo: 'block')
        .get();
    final iAmBlockedBy = await _reports
        .where('reportedUser', isEqualTo: userId)
        .where('reason', isEqualTo: 'block')
        .get();
    final ids = <String>{};
    for (final doc in blockedByMe.docs) {
      ids.add(doc['reportedUser'] as String);
    }
    for (final doc in iAmBlockedBy.docs) {
      ids.add(doc['reportedBy'] as String);
    }
    return ids.toList();
  }

  // ─── LIKES ─────────────────────────────────────────────
  Future<void> addLike(LikeModel like) async {
    await _likes.doc(like.id).set(like.toFirestore());
  }

  Future<bool> hasLiked(String senderId, String receiverId) async {
    final snapshot = await _likes
        .where('sender', isEqualTo: senderId)
        .where('receiver', isEqualTo: receiverId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // ─── MATCHES ───────────────────────────────────────────
  Future<MatchModel?> checkForMatch(String user1Id, String user2Id) async {
    final snapshot = await _matches
        .where('user1', isEqualTo: user1Id)
        .where('user2', isEqualTo: user2Id)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return MatchModel.fromFirestore(snapshot.docs.first);
    }

    final snapshot2 = await _matches
        .where('user1', isEqualTo: user2Id)
        .where('user2', isEqualTo: user1Id)
        .limit(1)
        .get();
    if (snapshot2.docs.isNotEmpty) {
      return MatchModel.fromFirestore(snapshot2.docs.first);
    }

    return null;
  }

  Future<MatchModel> createMatch(MatchModel match) async {
    final docRef = await _matches.add(match.toFirestore());
    return MatchModel(
      id: docRef.id,
      user1Id: match.user1Id,
      user2Id: match.user2Id,
      date: match.date,
    );
  }

  Stream<List<MatchModel>> getMatches(String userId) {
    final query1 = _matches.where('user1', isEqualTo: userId);
    final query2 = _matches.where('user2', isEqualTo: userId);

    return query1.snapshots().asyncExpand((snap1) {
      return query2.snapshots().map((snap2) {
        final allDocs = [...snap1.docs, ...snap2.docs];
        return allDocs
            .map((doc) => MatchModel.fromFirestore(doc))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
      });
    });
  }

  // ─── MESSAGES ──────────────────────────────────────────
  Future<void> sendMessage(MessageModel message) async {
    await _messages.doc(message.id).set(message.toFirestore());
    await _matches.doc(message.matchId).update({
      'lastMessage': message.message,
      'lastMessageTime': message.time,
    });
  }

  Stream<List<MessageModel>> getMessages(String matchId) {
    return _messages
        .where('matchId', isEqualTo: matchId)
        .orderBy('time', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList());
  }

  Future<void> markMessagesAsRead(String matchId, String currentUserId) async {
    final snapshot = await _messages
        .where('matchId', isEqualTo: matchId)
        .where('read', isEqualTo: false)
        .get();
    for (final doc in snapshot.docs) {
      if (doc['sender'] != currentUserId) {
        await doc.reference.update({'read': true});
      }
    }
  }

  // ─── CHAT LIST ─────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getChatList(String userId) async {
    final matchSnapshot = await _matches
        .where('user1', isEqualTo: userId)
        .get();
    final matchSnapshot2 = await _matches
        .where('user2', isEqualTo: userId)
        .get();

    final allMatches = [...matchSnapshot.docs, ...matchSnapshot2.docs]
        .map((doc) => MatchModel.fromFirestore(doc))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final chatList = <Map<String, dynamic>>[];
    for (final match in allMatches) {
      final otherUserId = match.getOtherUserId(userId);
      final otherUser = await getUser(otherUserId);
      if (otherUser == null) continue;

      final lastMsg = await _messages
          .where('matchId', isEqualTo: match.id)
          .orderBy('time', descending: true)
          .limit(1)
          .get();

      final unreadCount = await _messages
          .where('matchId', isEqualTo: match.id)
          .where('read', isEqualTo: false)
          .get();

      chatList.add({
        'match': match,
        'user': otherUser,
        'lastMessage': lastMsg.docs.isNotEmpty
            ? MessageModel.fromFirestore(lastMsg.docs.first)
            : null,
        'unreadCount': unreadCount.docs
            .where((d) => d['sender'] != userId)
            .length,
      });
    }

    return chatList;
  }

  // ─── REPORTS ───────────────────────────────────────────
  Future<void> reportUser(ReportModel report) async {
    await _reports.doc(report.id).set(report.toFirestore());
  }

  Future<void> blockUser(String reporterId, String blockedId) async {
    await _reports.add({
      'reportedBy': reporterId,
      'reportedUser': blockedId,
      'reason': 'block',
      'date': FieldValue.serverTimestamp(),
      'status': 'active',
    });
  }

  // ─── NOTIFICATIONS ─────────────────────────────────────
  Future<void> addNotification(AppNotification notification) async {
    await _notifications.doc(notification.id).set(notification.toFirestore());
  }

  Stream<List<AppNotification>> getNotifications(String userId) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromFirestore(doc))
            .toList());
  }

  Future<int> getUnreadNotificationCount(String userId) async {
    final snapshot = await _notifications
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();
    return snapshot.docs.length;
  }

  // ─── SUBSCRIPTIONS ─────────────────────────────────────
  Future<void> createSubscription(SubscriptionModel sub) async {
    await _subscriptions.doc(sub.id).set(sub.toFirestore());
    await _users.doc(sub.userId).update({
      'premium': true,
      'premiumPlan': sub.plan,
      'premiumExpiry': sub.expiry,
    });
  }

  Future<SubscriptionModel?> getActiveSubscription(String userId) async {
    final snapshot = await _subscriptions
        .where('userId', isEqualTo: userId)
        .where('active', isEqualTo: true)
        .orderBy('expiry', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return SubscriptionModel.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  // ─── ADMIN ─────────────────────────────────────────────
  Future<List<UserModel>> getAllUsers({int limit = 50}) async {
    final snapshot = await _users.limit(limit).get();
    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  Future<List<ReportModel>> getAllReports({String? status}) async {
    Query query = _reports.orderBy('date', descending: true);
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    final snapshot = await query.limit(100).get();
    return snapshot.docs.map((doc) => ReportModel.fromFirestore(doc)).toList();
  }

  Future<void> banUser(String userId) async {
    await _users.doc(userId).update({'banned': true});
  }

  Future<void> unbanUser(String userId) async {
    await _users.doc(userId).update({'banned': false});
  }

  Future<void> verifyUser(String userId) async {
    await _users.doc(userId).update({'verified': true});
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final usersSnap = await _users.count().get();
    final matchesSnap = await _matches.count().get();
    final messagesSnap = await _messages.count().get();
    final reportsSnap = await _reports.where('status', isEqualTo: 'pending').count().get();

    return {
      'totalUsers': usersSnap.count,
      'totalMatches': matchesSnap.count,
      'totalMessages': messagesSnap.count,
      'pendingReports': reportsSnap.count,
    };
  }
}
