import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/customer.dart';
import '../services/database_service.dart';
import '../pages/customer_update_form.dart';
import '../pages/capture_images_flow_page.dart';

class CustomerInfoModal extends StatefulWidget {
  final Customer customer;

  const CustomerInfoModal({super.key, required this.customer});

  @override
  _CustomerInfoModalState createState() => _CustomerInfoModalState();
}

class _CustomerInfoModalState extends State<CustomerInfoModal> {
  String _appendEditedField(String field) {
    final current = (widget.customer.editedFields ?? '').trim();
    if (current.isEmpty) return field;
    if (current.split(',').map((e) => e.trim()).contains(field)) return current;
    return '$current, $field';
  }

  Future<Position> _determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS/location services.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied. Please allow location in app settings.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<void> _saveCapturedImagesForCustomer(List<File> images) async {
    final appDir = await getApplicationDocumentsDirectory();
    final folderName = DatabaseService.customerImageFolderName(widget.customer);
    final folderPath = p.join(appDir.path, 'captured_images', folderName);
    final targetDir = Directory(folderPath);

    if (await targetDir.exists()) {
      final existing = targetDir.listSync().whereType<File>().toList();
      for (final file in existing) {
        await file.delete();
      }
    } else {
      await targetDir.create(recursive: true);
    }

    for (var i = 0; i < images.length; i++) {
      final src = images[i];
      final ext = p.extension(src.path).isEmpty ? '.jpg' : p.extension(src.path);
      final destination = p.join(targetDir.path, 'image_${i + 1}$ext');
      await src.copy(destination);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          Expanded(
            flex: 2,
            child: widget.customer.latitude != null && widget.customer.longitude != null
                ? Stack(
                    children: [
                      FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(widget.customer.latitude!, widget.customer.longitude!),
                          initialZoom: 15.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                            subdomains: const ['a', 'b', 'c', 'd'],
                            userAgentPackageName: 'com.example.kenea_customers',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(widget.customer.latitude!, widget.customer.longitude!),
                                child: const Icon(
                                  Icons.location_pin,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(140),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Lat: ${widget.customer.latitude!.toStringAsFixed(6)}\nLng: ${widget.customer.longitude!.toStringAsFixed(6)}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontFeatures: []),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(child: Text('No Long-Lat Data')),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Customer Code: ${widget.customer.customerCode}'),
                        Text('Name: ${widget.customer.customerName}'),
                        Text('Phone: ${widget.customer.phone}'),
                        Text('First Name: ${widget.customer.firstName}'),
                        Text('Last Name: ${widget.customer.lastName}'),
                        Text('TIN No: ${widget.customer.tinNo}'),
                        Text('Address: ${widget.customer.address}'),
                        Text('Party Classification: ${widget.customer.partyClassificationDescription}'),
                        Text('Coverage Day: ${widget.customer.coverageDay}'),
                        Text('Wkly Coverage: ${widget.customer.wklyCoverage}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _captureLocation,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Capture New Location'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _updateStatus,
                      icon: const Icon(Icons.toggle_on_outlined),
                      label: const Text('Customer Status Update'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _updateInfo,
                      icon: const Icon(Icons.edit_note),
                      label: const Text('Customer Information Update'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _captureLocation() async {
    try {
      final images = await Navigator.push<List<File>>(
        context,
        MaterialPageRoute(builder: (_) => const CaptureImagesFlowPage()),
      );

      if (!mounted || images == null || images.length != 3) {
        return;
      }

      final position = await _determinePosition();
      if (!mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Submit Location'),
          content: Text(
            'Images captured: 3/3\n\n'
            'Latitude: ${position.latitude.toStringAsFixed(6)}\n'
            'Longitude: ${position.longitude.toStringAsFixed(6)}\n\n'
            'Proceed to record/upload this location?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Submit Images'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      await _saveCapturedImagesForCustomer(images);

      final updated = widget.customer.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
        editedFields: _appendEditedField('location'),
      );
      await DatabaseService().updateCustomer(updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Location recorded with Lat ${position.latitude.toStringAsFixed(6)}, '
            'Lng ${position.longitude.toStringAsFixed(6)}.',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Capture failed: $e')),
      );
    }
  }

  void _updateStatus() {
    String currentStatus = widget.customer.status;
    showDialog(
      context: context,
      builder: (dialogContext) {
        final dialogNavigator = Navigator.of(dialogContext);
        final pageNavigator = Navigator.of(context);
        return AlertDialog(
        title: Text('Update Status'),
        content: DropdownButton<String>(
          value: currentStatus,
          items: ['Active/Approved', 'Blocked/On hold'].map((status) {
            return DropdownMenuItem(value: status, child: Text(status));
          }).toList(),
          onChanged: (value) => currentStatus = value!,
        ),
        actions: [
          TextButton(
            onPressed: () => dialogNavigator.pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Customer updated = widget.customer.copyWith(status: currentStatus, editedFields: _appendEditedField('status'));
              await DatabaseService().updateCustomer(updated);
              if (!mounted) return;
              dialogNavigator.pop();
              pageNavigator.pop(); // Close modal
            },
            child: Text('Submit'),
          ),
        ],
      );
      },
    );
  }

  void _updateInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerUpdateForm(customer: widget.customer),
      ),
    );
  }
}