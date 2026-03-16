import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

void main() {
  runApp(const SmartLensApp());
}

class SmartLensApp extends StatelessWidget {
  const SmartLensApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Lens',
      // Enabling the brand new Material 3 design system!
      theme: ThemeData(
        useMaterial3: true, 
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Modern Indigo
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Premium off-white
      ),
      home: const CameraScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  Uint8List? _imageBytes;
  String _resultText = "Upload an image to identify the object.";
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndAnalyzeImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _isLoading = true;
        _resultText = "AI is analyzing... Please wait.";
      });

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:3000/analyze-image'),
      );

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: image.name,
      ));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        var aiData = jsonResponse['ai_analysis'];
        setState(() {
          _resultText = "🎯 Detected: ${aiData['detected_object'].toUpperCase()}\n"
                        "📈 Confidence: ${aiData['confidence_percentage']}%\n"
                        "💾 DB Record: #${jsonResponse['database_record_id']}";
          _isLoading = false;
        });
      } else {
        setState(() {
          _resultText = "Error: Something went wrong on the server.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _resultText = "Failed to connect. Is your Node.js server running?";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Smart Lens AI', 
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Modern Floating Image Card
                  Container(
                    height: 320,
                    width: 320,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        )
                      ]
                    ),
                    child: _imageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.view_in_ar_rounded, size: 80, color: Colors.indigo.shade200),
                              const SizedBox(height: 16),
                              Text("Awaiting Image", style: TextStyle(color: Colors.indigo.shade300, fontWeight: FontWeight.w600)),
                            ],
                          ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Sleek Result Text
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.indigo.shade50),
                    ),
                    child: Text(
                      _resultText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.w600, 
                        height: 1.6,
                        color: Colors.blueGrey.shade800
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Premium Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
                            onPressed: _pickAndAnalyzeImage,
                            icon: const Icon(Icons.auto_awesome, color: Colors.white),
                            label: const Text(
                              "Analyze Image", 
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1), // Indigo
                              elevation: 10,
                              shadowColor: const Color(0xFF6366F1).withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)
                              )
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}