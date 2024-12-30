import 'dart:io'; // Provides file manipulation capabilities
import 'dart:typed_data'; // Supports working with byte data
import 'dart:ui' as ui; // Used for custom rendering and image manipulation
import 'package:flutter/material.dart'; // Core Flutter package for UI development
import 'package:flutter/rendering.dart'; // Provides rendering objects
import 'package:path_provider/path_provider.dart'; // Locates common storage directories
import 'package:dio/dio.dart'; // Handles HTTP requests and responses
import 'package:shared_preferences/shared_preferences.dart'; // Stores key-value pairs locally

void main() {
  runApp(const FaceDrawingApp()); // Entry point for the app
}

// Main application widget
class FaceDrawingApp extends StatelessWidget {
  const FaceDrawingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Hides the debug banner
      title: 'Sketchify AI', // App title
      theme: ThemeData(
        primaryColor: const Color(0xFFbfd7ed), // Primary theme color
        scaffoldBackgroundColor: Colors.white, // Background color for Scaffold
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFbfd7ed), // AppBar background color
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFbfd7ed), // FAB background color
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, // Default icon color
        ),
      ),
      home: const DrawingPage(), // Sets the initial page
    );
  }
}

// Stateful widget for the drawing page
class DrawingPage extends StatefulWidget {
  const DrawingPage({super.key});

  @override
  _DrawingPageState createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  final GlobalKey _drawingKey =
      GlobalKey(); // Key for capturing the drawing area
  bool _isLoading = false; // Tracks loading state
  String? _outputImagePath; // Path for the generated image
  String _apiUrl =
      'https://d30c-34-142-175-1.ngrok-free.app'; // Default API URL
  final List<Offset?> _points = []; // List of points for drawing

  @override
  void initState() {
    super.initState();
    _loadApiUrl(); // Load the saved API URL
  }

  // Loads the API URL from SharedPreferences
  Future<void> _loadApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiUrl =
          prefs.getString('api_url') ?? _apiUrl; // Use saved or default URL
    });
  }

  // Generates an image based on the user's drawing
  Future<void> _generateImage() async {
    try {
      setState(() {
        _isLoading = true; // Show loading indicator
        _outputImagePath = null; // Reset output image path
      });

      // Capture the drawn content as an image
      final RenderRepaintBoundary boundary = _drawingKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      // Save the image to a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/drawing.png');
      await tempFile.writeAsBytes(byteData!.buffer.asUint8List());

      // Send the image to the API
      final response = await Dio().post(
        '$_apiUrl/process-image',
        data: FormData.fromMap({
          'image': await MultipartFile.fromFile(tempFile.path,
              filename: 'drawing.png'),
        }),
        options: Options(responseType: ResponseType.bytes),
      );

      // Save the response image
      final outputFile = File('${tempDir.path}/output.jpg');
      await outputFile.writeAsBytes(response.data);

      setState(() {
        _outputImagePath = outputFile.path; // Display the processed image
      });
    } catch (e) {
      _showErrorPopup(
          context, 'Failed to connect to the API. Please try again.');
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  // Displays an error popup with retry and cancel options
  void _showErrorPopup(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'), // Popup title
          content: Text(message), // Error message
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'), // Close the popup
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _generateImage(); // Retry generating the image
              },
              child: const Text('Retry'),
            ),
          ],
        );
      },
    );
  }

  // Clears the drawing and resets the UI
  void _resetDrawing() {
    setState(() {
      _points.clear(); // Clear drawn points
      _outputImagePath = null; // Reset output image
    });
  }

  // Changes the API URL
  void _changeApiUrl() {
    final TextEditingController apiController =
        TextEditingController(text: _apiUrl);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change API URL'), // Popup title
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
                  _apiUrl = apiController.text.trim(); // Save new URL
                });
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('api_url', _apiUrl); // Persist new URL
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
        title: const Text('Sketchify AI'), // AppBar title
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            tooltip: 'About',
            onPressed: () {
              // Navigate to the About page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Change API URL',
            onPressed: _changeApiUrl, // Open API URL settings
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
                        File(_outputImagePath!), // Display generated image
                        height: double.infinity,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : const Center(
                        child: Text('Generated image will appear here'),
                      ),
              ),
              Expanded(
                flex: 1,
                child: RepaintBoundary(
                  key: _drawingKey, // Marks the drawing area for rendering
                  child: Container(
                    color: Colors.white,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          final RenderBox renderBox =
                              _drawingKey.currentContext!.findRenderObject()
                                  as RenderBox;
                          final offset =
                              renderBox.globalToLocal(details.globalPosition);
                          if (offset.dy >= renderBox.size.height / 16) {
                            _points.add(offset); // Add new point to the drawing
                          }
                        });
                      },
                      onPanEnd: (details) =>
                          _points.add(null), // Mark end of line
                      child: CustomPaint(
                        painter: _FacePainter(
                            points: _points), // Custom drawing logic
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
                  color: const Color(0xFFbfd7ed)
                      .withOpacity(0.7), // Loading overlay
                ),
                const Center(
                  child: CircularProgressIndicator(), // Loading indicator
                ),
              ],
            ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _isLoading ? null : _generateImage, // Generate image
              backgroundColor: const Color(0xFFbfd7ed),
              child: const Icon(Icons.star, size: 30),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: FloatingActionButton(
              onPressed: _resetDrawing, // Clear the drawing
              backgroundColor: const Color(0xFFbfd7ed),
              child: const Icon(Icons.refresh, size: 30),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for rendering the drawing
class _FacePainter extends CustomPainter {
  final List<Offset?> points; // List of points to draw

  _FacePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black // Drawing color
      ..strokeWidth = 2.0 // Line thickness
      ..strokeCap = StrokeCap.round; // Round line edges

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(
            points[i]!, points[i + 1]!, paint); // Draw line between points
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      true; // Always repaint
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
              'Developed by 117.',
            ),
          ],
        ),
      ),
    );
  }
}
