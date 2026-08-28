import 'dart:convert';
import 'dart:typed_data';
import 'offline_upload_service_stub.dart'
    if (dart.library.html) 'offline_upload_service_web.dart' as impl;

/// 待补传的照片条目（纯 Dart 模型，各平台共用）
class PendingUpload {
  final String id;
  final String boothId;
  final String teamId;
  final String fileName;
  final String dataBase64;
  final int createdAt;

  PendingUpload({
    required this.id,
    required this.boothId,
    required this.teamId,
    required this.fileName,
    required this.dataBase64,
    required this.createdAt,
  });

  factory PendingUpload.fromJson(Map<String, dynamic> json) {
    return PendingUpload(
      id: json['id'] as String,
      boothId: json['boothId'] as String,
      teamId: json['teamId'] as String,
      fileName: json['fileName'] as String,
      dataBase64: json['dataBase64'] as String,
      createdAt: json['createdAt'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'boothId': boothId,
      'teamId': teamId,
      'fileName': fileName,
      'dataBase64': dataBase64,
      'createdAt': createdAt,
    };
  }

  Uint8List get bytes => base64Decode(dataBase64);
}

/// 断网续传补传服务接口
///
/// Web 端用 IndexedDB 暂存待补传照片，断网时入队、联网后自动补传；
/// 其他平台（VM 测试）使用空实现，不产生副作用。
abstract class OfflineUploadService {
  factory OfflineUploadService() => impl.OfflineUploadServiceImpl();

  /// 启动网络监听：断网记录状态、恢复时自动补传
  void startListening({required Future<void> Function() onFlush});

  /// 监听断网事件
  void onOffline(void Function() callback);

  /// 加入待补传队列
  Future<void> addPending({
    required String boothId,
    required String teamId,
    required String fileName,
    required Uint8List bytes,
  });

  /// 获取待补传数量
  Future<int> getPendingCount();

  /// 读取所有待补传条目
  Future<List<PendingUpload>> getAllPending();

  /// 补传成功，从队列移除
  Future<void> removePending(String id);

  /// 订阅队列数量变化
  void onCountChanged(void Function(int count) callback);

  /// 释放资源
  void dispose();
}
