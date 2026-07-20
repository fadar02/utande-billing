import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        context.read<NotificationProvider>().loadNotifications(auth.user!.id);
      }
    });
  }

  void _onNotificationTap(AppNotification notification) {
    if (!notification.read) {
      context.read<NotificationProvider>().markAsRead(notification.id);
    }
    _navigateByType(notification);
  }

  void _navigateByType(AppNotification notification) {
    switch (notification.type) {
      case 'match':
      case 'message':
        if (notification.referenceId != null) {
          Navigator.pushNamed(context, '/chat', arguments: notification.referenceId);
        }
        break;
      case 'like':
      case 'comment':
        break;
      default:
        break;
    }
  }

  List<AppNotification> _getNewNotifications(NotificationProvider provider) {
    final now = DateTime.now();
    return provider.notifications.where((n) {
      final diff = now.difference(n.createdAt);
      return diff.inHours < 24;
    }).toList();
  }

  List<AppNotification> _getEarlierNotifications(NotificationProvider provider) {
    final now = DateTime.now();
    return provider.notifications.where((n) {
      final diff = now.difference(n.createdAt);
      return diff.inHours >= 24;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, NotificationProvider>(
      builder: (context, auth, notifProvider, _) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: const Text('Activity'),
            actions: [
              if (notifProvider.notifications.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.done_all, color: AppTheme.primaryColor),
                  onPressed: () {
                    final userId = auth.userId;
                    if (userId != null) {
                      notifProvider.markAllAsRead(userId);
                    }
                  },
                  tooltip: 'Mark all as read',
                ),
            ],
          ),
          body: notifProvider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
              : notifProvider.notifications.isEmpty
                  ? const _EmptyNotifications()
                  : _buildNotificationsList(notifProvider),
        );
      },
    );
  }

  Widget _buildNotificationsList(NotificationProvider provider) {
    final newNotifications = _getNewNotifications(provider);
    final earlierNotifications = _getEarlierNotifications(provider);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (newNotifications.isNotEmpty) ...[
          _buildSectionHeader('New'),
          ...newNotifications.map((n) => _buildNotificationTile(n)),
        ],
        if (earlierNotifications.isNotEmpty) ...[
          _buildSectionHeader('Earlier'),
          ...earlierNotifications.map((n) => _buildNotificationTile(n)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
      ),
    );
  }

  Widget _buildNotificationTile(AppNotification notification) {
    return InkWell(
      onTap: () => _onNotificationTap(notification),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: notification.read ? null : AppTheme.primaryColor.withValues(alpha: 0.04),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNotificationIcon(notification),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: notification.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: notification.read ? FontWeight.normal : FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const TextSpan(text: ' '),
                              TextSpan(
                                text: notification.message,
                                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.normal),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!notification.read)
                        const Padding(
                          padding: EdgeInsets.only(left: 8, top: 6),
                          child: Icon(Icons.circle, size: 8, color: AppTheme.primaryColor),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(notification.createdAt, allowFromNow: true),
                    style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
                  ),
                ],
              ),
            ),
            if (notification.type == 'match')
              const Icon(Icons.favorite, color: AppTheme.primaryColor, size: 20),
            if (notification.type == 'like')
              const Icon(Icons.favorite_border, color: AppTheme.primaryColor, size: 20),
            if (notification.type == 'comment')
              const Icon(Icons.comment, color: AppTheme.secondaryColor, size: 20),
            if (notification.type == 'follow')
              const Icon(Icons.person_add, color: AppTheme.successColor, size: 20),
            if (notification.type == 'system')
              const Icon(Icons.notifications, color: AppTheme.accentColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(AppNotification notification) {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case 'match':
        iconData = Icons.favorite;
        iconColor = AppTheme.primaryColor;
        break;
      case 'like':
        iconData = Icons.favorite_border;
        iconColor = AppTheme.primaryColor;
        break;
      case 'comment':
        iconData = Icons.chat_bubble_outline;
        iconColor = AppTheme.secondaryColor;
        break;
      case 'follow':
        iconData = Icons.person_add_outlined;
        iconColor = AppTheme.successColor;
        break;
      case 'system':
      default:
        iconData = Icons.notifications_outlined;
        iconColor = AppTheme.accentColor;
        break;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: iconColor, size: 22),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
              ),
              child: Icon(Icons.notifications_none_rounded, size: 48, color: AppTheme.primaryColor.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 24),
            const Text(
              'No notifications yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              "When you get notifications, they'll show up here.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
