library screenshot;

// import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'src/platform_specific/file_manager/file_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
// import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;

///
///
///Cannot capture Platformview due to issue https://github.com/flutter/flutter/issues/25306
///
///
class ScreenshotController {
  GlobalKey _containerKey;
  ScreenshotController() {
    _containerKey = GlobalKey();
  }

  /// Captures image and saves to given path
  Future<String> captureAndSave(
    String directory, {
    String fileName,
    double pixelRatio,
    Duration delay: const Duration(milliseconds: 20),
  }) async {
    Uint8List content = await capture(
      pixelRatio: pixelRatio,
      delay: delay,
    );

    PlatformFileManager fileManager = PlatformFileManager();

    return fileManager.saveFile(content, directory, name: fileName);
  }

  Future<Uint8List> capture({
    double pixelRatio,
    Duration delay: const Duration(milliseconds: 20),
  }) {
    //Delay is required. See Issue https://github.com/flutter/flutter/issues/22308
    return new Future.delayed(delay, () async {
      try {
        ui.Image image = await captureAsUiImage(
          delay: Duration.zero,
          pixelRatio: pixelRatio,
        );
        ByteData byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        Uint8List pngBytes = byteData.buffer.asUint8List();

        return pngBytes;
      } catch (Exception) {
        throw (Exception);
      }
    });
  }

  Future<ui.Image> captureAsUiImage(
      {double pixelRatio: 1,
      Duration delay: const Duration(milliseconds: 20)}) {
    //Delay is required. See Issue https://github.com/flutter/flutter/issues/22308
    return new Future.delayed(delay, () async {
      try {
        RenderRepaintBoundary boundary = this
            ._containerKey
            .currentContext
            .findRenderObject() as RenderRepaintBoundary;
        pixelRatio = pixelRatio ??
            MediaQuery.of(_containerKey.currentContext).devicePixelRatio;
        ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
        return image;
      } catch (Exception) {
        throw (Exception);
      }
    });
  }
}

class Screenshot<T> extends StatefulWidget {
  final Widget child;
  final ScreenshotController controller;
  const Screenshot({
    Key key,
    this.child,
    this.controller,
  }) : super(key: key);

  @override
  State<Screenshot> createState() {
    return new ScreenshotState();
  }
}

class ScreenshotState extends State<Screenshot> with TickerProviderStateMixin {
  ScreenshotController _controller;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _controller = ScreenshotController();
    } else
      _controller = widget.controller;
  }

  // @override
  // void didUpdateWidget(Screenshot oldWidget) {
  //   // super.didUpdateWidget(oldWidget);

  //   // if (widget.controller != oldWidget.controller) {
  //   //   widget.controller._containerKey = oldWidget.controller._containerKey;
  //   //   if (oldWidget.controller != null && widget.controller == null)
  //   //     _controller._containerKey = oldWidget.controller._containerKey;
  //   //   if (widget.controller != null) {
  //   //     if (oldWidget.controller == null) {
  //   //       _controller = null;
  //   //     }
  //   //   }
  //   // }
  // }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _controller._containerKey,
      child: widget.child,
    );
  }
}
