import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

void main() {
  runApp(const FaceDrawingApp());
}

class FaceDrawingApp extends StatelessWidget {
  const FaceDrawingApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Drawing App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DrawingPage(),
    );
  }
}

class DrawingPage extends StatefulWidget {
  const DrawingPage({Key? key}) : super(key: key);

  @override
  _DrawingPageState createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  final GlobalKey _drawingKey = GlobalKey();
  bool _isLoading = false;
  String? _outputImagePath;

  Future<void> _generateImage() async {
    try {
      setState(() {
        _isLoading = true;
        _outputImagePath = null;
      });

      // Capture the drawn content as an image
      final RenderRepaintBoundary boundary =
          _drawingKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      // Save the image to a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/drawing.png');
      await tempFile.writeAsBytes(byteData!.buffer.asUint8List());

      // Send the image to the API
      final response = await Dio().post(
        'https://d30c-34-142-175-1.ngrok-free.app/process-image',
        data: FormData.fromMap({
          'image': await MultipartFile.fromFile(tempFile.path, filename: 'drawing.png'),
        }),
        options: Options(responseType: ResponseType.bytes),
      );

      // Save the response image
      final outputFile = File('${tempDir.path}/output.jpg');
      await outputFile.writeAsBytes(response.data);

      setState(() {
        _outputImagePath = outputFile.path;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Face Drawing App')),
      body: Column(
        children: [
          Expanded(
            child: RepaintBoundary(
              key: _drawingKey,
              child: Container(
                color: Colors.white,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      final RenderBox renderBox = _drawingKey.currentContext!
                          .findRenderObject() as RenderBox;
                      final offset = renderBox.globalToLocal(details.globalPosition);
                      _points.add(offset);
                    });
                  },
                  onPanEnd: (details) => _points.add(null),
                  child: CustomPaint(
                    painter: _FacePainter(points: _points),
                    child: Container(),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading) const CircularProgressIndicator(),
          if (_outputImagePath != null)
            Image.file(
              File(_outputImagePath!),
              height: 200,
              fit: BoxFit.cover,
            ),
          ElevatedButton(
            onPressed: _isLoading ? null : _generateImage,
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  final List<Offset?> _points = [];
}

class _FacePainter extends CustomPainter {
  final List<Offset?> points;

  _FacePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
