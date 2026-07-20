import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/providers.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../models/user_model.dart';
import '../../models/report_model.dart';
import '../../l10n/app_localizations.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _firestoreService = FirestoreService();
  Map<String, dynamic> _stats = {};
  List<UserModel> _users = [];
  List<ReportModel> _reports = [];
  bool _isLoading = true;
  int _currentTab = 0;
  String _userSearchQuery = '';
  final _announcementTitleController = TextEditingController();
  final _announcementMessageController = TextEditingController();
  String _announcementAudience = 'All Users';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _announcementTitleController.dispose();
    _announcementMessageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _stats = await _firestoreService.getStatistics();
      _users = await _firestoreService.getAllUsers();
      _reports = await _firestoreService.getAllReports();
    } catch (e) {
      debugPrint('Error loading admin data: $e');
    }
    setState(() => _isLoading = false);
  }

  List<UserModel> get _filteredUsers {
    if (_userSearchQuery.isEmpty) return _users;
    final q = _userSearchQuery.toLowerCase();
    return _users.where((u) =>
        u.name.toLowerCase().contains(q) ||
        u.email?.toLowerCase().contains(q) == true ||
        u.district.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : Column(
              children: [
                _buildStatsCards(),
                _buildTabBar(),
                Expanded(child: _buildTabContent()),
              ],
            ),
    );
  }

  Widget _buildStatsCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatCard('Total Users', '${_stats['totalUsers'] ?? _users.length}', Icons.people_rounded, AppTheme.primaryColor),
          const SizedBox(width: 10),
          _buildStatCard('Active Today', '${_stats['activeToday'] ?? 0}', Icons.person_pin_rounded, AppTheme.successColor),
          const SizedBox(width: 10),
          _buildStatCard('Matches', '${_stats['totalMatches'] ?? 0}', Icons.favorite_rounded, AppTheme.likeColor),
          const SizedBox(width: 10),
          _buildStatCard('Reports', '${_stats['pendingReports'] ?? _reports.where((r) => r.status == 'pending').length}', Icons.flag_rounded, AppTheme.warningColor),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.dividerColor, width: 0.5)),
      ),
      child: Row(
        children: [
          _buildTabItem(0, Icons.people_outline, 'Users'),
          _buildTabItem(1, Icons.flag_outlined, 'Reports'),
          _buildTabItem(2, Icons.campaign_outlined, 'Announcements'),
          _buildTabItem(3, Icons.analytics_outlined, 'Analytics'),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, IconData icon, String label) {
    final isSelected = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isSelected ? AppTheme.primaryColor : Colors.transparent, width: 3)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_currentTab) {
      case 0:
        return _buildUsersTab();
      case 1:
        return _buildReportsTab();
      case 2:
        return _buildAnnouncementsTab();
      case 3:
        return _buildAnalyticsTab();
      default:
        return const SizedBox();
    }
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (v) => setState(() => _userSearchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search users by name, email, district...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.textHint),
              suffixIcon: _userSearchQuery.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _userSearchQuery = ''))
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.dividerColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.dividerColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        Expanded(
          child: _filteredUsers.isEmpty
              ? const EmptyState(icon: Icons.people_outline, title: 'No users found', subtitle: 'Try a different search.')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) => _buildUserTile(_filteredUsers[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildUserTile(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: user.banned ? AppTheme.errorColor.withValues(alpha: 0.5) : AppTheme.dividerColor,
          width: user.banned ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          ProfileAvatar(imageUrl: user.mainPhoto, radius: 24, isOnline: user.online),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(user.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    if (user.verified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, size: 14, color: AppTheme.primaryColor),
                    ],
                    if (user.isPremiumActive) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: AppTheme.goldColor, borderRadius: BorderRadius.circular(4)),
                        child: const Text('PRO', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                    if (user.banned) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.block, size: 14, color: AppTheme.errorColor),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${user.email ?? user.phoneNumber ?? "No contact"} - ${user.district}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleUserAction(value, user),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'verify',
                child: Row(
                  children: [
                    Icon(user.verified ? Icons.verified_outlined : Icons.verified, size: 18, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(user.verified ? 'Unverify' : 'Verify'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'ban',
                child: Row(
                  children: [
                    Icon(user.banned ? Icons.check_circle : Icons.block, size: 18, color: user.banned ? AppTheme.successColor : AppTheme.errorColor),
                    const SizedBox(width: 8),
                    Text(user.banned ? 'Unban' : 'Ban'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 18, color: AppTheme.textSecondary),
                    SizedBox(width: 8),
                    Text('View Profile'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleUserAction(String action, UserModel user) async {
    switch (action) {
      case 'verify':
        await _firestoreService.updateUser(user.id, {'verified': !user.verified});
        break;
      case 'ban':
        if (user.banned) {
          await _firestoreService.unbanUser(user.id);
        } else {
          await _firestoreService.banUser(user.id);
        }
        break;
      case 'profile':
        Navigator.pushNamed(context, '/user-profile', arguments: user);
        return;
    }
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(action == 'verify'
              ? 'User ${user.verified ? "unverified" : "verified"}'
              : 'User ${user.banned ? "unbanned" : "banned"}'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Widget _buildReportsTab() {
    if (_reports.isEmpty) {
      return const EmptyState(icon: Icons.flag_outlined, title: 'No reports', subtitle: 'There are no user reports at this time.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reports.length,
      itemBuilder: (context, index) => _buildReportTile(_reports[index]),
    );
  }

  Widget _buildReportTile(ReportModel report) {
    final isPending = report.status == 'pending';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPending ? AppTheme.warningColor.withValues(alpha: 0.5) : AppTheme.dividerColor,
          width: isPending ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPending ? AppTheme.warningColor.withValues(alpha: 0.1) : AppTheme.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  report.status.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isPending ? AppTheme.warningColor : AppTheme.successColor),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(report.reason, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              ),
            ],
          ),
          if (report.description != null && report.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(report.description!, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: AppTheme.textHint),
              const SizedBox(width: 4),
              Text('Reporter: ${report.reportedBy}', style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
              const Spacer(),
              const Icon(Icons.person_outline, size: 14, color: AppTheme.textHint),
              const SizedBox(width: 4),
              Text('Reported: ${report.reportedUser}', style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: AppTheme.textHint),
              const SizedBox(width: 4),
              Text(timeago.format(report.date), style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _resolveReport(report, 'dismissed'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: const BorderSide(color: AppTheme.dividerColor),
                      minimumSize: const Size(0, 36),
                    ),
                    child: const Text('Dismiss', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _resolveReport(report, 'resolved'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor, minimumSize: const Size(0, 36)),
                    child: const Text('Resolve', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _resolveReport(ReportModel report, String status) async {
    await FirebaseFirestore.instance.collection('reports').doc(report.id).update({'status': status});
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report ${status == 'resolved' ? "resolved" : "dismissed"}'), backgroundColor: AppTheme.successColor),
      );
    }
  }

  Widget _buildAnnouncementsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Send Announcement', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          const Text('Broadcast a message to your users.', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          const Text('Title', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _announcementTitleController,
            decoration: InputDecoration(
              hintText: 'Announcement title...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.dividerColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.dividerColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Message', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _announcementMessageController,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Write your announcement message...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.dividerColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.dividerColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Audience', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _announcementAudience,
                items: ['All Users', 'Premium Users', 'Free Users', 'New Users (last 7 days)'].map((e) {
                  return DropdownMenuItem(value: e, child: Text(e));
                }).toList(),
                onChanged: (v) => setState(() => _announcementAudience = v ?? 'All Users'),
              ),
            ),
          ),
          const SizedBox(height: 24),
          GradientButton(
            text: 'Send Announcement',
            onPressed: () {
              if (_announcementTitleController.text.isEmpty || _announcementMessageController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in both title and message'), backgroundColor: AppTheme.errorColor),
                );
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Announcement sent successfully'), backgroundColor: AppTheme.successColor),
              );
              _announcementTitleController.clear();
              _announcementMessageController.clear();
            },
            icon: Icons.send_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    final recentUsers = _users.length;
    final premiumUsers = _users.where((u) => u.isPremiumActive).length;
    final verifiedUsers = _users.where((u) => u.verified).length;
    final bannedUsers = _users.where((u) => u.banned).length;
    final pendingReports = _reports.where((r) => r.status == 'pending').length;
    final resolvedReports = _reports.where((r) => r.status == 'resolved').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Analytics Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 20),
          _buildAnalyticsCard('User Breakdown', [
            _buildAnalyticsRow('Total Users', '$recentUsers', AppTheme.primaryColor),
            _buildAnalyticsRow('Premium Users', '$premiumUsers', AppTheme.goldColor),
            _buildAnalyticsRow('Verified Users', '$verifiedUsers', AppTheme.successColor),
            _buildAnalyticsRow('Banned Users', '$bannedUsers', AppTheme.errorColor),
          ]),
          const SizedBox(height: 16),
          _buildAnalyticsCard('Reports Summary', [
            _buildAnalyticsRow('Total Reports', '${_reports.length}', AppTheme.warningColor),
            _buildAnalyticsRow('Pending', '$pendingReports', AppTheme.warningColor),
            _buildAnalyticsRow('Resolved', '$resolvedReports', AppTheme.successColor),
            _buildAnalyticsRow('Dismissed', '${_reports.where((r) => r.status == 'dismissed').length}', AppTheme.textSecondary),
          ]),
          const SizedBox(height: 16),
          _buildAnalyticsCard('Engagement (Simulated)', [
            _buildBarChartRow('Mon', 0.6),
            _buildBarChartRow('Tue', 0.8),
            _buildBarChartRow('Wed', 0.45),
            _buildBarChartRow('Thu', 0.9),
            _buildBarChartRow('Fri', 0.7),
            _buildBarChartRow('Sat', 0.95),
            _buildBarChartRow('Sun', 0.55),
          ]),
          const SizedBox(height: 16),
          _buildAnalyticsCard('Matches Per Day (Simulated)', [
            _buildBarChartRow('Mon', 0.3),
            _buildBarChartRow('Tue', 0.5),
            _buildBarChartRow('Wed', 0.4),
            _buildBarChartRow('Thu', 0.7),
            _buildBarChartRow('Fri', 0.6),
            _buildBarChartRow('Sat', 0.85),
            _buildBarChartRow('Sun', 0.5),
          ]),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildAnalyticsRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(width: 4, height: 4, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary))),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildBarChartRow(String day, double fraction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 32, child: Text(day, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 20,
              decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(4)),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fraction,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.6)]),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text('${(fraction * 100).round()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }
}
