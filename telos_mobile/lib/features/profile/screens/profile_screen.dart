import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/track_provider.dart';
import '../../../core/models/template_model.dart'; // PostModel is defined here
import '../../../core/network/api_client.dart';
import 'create_post_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PostModel> _posts = [];
  bool _isLoadingPosts = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoadingPosts = true);
    final myId = context.read<AuthProvider>().currentUser?.id ?? '';
    final res = await ApiClient.get('/posts/profile/${widget.userId ?? ''}');

    if (res['success'] == true && res['posts'] != null) {
      final rawList = res['posts'] as List;
      _posts = rawList.map((p) => PostModel.fromJson(p, myId)).toList();
    } else {
      _posts = [
        PostModel(
          id: 'post_1',
          authorName: 'Venil',
          authorUsername: 'venil_explorer',
          authorAvatar: '',
          text: 'Just completed Week 1 of our Software Launch Track! 🚀 Architecture verified and API test coverage hitting 100%. Moving into Mobile UI sprint next.',
          likesCount: 14,
          commentsCount: 3,
          isLikedByMe: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        ),
      ];
    }

    setState(() => _isLoadingPosts = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final trackProvider = context.watch<TrackProvider>();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final created = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          );
          if (created == true) _loadProfileData();
        },
        child: const Icon(Icons.post_add, color: Colors.white),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header Row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 38,
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          backgroundImage: user?.avatarUrl.isNotEmpty == true ? NetworkImage(user!.avatarUrl) : null,
                          child: user?.avatarUrl.isEmpty == true ? const Icon(Icons.person, size: 40, color: AppColors.primary) : null,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatColumn('Tracks', '${trackProvider.userTracks.length}'),
                              _buildStatColumn('Points', '${user?.points ?? 0}'),
                              _buildStatColumn('Streak', '${user?.streakDays ?? 5}d 🔥'),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Name and Username
                    Text(
                      user?.displayName ?? 'Telos Explorer',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '@${user?.username.isNotEmpty == true ? user!.username : 'explorer'}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),

                    if (user?.bio.isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Text(user!.bio, style: const TextStyle(fontSize: 13, height: 1.4)),
                    ],

                    const SizedBox(height: 16),

                    // Badges Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentGold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.accentGold.withOpacity(0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_outlined, size: 14, color: AppColors.accentGold),
                              SizedBox(width: 4),
                              Text('Founding Member', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentGold)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentCyan.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.accentCyan.withOpacity(0.4)),
                          ),
                          child: Text(
                            user?.profileVisibility.toUpperCase() ?? 'PUBLIC',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentCyan),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primaryLight,
                  unselectedLabelColor: AppColors.textMuted,
                  tabs: const [
                    Tab(text: 'TRACKS'),
                    Tab(text: 'POSTS'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // 1. Tracks tab
            ListView(
              padding: const EdgeInsets.all(16),
              children: trackProvider.userTracks.map((t) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${t.progressPercentage}% Complete  •  ${t.visibility.toUpperCase()}'),
                  trailing: const Icon(Icons.chevron_right),
                ),
              )).toList(),
            ),

            // 2. Posts Feed
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                final post = _posts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primary.withOpacity(0.2),
                              child: Text(post.authorName[0], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text(DateFormat('MMM d • h:mm a').format(post.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(post.text, style: const TextStyle(fontSize: 14, height: 1.4)),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Icon(post.isLikedByMe ? Icons.favorite : Icons.favorite_border, color: post.isLikedByMe ? AppColors.rose : AppColors.textMuted, size: 20),
                            const SizedBox(width: 4),
                            Text('${post.likesCount}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            const SizedBox(width: 18),
                            const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text('${post.commentsCount}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            const Spacer(),
                            const Icon(Icons.share_outlined, size: 18, color: AppColors.textMuted),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _SliverAppBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.darkBg,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
