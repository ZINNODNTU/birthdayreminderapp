import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/logging/app_logger.dart';

/// Stages the backup pipeline can fail at. Persisted in [BackupException]
/// so the UI can show a precise error message and we can grep the
/// right log bucket.
enum BackupStage { collect, encode, archive, writeFile, share }

class BackupException implements Exception {
  const BackupException(this.stage, this.cause, [this.detail]);
  final BackupStage stage;
  final String cause;
  final Object? detail;

  @override
  String toString() =>
      'BackupException(stage=${stage.name}, cause=$cause, detail=$detail)';
}

/// Outcome of `BackupFileService.save`. The UI uses [outcome] to decide
/// whether to celebrate, warn, or report a real failure.
enum BackupOutcome { savedToUserPath, shared, shareCancelled, shareFailed }

class BackupSaveResult {
  const BackupSaveResult({
    required this.outcome,
    required this.path,
    required this.bytes,
  });
  final BackupOutcome outcome;
  final String? path;
  final Uint8List bytes;
}

class BackupFileService {
  /// Normalize "data:image/jpeg;base64,..." or "data:image/png;base64,..."
  /// prefixes before we hand the string to `base64Decode`. Returns the
  /// cleaned payload or `null` if it does not look like base64 at all.
  static String? normalizeBase64(String input) {
    var s = input.trim();
    if (s.isEmpty) return null;
    const prefix = 'base64,';
    final idx = s.indexOf(prefix);
    if (idx >= 0) s = s.substring(idx + prefix.length);
    // Drop any data: URL metadata. After stripping the payload must be
    // pure base64 chars.
    s = s.replaceAll(RegExp(r'\s+'), '');
    if (s.length < 8) return null;
    if (!RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(s)) return null;
    return s;
  }

  /// Persist [bytes] to a real file before sharing. We never let the
  /// archive bytes be shared in-memory because some share targets
  /// (Telegram, Drive) require a stable filesystem path and will fail
  /// silently otherwise. Returns the saved path or throws.
  Future<String> _writeArchive(
    Uint8List bytes,
    String fileName, {
    required bool ensureExists,
  }) async {
    Directory dir;
    try {
      dir = await getApplicationDocumentsDirectory();
    } catch (e, st) {
      AppLogger.error('Backup', e, st);
      throw BackupException(
        BackupStage.writeFile,
        'Không thể truy cập thư mục dữ liệu ứng dụng.',
        e,
      );
    }
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    if (ensureExists && !await file.exists()) {
      throw BackupException(
        BackupStage.writeFile,
        'File backup không tồn tại sau khi ghi.',
      );
    }
    final length = await file.length();
    if (length <= 0) {
      throw BackupException(
        BackupStage.writeFile,
        'File backup rỗng (0 byte).',
      );
    }
    return file.path;
  }

  /// Save the archive bytes produced by [BackupService.createBackup].
  /// Steps:
  ///   1. Try FilePicker.saveFile so the user can pick a final location.
  ///   2. Otherwise write to the app documents directory and open the
  ///      platform share sheet pointing at the real file.
  /// The file is written and verified BEFORE we open the share sheet so
  /// the user never sees a "không thể tạo bản sao lưu" because share
  /// was cancelled.
  Future<BackupSaveResult> save(Uint8List bytes, String fileName) async {
    if (bytes.isEmpty) {
      throw BackupException(BackupStage.archive, 'Dữ liệu backup rỗng.');
    }
    String? userPath;
    try {
      userPath = await FilePicker.saveFile(
        dialogTitle: 'Lưu bản sao lưu',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
    } catch (e, st) {
      AppLogger.warn('Backup', 'FilePicker.saveFile failed: $e\n$st');
      userPath = null;
    }
    if (userPath != null) {
      final f = File(userPath);
      await f.writeAsBytes(bytes, flush: true);
      if (!await f.exists() || await f.length() <= 0) {
        throw BackupException(
          BackupStage.writeFile,
          'Không thể ghi file backup vào vị trí đã chọn.',
        );
      }
      return BackupSaveResult(
        outcome: BackupOutcome.savedToUserPath,
        path: userPath,
        bytes: bytes,
      );
    }
    final savedPath = await _writeArchive(bytes, fileName, ensureExists: true);
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(savedPath, mimeType: 'application/zip')],
          text: 'Bản sao lưu Birthday Reminder',
        ),
      );
      return BackupSaveResult(
        outcome: BackupOutcome.shared,
        path: savedPath,
        bytes: bytes,
      );
    } on PlatformException catch (e, st) {
      AppLogger.warn('Backup', 'share sheet error: $e\n$st');
      return BackupSaveResult(
        outcome: BackupOutcome.shareFailed,
        path: savedPath,
        bytes: bytes,
      );
    } catch (e, st) {
      // share_plus throws SharePlusException for cancellations and
      // platform failures. We translate them into a recoverable signal
      // — backup file already exists, so the user can still locate it
      // via the documents directory.
      AppLogger.warn('Backup', 'share unknown error: $e\n$st');
      final message = e.toString();
      if (message.contains('cancel') || message.contains('Cancel')) {
        return BackupSaveResult(
          outcome: BackupOutcome.shareCancelled,
          path: savedPath,
          bytes: bytes,
        );
      }
      return BackupSaveResult(
        outcome: BackupOutcome.shareFailed,
        path: savedPath,
        bytes: bytes,
      );
    }
  }

  Future<Uint8List?> pick() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      withData: true,
    );
    if (result == null) return null;
    final f = result.files.single;
    return f.bytes ?? (f.path == null ? null : File(f.path!).readAsBytes());
  }
}
