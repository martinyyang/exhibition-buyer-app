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
              });
            },
            tooltip: _isAddingFlag ? l10n.ok : l10n.annotateProducts,
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
    return Container(
      width: 80,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: flag.needsAttention ? Colors.red : Colors.grey.shade300,
          width: 1,
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
}
