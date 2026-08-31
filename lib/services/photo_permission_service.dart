import 'package:permission_handler/permission_handler.dart';

/// Status of photo library permission.
enum PhotoPermissionStatus { granted, denied, permanentlyDenied, restricted }

/// Reusable service that handles photo library permission checks and requests.
///
/// `permission_handler` automatically maps [Permission.photos] to the correct
/// Android permission depending on the OS version:
///   - Android 13+ (API 33+) -> READ_MEDIA_IMAGES
///   - Older Android          -> READ_EXTERNAL_STORAGE
///
/// This keeps the call-site simple and version-agnostic.
class PhotoPermissionService {
  const PhotoPermissionService();

  /// The permission appropriate for the current platform version.
  static const Permission _photoPermission = Permission.photos;

  /// Check current status and request if not granted.
  /// Returns [PhotoPermissionStatus] representing the final state.
  Future<PhotoPermissionStatus> checkAndRequest() async {
    var status = await _photoPermission.status;

    if (status.isGranted) {
      return PhotoPermissionStatus.granted;
    }

    if (status.isDenied) {
      status = await _photoPermission.request();
      if (status.isGranted) {
        return PhotoPermissionStatus.granted;
      } else if (status.isPermanentlyDenied) {
        return PhotoPermissionStatus.permanentlyDenied;
      } else {
        return PhotoPermissionStatus.denied;
      }
    }

    if (status.isPermanentlyDenied) {
      return PhotoPermissionStatus.permanentlyDenied;
    }

    if (status.isRestricted) {
      return PhotoPermissionStatus.restricted;
    }

    return PhotoPermissionStatus.denied;
  }

  /// Open app settings so the user can enable permission manually.
  Future<bool> openSettings() async {
    return openAppSettings();
  }
}
