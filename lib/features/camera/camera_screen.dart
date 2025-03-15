import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';



class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({super.key, required this.cameras});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameraController = CameraController(
      widget.cameras[0], // Use the first camera (back camera)
      ResolutionPreset.high,
    );
    await _cameraController!.initialize();
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    final image = await _cameraController!.takePicture();
    final objectName = await recognizeObject(File(image.path));
    await saveObjectDetails(objectName);
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('Object saved: $objectName')),
    // );
  }

  Future<String> recognizeObject(File imageFile) async {
    final uri = Uri.parse('https://api.openai.com/v1/images/classify');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${Platform.environment['API_KEY']}'
      ..files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ));

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      return responseData; // Process the response (e.g., extract object name)
    } else {
      throw Exception('Failed to recognize object');
    }
  }

  Future<void> saveObjectDetails(String objectName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(join(directory.path, 'objects.txt'));
    await file.writeAsString('$objectName\n', mode: FileMode.append);
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      body: CameraPreview(_cameraController!),
      floatingActionButton: FloatingActionButton(
        onPressed: _captureImage,
        child: Icon(Icons.camera),
      ),
    );
  }
}