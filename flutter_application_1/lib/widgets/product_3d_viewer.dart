import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../khan_colors.dart';

Uri? threeDModelViewerUri(String? value) {
  final uri = Uri.tryParse(value?.trim() ?? '');
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;

  final isSketchfab =
      uri.host == 'sketchfab.com' || uri.host.endsWith('.sketchfab.com');
  if (!isSketchfab || uri.pathSegments.contains('embed')) return uri;

  final modelIdPattern = RegExp(r'(?:^|-)([a-zA-Z0-9]{32})$');
  for (final segment in uri.pathSegments.reversed) {
    final modelId = modelIdPattern.firstMatch(segment)?.group(1);
    if (modelId != null) {
      return Uri.https('sketchfab.com', '/models/$modelId/embed');
    }
  }
  return uri;
}

class Product3DViewer extends StatefulWidget {
  const Product3DViewer({super.key, required this.url, required this.onClose});

  final String url;
  final VoidCallback onClose;

  @override
  State<Product3DViewer> createState() => _Product3DViewerState();
}

class _Product3DViewerState extends State<Product3DViewer> {
  late Uri? _viewerUri;
  bool _loading = true;
  String? _error;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _viewerUri = threeDModelViewerUri(widget.url);
  }

  @override
  void didUpdateWidget(covariant Product3DViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _viewerUri = threeDModelViewerUri(widget.url);
      _loading = true;
      _error = null;
      _retryCount = 0;
    }
  }

  void _showLoadError() {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error =
          'This 3D model could not be loaded. Check your connection '
          'or try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewerUri = _viewerUri;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.view_in_ar_outlined, color: khanGold),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Interactive 3D model',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: khanDark, fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              tooltip: 'Close 3D viewer',
              onPressed: widget.onClose,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : 600.0;
            final height = (availableWidth * 0.62).clamp(360.0, 520.0);
            return SizedBox(
              height: height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: ColoredBox(
                  color: khanDark,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (viewerUri != null && _error == null)
                        InAppWebView(
                          key: ValueKey(_retryCount),
                          initialUrlRequest: URLRequest(
                            url: WebUri(viewerUri.toString()),
                          ),
                          initialSettings: InAppWebViewSettings(
                            javaScriptEnabled: true,
                            supportZoom: true,
                            iframeAllowFullscreen: true,
                          ),
                          onLoadStart: (_, _) {
                            if (!mounted) return;
                            setState(() {
                              _loading = true;
                              _error = null;
                            });
                          },
                          onLoadStop: (_, _) {
                            if (!mounted) return;
                            setState(() => _loading = false);
                          },
                          onReceivedError: (_, request, error) {
                            if (request.isForMainFrame ?? true) {
                              _showLoadError();
                            }
                          },
                          onReceivedHttpError: (_, request, response) {
                            if ((request.isForMainFrame ?? true) &&
                                (response.statusCode ?? 0) >= 400) {
                              _showLoadError();
                            }
                          },
                        )
                      else if (viewerUri == null)
                        _errorContent(
                          'This 3D model link is not a valid HTTPS URL.',
                          null,
                        ),
                      if (_loading && _error == null && viewerUri != null)
                        const ColoredBox(
                          color: khanDark,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: khanGold),
                                SizedBox(height: 12),
                                Text(
                                  'Loading 3D model...',
                                  style: TextStyle(color: khanLightGold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_error != null) _errorContent(_error!, _retry),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _errorContent(String message, VoidCallback? onRetry) {
    return ColoredBox(
      color: khanDark,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.view_in_ar_outlined, color: khanGold, size: 40),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: khanLightGold),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: onRetry,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: khanGold,
                    side: const BorderSide(color: khanGold),
                  ),
                  child: const Text('Try again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _retry() {
    setState(() {
      _retryCount++;
      _loading = true;
      _error = null;
    });
  }
}
