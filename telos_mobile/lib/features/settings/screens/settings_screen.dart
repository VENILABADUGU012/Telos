import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../auth/screens/welcome_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _taskReminders = true;
  bool _deadlineReminders = true;
  bool _recurringReminders = true;
  bool _trackActivity = true;
  bool _collaboratorInvites = true;
  bool _chatMessages = true;
  String _language = 'en';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Account Section
          _buildSectionHeader('Account & Profile'),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.2),
                backgroundImage: user?.avatarUrl.isNotEmpty == true ? NetworkImage(user!.avatarUrl) : null,
                child: user?.avatarUrl.isEmpty == true ? const Icon(Icons.person) : null,
              ),
              title: Text(user?.displayName ?? 'Telos User', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(user?.email ?? 'user@telos.app', style: const TextStyle(fontSize: 12)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(6)),
                child: Text(user?.profileVisibility.toUpperCase() ?? 'PUBLIC', style: const TextStyle(fontSize: 10, color: AppColors.accentCyan)),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 2. Theme Section (Specification 12.2)
          _buildSectionHeader('Theme & Appearance'),
          Card(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('Dark Theme (Recommended)'),
                  subtitle: const Text('Optimized high-contrast dark palette for OLED/AMOLED screens'),
                  value: ThemeMode.dark,
                  groupValue: themeProvider.themeMode,
                  activeColor: AppColors.primary,
                  onChanged: (mode) => themeProvider.setThemeMode(mode!),
                ),
                const Divider(height: 1, color: AppColors.darkBorder),
                RadioListTile<ThemeMode>(
                  title: const Text('Light Theme'),
                  value: ThemeMode.light,
                  groupValue: themeProvider.themeMode,
                  activeColor: AppColors.primary,
                  onChanged: (mode) => themeProvider.setThemeMode(mode!),
                ),
                const Divider(height: 1, color: AppColors.darkBorder),
                RadioListTile<ThemeMode>(
                  title: const Text('System Default'),
                  value: ThemeMode.system,
                  groupValue: themeProvider.themeMode,
                  activeColor: AppColors.primary,
                  onChanged: (mode) => themeProvider.setThemeMode(mode!),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Notification Granular Switches (Specification 12.3)
          _buildSectionHeader('Notification Controls'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Task Reminders'),
                  subtitle: const Text('Scheduled task start times'),
                  value: _taskReminders,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _taskReminders = v),
                ),
                const Divider(height: 1, color: AppColors.darkBorder),
                SwitchListTile(
                  title: const Text('Deadline Reminders'),
                  subtitle: const Text('Alerts 1 hour before hard deadlines'),
                  value: _deadlineReminders,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _deadlineReminders = v),
                ),
                const Divider(height: 1, color: AppColors.darkBorder),
                SwitchListTile(
                  title: const Text('Recurring Task Reminders'),
                  value: _recurringReminders,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _recurringReminders = v),
                ),
                const Divider(height: 1, color: AppColors.darkBorder),
                SwitchListTile(
                  title: const Text('Track Collaboration Updates'),
                  value: _trackActivity,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _trackActivity = v),
                ),
                const Divider(height: 1, color: AppColors.darkBorder),
                SwitchListTile(
                  title: const Text('Direct & Group Messages'),
                  value: _chatMessages,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _chatMessages = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 4. Language Section (Specification 12.4)
          _buildSectionHeader('Language & Localization'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language_rounded, color: AppColors.accentCyan),
              title: const Text('Application Language'),
              subtitle: const Text('English (Default)'),
              trailing: DropdownButton<String>(
                value: _language,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'es', child: Text('Español')),
                  DropdownMenuItem(value: 'fr', child: Text('Français')),
                  DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                ],
                onChanged: (val) => setState(() => _language = val!),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 5. Logout Action (Specification 12.5)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.rose),
                foregroundColor: AppColors.rose,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Log out of TELOS?'),
                    content: const Text('Your session token will be securely cleared.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Log Out'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  await auth.logout();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                      (route) => false,
                    );
                  }
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out of Application'),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMuted),
      ),
    );
  }
}
