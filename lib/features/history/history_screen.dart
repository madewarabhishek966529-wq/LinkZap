import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_theme.dart';
import '../../core/services/export_service.dart';
import '../../core/services/haptic_service.dart';
import '../../data/models/qr_code_model.dart';
import '../../shared/animations/success_toast.dart';
import '../collections/collections_provider.dart';

import '../preview/qr_preview_screen.dart';
import 'collections_screen.dart';
import 'history_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inDays == 0 && now.day == dt.day) {
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      return 'Today · $hour:$minute $period';
    } else if (difference.inDays == 1 || (now.day - dt.day == 1 && now.month == dt.month)) {
      return 'Yesterday';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyProvider);
    final historyNotifier = ref.read(historyProvider.notifier);
    final collections = ref.watch(collectionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History & Saved', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open_rounded),
            tooltip: 'Collections',
            onPressed: () {
              HapticService.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CollectionsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Clear History',
            onPressed: () {
              if (historyState.items.isEmpty) return;
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear History?'),
                  content: const Text('This will delete all saved QR codes. This action cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        historyNotifier.clearAll();
                        Navigator.pop(context);
                        SuccessToast.show(context, '✓ History Cleared');
                      },
                      child: const Text('Clear All', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search history by title, URL or type...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          historyNotifier.setSearchQuery('');
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                historyNotifier.setSearchQuery(val);
              },
            ),
          ),

          // Filters Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: !historyState.favoritesOnly && historyState.selectedCollectionId == null,
                  onSelected: (val) {
                    if (val) {
                      HapticService.selectionClick();
                      historyNotifier.setFavoritesOnly(false);
                      historyNotifier.setCollectionFilter(null);
                    }
                  },
                  selectedColor: AppTheme.zapPrimary,
                  showCheckmark: false,
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                      SizedBox(width: 4),
                      Text('Favorites'),
                    ],
                  ),
                  selected: historyState.favoritesOnly,
                  onSelected: (val) {
                    HapticService.selectionClick();
                    historyNotifier.setFavoritesOnly(val);
                  },
                  selectedColor: AppTheme.zapPrimary,
                  showCheckmark: false,
                ),
                const SizedBox(width: 8),

                // Collection Filter Dropdown Chips
                ...collections.map((c) {
                  final isSelected = historyState.selectedCollectionId == c.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.folder_rounded, size: 16),
                          const SizedBox(width: 4),
                          Text(c.name),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (val) {
                        HapticService.selectionClick();
                        historyNotifier.setCollectionFilter(val ? c.id : null);
                      },
                      selectedColor: AppTheme.zapPrimary,
                      showCheckmark: false,
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // History Items List
          Expanded(
            child: historyState.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.zapPrimary))
                : historyState.items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'No QR codes found',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              'Generated and scanned QR codes will appear here',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        physics: const BouncingScrollPhysics(),
                        itemCount: historyState.items.length,
                        itemBuilder: (context, index) {
                          final item = historyState.items[index];
                          return Dismissible(
                            key: ValueKey(item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade400,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.delete_rounded, color: Colors.white),
                            ),
                            onDismissed: (dir) {
                              HapticService.heavyImpact();
                              historyNotifier.deleteQr(item.id!);
                            },
                            child: _buildHistoryCard(context, item, historyNotifier, isDark),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    QrCodeModel item,
    HistoryNotifier notifier,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.zapPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.type.icon, color: AppTheme.zapPrimary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(item.createdAt),
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    item.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: item.isFavorite ? Colors.amber : Colors.grey,
                  ),
                  onPressed: () {
                    HapticService.selectionClick();
                    notifier.toggleFavorite(item);
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                  onSelected: (action) {
                    if (action == 'preview') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QrPreviewScreen(initialModel: item),
                        ),
                      );
                    } else if (action == 'share') {
                      ExportService.shareQr(model: item, quality: QrExportQuality.high);
                    } else if (action == 'delete') {
                      notifier.deleteQr(item.id!);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'preview', child: Text('Preview & Customize')),
                    const PopupMenuItem(value: 'share', child: Text('Share QR')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
