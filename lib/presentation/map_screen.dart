import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:marti_case/core/dep_injection.dart';

import 'package:marti_case/features/location/domain/models/location_model.dart';
import 'package:marti_case/features/location/domain/models/location_state.dart';
import 'package:marti_case/presentation/screens/location_view_model.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  LocationModel? _selectedLocation;
  late final LocationViewModel viewModel;
  GoogleMapController? _mapController;
  bool _userZoomChanged = false;
  final double _defaultZoom = 20.0;
  final Set<Marker> _markers = {};

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

    debugPrint('Mevcut konum: ${locationState.currentLocation?.latitude}');
    debugPrint('Mevcut konum: ${locationState.currentLocation?.longitude}');
    debugPrint('Konum geçmişi sayısı: ${locationState.locationHistory.length}');

    _updateMarkers(locationState);

    Set<Polyline> polylines = {};
    List<LatLng> polylineCoordinates = [];

    if (locationState.locationHistory.isNotEmpty) {
      for (var location in locationState.locationHistory) {
        polylineCoordinates.add(LatLng(location.latitude, location.longitude));
      }

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

    CameraPosition initialPosition = locationState.currentLocation != null
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konum Takibi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              locationState.isTracking ? Icons.gps_fixed : Icons.gps_not_fixed,
            ),
            onPressed: () {
              if (!locationState.isTracking) {
                ref.read(locationViewModelProvider.notifier).startTracking();
              } else {
                ref.read(locationViewModelProvider.notifier).stopTracking();
              }
            },
          ),
        ],
      ),
      body: locationState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
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
                  onTap: (LatLng position) {
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
                  },
                ),
                // Alt bilgi paneli
                if (_selectedLocation != null)
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
                              'Zaman: ${_selectedLocation!.timestamp.toLocal()}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedLocation = null;

                                    if (locationState.currentLocation != null) {
                                      _updateCameraPosition(
                                        LatLng(
                                          locationState
                                              .currentLocation!.latitude,
                                          locationState
                                              .currentLocation!.longitude,
                                        ),
                                      );
                                    }
                                  });
                                },
                                child: Text('Kapat'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Marker ve rota sayısını gösteren widget
                Positioned(
                  bottom: 100,
                  right: 20,
                  child: GestureDetector(
                    onTap: () {
                      _showMarkersInfoDialog(context, _markers);
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
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
                          Text('Rota: ${polylines.length}'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _updateCameraPosition(LatLng position) {
    if (_mapController == null) return;

    if (_userZoomChanged) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(position),
      );
    } else {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(position, _defaultZoom),
      );
    }
  }

  // Marker bilgilerini gösteren popup - tüm marker'lar ve detaylı zaman damgası
  void _showMarkersInfoDialog(BuildContext context, Set<Marker> markers) {
    final locationState = ref.read(locationViewModelProvider);

    // Tüm marker'ları ve zaman bilgilerini saklayacak liste
    final List<Map<String, dynamic>> allMarkers = [];

    // Her marker için timestamp bilgisini bul
    for (var marker in markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;

      // Konum bilgisine karşılık gelen LocationModel'i bulmaya çalışıyoruz
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tüm Marker Konumları'),
        content: Container(
          width: double.maxFinite,
          height:
              MediaQuery.of(context).size.height * 0.6, // Yüksekliği sınırla
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: allMarkers.length,
            itemBuilder: (context, index) {
              final data = allMarkers[index];
              final position = data['position'] as LatLng;
              final timestamp = data['timestamp'] as DateTime?;

              String timeString = 'Zaman bilgisi yok';
              if (timestamp != null) {
                timeString =
                    '${timestamp.day}/${timestamp.month}/${timestamp.year} '
                    '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}:'
                    '${timestamp.second.toString().padLeft(2, '0')}.'
                    '${timestamp.millisecond.toString().padLeft(3, '0')}';
              }

              return ListTile(
                title: Text('Marker ${index + 1}'),
                subtitle: Text(
                  'Enlem: ${position.latitude.toStringAsFixed(6)}\n'
                  'Boylam: ${position.longitude.toStringAsFixed(6)}\n'
                  'Zaman: $timeString',
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _updateMarkers(LocationState locationState) {
    if (locationState.locationHistory.isEmpty) return;

    // Mevcut marker'ları temizleyelim
    _markers.clear();

    // Eklenen konumları takip etmek için bir set kullanacağız
    Set<String> addedPositions = {};

    // Her konum için bir marker oluştur, ama aynı konumları filtrele
    for (int i = 0; i < locationState.locationHistory.length; i++) {
      final location = locationState.locationHistory[i];

      // Konum bilgisini bir anahtar olarak oluştur (çok hassas bir karşılaştırma için)
      // 6 ondalık basamak yaklaşık 10cm hassasiyet sağlar
      final positionKey =
          '${location.latitude.toStringAsFixed(6)},${location.longitude.toStringAsFixed(6)}';

      // Eğer bu konum daha önce eklenmediyse ekle
      if (!addedPositions.contains(positionKey)) {
        // Bu konumu eklenen konumlar setine kaydet
        addedPositions.add(positionKey);

        final isSelected = _selectedLocation?.latitude == location.latitude &&
            _selectedLocation?.longitude == location.longitude;
        final isLastLocation = i == locationState.locationHistory.length - 1;

        _markers.add(
          Marker(
            markerId:
                MarkerId(location.timestamp.millisecondsSinceEpoch.toString()),
            position: LatLng(location.latitude, location.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              isSelected
                  ? BitmapDescriptor.hueGreen
                  : isLastLocation
                      ? BitmapDescriptor.hueRed
                      : BitmapDescriptor.hueViolet,
            ),
            infoWindow: InfoWindow(
              title: 'Konum ${addedPositions.length}',
              snippet:
                  '${location.timestamp.day}/${location.timestamp.month} ${location.timestamp.hour}:${location.timestamp.minute}',
            ),
            onTap: () {
              setState(() {
                _selectedLocation = location;

                _mapController?.animateCamera(
                  CameraUpdate.newLatLng(
                      LatLng(location.latitude, location.longitude)),
                );
              });
            },
          ),
        );

        // Debug mesajı ekleyelim, marker ekleme işlemlerini izleyelim
        debugPrint('Marker eklendi: $positionKey');
      } else {
        // Debug mesajı ekleyelim, atlanan konumları görelim
        debugPrint('Aynı konum atlandı: $positionKey');
      }
    }

    // Eklenen benzersiz marker sayısını göster
    debugPrint('Toplam eklenen benzersiz marker sayısı: ${_markers.length}');
  }
}

// class MapScreen extends ConsumerStatefulWidget {
//   const MapScreen({super.key});

//   @override
//   ConsumerState<MapScreen> createState() => _MapScreenState();
// }

// class _MapScreenState extends ConsumerState<MapScreen> {
//   GoogleMapController? _mapController;
//   final Set<Marker> _markers = {};
//   LatLng? _currentPosition;

//   @override
//   void initState() {
//     super.initState();
//     _getCurrentLocation();
//   }

//   Future<void> _getCurrentLocation() async {
//     bool serviceEnabled;
//     LocationPermission permission;

//     // Konum servisi açık mı kontrol et
//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       return;
//     }

//     // Konum izinlerini kontrol et
//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.deniedForever) {
//         return;
//       }
//     }

//     // Konumu al
//     Position position = await Geolocator.getCurrentPosition();

//     if (mounted) {
//       setState(() {
//         _currentPosition = LatLng(position.latitude, position.longitude);
//         _markers.add(
//           Marker(
//             markerId: const MarkerId("current_location"),
//             position: _currentPosition!,
//             infoWindow: const InfoWindow(title: "Şu Anki Konum"),
//           ),
//         );

//         // Location history'den de markerları ekle
//         final locationState = ref.read(locationViewModelProvider);
//         if (locationState.locationHistory.isNotEmpty) {
//           for (var location in locationState.locationHistory) {
//             _markers.add(
//               Marker(
//                 markerId: MarkerId(
//                     "history_${location.timestamp.millisecondsSinceEpoch}"),
//                 position: LatLng(location.latitude, location.longitude),
//                 icon: BitmapDescriptor.defaultMarkerWithHue(
//                     BitmapDescriptor.hueBlue),
//                 infoWindow: InfoWindow(
//                   title: "Geçmiş Konum",
//                   snippet: location.timestamp.toString(),
//                 ),
//               ),
//             );
//           }
//         }
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () {
//             ref.read(appRouterProvider).pop();
//           },
//         ),
//         title: const Text('Konum Haritası'),
//       ),
//       body: _currentPosition == null
//           ? const Center(child: CircularProgressIndicator())
//           : GoogleMap(
//               onMapCreated: (controller) {
//                 _mapController = controller;
//                 _mapController?.animateCamera(
//                     CameraUpdate.newLatLngZoom(_currentPosition!, 15));
//               },
//               initialCameraPosition: CameraPosition(
//                 target: _currentPosition!,
//                 zoom: 15.0,
//               ),
//               markers: _markers,
//               myLocationEnabled: true,
//               myLocationButtonEnabled: true,
//             ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           if (_currentPosition != null && _mapController != null) {
//             _mapController!.animateCamera(
//               CameraUpdate.newLatLngZoom(_currentPosition!, 15),
//             );
//           }
//           ref.read(locationViewModelProvider.notifier).fetchCurrentLocation();
//         },
//         child: const Icon(Icons.my_location),
//       ),
//     );
//   }
// }
