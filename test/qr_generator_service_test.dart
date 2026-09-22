import 'package:flutter_test/flutter_test.dart';
import 'package:linkzap/core/services/qr_generator_service.dart';
import 'package:linkzap/data/models/qr_code_model.dart';

void main() {
  group('QrGeneratorService Tests', () {
    test('detectInputType detects URL correctly', () {
      expect(QrGeneratorService.detectInputType('https://github.com'), QrType.url);
      expect(QrGeneratorService.detectInputType('github.com/example'), QrType.url);
      expect(QrGeneratorService.detectInputType('http://test.org'), QrType.url);
    });

    test('detectInputType detects Phone correctly', () {
      expect(QrGeneratorService.detectInputType('9876543210'), QrType.phone);
      expect(QrGeneratorService.detectInputType('+1 234 567 8900'), QrType.phone);
    });

    test('detectInputType detects Email correctly', () {
      expect(QrGeneratorService.detectInputType('hello@example.com'), QrType.email);
    });

    test('detectInputType detects Wi-Fi correctly', () {
      expect(QrGeneratorService.detectInputType('WIFI:S:HomeWifi;P:1234;;'), QrType.wifi);
    });

    test('normalizeUrl prepends https:// when missing', () {
      expect(QrGeneratorService.normalizeUrl('github.com/example'), 'https://github.com/example');
      expect(QrGeneratorService.normalizeUrl('https://github.com'), 'https://github.com');
    });

    test('formatPayload builds valid payload for Wi-Fi', () {
      final payload = QrGeneratorService.formatPayload(
        type: QrType.wifi,
        rawContent: '',
        wifiSsid: 'MyRouter',
        wifiPassword: 'SecretPassword',
        wifiSecurity: 'WPA',
      );
      expect(payload, 'WIFI:S:MyRouter;T:WPA;P:SecretPassword;;');
    });
  });
}
