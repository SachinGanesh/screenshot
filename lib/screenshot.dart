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
  late GlobalKey _containerKey;
  ScreenshotController() {
    _containerKey = GlobalKey();
  }

  /// Captures image and saves to given path
  Future<String?> captureAndSave(
    String directory, {
    String? fileName,
    double? pixelRatio,
    Duration delay = const Duration(milliseconds: 20),
  }) async {
    Uint8List? content = await capture(
      pixelRatio: pixelRatio,
      delay: delay,
    );
    PlatformFileManager fileManager = PlatformFileManager();

    return fileManager.saveFile(content!, directory, name: fileName);
  }

  Future<Uint8List?> capture({
    double? pixelRatio,
    Duration delay = const Duration(milliseconds: 20),
  }) {
    //Delay is required. See Issue https://github.com/flutter/flutter/issues/22308
    return new Future.delayed(delay, () async {
      try {
        ui.Image image = await captureAsUiImage(
          delay: Duration.zero,
          pixelRatio: pixelRatio,
        );
        ByteData? byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        Uint8List? pngBytes = byteData?.buffer.asUint8List();

        return pngBytes;
      } catch (Exception) {
        throw (Exception);
      }
    });
  }

  Future<ui.Image> captureAsUiImage(
      {double? pixelRatio: 1,
      Duration delay: const Duration(milliseconds: 20)}) {
    //Delay is required. See Issue https://github.com/flutter/flutter/issues/22308
    return new Future.delayed(delay, () async {
      try {
        RenderRepaintBoundary boundary = this
            ._containerKey
            .currentContext
            ?.findRenderObject() as RenderRepaintBoundary;
        BuildContext? context = _containerKey.currentContext;
        if (pixelRatio == null) {
          if (context != null)
            pixelRatio = pixelRatio ?? MediaQuery.of(context).devicePixelRatio;
        }
        ui.Image image = await boundary.toImage(pixelRatio: pixelRatio ?? 1);
        return image;
      } catch (Exception) {
        throw (Exception);
      }
    });
  }

  Future<Uint8List> captureFromWidget(Widget widget,
      {Duration delay: const Duration(milliseconds: 20)}) async {
    final RenderRepaintBoundary repaintBoundary = RenderRepaintBoundary();

    Size logicalSize = ui.window.physicalSize / ui.window.devicePixelRatio;
    Size imageSize = ui.window.physicalSize;

    assert(logicalSize.aspectRatio == imageSize.aspectRatio);

    final RenderView renderView = RenderView(
      window: ui.window,
      child: RenderPositionedBox(
          alignment: Alignment.center, child: repaintBoundary),
      configuration: ViewConfiguration(
        size: logicalSize,
        devicePixelRatio: 1.0,
      ),
    );

    final PipelineOwner pipelineOwner = PipelineOwner();
    final BuildOwner buildOwner = BuildOwner(focusManager: FocusManager());

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final RenderObjectToWidgetElement<RenderBox> rootElement =
        RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: widget,
      ),
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);

    await Future.delayed(delay);

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();

    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final ui.Image image = await repaintBoundary.toImage(
        pixelRatio: imageSize.width / logicalSize.width);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }
}

class Screenshot<T> extends StatefulWidget {
  final Widget? child;
  final ScreenshotController controller;
  const Screenshot({
    Key? key,
    required this.child,
    required this.controller,
  }) : super(key: key);

  @override
  State<Screenshot> createState() {
    return new ScreenshotState();
  }
}

class ScreenshotState extends State<Screenshot> with TickerProviderStateMixin {
  late ScreenshotController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _controller._containerKey,
      child: widget.child,
    );
  }
}
