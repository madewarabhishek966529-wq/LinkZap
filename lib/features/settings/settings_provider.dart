import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/haptic_service.dart';

class SettingsState {
  final ThemeMode themeMode;
  final bool enableClipboardDetection;
  final bool enableHaptics;
  final Color defaultForegroundColor;
  final Color defaultBackgroundColor;
  final String defaultErrorCorrection;

  SettingsState({
    this.themeMode = ThemeMode.system,
    this.enableClipboardDetection = true,
    this.enableHaptics = true,
    this.defaultForegroundColor = Colors.black,
    this.defaultBackgroundColor = Colors.white,
    this.defaultErrorCorrection = 'M',
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? enableClipboardDetection,
    bool? enableHaptics,
    Color? defaultForegroundColor,
    Color? defaultBackgroundColor,
    String? defaultErrorCorrection,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      enableClipboardDetection: enableClipboardDetection ?? this.enableClipboardDetection,
      enableHaptics: enableHaptics ?? this.enableHaptics,
      defaultForegroundColor: defaultForegroundColor ?? this.defaultForegroundColor,
      defaultBackgroundColor: defaultBackgroundColor ?? this.defaultBackgroundColor,
      defaultErrorCorrection: defaultErrorCorrection ?? this.defaultErrorCorrection,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState());

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void toggleClipboardDetection(bool enabled) {
    state = state.copyWith(enableClipboardDetection: enabled);
  }

  void toggleHaptics(bool enabled) {
    state = state.copyWith(enableHaptics: enabled);
    HapticService.enabled = enabled;
  }

  void setDefaultForegroundColor(Color color) {
    state = state.copyWith(defaultForegroundColor: color);
  }

  void setDefaultBackgroundColor(Color color) {
    state = state.copyWith(defaultBackgroundColor: color);
  }

  void setDefaultErrorCorrection(String ec) {
    state = state.copyWith(defaultErrorCorrection: ec);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
