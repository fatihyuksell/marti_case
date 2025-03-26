import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:marti_case/core/providers.dart';

import 'package:marti_case/data/models/location_model.dart';
import 'package:marti_case/data/models/location_state.dart';
import 'package:marti_case/screens/view_model/location_view_model.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  late final LocationViewModel viewModel;
  final double _defaultZoom = 20.0;
  final Set<Marker> _markers = {};

  LocationModel? _selectedLocation;
  GoogleMapController? _mapController;

  bool _userZoomChanged = false;
  String? _selectedLocationAddress;
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    viewModel = ref.read(locationViewModelProvider.notifier);
    Future.microtask(() {
      viewModel.getCurrentLocation();
      viewModel.startTracking();
    });
  }

  @override
  void dispose() {
    viewModel.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationViewModelProvider);

    _updateMarkers(locationState);
    _handleLocationUpdate(locationState);

    return Scaffold(
      appBar: _buildAppBar(locationState),
      body: locationState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                _buildGoogleMap(locationState),
                if (_selectedLocation != null)
                  _buildLocationInfoPanel(locationState),
                _buildMapStatsWidget(locationState),
              ],
            ),
    );
  }

  AppBar _buildAppBar(LocationState locationState) {
    return AppBar(
      title: const Text('Konum Takibi'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            _resetRoute(locationState);
          },
          tooltip: 'Rotayı Sıfırla',
        ),
        IconButton(
          icon: Icon(
              locationState.isTracking ? Icons.gps_fixed : Icons.gps_not_fixed),
          onPressed: () {
            if (!locationState.isTracking) {
              viewModel.startTracking();
              if (locationState.currentLocation != null) {
                _updateCameraPosition(
                  LatLng(
                    locationState.currentLocation!.latitude,
                    locationState.currentLocation!.longitude,
                  ),
                );
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Konum takibi başlatıldı, yeni rota oluşturuluyor'),
                  duration: Duration(seconds: 2),
                ),
              );
            } else {
              viewModel.stopTracking();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Konum takibi durduruldu, rota kaydedildi'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildGoogleMap(LocationState locationState) {
    final initialPosition = _getInitialCameraPosition(locationState);
    final polylines = _createPolylines(locationState);

    return GoogleMap(
      initialCameraPosition: initialPosition,
      markers: _markers,
      polylines: polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      mapType: MapType.normal,
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
      },
      onCameraMove: (CameraPosition position) {
        _userZoomChanged = true;
      },
      onTap: (LatLng position) => _handleMapTap(position, locationState),
    );
  }

  CameraPosition _getInitialCameraPosition(LocationState locationState) {
    return locationState.currentLocation != null
        ? CameraPosition(
            target: LatLng(
              locationState.currentLocation!.latitude,
              locationState.currentLocation!.longitude,
            ),
            zoom: _defaultZoom,
          )
        : const CameraPosition(
            target: LatLng(41.0082, 28.9784),
            zoom: 10,
          );
  }

  Set<Polyline> _createPolylines(LocationState locationState) {
    Set<Polyline> polylines = {};

    if (locationState.locationHistory.isNotEmpty) {
      List<LatLng> polylineCoordinates = locationState.locationHistory
          .map((loc) => LatLng(loc.latitude, loc.longitude))
          .toList();

      if (locationState.currentLocation != null) {
        polylineCoordinates.add(LatLng(
          locationState.currentLocation!.latitude,
          locationState.currentLocation!.longitude,
        ));
      }

      polylines.add(
        Polyline(
          polylineId: const PolylineId('location_history'),
          points: polylineCoordinates,
          color: Colors.blue,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      );
    }

    return polylines;
  }

  void _handleLocationUpdate(LocationState locationState) {
    if (locationState.currentLocation != null &&
        _mapController != null &&
        locationState.isTracking &&
        _selectedLocation == null) {
      _updateCameraPosition(
        LatLng(
          locationState.currentLocation!.latitude,
          locationState.currentLocation!.longitude,
        ),
      );
    }
  }

  void _handleMapTap(LatLng position, LocationState locationState) {
    setState(() {
      _selectedLocation = null;

      if (locationState.currentLocation != null) {
        _updateCameraPosition(
          LatLng(
            locationState.currentLocation!.latitude,
            locationState.currentLocation!.longitude,
          ),
        );
      }
    });
  }

  void _updateCameraPosition(LatLng position) {
    if (_mapController == null) return;

    if (_userZoomChanged) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(position));
    } else {
      _mapController!
          .animateCamera(CameraUpdate.newLatLngZoom(position, _defaultZoom));
    }
  }

  void _updateMarkers(LocationState locationState) {
    if (locationState.locationHistory.isEmpty) return;

    _markers.clear();
    Set<String> addedPositions = {};

    for (int i = 0; i < locationState.locationHistory.length; i++) {
      final location = locationState.locationHistory[i];
      final positionKey =
          '${location.latitude.toStringAsFixed(6)},${location.longitude.toStringAsFixed(6)}';

      if (!addedPositions.contains(positionKey)) {
        addedPositions.add(positionKey);

        _markers.add(
          _createMarker(location, i, locationState.locationHistory.length - 1),
        );
      }
    }
  }

  Marker _createMarker(LocationModel location, int index, int lastIndex) {
    final isSelected = _selectedLocation?.latitude == location.latitude &&
        _selectedLocation?.longitude == location.longitude;
    final isLastLocation = index == lastIndex;

    return Marker(
      markerId: MarkerId(location.timestamp.millisecondsSinceEpoch.toString()),
      position: LatLng(location.latitude, location.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        isSelected
            ? BitmapDescriptor.hueGreen
            : isLastLocation
                ? BitmapDescriptor.hueRed
                : BitmapDescriptor.hueViolet,
      ),
      infoWindow: InfoWindow(
        title: 'Konum ${index + 1}',
        snippet: _formatTimestamp(location.timestamp, short: true),
      ),
      onTap: () {
        setState(() {
          _selectedLocation = location;
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(
                LatLng(location.latitude, location.longitude)),
          );
          _getAddressFromLatLng(location);
        });
      },
    );
  }

  Future<void> _getAddressFromLatLng(LocationModel location) async {
    setState(() {
      _selectedLocationAddress = null;
      _isLoadingAddress = true;
    });

    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        setState(() {
          _selectedLocationAddress =
              '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, '
              '${place.administrativeArea}, ${place.postalCode}, ${place.country}';
          _isLoadingAddress = false;
        });
      } else {
        setState(() {
          _selectedLocationAddress = 'Adres bulunamadı';
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      setState(() {
        _selectedLocationAddress = 'Adres alınamadı: $e';
        _isLoadingAddress = false;
      });
    }
  }

  Widget _buildLocationInfoPanel(LocationState locationState) {
    return Positioned(
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
                _selectedLocation == locationState.currentLocation
                    ? 'Şu anki konumunuz'
                    : 'Geçmiş Konum',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Enlem: ${_selectedLocation!.latitude.toStringAsFixed(6)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'Boylam: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'Zaman: ${_formatTimestamp(_selectedLocation!.timestamp)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              _isLoadingAddress
                  ? const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text("Adres yükleniyor..."),
                      ],
                    )
                  : _selectedLocationAddress != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Açık Adres:',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              _selectedLocationAddress!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        )
                      : const Text("Adres bilgisi yok"),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _closeLocationInfoPanel(locationState),
                  child: const Text('Kapat'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _closeLocationInfoPanel(LocationState locationState) {
    setState(() {
      _selectedLocation = null;

      if (locationState.currentLocation != null) {
        _updateCameraPosition(
          LatLng(
            locationState.currentLocation!.latitude,
            locationState.currentLocation!.longitude,
          ),
        );
      }
    });
  }

  Widget _buildMapStatsWidget(LocationState locationState) {
    return Positioned(
      top: 20,
      right: 20,
      child: GestureDetector(
        onTap: () => _showMarkersInfoDialog(context),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Marker: ${_markers.length}'),
              Text('Rota: ${_createPolylines(locationState).length}'),
            ],
          ),
        ),
      ),
    );
  }

  void _showMarkersInfoDialog(BuildContext context) {
    final locationState = ref.read(locationViewModelProvider);
    final allMarkers = _getAllMarkersWithTimestamps(locationState);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tüm Marker Konumları'),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: allMarkers.length,
            itemBuilder: (context, index) =>
                _buildMarkerListItem(index, allMarkers[index]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getAllMarkersWithTimestamps(
      LocationState locationState) {
    final List<Map<String, dynamic>> allMarkers = [];

    for (var marker in _markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;

      DateTime? timestamp;
      if (locationState.locationHistory.isNotEmpty) {
        for (var location in locationState.locationHistory) {
          if ((location.latitude - lat).abs() < 0.000001 &&
              (location.longitude - lng).abs() < 0.000001) {
            timestamp = location.timestamp;
            break;
          }
        }
      }

      allMarkers.add({
        'position': marker.position,
        'timestamp': timestamp,
      });
    }

    return allMarkers;
  }

  Widget _buildMarkerListItem(int index, Map<String, dynamic> data) {
    final position = data['position'] as LatLng;
    final timestamp = data['timestamp'] as DateTime?;

    return ListTile(
      title: Text('Marker ${index + 1}'),
      subtitle: Text(
        'Enlem: ${position.latitude.toStringAsFixed(6)}\n'
        'Boylam: ${position.longitude.toStringAsFixed(6)}\n'
        'Zaman: ${timestamp != null ? _formatTimestamp(timestamp) : 'Zaman bilgisi yok'}',
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp, {bool short = false}) {
    if (short) {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }

    return '${timestamp.day}/${timestamp.month}/${timestamp.year} '
        '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}.'
        '${timestamp.millisecond.toString().padLeft(3, '0')}';
  }

  void _resetRoute(LocationState locationState) {
    viewModel.resetRoute();

    if (!locationState.isTracking) {
      viewModel.startTracking();
    }

    if (locationState.currentLocation != null) {
      _updateCameraPosition(
        LatLng(
          locationState.currentLocation!.latitude,
          locationState.currentLocation!.longitude,
        ),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Rota sıfırlandı! Önceki rota kaydedildi ve yeni rota başlatıldı.'),
        duration: Duration(seconds: 3),
      ),
    );
  }
}
