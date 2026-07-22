import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../flag/models/flag.dart';
import '../../../shared/widgets/loading_indicator.dart';

class PhotoAnnotationCanvas extends StatelessWidget {
  final String imageUrl;
  final List<Flag> flags;
  final Function(Offset)? onTap;
  final Function(Flag)? onFlagLongPress;
  final bool enableZoom;

  const PhotoAnnotationCanvas({
    super.key,
    required this.imageUrl,
    required this.flags,
    this.onTap,
    this.onFlagLongPress,
    this.enableZoom = true,
  });

  Widget _buildFlagMarker(Flag flag, Size imageSize) {
    return Positioned(
      left: flag.positionX * imageSize.width - 20,
      top: flag.positionY * imageSize.height - 40,
      child: GestureDetector(
        onLongPress: onFlagLongPress != null
            ? () => onFlagLongPress!(flag)
            : null,
        child: Column(
          children: [
            // 旗子圆圈
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: flag.needsAttention ? Colors.red : Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${flag.number}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            // 旗杆
            Container(
              width: 2,
              height: 20,
              color: flag.needsAttention ? Colors.red : Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageSize = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );

        return GestureDetector(
          onTapDown: onTap != null
              ? (details) {
                  final localPosition = details.localPosition;
                  final relativeOffset = Offset(
                    localPosition.dx / imageSize.width,
                    localPosition.dy / imageSize.height,
                  );
                  onTap!(relativeOffset);
                }
              : null,
          child: Stack(
            children: [
              // 照片
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) =>
                      const Center(child: LoadingIndicator()),
                  errorWidget: (context, url, error) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '照片加载失败',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 旗子标记
              ...flags.map((flag) => _buildFlagMarker(flag, imageSize)),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (enableZoom) {
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: _buildContent(context),
      );
    } else {
      return _buildContent(context);
    }
  }
}
