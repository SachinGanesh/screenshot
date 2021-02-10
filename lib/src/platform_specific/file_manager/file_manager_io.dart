import 'dart:io';
import 'dart:typed_data';

import 'file_manager.dart';

PlatformFileManager getFileManager() => PlatformFilePickerWindows();

class PlatformFilePickerWindows implements PlatformFileManager {
  @override
  Future<String> saveFile(Uint8List fileContent, String path,
      {String? name}) async {
    name = name ?? "${DateTime.now().microsecondsSinceEpoch}.png";
    File file = await File("$path/$name").create(recursive: true);
    file.writeAsBytesSync(fileContent);
    return file.path;
  }
}
