import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
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

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
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

  Future<void> _endSession() async {
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

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: const SizedBox.shrink(),
        title: Text(
          _isSending ? 'Echoe is reflecting...' : 'Echoe is listening...',
          style: textTheme.labelSmall,
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
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg.role == 'user';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
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
              },
            ),
          ),
          // Input area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              border: Border(
                top: BorderSide(color: AppColors.outlineVariant, width: 0.5),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      enabled: !_isSending,
                      decoration: InputDecoration(
                        hintText: 'Type or keep speaking...',
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
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSending ? null : _sendText,
                    icon: Icon(
                      Icons.send_rounded,
                      color: _isSending
                          ? AppColors.outlineVariant
                          : AppColors.primary,
                    ),
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
