import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/breathing_orb.dart';

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen> {
  int _selectedMinutes = 3;
  bool _isActive = false;
  int _secondsRemaining = 0;
  Timer? _timer;
  String _cueText = 'Breathe in...';

  final _phaseDurations = [4, 2, 4, 2]; // seconds per phase
  final _phaseLabels = ['Breathe in...', 'Hold.', 'Breathe out...', 'Pause.'];

  void _start() {
    setState(() {
      _isActive = true;
      _secondsRemaining = _selectedMinutes * 60;
      _cueText = _phaseLabels[0];
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsRemaining <= 0) {
        _stop();
        return;
      }
      setState(() {
        _secondsRemaining--;
        // Cycle breath phases
        final totalCycle = _phaseDurations.reduce((a, b) => a + b);
        final elapsed = (_selectedMinutes * 60 - _secondsRemaining) % totalCycle;
        int acc = 0;
        for (int i = 0; i < _phaseDurations.length; i++) {
          acc += _phaseDurations[i];
          if (elapsed < acc) {
            _cueText = _phaseLabels[i];
            break;
          }
        }
      });
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() {
      _isActive = false;
      _cueText = 'Well done.';
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Breathe with Echoe',
                  style: textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                const BreathingOrb(size: 250),
                const SizedBox(height: 32),
                Text(
                  _cueText,
                  style: GoogleFonts.notoSerif(
                    fontSize: 20,
                    height: 1.5,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                if (_isActive) ...[
                  const SizedBox(height: 16),
                  Text(
                    _formatTime(_secondsRemaining),
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
                const SizedBox(height: 48),
                if (!_isActive) ...[
                  // Duration picker
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [3, 5, 10].map((m) {
                      final selected = _selectedMinutes == m;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: ChoiceChip(
                          label: Text('$m min'),
                          selected: selected,
                          selectedColor: AppColors.primaryContainer,
                          backgroundColor: AppColors.surfaceContainerLow,
                          labelStyle: TextStyle(
                            color: selected
                                ? AppColors.onPrimary
                                : AppColors.onSurface,
                          ),
                          onSelected: (_) =>
                              setState(() => _selectedMinutes = m),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _start,
                    child: const Text('Begin'),
                  ),
                ] else
                  OutlinedButton(
                    onPressed: _stop,
                    child: const Text('Stop'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
