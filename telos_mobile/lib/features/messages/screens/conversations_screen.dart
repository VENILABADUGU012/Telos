import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/message_provider.dart';
import '../../../core/providers/auth_provider.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessageProvider>().fetchConversations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messageProvider = context.watch<MessageProvider>();
    final myUserId = context.read<AuthProvider>().currentUser?.id ?? 'me';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_outlined),
            tooltip: 'New Group',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Create Group conversation')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search chats & group channels...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                filled: true,
                fillColor: AppColors.darkCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),

          // Conversation List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => messageProvider.fetchConversations(),
              child: messageProvider.conversations.isEmpty
                  ? const Center(child: Text('No messages yet', style: TextStyle(color: AppColors.textMuted)))
                  : ListView.separated(
                      itemCount: messageProvider.conversations.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72, color: AppColors.darkBorder),
                      itemBuilder: (context, index) {
                        final conv = messageProvider.conversations[index];
                        final isGroup = conv.type == 'group' || conv.type == 'track';

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: isGroup ? AppColors.primary.withOpacity(0.2) : AppColors.accentCyan.withOpacity(0.2),
                                child: Icon(
                                  isGroup ? Icons.groups_rounded : Icons.person_rounded,
                                  color: isGroup ? AppColors.primaryLight : AppColors.accentCyan,
                                ),
                              ),
                              if (conv.unreadCount > 0)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  conv.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: conv.unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Text(
                                DateFormat('h:mm a').format(conv.lastMessageTime),
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            conv.lastMessageText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: conv.unreadCount > 0 ? AppColors.textLight : AppColors.textMuted,
                              fontWeight: conv.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  conversationId: conv.id,
                                  title: conv.name,
                                  isGroup: isGroup,
                                  myUserId: myUserId,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
