import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NexoraLogo extends StatelessWidget {
  final double size;

  const NexoraLogo({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(size * 0.3), // squircle
      ),
      alignment: Alignment.center,
      child: Text(
        'N',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: size * 0.55,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}