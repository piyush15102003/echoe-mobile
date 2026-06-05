import 'package:dbcrypt/dbcrypt.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/pin_dialog.dart';
import '../../auth/providers/auth_provider.dart';
import '../../vault/providers/vault_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _language = 'en';
  String _voice = 'female';
  bool _vaultEnabled = false;
  bool _vaultLoading = true;
  bool _biometricEnabled = false;

  // Emergency contact
  final _contactNameCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();
  bool _contactSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _contactNameCtrl.dispose();
    _contactPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final lang = await SecureStorage.getLanguage() ?? 'en';
    final voice = await SecureStorage.getVoicePreference() ?? 'female';
    final bio = await SecureStorage.isBiometricEnabled();
    setState(() {
      _language = lang;
      _voice = voice;
      _biometricEnabled = bio;
    });

    try {
      final settings = await ref.read(vaultRepositoryProvider).getSettings();
      setState(() {
        _vaultEnabled = settings['vault_enabled'] as bool? ?? false;
        _vaultLoading = false;
      });
    } catch (_) {
      setState(() => _vaultLoading = false);
    }
  }

  Future<void> _toggleVault(bool enable) async {
    try {
      await ref.read(vaultRepositoryProvider).updateSettings(enable: enable);
      setState(() => _vaultEnabled = enable);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(enable ? 'Vault Mode enabled.' : 'Vault Mode disabled.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update vault. Please try again.')),
        );
      }
    }
  }

  Future<void> _toggleBiometric(bool enable) async {
    await SecureStorage.setBiometricEnabled(enable);
    setState(() => _biometricEnabled = enable);
  }

  Future<void> _changePin() async {
    // Step 1: Verify current PIN
    final currentPin =
        await showPinDialog(context, title: 'Enter current PIN');
    if (currentPin == null || !mounted) return;

    try {
      final result =
          await ref.read(authRepositoryProvider).verifyPin(currentPin);
      final success = result['success'] as bool? ?? false;
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wrong PIN.')),
          );
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not verify PIN.')),
        );
      }
      return;
    }

    if (!mounted) return;

    // Step 2: Enter new PIN
    final newPin = await showPinDialog(context, title: 'Enter new PIN');
    if (newPin == null || !mounted) return;

    // Step 3: Confirm new PIN
    final confirmPin = await showPinDialog(context, title: 'Confirm new PIN');
    if (confirmPin == null || !mounted) return;

    if (newPin != confirmPin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PINs do not match.')),
        );
      }
      return;
    }

    // Step 4: Set new PIN on backend + update local hash
    try {
      await ref.read(authRepositoryProvider).setPin(newPin);
      final hash = DBCrypt().hashpw(newPin, DBCrypt().gensalt());
      await SecureStorage.savePinHash(hash);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN changed successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not change PIN.')),
        );
      }
    }
  }

  Future<void> _saveEmergencyContact() async {
    final name = _contactNameCtrl.text.trim();
    final phone = _contactPhoneCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty) return;

    setState(() => _contactSaving = true);
    try {
      await ref.read(authRepositoryProvider).saveEmergencyContact(
            name: name,
            phone: phone,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Emergency contact saved.')),
        );
        FocusScope.of(context).unfocus();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save contact. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _contactSaving = false);
    }
  }

  Future<void> _removeEmergencyContact() async {
    try {
      await ref.read(authRepositoryProvider).deleteEmergencyContact();
      _contactNameCtrl.clear();
      _contactPhoneCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Contact removed.')));
      }
    } catch (_) {}
  }

  Future<void> _confirmReset() async {
    // Verify PIN first
    final pin = await showPinDialog(context, title: 'Enter your PIN');
    if (pin == null || !mounted) return;

    try {
      final result = await ref.read(authRepositoryProvider).verifyPin(pin);
      final success = result['success'] as bool? ?? false;
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wrong PIN.')),
          );
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not verify PIN.')),
        );
      }
      return;
    }

    if (!mounted) return;

    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Echoe?'),
        content: const Text(
            'This deletes everything. Permanently. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                Text('Yes, reset', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Wipe account on backend, then clear local storage
    try {
      await ref.read(authRepositoryProvider).wipeAccount(pin);
    } catch (_) {
      // Even if backend wipe fails, clear locally
    }
    await SecureStorage.clearAll();
    if (mounted) context.go('/onboarding/language');
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
              ))
              .animate()
              .fadeIn(duration: 300.ms),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Voice'),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'female', label: Text('Female')),
                ButtonSegment(value: 'male', label: Text('Male')),
              ],
              selected: {_voice},
              showSelectedIcon: false,
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
          // Privacy
          Text('PRIVACY',
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ))
              .animate()
              .fadeIn(duration: 300.ms, delay: 100.ms),
          const SizedBox(height: 8),
          if (_vaultLoading)
            const ListTile(
              title: Text('Vault Mode'),
              trailing: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            SwitchListTile(
              title: const Text('Vault Mode'),
              subtitle: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _vaultEnabled
                      ? 'Sessions are saved and auto-delete after 7 days.'
                      : 'Enable to save and browse past sessions.',
                  key: ValueKey(_vaultEnabled),
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              value: _vaultEnabled,
              onChanged: _toggleVault,
            ),
          SwitchListTile(
            title: const Text('Biometric Unlock'),
            subtitle: Text(
              'Use fingerprint or face to unlock Echoe.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            value: _biometricEnabled,
            onChanged: _toggleBiometric,
          ),
          ListTile(
            title: const Text('Change PIN'),
            subtitle: Text(
              'Update your 4-digit security PIN.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _changePin,
          ),
          const Divider(height: 32),

          // Emergency contact
          Text('EMERGENCY CONTACT',
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ))
              .animate()
              .fadeIn(duration: 300.ms, delay: 150.ms),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'If Echoe detects you\'re in crisis 3 times, it will suggest you reach out to this person.',
              style: textTheme.bodySmall
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contactNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. Mom, Best friend',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _contactPhoneCtrl,
            decoration: const InputDecoration(
              labelText: 'Phone number',
              hintText: '+91 98765 43210',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _contactSaving ? null : _saveEmergencyContact,
                  child: _contactSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save contact'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: _removeEmergencyContact,
                child: const Text('Remove'),
              ),
            ],
          ),
          const Divider(height: 32),

          // Danger zone
          Text('DANGER ZONE',
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.error,
              ))
              .animate()
              .fadeIn(duration: 300.ms, delay: 200.ms),
          const SizedBox(height: 8),
          ListTile(
            title: Text(
              'Reset Echoe',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.error),
            ),
            subtitle: const Text('Delete everything. Permanently.'),
            onTap: () {
              HapticFeedback.mediumImpact();
              _confirmReset();
            },
          ),
          const Divider(height: 32),
          // About
          Text('ABOUT',
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ))
              .animate()
              .fadeIn(duration: 300.ms, delay: 300.ms),
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

  void _showCrisisResources(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Crisis Resources'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('iCall \u2014 9152987821 (24/7)'),
            SizedBox(height: 8),
            Text('Vandrevala Foundation \u2014 1860-2662-345 (24/7)'),
            SizedBox(height: 8),
            Text('AASRA \u2014 9820466726 (24/7)'),
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
