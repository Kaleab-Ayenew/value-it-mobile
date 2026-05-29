import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

class PickedPhoto {
  PickedPhoto({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}

class PhotoService {
  static Future<List<PickedPhoto>> pickPhotos({bool compress = true}) async {
    List<PickedPhoto> raw;
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );
      if (result == null) return [];
      raw = result.files
          .where((f) => f.bytes != null)
          .map((f) => PickedPhoto(bytes: f.bytes!, filename: f.name))
          .toList();
    } else {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage();
      raw = <PickedPhoto>[];
      for (final img in images) {
        final bytes = await img.readAsBytes();
        raw.add(PickedPhoto(bytes: bytes, filename: img.name));
      }
    }
    if (!compress || kIsWeb) return raw;
    final out = <PickedPhoto>[];
    for (final p in raw) {
      final compressed = await FlutterImageCompress.compressWithList(
        p.bytes,
        minWidth: 1920,
        minHeight: 1920,
        quality: 72,
      );
      out.add(PickedPhoto(
        bytes: compressed.isNotEmpty ? compressed : p.bytes,
        filename: p.filename,
      ));
    }
    return out;
  }
}
