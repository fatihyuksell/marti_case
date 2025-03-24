import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:marti_case/core/dep_injection.dart';

import 'package:marti_case/features/location/domain/models/location_model.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  LocationModel? _selectedLocation;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(locationViewModelProvider.notifier).getCurrentLocation();
      ref.read(locationViewModelProvider.notifier).startTracking();
    });
  }

  @override
  void dispose() {
    // ViewModel referansını, dispose çağrılmadan önce al
    final viewModel = ref.read(locationViewModelProvider.notifier);

    // Önce üst sınıfın dispose metodunu çağır
    super.dispose();

    // Ardından ViewModel üzerinde işlemi gerçekleştir
    // Bu şekilde 'ref' kullanımı widget dispose olduktan sonra gerçekleşmez
    viewModel.stopTracking();
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationViewModelProvider);

    debugPrint('Mevcut konum: ${locationState.currentLocation?.latitude}');
    debugPrint('Mevcut konum: ${locationState.currentLocation?.longitude}');
    debugPrint('Konum geçmişi sayısı: ${locationState.locationHistory.length}');

    Set<Marker> markers = {};

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

      for (int i = 0; i < locationState.locationHistory.length; i++) {
        LocationModel location = locationState.locationHistory[i];
        markers.add(
          Marker(
            markerId: MarkerId('location_$i'),
            position: LatLng(location.latitude, location.longitude),
            infoWindow: InfoWindow(
              title: 'Konum ${i + 1}',
              snippet: '${location.timestamp.toLocal()}',
            ),
            onTap: () {
              setState(() {
                _selectedLocation = location;
              });
            },
          ),
        );
      }
    }

    if (locationState.currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            locationState.currentLocation!.latitude,
            locationState.currentLocation!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Şu anki konumunuz',
          ),
          onTap: () {
            setState(() {
              _selectedLocation = locationState.currentLocation;
            });
          },
        ),
      );
    }

    CameraPosition initialPosition = locationState.currentLocation != null
        ? CameraPosition(
            target: LatLng(
              locationState.currentLocation!.latitude,
              locationState.currentLocation!.longitude,
            ),
            zoom: 15,
          )
        : const CameraPosition(
            target: LatLng(41.0082, 28.9784), // İstanbul
            zoom: 10,
          );

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
                  markers: markers,
                  polylines: polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  mapType: MapType.normal,
                  onMapCreated: (GoogleMapController controller) {
                    // Harita controller'ını gerekirse saklayabilirsiniz
                  },
                  onTap: (LatLng position) {
                    // Harita boş bir yerine tıklandığında seçili lokasyonu temizle
                    setState(() {
                      _selectedLocation = null;
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
                          ],
                        ),
                      ),
                    ),
                  ),
                // Debug bilgisi için ekran üzerinde gösterge
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.black54,
                    child: Text(
                      'Marker: ${markers.length} | Rota: ${polylineCoordinates.length} nokta',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
    );
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
