import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/echo_card.dart';
import '../../../shared/widgets/emotion_tag.dart';
import '../providers/vault_provider.dart';

class VaultDetailScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const VaultDetailScreen({super.key, required this.sessionId});

  @override
  ConsumerState<VaultDetailScreen> createState() => _VaultDetailScreenState();
}

class _VaultDetailScreenState extends ConsumerState<VaultDetailScreen> {
  Map<String, dynamic>? _detail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final detail = await ref
          .read(vaultRepositoryProvider)
          .getSessionDetail(widget.sessionId);
      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load session.';
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete this echo?'),
        content: const Text(
          'This cannot be undone. The conversation will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(vaultRepositoryProvider)
          .deleteSession(widget.sessionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Echo deleted.')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete session.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _detail == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text(
            _error ?? 'Something went wrong.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final d = _detail!;
    final summaryQuote = d['summary_quote'] as String?;
    final closingReflection = d['closing_reflection'] as String?;
    final emotionTags =
        (d['emotion_tags'] as List<dynamic>?)?.cast<String>() ?? [];
    final messages =
        (d['messages'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final inputMode = d['input_mode'] as String? ?? 'text';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          inputMode == 'voice' ? 'Voice session' : 'Text session',
          style: textTheme.labelSmall,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Summary quote
            if (summaryQuote != null) ...[
              Center(
                child: Text(
                  'WHAT CAME UP',
                  style: textTheme.labelSmall,
                ),
              ),
              const SizedBox(height: 12),
              EchoCard(quote: summaryQuote),
              const SizedBox(height: 16),
            ],

            // Emotion tags
            if (emotionTags.isNotEmpty) ...[
              Center(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: emotionTags
                      .map((t) => EmotionTag(label: t))
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Closing reflection
            if (closingReflection != null) ...[
              Center(
                child: Text(
                  closingReflection,
                  style: GoogleFonts.notoSerif(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                    color: AppColors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Conversation
            if (messages.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'CONVERSATION',
                  style: textTheme.labelSmall,
                ),
              ),
              const SizedBox(height: 16),
              ...messages.map((msg) {
                final role = msg['role'] as String? ?? '';
                final content = msg['content'] as String? ?? '';
                final isUser = role == 'user';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
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
                        content,
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
              }),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
