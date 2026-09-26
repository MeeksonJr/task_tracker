import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/attachment_service.dart';

final attachmentServiceProvider = Provider<AttachmentService>((ref) {
  return AttachmentService();
});

// tracks upload progress: null = idle, 0.0-1.0 = uploading
class AttachmentUploadNotifier extends Notifier<double?> {
  @override
  double? build() => null;

  // save one file locally, return local file path or null on failure
  Future<String?> upload({required String taskId, required File file}) async {
    state = 0.0;
    try {
      final path = await ref
          .read(attachmentServiceProvider)
          .saveAttachment(file: file);
      state = null;
      return path;
    } catch (_) {
      state = null;
      return null;
    }
  }

  Future<void> delete(String path) async {
    await ref.read(attachmentServiceProvider).deleteAttachment(path);
  }
}

final attachmentUploadProvider =
    NotifierProvider<AttachmentUploadNotifier, double?>(
  AttachmentUploadNotifier.new,
);
