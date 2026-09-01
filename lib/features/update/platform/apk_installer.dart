import 'dart:io';

import 'package:flutter/services.dart';

/// Platform interface for APK installation.
class ApkInstaller {
  static const MethodChannel _channel = MethodChannel(
    'com.zinnodntu.birthdayreminderapp/install',
  );

  /// Check if the app can request package installs (Android O+).
  static Future<bool> canRequestPackageInstalls() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>(
        'canRequestPackageInstalls',
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Open system settings to allow install from unknown sources.
  static Future<bool> openInstallPermissionSettings() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>(
        'openInstallPermissionSettings',
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Launch the package installer for the given APK file.
  /// Returns true if the intent was launched successfully.
  static Future<bool> installApk(File apkFile) async {
    if (!Platform.isAndroid) return false;
    try {
      final uri = await _getContentUri(apkFile);
      final result = await _channel.invokeMethod<bool>('installApk', {
        'uri': uri,
      });
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<String> _getContentUri(File file) async {
    final uri = await _channel.invokeMethod<String>('getContentUri', {
      'path': file.path,
    });
    if (uri == null) throw Exception('Failed to get content URI');
    return uri;
  }
}
