 <img src="https://github.com/SachinGanesh/screenshot/raw/master/assets/sc.png" alt="screenshot"/>

A simple package to capture widgets as Images. Now you can also capture the widgets that are not rendered on the screen!

This package wraps your widgets inside [RenderRepaintBoundary](https://docs.flutter.io/flutter/rendering/RenderRepaintBoundary-class.html)

[Source](https://stackoverflow.com/a/51118088)

| | | 
| :---: | :---: |
|<img src="https://github.com/SachinGanesh/screenshot/raw/master/assets/screenshot.gif" alt="screenshot"/>|<p>&nbsp; Capture a `widget`:</p><img src="https://github.com/SachinGanesh/screenshot/raw/master/assets/code1.png" alt="screenshot"/><hr><p>&nbsp;Capture an `invisible widget` (a widget which is not part of the widget tree):</p><img src="https://github.com/SachinGanesh/screenshot/raw/master/assets/code2.png" alt="screenshot"/>|

---
## Getting Started

This handy package can be used to capture any Widget including full screen screenshots & individual widgets like `Text()`.

1) Create Instance of `Screenshot Controller`

```dart
class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  Uint8List _imageFile;

  //Create an instance of ScreenshotController
  ScreenshotController screenshotController = ScreenshotController(); 

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }
  ...
}
```
2) Wrap the widget that you want to capture inside `Screenshot` Widget. Assign the controller to `screenshotController` that you have created earlier

```dart
Screenshot(
    controller: screenshotController,
    child: Text("This text will be captured as image"),
),
```

3) Take the screenshot by calling `capture` method. This will return a `Uint8List`

```dart
screenshotController.capture().then((Uint8List image) {
    //Capture Done
    setState(() {
        _imageFile = image;
    });
}).catchError((onError) {
    print(onError);
});
```
---
## Capturing Widgets that are not in the widget tree

You can capture invisible widgets by calling `captureFromWidget` and passing a widget tree to the function

```dart
screenshotController
      .captureFromWidget(Container(
          padding: const EdgeInsets.all(30.0),
          decoration: BoxDecoration(
            border:
                Border.all(color: Colors.blueAccent, width: 5.0),
            color: Colors.redAccent,
          ),
          child: Text("This is an invisible widget")))
      .then((capturedImage) {
    // Handle captured image
  });

```

---

## Capturing a List Widget

You can capture a long Invisible widgets by using `captureFromLongWidget` function.



```dart
var randomItemCount = Random().nextInt(100);

///
/// Step 1: Create Long widget using Column.
///

var myLongWidget = Builder(builder: (context) {
  return Container(
      padding: const EdgeInsets.all(30.0),
      decoration: BoxDecoration(
        border:
            Border.all(color: Colors.blueAccent, width: 5.0),
        color: Colors.redAccent,
      ),
      ///
      /// Note: Do not use Scrolling widget, instead place your children in Column. 
      ///  
      /// Do not use widgets like 'Expanded','Flexible',or 'Spacer'
      ///
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < randomItemCount; i++)
            Text("Tile Index $i"),
        ],
      ));
});

///
/// Step 2: 
///    Use `captureFromLongWidget` function for taking screenshot.
///
screenshotController
      .captureFromLongWidget(
          InheritedTheme.captureAll(
            context, 
            Material(
              child: myLongWidget,
            ),
          ),
          delay: Duration(milliseconds: 100),
          context: context,


          ///
          /// Additionally you can define constraint for your image.
          ///
          /// constraints: BoxConstraints(
          ///   maxHeight: 1000,
          ///   maxWidth: 1000,
          /// )
      )
      .then((capturedImage) {
    // Handle captured image
  });

```


---
## Saving images to Specific Location
For this you can use `captureAndSave` method by passing directory location. By default, the captured image will be saved to Application Directory. Custom paths can be set using **path parameter**. Refer [path_provider](https://pub.dartlang.org/packages/path_provider)

### Note

>Method `captureAndSave` is not supported for `web`. 


```dart
final directory = (await getApplicationDocumentsDirectory ()).path; //from path_provide package
String fileName = DateTime.now().microsecondsSinceEpoch;
path = '$directory';

screenshotController.captureAndSave(
    path //set path where screenshot will be saved
    fileName:fileName 
);
```
---
## Saving images to Gallery
If you want to save captured image to Gallery, Please use https://github.com/hui-z/image_gallery_saver
Example app uses the same to save screenshots to gallery.

---

## Sharing Captured Images 

```dart
await _screenshotController.capture(delay: const Duration(milliseconds: 10)).then((Uint8List image) async {
      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final imagePath = await File('${directory.path}/image.png').create();
        await imagePath.writeAsBytes(image);

        /// Share Plugin
        await Share.shareFiles([imagePath.path]);
      }
    });
```

---
## Note:
Captured image may look pixelated. You can overcome this issue by setting value for **pixelRatio** 

>The pixelRatio describes the scale between the logical pixels and the size of the output image. It is independent of the window.devicePixelRatio for the device, so specifying 1.0 (the default) will give you a 1:1 mapping between logical pixels and the output pixels in the image.


```dart
double pixelRatio = MediaQuery.of(context).devicePixelRatio;

screenshotController.capture(
    pixelRatio: pixelRatio //1.5
)
```
---
Sometimes rastergraphics like images may not be captured by the plugin with default configurations. The issue is discussed [here](https://api.flutter.dev/flutter/flutter_driver/FlutterDriver/screenshot.html). 

```
...screenshot is taken before the GPU thread is done rasterizing the frame 
so the screenshot of the previous frame is taken, which is wrong.
```

The solution is to add a small delay before capturing. 

```dart
screenshotController.capture(delay: Duration(milliseconds: 10))
```
---
## Known Issues
- **`Platform Views are not supported. (Example: Google Maps, Camera etc)`[issue](https://github.com/flutter/flutter/issues/83856)**
---