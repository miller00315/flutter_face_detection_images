import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyHomePage());
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late ImagePicker imagePicker;
  late FaceDetector faceDetector;
  File? _image;
  String result = '';
  dynamic image;
  List<Face> faces = [];
  @override
  void initState() {
    super.initState();
    final options = FaceDetectorOptions(
      enableLandmarks: true,
      enableClassification: true,
      enableContours: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.fast,
    );

    faceDetector = FaceDetector(options: options);

    imagePicker = ImagePicker();
    //TODO initialize detector
  }

  @override
  void dispose() async {
    await faceDetector.close();
    super.dispose();
  }

  //TODO capture image using camera
  _imgFromCamera() async {
    XFile? pickedFile = await imagePicker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      _image = File(pickedFile.path);
      doFaceDetection();
    }
  }

  //TODO choose image using gallery
  _imgFromGallery() async {
    XFile? pickedFile =
        await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _image = File(pickedFile.path);
      doFaceDetection();
    }
  }

  //TODO face detection code here
  doFaceDetection() async {
    result = "";

    if (_image != null) {
      final InputImage inputImage = InputImage.fromFile(_image!);

      faces = await faceDetector.processImage(inputImage);

      for (Face face in faces) {
        if (face.smilingProbability != null) {
          if (face.smilingProbability! > 0.5) {
            result += "Smiling";
          } else {
            result += "Serious";
          }
        }
      }
    }

    setState(() {
      _image;
      result;
    });

    drawRectangleAroundFaces();
  }

  drawRectangleAroundFaces() async {
    image = await _image?.readAsBytes();

    image = await decodeImageFromList(image);

    setState(() {
      image;
      result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage('images/bg.jpg'), fit: BoxFit.cover),
        ),
        child: Column(
          children: [
            const SizedBox(
              width: 100,
            ),
            Container(
              margin: const EdgeInsets.only(top: 100),
              child: Stack(children: <Widget>[
                Center(
                  child: ElevatedButton(
                    onPressed: _imgFromGallery,
                    onLongPress: _imgFromCamera,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent),
                    child: Container(
                      width: 335,
                      height: 495,
                      margin: const EdgeInsets.only(
                        top: 45,
                      ),
                      child: image != null
                          ? Center(
                              child: FittedBox(
                                child: SizedBox(
                                  width: image.width.toDouble(),
                                  height: image.width.toDouble(),
                                  child: CustomPaint(
                                    painter: FacePainter(
                                        facesList: faces, imageFile: image),
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.black,
                              width: 340,
                              height: 330,
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ]),
            ),
            Container(
              margin: const EdgeInsets.only(top: 20),
              child: Text(
                result,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 36, color: Colors.red),
              ),
            ),
          ],
        ),
      )),
    );
  }
}

class FacePainter extends CustomPainter {
  List<Face> facesList;
  dynamic imageFile;
  FacePainter({required this.facesList, @required this.imageFile});

  @override
  void paint(Canvas canvas, Size size) {
    if (imageFile != null) {
      canvas.drawImage(imageFile, Offset.zero, Paint());
    }
    Paint p = Paint();
    p.color = Colors.red;
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 1;

    for (Face rectangle in facesList) {
      canvas.drawRect(rectangle.boundingBox, p);
    }

    Paint p2 = Paint();
    p2.color = Colors.green;
    p2.style = PaintingStyle.stroke;
    p2.strokeWidth = 1;

    Paint p3 = Paint();
    p3.color = Colors.yellow;
    p3.style = PaintingStyle.stroke;
    p3.strokeWidth = 1;

    for (final Face face in facesList) {
      Map<FaceContourType, FaceContour?> con = face.contours;
      List<Offset> offsetPoints = <Offset>[];
      con.forEach((key, value) {
        if (value != null) {
          List<Point<int>>? points = value.points;
          for (Point p in points) {
            Offset offset = Offset(p.x.toDouble(), p.y.toDouble());
            offsetPoints.add(offset);
          }
          canvas.drawPoints(PointMode.points, offsetPoints, p2);
        }
      });

      //If landmark detection was enabled with FaceDetectorOptions (mouth, ears,
      // eyes, cheeks, and nose available):
      final FaceLandmark? leftEar = face.landmarks[FaceLandmarkType.leftEar];

      if (leftEar != null) {
        final Point<int> leftEarPos = leftEar.position;
        canvas.drawRect(
            Rect.fromLTWH(leftEarPos.x.toDouble() - 5,
                leftEarPos.y.toDouble() - 5, 10, 10),
            p3);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
