import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

// saves images to the app's documents dir and returns the local path
class AttachmentService {
  // copy the picked file into persistent app storage, return its new path
  Future<String> saveAttachment({required File file}) async {
    final dir = await getApplicationDocumentsDirectory();
    final ext = p.extension(file.path); // e.g. ".jpg"
    final fileName = '${const Uuid().v4()}$ext';
    final destPath = p.join(dir.path, 'attachments', fileName);

    // make sure the folder exists
    await Directory(p.dirname(destPath)).create(recursive: true);

    final saved = await file.copy(destPath);
    return saved.path;
  }

  // delete a local attachment file
  Future<void> deleteAttachment(String localPath) async {
    try {
      final file = File(localPath);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // ignore if already gone
    }
  }
}
