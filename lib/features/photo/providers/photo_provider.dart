import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/realtime_service.dart';
import '../services/photo_service.dart';
import '../models/photo.dart';
import '../../auth/providers/auth_provider.dart';

// PhotoService Provider
final photoServiceProvider = Provider((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return PhotoService(supabase.client);
});

// 照片列表状态管理（支持实时同步）
class PhotosNotifier extends StateNotifier<AsyncValue<List<Photo>>> {
  final PhotoService _photoService;
  final RealtimeService _realtimeService;
  final String _boothId;
  RealtimeChannel? _channel;

  PhotosNotifier(
    this._photoService,
    this._realtimeService,
    this._boothId,
  ) : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    // 初始加载
    await refresh();

    // 订阅实时更新
    _channel = _realtimeService.subscribeToPhotos(_boothId, (payload) {
      // 数据变化时重新加载
      refresh();
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final photos = await _photoService.getPhotos(_boothId);
      state = AsyncValue.data(photos);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  @override
  void dispose() {
    if (_channel != null) {
      _realtimeService.unsubscribe(_channel!);
    }
    super.dispose();
  }
}

// 照片列表Provider（按摊位过滤，支持实时同步）
final photosProvider = StateNotifierProvider.family<PhotosNotifier, AsyncValue<List<Photo>>, String>(
  (ref, boothId) {
    final photoService = ref.watch(photoServiceProvider);
    final realtimeService = ref.watch(realtimeServiceProvider);
    return PhotosNotifier(photoService, realtimeService, boothId);
  },
);

// 单个照片Provider
final photoProvider = FutureProvider.family<Photo?, String>((ref, photoId) async {
  final photoService = ref.watch(photoServiceProvider);
  return await photoService.getPhoto(photoId);
});
