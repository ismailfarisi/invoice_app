import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FileUtils {
  static Future<void> shareFile(
    Uint8List bytes,
    String fileName, {
    String? text,
  }) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path)], text: text);
  }

  static Future<String> saveLogoImage(String sourcePath) async {
    final applicationDirectory = await getApplicationDocumentsDirectory();
    final fileName = 'logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final permanentPath = '${applicationDirectory.path}/$fileName';

    final sourceFile = File(sourcePath);
    if (await sourceFile.exists()) {
      await sourceFile.copy(permanentPath);
    }

    return permanentPath;
  }

  static File? getFileIfExists(String? path) {
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    return file.existsSync() ? file : null;
  }
}
