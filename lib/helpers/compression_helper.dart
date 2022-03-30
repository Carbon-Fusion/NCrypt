import 'package:archive/archive_io.dart';

class CompressionHelper {
  Future<void> dirToZip(Map<String, dynamic> params) async {
    ZipFileEncoder().zipDirectory(params['encryptionTempDirectory']!,
        filename: params['encryptedFilePath']!);
  }

  Future<Archive> zipView(String path) async {
    return ZipDecoder().decodeBuffer(InputFileStream(path));
  }

  Future<void> archiveToDir(Map<String, dynamic> params) async {
    extractArchiveToDisk(params['archive'], params['outputPath']);
  }
}
