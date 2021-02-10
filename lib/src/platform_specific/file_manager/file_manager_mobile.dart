// import 'dart:io';
// import 'dart:typed_data';

// import 'file_manager.dart';

// PlatformFileManager getFilePicker() => PlatformFilePickerMobile();

// class PlatformFilePickerMobile with PlatformFileManager {
//   @override
//   Future<String> saveFile(Uint8List fileContent, String path, {String name}) async{
//    name = name??"${DateTime.now().toIso8601String()}.png";
//    File file = File("$path/$name");
//     file.writeAsBytesSync(fileContent);
//     return file.path;
//   }

// }
