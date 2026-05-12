import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class EchoCard extends StatelessWidget {
  final String quote;
  final String? dateLabel;
  final VoidCallback? onTap;

  const EchoCard({
    super.key,
    required this.quote,
    this.dateLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A2740), Color(0xFF04122A)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quote,
              style: GoogleFonts.notoSerif(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                height: 1.7,
                color: AppColors.surface,
              ),
            ),
            if (dateLabel != null) ...[
              const SizedBox(height: 16),
              Text(
                dateLabel!.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: AppColors.surfaceDim,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
