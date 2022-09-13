import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot/screenshot.dart';

part 'screenshot_service_test_constants.dart'; // contains the bytes of the captured image and the app widget

void main() {
  group('captureFromWidget', () {
    testWidgets('Should return the correct Uint8List when successful.',
        (WidgetTester tester) async {
      TestWidgetsFlutterBinding.ensureInitialized();

      // setup the physical size
      tester.binding.window.physicalSizeTestValue = const Size(1366.0, 673.0);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      // reset the edited settings after the test ends
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);

      await tester.pumpWidget(appWidget);
      await tester.pumpAndSettle();

      // setup the screenshot service
      ScreenshotController screenshotController = ScreenshotController();

      // capture the widget and get the actual result Uint8List
      final List<int>? actualResult = await tester.runAsync<List<int>?>(
          () async => (await screenshotController.captureFromWidget(
                appWidget,
                context: tester.element(find.byType(Text)),
                outputImageSize: const Size(1366, 768),
                window: tester.binding.window,
                delay: const Duration(milliseconds: 1000),
                outputImagePixelRatio: 1.0,
                outputImageByteFormat: ImageByteFormat.png,
              ))
                  .toList());

      // assert the result is correct
      expect(actualResult, expectedResult);
    });
  });
}
