import 'dart:convert';

import 'package:image/image.dart' as img;
import 'package:share_plus/share_plus.dart';

class Helpers {
  static Future<String?> convertImageToBase64(XFile? image) async {
    if (image == null) return null;
    final bytes = await image.readAsBytes();
    final imageDecoded = img.decodeImage(bytes);
    if (imageDecoded == null) return null;
    final resized = img.copyResize(imageDecoded, width: 100);
    final encoded = img.encodePng(resized);
    return base64Encode(encoded);
  }

  static Future<void> shareBirthday(String name, DateTime date) async {
    final text =
        'Don\'t forget $name\'s birthday on ${date.day}/${date.month}/${date.year}!';
    await SharePlus.instance.share(ShareParams(text: text));
  }
}
