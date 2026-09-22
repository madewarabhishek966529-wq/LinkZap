import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_theme.dart';
import '../../core/services/haptic_service.dart';
import '../../data/models/qr_code_model.dart';
import '../generator/generator_provider.dart';
import '../history/history_provider.dart';
import '../preview/qr_preview_screen.dart';
import '../settings/settings_provider.dart';
import '../settings/settings_screen.dart';
import '../../shared/buttons/zap_button.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _wifiSsidController = TextEditingController();
  final TextEditingController _wifiPassController = TextEditingController();
  String _clipboardUrl = '';
  bool _showClipboardBanner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkClipboard();
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _wifiSsidController.dispose();
    _wifiPassController.dispose();
    super.dispose();
  }

  Future<void> _checkClipboard() async {
    final settings = ref.read(settingsProvider);
    if (!settings.enableClipboardDetection) return;

    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null && data.text!.isNotEmpty) {
        final text = data.text!.trim();
        if (text != _clipboardUrl && (text.startsWith('http://') || text.startsWith('https://') || text.contains('.'))) {
          if (mounted) {
            setState(() {
              _clipboardUrl = text;
              _showClipboardBanner = true;
            });
          }
        }
      }
    } catch (_) {}
  }

  void _onZapPressed() {
    final generatorNotifier = ref.read(generatorProvider.notifier);
    final isValid = generatorNotifier.validateInput();

    if (isValid) {
      final model = ref.read(generatorProvider).toQrModel();
      // Save to history automatically
      ref.read(historyProvider.notifier).addQrCode(model);

      HapticService.mediumImpact();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QrPreviewScreen(initialModel: model),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final genState = ref.watch(generatorProvider);
    final genNotifier = ref.read(generatorProvider.notifier);
    final historyState = ref.watch(historyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                  fontFamily: 'Outfit',
                ),
                children: const [
                  TextSpan(text: 'Link'),
                  TextSpan(text: 'Zap', style: TextStyle(color: AppTheme.zapPrimary)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              HapticService.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clipboard detection banner
            if (_showClipboardBanner)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.zapPrimary.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.zapPrimary.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.content_paste_rounded, color: AppTheme.zapPrimary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Copied Link Detected',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            _clipboardUrl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.zapPrimary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        setState(() {
                          _inputController.text = _clipboardUrl;
                          _showClipboardBanner = false;
                        });
                        genNotifier.setRawInput(_clipboardUrl);
                        _onZapPressed();
                      },
                      child: const Text('⚡ Zap', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        setState(() {
                          _showClipboardBanner = false;
                        });
                      },
                    ),
                  ],
                ),
              ),

            // Tagline
            Text(
              'Paste. Zap. Share.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Smart Input Type Selector Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: QrType.values.map((t) {
                  final isSelected = genState.type == t;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isSelected,
                      showCheckmark: false,
                      avatar: Icon(
                        t.icon,
                        size: 18,
                        color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      label: Text(t.displayName),
                      labelStyle: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      selectedColor: AppTheme.zapPrimary,
                      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
                      onSelected: (selected) {
                        if (selected) {
                          HapticService.selectionClick();
                          genNotifier.setType(t);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Main Input Field
            if (genState.type == QrType.wifi) ...[
              TextField(
                controller: _wifiSsidController,
                decoration: const InputDecoration(
                  labelText: 'Wi-Fi Network Name (SSID)',
                  prefixIcon: Icon(Icons.wifi_rounded),
                ),
                onChanged: (val) {
                  genNotifier.updateWifiDetails(ssid: val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _wifiPassController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
                onChanged: (val) {
                  genNotifier.updateWifiDetails(password: val);
                },
              ),
            ] else ...[
              TextField(
                controller: _inputController,
                maxLines: genState.type == QrType.text ? 4 : 2,
                keyboardType: genState.type == QrType.url
                    ? TextInputType.url
                    : genState.type == QrType.phone
                        ? TextInputType.phone
                        : genState.type == QrType.email
                            ? TextInputType.emailAddress
                            : TextInputType.text,
                decoration: InputDecoration(
                  hintText: genState.type == QrType.url
                      ? 'Paste link (e.g. github.com)...'
                      : genState.type == QrType.phone
                          ? 'Enter phone number...'
                          : genState.type == QrType.email
                              ? 'Enter email address...'
                              : 'Enter text here...',
                  prefixIcon: Icon(genState.type.icon),
                  suffixIcon: _inputController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _inputController.clear();
                            genNotifier.setRawInput('');
                          },
                        )
                      : IconButton(
                          icon: const Icon(Icons.content_paste_rounded),
                          onPressed: () async {
                            final data = await Clipboard.getData(Clipboard.kTextPlain);
                            if (data != null && data.text != null) {
                              _inputController.text = data.text!;
                              genNotifier.setRawInput(data.text!);
                            }
                          },
                        ),
                ),
                onChanged: (text) {
                  genNotifier.setRawInput(text);
                },
              ),
            ],

            // Validation Error message if any
            if (genState.errorMessage != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppTheme.zapError, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    genState.errorMessage!,
                    style: const TextStyle(color: AppTheme.zapError, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // ZAP BUTTON
            ZapButton(
              onPressed: _onZapPressed,
            ),

            const SizedBox(height: 32),

            // Quick Create Section
            const Text(
              'Quick Create',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildQuickCard(context, QrType.url, 'Website', Icons.language_rounded, genNotifier),
                const SizedBox(width: 12),
                _buildQuickCard(context, QrType.wifi, 'Wi-Fi', Icons.wifi_rounded, genNotifier),
                const SizedBox(width: 12),
                _buildQuickCard(context, QrType.phone, 'Phone', Icons.phone_rounded, genNotifier),
                const SizedBox(width: 12),
                _buildQuickCard(context, QrType.email, 'Email', Icons.email_rounded, genNotifier),
              ],
            ),

            const SizedBox(height: 32),

            // Recent Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent QR Codes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (historyState.items.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      // Handled by tab navigation or tap
                    },
                    child: const Text('See All', style: TextStyle(color: AppTheme.zapPrimaryDark)),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (historyState.items.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.qr_code_2_rounded, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'No recent QR codes yet.',
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Paste content above and tap ⚡ ZAP QR',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: historyState.items.take(5).length,
                  itemBuilder: (context, index) {
                    final item = historyState.items[index];
                    return _buildRecentCard(context, item);
                  },
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCard(BuildContext context, QrType type, String title, IconData icon, GeneratorNotifier notifier) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Material(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            HapticService.selectionClick();
            notifier.setType(type);
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              children: [
                Icon(icon, color: AppTheme.zapPrimary, size: 26),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentCard(BuildContext context, QrCodeModel item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticService.selectionClick();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QrPreviewScreen(initialModel: item),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(item.type.icon, size: 20, color: AppTheme.zapPrimary),
                    if (item.isFavorite)
                      const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                  ],
                ),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  item.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
