import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:marti_case/features/location/domain/models/route_history_model.dart';
import 'package:marti_case/features/location/domain/models/location_model.dart';
import 'dart:math' show max, min;

class RouteMapScreen extends ConsumerStatefulWidget {
  final RouteHistoryModel route;

  const RouteMapScreen({
    super.key,
    required this.route,
  });

  @override
  ConsumerState<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends ConsumerState<RouteMapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _initializeRouteOnMap();
  }

  void _initializeRouteOnMap() {
    _createMarkersFromRoute();

    _createPolyline();
  }

  void _createMarkersFromRoute() {
    if (widget.route.locationPoints.isEmpty) return;

    final markers = <Marker>{};
    final locations = widget.route.locationPoints;

    markers.add(
      _createMarker(
        locations.first,
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        'Başlangıç',
      ),
    );

    markers.add(
      _createMarker(
        locations.last,
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        'Bitiş',
      ),
    );

    if (locations.length > 2) {
      final step = max(1, (locations.length - 2) ~/ 8);
      for (int i = step; i < locations.length - 1; i += step) {
        markers.add(_createMarker(
            locations[i],
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            'Nokta ${i + 1}'));
      }
    }
    setState(() {
      _markers.addAll(markers);
    });
  }

  Marker _createMarker(
      LocationModel location, BitmapDescriptor icon, String title) {
    return Marker(
      markerId: MarkerId('${location.timestamp}'),
      position: LatLng(location.latitude, location.longitude),
      icon: icon,
      infoWindow: InfoWindow(
        title: title,
        snippet:
            'Tarih: ${_formatTimestamp(location.timestamp.millisecondsSinceEpoch)}',
      ),
      onTap: () {
        setState(() {});
      },
    );
  }

  void _createPolyline() {
    if (widget.route.locationPoints.isEmpty) return;

    final List<LatLng> points = widget.route.locationPoints
        .map((loc) => LatLng(loc.latitude, loc.longitude))
        .toList();

    final polyline = Polyline(
      polylineId: PolylineId('route_${widget.route.id}'),
      points: points,
      color: Colors.blue,
      width: 5,
    );

    setState(() {
      _polylines.add(polyline);
    });
  }

  String _formatTimestamp(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geçmiş Rota'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _getInitialCameraPosition(),
            markers: _markers,
            polylines: _polylines,
            mapType: MapType.normal,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            onMapCreated: (controller) {
              _mapController = controller;
              _fitMapToRoute();
            },
          ),
          // Rota bilgileri paneli
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Rota Bilgileri',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                        'Başlangıç: ${_formatDateTime(widget.route.startTime)}'),
                    Text('Bitiş: ${_formatDateTime(widget.route.endTime)}'),
                    Text(
                        'Süre: ${_formatDuration(widget.route.endTime.difference(widget.route.startTime))}'),
                    Text(
                        'Mesafe: ${(widget.route.totalDistance / 1000).toStringAsFixed(2)} km'),
                    //TODO: Konum noktalarını görüntüleme
                    // Text(
                    //   'Konum Noktaları: ${widget.route.locationPoints.length}',
                    //   style: TextStyle(
                    //     color: widget.route.locationPoints.isEmpty
                    //         ? Colors.red
                    //         : Colors.black,
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  CameraPosition _getInitialCameraPosition() {
    if (widget.route.locationPoints.isEmpty) {
      return const CameraPosition(
        target: LatLng(41.015137, 28.979530),
        zoom: 12,
      );
    }

    // İlk konumu kullan
    final firstLocation = widget.route.locationPoints.first;
    return CameraPosition(
      target: LatLng(firstLocation.latitude, firstLocation.longitude),
      zoom: 14,
    );
  }

  void _fitMapToRoute() {
    if (widget.route.locationPoints.isEmpty || _mapController == null) return;

    double minLat = 90.0;
    double maxLat = -90.0;
    double minLng = 180.0;
    double maxLng = -180.0;

    for (final location in widget.route.locationPoints) {
      minLat = min(minLat, location.latitude);
      maxLat = max(maxLat, location.latitude);
      minLng = min(minLng, location.longitude);
      maxLng = max(maxLng, location.longitude);
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50.0),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}:${dateTime.second}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '$hours saat $minutes dakika';
    } else if (minutes > 0) {
      return '$minutes dakika $seconds saniye';
    } else {
      return '$seconds saniye';
    }
  }
}
