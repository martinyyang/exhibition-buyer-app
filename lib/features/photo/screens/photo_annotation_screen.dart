import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../flag/models/flag.dart';
import '../../flag/providers/flag_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/photo_annotation_canvas.dart';
import '../providers/photo_provider.dart';
import '../../../shared/widgets/safe_back_button.dart';

class PhotoAnnotationScreen extends ConsumerStatefulWidget {
  final String photoId;

  const PhotoAnnotationScreen({
    super.key,
    required this.photoId,
  });

  @override
  ConsumerState<PhotoAnnotationScreen> createState() =>
      _PhotoAnnotationScreenState();
}

class _PhotoAnnotationScreenState extends ConsumerState<PhotoAnnotationScreen> {
  Flag? _selectedFlag;
  bool _isAddingFlag = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final photoAsync = ref.watch(photoProvider(widget.photoId));
    final flagsAsync = ref.watch(flagsProvider(widget.photoId));
    final currentUser = ref.watch(currentUserDataProvider);
    final userId = currentUser.value?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.annotateProducts),
        leading: const SafeBackButton(fallbackPath: '/events'),
        actions: [
          IconButton(
            icon: Icon(_isAddingFlag ? Icons.check : Icons.add_location),
            onPressed: () {
              setState(() {
                _isAddingFlag = !_isAddingFlag;
                if (!_isAddingFlag) {
                  _selectedFlag = null;
                }
              });
            },
            tooltip: _isAddingFlag ? l10n.ok : l10n.annotateProducts,
          ),
          if (_selectedFlag != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteFlag(_selectedFlag!),
              tooltip: l10n.deleteFlag,
            ),
        ],
      ),
      body: photoAsync.when(
        data: (photo) {
          if (photo == null) {
            return Center(child: Text(l10n.noPhotos));
          }

          return flagsAsync.when(
            data: (flags) => Column(
              children: [
                // 提示信息
                if (_isAddingFlag)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.blue.withOpacity(0.1),
                    child: Text(
                      l10n.tapToMarkProduct,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // 照片标注区域
                Expanded(
                  child: PhotoAnnotationCanvas(
                    imageUrl: photo.url,
                    flags: flags,
                    onTap: _isAddingFlag && userId != null
                        ? (offset) => _addFlag(offset, flags.length + 1, userId)
                        : null,
                    onFlagLongPress: (flag) {
                      setState(() {
                        _selectedFlag = flag;
                      });
                      _showFlagDetails(flag);
                    },
                    enableZoom: true,
                  ),
                ),

                // 底部标记列表
                if (flags.isNotEmpty)
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(8),
                      itemCount: flags.length,
                      itemBuilder: (context, index) {
                        final flag = flags[index];
                        return _buildFlagCard(flag);
                      },
                    ),
                  ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) =>
                Center(child: Text(l10n.loadFailed(err.toString()))),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text(l10n.loadFailed(err.toString()))),
      ),
    );
  }

  Widget _buildFlagCard(Flag flag) {
    final isSelected = _selectedFlag?.id == flag.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFlag = isSelected ? null : flag;
        });
      },
      onLongPress: () => _showFlagDetails(flag),
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.white,
          border: Border.all(
            color: flag.needsAttention
                ? Colors.red
                : (isSelected ? Colors.blue : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: flag.needsAttention ? Colors.red : Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${flag.number}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            if (flag.priceRmb != null)
              Text(
                '¥${flag.priceRmb!.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addFlag(Offset position, int number, String userId) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final flagService = ref.read(flagServiceProvider);
      await flagService.createFlag(
        photoId: widget.photoId,
        positionX: position.dx,
        positionY: position.dy,
        createdBy: userId,
      );

      // 刷新标记列表
      ref.invalidate(flagsProvider(widget.photoId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.flagAdded)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.addFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _deleteFlag(Flag flag) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteFlag),
        content: Text(l10n.confirmDeleteFlagMessage(flag.number)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final flagService = ref.read(flagServiceProvider);
      await flagService.deleteFlag(flag.id);

      // 刷新标记列表
      ref.invalidate(flagsProvider(widget.photoId));

      setState(() {
        _selectedFlag = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.flagDeletedSuccess(flag.number))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.deleteFailed(e.toString()))),
        );
      }
    }
  }

  void _showFlagDetails(Flag flag) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FlagDetailsSheet(
        flag: flag,
        photoId: widget.photoId,
      ),
    );
  }
}

class _FlagDetailsSheet extends ConsumerStatefulWidget {
  final Flag flag;
  final String photoId;

  const _FlagDetailsSheet({
    required this.flag,
    required this.photoId,
  });

  @override
  ConsumerState<_FlagDetailsSheet> createState() => _FlagDetailsSheetState();
}

class _FlagDetailsSheetState extends ConsumerState<_FlagDetailsSheet> {
  late TextEditingController _priceRmbController;
  late TextEditingController _targetPriceController;
  bool _needsAttention = false;

  @override
  void initState() {
    super.initState();
    _priceRmbController = TextEditingController(
      text: widget.flag.priceRmb?.toStringAsFixed(0) ?? '',
    );
    _targetPriceController = TextEditingController(
      text: widget.flag.targetPrice?.toStringAsFixed(2) ?? '',
    );
    _needsAttention = widget.flag.needsAttention;
  }

  @override
  void dispose() {
    _priceRmbController.dispose();
    _targetPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _needsAttention ? Colors.red : Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${widget.flag.number}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.annotationDetails,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _priceRmbController,
            decoration: InputDecoration(
              labelText: l10n.priceRmb,
              prefixText: '¥',
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _targetPriceController,
            decoration: InputDecoration(
              labelText: l10n.targetPrice,
              prefixText: '\$',
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(l10n.status),
            subtitle: Text(l10n.status),
            value: _needsAttention,
            onChanged: (value) {
              setState(() {
                _needsAttention = value;
              });
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveChanges,
              child: Text(l10n.save),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final flagService = ref.read(flagServiceProvider);

      double? priceRmb;
      if (_priceRmbController.text.isNotEmpty) {
        priceRmb = double.tryParse(_priceRmbController.text);
      }

      double? targetPrice;
      if (_targetPriceController.text.isNotEmpty) {
        targetPrice = double.tryParse(_targetPriceController.text);
      }

      await flagService.updateFlag(
        flagId: widget.flag.id,
        priceRmb: priceRmb,
        targetPrice: targetPrice,
        needsAttention: _needsAttention,
      );

      // 刷新标记列表
      ref.invalidate(flagsProvider(widget.photoId));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.save)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.saveFailed(e.toString()))),
        );
      }
    }
  }
}
