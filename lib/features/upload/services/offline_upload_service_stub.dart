import 'dart:typed_data';
import 'offline_upload_service.dart';

/// 非 Web 平台（VM 测试）空实现：不产生任何副作用
class OfflineUploadServiceImpl implements OfflineUploadService {
  @override
  void startListening({required Future<void> Function() onFlush}) {}

  @override
  void onOffline(void Function() callback) {}

  @override
  Future<void> addPending({
    required String boothId,
    required String teamId,
    required String fileName,
    required Uint8List bytes,
  }) async {}

  @override
  Future<int> getPendingCount() async => 0;

  @override
  Future<List<PendingUpload>> getAllPending() async => [];

  @override
  Future<void> removePending(String id) async {}

  @override
  void onCountChanged(void Function(int count) callback) {}

  @override
  void dispose() {}
}
