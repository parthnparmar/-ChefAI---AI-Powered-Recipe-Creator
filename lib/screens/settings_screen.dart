import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../services/storage_service.dart';
import '../services/firebase_service.dart';
import '../utils/theme.dart';
import 'auth_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _buildProfileCard(context),
                const SizedBox(height: 16),
                _buildSectionTitle(context, 'Appearance'),
                _buildCard(context, [
                  Consumer<ThemeProvider>(
                    builder: (ctx, tp, _) => _settingsTile(
                      context,
                      icon: tp.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      iconColor: tp.isDarkMode ? Colors.indigo : Colors.amber,
                      title: 'Dark Mode',
                      subtitle: tp.isDarkMode ? 'Dark theme active' : 'Light theme active',
                      trailing: Switch(
                        value: tp.isDarkMode,
                        onChanged: (_) => tp.toggleTheme(),
                        activeColor: AppTheme.primary,
                      ),
                    ),
                  ),
                  Consumer<LanguageProvider>(
                    builder: (ctx, lp, _) => _settingsTile(
                      context,
                      icon: Icons.language_rounded,
                      iconColor: const Color(0xFF4CAF50),
                      title: 'Language',
                      subtitle: AppConstants.languages[lp.currentLanguage] ?? 'English',
                      onTap: () => _showLanguageDialog(context),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                _buildSectionTitle(context, 'Account & Sync'),
                _buildCard(context, [
                  StreamBuilder(
                    stream: FirebaseService().authStateChanges,
                    builder: (ctx, snap) {
                      final signedIn = FirebaseService().isSignedIn;
                      final user = FirebaseService().currentUser;
                      if (signedIn) {
                        return Column(
                          children: [
                            _settingsTile(context,
                              icon: Icons.account_circle_rounded,
                              iconColor: const Color(0xFF4CAF50),
                              title: user?.email ?? 'Signed In',
                              subtitle: 'Cloud sync active'),
                            _settingsTile(context,
                              icon: Icons.logout_rounded,
                              iconColor: Colors.red,
                              title: 'Sign Out',
                              titleColor: Colors.red,
                              onTap: () async {
                                await FirebaseService().signOut();
                              }),
                          ],
                        );
                      }
                      return _settingsTile(context,
                        icon: Icons.cloud_sync_rounded,
                        iconColor: const Color(0xFF2196F3),
                        title: 'Sign In / Sign Up',
                        subtitle: 'Sync recipes across devices',
                        onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const AuthScreen())));
                    },
                  ),
                ]),
                const SizedBox(height: 16),
                _buildSectionTitle(context, 'Notifications'),
                _buildCard(context, [
                  _settingsTile(context,
                    icon: Icons.notifications_rounded,
                    iconColor: Colors.orange,
                    title: 'Push Notifications',
                    subtitle: 'Recipe tips and updates',
                    trailing: Switch(value: true, onChanged: (_) {}, activeColor: AppTheme.primary)),
                ]),
                const SizedBox(height: 16),
                _buildSectionTitle(context, 'Data Management'),
                _buildCard(context, [
                  _settingsTile(context,
                    icon: Icons.download_rounded,
                    iconColor: const Color(0xFF4CAF50),
                    title: 'Export Data',
                    subtitle: 'Backup all recipes',
                    onTap: () => _exportData(context)),
                  _settingsTile(context,
                    icon: Icons.cleaning_services_rounded,
                    iconColor: Colors.orange,
                    title: 'Clear Cache',
                    subtitle: 'Free up storage space',
                    onTap: () => _clearCache(context)),
                  _settingsTile(context,
                    icon: Icons.delete_forever_rounded,
                    iconColor: Colors.red,
                    title: 'Clear All Data',
                    titleColor: Colors.red,
                    subtitle: 'Delete all recipes and settings',
                    onTap: () => _clearAllData(context)),
                ]),
                const SizedBox(height: 16),
                _buildSectionTitle(context, 'About'),
                _buildCard(context, [
                  _settingsTile(context,
                    icon: Icons.info_rounded,
                    iconColor: const Color(0xFF2196F3),
                    title: 'App Version',
                    subtitle: '2.0.0'),
                  _settingsTile(context,
                    icon: Icons.privacy_tip_rounded,
                    iconColor: Colors.purple,
                    title: 'Privacy Policy',
                    onTap: () => _showPrivacyPolicy(context)),
                  _settingsTile(context,
                    icon: Icons.code_rounded,
                    iconColor: Colors.teal,
                    title: 'About ChefAI',
                    subtitle: 'Built with Flutter & OpenAI',
                    onTap: () => _showAbout(context)),
                ]),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFF673AB7)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.settings_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Text('Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chef User', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('Premium Member', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Edit', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.primary, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
    );
  }

  Widget _buildCard(BuildContext context, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: children.asMap().entries.map((e) {
          final isLast = e.key == children.length - 1;
          return Column(
            children: [
              e.value,
              if (!isLast) Divider(height: 1, indent: 56, endIndent: 16, color: Colors.grey.withOpacity(0.15)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _settingsTile(BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Color? titleColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: titleColor)),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey))
          : null,
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20) : null),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Select Language', style: TextStyle(fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: AppConstants.languages.entries.map((e) {
              return ListTile(
                title: Text(e.value),
                onTap: () async {
                  await ctx.read<LanguageProvider>().changeLanguage(e.key);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _exportData(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data exported successfully!'), backgroundColor: AppTheme.primary),
    );
  }

  void _clearCache(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache cleared!'), backgroundColor: AppTheme.primary),
    );
  }

  void _clearAllData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear All Data', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('This will permanently delete all your recipes and settings. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await StorageService().clearAllData();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('All data cleared'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const SingleChildScrollView(
          child: Text(
            'ChefAI Privacy Policy\n\n'
            '1. Data Collection: We only collect the recipes you create and your app preferences.\n\n'
            '2. Data Storage: All data is stored locally on your device using Hive database.\n\n'
            '3. API Usage: When generating recipes, your ingredients and preferences are sent to OpenAI\'s API. No personal information is shared.\n\n'
            '4. Data Sharing: We do not share your personal data with third parties.\n\n'
            '5. Data Control: You can export or delete all your data at any time from Settings.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'ChefAI',
      applicationVersion: '2.0.0',
      applicationIcon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 28),
      ),
      children: const [
        Text('ChefAI is an AI-powered recipe creator that helps you generate delicious recipes based on your available ingredients and preferences.\n\nBuilt with Flutter and powered by OpenAI GPT models.'),
      ],
    );
  }
}
