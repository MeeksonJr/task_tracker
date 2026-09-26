import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

// picks an image from camera or gallery with permission handling
class ImagePickerHelper {
  static final _picker = ImagePicker();

  // show a bottom sheet to choose source, then pick image
  static Future<File?> pickImage(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return null;
    // context guard after the async bottom sheet
    if (!context.mounted) return null;

    // request the right permission based on source
    final granted = await _requestPermission(source, context);
    if (!granted) return null;


    final xFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1920,
    );

    return xFile == null ? null : File(xFile.path);
  }

  // returns true if permission is granted
  static Future<bool> _requestPermission(
      ImageSource source, BuildContext context) async {
    Permission permission;

    if (source == ImageSource.camera) {
      permission = Permission.camera;
    } else {
      // gallery — READ_MEDIA_IMAGES on Android 13+, photos on iOS
      permission = Platform.isAndroid ? Permission.photos : Permission.photos;
    }

    final status = await permission.request();

    if (status.isGranted || status.isLimited) return true;

    if (status.isPermanentlyDenied && context.mounted) {
      // guide user to settings
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Permission Required'),
          content: Text(
            source == ImageSource.camera
                ? 'Camera access is required to take photos. Please enable it in Settings.'
                : 'Gallery access is required to attach photos. Please enable it in Settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                openAppSettings();
                Navigator.of(ctx).pop();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }

    return false;
  }
}
