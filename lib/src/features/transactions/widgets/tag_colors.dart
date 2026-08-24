import 'package:flutter/material.dart';

Color foregroundFor(Color color) {
  return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
      ? Colors.white
      : const Color(0xFF091312);
}
