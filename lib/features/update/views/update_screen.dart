import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../l10n/l10n_extensions.dart';
import '../models/app_release.dart';
import '../models/update_status.dart';
import '../services/app_update_service.dart';

/// Screen that displays current version and update options.
class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  @override
  void initState() {
    super.initState();
    // Perform a check on load, but only if not already checked recently.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates(manual: true);
    });
  }

  Future<void> _checkForUpdates({bool manual = false}) async {
    final service = context.read<AppUpdateService>();
    if (service.status == UpdateStatus.checking) return;
    await service.checkForUpdates(manual: manual);
  }

  Future<void> _downloadUpdate() async {
    final service = context.read<AppUpdateService>();
    if (service.status != UpdateStatus.updateAvailable) return;
    await service.downloadUpdate();
  }

  Future<void> _installUpdate() async {
    final service = context.read<AppUpdateService>();
    if (service.status != UpdateStatus.readyToInstall) return;
    await service.installUpdate();
  }

  void _ignoreVersion() {
    final service = context.read<AppUpdateService>();
    service.ignoreVersion();
  }

  Future<void> _openDownloadInBrowser() async {
    final url = context.read<AppUpdateService>().latestRelease?.apkDownloadUrl;
    if (url == null || url.isEmpty) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.updateTitle)),
      body: Consumer<AppUpdateService>(
        builder: (ctx, service, _) {
          final status = service.status;
          final release = service.latestRelease;
          final error = service.errorMessage;
          final progress = service.downloadProgress;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCurrentVersionCard(context),
                const SizedBox(height: 16),
                _buildStatusCard(
                  context,
                  status,
                  release,
                  error,
                  progress,
                  service.downloadedBytes,
                  service.totalBytes,
                ),
                const SizedBox(height: 16),
                if (status == UpdateStatus.updateAvailable ||
                    status == UpdateStatus.readyToInstall ||
                    (status == UpdateStatus.error && release != null))
                  _buildActionButtons(context, status),
                if (release != null) _buildReleaseDetails(context, release),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentVersionCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.currentVersion,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // We need to get package info. We'll use a future builder or just use a provider? We can use the service.
            FutureBuilder(
              future: PackageInfo.fromPlatform(),
              builder: (ctx, snapshot) {
                if (snapshot.hasData) {
                  final info = snapshot.data!;
                  return Text('${info.version} (${info.buildNumber})');
                } else {
                  return Text(context.l10n.loading);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    UpdateStatus status,
    AppRelease? release,
    String? error,
    double progress,
    int downloadedBytes,
    int? totalBytes,
  ) {
    String title;
    String subtitle;
    Color color = Colors.black;

    switch (status) {
      case UpdateStatus.idle:
        title = context.l10n.updateReady;
        subtitle = context.l10n.updateCheckHint;
        break;
      case UpdateStatus.checking:
        title = context.l10n.checkingUpdate;
        subtitle = context.l10n.checkingUpdate;
        break;
      case UpdateStatus.upToDate:
        title = context.l10n.upToDate;
        subtitle = context.l10n.usingLatestVersion;
        color = Colors.green.shade700;
        break;
      case UpdateStatus.updateAvailable:
        title = context.l10n.newVersionAvailable;
        subtitle = context.l10n.versionAvailable(release?.version ?? '');
        color = Colors.blue.shade700;
        break;
      case UpdateStatus.reinstallRequired:
        title = context.l10n.reinstallRequired;
        subtitle = release?.migrationMessage ?? context.l10n.reinstallMessage;
        color = Colors.orange.shade800;
        break;
      case UpdateStatus.downloading:
        title = context.l10n.downloadingUpdate;
        subtitle =
            totalBytes != null && totalBytes > 0
                ? '${(progress * 100).toStringAsFixed(0)}% — ${_formatBytes(downloadedBytes)} / ${_formatBytes(totalBytes)}'
                : context.l10n.downloadedSize(_formatBytes(downloadedBytes));
        break;
      case UpdateStatus.verifying:
        title = context.l10n.verifyingUpdate;
        subtitle = context.l10n.verifyingFile;
        break;
      case UpdateStatus.readyToInstall:
        title = context.l10n.readyToInstall;
        subtitle = context.l10n.updateDownloaded;
        color = Colors.green.shade700;
        break;
      case UpdateStatus.installPermissionRequired:
        title = context.l10n.installPermissionRequired;
        subtitle = context.l10n.installPermissionHint;
        color = Colors.orange.shade800;
        break;
      case UpdateStatus.installing:
        title = context.l10n.installingUpdate;
        subtitle = context.l10n.pleaseWait;
        break;
      case UpdateStatus.error:
        title = context.l10n.updateError;
        subtitle = error ?? context.l10n.genericUpdateError;
        color = Colors.red.shade700;
        break;
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(subtitle),
            if (status == UpdateStatus.downloading)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(
                  value: totalBytes != null && totalBytes > 0 ? progress : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, UpdateStatus status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (status == UpdateStatus.updateAvailable)
          OutlinedButton(
            onPressed: _ignoreVersion,
            child: Text(context.l10n.skipUpdate),
          ),
        if (status == UpdateStatus.error)
          OutlinedButton(
            onPressed: _downloadUpdate,
            child: Text(context.l10n.retry),
          ),
        const SizedBox(width: 8),
        if (status == UpdateStatus.error)
          ElevatedButton.icon(
            onPressed: _openDownloadInBrowser,
            icon: const Icon(Icons.open_in_browser),
            label: Text(context.l10n.openDownloadPage),
          )
        else if (status == UpdateStatus.reinstallRequired)
          Expanded(child: Text(context.l10n.reinstallSteps))
        else
          ElevatedButton.icon(
            onPressed:
                status == UpdateStatus.updateAvailable &&
                        context
                                .read<AppUpdateService>()
                                .latestRelease
                                ?.sha256
                                .isNotEmpty ==
                            true
                    ? _downloadUpdate
                    : null,
            icon: const Icon(Icons.download),
            label: Text(context.l10n.downloadUpdate),
          ),
        if (status == UpdateStatus.readyToInstall)
          ElevatedButton.icon(
            onPressed: _installUpdate,
            icon: const Icon(Icons.install_desktop),
            label: Text(context.l10n.installUpdate),
          ),
      ],
    );
  }

  Widget _buildReleaseDetails(BuildContext context, AppRelease release) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.releaseDetails,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _infoRow(context.l10n.latestVersion, release.version),
            _infoRow(context.l10n.buildLabel, '${release.buildNumber}'),
            _infoRow(
              context.l10n.releaseDate,
              DateFormat('dd/MM/yyyy').format(release.publishedAt),
            ),
            _infoRow(
              context.l10n.fileSize,
              '${(release.apkSize / 1024 / 1024).toStringAsFixed(1)} MB',
            ),
            if (release.sha256.isNotEmpty)
              _infoRow(
                'SHA256',
                '${release.sha256.substring(0, 8)}...${release.sha256.substring(release.sha256.length - 8)}',
              ),
            const Divider(),
            Text(
              context.l10n.whatsNew,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              release.releaseNotes.isEmpty
                  ? context.l10n.noReleaseNotes
                  : release.releaseNotes,
            ),
            if (release.githubReleaseUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: GestureDetector(
                  onTap: () {
                    // TODO: open URL in browser (use url_launcher)
                  },
                  child: Text(
                    context.l10n.viewOnGitHub,
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
