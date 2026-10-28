import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../navigation/main_scaffold.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  String _profileVisibility = 'public';
  bool _taskReminders = true;
  bool _trackActivity = true;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      _displayNameController.text = user.displayName;
      _usernameController.text = user.email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '').toLowerCase();
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      backgroundImage: user?.avatarUrl.isNotEmpty == true
                          ? NetworkImage(user!.avatarUrl)
                          : null,
                      child: user?.avatarUrl.isEmpty == true
                          ? const Icon(Icons.person, size: 48, color: AppColors.primary)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text('Display Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.badge_outlined),
                  hintText: 'Your Full Name',
                ),
              ),

              const SizedBox(height: 18),

              const Text('Unique Username', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.alternate_email),
                  hintText: 'e.g. alex_momentum',
                ),
              ),

              const SizedBox(height: 24),

              const Text('Profile Visibility', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('Public Profile', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Other TELOS users can view your public Tracks and achievements.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      value: 'public',
                      groupValue: _profileVisibility,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _profileVisibility = val!),
                    ),
                    const Divider(height: 1, color: AppColors.darkBorder),
                    RadioListTile<String>(
                      title: const Text('Private Profile', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Only invited collaborators can see your activity.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      value: 'private',
                      groupValue: _profileVisibility,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _profileVisibility = val!),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Track Concept Educational Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.accentCyan, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Public vs. Private Tracks: Even with a public profile, your private Tracks, private messages, and personal notes are never exposed.',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text('Notification Preferences', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Daily Task & Deadline Reminders', style: TextStyle(fontSize: 14)),
                value: _taskReminders,
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _taskReminders = val),
              ),
              SwitchListTile(
                title: const Text('Track Collaboration & Chat Activity', style: TextStyle(fontSize: 14)),
                value: _trackActivity,
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _trackActivity = val),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                          final success = await auth.completeOnboarding(
                            username: _usernameController.text.trim(),
                            displayName: _displayNameController.text.trim(),
                            profileVisibility: _profileVisibility,
                          );
                          if (success && context.mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const MainScaffold()),
                            );
                          }
                        },
                  child: auth.isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Finish & Open TELOS', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
