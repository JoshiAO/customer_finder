import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/customer.dart';
import '../services/database_service.dart';
import '../services/routing_service.dart';
import '../pages/customer_update_form.dart';
import '../pages/capture_images_flow_page.dart';

class CustomerInfoModal extends StatefulWidget {
  final Customer customer;

  const CustomerInfoModal({super.key, required this.customer});

  @override
  State<CustomerInfoModal> createState() => _CustomerInfoModalState();
}

class _CustomerInfoModalState extends State<CustomerInfoModal> {
  final MapController _mapController = MapController();
  final RoutingService _routingService = const RoutingService();
  static const double _trackingZoom = 16.5;
  static const Duration _routeRefreshInterval = Duration(seconds: 6);
  static const double _routeRefreshDistanceMeters = 20;

  StreamSubscription<Position>? _trackingSubscription;
  Position? _trackedPosition;
  bool _isTracking = false;
  bool _isTrackingBusy = false;
  String? _trackingError;
  bool _isRouteLoading = false;
  String? _routeError;
  String? _routeProvider;
  List<LatLng> _routePoints = [];
  double? _routeDistanceMeters;
  double? _routeDurationSeconds;
  Position? _lastRouteOrigin;
  DateTime? _lastRouteFetchAt;

  bool get _hasCustomerLocation => widget.customer.latitude != null && widget.customer.longitude != null;

  LatLng get _customerLatLng => LatLng(widget.customer.latitude!, widget.customer.longitude!);

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

  double? get _distanceToCustomerMeters {
    if (!_hasCustomerLocation || _trackedPosition == null) return null;
    return Geolocator.distanceBetween(
      _trackedPosition!.latitude,
      _trackedPosition!.longitude,
      widget.customer.latitude!,
      widget.customer.longitude!,
    );
  }

  double? get _bearingToCustomer {
    if (!_hasCustomerLocation || _trackedPosition == null) return null;
    return Geolocator.bearingBetween(
      _trackedPosition!.latitude,
      _trackedPosition!.longitude,
      widget.customer.latitude!,
      widget.customer.longitude!,
    );
  }

  String _bearingLabel(double degrees) {
    const labels = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final normalized = (degrees % 360 + 360) % 360;
    final index = ((normalized / 45).round()) % labels.length;
    return labels[index];
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }

  bool _shouldRefreshRoute(Position origin) {
    if (_lastRouteOrigin == null || _lastRouteFetchAt == null) return true;

    final elapsed = DateTime.now().difference(_lastRouteFetchAt!);
    if (elapsed < _routeRefreshInterval) return false;

    final moved = Geolocator.distanceBetween(
      _lastRouteOrigin!.latitude,
      _lastRouteOrigin!.longitude,
      origin.latitude,
      origin.longitude,
    );
    return moved >= _routeRefreshDistanceMeters;
  }

  Future<void> _fetchRoadRoute({required Position origin, bool force = false}) async {
    if (!_hasCustomerLocation || _isRouteLoading) return;
    if (!force && !_shouldRefreshRoute(origin)) return;

    if (mounted) {
      setState(() {
        _isRouteLoading = true;
        _routeError = null;
      });
    }

    try {
      final route = await _routingService.getDrivingRoute(
        origin: LatLng(origin.latitude, origin.longitude),
        destination: _customerLatLng,
      );

      if (!mounted) return;
      setState(() {
        _routePoints = route.points;
        _routeDistanceMeters = route.distanceMeters;
        _routeDurationSeconds = route.durationSeconds;
        _routeProvider = route.provider;
        _routeError = null;
      });
      _lastRouteOrigin = origin;
      _lastRouteFetchAt = DateTime.now();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _routeError = e.toString();
        _routeProvider = null;
        _routePoints = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRouteLoading = false;
        });
      }
    }
  }

  void _centerMapOnTrackedPosition() {
    if (_trackedPosition == null) return;
    final point = LatLng(_trackedPosition!.latitude, _trackedPosition!.longitude);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.move(point, _trackingZoom);
    });
  }

  Future<void> _refreshMapView() async {
    if (!_hasCustomerLocation) return;

    if (_trackedPosition != null) {
      _centerMapOnTrackedPosition();
      await _fetchRoadRoute(origin: _trackedPosition!, force: true);
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.move(_customerLatLng, 15.0);
    });
  }

  Future<void> _openFullScreenMap() async {
    if (!_hasCustomerLocation) return;

    final trackedLatLng = _trackedPosition == null
        ? null
        : LatLng(_trackedPosition!.latitude, _trackedPosition!.longitude);
    final distanceToCustomer = _routeDistanceMeters ?? _distanceToCustomerMeters;
    final bearingToCustomer = _bearingToCustomer;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenDirectionMap(
          customerLatLng: _customerLatLng,
          trackedLatLng: trackedLatLng,
          routePoints: List<LatLng>.from(_routePoints),
          isTracking: _isTracking,
          isRouteLoading: _isRouteLoading,
          routeError: _routeError,
          routeProvider: _routeProvider,
          distanceMeters: distanceToCustomer,
          durationSeconds: _routeDurationSeconds,
          bearingDegrees: bearingToCustomer,
        ),
      ),
    );
  }

  Future<void> _stopTracking({bool clearError = false}) async {
    await _trackingSubscription?.cancel();
    _trackingSubscription = null;
    if (!mounted) return;
    setState(() {
      _isTracking = false;
      _isRouteLoading = false;
        _routeProvider = null;
      if (clearError) {
        _trackingError = null;
        _routeError = null;
      }
    });
  }

  Future<void> _toggleTracking() async {
    if (!_hasCustomerLocation) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tracking is unavailable because this customer has no saved coordinates.')),
      );
      return;
    }

    if (_isTracking) {
      await _stopTracking(clearError: true);
      return;
    }

    setState(() {
      _isTrackingBusy = true;
      _trackingError = null;
    });

    try {
      final initialPosition = await _determinePosition();
      if (!mounted) return;

      setState(() {
        _trackedPosition = initialPosition;
        _isTracking = true;
      });
      _centerMapOnTrackedPosition();
      await _fetchRoadRoute(origin: initialPosition, force: true);

      _trackingSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 5,
        ),
      ).listen(
        (position) {
          if (!mounted) return;
          setState(() {
            _trackedPosition = position;
          });
          _centerMapOnTrackedPosition();
          unawaited(_fetchRoadRoute(origin: position));
        },
        onError: (Object error) async {
          if (!mounted) return;
          await _stopTracking();
          if (!mounted) return;
          setState(() {
            _trackingError = error.toString();
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _trackingError = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to start tracking: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTrackingBusy = false;
        });
      }
    }
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
  void dispose() {
    _trackingSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackedLatLng = _trackedPosition == null
        ? null
        : LatLng(_trackedPosition!.latitude, _trackedPosition!.longitude);
    final distanceToCustomer = _routeDistanceMeters ?? _distanceToCustomerMeters;
    final bearingToCustomer = _bearingToCustomer;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          Expanded(
            flex: 2,
            child: _hasCustomerLocation
                ? Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _customerLatLng,
                          initialZoom: 15.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                            subdomains: const ['a', 'b', 'c', 'd'],
                            userAgentPackageName: 'com.example.kenea_customers',
                          ),
                          if (trackedLatLng != null)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: _routePoints.length >= 2 ? _routePoints : [_customerLatLng, trackedLatLng],
                                  strokeWidth: 4,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _customerLatLng,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                              if (trackedLatLng != null)
                                Marker(
                                  point: trackedLatLng,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x33000000),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const SizedBox(width: 18, height: 18),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Material(
                          color: Colors.black.withAlpha(145),
                          borderRadius: BorderRadius.circular(8),
                          child: IconButton(
                            onPressed: _refreshMapView,
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            tooltip: 'Refresh Map View',
                          ),
                        ),
                      ),
                      if (_isTracking || _trackingError != null)
                        Positioned(
                          top: 60,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(150),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DefaultTextStyle(
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_isTracking ? 'Tracking: ON' : 'Tracking: OFF'),
                                  if (_isRouteLoading)
                                    const Text('Route: updating...'),
                                  if (distanceToCustomer != null)
                                    Text('Distance: ${_formatDistance(distanceToCustomer)}'),
                                  if (_routeDurationSeconds != null)
                                    Text('ETA: ${(_routeDurationSeconds! / 60).toStringAsFixed(0)} min'),
                                  if (_routeProvider != null)
                                    Text('Route source: $_routeProvider'),
                                  if (bearingToCustomer != null)
                                    Text(
                                      'Direction: ${bearingToCustomer.toStringAsFixed(0)}° ${_bearingLabel(bearingToCustomer)}',
                                    ),
                                  if (_routeError != null)
                                    const Text('Route: unavailable, using straight line'),
                                  if (_trackingError != null)
                                    Text('Error: $_trackingError'),
                                ],
                              ),
                            ),
                          ),
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
                            'Customer\nLat: ${widget.customer.latitude!.toStringAsFixed(6)}\nLng: ${widget.customer.longitude!.toStringAsFixed(6)}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontFeatures: []),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Material(
                          color: Colors.black.withAlpha(145),
                          borderRadius: BorderRadius.circular(8),
                          child: IconButton(
                            onPressed: _openFullScreenMap,
                            icon: const Icon(Icons.fullscreen, color: Colors.white),
                            tooltip: 'Open Full Screen Map',
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
              child: ListView(
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
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final buttonWidth = (constraints.maxWidth - 12) / 2;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: buttonWidth,
                            child: ElevatedButton.icon(
                              onPressed: (!_hasCustomerLocation || _isTrackingBusy) ? null : _toggleTracking,
                              icon: Icon(_isTracking ? Icons.location_disabled : Icons.assistant_navigation),
                              label: Text(_isTracking ? 'Stop Tracking' : 'Live Tracking'),
                            ),
                          ),
                          SizedBox(
                            width: buttonWidth,
                            child: ElevatedButton.icon(
                              onPressed: _captureLocation,
                              icon: const Icon(Icons.my_location),
                              label: const Text('Capture Location'),
                            ),
                          ),
                          SizedBox(
                            width: buttonWidth,
                            child: ElevatedButton.icon(
                              onPressed: _updateStatus,
                              icon: const Icon(Icons.toggle_on_outlined),
                              label: const Text('Update Status'),
                            ),
                          ),
                          SizedBox(
                            width: buttonWidth,
                            child: ElevatedButton.icon(
                              onPressed: _updateInfo,
                              icon: const Icon(Icons.edit_note),
                              label: const Text('Update Info'),
                            ),
                          ),
                        ],
                      );
                    },
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

class _FullScreenDirectionMap extends StatelessWidget {
  const _FullScreenDirectionMap({
    required this.customerLatLng,
    required this.trackedLatLng,
    required this.routePoints,
    required this.isTracking,
    required this.isRouteLoading,
    required this.routeError,
    required this.routeProvider,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.bearingDegrees,
  });

  final LatLng customerLatLng;
  final LatLng? trackedLatLng;
  final List<LatLng> routePoints;
  final bool isTracking;
  final bool isRouteLoading;
  final String? routeError;
  final String? routeProvider;
  final double? distanceMeters;
  final double? durationSeconds;
  final double? bearingDegrees;

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }

  String _bearingLabel(double degrees) {
    const labels = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final normalized = (degrees % 360 + 360) % 360;
    final index = ((normalized / 45).round()) % labels.length;
    return labels[index];
  }

  @override
  Widget build(BuildContext context) {
    final linePoints = trackedLatLng == null
        ? <LatLng>[]
        : (routePoints.length >= 2 ? routePoints : [customerLatLng, trackedLatLng!]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Direction Map'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: trackedLatLng ?? customerLatLng,
              initialZoom: trackedLatLng == null ? 15.0 : 16.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.kenea_customers',
              ),
              if (linePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: linePoints,
                      strokeWidth: 5,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: customerLatLng,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                  if (trackedLatLng != null)
                    Marker(
                      point: trackedLatLng!,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const SizedBox(width: 18, height: 18),
                      ),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(150),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DefaultTextStyle(
                style: const TextStyle(color: Colors.white, fontSize: 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isTracking ? 'Tracking: ON' : 'Tracking: OFF'),
                    if (isRouteLoading) const Text('Route: updating...'),
                    if (distanceMeters != null) Text('Distance: ${_formatDistance(distanceMeters!)}'),
                    if (durationSeconds != null) Text('ETA: ${(durationSeconds! / 60).toStringAsFixed(0)} min'),
                    if (routeProvider != null) Text('Route source: $routeProvider'),
                    if (bearingDegrees != null)
                      Text('Direction: ${bearingDegrees!.toStringAsFixed(0)}° ${_bearingLabel(bearingDegrees!)}'),
                    if (routeError != null) const Text('Route: unavailable, using straight line'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}