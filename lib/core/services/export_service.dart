import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/qr_code_model.dart';

enum QrExportQuality {
  standard(512, 'Standard (512x512)'),
  high(1024, 'High (1024x1024)'),
  ultra(2048, 'Ultra (2048x2048)');

  final int dimension;
  final String label;
  const QrExportQuality(this.dimension, this.label);
}

class ExportService {
  static int _mapErrorCorrection(QrErrorCorrection level) {
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

  static Future<Uint8List> generatePngBytes({
    required QrCodeModel model,
    required QrExportQuality quality,
  }) async {
    final painter = QrPainter(
      data: model.content,
      version: QrVersions.auto,
      errorCorrectionLevel: _mapErrorCorrection(model.errorCorrection),
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: model.foregroundColor,
      ),
      eyeStyle: QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: model.foregroundColor,
      ),
      gapless: true,
    );

    final size = quality.dimension.toDouble();
    final uiImage = await painter.toImage(size);
    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Failed to render QR Code to PNG');
    }

    return byteData.buffer.asUint8List();
  }

  static String buildFilename(String title) {
    final cleanTitle = title
        .replaceAll(RegExp(r'[^\w\s\-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    final dateStr = DateTime.now().toIso8601String().split('T').first;
    final name = cleanTitle.isNotEmpty ? cleanTitle : 'QR';
    return 'LinkZap_${name}_$dateStr.png';
  }

  static Future<File> saveToTempFile({
    required QrCodeModel model,
    required QrExportQuality quality,
  }) async {
    final bytes = await generatePngBytes(model: model, quality: quality);
    final tempDir = await getTemporaryDirectory();
    final filename = buildFilename(model.title);
    final file = File('${tempDir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }

  static Future<void> downloadToGallery({
    required QrCodeModel model,
    required QrExportQuality quality,
  }) async {
    final tempFile = await saveToTempFile(model: model, quality: quality);
    await Gal.putImage(tempFile.path);
  }

  static Future<void> shareQr({
    required QrCodeModel model,
    required QrExportQuality quality,
    bool includeText = true,
  }) async {
    final file = await saveToTempFile(model: model, quality: quality);
    final xFile = XFile(file.path);

    if (includeText) {
      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: 'QR Code created with LinkZap:\n${model.content}',
          subject: model.title,
        ),
      );
    } else {
      await SharePlus.instance.share(
        ShareParams(files: [xFile], subject: model.title),
      );
    }
  }
}
