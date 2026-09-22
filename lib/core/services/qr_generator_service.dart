import '../../data/models/qr_code_model.dart';

class QrGeneratorService {
  static QrType detectInputType(String rawInput) {
    final input = rawInput.trim();
    if (input.isEmpty) return QrType.text;

    // Check Wi-Fi pattern
    if (input.toUpperCase().startsWith('WIFI:')) {
      return QrType.wifi;
    }

    // Check Email pattern
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (emailRegex.hasMatch(input) || input.startsWith('mailto:')) {
      return QrType.email;
    }

    // Check URL pattern
    final urlRegex = RegExp(
      r'^(https?:\/\/)?([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}(:\d+)?(\/[^\s]*)?$',
      caseSensitive: false,
    );
    if (urlRegex.hasMatch(input) || input.startsWith('http://') || input.startsWith('https://')) {
      return QrType.url;
    }

    // Check Phone pattern
    final phoneRegex = RegExp(r'^\+?[0-9\s\-\(\)]{7,15}$');
    if (phoneRegex.hasMatch(input) || input.startsWith('tel:')) {
      return QrType.phone;
    }

    return QrType.text;
  }

  static String normalizeUrl(String input) {
    var trimmed = input.trim();
    if (trimmed.isEmpty) return trimmed;

    if (!trimmed.toLowerCase().startsWith('http://') &&
        !trimmed.toLowerCase().startsWith('https://')) {
      return 'https://$trimmed';
    }
    return trimmed;
  }

  static String formatPayload({
    required QrType type,
    required String rawContent,
    String? wifiSsid,
    String? wifiPassword,
    String? wifiSecurity,
  }) {
    final content = rawContent.trim();

    switch (type) {
      case QrType.url:
        return normalizeUrl(content);
      case QrType.phone:
        if (content.startsWith('tel:')) return content;
        final cleanPhone = content.replaceAll(RegExp(r'[^\d+]'), '');
        return 'tel:$cleanPhone';
      case QrType.email:
        if (content.startsWith('mailto:')) return content;
        return 'mailto:$content';
      case QrType.wifi:
        final ssid = wifiSsid ?? content;
        final pass = wifiPassword ?? '';
        final sec = wifiSecurity ?? 'WPA';
        return 'WIFI:S:$ssid;T:$sec;P:$pass;;';
      case QrType.text:
        return content;
    }
  }

  static String generateTitle(QrType type, String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return 'New QR Code';

    switch (type) {
      case QrType.url:
        try {
          final uri = Uri.parse(normalizeUrl(trimmed));
          return uri.host.isNotEmpty ? uri.host : 'Website QR';
        } catch (_) {
          return 'URL QR';
        }
      case QrType.phone:
        return 'Phone: ${trimmed.replaceAll('tel:', '')}';
      case QrType.email:
        return 'Email: ${trimmed.replaceAll('mailto:', '')}';
      case QrType.wifi:
        return 'Wi-Fi Network';
      case QrType.text:
        return trimmed.length > 25 ? '${trimmed.substring(0, 25)}...' : trimmed;
    }
  }
}
