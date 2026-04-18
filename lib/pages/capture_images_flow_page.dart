import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CaptureImagesFlowPage extends StatefulWidget {
  const CaptureImagesFlowPage({super.key});

  @override
  State<CaptureImagesFlowPage> createState() => _CaptureImagesFlowPageState();
}

class _CaptureImagesFlowPageState extends State<CaptureImagesFlowPage> {
  final ImagePicker _picker = ImagePicker();
  final List<File?> _images = List<File?>.filled(3, null);

  int get _capturedCount => _images.where((img) => img != null).length;

  Future<void> _captureAt(int index) async {
    final file = await _picker.pickImage(source: ImageSource.camera);
    if (file == null) return;
    setState(() {
      _images[index] = File(file.path);
    });
  }

  Future<void> _captureNext() async {
    final nextIndex = _images.indexWhere((img) => img == null);
    if (nextIndex == -1) {
      await _openPreview();
      return;
    }
    await _captureAt(nextIndex);
    if (_capturedCount == 3 && mounted) {
      await _openPreview();
    }
  }

  Future<void> _openPreview() async {
    if (_capturedCount < 3) return;
    final result = await Navigator.push<List<File>>(
      context,
      MaterialPageRoute(
        builder: (_) => ImagePreviewPage(
          images: _images.cast<File>(),
        ),
      ),
    );
    if (!mounted || result == null) return;
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Images'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Checklist: $_capturedCount/3',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < 3; i++)
              Card(
                child: ListTile(
                  leading: Icon(
                    _images[i] == null ? Icons.radio_button_unchecked : Icons.check_circle,
                    color: _images[i] == null ? Colors.grey : Colors.green,
                  ),
                  title: Text('Image ${i + 1}'),
                  subtitle: Text(_images[i] == null ? 'Not captured yet' : 'Captured'),
                  trailing: TextButton(
                    onPressed: () => _captureAt(i),
                    child: Text(_images[i] == null ? 'Capture' : 'Retake'),
                  ),
                ),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _captureNext,
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(_capturedCount < 3 ? 'Capture ${_capturedCount + 1}/3' : 'Review Images'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ImagePreviewPage extends StatefulWidget {
  const ImagePreviewPage({super.key, required this.images});

  final List<File> images;

  @override
  State<ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<ImagePreviewPage> {
  final ImagePicker _picker = ImagePicker();
  late final List<File> _images;

  @override
  void initState() {
    super.initState();
    _images = List<File>.from(widget.images);
  }

  Future<void> _retakeImage(int index) async {
    final file = await _picker.pickImage(source: ImageSource.camera);
    if (file == null) return;
    setState(() {
      _images[index] = File(file.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Captured Images'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _images),
            child: const Text(
              'Submit Images',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _images.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Image ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _images[index],
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => _retakeImage(index),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Retake Image'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}