import 'package:archive/archive_io.dart';

class CompressionHelper {
  Future<void> dirToZip(Map<String, dynamic> params) async {
    ZipFileEncoder().zipDirectory(params['encryptionTempDirectory']!,
        filename: params['encryptedFilePath']!);
  }
}
