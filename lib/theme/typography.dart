import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class C8PTypo {
  static TextStyle disp({double size = 24, Color color = C8P.chalk, FontWeight weight = FontWeight.w700}) {
    return GoogleFonts.antonio(
      fontSize: size, color: color, fontWeight: weight,
      letterSpacing: -0.02 * size, height: 0.9,
    );
  }

  static TextStyle mono({double size = 11, Color color = C8P.mute, double letterSpacing = 0.18}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size, color: color,
      letterSpacing: letterSpacing * size, fontWeight: FontWeight.w500,
    );
  }

  static TextStyle sans({double size = 13, Color color = C8P.chalk, FontWeight weight = FontWeight.w500}) {
    return GoogleFonts.manrope(
      fontSize: size, color: color, fontWeight: weight,
    );
  }
}
