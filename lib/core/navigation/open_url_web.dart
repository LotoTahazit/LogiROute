import 'package:web/web.dart' as web;

/// Open URL in a new browser tab (web only).
void openUrlInNewTab(String url) {
  web.window.open(url, '_blank');
}
