import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppText {
  static TextStyle get score => GoogleFonts.barlowCondensed(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.1,
  );
  static TextStyle get team =>
      GoogleFonts.barlowCondensed(fontSize: 26, fontWeight: FontWeight.w700);
  static TextStyle get label => GoogleFonts.sourceSans3(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
  );
  static TextTheme theme(Brightness brightness) =>
      GoogleFonts.sourceSans3TextTheme(
        ThemeData(brightness: brightness).textTheme,
      );
}
