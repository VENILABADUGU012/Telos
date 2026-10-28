import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../ai_planner/screens/ai_chatbot_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';
  bool _isLoading = false;
  Map<String, dynamic> _results = {};
  bool _showAiHandoff = false;

  final List<String> _filters = ['all', 'tasks', 'tracks', 'users', 'posts', 'templates'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = {};
        _showAiHandoff = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    final typeParam = _selectedFilter == 'all' ? '' : '&type=$_selectedFilter';
    final res = await ApiClient.get('/search?q=${Uri.encodeComponent(query.trim())}$typeParam');

    if (res['success'] == true) {
      setState(() {
        _results = res['results'] ?? {};
        _showAiHandoff = res['aiHandoff']?['suggested'] ?? false;
      });
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search tasks, tracks, users, or UI commands...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch('');
                    },
                  )
                : null,
          ),
          onChanged: _performSearch,
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              itemBuilder: (context, idx) {
                final f = _filters[idx];
                final isSel = _selectedFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f[0].toUpperCase() + f.substring(1)),
                    selected: isSel,
                    selectedColor: AppColors.primary,
                    onSelected: (_) {
                      setState(() => _selectedFilter = f);
                      _performSearch(_searchController.text);
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // 1. Navigation / Interface Destinations (Specification 10.4)
                      if (_results['navigation'] != null && (_results['navigation'] as List).isNotEmpty) ...[
                        const Text('Navigation & Quick Actions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.accentCyan)),
                        const SizedBox(height: 8),
                        ...(_results['navigation'] as List).map((nav) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(Icons.directions_rounded, color: AppColors.accentCyan),
                                title: Text(nav['title'], style: const TextStyle(fontWeight: FontWeight.w600)),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                                onTap: () {
                                  Navigator.pop(context);
                                },
                              ),
                            )),
                        const SizedBox(height: 16),
                      ],

                      // 2. Tasks Results
                      if (_results['tasks'] != null && (_results['tasks'] as List).isNotEmpty) ...[
                        const Text('Tasks', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...(_results['tasks'] as List).map((task) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(Icons.task_alt, color: AppColors.primaryLight),
                                title: Text(task['title']),
                                subtitle: Text(task['status']?.toUpperCase() ?? 'PENDING'),
                              ),
                            )),
                        const SizedBox(height: 16),
                      ],

                      // 3. Tracks Results
                      if (_results['tracks'] != null && (_results['tracks'] as List).isNotEmpty) ...[
                        const Text('Tracks', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...(_results['tracks'] as List).map((t) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(Icons.route_rounded, color: AppColors.emerald),
                                title: Text(t['title']),
                                subtitle: Text(t['description'] ?? ''),
                              ),
                            )),
                        const SizedBox(height: 16),
                      ],

                      // 4. Ask AI Assistant contextual handoff (Specification 10.4)
                      if (_searchController.text.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.smart_toy_outlined, color: AppColors.accentCyan, size: 20),
                                  SizedBox(width: 8),
                                  Text('Need reasoning or customized planning?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accentCyan)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ask the TELOS AI Planning Assistant to analyze "${_searchController.text.trim()}".',
                                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => AIChatbotScreen(initialPrompt: _searchController.text.trim()),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.auto_awesome, size: 16),
                                label: const Text('Ask AI Assistant for more information'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
