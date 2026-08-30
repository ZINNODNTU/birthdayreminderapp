import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cập nhật ứng dụng')),
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
                _buildStatusCard(context, status, release, error, progress),
                const SizedBox(height: 16),
                if (status == UpdateStatus.updateAvailable ||
                    status == UpdateStatus.readyToInstall)
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
            const Text(
              'Phiên bản hiện tại',
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
                  return const Text('Đang tải...');
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
  ) {
    String title;
    String subtitle;
    Color color = Colors.black;

    switch (status) {
      case UpdateStatus.idle:
        title = 'Sẵn sàng';
        subtitle = 'Nhấn "Kiểm tra cập nhật" để tìm phiên bản mới.';
        break;
      case UpdateStatus.checking:
        title = 'Đang kiểm tra...';
        subtitle = 'Đang kiểm tra phiên bản mới...';
        break;
      case UpdateStatus.upToDate:
        title = 'Đã có phiên bản mới nhất';
        subtitle = 'Bạn đang sử dụng phiên bản mới nhất.';
        color = Colors.green.shade700;
        break;
      case UpdateStatus.updateAvailable:
        title = 'Có bản cập nhật mới!';
        subtitle = 'Phiên bản ${release?.version} đã sẵn sàng.';
        color = Colors.blue.shade700;
        break;
      case UpdateStatus.reinstallRequired:
        title = 'Yêu cầu cài đặt lại';
        subtitle =
            release?.migrationMessage ??
            'Phiên bản mới sử dụng chữ ký bảo mật mới. Hãy sao lưu dữ liệu trước khi cài đặt lại.';
        color = Colors.orange.shade800;
        break;
      case UpdateStatus.downloading:
        title = 'Đang tải...';
        subtitle = '${(progress * 100).toStringAsFixed(0)}%';
        break;
      case UpdateStatus.verifying:
        title = 'Đang xác minh...';
        subtitle = 'Đang kiểm tra tính toàn vẹn của tệp...';
        break;
      case UpdateStatus.readyToInstall:
        title = 'Sẵn sàng cài đặt!';
        subtitle = 'Bản cập nhật đã tải về và xác minh.';
        color = Colors.green.shade700;
        break;
      case UpdateStatus.installPermissionRequired:
        title = 'Cần quyền cài đặt';
        subtitle = 'Cho phép cài đặt ứng dụng từ nguồn này rồi thử lại.';
        color = Colors.orange.shade800;
        break;
      case UpdateStatus.installing:
        title = 'Đang cài đặt...';
        subtitle = 'Vui lòng chờ...';
        break;
      case UpdateStatus.error:
        title = 'Lỗi';
        subtitle = error ?? 'Đã xảy ra lỗi. Vui lòng thử lại.';
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
                child: LinearProgressIndicator(value: progress),
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
            child: const Text('Bỏ qua'),
          ),
        const SizedBox(width: 8),
        if (status == UpdateStatus.reinstallRequired)
          const Expanded(
            child: Text(
              '1. Sao lưu dữ liệu\n2. Giữ file backup an toàn\n3. Cài đặt bản mới theo hướng dẫn\n4. Khôi phục backup',
            ),
          )
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
            label: const Text('Tải bản cập nhật'),
          ),
        if (status == UpdateStatus.readyToInstall)
          ElevatedButton.icon(
            onPressed: _installUpdate,
            icon: const Icon(Icons.install_desktop),
            label: const Text('Cài đặt'),
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
            const Text(
              'Chi tiết phiên bản',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _infoRow('Phiên bản', release.version),
            _infoRow('Build', '${release.buildNumber}'),
            _infoRow(
              'Ngày phát hành',
              DateFormat('dd/MM/yyyy').format(release.publishedAt),
            ),
            _infoRow(
              'Dung lượng',
              '${(release.apkSize / 1024 / 1024).toStringAsFixed(1)} MB',
            ),
            if (release.sha256.isNotEmpty)
              _infoRow(
                'SHA256',
                '${release.sha256.substring(0, 8)}...${release.sha256.substring(release.sha256.length - 8)}',
              ),
            const Divider(),
            const Text(
              'Có gì mới',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              release.releaseNotes.isEmpty
                  ? 'Không có ghi chú phát hành.'
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
                    'Xem trên GitHub',
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
