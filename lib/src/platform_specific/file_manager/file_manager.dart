import 'dart:typed_data';

// import 'file_manager_mobile.dart';
import 'file_manager_stub.dart'
    if (dart.library.io) "file_manager_io.dart"
    if (dart.library.html) "non_io.dart";

abstract class PlatformFileManager {
  factory PlatformFileManager() => getFileManager();
  Future<String> saveFile(Uint8List fileContent, String path, {String? name});
}
