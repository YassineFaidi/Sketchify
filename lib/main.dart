import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const FaceDrawingApp());
}

class FaceDrawingApp extends StatelessWidget {
  const FaceDrawingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sketchify AI',
      theme: ThemeData(
        primaryColor: const Color(0xFFbfd7ed),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFbfd7ed),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFbfd7ed),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      home: const DrawingPage(),
    );
  }
}

class DrawingPage extends StatefulWidget {
  const DrawingPage({super.key});

  @override
  _DrawingPageState createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  final GlobalKey _drawingKey = GlobalKey();
  bool _isLoading = false;
  String? _outputImagePath;
  String _apiUrl = 'https://d30c-34-142-175-1.ngrok-free.app';

  // Drawing state management
  List<List<Offset?>> _undoStack = [];
  List<List<Offset?>> _redoStack = [];
  List<Offset?> _currentLine = [];
  bool _isErasing = false;
  double _strokeWidth = 2.0;
  Color _drawingColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _loadApiUrl();
  }

  Future<void> _loadApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiUrl = prefs.getString('api_url') ?? _apiUrl;
    });
  }

  void _addLine() {
    if (_currentLine.isNotEmpty) {
      setState(() {
        _undoStack.add(List.from(_currentLine));
        _currentLine = [];
        _redoStack.clear();
      });
    }
  }

  void _undo() {
    setState(() {
      if (_undoStack.isNotEmpty) {
        _redoStack.add(_undoStack.removeLast());
      }
    });
  }

  void _redo() {
    setState(() {
      if (_redoStack.isNotEmpty) {
        _undoStack.add(_redoStack.removeLast());
      }
    });
  }

  void _toggleEraser() {
    setState(() {
      if (_currentLine.isNotEmpty) {
        _addLine();
      }
      _isErasing = !_isErasing;
      _drawingColor = _isErasing ? Colors.white : Colors.black;
      _strokeWidth = _isErasing ? 20.0 : 2.0;
    });
  }

  Future<void> _clearTemporaryDirectory() async {
    print("Clearing...");
    final tempDir = await getTemporaryDirectory();
    final directory = Directory(tempDir.path);

    if (directory.existsSync()) {
      final files = directory.listSync();
      for (var file in files) {
        try {
          if (file is File) {
            file.deleteSync();
          }
        } catch (e) {
          debugPrint('Error deleting file: $e');
        }
      }
    }
  }

  Future<void> _generateImage() async {
    try {
      await _clearTemporaryDirectory();
      setState(() {
        _isLoading = true;
        _outputImagePath = null;
      });

      final RenderRepaintBoundary boundary = _drawingKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/drawing.png');
      await tempFile.writeAsBytes(byteData!.buffer.asUint8List());

      final response = await Dio().post(
        '$_apiUrl/process-image',
        data: FormData.fromMap({
          'image': await MultipartFile.fromFile(tempFile.path,
              filename: 'drawing.png'),
        }),
        options: Options(responseType: ResponseType.bytes),
      );

      final outputFile = File('${tempDir.path}/output.jpg');
      await outputFile.writeAsBytes(response.data);

      setState(() {
        _outputImagePath = outputFile.path;
      });
    } catch (e) {
      _showErrorPopup(
          context, 'Failed to connect to the API. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorPopup(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _generateImage();
              },
              child: const Text('Retry'),
            ),
          ],
        );
      },
    );
  }

  void _resetDrawing() async {
    await _clearTemporaryDirectory();
    setState(() {
      _undoStack.clear();
      _redoStack.clear();
      _currentLine.clear();
      _outputImagePath = null;
    });
  }

  void _changeApiUrl() {
    final TextEditingController apiController =
        TextEditingController(text: _apiUrl);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change API URL'),
          content: TextField(
            controller: apiController,
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
              onPressed: () async {
                setState(() {
                  _apiUrl = apiController.text.trim();
                });
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('api_url', _apiUrl);
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
        title: const Text('Sketchify AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            tooltip: 'About',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutPage()),
              );
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
              Container(
                color: const Color(0xFFbfd7ed),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(Icons.undo,
                          color:
                              _undoStack.isEmpty ? Colors.grey : Colors.white),
                      onPressed: _undoStack.isEmpty ? null : _undo,
                      tooltip: 'Undo',
                    ),
                    IconButton(
                      icon: Icon(Icons.redo,
                          color:
                              _redoStack.isEmpty ? Colors.grey : Colors.white),
                      onPressed: _redoStack.isEmpty ? null : _redo,
                      tooltip: 'Redo',
                    ),
                    IconButton(
                      icon: Icon(_isErasing ? Icons.edit : Icons.emergency,
                          color: Colors.white),
                      onPressed: _toggleEraser,
                      tooltip: _isErasing ? 'Draw' : 'Erase',
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: RepaintBoundary(
                  key: _drawingKey,
                  child: Container(
                    color: Colors.white,
                    child: GestureDetector(
                      onPanStart: (details) {
                        _currentLine = [];
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          final RenderBox renderBox =
                              _drawingKey.currentContext!.findRenderObject()
                                  as RenderBox;
                          final offset =
                              renderBox.globalToLocal(details.globalPosition);
                          if (offset.dy >= renderBox.size.height / 16) {
                            _currentLine.add(offset);
                          }
                        });
                      },
                      onPanEnd: (details) {
                        _addLine();
                      },
                      child: CustomPaint(
                        painter: _FacePainter(
                          points: [..._undoStack, _currentLine],
                          strokeWidth: _strokeWidth,
                          drawingColor: _drawingColor,
                        ),
                        child: Container(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading)
            Stack(
              children: [
                Container(
                  color: const Color(0xFFbfd7ed).withOpacity(0.7),
                ),
                const Center(
                  child: CircularProgressIndicator(),
                ),
              ],
            ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _isLoading ? null : _generateImage,
              backgroundColor: const Color(0xFFbfd7ed),
              child: const Icon(Icons.star, size: 30),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: FloatingActionButton(
              onPressed: _resetDrawing,
              backgroundColor: const Color(0xFFbfd7ed),
              child: const Icon(Icons.refresh, size: 30),
            ),
          ),
        ],
      ),
    );
  }
}

class _FacePainter extends CustomPainter {
  final List<List<Offset?>> points;
  final double strokeWidth;
  final Color drawingColor;

  _FacePainter({
    required this.points,
    this.strokeWidth = 2.0,
    this.drawingColor = Colors.black,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = drawingColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    for (final line in points) {
      for (int i = 0; i < line.length - 1; i++) {
        if (line[i] != null && line[i + 1] != null) {
          canvas.drawLine(line[i]!, line[i + 1]!, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About Sketchify AI',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'This app allows users to draw sketches and process them using AI to generate an image.',
            ),
            SizedBox(height: 10),
            Text(
              'Features:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text('• Draw sketches directly on the screen'),
            Text('• Generate images based on your drawing'),
            Text('• Customize the API URL for image processing'),
            SizedBox(height: 10),
            Text(
              'Developed by Dotware@117.',
            ),
          ],
        ),
      ),
    );
  }
}
