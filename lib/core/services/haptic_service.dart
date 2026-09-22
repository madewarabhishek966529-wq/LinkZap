import 'package:flutter/services.dart';

class HapticService {
  static bool enabled = true;

  static void lightImpact() {
    if (enabled) {
      HapticFeedback.lightImpact();
    }
  }

  static void mediumImpact() {
    if (enabled) {
      HapticFeedback.mediumImpact();
    }
  }

  static void heavyImpact() {
    if (enabled) {
      HapticFeedback.heavyImpact();
    }
  }

  static void selectionClick() {
    if (enabled) {
      HapticFeedback.selectionClick();
    }
  }

  static void vibrate() {
    if (enabled) {
      HapticFeedback.vibrate();
    }
  }
}
