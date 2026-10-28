import 'package:flutter/material.dart';
import '../models/template_model.dart'; // ConversationModel and MessageModel are declared here
import '../network/api_client.dart';

class MessageProvider extends ChangeNotifier {
  List<ConversationModel> _conversations = [];
  List<MessageModel> _currentMessages = [];
  bool _isLoading = false;

  List<ConversationModel> get conversations => _conversations;
  List<MessageModel> get currentMessages => _currentMessages;
  bool get isLoading => _isLoading;

  Future<void> fetchConversations() async {
    _isLoading = true;
    notifyListeners();

    final res = await ApiClient.get('/messages/conversations');
    if (res['success'] == true && res['conversations'] != null) {
      final rawList = res['conversations'] as List;
      _conversations = rawList.map((c) => ConversationModel.fromJson(c)).toList();
    } else {
      _conversations = [
        ConversationModel(
          id: 'conv_1',
          type: 'group',
          name: '🚀 Product Launch Core Team',
          avatarUrl: '',
          lastMessageText: 'Admin assigned a new task: "Production Deployment"',
          lastMessageTime: DateTime.now().subtract(const Duration(minutes: 12)),
          unreadCount: 2,
        ),
        ConversationModel(
          id: 'conv_2',
          type: 'individual',
          name: 'Elena Rostova',
          avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
          lastMessageText: 'Did you review the study plan for next Tuesday?',
          lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
          unreadCount: 0,
        ),
        ConversationModel(
          id: 'conv_3',
          type: 'track',
          name: 'Full-Stack Software Discussion',
          avatarUrl: '',
          lastMessageText: 'API test suite passing at 100% now!',
          lastMessageTime: DateTime.now().subtract(const Duration(hours: 5)),
          unreadCount: 0,
        ),
      ];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMessages(String conversationId, String myUserId) async {
    _isLoading = true;
    notifyListeners();

    final res = await ApiClient.get('/messages/conversations/$conversationId/messages');
    if (res['success'] == true && res['messages'] != null) {
      final rawList = res['messages'] as List;
      _currentMessages = rawList.map((m) => MessageModel.fromJson(m, myUserId)).toList();
    } else {
      _currentMessages = [
        MessageModel(
          id: 'msg_1',
          senderId: 'other',
          senderName: 'Elena',
          senderAvatar: '',
          text: 'Welcome to the TELOS track team!',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          isMe: false,
        ),
        MessageModel(
          id: 'msg_2',
          senderId: myUserId,
          senderName: 'You',
          senderAvatar: '',
          text: 'Glad to be here! Ready to execute the milestones.',
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
          isMe: true,
        ),
      ];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> sendMessage(String conversationId, String text, String myUserId) async {
    final newMsg = MessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: myUserId,
      senderName: 'You',
      senderAvatar: '',
      text: text,
      createdAt: DateTime.now(),
      isMe: true,
    );

    _currentMessages.add(newMsg);
    notifyListeners();

    try {
      await ApiClient.post('/messages/conversations/$conversationId/messages', {
        'text': text,
      });
    } catch (e) {
      print('Send message error: $e');
    }
  }

  Future<bool> createGroupTask(String conversationId, Map<String, dynamic> taskData) async {
    final res = await ApiClient.post('/messages/conversations/$conversationId/tasks', taskData);
    return res['success'] == true;
  }
}
