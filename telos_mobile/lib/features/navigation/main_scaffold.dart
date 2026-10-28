import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../home/screens/home_screen.dart';
import '../tracks/screens/tracks_screen.dart';
import '../add/screens/add_hub_screen.dart';
import '../messages/screens/conversations_screen.dart';
import '../profile/screens/profile_screen.dart';
import '../search/screens/global_search_screen.dart';
import '../ai_planner/screens/ai_chatbot_screen.dart';
import '../rewards/screens/points_chest_screen.dart';
import '../settings/screens/settings_screen.dart';

class MainScaffold extends StatefulWidget {
  final int initialIndex;
  const MainScaffold({super.key, this.initialIndex = 0});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _currentIndex;

  final List<Widget> _destinations = const [
    HomeScreen(),
    TracksScreen(),
    AddHubScreen(),
    ConversationsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accentCyan],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.radar_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'TELOS',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 18),
            ),
          ],
        ),
        actions: [
          // 1. Search
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Global Search',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GlobalSearchScreen()),
              );
            },
          ),
          // 2. AI Chatbot
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined, color: AppColors.accentCyan),
            tooltip: 'AI Planning Assistant',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AIChatbotScreen()),
              );
            },
          ),
          // 3. Points Chest / Rewards
          IconButton(
            icon: const Icon(Icons.military_tech_outlined, color: AppColors.accentGold),
            tooltip: 'Points & Rewards Chest',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PointsChestScreen()),
              );
            },
          ),
          // 4. Settings
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _destinations,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.route_outlined),
            activeIcon: Icon(Icons.route_rounded),
            label: 'Track',
          ),
          // Add - Center distinctive primary action
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accentCyan],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 22),
            ),
            label: 'Add',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Messages',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
