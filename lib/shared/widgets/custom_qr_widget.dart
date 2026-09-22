import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../data/models/qr_code_model.dart';

class CustomQrWidget extends StatelessWidget {
  final QrCodeModel model;
  final double size;
  final bool embeddedLogoEnabled;

  const CustomQrWidget({
    super.key,
    required this.model,
    this.size = 260.0,
    this.embeddedLogoEnabled = true,
  });

  int _mapErrorCorrection(QrErrorCorrection level) {
    switch (level) {
      case QrErrorCorrection.low:
        return QrErrorCorrectLevel.L;
      case QrErrorCorrection.medium:
        return QrErrorCorrectLevel.M;
      case QrErrorCorrection.quartile:
        return QrErrorCorrectLevel.Q;
      case QrErrorCorrection.high:
        return QrErrorCorrectLevel.H;
    }
  }

  QrDataModuleShape _mapDataModuleShape(DotStyle style) {
    switch (style) {
      case DotStyle.circle:
        return QrDataModuleShape.circle;
      case DotStyle.rounded:
        return QrDataModuleShape.circle; // QrDataModuleShape supports circle or square
      case DotStyle.square:
        return QrDataModuleShape.square;
    }
  }

  QrEyeShape _mapEyeShape(EyeStyle style) {
    switch (style) {
      case EyeStyle.circle:
      case EyeStyle.rounded:
        return QrEyeShape.circle;
      case EyeStyle.square:
        return QrEyeShape.square;
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? logoProvider;
    if (embeddedLogoEnabled && model.logoPath != null && model.logoPath!.isNotEmpty) {
      final file = File(model.logoPath!);
      if (file.existsSync()) {
        logoProvider = FileImage(file);
      }
    }

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(model.margin),
      decoration: BoxDecoration(
        color: model.backgroundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: QrImageView(
          data: model.content.isEmpty ? 'https://linkzap.app' : model.content,
          version: QrVersions.auto,
          size: size - (model.margin * 2),
          backgroundColor: model.backgroundColor,
          errorCorrectionLevel: _mapErrorCorrection(model.errorCorrection),
          dataModuleStyle: QrDataModuleStyle(
            dataModuleShape: _mapDataModuleShape(model.dotStyle),
            color: model.foregroundColor,
          ),
          eyeStyle: QrEyeStyle(
            eyeShape: _mapEyeShape(model.eyeStyle),
            color: model.foregroundColor,
          ),
          embeddedImage: logoProvider,
          embeddedImageStyle: logoProvider != null
              ? QrEmbeddedImageStyle(
                  size: Size(size * 0.22, size * 0.22),
                )
              : null,
          gapless: true,
          errorStateBuilder: (ctx, err) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.error_outline, color: Colors.red, size: 36),
                  SizedBox(height: 8),
                  Text(
                    'QR Error',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
