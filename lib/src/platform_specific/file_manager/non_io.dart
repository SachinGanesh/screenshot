// import 'dart:html';
import 'dart:typed_data';

import 'file_manager.dart';

PlatformFileManager getFileManager() => PlatformFileManagerWeb();

class PlatformFileManagerWeb implements PlatformFileManager {
  @override
  Future<String> saveFile(Uint8List fileContent, String path,
      {String? name}) async {
    throw UnsupportedError("File cannot be saved in current platform");
    // name = name ?? "${DateTime.now().microsecondsSinceEpoch}.png";
    // File file = await File("$path/$name").create(recursive: true);
    // file.writeAsBytesSync(fileContent);
    // return file.path;
  }
}
