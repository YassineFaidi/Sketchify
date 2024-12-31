import 'dart:io';
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

class DrawingAction {
  final bool isErase;
  final List<Offset?> points;
  final List<List<Offset?>> erasedPoints;

  DrawingAction({
    required this.isErase,
    required this.points,
    this.erasedPoints = const [],
  });
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

  final List<DrawingAction> _undoStack = [];
  final List<DrawingAction> _redoStack = [];
  List<Offset?> _currentLine = [];
  bool _isErasing = false;
  final double _strokeWidth = 2.0;
  final double _eraserSize = 20.0;
  Offset? _currentEraserPosition;
  List<List<Offset?>> _activePoints = [];

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
        _undoStack.add(DrawingAction(
          isErase: false,
          points: List.from(_currentLine),
        ));
        _activePoints.add(List.from(_currentLine));
        _currentLine = [];
        _redoStack.clear();
      });
    }
  }

  void _addEraseAction(List<List<Offset?>> erasedPoints) {
    if (erasedPoints.isNotEmpty) {
      setState(() {
        _undoStack.add(DrawingAction(
          isErase: true,
          points: [],
          erasedPoints: erasedPoints,
        ));
        _redoStack.clear();
      });
    }
  }

  void _undo() {
    setState(() {
      if (_undoStack.isNotEmpty) {
        final action = _undoStack.removeLast();
        _redoStack.add(action);

        if (action.isErase) {
          _activePoints.addAll(action.erasedPoints);
        } else {
          _activePoints.removeLast();
        }
      }
    });
  }

  void _redo() {
    setState(() {
      if (_redoStack.isNotEmpty) {
        final action = _redoStack.removeLast();
        _undoStack.add(action);

        if (action.isErase) {
          for (var points in action.erasedPoints) {
            _activePoints.remove(points);
          }
        } else {
          _activePoints.add(action.points);
        }
      }
    });
  }

  void _toggleEraser() {
    setState(() {
      _isErasing = !_isErasing;
      _currentEraserPosition = null;
    });
  }

  Future<void> _clearTemporaryDirectory() async {
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

      final boundary = _drawingKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/drawing.png');
      await tempFile.writeAsBytes(byteData!.buffer.asUint8List());

      final response = await Dio().post(
        '$_apiUrl/process-image',
        data: FormData.fromMap({
          'image': await MultipartFile.fromFile(tempFile.path, filename: 'drawing.png'),
        }),
        options: Options(responseType: ResponseType.bytes),
      );

      final outputFile = File('${tempDir.path}/output.jpg');
      await outputFile.writeAsBytes(response.data);

      setState(() {
        _outputImagePath = outputFile.path;
      });
    } catch (e) {
      _showErrorPopup(context, 'Failed to connect to the API. Please try again.');
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
              onPressed: () => Navigator.of(context).pop(),
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
      _activePoints.clear();
      _outputImagePath = null;
      _currentEraserPosition = null;
    });
  }

  void _changeApiUrl() {
    final apiController = TextEditingController(text: _apiUrl);
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
              onPressed: () => Navigator.of(context).pop(),
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
                          color: _undoStack.isEmpty ? Colors.grey : Colors.white),
                      onPressed: _undoStack.isEmpty ? null : _undo,
                      tooltip: 'Undo',
                    ),
                    IconButton(
                      icon: Icon(Icons.redo,
                          color: _redoStack.isEmpty ? Colors.grey : Colors.white),
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
                        if (_isErasing) {
                          final RenderBox renderBox =
                              _drawingKey.currentContext!.findRenderObject() as RenderBox;
                          _currentEraserPosition = renderBox.globalToLocal(details.globalPosition);
                        }
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          final RenderBox renderBox =
                              _drawingKey.currentContext!.findRenderObject() as RenderBox;
                          final offset = renderBox.globalToLocal(details.globalPosition);
                          
                          if (offset.dy >= renderBox.size.height / 16) {
                            if (_isErasing) {
                              _currentEraserPosition = offset;
                              List<List<Offset?>> erasedPoints = [];
                              _activePoints = _activePoints.map((points) {
                                var originalPoints = List<Offset?>.from(points);
                                points.removeWhere((point) => point != null &&
                                    (point - offset).distance <= _eraserSize / 2);
                                if (points.length != originalPoints.length) {
                                  erasedPoints.add(originalPoints);
                                }
                                return points;
                              }).toList();
                              if (erasedPoints.isNotEmpty) {
                                _addEraseAction(erasedPoints);
                              }
                            } else {
                              _currentLine.add(offset);
                            }
                          }
                        });
                      },
                      onPanEnd: (details) {
                        if (!_isErasing) {
                          _addLine();
                        }
                        _currentEraserPosition = null;
                      },
                      child: CustomPaint(
                        painter: _FacePainter(
                          points: [..._activePoints, if (!_isErasing) _currentLine],
                          strokeWidth: _strokeWidth,
                          drawingColor: Colors.black,
                          isErasing: _isErasing,
                          eraserPosition: _currentEraserPosition,
                          eraserSize: _eraserSize,
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
            Container(
              color: const Color(0xFFbfd7ed).withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
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
              child: const Icon(Icons.delete, size: 30),
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
  final bool isErasing;
  final Offset? eraserPosition;
  final double eraserSize;

  _FacePainter({
    required this.points,
    required this.strokeWidth,
    required this.drawingColor,
    this.isErasing = false,
    this.eraserPosition,
    this.eraserSize = 20.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = drawingColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    for (var line in points) {
      if (line.isNotEmpty) {
        for (var i = 0; i < line.length - 1; i++) {
          if (line[i] != null && line[i + 1] != null) {
            canvas.drawLine(line[i]!, line[i + 1]!, paint);
          }
        }
      }
    }

    if (isErasing && eraserPosition != null) {
      final eraserPaint = Paint()
        ..color = Colors.grey.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(eraserPosition!, eraserSize / 2, eraserPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sketchify AI',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                )),
            SizedBox(height: 16),
            Text('Version 1.0'),
            SizedBox(height: 16),
            Text(
                'Sketchify AI is an app that turns sketches into beautiful images with the help of AI.'),
          ],
        ),
      ),
    );
  }
}
