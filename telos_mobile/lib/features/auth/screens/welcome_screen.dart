import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import 'onboarding_screen.dart';
import '../../navigation/main_scaffold.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // TELOS Logo & Branding
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accentCyan],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.radar_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'TELOS',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Transform your daily tasks into structured long-term Tracks with collaborative spaces, gamified momentum, and AI-powered planning.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 3),

              if (auth.errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.rose.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.rose.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.rose, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          auth.errorMessage!,
                          style: const TextStyle(color: AppColors.rose, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // Continue with Google Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                          final success = await auth.signInWithGoogle();
                          if (success && context.mounted) {
                            if (auth.currentUser?.isOnboarded == false) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                              );
                            } else {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const MainScaffold()),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1F1F1F),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              'https://fonts.gstatic.com/s/i/productlogos/googleg/v6/24px.svg',
                              width: 22,
                              height: 22,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.g_mobiledata_rounded,
                                size: 28,
                                color: Color(0xFF4285F4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F1F1F),
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // Fast Demo / Pilot Login for rapid test
              TextButton.icon(
                onPressed: auth.isLoading
                    ? null
                    : () async {
                        final success = await auth.signInDemo();
                        if (success && context.mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const MainScaffold()),
                          );
                        }
                      },
                icon: const Icon(Icons.bolt_rounded, size: 18, color: AppColors.accentCyan),
                label: const Text(
                  'Quick Pilot Access (Dev Mode)',
                  style: TextStyle(color: AppColors.accentCyan, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),

              const SizedBox(height: 24),

              // Terms & Privacy Links
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      'Terms of Service',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12, decoration: TextDecoration.underline),
                    ),
                  ),
                  const Text('  •  ', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      'Privacy Policy',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
