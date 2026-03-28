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
      title: 'Smart Lens AI',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark, // Professional Dark Mode
        colorSchemeSeed: Colors.blueAccent,
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
  String _objectName = "";
  double _confidence = 0.0;
  bool _isLoading = false;
  bool _isAnalyzed = false;

  final ImagePicker _picker = ImagePicker();

  // Step 1: JUST pick the image
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _isAnalyzed = false; // Reset analysis state for new image
      _objectName = "";
      _confidence = 0.0;
    });
  }

  // Step 2: Explicitly trigger AI analysis
  Future<void> _analyzeImage() async {
    if (_imageBytes == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:3000/analyze-image'),
      );

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        _imageBytes!,
        filename: "upload.jpg",
      ));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        var aiData = jsonResponse['ai_analysis'];
        setState(() {
          _objectName = aiData['detected_object'].toString().toUpperCase();
          _confidence = (aiData['confidence_percentage'] as num).toDouble();
          _isAnalyzed = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Analysis failed. Check server connection.")),
      );
      setState(() => _isLoading = false);
    }
  }

  void _reset() {
    setState(() {
      _imageBytes = null;
      _isAnalyzed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep Slate/Navy background
      appBar: AppBar(
        title: const Text("SMART LENS ENGINE", style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // UPLOAD / PREVIEW SECTION
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                ),
                child: _imageBytes == null
                    ? _buildUploadPlaceholder()
                    : _buildImagePreview(),
              ),
            ),
            
            const SizedBox(height: 24),

            // RESULTS SECTION (Only shows after analysis)
            if (_isAnalyzed) _buildResultPanel(),

            const SizedBox(height: 24),

            // ACTION BUTTON
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, size: 64, color: Colors.blueAccent.shade100),
          const SizedBox(height: 16),
          const Text("SELECT SOURCE IMAGE", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const Text("JPG, PNG up to 10MB", style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
        ),
        PositionAtTopRight(
          child: IconButton(
            icon: const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.close, color: Colors.white, size: 16)),
            onPressed: _reset,
          ),
        ),
      ],
    );
  }

  Widget _buildResultPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("DETECTION RESULT", style: TextStyle(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
              Text("${_confidence.toStringAsFixed(1)}%", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(_objectName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          // Professional Confidence Bar
          Stack(
            children: [
              Container(height: 8, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4))),
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                height: 8,
                width: (MediaQuery.of(context).size.width - 88) * (_confidence / 100),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.blueAccent, Colors.cyanAccent.shade400]),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 8)],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    bool canAnalyze = _imageBytes != null && !_isAnalyzed;

    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: canAnalyze && !_isLoading ? _analyzeImage : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.white10,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: canAnalyze ? 8 : 0,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                _isAnalyzed ? "ANALYSIS COMPLETE" : "RUN AI ANALYSIS",
                style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1),
              ),
      ),
    );
  }
}

class PositionAtTopRight extends StatelessWidget {
  final Widget child;
  const PositionAtTopRight({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Positioned(top: 8, right: 8, child: child);
  }
}