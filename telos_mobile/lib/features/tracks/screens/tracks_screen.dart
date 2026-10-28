import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/track_model.dart';
import '../../../core/providers/track_provider.dart';
import 'track_details_screen.dart';

class TracksScreen extends StatefulWidget {
  const TracksScreen({super.key});

  @override
  State<TracksScreen> createState() => _TracksScreenState();
}

class _TracksScreenState extends State<TracksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrackProvider>().fetchUserTracks();
      context.read<TrackProvider>().fetchPublicTracks();
      context.read<TrackProvider>().fetchTemplates();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackProvider = context.watch<TrackProvider>();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: AppColors.darkBg,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelColor: AppColors.primaryLight,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'YOUR TRACKS'),
              Tab(text: 'COLLABORATE'),
              Tab(text: 'TEMPLATES'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Section 1: YOUR TRACKS
          _buildYourTracksTab(trackProvider),

          // Section 2: COLLABORATE WITH OTHERS
          _buildCollaborateTab(trackProvider),

          // Section 3: EXPLORE TEMPLATES
          _buildTemplatesTab(trackProvider),
        ],
      ),
    );
  }

  // 1. YOUR TRACKS TAB
  Widget _buildYourTracksTab(TrackProvider provider) {
    final filters = ['all', 'active', 'completed', 'upcoming', 'public', 'private', 'collaborative'];

    return RefreshIndicator(
      onRefresh: () => provider.fetchUserTracks(filter: provider.currentFilter),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Filter Chips Row
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              itemBuilder: (context, idx) {
                final f = filters[idx];
                final isSel = provider.currentFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(f[0].toUpperCase() + f.substring(1)),
                    selected: isSel,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.darkCard,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: isSel ? Colors.white : AppColors.textMuted,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: const BorderSide(color: AppColors.darkBorder),
                    onSelected: (_) => provider.fetchUserTracks(filter: f),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          if (provider.isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (provider.userTracks.isEmpty)
            _buildEmptyState('No tracks found under "${provider.currentFilter}" filter.')
          else
            ...provider.userTracks.map((track) => _buildTrackCard(track)),
        ],
      ),
    );
  }

  Widget _buildTrackCard(TrackModel track) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Category pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    track.category.toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                  ),
                ),
                const SizedBox(width: 8),

                // Visibility badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: track.isPublic ? AppColors.accentCyan.withOpacity(0.15) : AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    track.visibility.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: track.isPublic ? AppColors.accentCyan : AppColors.textMuted,
                    ),
                  ),
                ),

                const Spacer(),

                // More Options Menu Action
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textMuted),
                  onSelected: (action) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TrackDetailsScreen(track: track, initialSection: action),
                      ),
                    );
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'analytics', child: Text('📊 Overall Analytics')),
                    const PopupMenuItem(value: 'tasks', child: Text('📅 Day-to-Day Tasks')),
                    const PopupMenuItem(value: 'weekly', child: Text('🗓️ Weekly Allotment')),
                    const PopupMenuItem(value: 'monthly', child: Text('📆 Monthly Allotment')),
                    const PopupMenuItem(value: 'timeline', child: Text('👥 Collaborator Timeline')),
                    const PopupMenuItem(value: 'chat', child: Text('💬 Track Chat Room')),
                    const PopupMenuItem(value: 'ai_edit', child: Text('✨ AI-Assisted Editing')),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Track Title
            Text(
              track.title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),

            if (track.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                track.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ],

            const SizedBox(height: 14),

            // Dates & Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${DateFormat('MMM d').format(track.startDate)} - ${DateFormat('MMM d, y').format(track.endDate)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                Text(
                  '${track.progressPercentage}% Complete',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.emerald),
                ),
              ],
            ),

            const SizedBox(height: 8),

            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: track.progressPercentage / 100,
                minHeight: 8,
                backgroundColor: AppColors.darkSurface,
                color: track.progressPercentage == 100 ? AppColors.emerald : AppColors.primary,
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 14, color: AppColors.emerald),
                const SizedBox(width: 4),
                Text(
                  '${track.completedTasks}/${track.totalTasks} tasks',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(width: 14),
                const Icon(Icons.group_outlined, size: 14, color: AppColors.accentCyan),
                const SizedBox(width: 4),
                Text(
                  '${track.collaboratorsCount} collaborator${track.collaboratorsCount > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TrackDetailsScreen(track: track),
                      ),
                    );
                  },
                  child: const Text('Open Track', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 2. COLLABORATE WITH OTHERS TAB
  Widget _buildCollaborateTab(TrackProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.fetchPublicTracks(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          const Text(
            'Discover Public Tracks',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Join open learning cohorts, software launch roadmaps, and fitness habits hosted by creators.',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),

          ...provider.publicTracks.map((publicTrack) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.accentCyan.withOpacity(0.2),
                            child: const Icon(Icons.public, size: 14, color: AppColors.accentCyan),
                          ),
                          const SizedBox(width: 8),
                          Text(publicTrack.creatorName, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.darkSurface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('${publicTrack.collaboratorsCount} members', style: const TextStyle(fontSize: 11, color: AppColors.accentCyan)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(publicTrack.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(publicTrack.description, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${publicTrack.totalTasks} shared tasks', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              backgroundColor: AppColors.primary,
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Joined "${publicTrack.title}"! Shared tasks added to your schedule.')),
                              );
                            },
                            child: const Text('Join Track', style: TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // 3. EXPLORE TEMPLATES TAB
  Widget _buildTemplatesTab(TrackProvider provider) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        const Text('Explore Track Templates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Adopt proven blueprints for academic sprints, software releases, and fitness.', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        const SizedBox(height: 16),

        ...provider.templates.map((tpl) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentGold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${tpl.durationWeeks} WEEKS',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accentGold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tpl.category.toUpperCase(),
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(tpl.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(tpl.description, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text('${tpl.tasksCount} Tasks  •  ${tpl.milestonesCount} Milestones', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        const Spacer(),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkSurface,
                            foregroundColor: AppColors.textLight,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          onPressed: () async {
                            final success = await provider.applyTemplate(tpl.id);
                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Template "${tpl.title}" added to your Tracks!')),
                              );
                              _tabController.animateTo(0);
                            }
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Use Template', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildEmptyState(String msg) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
      ),
    );
  }
}
