import 'dart:html' as html;

/// Web 平台：用 Blob + AnchorElement 触发 HTML 文件下载
void downloadHtmlFile(String content, String fileName) {
  final blob = html.Blob([content], 'text/html;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';
  html.document.body!.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
