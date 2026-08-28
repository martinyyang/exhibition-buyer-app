import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/providers/auth_provider.dart';
import '../../photo/providers/photo_provider.dart';
import '../services/offline_upload_service.dart';

/// 离线上传队列状态
class OfflineUploadState {
  final int pendingCount;
  final bool isOnline;
  final bool isFlushing;
  final String? lastError;

  const OfflineUploadState({
    this.pendingCount = 0,
    this.isOnline = true,
    this.isFlushing = false,
    this.lastError,
  });

  OfflineUploadState copyWith({
    int? pendingCount,
    bool? isOnline,
    bool? isFlushing,
    String? lastError,
  }) {
    return OfflineUploadState(
      pendingCount: pendingCount ?? this.pendingCount,
      isOnline: isOnline ?? this.isOnline,
      isFlushing: isFlushing ?? this.isFlushing,
      lastError: lastError ?? this.lastError,
    );
  }
}

/// 离线上传控制器：管理待补传队列、网络状态与自动补传
class OfflineUploadController extends StateNotifier<OfflineUploadState> {
  final OfflineUploadService _service;
  final Ref _ref;
  bool _initialized = false;

  OfflineUploadController(this._service, this._ref)
      : super(const OfflineUploadState());

  /// 初始化：启动网络监听、加载队列数量、订阅变化
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final count = await _service.getPendingCount();
    state = state.copyWith(pendingCount: count);

    _service.onCountChanged((count) {
      if (mounted) {
        state = state.copyWith(pendingCount: count);
      }
    });

    // 网络恢复时自动补传
    _service.startListening(onFlush: () async {
      if (mounted) {
        state = state.copyWith(isOnline: true);
        await flush();
      }
    });

    // 监听断网
    _service.onOffline(() {
      if (mounted) {
        state = state.copyWith(isOnline: false);
      }
    });
  }

  /// 把一张失败/断网的照片加入待补传队列
  Future<void> addPending({
    required String boothId,
    required String teamId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    await _service.addPending(
      boothId: boothId,
      teamId: teamId,
      fileName: fileName,
      bytes: bytes,
    );
  }

  /// 立即尝试补传队列中的所有照片
  Future<void> flush() async {
    if (state.isFlushing) return;
    final pending = await _service.getAllPending();
    if (pending.isEmpty) return;

    state = state.copyWith(isFlushing: true, lastError: null);
    try {
      final userData = await _ref.read(currentUserDataProvider.future);
      final authState = _ref.read(currentUserProvider);
      final user = authState.asData?.value.session?.user;
      final teamId = userData?.teamId;
      if (user == null || teamId == null) return;

      final photoService = _ref.read(photoServiceProvider);

      for (final item in pending) {
        if (item.teamId != teamId) continue; // 只补传当前团队的照片
        try {
          final xfile = XFile.fromData(
            item.bytes,
            name: item.fileName,
            mimeType: 'image/webp',
          );
          await photoService.uploadPhoto(
            photoFile: xfile,
            boothId: item.boothId,
            teamId: teamId,
            uploadedBy: user.id,
          );
          await _service.removePending(item.id);
          // 刷新对应摊位的照片列表
          _ref.read(photosProvider(item.boothId).notifier).refresh();
        } catch (_) {
          // 单张补传失败不阻塞队列，留给下次重试
        }
      }
    } catch (e) {
      state = state.copyWith(lastError: e.toString());
    } finally {
      if (mounted) {
        state = state.copyWith(isFlushing: false);
      }
    }
  }

  void setOffline() {
    if (mounted) {
      state = state.copyWith(isOnline: false);
    }
  }
}

final offlineUploadServiceProvider = Provider<OfflineUploadService>((ref) {
  final service = OfflineUploadService();
  ref.onDispose(service.dispose);
  return service;
});

final offlineUploadProvider =
    StateNotifierProvider<OfflineUploadController, OfflineUploadState>((ref) {
  final service = ref.watch(offlineUploadServiceProvider);
  final controller = OfflineUploadController(service, ref);
  // 延迟到下一帧初始化，避免在构建期间触发异步
  Future.microtask(controller.initialize);
  return controller;
});
