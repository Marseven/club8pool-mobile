import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';

class Ball8 extends StatelessWidget {
  final double size;
  const Ball8({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: [Color(0xFF444444), Color(0xFF0A0A0B), Color(0xFF000000)],
          stops: [0, 0.6, 1],
        ),
      ),
      child: Center(
        child: Container(
          width: size * 0.42,
          height: size * 0.42,
          margin: EdgeInsets.only(bottom: size * 0.15),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: C8P.chalk,
          ),
          child: Center(
            child: Text(
              '8',
              style: GoogleFonts.antonio(
                fontSize: size * 0.32,
                fontWeight: FontWeight.w700,
                color: C8P.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
