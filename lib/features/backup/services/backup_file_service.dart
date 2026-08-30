import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupFileService {
  Future<String?> save(Uint8List bytes, String fileName) async {
    final path = await FilePicker.saveFile(
      dialogTitle: 'Lưu bản sao lưu',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (path != null) {
      await File(path).writeAsBytes(bytes, flush: true);
      return path;
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Bản sao lưu Birthday Reminder',
      ),
    );
    return null;
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
