import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/socket_service.dart';

class TrackChatScreen extends StatefulWidget {
  final String trackId;
  final String trackTitle;

  const TrackChatScreen({
    super.key,
    required this.trackId,
    required this.trackTitle,
  });

  @override
  State<TrackChatScreen> createState() => _TrackChatScreenState();
}

class _TrackChatScreenState extends State<TrackChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'Alex Rivera',
      'text': 'Welcome to the dedicated track discussion room! All updates here are isolated to this Track.',
      'time': '10:00 AM',
      'isMe': false,
    },
    {
      'sender': 'You',
      'text': 'Sounds great! I just checked off the Week 1 architecture task.',
      'time': '10:14 AM',
      'isMe': true,
    },
    {
      'sender': 'System Bot',
      'text': '📋 Milestone "Architecture & Schema Approved" marked as completed (+25 pts).',
      'time': '10:15 AM',
      'isSystem': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    SocketService.joinRoom('track_${widget.trackId}');
    SocketService.onReceiveMessage((data) {
      if (mounted) {
        setState(() {
          _messages.add({
            'sender': data['senderName'] ?? 'Member',
            'text': data['text'] ?? '',
            'time': 'Just now',
            'isMe': false,
          });
        });
      }
    });
  }

  @override
  void dispose() {
    SocketService.leaveRoom('track_${widget.trackId}');
    _msgController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'sender': 'You',
        'text': text,
        'time': 'Just now',
        'isMe': true,
      });
    });

    SocketService.sendMessage({
      'roomId': 'track_${widget.trackId}',
      'text': text,
      'senderName': 'You',
    });

    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.trackTitle, style: const TextStyle(fontSize: 16)),
            const Text(
              'Track Chat • Authorized Members Only',
              style: TextStyle(fontSize: 11, color: AppColors.accentCyan),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['isMe'] == true;
                final isSystem = msg['isSystem'] == true;

                if (isSystem) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.emerald.withOpacity(0.3)),
                    ),
                    child: Text(
                      msg['text']!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: AppColors.emerald, fontWeight: FontWeight.w600),
                    ),
                  );
                }

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
                        if (!isMe)
                          Text(
                            msg['sender']!,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentCyan),
                          ),
                        Text(
                          msg['text']!,
                          style: const TextStyle(fontSize: 14, height: 1.3),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          msg['time']!,
                          style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Message Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: AppColors.darkCard,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: InputDecoration(
                        hintText: 'Message #${widget.trackTitle}...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sendMessage,
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
