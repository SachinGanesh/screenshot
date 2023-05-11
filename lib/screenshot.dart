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

  ///
  /// Value for [delay] should increase with widget tree size. Prefered value is 1 seconds
  ///
  ///[context] parameter is used to Inherit App Theme and MediaQuery data.
  ///
  ///
  ///
  Future<Uint8List> captureFromWidget(
    Widget widget, {
    Duration delay: const Duration(seconds: 1),
    double? pixelRatio,
    BuildContext? context,
    Size? targetSize,
  }) async {
    ui.Image image = await widgetToUiImage(widget,
        delay: delay,
        pixelRatio: pixelRatio,
        context: context,
        targetSize: targetSize);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    return byteData!.buffer.asUint8List();
  }

  static Future<ui.Image> widgetToUiImage(
    Widget widget, {
    Duration delay: const Duration(seconds: 1),
    double? pixelRatio,
    BuildContext? context,
    Size? targetSize,
  }) async {
    ///
    ///Retry counter
    ///
    int retryCounter = 3;
    bool isDirty = false;

    Widget child = widget;

    if (context != null) {
      ///
      ///Inherit Theme and MediaQuery of app
      ///
      ///
      child = InheritedTheme.captureAll(
        context,
        MediaQuery(
            data: MediaQuery.of(context),
            child: Material(
              child: child,
              color: Colors.transparent,
            )),
      );
    }

    final RenderRepaintBoundary repaintBoundary = RenderRepaintBoundary();

    ui.FlutterView flutterView = View.of(context!);
    Size logicalSize = targetSize ??
        flutterView.physicalSize / flutterView.devicePixelRatio; // Adapted
    Size imageSize = targetSize ?? flutterView.physicalSize; // Adapted

    assert(logicalSize.aspectRatio.toStringAsPrecision(5) ==
        imageSize.aspectRatio
            .toStringAsPrecision(5)); // Adapted (toPrecision was not available)

    final RenderView renderView = RenderView(
      view: flutterView,
      child: RenderPositionedBox(
          alignment: Alignment.center, child: repaintBoundary),
      configuration: ViewConfiguration(
        size: logicalSize,
        devicePixelRatio: pixelRatio ?? 1.0,
      ),
    );

    final PipelineOwner pipelineOwner = PipelineOwner();
    final BuildOwner buildOwner = BuildOwner(
        focusManager: FocusManager(),
        onBuildScheduled: () {
          ///
          ///current render is dirty, mark it.
          ///
          isDirty = true;
        });

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final RenderObjectToWidgetElement<RenderBox> rootElement =
        RenderObjectToWidgetAdapter<RenderBox>(
            container: repaintBoundary,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: child,
            )).attachToRenderTree(
      buildOwner,
    );
    ////
    ///Render Widget
    ///
    ///

    buildOwner.buildScope(
      rootElement,
    );
    buildOwner.finalizeTree();

    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    ui.Image? image;

    do {
      ///
      ///Reset the dirty flag
      ///
      ///
      isDirty = false;

      image = await repaintBoundary.toImage(
          pixelRatio: pixelRatio ?? (imageSize.width / logicalSize.width));

      ///
      ///This delay sholud increas with Widget tree Size
      ///

      await Future.delayed(delay);

      ///
      ///Check does this require rebuild
      ///
      ///
      if (isDirty) {
        ///
        ///Previous capture has been updated, re-render again.
        ///
        ///
        buildOwner.buildScope(
          rootElement,
        );
        buildOwner.finalizeTree();
        pipelineOwner.flushLayout();
        pipelineOwner.flushCompositingBits();
        pipelineOwner.flushPaint();
      }
      retryCounter--;

      ///
      ///retry untill capture is successfull
      ///

    } while (isDirty && retryCounter >= 0);
    try {

      /// Dispose All widgets 
      rootElement.visitChildren((Element element) {
        rootElement.deactivateChild(element);
      });
      buildOwner.finalizeTree();
    } catch (e) {}


    return image; // Adapted to directly return the image and not the Uint8List
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
