import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/message_provider.dart';
import 'call_screen.dart';
import '../dialogs/group_admin_create_task_dialog.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String title;
  final bool isGroup;
  final String myUserId;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.title,
    required this.isGroup,
    required this.myUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessageProvider>().fetchMessages(widget.conversationId, widget.myUserId);
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    context.read<MessageProvider>().sendMessage(widget.conversationId, text, widget.myUserId);
    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messageProvider = context.watch<MessageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: const TextStyle(fontSize: 16)),
            Text(
              widget.isGroup ? 'Group Conversation' : 'Direct Message • Active',
              style: const TextStyle(fontSize: 11, color: AppColors.accentCyan),
            ),
          ],
        ),
        actions: [
          // Audio Call
          IconButton(
            icon: const Icon(Icons.call_outlined),
            tooltip: 'Audio Call',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CallScreen(peerName: widget.title, isVideo: false)),
              );
            },
          ),
          // Video Call
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            tooltip: 'Video Call',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CallScreen(peerName: widget.title, isVideo: true)),
              );
            },
          ),
          // If Group, Admin Task Creation option
          if (widget.isGroup)
            IconButton(
              icon: const Icon(Icons.add_task_rounded, color: AppColors.emerald),
              tooltip: 'Admin: Assign Group Task',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => GroupAdminCreateTaskDialog(
                    conversationId: widget.conversationId,
                    onTaskCreated: (taskData) async {
                      await messageProvider.createGroupTask(widget.conversationId, taskData);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Group task "${taskData['title']}" assigned and shared!')),
                        );
                      }
                    },
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Chat Messages List
          Expanded(
            child: messageProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: messageProvider.currentMessages.length,
                    itemBuilder: (context, index) {
                      final msg = messageProvider.currentMessages[index];
                      final isMe = msg.isMe;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isMe ? AppColors.primary : AppColors.darkCard,
                            borderRadius: BorderRadius.circular(16).copyWith(
                              bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                              bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                            ),
                            border: Border.all(
                              color: isMe ? AppColors.primary : AppColors.darkBorder,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (!isMe && widget.isGroup)
                                Text(
                                  msg.senderName,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentCyan),
                                ),
                              Text(
                                msg.text,
                                style: const TextStyle(fontSize: 14, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Message Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: AppColors.darkCard,
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: AppColors.textMuted),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.poll_outlined, color: AppColors.accentGold),
                    tooltip: 'Create Poll',
                    onPressed: () {
                      _msgController.text = 'Poll: Ready for sprint deployment? [Yes / Needs review]';
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: const InputDecoration(
                        hintText: 'Message...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
