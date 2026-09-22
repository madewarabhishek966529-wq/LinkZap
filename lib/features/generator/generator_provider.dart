import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/qr_code_model.dart';
import '../../core/services/qr_generator_service.dart';

class GeneratorState {
  final QrType type;
  final String rawInput;
  final String? wifiSsid;
  final String? wifiPassword;
  final String wifiSecurity;
  final Color foregroundColor;
  final Color backgroundColor;
  final DotStyle dotStyle;
  final EyeStyle eyeStyle;
  final QrErrorCorrection errorCorrection;
  final String? logoPath;
  final bool logoIsRounded;
  final double margin;
  final bool isSmartDetected;
  final String? errorMessage;

  GeneratorState({
    this.type = QrType.url,
    this.rawInput = '',
    this.wifiSsid,
    this.wifiPassword,
    this.wifiSecurity = 'WPA',
    this.foregroundColor = Colors.black,
    this.backgroundColor = Colors.white,
    this.dotStyle = DotStyle.square,
    this.eyeStyle = EyeStyle.square,
    this.errorCorrection = QrErrorCorrection.medium,
    this.logoPath,
    this.logoIsRounded = true,
    this.margin = 12.0,
    this.isSmartDetected = true,
    this.errorMessage,
  });

  GeneratorState copyWith({
    QrType? type,
    String? rawInput,
    String? wifiSsid,
    String? wifiPassword,
    String? wifiSecurity,
    Color? foregroundColor,
    Color? backgroundColor,
    DotStyle? dotStyle,
    EyeStyle? eyeStyle,
    QrErrorCorrection? errorCorrection,
    String? logoPath,
    bool? logoIsRounded,
    double? margin,
    bool? isSmartDetected,
    String? errorMessage,
    bool clearError = false,
  }) {
    return GeneratorState(
      type: type ?? this.type,
      rawInput: rawInput ?? this.rawInput,
      wifiSsid: wifiSsid ?? this.wifiSsid,
      wifiPassword: wifiPassword ?? this.wifiPassword,
      wifiSecurity: wifiSecurity ?? this.wifiSecurity,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      dotStyle: dotStyle ?? this.dotStyle,
      eyeStyle: eyeStyle ?? this.eyeStyle,
      errorCorrection: errorCorrection ?? this.errorCorrection,
      logoPath: logoPath ?? this.logoPath,
      logoIsRounded: logoIsRounded ?? this.logoIsRounded,
      margin: margin ?? this.margin,
      isSmartDetected: isSmartDetected ?? this.isSmartDetected,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  String get formattedPayload {
    return QrGeneratorService.formatPayload(
      type: type,
      rawContent: rawInput,
      wifiSsid: wifiSsid,
      wifiPassword: wifiPassword,
      wifiSecurity: wifiSecurity,
    );
  }

  QrCodeModel toQrModel() {
    final title = QrGeneratorService.generateTitle(type, rawInput);
    return QrCodeModel(
      type: type,
      title: title,
      content: formattedPayload,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      dotStyle: dotStyle,
      eyeStyle: eyeStyle,
      errorCorrection: logoPath != null ? QrErrorCorrection.high : errorCorrection,
      logoPath: logoPath,
      logoIsRounded: logoIsRounded,
      margin: margin,
    );
  }
}

class GeneratorNotifier extends StateNotifier<GeneratorState> {
  GeneratorNotifier() : super(GeneratorState());

  void setRawInput(String text) {
    if (state.isSmartDetected) {
      final detected = QrGeneratorService.detectInputType(text);
      state = state.copyWith(
        rawInput: text,
        type: detected,
        clearError: true,
      );
    } else {
      state = state.copyWith(rawInput: text, clearError: true);
    }
  }

  void setType(QrType newType) {
    state = state.copyWith(
      type: newType,
      isSmartDetected: false,
      clearError: true,
    );
  }

  void updateWifiDetails({String? ssid, String? password, String? security}) {
    state = state.copyWith(
      wifiSsid: ssid ?? state.wifiSsid,
      wifiPassword: password ?? state.wifiPassword,
      wifiSecurity: security ?? state.wifiSecurity,
      clearError: true,
    );
  }

  void setForegroundColor(Color color) {
    state = state.copyWith(foregroundColor: color);
  }

  void setBackgroundColor(Color color) {
    state = state.copyWith(backgroundColor: color);
  }

  void setDotStyle(DotStyle style) {
    state = state.copyWith(dotStyle: style);
  }

  void setEyeStyle(EyeStyle style) {
    state = state.copyWith(eyeStyle: style);
  }

  void setErrorCorrection(QrErrorCorrection level) {
    state = state.copyWith(errorCorrection: level);
  }

  void setLogoPath(String? path) {
    // When logo is added, elevate error correction to High as per PRD requirement
    state = state.copyWith(
      logoPath: path,
      errorCorrection: path != null ? QrErrorCorrection.high : state.errorCorrection,
    );
  }

  void setLogoIsRounded(bool rounded) {
    state = state.copyWith(logoIsRounded: rounded);
  }

  void setMargin(double margin) {
    state = state.copyWith(margin: margin);
  }

  void applyTemplate(String templateName) {
    switch (templateName) {
      case 'Minimal':
        state = state.copyWith(
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          dotStyle: DotStyle.square,
          eyeStyle: EyeStyle.square,
          errorCorrection: QrErrorCorrection.medium,
        );
        break;
      case 'Business':
        state = state.copyWith(
          foregroundColor: const Color(0xFF0F172A),
          backgroundColor: Colors.white,
          dotStyle: DotStyle.rounded,
          eyeStyle: EyeStyle.rounded,
          errorCorrection: QrErrorCorrection.high,
        );
        break;
      case 'Portfolio':
        state = state.copyWith(
          foregroundColor: const Color(0xFF4F46E5),
          backgroundColor: const Color(0xFFF8FAFC),
          dotStyle: DotStyle.circle,
          eyeStyle: EyeStyle.circle,
          errorCorrection: QrErrorCorrection.high,
        );
        break;
      case 'Social':
        state = state.copyWith(
          foregroundColor: const Color(0xFF9333EA),
          backgroundColor: const Color(0xFFFDF2F8),
          dotStyle: DotStyle.circle,
          eyeStyle: EyeStyle.rounded,
          errorCorrection: QrErrorCorrection.high,
        );
        break;
      case 'Event':
        state = state.copyWith(
          foregroundColor: const Color(0xFF059669),
          backgroundColor: const Color(0xFFECFDF5),
          dotStyle: DotStyle.rounded,
          eyeStyle: EyeStyle.circle,
          errorCorrection: QrErrorCorrection.medium,
        );
        break;
      case 'Restaurant':
        state = state.copyWith(
          foregroundColor: const Color(0xFFD97706),
          backgroundColor: const Color(0xFFFFFBEB),
          dotStyle: DotStyle.square,
          eyeStyle: EyeStyle.rounded,
          errorCorrection: QrErrorCorrection.medium,
        );
        break;
      case 'Wi-Fi':
        state = state.copyWith(
          foregroundColor: const Color(0xFF2563EB),
          backgroundColor: Colors.white,
          dotStyle: DotStyle.circle,
          eyeStyle: EyeStyle.circle,
          errorCorrection: QrErrorCorrection.high,
        );
        break;
      case 'Payment':
        state = state.copyWith(
          foregroundColor: const Color(0xFF0D9488),
          backgroundColor: Colors.white,
          dotStyle: DotStyle.rounded,
          eyeStyle: EyeStyle.square,
          errorCorrection: QrErrorCorrection.high,
        );
        break;
    }
  }

  bool validateInput() {
    final input = state.rawInput.trim();
    if (input.isEmpty && state.type != QrType.wifi) {
      state = state.copyWith(errorMessage: 'Please enter something to generate a QR code.');
      return false;
    }

    if (state.type == QrType.url) {
      final urlRegex = RegExp(r'^(https?:\/\/)?([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}(:\d+)?(\/[^\s]*)?$', caseSensitive: false);
      if (!urlRegex.hasMatch(input)) {
        state = state.copyWith(errorMessage: "That doesn't look like a valid URL.");
        return false;
      }
    }

    if (state.type == QrType.wifi) {
      final ssid = (state.wifiSsid ?? state.rawInput).trim();
      if (ssid.isEmpty) {
        state = state.copyWith(errorMessage: 'Please enter a Wi-Fi SSID network name.');
        return false;
      }
    }

    state = state.copyWith(clearError: true);
    return true;
  }

  void loadFromModel(QrCodeModel model) {
    state = GeneratorState(
      type: model.type,
      rawInput: model.content,
      foregroundColor: model.foregroundColor,
      backgroundColor: model.backgroundColor,
      dotStyle: model.dotStyle,
      eyeStyle: model.eyeStyle,
      errorCorrection: model.errorCorrection,
      logoPath: model.logoPath,
      logoIsRounded: model.logoIsRounded,
      margin: model.margin,
      isSmartDetected: false,
    );
  }
}

final generatorProvider = StateNotifierProvider<GeneratorNotifier, GeneratorState>((ref) {
  return GeneratorNotifier();
});
