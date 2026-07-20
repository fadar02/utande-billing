import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/like_model.dart';
import '../models/match_model.dart';
import '../models/message_model.dart';
import '../models/report_model.dart';
import '../models/notification_model.dart';
import '../models/subscription_model.dart';
import '../models/story_model.dart';
import '../models/post_model.dart';
import '../models/reel_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/matching_service.dart';
import '../services/social_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
// AUTH PROVIDER
// ══════════════════════════════════════════════════════════════════════════════

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();
  final StorageService _storageService = StorageService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  String? _verificationId;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _authService.currentUser != null;
  String? get userId => _authService.currentUser?.uid;
  UserModel? get currentUser => _user;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final authUser = _authService.currentUser;
      if (authUser != null) {
        await _loadUser(authUser.uid);
        try {
          await _notificationService.saveToken(authUser.uid);
        } catch (_) {}
        try {
          await _authService.updateOnlineStatus(true);
        } catch (_) {}
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadUser(String userId) async {
    _user = await _firestoreService.getUser(userId);
    notifyListeners();
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.signInWithEmail(email, password);
      await _loadUser(result.user!.uid);
      await _notificationService.saveToken(result.user!.uid);
      await _authService.updateOnlineStatus(true);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.signUpWithEmail(email, password);
      final user = UserModel(
        id: result.user!.uid,
        name: name,
        age: 0,
        gender: '',
        district: '',
        occupation: '',
        education: '',
        email: email,
        phoneNumber: result.user!.phoneNumber,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _firestoreService.createUser(user);
      _user = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> sendOTP({
    required String phoneNumber,
    required Function onCompleted,
    required Function onError,
    required Function onCodeSent,
    required Function onTimeout,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await _authService.sendOTP(
      phoneNumber,
      (credential) async {
        final authUser = _authService.currentUser;
        if (authUser != null) {
          await _loadUser(authUser.uid);
          await _notificationService.saveToken(authUser.uid);
          await _authService.updateOnlineStatus(true);
        }
        _isLoading = false;
        notifyListeners();
        onCompleted();
      },
      (error) {
        _error = 'Phone verification failed. Please try again.';
        _isLoading = false;
        notifyListeners();
        onError();
      },
      (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _isLoading = false;
        notifyListeners();
        onCodeSent();
      },
      (String verificationId) {
        _verificationId = verificationId;
        onTimeout();
      },
    );
  }

  Future<bool> verifyOTP(String otp) async {
    if (_verificationId == null) {
      _error = 'No verification ID. Please request a new code.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.verifyOTP(_verificationId!, otp);
      await _loadUser(result.user!.uid);
      await _notificationService.saveToken(result.user!.uid);
      await _authService.updateOnlineStatus(true);
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _error = 'Invalid OTP. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (_user == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestoreService.updateUser(_user!.id, data);
      await _loadUser(_user!.id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadPhotos(List<File> photos) async {
    if (_user == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final urls = await _storageService.uploadMultiplePhotos(
        userId: _user!.id,
        imageFiles: photos,
      );
      final allPhotos = [..._user!.photos, ...urls];
      await _firestoreService.updateUser(_user!.id, {'photos': allPhotos});
      await _loadUser(_user!.id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _error = null;
    _verificationId = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DISCOVERY PROVIDER
// ══════════════════════════════════════════════════════════════════════════════

class DiscoveryProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final MatchingService _matchingService;

  List<UserModel> _users = [];
  int _currentIndex = 0;
  bool _isLoading = false;
  MatchResult? _lastResult;
  UserModel? _matchedUser;
  final List<int> _rewindStack = [];
  UserModel? _currentUser;

  DiscoveryProvider(this._matchingService);

  List<UserModel> get users => _users;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  MatchResult? get lastResult => _lastResult;
  UserModel? get matchedUser => _matchedUser;
  bool get hasMoreUsers => _currentIndex < _users.length;
  UserModel? get currentUser => _currentUser;

  void setCurrentUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> loadUsers(UserModel currentUser) async {
    _isLoading = true;
    notifyListeners();

    final genderFilter = currentUser.lookingFor;
    final minAge = int.tryParse(currentUser.ageRangeMin ?? '18') ?? 18;
    final maxAge = int.tryParse(currentUser.ageRangeMax ?? '60') ?? 60;
    final district = currentUser.district.isNotEmpty ? currentUser.district : 'Anywhere in Malawi';

    _users = await _firestoreService.getDiscoveryUsers(
      currentUserId: currentUser.id,
      gender: genderFilter,
      minAge: minAge,
      maxAge: maxAge,
      district: district,
    );

    _currentIndex = 0;
    _rewindStack.clear();
    _lastResult = null;
    _matchedUser = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> like(UserModel currentUser) async {
    if (!hasMoreUsers) return;

    final targetUser = _users[_currentIndex];
    _rewindStack.add(_currentIndex);

    _lastResult = await _matchingService.handleLike(
      senderId: currentUser.id,
      receiverId: targetUser.id,
      isSuperLike: false,
    );

    if (_lastResult == MatchResult.newMatch) {
      _matchedUser = targetUser;
    }

    _currentIndex++;
    notifyListeners();
  }

  Future<void> superLike(UserModel currentUser) async {
    if (!hasMoreUsers) return;

    final targetUser = _users[_currentIndex];
    _rewindStack.add(_currentIndex);

    _lastResult = await _matchingService.handleLike(
      senderId: currentUser.id,
      receiverId: targetUser.id,
      isSuperLike: true,
    );

    if (_lastResult == MatchResult.newMatch) {
      _matchedUser = targetUser;
    }

    _currentIndex++;
    notifyListeners();
  }

  void pass() {
    if (!hasMoreUsers) return;

    _rewindStack.add(_currentIndex);
    _currentIndex++;
    _lastResult = null;
    notifyListeners();
  }

  void rewind() {
    if (_rewindStack.isNotEmpty) {
      _currentIndex = _rewindStack.removeLast();
      _lastResult = null;
      notifyListeners();
    }
  }

  void clearMatchResult() {
    _lastResult = null;
    _matchedUser = null;
    notifyListeners();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CHAT PROVIDER
// ══════════════════════════════════════════════════════════════════════════════

class ChatProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final _uuid = const Uuid();

  StreamSubscription? _chatListSubscription;
  StreamSubscription? _messagesSubscription;

  List<Map<String, dynamic>> _chatList = [];
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _isLoadingMessages = false;
  bool _isTyping = false;

  ChatProvider(this._firestoreService);

  List<Map<String, dynamic>> get chatList => _chatList;
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isTyping => _isTyping;

  void loadChatList(String userId) {
    _isLoading = true;
    notifyListeners();

    _chatListSubscription?.cancel();
    _chatListSubscription =
        _firestoreService.getMatches(userId).listen((matches) async {
      try {
        _chatList = await _firestoreService.getChatList(userId);
      } catch (_) {
        _chatList = [];
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  void loadMessages(String matchId) {
    _isLoadingMessages = true;
    notifyListeners();

    _messagesSubscription?.cancel();
    _messagesSubscription =
        _firestoreService.getMessages(matchId).listen((messages) {
      _messages = messages;
      _isLoadingMessages = false;
      notifyListeners();
    });
  }

  Future<void> sendMessage({
    required String matchId,
    required String senderId,
    required String message,
    MessageType type = MessageType.text,
    String? imageUrl,
  }) async {
    final msg = MessageModel(
      id: _uuid.v4(),
      matchId: matchId,
      senderId: senderId,
      message: message,
      type: type,
      time: DateTime.now(),
      imageUrl: imageUrl,
    );
    await _firestoreService.sendMessage(msg);
  }

  Future<void> sendPhotoMessage({
    required String matchId,
    required String senderId,
    required File imageFile,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final storageService = StorageService();
      final imageUrl = await storageService.uploadChatImage(
        matchId: matchId,
        imageFile: imageFile,
      );
      await sendMessage(
        matchId: matchId,
        senderId: senderId,
        message: 'Photo',
        type: MessageType.image,
        imageUrl: imageUrl,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String matchId, String currentUserId) async {
    await _firestoreService.markMessagesAsRead(matchId, currentUserId);
  }

  void setTyping(bool typing) {
    _isTyping = typing;
    notifyListeners();
  }

  @override
  void dispose() {
    _chatListSubscription?.cancel();
    _messagesSubscription?.cancel();
    super.dispose();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SAFETY PROVIDER
// ══════════════════════════════════════════════════════════════════════════════

class SafetyProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;

  SafetyProvider(this._firestoreService);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    String? description,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService.reportUser(
        ReportModel(
          id: const Uuid().v4(),
          reportedBy: reporterId,
          reportedUser: reportedUserId,
          reason: reason,
          description: description,
          date: DateTime.now(),
        ),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> blockUser(String reporterId, String blockedId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService.blockUser(reporterId, blockedId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> unblockUser(String reporterId, String blockedId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('reports')
          .where('reportedBy', isEqualTo: reporterId)
          .where('reportedUser', isEqualTo: blockedId)
          .where('reason', isEqualTo: 'block')
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// NOTIFICATION PROVIDER
// ══════════════════════════════════════════════════════════════════════════════

class NotificationProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;

  StreamSubscription? _notificationsSubscription;

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  NotificationProvider(this._firestoreService);

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  void loadNotifications(String userId) {
    _notificationsSubscription?.cancel();
    _notificationsSubscription =
        _firestoreService.getNotifications(userId).listen((notifications) {
      _notifications = notifications;
      _unreadCount = notifications.where((n) => !n.read).length;
      notifyListeners();
    });
  }

  Future<void> markAsRead(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});

    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      final old = _notifications[index];
      _notifications[index] = AppNotification(
        id: old.id,
        userId: old.userId,
        title: old.title,
        message: old.message,
        read: true,
        createdAt: old.createdAt,
        type: old.type,
        referenceId: old.referenceId,
      );
      _unreadCount = _notifications.where((n) => !n.read).length;
      notifyListeners();
    }
  }

  Future<void> markAllAsRead(String userId) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final notification in _notifications.where((n) => !n.read)) {
      final docRef = FirebaseFirestore.instance
          .collection('notifications')
          .doc(notification.id);
      batch.update(docRef, {'read': true});
    }
    await batch.commit();

    _notifications = _notifications
        .map((n) => AppNotification(
              id: n.id,
              userId: n.userId,
              title: n.title,
              message: n.message,
              read: true,
              createdAt: n.createdAt,
              type: n.type,
              referenceId: n.referenceId,
            ))
        .toList();
    _unreadCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SOCIAL PROVIDER
// ══════════════════════════════════════════════════════════════════════════════

class SocialProvider extends ChangeNotifier {
  final SocialService _socialService;
  final StorageService _storageService;
  final _uuid = const Uuid();

  SocialProvider(this._socialService, this._storageService);

  StreamSubscription? _storiesSubscription;
  StreamSubscription? _postsSubscription;
  StreamSubscription? _reelsSubscription;

  List<StoryModel> _stories = [];
  List<PostModel> _posts = [];
  List<ReelModel> _reels = [];
  List<Map<String, dynamic>> _exploreItems = [];
  bool _isLoading = false;

  List<StoryModel> get stories => _stories;
  List<PostModel> get posts => _posts;
  List<ReelModel> get reels => _reels;
  List<Map<String, dynamic>> get exploreItems => _exploreItems;
  bool get isLoading => _isLoading;

  // ─── STORIES ─────────────────────────────────────────────────────────────

  void loadStories(List<String> userIds) {
    _storiesSubscription?.cancel();
    _storiesSubscription =
        _socialService.getStories(userIds).listen((stories) {
      _stories = stories;
      notifyListeners();
    });
  }

  Future<void> createStory({
    required String userId,
    required File mediaFile,
    String? caption,
    StoryType type = StoryType.image,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final ext = mediaFile.path.split('.').last;
      final fileName = '${userId}_${_uuid.v4()}.$ext';
      final ref =
          FirebaseStorage.instance.ref().child('stories/$userId/$fileName');
      await ref.putFile(mediaFile);
      final mediaUrl = await ref.getDownloadURL();

      final story = StoryModel(
        id: _uuid.v4(),
        userId: userId,
        mediaUrl: mediaUrl,
        caption: caption,
        type: type,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );

      await _socialService.createStory(story);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> viewStory(String storyId, String userId) async {
    await _socialService.viewStory(storyId, userId);
  }

  // ─── FEED / POSTS ───────────────────────────────────────────────────────

  void loadFeed() {
    _postsSubscription?.cancel();
    _postsSubscription = _socialService.getFeedPosts().listen((posts) {
      _posts = posts;
      notifyListeners();
    });
  }

  Future<void> createPost({
    required String userId,
    required List<File> mediaFiles,
    String? caption,
    String? location,
    List<String>? tags,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final mediaUrls = <String>[];
      for (final file in mediaFiles) {
        final ext = file.path.split('.').last;
        final fileName = '${userId}_${_uuid.v4()}.$ext';
        final ref =
            FirebaseStorage.instance.ref().child('posts/$userId/$fileName');
        await ref.putFile(file);
        final url = await ref.getDownloadURL();
        mediaUrls.add(url);
      }

      final post = PostModel(
        id: _uuid.v4(),
        userId: userId,
        mediaUrls: mediaUrls,
        caption: caption ?? '',
        createdAt: DateTime.now(),
        location: location,
        tags: tags ?? [],
      );

      await _socialService.createPost(post);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleLikePost(String postId, String userId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    if (_posts[index].isLikedBy(userId)) {
      await _socialService.unlikePost(postId, userId);
    } else {
      await _socialService.likePost(postId, userId);
    }
    notifyListeners();
  }

  Future<void> addComment(String postId, String userId, String text) async {
    final comment = CommentModel(
      id: _uuid.v4(),
      userId: userId,
      text: text,
      createdAt: DateTime.now(),
    );
    await _socialService.addComment(postId, comment);
    notifyListeners();
  }

  Future<void> deletePost(String postId) async {
    await _socialService.deletePost(postId);
  }

  // ─── REELS ──────────────────────────────────────────────────────────────

  void loadReels() {
    _reelsSubscription?.cancel();
    _reelsSubscription = _socialService.getReels().listen((reels) {
      _reels = reels;
      notifyListeners();
    });
  }

  Future<void> createReel({
    required String userId,
    required File videoFile,
    String? caption,
    String? audio,
    List<String>? tags,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final ext = videoFile.path.split('.').last;
      final fileName = '${userId}_${_uuid.v4()}.$ext';
      final ref =
          FirebaseStorage.instance.ref().child('reels/$userId/$fileName');
      await ref.putFile(videoFile);
      final videoUrl = await ref.getDownloadURL();

      final reel = ReelModel(
        id: _uuid.v4(),
        userId: userId,
        videoUrl: videoUrl,
        caption: caption ?? '',
        createdAt: DateTime.now(),
        audio: audio,
        tags: tags ?? [],
      );

      await _socialService.createReel(reel);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleLikeReel(String reelId, String userId) async {
    final index = _reels.indexWhere((r) => r.id == reelId);
    if (index == -1) return;

    if (_reels[index].isLikedBy(userId)) {
      await _socialService.unlikeReel(reelId, userId);
    } else {
      await _socialService.likeReel(reelId, userId);
    }
    notifyListeners();
  }

  // ─── EXPLORE ────────────────────────────────────────────────────────────

  Future<void> loadExplore(String district) async {
    _isLoading = true;
    notifyListeners();

    _exploreItems = await _socialService.getExploreData(district: district);

    _isLoading = false;
    notifyListeners();
  }

  // ─── CLEANUP ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _storiesSubscription?.cancel();
    _postsSubscription?.cancel();
    _reelsSubscription?.cancel();
    super.dispose();
  }
}
