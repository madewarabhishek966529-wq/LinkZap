import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_theme.dart';
import '../../core/services/haptic_service.dart';
import '../../shared/animations/success_toast.dart';
import '../history/history_provider.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        children: [
          // APPEARANCE SECTION
          const Text('Appearance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.zapPrimary)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
            ),
            child: RadioGroup<ThemeMode>(
              groupValue: settings.themeMode,
              onChanged: (mode) {
                if (mode != null) {
                  HapticService.selectionClick();
                  settingsNotifier.setThemeMode(mode);
                }
              },
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.system,
                    title: const Text('System Default'),
                  ),
                  const Divider(height: 1),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.light,
                    title: const Text('Light Mode'),
                  ),
                  const Divider(height: 1),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.dark,
                    title: const Text('Dark Mode'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // BEHAVIOR SECTION
          const Text('Behavior', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.zapPrimary)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Smart Clipboard Detection'),
                  subtitle: const Text('Detect copied links on launch'),
                  value: settings.enableClipboardDetection,
                  activeThumbColor: AppTheme.zapPrimary,
                  onChanged: (val) {
                    HapticService.selectionClick();
                    settingsNotifier.toggleClipboardDetection(val);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Haptic Feedback'),
                  subtitle: const Text('Vibrate on key actions & Zaps'),
                  value: settings.enableHaptics,
                  activeThumbColor: AppTheme.zapPrimary,
                  onChanged: (val) {
                    settingsNotifier.toggleHaptics(val);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // STORAGE SECTION
          const Text('Storage & Data', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.zapPrimary)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
            ),
            child: ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text('Clear All History', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear All History?'),
                    content: const Text('This will delete all saved QR codes from SQLite storage.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(historyProvider.notifier).clearAll();
                          Navigator.pop(context);
                          SuccessToast.show(context, '✓ History Cleared');
                        },
                        child: const Text('Clear', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // ABOUT & PRIVACY SECTION
          const Text('About', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.zapPrimary)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
            ),
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline_rounded, color: AppTheme.zapPrimary),
                  title: Text('App Version'),
                  trailing: Text('1.0.0 (MVP)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppTheme.zapPrimary),
                  title: const Text('Privacy & Local-First Architecture'),
                  subtitle: const Text('All QR data and images stay 100% on your device.'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Privacy First'),
                        content: const Text(
                          'LinkZap operates completely offline. No tracking, no backend servers, and no data collection. Everything is saved locally on your device in SQLite.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.code_rounded, color: AppTheme.zapPrimary),
                  title: const Text('Open Source Licenses'),
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName: 'LinkZap',
                      applicationVersion: '1.0.0',
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
