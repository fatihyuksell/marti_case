import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marti_case/core/dep_injection.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationViewModelProvider);
    final locationViewModel = ref.read(locationViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Tracker'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Location',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      if (locationState.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (locationState.currentLocation != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Latitude: ${locationState.currentLocation!.latitude}',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            Text(
                              'Longitude: ${locationState.currentLocation!.longitude}',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            Text(
                              'Time: ${locationState.currentLocation!.timestamp.toString()}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        )
                      else
                        Text(
                          'No location data',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => locationViewModel.fetchCurrentLocation(),
                    icon: const Icon(Icons.location_searching),
                    label: const Text('Get Current Location'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => ref
                        .read(appRouterProvider)
                        .routerDelegate
                        .navigateToMap(),
                    icon: const Icon(Icons.map),
                    label: const Text('View Map'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: locationState.isTracking
                        ? null
                        : () => locationViewModel.startTracking(),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Tracking'),
                  ),
                  ElevatedButton.icon(
                    onPressed: !locationState.isTracking
                        ? null
                        : () => locationViewModel.stopTracking(),
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop Tracking'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Location History',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: locationState.locationHistory.isEmpty
                    ? const Center(
                        child: Text('No location history available'),
                      )
                    : ListView.builder(
                        itemCount: locationState.locationHistory.length,
                        itemBuilder: (context, index) {
                          final location = locationState.locationHistory[
                              locationState.locationHistory.length - 1 - index];
                          return ListTile(
                            title: Text(
                              'Lat: ${location.latitude.toStringAsFixed(6)}, '
                              'Lng: ${location.longitude.toStringAsFixed(6)}',
                            ),
                            subtitle: Text(
                              location.timestamp.toString(),
                            ),
                            leading: const Icon(Icons.location_on),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
