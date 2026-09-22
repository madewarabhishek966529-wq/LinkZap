import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../core/services/haptic_service.dart';
import '../features/generator/generator_provider.dart';
import '../features/home/home_screen.dart';
import '../features/history/history_screen.dart';
import '../features/preview/qr_preview_screen.dart';
import '../features/scanner/scanner_screen.dart';
import '../app/theme/app_theme.dart';

class MainNavigationScaffold extends ConsumerStatefulWidget {
  const MainNavigationScaffold({super.key});

  @override
  ConsumerState<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends ConsumerState<MainNavigationScaffold> {
  int _currentIndex = 0;
  StreamSubscription? _intentDataStreamSubscription;

  final List<Widget> _screens = const [
    HomeScreen(),
    HistoryScreen(),
    ScannerScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initShareIntentListener();
  }

  void _initShareIntentListener() {
    // For sharing text while app is running in background or active
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((value) {
      if (value.isNotEmpty) {
        final text = value.first.path;
        _processSharedText(text);
      }
    });

    // For sharing text when app is launched via intent
    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      if (value.isNotEmpty) {
        final text = value.first.path;
        _processSharedText(text);
      }
    });
  }

  void _processSharedText(String text) {
    if (text.isEmpty) return;
    final genNotifier = ref.read(generatorProvider.notifier);
    genNotifier.setRawInput(text);
    final model = ref.read(generatorProvider).toQrModel();

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QrPreviewScreen(initialModel: model),
        ),
      );
    }
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            HapticService.selectionClick();
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: AppTheme.zapPrimary,
          unselectedItemColor: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.bolt_rounded),
              activeIcon: Icon(Icons.bolt_rounded, color: AppTheme.zapPrimary),
              label: '⚡ Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              activeIcon: Icon(Icons.history_rounded, color: AppTheme.zapPrimary),
              label: '◷ History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner_rounded),
              activeIcon: Icon(Icons.qr_code_scanner_rounded, color: AppTheme.zapPrimary),
              label: '◉ Scan',
            ),
          ],
        ),
      ),
    );
  }
}
