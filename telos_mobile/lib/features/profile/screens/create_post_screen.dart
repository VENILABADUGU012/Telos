import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _textController = TextEditingController();
  String _visibility = 'public';
  bool _isPublishing = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _publishPost() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please write some content')));
      return;
    }

    setState(() => _isPublishing = true);

    final res = await ApiClient.post('/posts', {
      'text': text,
      'visibility': _visibility,
    });

    setState(() => _isPublishing = false);

    if (res['success'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post published successfully!')));
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          TextButton(
            onPressed: _isPublishing ? null : _publishPost,
            child: _isPublishing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Publish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Share a milestone win, productivity streak, or Track progress with your network...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image_outlined, color: AppColors.accentCyan),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.tag, color: AppColors.primaryLight),
                  onPressed: () {},
                ),
                const Spacer(),
                DropdownButton<String>(
                  value: _visibility,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'public', child: Text('Public', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'private', child: Text('Followers Only', style: TextStyle(fontSize: 12))),
                  ],
                  onChanged: (val) => setState(() => _visibility = val!),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
