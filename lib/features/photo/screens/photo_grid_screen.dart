import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/error_handler.dart';
import '../models/photo.dart';
import '../services/image_helper_service.dart';
import '../providers/photo_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/safe_back_button.dart';
import '../../flag/providers/flag_provider.dart';
import '../../booth/providers/booth_provider.dart';
import '../providers/photo_update_provider.dart';
import '../../../core/providers/onboarding_provider.dart';
import '../../../shared/widgets/onboarding_dialog.dart';

class PhotoGridScreen extends ConsumerStatefulWidget {
  final String boothId;

  const PhotoGridScreen({
    super.key,
    required this.boothId,
  });

  @override
  ConsumerState<PhotoGridScreen> createState() => _PhotoGridScreenState();
}

class _PhotoGridScreenState extends ConsumerState<PhotoGridScreen> {
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showOnboardingIfNeeded();
    });
  }

  Future<void> _showOnboardingIfNeeded() async {
    final onboardingService = ref.read(onboardingServiceProvider);
    final hasSeenOnboarding =
        await onboardingService.hasSeenOnboarding('photo_grid');

    if (!hasSeenOnboarding && mounted) {
      await _showOnboarding(markAsSeen: true);
    }
  }

  Future<void> _showOnboarding({bool markAsSeen = false}) async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog(
      context: context,
      builder: (context) => OnboardingDialog(
        title: l10n.onboardingTitlePhotoGrid,
        tips: [
          OnboardingTip(
            icon: Icons.add_a_photo,
            title: l10n.onboardingPhotoGridTip1Title,
            description: l10n.onboardingPhotoGridTip1Desc,
          ),
          OnboardingTip(
            icon: Icons.photo_library,
            title: l10n.onboardingPhotoGridTip2Title,
            description: l10n.onboardingPhotoGridTip2Desc,
          ),
          OnboardingTip(
            icon: Icons.more_vert,
            title: l10n.onboardingPhotoGridTip3Title,
            description: l10n.onboardingPhotoGridTip3Desc,
          ),
        ],
        onDismiss: () {
          if (markAsSeen) {
            ref
                .read(onboardingServiceProvider)
                .markOnboardingSeen('photo_grid');
          }
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _takePhoto() async {
    // 检测是否是移动设备（包括移动浏览器）
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      // 移动端（原生应用或移动浏览器）：显示相机/相册选择对话框
      await _showImageSourceDialog();
    } else {
      // 桌面端 Web：直接打开文件选择器
      await _pickImageFromGallery();
    }
  }

  /// Web 端和移动端相册选择
  Future<void> _pickImageFromGallery() async {
    final l10n = AppLocalizations.of(context)!;

    // 显示选择对话框：单张还是多张
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectPhotos),
        content: Text(l10n.selectPhotoMode),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'single'),
            child: Text(l10n.singlePhoto),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'multiple'),
            child: Text(l10n.multiplePhotos),
          ),
        ],
      ),
    );

    if (choice == null) return;

    if (choice == 'single') {
      await _uploadSinglePhoto();
    } else {
      await _uploadMultiplePhotos();
    }
  }

  /// 单张照片上传
  Future<void> _uploadSinglePhoto() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isUploading = true;
    });

    try {
      final pickedFile = await imageHelper.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        final photoService = ref.read(photoServiceProvider);
        final userData = await ref.read(currentUserDataProvider.future);
        final authState = ref.read(currentUserProvider);
        final user = authState.asData?.value.session?.user;
        final teamId = userData?.teamId;

        if (user == null || teamId == null) {
          throw Exception(l10n.userNotInTeam);
        }

        await photoService.uploadPhoto(
          photoFile: pickedFile,
          boothId: widget.boothId,
          teamId: teamId,
          uploadedBy: user.id,
          onProgress: (progress) {
            setState(() {
              _uploadProgress = progress;
            });
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.photoUploadSuccess)),
          );

          // 手动刷新照片列表（Realtime 未启用时的临时方案）
          ref.read(photosProvider(widget.boothId).notifier).refresh();
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.show(context, e, onRetry: _uploadSinglePhoto);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  /// 批量照片上传
  Future<void> _uploadMultiplePhotos() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isUploading = true;
    });

    try {
      final pickedFiles = await imageHelper.pickMultipleImages();

      if (pickedFiles.isNotEmpty) {
        final photoService = ref.read(photoServiceProvider);
        final userData = await ref.read(currentUserDataProvider.future);
        final authState = ref.read(currentUserProvider);
        final user = authState.asData?.value.session?.user;
        final teamId = userData?.teamId;

        if (user == null || teamId == null) {
          throw Exception(l10n.userNotInTeam);
        }

        int uploadedCount = 0;
        await photoService.uploadPhotos(
          photoFiles: pickedFiles,
          boothId: widget.boothId,
          teamId: teamId,
          uploadedBy: user.id,
          onProgress: (progress) {
            setState(() {
              _uploadProgress = progress;
            });
          },
          onSingleComplete: (current, total, photo) {
            uploadedCount = current;
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  l10n.photosUploadSuccess(uploadedCount, pickedFiles.length)),
              duration: const Duration(seconds: 3),
            ),
          );

          // 手动刷新照片列表
          ref.read(photosProvider(widget.boothId).notifier).refresh();
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.show(context, e, onRetry: _uploadMultiplePhotos);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  /// 移动端：相机拍照
  Future<void> _pickImageFromCamera() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isUploading = true;
    });

    try {
      final pickedFile = await imageHelper.pickImage(
        source: ImageSource.camera,
      );

      if (pickedFile != null) {
        final photoService = ref.read(photoServiceProvider);
        final userData = await ref.read(currentUserDataProvider.future);
        final authState = ref.read(currentUserProvider);
        final user = authState.asData?.value.session?.user;
        final teamId = userData?.teamId;

        if (user == null || teamId == null) {
          throw Exception(l10n.userNotInTeam);
        }

        await photoService.uploadPhoto(
          photoFile: pickedFile,
          boothId: widget.boothId,
          teamId: teamId,
          uploadedBy: user.id,
          onProgress: (progress) {
            setState(() {
              _uploadProgress = progress;
            });
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.photoUploadSuccess)),
          );

          // 手动刷新照片列表（Realtime 未启用时的临时方案）
          ref.read(photosProvider(widget.boothId).notifier).refresh();
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.show(context, e, onRetry: _pickImageFromCamera);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  /// 移动端：显示图片来源选择对话框
  Future<void> _showImageSourceDialog() async {
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: Text(l10n.takePhotoAction),
            onTap: () {
              Navigator.pop(context);
              _pickImageFromCamera();
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: Text(l10n.chooseFromGallery),
            onTap: () {
              Navigator.pop(context);
              _pickImageFromGallery();
            },
          ),
        ],
      ),
    );
  }

  void _onPhotoTap(Photo photo) {
    context.push('/photos/${photo.id}');
  }

  void _onPhotoLongPress(Photo photo) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _confirmDeletePhoto(photo);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeletePhoto(Photo photo) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.confirmDeletePhotoMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePhoto(photo);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePhoto(Photo photo) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final photoService = ref.read(photoServiceProvider);
      await photoService.deletePhoto(photo.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.photoDeleted)),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.show(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final photosAsync = ref.watch(photosProvider(widget.boothId));
    final boothAsync = ref.watch(boothProvider(widget.boothId));

    return Scaffold(
      appBar: AppBar(
        title: boothAsync.when(
          data: (booth) => booth != null
              ? Text(l10n.boothLabel(booth.boothNumber))
              : Text(l10n.photos),
          loading: () => Text(l10n.photos),
          error: (_, __) => Text(l10n.photos),
        ),
        leading: boothAsync.when(
          data: (booth) => SafeBackButton(
            fallbackPath:
                booth != null ? '/events/${booth.eventId}/booths' : '/events',
          ),
          loading: () => const SafeBackButton(fallbackPath: '/events'),
          error: (_, __) => const SafeBackButton(fallbackPath: '/events'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showOnboarding(markAsSeen: false),
            tooltip: '查看操作指南',
          ),
        ],
      ),
      body: photosAsync.when(
        data: (photos) => photos.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_camera,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noPhotos,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.takePhotoHint,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: Responsive.getGridColumns(context),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  final photo = photos[index];
                  return _PhotoCard(
                    photo: photo,
                    onTap: () => _onPhotoTap(photo),
                    onLongPress: () => _onPhotoLongPress(photo),
                  );
                },
              ),
        loading: () => const Center(child: LoadingIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(l10n.loadFailed(err.toString())),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(photosProvider(widget.boothId)),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _isUploading
          ? FloatingActionButton(
              onPressed: null,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      value: _uploadProgress,
                      strokeWidth: 3,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  Text(
                    '${(_uploadProgress * 100).toInt()}%',
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          : Builder(
              builder: (context) {
                final isMobile = MediaQuery.of(context).size.width < 600;
                return FloatingActionButton(
                  onPressed: _takePhoto,
                  tooltip:
                      isMobile ? l10n.cameraButton : l10n.uploadPhotoButton,
                  child: Icon(isMobile ? Icons.camera_alt : Icons.upload_file),
                );
              },
            ),
    );
  }
}

class _PhotoCard extends ConsumerWidget {
  final Photo photo;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _PhotoCard({
    required this.photo,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final flagCount = ref.watch(photoFlagCountProvider(photo.id));
    final hasUpdatesAsync = ref.watch(photoHasUpdatesProvider(photo.id));

    return Badge(
      isLabelVisible: hasUpdatesAsync.valueOrNull == true,
      offset: const Offset(-8, 8),
      backgroundColor: Colors.red,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: CachedNetworkImage(
                      imageUrl: photo.url,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const Center(child: LoadingIndicator()),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (photo.supplierName != null)
                          Text(
                            photo.supplierName!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.flag, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              l10n.flagCount(flagCount),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // 菜单按钮（右上角）
              Positioned(
                top: 4,
                right: 4,
                child: Tooltip(
                  message: l10n.delete,
                  child: Material(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: onLongPress,
                      borderRadius: BorderRadius.circular(16),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.more_vert,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
