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
      debugShowCheckedModeBanner: false,
      title: 'Face Drawing App',
      theme: ThemeData(
        primaryColor: Color(0xFFbfd7ed),  // Updated to #bfd7ed
        scaffoldBackgroundColor: Colors.white,  // White background color
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFFbfd7ed),  // Updated AppBar color
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFbfd7ed),  // Matching button color
        ),
        iconTheme: IconThemeData(
          color: Colors.white,  // White icons to match theme
        ),
      ),
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
  String _apiUrl = 'https://d30c-34-142-175-1.ngrok-free.app';
  final List<Offset?> _points = [];

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
        '$_apiUrl/process-image',
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

  void _resetDrawing() {
    setState(() {
      _points.clear();
      _outputImagePath = null;  // Reset the output image path as well
    });
  }

  void _changeApiUrl() {
    final TextEditingController _apiController = TextEditingController(text: _apiUrl);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change API URL'),
          content: TextField(
            controller: _apiController,
            decoration: const InputDecoration(labelText: 'API URL'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _apiUrl = _apiController.text.trim();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Drawing App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            tooltip: 'About',
            onPressed: () {
              // Open About page or show information
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Change API URL',
            onPressed: _changeApiUrl,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Top half - Generated image
              Expanded(
                flex: 1,
                child: _outputImagePath != null
                    ? Image.file(
                        File(_outputImagePath!),
                        height: double.infinity,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : const Center(
                        child: Text('Generated image will appear here'),
                      ),
              ),
              // Bottom half - Drawing area
              Expanded(
                flex: 1,
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
            ],
          ),
          // Centered Loading State with Overlay
          if (_isLoading)
            Stack(
              children: [
                // Semi-transparent overlay with same color as the app bar
                Container(
                  color: Color(0xFFbfd7ed).withOpacity(0.7), // Same color as app bar with transparency
                ),
                // Centered Loading Indicator
                const Center(
                  child: CircularProgressIndicator(),
                ),
              ],
            ),
          // Positioned Generate Button with Magic Icon (Updated)
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _isLoading ? null : _generateImage,
              backgroundColor: const Color(0xFFbfd7ed),  // Matching button color
              child: const Icon(Icons.star, size: 30), // Magic-like icon (Star)
            ),
          ),
          // Positioned Reset Button at the bottom left
          Positioned(
            bottom: 20,
            left: 20,
            child: FloatingActionButton(
              onPressed: _resetDrawing,
              backgroundColor: const Color(0xFFbfd7ed),  // Matching button color
              child: const Icon(Icons.refresh, size: 30),  // Reset icon
            ),
          ),
        ],
      ),
    );
  }
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
