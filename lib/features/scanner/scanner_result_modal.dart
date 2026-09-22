import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme/app_theme.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/qr_generator_service.dart';
import '../../shared/animations/success_toast.dart';
import '../generator/generator_provider.dart';
import '../preview/qr_preview_screen.dart';

class ScannerResultModal extends ConsumerWidget {
  final String rawBarcodeData;

  const ScannerResultModal({super.key, required this.rawBarcodeData});

  Future<void> _launchUrlSafely(BuildContext context, String urlString) async {
    final normalized = QrGeneratorService.normalizeUrl(urlString);
    final uri = Uri.parse(normalized);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open URL.')),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid link target.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = QrGeneratorService.detectInputType(rawBarcodeData);
    final isUrl = type == Uri || rawBarcodeData.startsWith('http://') || rawBarcodeData.startsWith('https://') || rawBarcodeData.contains('.');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String domain = '';
    if (isUrl) {
      try {
        final uri = Uri.parse(QrGeneratorService.normalizeUrl(rawBarcodeData));
        domain = uri.host;
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.zapPrimary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.zapPrimary, size: 28),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('QR Code Detected', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Type: ${type.displayName}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Safety Box
          if (domain.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceVariant : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.zapPrimary.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security_rounded, color: AppTheme.zapPrimary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87),
                        children: [
                          const TextSpan(text: 'Destination Domain: '),
                          TextSpan(
                            text: domain,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.zapPrimaryDark),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Content Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceVariant : AppTheme.lightSurfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SelectableText(
              rawBarcodeData,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),

          const SizedBox(height: 24),

          // Main Action Buttons
          if (isUrl) ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.zapPrimary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open Link', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                onPressed: () {
                  HapticService.selectionClick();
                  _launchUrlSafely(context, rawBarcodeData);
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy'),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: rawBarcodeData));
                    if (context.mounted) {
                      SuccessToast.show(context, '✓ Copied to Clipboard');
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Share'),
                  onPressed: () {
                    Share.share(rawBarcodeData);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.bolt_rounded, color: AppTheme.zapPrimary, size: 18),
                  label: const Text('Zap QR'),
                  onPressed: () {
                    Navigator.pop(context);
                    ref.read(generatorProvider.notifier).setRawInput(rawBarcodeData);
                    final model = ref.read(generatorProvider).toQrModel();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QrPreviewScreen(initialModel: model),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
