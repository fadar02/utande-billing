import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../models/user_model.dart';
import '../../models/message_model.dart';
import '../../screens/profile/user_profile_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();
  late AnimationController _typingAnimationController;
  bool _showSendButton = false;
  bool _isRecording = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _textController.addListener(() {
      final hasText = _textController.text.trim().isNotEmpty;
      if (hasText != _showSendButton) {
        setState(() {
          _showSendButton = hasText;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initChat();
    });
  }

  void _initChat() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) return;

    final matchId = args['matchId'] as String;
    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();

    chatProvider.loadMessages(matchId);
    final userId = authProvider.userId;
    if (userId != null) {
      chatProvider.markAsRead(matchId, userId);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingAnimationController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _sendTextMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) return;

    final matchId = args['matchId'] as String;
    final userId = context.read<AuthProvider>().userId ?? '';

    context.read<ChatProvider>().sendMessage(
          matchId: matchId,
          senderId: userId,
          message: text,
          type: MessageType.text,
        );

    _textController.clear();
    _focusNode.requestFocus();
    _scrollToBottom();
  }

  Future<void> _sendPhotoMessage({required ImageSource source}) async {
    final XFile? image = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1080,
      imageQuality: 80,
    );

    if (image != null) {
      if (!mounted) return;
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (!mounted) return;
      if (args == null) return;

      if (!mounted) return;
      final matchId = args['matchId'] as String;
      final userId = context.read<AuthProvider>().userId ?? '';

      if (!mounted) return;
      context.read<ChatProvider>().sendPhotoMessage(
            matchId: matchId,
            senderId: userId,
            imageFile: File(image.path),
          );

      _scrollToBottom();
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.photo,
                    label: 'Photo',
                    color: AppTheme.primaryColor,
                    onTap: () {
                      Navigator.pop(context);
                      _sendPhotoMessage(source: ImageSource.gallery);
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: AppTheme.accentColor,
                    onTap: () {
                      Navigator.pop(context);
                      _sendPhotoMessage(source: ImageSource.camera);
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.mic,
                    label: 'Voice',
                    color: AppTheme.successColor,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.location_on,
                    label: 'Location',
                    color: AppTheme.superLikeColor,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.emoji_emotions_outlined,
                    label: 'Sticker',
                    color: AppTheme.secondaryColor,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final otherUser = args['otherUser'] as UserModel? ?? UserModel(
      id: '', name: '', age: 0, gender: '', district: '',
      occupation: '', education: '', createdAt: DateTime.now(), updatedAt: DateTime.now(),
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(otherUser),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          _buildTypingIndicator(),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(UserModel otherUser) {
    return AppBar(
      backgroundColor: AppTheme.surfaceColor,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(
          Icons.arrow_back_ios,
          color: AppTheme.textPrimary,
          size: 22,
        ),
      ),
      titleSpacing: 0,
      title: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/user-profile', arguments: otherUser);
        },
        child: Row(
          children: [
            ProfileAvatar(
              imageUrl: otherUser.mainPhoto,
              radius: 18,
              isOnline: otherUser.online,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherUser.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    otherUser.online
                        ? 'Active now'
                        : 'Last seen ${timeago.format(otherUser.lastSeen ?? otherUser.updatedAt, locale: 'en_short')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: otherUser.online
                          ? AppTheme.successColor
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.videocam_outlined,
            color: AppTheme.textPrimary,
            size: 26,
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.pushNamed(context, '/user-profile', arguments: otherUser);
          },
          icon: const Icon(
            Icons.info_outline,
            color: AppTheme.textPrimary,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageList() {
    return Consumer2<AuthProvider, ChatProvider>(
      builder: (context, authProvider, chatProvider, child) {
        if (chatProvider.isLoadingMessages) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }

        final messages = chatProvider.messages;

        if (messages.isEmpty) {
          return _buildEmptyChat();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMe = message.senderId == authProvider.userId;
            final showTimeSeparator = index == 0 ||
                !_isSameDay(messages[index].time, messages[index - 1].time);
            final showAvatar = !isMe &&
                (index == messages.length - 1 ||
                    messages[index + 1].senderId != message.senderId);

            return Column(
              children: [
                if (showTimeSeparator) _buildTimeSeparator(message.time),
                _buildMessageBubble(
                  message: message,
                  isMe: isMe,
                  showAvatar: showAvatar,
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildTimeSeparator(DateTime time) {
    String text;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      text = 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      text = 'Yesterday';
    } else {
      text = '${time.day}/${time.month}/${time.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required MessageModel message,
    required bool isMe,
    required bool showAvatar,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ProfileAvatar(
                imageUrl: context.read<AuthProvider>().user?.mainPhoto,
                radius: 14,
              ),
            )
          else if (!isMe)
            const SizedBox(width: 34),
          Flexible(
            child: _buildBubbleContent(message, isMe),
          ),
        ],
      ),
    );
  }

  Widget _buildBubbleContent(MessageModel message, bool isMe) {
    switch (message.type) {
      case MessageType.image:
        return _buildImageMessage(message, isMe);
      case MessageType.voice:
        return _buildVoiceMessage(message, isMe);
      default:
        return _buildTextMessage(message, isMe);
    }
  }

  Widget _buildTextMessage(MessageModel message, bool isMe) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: isMe
            ? const LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isMe ? null : AppTheme.surfaceColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            message.message,
            style: TextStyle(
              fontSize: 15,
              color: isMe ? Colors.white : AppTheme.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatMessageTime(message.time),
                style: TextStyle(
                  fontSize: 10,
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppTheme.textSecondary,
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                _buildReadReceipt(message.read),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadReceipt(bool isRead) {
    if (isRead) {
      return const Icon(
        Icons.done_all,
        size: 14,
        color: Color(0xFF34B7F1),
      );
    }
    return Icon(
      Icons.done,
      size: 14,
      color: Colors.white.withValues(alpha: 0.7),
    );
  }

  Widget _buildImageMessage(MessageModel message, bool isMe) {
    return GestureDetector(
      onTap: () => _showFullImage(message.imageUrl ?? ''),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Image.network(
                message.imageUrl ?? '',
                width: 220,
                height: 220,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 220,
                    height: 220,
                    color: AppTheme.primaryLight,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  width: 220,
                  height: 220,
                  color: AppTheme.primaryLight,
                  child: const Icon(
                    Icons.broken_image,
                    color: AppTheme.primaryColor,
                    size: 40,
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(message.time),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 3),
                        _buildReadReceipt(true),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceMessage(MessageModel message, bool isMe) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: isMe
            ? const LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isMe ? null : AppTheme.surfaceColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_arrow_rounded,
            color: isMe ? Colors.white : AppTheme.primaryColor,
            size: 28,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SizedBox(
              width: 100,
              child: CustomPaint(
                painter: _WaveformPainter(
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.6)
                      : AppTheme.primaryColor.withValues(alpha: 0.4),
                ),
                size: const Size(100, 24),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatMessageTime(message.time),
            style: TextStyle(
              fontSize: 10,
              color: isMe
                  ? Colors.white.withValues(alpha: 0.7)
                  : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image,
                  color: Colors.white54,
                  size: 60,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        if (!chatProvider.isTyping) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              ProfileAvatar(
                imageUrl: context.read<AuthProvider>().user?.mainPhoto,
                radius: 12,
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    return AnimatedBuilder(
                      animation: _typingAnimationController,
                      builder: (context, _) {
                        final delay = index * 0.15;
                        final value = (_typingAnimationController.value + delay)
                            .remainder(1.0);
                        final bounce =
                            (value < 0.5 ? value * 2 : (1 - value) * 2);
                        return Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.textSecondary.withValues(
                                alpha: 0.4 + bounce * 0.6),
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: () => _showAttachmentOptions(),
              icon: const Icon(
                Icons.add_circle_outline,
                color: AppTheme.primaryColor,
                size: 28,
              ),
            ),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'Message...',
                    hintStyle: const TextStyle(
                      color: AppTheme.textHint,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    prefixIcon: IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.emoji_emotions_outlined,
                        color: AppTheme.textSecondary,
                        size: 24,
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _sendTextMessage(),
                ),
              ),
            ),
            const SizedBox(width: 6),
            _showSendButton
                ? GestureDetector(
                    onTap: _sendTextMessage,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  )
                : GestureDetector(
                    onLongPress: () {
                      HapticFeedback.mediumImpact();
                      _showAttachmentOptions();
                    },
                    onLongPressEnd: (_) {
                      if (_isRecording) {
                        setState(() => _isRecording = false);
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _isRecording
                            ? AppTheme.errorColor
                            : AppTheme.backgroundColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.dividerColor),
                      ),
                      child: Icon(
                        Icons.mic,
                        color: _isRecording
                            ? Colors.white
                            : AppTheme.textSecondary,
                        size: 22,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChat() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final otherUser = args['otherUser'] as UserModel?;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ProfileAvatar(
              imageUrl: otherUser?.mainPhoto,
              radius: 40,
            ),
            const SizedBox(height: 20),
            Text(
              'Say hello to ${otherUser?.name ?? 'your match'}!',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Send a message to start the conversation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}

class _WaveformPainter extends CustomPainter {
  final Color color;

  _WaveformPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final randomHeights = [0.3, 0.7, 0.5, 0.9, 0.4, 0.8, 0.3, 0.6, 0.9, 0.5, 0.7, 0.4, 0.8, 0.3, 0.6, 0.9, 0.5, 0.7, 0.4, 0.8, 0.3, 0.6, 0.9, 0.5];

    final barWidth = size.width / randomHeights.length;
    final centerY = size.height / 2;

    for (int i = 0; i < randomHeights.length; i++) {
      final barHeight = size.height * 0.8 * randomHeights[i];
      final x = i * barWidth + barWidth / 2;
      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
