import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CallScreen extends StatefulWidget {
  final String peerName;
  final bool isVideo;

  const CallScreen({
    super.key,
    required this.peerName,
    this.isVideo = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = true;
  String _callStatus = 'Calling...';

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _callStatus = '00:15 • Connected');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070A10),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Peer info
            CircleAvatar(
              radius: 54,
              backgroundColor: AppColors.primary.withOpacity(0.2),
              child: Text(
                widget.peerName.substring(0, 1).toUpperCase(),
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
              ),
            ),

            const SizedBox(height: 18),

            Text(
              widget.peerName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),

            const SizedBox(height: 8),

            Text(
              _callStatus,
              style: const TextStyle(fontSize: 14, color: AppColors.accentCyan),
            ),

            const Spacer(),

            // Call Controls Row
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.darkCard.withOpacity(0.9),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute Button
                  IconButton(
                    icon: Icon(_isMuted ? Icons.mic_off : Icons.mic, color: _isMuted ? AppColors.rose : Colors.white),
                    onPressed: () => setState(() => _isMuted = !_isMuted),
                  ),

                  // Camera Toggle (if video call)
                  if (widget.isVideo)
                    IconButton(
                      icon: Icon(_isCameraOff ? Icons.videocam_off : Icons.videocam, color: _isCameraOff ? AppColors.rose : Colors.white),
                      onPressed: () => setState(() => _isCameraOff = !_isCameraOff),
                    ),

                  // Speaker
                  IconButton(
                    icon: Icon(_isSpeakerOn ? Icons.volume_up : Icons.volume_mute, color: Colors.white),
                    onPressed: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
                  ),

                  // End Call Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.rose,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.call_end, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
