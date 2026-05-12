import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _language = 'en';
  String _voice = 'female';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final lang = await SecureStorage.getLanguage() ?? 'en';
    final voice = await SecureStorage.getVoicePreference() ?? 'female';
    setState(() {
      _language = lang;
      _voice = voice;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 16),
          // Voice & Language
          Text('VOICE & LANGUAGE',
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              )),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Voice'),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'female', label: Text('Female')),
                ButtonSegment(value: 'male', label: Text('Male')),
              ],
              selected: {_voice},
              onSelectionChanged: (val) {
                setState(() => _voice = val.first);
                SecureStorage.saveVoicePreference(_voice);
              },
            ),
          ),
          ListTile(
            title: const Text('Language'),
            trailing: DropdownButton<String>(
              value: _language,
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'hi', child: Text('Hindi')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _language = val);
                  SecureStorage.saveLanguage(val);
                }
              },
            ),
          ),
          const Divider(height: 32),
          // Danger zone
          Text('DANGER ZONE',
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.error,
              )),
          const SizedBox(height: 8),
          ListTile(
            title: Text(
              'Reset Echoe',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.error),
            ),
            subtitle: const Text('Delete everything. Permanently.'),
            onTap: () => _confirmReset(context),
          ),
          const Divider(height: 32),
          // About
          Text('ABOUT',
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              )),
          const SizedBox(height: 8),
          const ListTile(
            title: Text('Version'),
            trailing: Text('1.0.0'),
          ),
          ListTile(
            title: const Text('Crisis Resources'),
            subtitle: const Text('Always available helplines'),
            onTap: () => _showCrisisResources(context),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Echoe?'),
        content: const Text(
            'This deletes everything. Permanently. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await SecureStorage.clearAll();
              if (context.mounted) context.go('/onboarding/language');
            },
            child: Text('Yes, reset',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showCrisisResources(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Crisis Resources'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('iCall — 9152987821 (24/7)'),
            SizedBox(height: 8),
            Text('Vandrevala Foundation — 1860-2662-345 (24/7)'),
            SizedBox(height: 8),
            Text('AASRA — 9820466726 (24/7)'),
            SizedBox(height: 16),
            Text('If you are in immediate danger, call 112.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
