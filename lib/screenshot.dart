library screenshot;

// import 'dart:io';
import 'dart:async';
import 'dart:typed_data';

// import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'src/platform_specific/file_manager/file_manager.dart';

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
        ui.Image? image = await captureAsUiImage(
          delay: Duration.zero,
          pixelRatio: pixelRatio,
        );
        ByteData? byteData =
            await image?.toByteData(format: ui.ImageByteFormat.png);
        image?.dispose();

        Uint8List? pngBytes = byteData?.buffer.asUint8List();

        return pngBytes;
      } catch (Exception) {
        throw (Exception);
      }
    });
  }

  Future<ui.Image?> captureAsUiImage(
      {double? pixelRatio: 1,
      Duration delay: const Duration(milliseconds: 20)}) {
    //Delay is required. See Issue https://github.com/flutter/flutter/issues/22308
    return new Future.delayed(delay, () async {
      try {
        var findRenderObject =
            this._containerKey.currentContext?.findRenderObject();
        if (findRenderObject == null) {
          return null;
        }
        RenderRepaintBoundary boundary =
            findRenderObject as RenderRepaintBoundary;
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

  /// Captures the given widget and returns the result as a [Uint8List].
  ///
  /// Params:
  ///
  ///- [context] : used to inherit the MediaQueryData and ThemeData of the widget.
  ///- [widget] : the widget to capture.
  ///- [delay] : used between retries of capturing the widget. This value should increase
  /// with the size of the widget tree.
  /// - [window] : the [FlutterWindow] of the application to put the widget in. Usually this is the same [FlutterWindow]
  /// as that of the current running app, which is obtained by the [window] getter from `dart:ui`.
  /// - [outputImageSize] : The size of the output image. If null, the physical size of the window will be used.
  /// - [outputImagePixelRatio] : The pixel ratio of the output image. Defaults to 1.0.
  /// - [outputImageByteFormat] : The output format of the image. Defaults to [ImageByteFormat.png].
  Future<Uint8List> captureFromWidget(
    Widget widget, {
    BuildContext? context,
    Duration? delay,
    ui.FlutterWindow? window,
    Size? outputImageSize,
    double? outputImagePixelRatio,
    ui.ImageByteFormat? outputImageByteFormat,
  }) async {
    int retryCounter = 3;
    bool isDirty = false;

    Widget child = widget;

    if (context != null) {
      // Inherit Theme and MediaQuery of app
      child = InheritedTheme.captureAll(
        context,
        MediaQuery(
            data: MediaQuery.of(context),
            child: Material(color: Colors.transparent, child: child)),
      );
    }

    final RenderRepaintBoundary repaintBoundary = RenderRepaintBoundary();

    final RenderView renderView = RenderView(
      window: window ?? ui.window,
      child: RenderPositionedBox(
          alignment: Alignment.center, child: repaintBoundary),
      configuration: ViewConfiguration(
        size: outputImageSize ?? window?.physicalSize ?? ui.window.physicalSize,
        devicePixelRatio: window?.devicePixelRatio ?? 1.0,
      ),
    );

    final PipelineOwner pipelineOwner = PipelineOwner();
    final BuildOwner buildOwner = BuildOwner(
        focusManager: FocusManager(), onBuildScheduled: () => isDirty = true);

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final RenderObjectToWidgetElement<RenderBox> rootElement =
        RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Directionality(
        textDirection:
            context != null ? Directionality.of(context) : TextDirection.ltr,
        child: child,
      ),
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();
    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    ui.Image image;

    do {
      // Reset the dirty flag
      isDirty = false;

      image = await repaintBoundary.toImage(
          pixelRatio: outputImagePixelRatio ?? 1.0);

      // This delay should increase with widget tree size
      await Future.delayed(delay ?? const Duration(milliseconds: 1000));

      // Check does this require rebuild
      if (isDirty) {
        // Previous capture has been updated, re-render again.
        buildOwner.buildScope(rootElement);
        buildOwner.finalizeTree();
        pipelineOwner.flushLayout();
        pipelineOwner.flushCompositingBits();
        pipelineOwner.flushPaint();
      }

      retryCounter--;
      // Retry until capture is successful
    } while (isDirty && retryCounter >= 0);

    final ByteData? byteData = await image.toByteData(
        format: outputImageByteFormat ?? ui.ImageByteFormat.png);
    image.dispose();

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

extension Ex on double {
  double toPrecision(int n) => double.parse(toStringAsFixed(n));
}
