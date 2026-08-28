import 'report_download_helper_stub.dart'
    if (dart.library.html) 'report_download_helper_web.dart' as download;
import '../../booth/models/booth.dart';
import '../../photo/models/photo.dart';
import '../../flag/models/flag.dart';

/// HTML 复盘报告导出服务
///
/// 将场次下的所有摊位、照片、旗子标注聚合为一份单文件 HTML 报告：
/// - 每个摊位一个分区
/// - 每张照片显示原图 + 旗子红点标注（基于 position_x/y 相对坐标，用百分比定位）
/// - 照片下方为旗子明细表（编号/现场报价/换算价/远程目标价/采购状态/最终状态）
///
/// 浏览器打开即可查看，也可通过打印另存为 PDF 归档。
class ReportExportService {
  /// 导出整个场次的复盘报告
  Future<void> exportEventReport({
    required String eventName,
    required List<Booth> booths,
    required Future<List<Photo>> Function(String boothId) loadPhotos,
    required Future<List<Flag>> Function(String photoId) loadFlags,
  }) async {
    // 并行加载所有摊位下的照片，再并行加载照片下的旗子
    final boothPhotos = <String, List<Photo>>{};
    final photoFlags = <String, List<Flag>>{};

    for (final booth in booths) {
      final photos = await loadPhotos(booth.id);
      boothPhotos[booth.id] = photos;
      for (final photo in photos) {
        photoFlags[photo.id] = await loadFlags(photo.id);
      }
    }

    final htmlContent = _buildHtml(
      eventName: eventName,
      booths: booths,
      boothPhotos: boothPhotos,
      photoFlags: photoFlags,
    );

    _downloadHtml(htmlContent, 'report_${eventName}.html');
  }

  String _buildHtml({
    required String eventName,
    required List<Booth> booths,
    required Map<String, List<Photo>> boothPhotos,
    required Map<String, List<Flag>> photoFlags,
  }) {
    final now = DateTime.now();
    final timeStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final boothSections = booths.map((booth) {
      final photos = boothPhotos[booth.id] ?? [];
      final photoCards = photos.map((photo) {
        final flags = photoFlags[photo.id] ?? [];
        return _buildPhotoCard(photo, flags);
      }).join('\n');

      final totalFlags = photos.fold<int>(0, (sum, p) {
        return sum + (photoFlags[p.id]?.length ?? 0);
      });
      final purchased = photos.fold<int>(0, (sum, p) {
        final flags = photoFlags[p.id] ?? [];
        return sum +
            flags
                .where((f) =>
                    f.finalStatus == '购买' || f.purchaseStatus == 'Purchased')
                .length;
      });

      final supplierInfo = booth.supplierName != null
          ? '<span class="supplier">供应商：${booth.supplierName}</span>'
          : '';

      return '''
<section class="booth-section">
  <h2>摊位 ${_esc(booth.boothNumber)} $supplierInfo</h2>
  <div class="booth-summary">照片 ${photos.length} 张 · 旗子 $totalFlags 面 · 成交 $purchased 面</div>
  $photoCards
</section>''';
    }).join('\n');

    return '''<!DOCTYPE html>
<html lang="zh">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>复盘报告 - ${_esc(eventName)}</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "PingFang SC", "Microsoft YaHei", sans-serif; background: #f0f2f5; color: #1a1a2e; }
  .header { background: linear-gradient(135deg, #1a1a2e, #16213e); color: #fff; padding: 28px 24px; }
  .header h1 { font-size: 24px; margin-bottom: 6px; }
  .header .meta { font-size: 13px; opacity: .75; }
  .main { max-width: 1100px; margin: 0 auto; padding: 20px 16px 60px; }
  .booth-section { background: #fff; border-radius: 10px; box-shadow: 0 1px 4px rgba(0,0,0,.08); padding: 20px; margin-bottom: 24px; }
  .booth-section h2 { font-size: 18px; margin-bottom: 6px; display: flex; align-items: center; gap: 10px; flex-wrap: wrap; }
  .supplier { font-size: 13px; color: #3f51b5; font-weight: normal; }
  .booth-summary { font-size: 13px; color: #666; margin-bottom: 16px; }
  .photo-card { border: 1px solid #e5e7eb; border-radius: 8px; padding: 14px; margin-bottom: 20px; background: #fafbfc; }
  .photo-title { font-size: 13px; color: #555; margin-bottom: 10px; }
  .photo-img-wrap { position: relative; display: inline-block; max-width: 100%; background: #eee; border-radius: 6px; overflow: hidden; }
  .photo-img-wrap img { max-width: 100%; display: block; }
  .flag-marker { position: absolute; width: 20px; height: 20px; transform: translate(-50%,-50%); border-radius: 50%; background: rgba(220,38,38,.9); border: 2px solid #fff; color: #fff; font-size: 11px; font-weight: 700; display: flex; align-items: center; justify-content: center; box-shadow: 0 1px 4px rgba(0,0,0,.4); pointer-events: none; }
  .flag-table { width: 100%; border-collapse: collapse; margin-top: 10px; font-size: 13px; }
  .flag-table th, .flag-table td { border: 1px solid #e5e7eb; padding: 7px 10px; text-align: left; }
  .flag-table th { background: #f3f4f6; font-weight: 600; }
  .flag-table tr:nth-child(even) { background: #f9fafb; }
  .status-purchased { color: #16a34a; font-weight: 600; }
  .status-soldout { color: #dc2626; font-weight: 600; }
  .status-abandoned { color: #9ca3af; }
  .empty { color: #9ca3af; font-size: 13px; padding: 20px 0; text-align: center; }
  @media print {
    body { background: #fff; }
    .booth-section { box-shadow: none; border: 1px solid #ddd; page-break-inside: avoid; }
    .photo-card { page-break-inside: avoid; }
  }
</style>
</head>
<body>
  <div class="header">
    <h1>采购复盘报告</h1>
    <div class="meta">${_esc(eventName)} · 导出时间：$timeStr</div>
  </div>
  <div class="main">
    $boothSections
  </div>
</body>
</html>''';
  }

  String _buildPhotoCard(Photo photo, List<Flag> flags) {
    final markers = flags.map((f) {
      final left = (f.positionX * 100).toStringAsFixed(2);
      final top = (f.positionY * 100).toStringAsFixed(2);
      return '''
      <div class="flag-marker" style="left:$left%;top:$top%">${f.number}</div>''';
    }).join('\n');

    if (flags.isEmpty) {
      return '''
<div class="photo-card">
  <div class="photo-title">${_esc(photo.supplierName ?? '未标注供应商')} · 无旗子标注</div>
  <div class="photo-img-wrap"><img src="${_esc(photo.url)}" alt="photo" loading="lazy"></div>
</div>''';
    }

    final rows = flags.map((f) {
      final statusClass = _statusClass(f);
      return '''
      <tr>
        <td>${f.number}</td>
        <td>${_money(f.priceRmb)}</td>
        <td>${_money(f.priceConverted)}</td>
        <td>${_money(f.targetPrice)}</td>
        <td class="$statusClass">${_esc(_purchaseStatusText(f))}</td>
        <td class="$statusClass">${_esc(_finalStatusText(f))}</td>
      </tr>''';
    }).join('\n');

    return '''
<div class="photo-card">
  <div class="photo-title">${_esc(photo.supplierName ?? '未标注供应商')} · ${flags.length} 面旗子</div>
  <div class="photo-img-wrap"><img src="${_esc(photo.url)}" alt="photo" loading="lazy">$markers</div>
  <table class="flag-table">
    <thead><tr><th>编号</th><th>现场报价(¥)</th><th>换算价</th><th>远程目标价</th><th>采购状态</th><th>最终状态</th></tr></thead>
    <tbody>$rows</tbody>
  </table>
</div>''';
  }

  String _statusClass(Flag f) {
    if (f.finalStatus == '购买' || f.purchaseStatus == 'Purchased') {
      return 'status-purchased';
    }
    if (f.finalStatus == '已售' || f.purchaseStatus == 'sold out') {
      return 'status-soldout';
    }
    if (f.finalStatus == '放弃') {
      return 'status-abandoned';
    }
    return '';
  }

  String _purchaseStatusText(Flag f) {
    if (f.purchaseStatus == 'Purchased') return '已购';
    if (f.purchaseStatus == 'sold out') return '售罄';
    if (f.purchaseStatus == null || f.purchaseStatus!.isEmpty) return '-';
    return f.purchaseStatus!;
  }

  String _finalStatusText(Flag f) {
    if (f.finalStatus == null || f.finalStatus!.isEmpty) return '-';
    return f.finalStatus!;
  }

  String _money(double? v) => v == null ? '-' : v.toStringAsFixed(2);

  String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  void _downloadHtml(String content, String fileName) {
    download.downloadHtmlFile(content, fileName);
  }
}
