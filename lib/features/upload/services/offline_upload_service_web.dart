import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:indexed_db' as idb;
import 'dart:typed_data';
import 'offline_upload_service.dart';

/// Web 平台实现：断网续传补传（IndexedDB 暂存）
///
/// 上传失败或断网时，将照片字节（base64）暂存到浏览器 IndexedDB；
/// 网络恢复后自动从队列依次补传，补传成功即从队列移除。
/// 关闭页面也不丢失（IndexedDB 持久化）。
class OfflineUploadServiceImpl implements OfflineUploadService {
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

  @override
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

  @override
  void onOffline(void Function() callback) {
    _offlineListeners.add(callback);
  }

  @override
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

  @override
  Future<int> getPendingCount() async {
    try {
      final items = await getAllPending();
      return items.length;
    } catch (_) {
      return 0;
    }
  }

  @override
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

  @override
  Future<void> removePending(String id) async {
    final db = await _getDb();
    final tx = db.transaction(_storeName, 'readwrite');
    tx.objectStore(_storeName).delete(id);
    await tx.completed;
    _notifyCountChange();
  }

  @override
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

  @override
  void dispose() {
    _countListeners.clear();
    _offlineListeners.clear();
    _db?.close();
    _db = null;
  }
}
