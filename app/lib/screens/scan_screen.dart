import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../services/api_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final TextEditingController _messageController =
      TextEditingController();

  final TextEditingController _linkController =
      TextEditingController();

  final image_picker.ImagePicker _imagePicker =
      image_picker.ImagePicker();

  final stt.SpeechToText _speech =
      stt.SpeechToText();

  bool _isLoading = false;
  bool _isListening = false;
  bool _speechAvailable = false;

  String _voiceText = '';

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  // ============================================================
  // SPEECH INITIALIZATION
  // ============================================================

  Future<void> _initializeSpeech() async {
    try {
      final available = await _speech.initialize();

      if (!mounted) return;

      setState(() {
        _speechAvailable = available;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _speechAvailable = false;
      });
    }
  }

  // ============================================================
  // TEXT SCANNING
  // ============================================================

  Future<void> _scanMessage() async {
    final message =
        _messageController.text.trim();

    if (message.isEmpty) {
      _showMessage(
        'Please enter a message first.',
      );
      return;
    }

    await _performScan(
      () => ApiService.scanMessage(message),
    );
  }

  // ============================================================
  // IMAGE SCANNING
  // ============================================================

  Future<void> _pickImage() async {
    try {
      final image =
          await _imagePicker.pickImage(
        source: image_picker.ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) {
        return;
      }

      final Uint8List bytes =
          await image.readAsBytes();

      await _performScan(
        () => ApiService.scanImage(
          bytes,
          image.name,
        ),
      );
    } catch (e) {
      _showMessage(
        'Unable to process image: $e',
      );
    }
  }

  // ============================================================
  // CAMERA
  // ============================================================

  Future<void> _takePhoto() async {
    if (_isLoading) return;

    try {
      final Uint8List? imageBytes =
          await Navigator.push<Uint8List>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const _CameraCaptureScreen(),
        ),
      );

      if (imageBytes == null) {
        return;
      }

      await _performScan(
        () => ApiService.scanImage(
          imageBytes,
          'sangyan_camera_photo.jpg',
        ),
      );
    } catch (e) {
      _showMessage(
        'Unable to access camera: $e',
      );
    }
  }

  // ============================================================
  // LINK SCANNING
  // ============================================================

  Future<void> _scanLink() async {
    final url =
        _linkController.text.trim();

    if (url.isEmpty) {
      _showMessage(
        'Please enter a URL.',
      );
      return;
    }

    await _performScan(
      () => ApiService.scanLink(url),
    );
  }

  // ============================================================
  // VOICE SCANNING
  // ============================================================

  Future<void> _toggleVoiceRecording() async {
    if (!_speechAvailable) {
      _showMessage(
        'Speech recognition is not available on this device.',
      );
      return;
    }

    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    _voiceText = '';

    try {
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;

          setState(() {
            _voiceText =
                result.recognizedWords;
          });
        },
      );

      if (!mounted) return;

      setState(() {
        _isListening = true;
      });
    } catch (e) {
      _showMessage(
        'Could not start microphone: $e',
      );
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();

    if (!mounted) return;

    setState(() {
      _isListening = false;
    });

    if (_voiceText.trim().isEmpty) {
      _showMessage(
        'No speech was detected.',
      );
      return;
    }

    await _performScan(
      () => ApiService.scanMessage(
        _voiceText.trim(),
      ),
    );
  }

  // ============================================================
  // COMMON SCAN FUNCTION
  // ============================================================

  Future<void> _performScan(
    Future<Map<String, dynamic>> Function()
        operation,
  ) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response =
          await operation();

      if (!mounted) return;

      Navigator.pushNamed(
        context,
        '/result',
        arguments: {
          'message':
              response['message']?.toString() ??
                  '',

          'analysis':
              response['analysis']?.toString() ??
                  'No analysis available.',

          'isScam':
              _parseBool(
                response['is_scam'],
              ),

          'scamType':
              response['scam_type']?.toString() ??
                  'Unknown',

          'riskLevel':
              response['risk_level']?.toString() ??
                  'Unknown',

          'confidence':
              _parseConfidence(
                response['confidence'],
              ),

          'category':
              response['category']?.toString() ??
                  'Unknown',
        },
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is String) {
      return value.toLowerCase() == 'true';
    }

    return false;
  }

  double _parseConfidence(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }

    return 0.0;
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan with Sangyan',
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Sangyan is analyzing...',
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detect suspicious messages, screenshots, links and voice conversations.',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    _buildImageSection(),

                    const SizedBox(
                      height: 28,
                    ),

                    _buildMessageSection(),

                    const SizedBox(
                      height: 28,
                    ),

                    _buildLinkSection(),

                    const SizedBox(
                      height: 28,
                    ),

                    _buildVoiceSection(),
                  ],
                ),
              ),
      ),
    );
  }

  // ============================================================
  // IMAGE SECTION
  // ============================================================

  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.image_search,
                ),
                SizedBox(width: 10),
                Text(
                  'Scan a Screenshot',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            const Text(
              'Upload a suspicious SMS, WhatsApp message, email or website screenshot.',
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(
                  Icons.upload_file,
                ),
                label: const Text(
                  'Upload Screenshot',
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(
                  Icons.camera_alt,
                ),
                label: const Text(
                  'Take a Photo',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE SECTION
  // ============================================================

  Widget _buildMessageSection() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a Message',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller:
                  _messageController,
              maxLines: 6,
              decoration:
                  const InputDecoration(
                border:
                    OutlineInputBorder(),
                hintText:
                    'Paste a suspicious SMS, WhatsApp message, email, etc.',
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _scanMessage,
                icon: const Icon(
                  Icons.security,
                ),
                label: const Text(
                  'Scan Message',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LINK SECTION
  // ============================================================

  Widget _buildLinkSection() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.link),
                SizedBox(width: 10),
                Text(
                  'Check a Link',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            const Text(
              'Paste a suspicious website link to check for phishing indicators.',
            ),

            const SizedBox(height: 16),

            TextField(
              controller:
                  _linkController,
              keyboardType:
                  TextInputType.url,
              decoration:
                  const InputDecoration(
                border:
                    OutlineInputBorder(),
                hintText:
                    'https://example.com',
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _scanLink,
                icon: const Icon(
                  Icons.search,
                ),
                label: const Text(
                  'Check Link',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // VOICE SECTION
  // ============================================================

  Widget _buildVoiceSection() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.mic),
                SizedBox(width: 10),
                Text(
                  'Voice Scam Detection',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            const Text(
              'Record a suspicious conversation. Sangyan converts the speech to text and analyzes it for scam tactics.',
            ),

            const SizedBox(height: 18),

            if (_voiceText.isNotEmpty)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(14),
                decoration:
                    BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outline,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: Text(
                  _voiceText,
                ),
              ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    _toggleVoiceRecording,
                icon: Icon(
                  _isListening
                      ? Icons.stop
                      : Icons.mic,
                ),
                label: Text(
                  _isListening
                      ? 'Stop & Analyze'
                      : 'Start Voice Scan',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// CAMERA CAPTURE SCREEN
// ==================================================================

class _CameraCaptureScreen
    extends StatefulWidget {
  const _CameraCaptureScreen();

  @override
  State<_CameraCaptureScreen>
      createState() =>
          _CameraCaptureScreenState();
}

class _CameraCaptureScreenState
    extends State<_CameraCaptureScreen> {
  CameraController? _controller;

  bool _isInitializing = true;
  bool _isTakingPhoto = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras =
          await availableCameras();

      if (cameras.isEmpty) {
        throw Exception(
          'No camera was found on this device.',
        );
      }

      CameraDescription selectedCamera =
          cameras.first;

      // Prefer the back camera when available.
      for (final camera in cameras) {
        if (camera.lensDirection ==
            CameraLensDirection.back) {
          selectedCamera = camera;
          break;
        }
      }

      final controller =
          CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      _controller = controller;

      await controller.initialize();

      if (!mounted) return;

      setState(() {
        _isInitializing = false;
      });
    } on CameraException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'CameraAccessDenied':
          message =
              'Camera permission was denied. Please allow camera access in your browser.';
          break;

        case 'CameraAccessDeniedWithoutPrompt':
          message =
              'Camera permission was previously denied. Please enable camera access in browser settings.';
          break;

        default:
          message =
              'Camera error: ${e.description ?? e.code}';
      }

      setState(() {
        _isInitializing = false;
        _errorMessage = message;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _errorMessage =
            'Unable to start camera: $e';
      });
    }
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;

    if (controller == null ||
        !controller.value.isInitialized ||
        _isTakingPhoto) {
      return;
    }

    try {
      setState(() {
        _isTakingPhoto = true;
      });

      final XFile photo =
          await controller.takePicture();

      final Uint8List bytes =
          await photo.readAsBytes();

      if (!mounted) return;

      Navigator.pop(
        context,
        bytes,
      );
    } on CameraException catch (e) {
      if (!mounted) return;

      setState(() {
        _isTakingPhoto = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Could not capture photo: ${e.description ?? e.code}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isTakingPhoto = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Could not capture photo: $e',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Take a Photo',
        ),
      ),

      body: _buildBody(),

      bottomNavigationBar:
          _buildCaptureButton(),
    );
  }

  Widget _buildBody() {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Starting camera...',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                color: Colors.white,
                size: 64,
              ),

              const SizedBox(height: 20),

              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 24),

              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Go Back',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _controller;

    if (controller == null ||
        !controller.value.isInitialized) {
      return const Center(
        child: Text(
          'Camera is not available.',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio:
            controller.value.aspectRatio,
        child: CameraPreview(
          controller,
        ),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return Container(
      color: Colors.black,
      padding:
          const EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          width: double.infinity,
          child: FilledButton.icon(
            onPressed:
                _isInitializing ||
                        _errorMessage != null ||
                        _isTakingPhoto
                    ? null
                    : _capturePhoto,
            icon: _isTakingPhoto
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.camera,
                  ),
            label: Text(
              _isTakingPhoto
                  ? 'Capturing...'
                  : 'Capture Photo',
            ),
          ),
        ),
      ),
    );
  }
}