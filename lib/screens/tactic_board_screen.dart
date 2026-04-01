import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class TacticBoardScreen extends StatefulWidget {
  final String sourcePath;

  const TacticBoardScreen({super.key, required this.sourcePath});

  @override
  State<TacticBoardScreen> createState() => _TacticBoardScreenState();
}

class _TacticBoardScreenState extends State<TacticBoardScreen> {
  InAppWebViewController? _engineController;
  double _renderProgress = 0;

  bool _cmbk = false;
  bool _cbf = false;

  final _secureStorage = const FlutterSecureStorage();
  static const String _lastSyncStateKey = 'last_sync_state_hash';
  bool _isInitializing = true;
  String? _initialUrl;

  final InAppWebViewSettings _engineSettings = InAppWebViewSettings(
    javaScriptEnabled: true,
    javaScriptCanOpenWindowsAutomatically: true,
    supportMultipleWindows: true,
    allowsInlineMediaPlayback: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsBackForwardNavigationGestures: true,
    isFraudulentWebsiteWarningEnabled: false,
    thirdPartyCookiesEnabled: true,
    allowFileAccess: true,
  );

  Future<void> _resolveInitialState() async {
    // 1. Check secure storage for a previous session URL
    String? savedSessionUrl = await _secureStorage.read(key: _lastSyncStateKey);

    // 2. Fallback to the root route provided by the TDS if no session exists
    setState(() {
      _initialUrl = savedSessionUrl ?? widget.sourcePath;
      _isInitializing = false;
    });
  }

  Future<void> _evaluateAndSaveUrl(String currentUrl) async {
      await _secureStorage.write(key: _lastSyncStateKey, value: currentUrl);
  }

  @override
  void initState() {
    super.initState();
    _resolveInitialState();
  }

  @override
  Widget build(BuildContext context) {

    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (await _engineController?.canGoBack() ?? false) {
          _engineController?.goBack();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(_initialUrl!)),
                initialSettings: _engineSettings,
                onWebViewCreated: (controller) {
                  _engineController = controller;
                },
                onUpdateVisitedHistory: (controller, url, isReload) async {
                  final canBack = await controller.canGoBack();
                  final canForward = await controller.canGoForward();
                  if (mounted) {
                    setState(() {
                      _cmbk = canBack;
                      _cbf = canForward;
                    });
                  }

                  if (url != null) {
                    _evaluateAndSaveUrl(url.toString());
                  }
                },
                onProgressChanged: (controller, progress) {
                  setState(() {
                    _renderProgress = progress / 100;
                  });
                },
                onPermissionRequest: (controller, request) async {
                  final resources = <PermissionResourceType>[];

                  if (request.resources.contains(PermissionResourceType.CAMERA)) {
                    final status = await Permission.camera.request();
                    if (status.isGranted) resources.add(PermissionResourceType.CAMERA);
                  }
                  if (request.resources.contains(PermissionResourceType.MICROPHONE)) {
                    final status = await Permission.microphone.request();
                    if (status.isGranted) resources.add(PermissionResourceType.MICROPHONE);
                  }

                  return PermissionResponse(
                    resources: resources,
                    action: resources.isEmpty
                        ? PermissionResponseAction.DENY
                        : PermissionResponseAction.GRANT,
                  );
                },

                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  final uri = navigationAction.request.url;
                  if (uri == null) return NavigationActionPolicy.CANCEL;

                  final scheme = uri.scheme.toLowerCase();

                  if (scheme == 'http' || scheme == 'https' || scheme == 'about') {
                    return NavigationActionPolicy.ALLOW;
                  }

                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                    return NavigationActionPolicy.CANCEL;
                  }

                  return NavigationActionPolicy.ALLOW;
                },

                onCreateWindow: (controller, createWindowAction) async {
                  showDialog(
                    context: context,
                    useSafeArea: false,
                    builder: (context) {
                      return _buildSecondaryEngine(createWindowAction.request.url);
                    },
                  );
                  return true;
                },
              ),

              if (_renderProgress < 1.0)
                LinearProgressIndicator(
                  value: _renderProgress,
                  backgroundColor: Colors.transparent,
                  color: Colors.blueAccent.withOpacity(0.5),
                ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            height: 50,
            decoration: const BoxDecoration(
              color: Colors.black87,
              border: Border(top: BorderSide(color: Colors.white12, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 20),
                  color: _cmbk ? Colors.white : Colors.white30,
                  onPressed: _cmbk
                      ? () => _engineController?.goBack()
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 20),
                  color: _cbf ? Colors.white : Colors.white30,
                  onPressed: _cbf
                      ? () => _engineController?.goForward()
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 22),
                  color: Colors.white,
                  onPressed: () => _engineController?.reload(),
                ),
                IconButton(
                  icon: const Icon(Icons.home_outlined, size: 24),
                  color: Colors.white,
                  onPressed: () {
                    _engineController?.loadUrl(
                      urlRequest: URLRequest(url: WebUri(widget.sourcePath)),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryEngine(WebUri? targetPath) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        toolbarHeight: 40,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: targetPath),
        initialSettings: _engineSettings,
      ),
    );
  }
}