import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../models/match_model.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().userId;
      if (userId != null) {
        context.read<ChatProvider>().loadChatList(userId);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterChats(List<Map<String, dynamic>> chats) {
    if (_searchQuery.isEmpty) return chats;
    return chats.where((chat) {
      final user = chat['otherUser'] as UserModel?;
      if (user == null) return false;
      return user.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _openChat(Map<String, dynamic> chatData) {
    final otherUser = chatData['otherUser'] as UserModel;
    final matchId = chatData['matchId'] as String;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(),
        settings: RouteSettings(
          arguments: {
            'matchId': matchId,
            'otherUser': otherUser,
          },
        ),
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: Consumer2<AuthProvider, ChatProvider>(
        builder: (context, authProvider, chatProvider, child) {
          if (chatProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          final filteredChats = _filterChats(chatProvider.chatList);

          if (filteredChats.isEmpty && !_isSearching) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            color: AppTheme.primaryColor,
            onRefresh: () async {
              final userId = authProvider.userId;
              if (userId != null) {
                chatProvider.loadChatList(userId);
              }
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildSearchBar()),
                SliverToBoxAdapter(
                  child: _buildStoriesRow(authProvider, chatProvider),
                ),
                if (filteredChats.isEmpty && _isSearching)
                  SliverFillRemaining(
                    child: _buildNoResults(),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final chatData = filteredChats[index];
                        return _buildChatListItem(chatData, authProvider);
                      },
                      childCount: filteredChats.length,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.backgroundColor,
      elevation: 0,
      centerTitle: false,
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(
                fontSize: 18,
                color: AppTheme.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: 'Search conversations...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: AppTheme.textHint),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            )
          : const Text(
              'Chats',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
      actions: [
        IconButton(
          onPressed: _toggleSearch,
          icon: Icon(
            _isSearching ? Icons.close : Icons.search,
            color: AppTheme.textSecondary,
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.edit_square,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    if (_isSearching) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Search',
            hintStyle: TextStyle(color: AppTheme.textHint),
            prefixIcon: Icon(
              Icons.search,
              color: AppTheme.textHint,
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildStoriesRow(
      AuthProvider authProvider, ChatProvider chatProvider) {
    final currentUserId = authProvider.userId ?? '';
    final chats = chatProvider.chatList;

    if (chats.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chatData = chats[index];
          final otherUser = chatData['otherUser'] as UserModel?;
          if (otherUser == null) return const SizedBox.shrink();
          final hasStory = chatData['hasStory'] as bool? ?? false;

          return GestureDetector(
            onTap: () => _openChat(chatData),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: hasStory
                              ? Border.all(
                                  color: AppTheme.primaryColor,
                                  width: 3,
                                )
                              : null,
                        ),
                        child: ProfileAvatar(
                          imageUrl: otherUser.mainPhoto,
                          radius: 30,
                          isOnline: otherUser.online,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 72,
                    child: Text(
                      otherUser.name.split(' ').first,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatListItem(
      Map<String, dynamic> chatData, AuthProvider authProvider) {
    final otherUser = chatData['otherUser'] as UserModel?;
    final lastMessage = chatData['lastMessage'] as MessageModel?;
    final unreadCount = chatData['unreadCount'] as int? ?? 0;
    final matchId = chatData['matchId'] as String? ?? '';
    final currentUserId = authProvider.userId ?? '';

    if (otherUser == null) return const SizedBox.shrink();

    final hasUnread = unreadCount > 0;
    final isOwnMessage = lastMessage?.senderId == currentUserId;

    return Dismissible(
      key: Key(matchId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.textSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.volume_off, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return await _showDeleteConfirmation(chatData);
        } else {
          _showMuteSnackBar();
          return false;
        }
      },
      child: GestureDetector(
        onTap: () => _openChat(chatData),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              ProfileAvatar(
                imageUrl: otherUser.mainPhoto,
                radius: 28,
                isOnline: otherUser.online,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            otherUser.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  hasUnread ? FontWeight.bold : FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (lastMessage != null)
                          Text(
                            timeago.format(lastMessage.time, locale: 'en_short'),
                            style: TextStyle(
                              fontSize: 12,
                              color: hasUnread
                                  ? AppTheme.primaryColor
                                  : AppTheme.textSecondary,
                              fontWeight:
                                  hasUnread ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: lastMessage != null
                              ? Text(
                                  _getLastMessagePreview(
                                      lastMessage, isOwnMessage),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: hasUnread
                                        ? AppTheme.textPrimary
                                        : AppTheme.textSecondary,
                                    fontWeight: hasUnread
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : Text(
                                  'Say hello!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                unreadCount > 99 ? '99+' : '$unreadCount',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLastMessagePreview(MessageModel message, bool isOwnMessage) {
    final prefix = isOwnMessage ? 'You: ' : '';
    switch (message.type) {
      case MessageType.text:
        return '$prefix${message.message}';
      case MessageType.image:
        return '$prefix📷 Photo';
      case MessageType.voice:
        return '$prefix🎤 Voice message';
      case MessageType.video:
        return '$prefix🎬 Video';
      case MessageType.location:
        return '$prefix📍 Location';
      case MessageType.sticker:
        return '$prefix sticker';
      case MessageType.gif:
        return '$prefix GIF';
      default:
        return '$prefix${message.message}';
    }
  }

  Future<bool?> _showDeleteConfirmation(Map<String, dynamic> chatData) {
    final otherUser = chatData['otherUser'] as UserModel?;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text(
          'Delete your conversation with ${otherUser?.name ?? 'this person'}? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showMuteSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conversation muted'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppTheme.textHint,
            ),
            const SizedBox(height: 16),
            const Text(
              'No conversations found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            const Text(
              'No matches yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No matches yet. Start swiping!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
