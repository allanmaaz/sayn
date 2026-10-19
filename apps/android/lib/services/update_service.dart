import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'platform_channels.dart';

class UpdateInfo {
  final bool hasUpdate;
  final String latestVersion;
  final String currentVersion;
  final String downloadUrl;
  final String title;
  final String releaseNotes;

  UpdateInfo({
    required this.hasUpdate,
    required this.latestVersion,
    required this.currentVersion,
    required this.downloadUrl,
    required this.title,
    required this.releaseNotes,
  });
}

class UpdateService {
  static const String _workerVersionUrl =
      'https://sayn-api-worker.allanmaazimdad.workers.dev/api/v1/version';
  static const String _saynVersionUrl = 'https://sayn.ai/version.json';
  static const String _githubReleasesUrl =
      'https://api.github.com/repos/allanmaaz/sayn/releases/latest';

  static Future<UpdateInfo?> checkUpdate() async {
    try {
      final currentVersion = await PlatformChannels.getAppVersion();

      // 1. Primary: Check live Cloudflare Worker endpoint (always-on, unauthenticated, zero rate-limit)
      for (final endpoint in [_workerVersionUrl, _saynVersionUrl]) {
        try {
          final res = await http.get(
            Uri.parse(endpoint),
            headers: {'Accept': 'application/json', 'User-Agent': 'SAYN-Android-App'},
          ).timeout(const Duration(seconds: 4));

          if (res.statusCode == 200) {
            final data = jsonDecode(res.body) as Map<String, dynamic>;
            final latest = (data['version'] as String? ?? '').replaceFirst('v', '').trim();
            final name = data['name'] as String? ?? 'SAYN Update';
            final body = data['releaseNotes'] as String? ?? '';
            final downloadUrl = data['downloadUrl'] as String? ??
                'https://github.com/allanmaaz/sayn/releases/download/v1.1.5/sayn-release.apk';

            return UpdateInfo(
              hasUpdate: _isNewer(latest, currentVersion),
              latestVersion: latest,
              currentVersion: currentVersion,
              downloadUrl: downloadUrl,
              title: name,
              releaseNotes: body,
            );
          }
        } catch (_) {}
      }

      // 2. Secondary: Fallback to GitHub Releases API with explicit User-Agent
      final response = await http.get(
        Uri.parse(_githubReleasesUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'SAYN-Android-App',
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = (data['tag_name'] as String? ?? '').replaceFirst('v', '').trim();
      final name = data['name'] as String? ?? 'SAYN Update';
      final body = data['body'] as String? ?? '';

      // Find sayn-release.apk asset
      String downloadUrl = '';
      final assets = data['assets'] as List<dynamic>? ?? [];
      for (final asset in assets) {
        final aName = asset['name'] as String? ?? '';
        if (aName.endsWith('.apk')) {
          downloadUrl = asset['browser_download_url'] as String? ?? '';
          break;
        }
      }

      if (downloadUrl.isEmpty) {
        downloadUrl = 'https://github.com/allanmaaz/sayn/releases/latest/download/sayn-release.apk';
      }

      final hasUpdate = _isNewer(tagName, currentVersion);

      return UpdateInfo(
        hasUpdate: hasUpdate,
        latestVersion: tagName,
        currentVersion: currentVersion,
        downloadUrl: downloadUrl,
        title: name,
        releaseNotes: body,
      );
    } catch (_) {
      return null;
    }
  }

  static bool _isNewer(String latest, String current) {
    if (latest.isEmpty || current.isEmpty) return false;
    final lParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final cParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final l = i < lParts.length ? lParts[i] : 0;
      final c = i < cParts.length ? cParts[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }

  /// Displays the interactive update dialog with real-time download progress
  static void showUpdateDialog(BuildContext context, UpdateInfo info) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _UpdateDialogContent(info: info),
    );
  }
}

class _UpdateDialogContent extends StatefulWidget {
  final UpdateInfo info;

  const _UpdateDialogContent({required this.info});

  @override
  State<_UpdateDialogContent> createState() => _UpdateDialogContentState();
}

class _UpdateDialogContentState extends State<_UpdateDialogContent> {
  bool _isDownloading = false;
  int _progress = 0;
  String _statusMessage = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    PlatformChannels.setUpdaterListener(
      onProgress: (p) {
        if (mounted) {
          setState(() {
            _progress = p;
            _statusMessage = 'Downloading update... $p%';
          });
        }
      },
      onComplete: (filePath) {
        if (mounted) {
          setState(() {
            _progress = 100;
            _statusMessage = 'Download complete! Launching installer...';
          });
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _errorMessage = err;
            _statusMessage = 'Update failed. Tap retry.';
          });
        }
      },
    );
  }

  Future<void> _startUpdate() async {
    final canInstall = await PlatformChannels.canRequestPackageInstalls();
    if (!canInstall) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable "Install unknown apps" for SAYN to auto-update.'),
            backgroundColor: Color(0xFF6F1025),
          ),
        );
      }
      await PlatformChannels.openInstallPermissionSettings();
      return;
    }

    setState(() {
      _isDownloading = true;
      _progress = 0;
      _errorMessage = null;
      _statusMessage = 'Starting download...';
    });

    await PlatformChannels.downloadAndInstallApk(widget.info.downloadUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF180B0F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF3D1520)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0x336F1025),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF3D1520)),
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    color: Color(0xFFF5EBDD),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'New Update Available',
                        style: TextStyle(
                          color: Color(0xFFF5EBDD),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'v${widget.info.latestVersion} (Current: v${widget.info.currentVersion})',
                        style: const TextStyle(
                          color: Color(0xFFD6C7B2),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(maxHeight: 140),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF240F16),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF3D1520)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  widget.info.releaseNotes.isNotEmpty
                      ? widget.info.releaseNotes
                      : 'Performance improvements, bug fixes, and latest voice keyboard features.',
                  style: const TextStyle(
                    color: Color(0xFFF5EBDD),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_isDownloading) ...[
              LinearProgressIndicator(
                value: _progress > 0 ? _progress / 100.0 : null,
                backgroundColor: const Color(0xFF240F16),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6F1025)),
                borderRadius: BorderRadius.circular(6),
                minHeight: 8,
              ),
              const SizedBox(height: 10),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFF5EBDD),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFFF453A), fontSize: 12),
              ),
              const SizedBox(height: 12),
            ],
            if (!_isDownloading) ...[
              ElevatedButton(
                onPressed: _startUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6F1025),
                  foregroundColor: const Color(0xFFF5EBDD),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Download & Install Update',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Later',
                  style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
