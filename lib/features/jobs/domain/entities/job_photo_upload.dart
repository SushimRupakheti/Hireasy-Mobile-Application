import 'dart:typed_data';

class JobPhotoUpload {
  final String fileName;
  final Uint8List bytes;

  const JobPhotoUpload({required this.fileName, required this.bytes});
}
