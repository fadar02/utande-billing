import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifMatches = true;
  bool _notifMessages = true;
  bool _notifLikes = true;
  bool _notifComments = true;
  bool _notifStories = true;
  bool _screenshotAlerts = true;
  bool _lowDataMode = false;
  bool _isChichewa = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifMatches = prefs.getBool('notif_matches') ?? true;
      _notifMessages = prefs.getBool('notif_messages') ?? true;
      _notifLikes = prefs.getBool('notif_likes') ?? true;
      _notifComments = prefs.getBool('notif_comments') ?? true;
      _notifStories = prefs.getBool('notif_stories') ?? true;
      _screenshotAlerts = prefs.getBool('screenshot_alerts') ?? true;
      _lowDataMode = prefs.getBool('low_data_mode') ?? false;
      _isChichewa = AppLocalizations.currentLocale == 'ny';
    });
  }

  Future<void> _togglePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _toggleLanguage(bool chichewa) {
    setState(() => _isChichewa = chichewa);
    AppLocalizations.setLocale(chichewa ? 'ny' : 'en');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(user),
            const SizedBox(height: 8),
            _buildSection(
              title: 'Account',
              children: [
                _buildTile(
                  icon: Icons.person_outline,
                  title: AppLocalizations.t('edit_profile'),
                  onTap: () => Navigator.pushNamed(context, '/edit-profile'),
                ),
                _buildTile(
                  icon: Icons.phone_outlined,
                  title: AppLocalizations.t('phone_number'),
                  subtitle: user?.phoneNumber ?? 'Not set',
                  onTap: () {},
                ),
                _buildTile(
                  icon: Icons.email_outlined,
                  title: AppLocalizations.t('email'),
                  subtitle: user?.email ?? 'Not set',
                  onTap: () {},
                ),
              ],
            ),
            _buildSection(
              title: 'Discovery Preferences',
              children: [
                _buildTile(
                  icon: Icons.person_search,
                  title: AppLocalizations.t('looking_for'),
                  subtitle: user?.lookingFor ?? 'Female',
                  onTap: () {},
                ),
                _buildTile(
                  icon: Icons.cake_outlined,
                  title: AppLocalizations.t('age_range'),
                  subtitle: '${user?.ageRangeMin ?? '18'} - ${user?.ageRangeMax ?? '60'}',
                  onTap: () {},
                ),
                _buildTile(
                  icon: Icons.location_on_outlined,
                  title: AppLocalizations.t('distance'),
                  subtitle: '${user?.distancePreference ?? '20'} km',
                  onTap: () {},
                ),
                _buildTile(
                  icon: Icons.favorite_outline,
                  title: AppLocalizations.t('relationship_type'),
                  subtitle: user?.relationshipType ?? 'Serious relationship',
                  onTap: () {},
                ),
              ],
            ),
            _buildSection(
              title: 'Notifications',
              children: [
                _buildSwitchTile(
                  icon: Icons.favorite_outline,
                  title: 'Matches',
                  value: _notifMatches,
                  onChanged: (v) {
                    setState(() => _notifMatches = v);
                    _togglePref('notif_matches', v);
                  },
                ),
                _buildSwitchTile(
                  icon: Icons.chat_bubble_outline,
                  title: 'Messages',
                  value: _notifMessages,
                  onChanged: (v) {
                    setState(() => _notifMessages = v);
                    _togglePref('notif_messages', v);
                  },
                ),
                _buildSwitchTile(
                  icon: Icons.favorite_border,
                  title: 'Likes',
                  value: _notifLikes,
                  onChanged: (v) {
                    setState(() => _notifLikes = v);
                    _togglePref('notif_likes', v);
                  },
                ),
                _buildSwitchTile(
                  icon: Icons.comment_outlined,
                  title: 'Comments',
                  value: _notifComments,
                  onChanged: (v) {
                    setState(() => _notifComments = v);
                    _togglePref('notif_comments', v);
                  },
                ),
                _buildSwitchTile(
                  icon: Icons.circle_outlined,
                  title: 'Stories',
                  value: _notifStories,
                  onChanged: (v) {
                    setState(() => _notifStories = v);
                    _togglePref('notif_stories', v);
                  },
                ),
              ],
            ),
            _buildSection(
              title: 'Privacy',
              children: [
                _buildTile(
                  icon: Icons.block,
                  title: 'Block List',
                  onTap: () {},
                ),
                _buildSwitchTile(
                  icon: Icons.screenshot_outlined,
                  title: 'Screenshot Alerts',
                  value: _screenshotAlerts,
                  onChanged: (v) {
                    setState(() => _screenshotAlerts = v);
                    _togglePref('screenshot_alerts', v);
                  },
                ),
              ],
            ),
            _buildSection(
              title: 'Safety',
              children: [
                _buildTile(
                  icon: Icons.flag_outlined,
                  title: 'Report a Problem',
                  onTap: () {},
                ),
                _buildTile(
                  icon: Icons.emergency_outlined,
                  title: 'Panic Button Setup',
                  onTap: () {},
                ),
                _buildTile(
                  icon: Icons.contact_phone_outlined,
                  title: 'Emergency Contact',
                  onTap: () {},
                ),
              ],
            ),
            _buildSection(
              title: 'Premium',
              children: [
                _buildTile(
                  icon: Icons.diamond_outlined,
                  title: 'Upgrade to Premium',
                  subtitle: user?.isPremiumActive == true
                      ? 'Active (${user?.premiumPlan})'
                      : 'Free Account',
                  iconColor: AppTheme.goldColor,
                  onTap: () => Navigator.pushNamed(context, '/premium'),
                  trailing: user?.isPremiumActive == true
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA000)]),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('ACTIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                        )
                      : null,
                ),
              ],
            ),
            _buildSection(
              title: 'Language',
              children: [
                _buildLanguageTile(),
              ],
            ),
            _buildSection(
              title: 'Data',
              children: [
                _buildSwitchTile(
                  icon: Icons.data_usage_outlined,
                  title: AppLocalizations.t('low_data_mode'),
                  value: _lowDataMode,
                  onChanged: (v) {
                    setState(() => _lowDataMode = v);
                    _togglePref('low_data_mode', v);
                  },
                ),
              ],
            ),
            _buildSection(
              title: 'About',
              children: [
                _buildTile(
                  icon: Icons.description_outlined,
                  title: AppLocalizations.t('terms'),
                  onTap: () {},
                ),
                _buildTile(
                  icon: Icons.privacy_tip_outlined,
                  title: AppLocalizations.t('privacy'),
                  onTap: () {},
                ),
                _buildTile(
                  icon: Icons.contact_mail_outlined,
                  title: AppLocalizations.t('contact'),
                  onTap: () {},
                ),
                _buildTile(
                  icon: Icons.info_outline,
                  title: 'Version',
                  subtitle: '1.0.0',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutDialog(context),
                  icon: const Icon(Icons.logout, color: AppTheme.errorColor),
                  label: const Text(
                    'Logout',
                    style: TextStyle(color: AppTheme.errorColor, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.errorColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          ProfileAvatar(imageUrl: user?.mainPhoto, radius: 36, showBorder: true),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.name ?? 'User', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? user?.phoneNumber ?? '',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.textHint),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 0.5),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.dividerColor, width: 0.5))),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor ?? AppTheme.textSecondary),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary))),
            if (subtitle != null)
              Text(subtitle, style: const TextStyle(fontSize: 13, color: AppTheme.textHint)),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing,
            ] else ...[
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppTheme.textHint, size: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.dividerColor, width: 0.5))),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppTheme.textSecondary),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary))),
          Switch(value: value, onChanged: onChanged, activeColor: AppTheme.primaryColor),
        ],
      ),
    );
  }

  Widget _buildLanguageTile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.language, size: 22, color: AppTheme.textSecondary),
          const SizedBox(width: 16),
          const Expanded(child: Text('Language', style: TextStyle(fontSize: 15, color: AppTheme.textPrimary))),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleLanguage(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: !_isChichewa ? AppTheme.primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      AppLocalizations.t('english'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: !_isChichewa ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _toggleLanguage(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isChichewa ? AppTheme.primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      AppLocalizations.t('chichewa'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _isChichewa ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().signOut();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: const Text('Logout', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }
}
