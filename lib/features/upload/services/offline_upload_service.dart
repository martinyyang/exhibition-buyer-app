import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:indexed_db' as idb;
import 'dart:typed_data';

/// 待补传的照片条目
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

/// 断网续传补传服务（Web 端）
///
/// 上传失败或断网时，将照片字节（base64）暂存到浏览器 IndexedDB；
/// 网络恢复后自动从队列依次补传，补传成功即从队列移除。
/// 关闭页面也不丢失（IndexedDB 持久化）。
class OfflineUploadService {
  static const String _dbName = 'offline_uploads';
  static const String _storeName = 'pending';

  idb.Database? _db;
  bool _listening = false;
  final List<void Function(int count)> _countListeners = [];
  final List<void Function()> _offlineListeners = [];

  /// 打开 IndexedDB（dart:indexed_db async API）
  Future<idb.Database> _getDb() async {
    if (_db != null) return _db!;
    final factory = html.window.indexedDB;
    if (factory == null) {
      throw StateError('IndexedDB is not supported in this browser');
    }
    _db = await factory.open(
      _dbName,
      version: 1,
      onUpgradeNeeded: (idb.VersionChangeEvent e) {
        final db = (e.target as idb.OpenDBRequest).result;
        if (!db.objectStoreNames.contains(_storeName)) {
          db.createObjectStore(_storeName, keyPath: 'id');
        }
      },
    );
    return _db!;
  }

  /// 启动网络监听：断网记录状态、恢复时自动补传
  void startListening({required Future<void> Function() onFlush}) {
    if (_listening) return;
    _listening = true;

    html.window.onOnline.listen((_) {
      // 网络恢复，触发补传
      onFlush();
    });
    html.window.onOffline.listen((_) {
      for (final cb in _offlineListeners) {
        cb();
      }
    });
    // 首次启动时若在线且有遗留队列，也尝试补传
    onFlush();
  }

  /// 监听断网事件
  void onOffline(void Function() callback) {
    _offlineListeners.add(callback);
  }

  /// 加入待补传队列
  Future<void> addPending({
    required String boothId,
    required String teamId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final db = await _getDb();
    final item = PendingUpload(
      id: '${DateTime.now().millisecondsSinceEpoch}_${bytes.length}',
      boothId: boothId,
      teamId: teamId,
      fileName: fileName,
      dataBase64: base64Encode(bytes),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    final tx = db.transaction(_storeName, 'readwrite');
    tx.objectStore(_storeName).put(item.toJson());
    await tx.completed;
    _notifyCountChange();
  }

  /// 获取待补传数量
  Future<int> getPendingCount() async {
    try {
      final items = await getAllPending();
      return items.length;
    } catch (_) {
      return 0;
    }
  }

  /// 读取所有待补传条目
  Future<List<PendingUpload>> getAllPending() async {
    final db = await _getDb();
    final tx = db.transaction(_storeName, 'readonly');
    final store = tx.objectStore(_storeName);
    final req = store.getAll(null);
    final completer = Completer<List>();
    req.onSuccess.listen((_) => completer.complete(req.result as List));
    req.onError.listen((_) => completer.completeError('read queue failed'));
    final items = await completer.future;
    return items
        .map((e) => PendingUpload.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// 补传成功，从队列移除
  Future<void> removePending(String id) async {
    final db = await _getDb();
    final tx = db.transaction(_storeName, 'readwrite');
    tx.objectStore(_storeName).delete(id);
    await tx.completed;
    _notifyCountChange();
  }

  /// 订阅队列数量变化
  void onCountChanged(void Function(int count) callback) {
    _countListeners.add(callback);
  }

  void _notifyCountChange() {
    getPendingCount().then((count) {
      for (final cb in _countListeners) {
        cb(count);
      }
    });
  }

  /// 释放资源
  void dispose() {
    _countListeners.clear();
    _offlineListeners.clear();
    _db?.close();
    _db = null;
  }
}
