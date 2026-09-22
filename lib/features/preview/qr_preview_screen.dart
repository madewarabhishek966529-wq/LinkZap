import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../app/theme/app_theme.dart';
import '../../core/services/export_service.dart';
import '../../core/services/haptic_service.dart';
import '../../data/models/qr_code_model.dart';
import '../../shared/animations/success_toast.dart';
import '../../shared/widgets/custom_qr_widget.dart';
import '../collections/collections_provider.dart';
import '../history/history_provider.dart';

class QrPreviewScreen extends ConsumerStatefulWidget {
  final QrCodeModel initialModel;

  const QrPreviewScreen({super.key, required this.initialModel});

  @override
  ConsumerState<QrPreviewScreen> createState() => _QrPreviewScreenState();
}

class _QrPreviewScreenState extends ConsumerState<QrPreviewScreen> {
  late QrCodeModel _currentModel;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentModel = widget.initialModel;
  }

  void _updateModel(QrCodeModel updated) {
    setState(() {
      _currentModel = updated;
    });
    // Update in database if already persisted
    if (_currentModel.id != null) {
      ref.read(historyProvider.notifier).addQrCode(_currentModel);
    }
  }

  Future<void> _pickLogo() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        HapticService.selectionClick();
        _updateModel(_currentModel.copyWith(
          logoPath: image.path,
          errorCorrection: QrErrorCorrection.high, // Elevate EC when logo attached
        ));
      }
    } catch (_) {}
  }

  void _showDownloadDialog() {
    QrExportQuality selectedQuality = QrExportQuality.high;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Download PNG',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Resolution Quality:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  ...QrExportQuality.values.map((q) {
                    return RadioListTile<QrExportQuality>(
                      value: q,
                      groupValue: selectedQuality,
                      title: Text(q.label, style: const TextStyle(fontWeight: FontWeight.w500)),
                      activeColor: AppTheme.zapPrimary,
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedQuality = val;
                          });
                        }
                      },
                    );
                  }).toList(),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.zapPrimary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.download_rounded, color: Colors.black),
                      label: const Text('Save to Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      onPressed: () async {
                        Navigator.pop(context);
                        try {
                          await ExportService.downloadToGallery(
                            model: _currentModel,
                            quality: selectedQuality,
                          );
                          if (mounted) {
                            SuccessToast.show(context, '✓ Saved to Gallery');
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to save image to gallery.')),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _shareQr() async {
    HapticService.selectionClick();
    await ExportService.shareQr(
      model: _currentModel,
      quality: QrExportQuality.high,
      includeText: true,
    );
    if (mounted) {
      SuccessToast.show(context, '✓ Shared');
    }
  }

  void _showCollectionPicker() {
    final collections = ref.read(collectionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Move to Collection',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.folder_off_outlined),
                title: const Text('None (Default History)'),
                trailing: _currentModel.collectionId == null ? const Icon(Icons.check, color: AppTheme.zapPrimary) : null,
                onTap: () {
                  _updateModel(_currentModel.copyWith(collectionId: null));
                  ref.read(historyProvider.notifier).moveCollection(_currentModel, null);
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ...collections.map((c) {
                final isSelected = _currentModel.collectionId == c.id;
                return ListTile(
                  leading: const Icon(Icons.folder_rounded, color: AppTheme.zapPrimary),
                  title: Text(c.name),
                  trailing: isSelected ? const Icon(Icons.check, color: AppTheme.zapPrimary) : null,
                  onTap: () {
                    _updateModel(_currentModel.copyWith(collectionId: c.id));
                    ref.read(historyProvider.notifier).moveCollection(_currentModel, c.id);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Preview', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(
              _currentModel.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: _currentModel.isFavorite ? Colors.amber : null,
            ),
            onPressed: () {
              HapticService.selectionClick();
              final updated = _currentModel.copyWith(isFavorite: !_currentModel.isFavorite);
              _updateModel(updated);
              ref.read(historyProvider.notifier).toggleFavorite(updated);
            },
          ),
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: _showCollectionPicker,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Live Animated QR Display
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: CustomQrWidget(
                  key: ValueKey('${_currentModel.foregroundColor.value}_${_currentModel.backgroundColor.value}_${_currentModel.dotStyle.name}_${_currentModel.eyeStyle.name}_${_currentModel.logoPath}'),
                  model: _currentModel,
                  size: 270,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Content summary pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_currentModel.type.icon, size: 16, color: AppTheme.zapPrimary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _currentModel.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // CUSTOMIZATION PANELS
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Customize',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),

            // Presets / Templates Carousel
            _buildSectionCard(
              context,
              title: 'Templates',
              icon: Icons.auto_awesome_rounded,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    'Minimal',
                    'Business',
                    'Portfolio',
                    'Social',
                    'Event',
                    'Restaurant',
                    'Wi-Fi',
                    'Payment',
                  ].map((tpl) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(tpl),
                        backgroundColor: isDark ? AppTheme.darkSurfaceVariant : Colors.grey.shade200,
                        onPressed: () {
                          HapticService.selectionClick();
                          ref.read(generatorProvider.notifier).applyTemplate(tpl);
                          final updatedFromGen = ref.read(generatorProvider).toQrModel();
                          _updateModel(_currentModel.copyWith(
                            foregroundColor: updatedFromGen.foregroundColor,
                            backgroundColor: updatedFromGen.backgroundColor,
                            dotStyle: updatedFromGen.dotStyle,
                            eyeStyle: updatedFromGen.eyeStyle,
                            errorCorrection: updatedFromGen.errorCorrection,
                          ));
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Color Selection
            _buildSectionCard(
              context,
              title: 'Colors',
              icon: Icons.palette_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Foreground Color', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Colors.black,
                      Colors.white,
                      const Color(0xFF2563EB),
                      const Color(0xFF9333EA),
                      const Color(0xFF059669),
                      const Color(0xFFDC2626),
                      const Color(0xFFD97706),
                    ].map((color) {
                      final isSelected = _currentModel.foregroundColor.value == color.value;
                      return GestureDetector(
                        onTap: () {
                          HapticService.selectionClick();
                          _updateModel(_currentModel.copyWith(foregroundColor: color));
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppTheme.zapPrimary : Colors.grey,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  size: 16,
                                  color: color == Colors.white ? Colors.black : Colors.white,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Background Color', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Colors.white,
                      const Color(0xFF0F172A),
                      const Color(0xFFFDF2F8),
                      const Color(0xFFECFDF5),
                      const Color(0xFFFFFBEB),
                    ].map((color) {
                      final isSelected = _currentModel.backgroundColor.value == color.value;
                      return GestureDetector(
                        onTap: () {
                          HapticService.selectionClick();
                          _updateModel(_currentModel.copyWith(backgroundColor: color));
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppTheme.zapPrimary : Colors.grey,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  size: 16,
                                  color: color == Colors.white ? Colors.black : Colors.white,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Style & Shape Selection
            _buildSectionCard(
              context,
              title: 'Styles & Shapes',
              icon: Icons.interests_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dot Style', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: DotStyle.values.map((ds) {
                      final isSelected = _currentModel.dotStyle == ds;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          selected: isSelected,
                          label: Text(ds.displayName),
                          selectedColor: AppTheme.zapPrimary,
                          labelStyle: TextStyle(color: isSelected ? Colors.black : null),
                          onSelected: (val) {
                            if (val) {
                              HapticService.selectionClick();
                              _updateModel(_currentModel.copyWith(dotStyle: ds));
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Eye Style', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: EyeStyle.values.map((es) {
                      final isSelected = _currentModel.eyeStyle == es;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          selected: isSelected,
                          label: Text(es.displayName),
                          selectedColor: AppTheme.zapPrimary,
                          labelStyle: TextStyle(color: isSelected ? Colors.black : null),
                          onSelected: (val) {
                            if (val) {
                              HapticService.selectionClick();
                              _updateModel(_currentModel.copyWith(eyeStyle: es));
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Logo Support
            _buildSectionCard(
              context,
              title: 'Logo',
              icon: Icons.image_rounded,
              child: Row(
                children: [
                  if (_currentModel.logoPath != null) ...[
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage(_currentModel.logoPath!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                      label: const Text('Remove', style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        HapticService.selectionClick();
                        _updateModel(_currentModel.copyWith(logoPath: null));
                      },
                    ),
                  ] else ...[
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add_photo_alternate_rounded),
                      label: const Text('+ Add Logo from Gallery'),
                      onPressed: _pickLogo,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 100), // Bottom padding for action bar
          ],
        ),
      ),

      // Bottom Action Bar
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Share', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _shareQr,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.zapPrimary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Download', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _showDownloadDialog,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.zapPrimary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
