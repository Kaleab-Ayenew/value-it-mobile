import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class PickedPhoto {
  PickedPhoto({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}

class PhotoService {
  static Future<List<PickedPhoto>> pickPhotos() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );
      if (result == null) return [];
      return result.files
          .where((f) => f.bytes != null)
          .map((f) => PickedPhoto(bytes: f.bytes!, filename: f.name))
          .toList();
    }
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    final photos = <PickedPhoto>[];
    for (final img in images) {
      final bytes = await img.readAsBytes();
      photos.add(PickedPhoto(bytes: bytes, filename: img.name));
    }
    return photos;
  }
}
