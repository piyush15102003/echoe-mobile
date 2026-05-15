import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/mic_button.dart';
import '../../../shared/widgets/typing_indicator.dart';
import '../providers/session_provider.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final String mode;

  const ConversationScreen({
    super.key,
    required this.sessionId,
    required this.mode,
  });

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;
  bool _hasText = false;

  late final AudioRecorder _audioRecorder;
  late final AudioPlayer _audioPlayer;
  bool _isRecording = false;

  // Track which message indices have already been animated
  final Set<int> _animatedIndices = {};

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _audioPlayer = AudioPlayer();
    _textController.addListener(() {
      final hasText = _textController.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    HapticFeedback.lightImpact();
    _textController.clear();
    setState(() => _isSending = true);

    ref.read(chatMessagesProvider.notifier).addMessage(
          ChatMessage(role: 'user', content: text),
        );
    _scrollToBottom();

    try {
      final data = await ref.read(sessionRepositoryProvider).sendTextMessage(
            sessionId: widget.sessionId,
            content: text,
          );

      final echo = data['echo'] as Map<String, dynamic>?;
      if (echo != null) {
        final reflection = echo['reflection'] as String? ?? '';
        final question = echo['question'] as String? ?? '';
        final content =
            question.isNotEmpty ? '$reflection\n\n$question' : reflection;

        ref.read(chatMessagesProvider.notifier).addMessage(
              ChatMessage(role: 'echo', content: content),
            );
        _scrollToBottom();
      }

      // Check crisis
      if (data['crisis_detected'] == true) {
        HapticFeedback.mediumImpact();
        _showCrisisOverlay(data['crisis_resources']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Try again.')),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _toggleRecording() async {
    if (_isSending) return;

    HapticFeedback.lightImpact();

    if (_isRecording) {
      // Stop recording
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path == null) {
        debugPrint('[Echoe] Recording stopped but path is null');
        return;
      }

      setState(() => _isSending = true);

      try {
        final file = File(path);
        final audioBytes = await file.readAsBytes();
        final language = await SecureStorage.getLanguage() ?? 'en';
        debugPrint('[Echoe] Sending voice: ${audioBytes.length} bytes, lang=$language');

        final data = await ref.read(sessionRepositoryProvider).sendVoiceMessage(
              sessionId: widget.sessionId,
              audioBytes: audioBytes.toList(),
              language: language,
            );
        debugPrint('[Echoe] Voice response received: ${data.keys}');

        // Display transcribed user text
        final transcribedText = data['transcribed_text'] as String? ?? '';
        if (transcribedText.isNotEmpty) {
          ref.read(chatMessagesProvider.notifier).addMessage(
                ChatMessage(role: 'user', content: transcribedText),
              );
          _scrollToBottom();
        }

        // Display echo text response
        final echo = data['echo'] as Map<String, dynamic>?;
        if (echo != null) {
          final reflection = echo['reflection'] as String? ?? '';
          final question = echo['question'] as String? ?? '';
          final content =
              question.isNotEmpty ? '$reflection\n\n$question' : reflection;

          ref.read(chatMessagesProvider.notifier).addMessage(
                ChatMessage(role: 'echo', content: content),
              );
          _scrollToBottom();
        }

        // Play audio response
        final audioBase64 = data['audio_base64'] as String?;
        if (audioBase64 != null && audioBase64.isNotEmpty) {
          final responseBytes = base64Decode(audioBase64);
          await _audioPlayer.setAudioSource(
            _Base64AudioSource(responseBytes),
          );
          _audioPlayer.play();
        }

        // Check crisis
        if (data['crisis_detected'] == true) {
          HapticFeedback.mediumImpact();
          _showCrisisOverlay(data['crisis_resources']);
        }
      } catch (e) {
        debugPrint('[Echoe] Voice error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Something went wrong. Please try again.')),
          );
        }
      } finally {
        setState(() => _isSending = false);
      }
    } else {
      // Start recording
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission is required to speak.'),
            ),
          );
        }
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/echoe_recording.wav';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );

      debugPrint('[Echoe] Recording started: $path');
      setState(() => _isRecording = true);
    }
  }

  Future<void> _endSession() async {
    HapticFeedback.lightImpact();
    try {
      final data = await ref
          .read(sessionRepositoryProvider)
          .endSession(widget.sessionId);
      if (mounted) {
        context.go('/summary', extra: data);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not end session.')),
        );
      }
    }
  }

  Future<void> _pauseSession() async {
    HapticFeedback.lightImpact();
    try {
      await ref.read(sessionRepositoryProvider).pauseSession(widget.sessionId);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not pause session.')),
        );
      }
    }
  }

  Future<bool> _showExitDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Leaving so soon?',
          style: GoogleFonts.notoSerif(fontSize: 20),
        ),
        content: Text(
          'You can pause and come back later, or end the session now.',
          style: GoogleFonts.inter(
            fontSize: 15,
            height: 1.5,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('keep'),
            child: const Text('Keep talking'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('end'),
            child: Text('End session',
                style: TextStyle(color: AppColors.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop('pause'),
            child: const Text('Pause & come back'),
          ),
        ],
      ),
    );

    if (result == 'pause') {
      await _pauseSession();
      return false;
    } else if (result == 'end') {
      await _endSession();
      return false;
    }
    return false; // keep talking — don't pop
  }

  void _showCrisisOverlay(dynamic resources) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'ECHOE IS HERE WITH YOU',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "What you're carrying right now sounds really heavy. I want to make sure you're safe.",
              style: GoogleFonts.notoSerif(fontSize: 16, height: 1.6),
            ),
            const SizedBox(height: 24),
            if (resources is List)
              ...resources.map((r) {
                final res = r as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '${res['name']} — ${res['phone']}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                );
              }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('I understand'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, int index) {
    final isUser = msg.role == 'user';
    final shouldAnimate = !_animatedIndices.contains(index);
    if (shouldAnimate) _animatedIndices.add(index);

    Widget bubble = Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: EdgeInsets.all(isUser ? 16 : 0),
          decoration: isUser
              ? BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                )
              : null,
          child: Text(
            msg.content,
            style: isUser
                ? GoogleFonts.inter(
                    fontSize: 16,
                    height: 1.6,
                    color: AppColors.surface,
                  )
                : GoogleFonts.notoSerif(
                    fontSize: 18,
                    height: 1.7,
                    color: AppColors.onSurface,
                  ),
          ),
        ),
      ),
    );

    if (shouldAnimate) {
      if (isUser) {
        bubble = bubble
            .animate()
            .fadeIn(duration: 200.ms)
            .slideX(begin: 0.05, end: 0, duration: 200.ms, curve: Curves.easeOut);
      } else {
        bubble = bubble
            .animate()
            .fadeIn(duration: 300.ms)
            .slideX(begin: -0.05, end: 0, duration: 300.ms, curve: Curves.easeOut);
      }
    }

    return bubble;
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitDialog();
      },
      child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _showExitDialog,
        ),
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _isRecording
                ? 'Listening...'
                : _isSending
                    ? 'Echoe is reflecting...'
                    : 'Echoe is listening...',
            key: ValueKey(_isRecording ? 'rec' : _isSending ? 'send' : 'idle'),
            style: textTheme.labelSmall,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _endSession,
            child: Text(
              "I'm done for now",
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              itemCount: messages.length + (_isSending ? 1 : 0),
              itemBuilder: (context, index) {
                // Typing indicator at the end
                if (index == messages.length) {
                  return const TypingIndicator();
                }
                return _buildMessageBubble(messages[index], index);
              },
            ),
          ),
          // Voice recording waveform indicator
          if (_isRecording)
            const _VoiceWaveform(),
          // Input area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLow,
              border: Border(
                top: BorderSide(color: AppColors.outlineVariant, width: 0.5),
              ),
            ),
            child: SafeArea(
              top: false,
              child: widget.mode == 'voice'
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: MicButton(
                          isRecording: _isRecording,
                          onPressed: _isSending ? () {} : _toggleRecording,
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextField(
                              controller: _textController,
                              enabled: !_isSending,
                              decoration: InputDecoration(
                                hintText: 'Write what you feel...',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.onSurfaceVariant,
                                ),
                                border: InputBorder.none,
                              ),
                              style: GoogleFonts.inter(fontSize: 16),
                              maxLines: 3,
                              minLines: 1,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendText(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: IconButton(
                            onPressed: _isSending ? null : _sendText,
                            icon: Icon(
                              Icons.send_rounded,
                              color: _hasText && !_isSending
                                  ? AppColors.primary
                                  : AppColors.outlineVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    ));
  }
}

/// Animated waveform bars shown above input when recording
class _VoiceWaveform extends StatefulWidget {
  const _VoiceWaveform();

  @override
  State<_VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<_VoiceWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = Random();
  late List<double> _phases;

  @override
  void initState() {
    super.initState();
    _phases = List.generate(5, (_) => _random.nextDouble() * 2 * pi);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final height = 8.0 +
                  16.0 * ((sin(_controller.value * 2 * pi + _phases[i]) + 1) / 2);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 4,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    )
        .animate()
        .fadeIn(duration: 200.ms);
  }
}

class _Base64AudioSource extends StreamAudioSource {
  final List<int> _bytes;

  _Base64AudioSource(this._bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _bytes.length;
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(Uint8List.fromList(_bytes.sublist(start, end))),
      contentType: 'audio/mpeg',
    );
  }
}
