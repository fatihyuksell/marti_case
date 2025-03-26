import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marti_case/core/providers.dart';
import 'package:marti_case/core/router/app_router.dart';
import 'package:marti_case/data/models/location_model.dart';
import 'package:marti_case/data/models/location_state.dart';
import 'package:marti_case/data/models/route_history_model.dart';
import 'package:intl/intl.dart';
import 'package:marti_case/screens/view_model/location_view_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<RouteHistoryModel> _routeHistory = [];
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRouteHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRouteHistory() async {
    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final locationRepository = ref.read(locationRepositoryProvider);
      final history = await locationRepository.getRouteHistory();

      debugPrint("Yüklenen rota sayısı: ${history.length}");

      setState(() {
        _routeHistory = history;
        _isLoadingHistory = false;
      });
    } catch (e) {
      debugPrint("Rota geçmişi yükleme hatası: $e");
      setState(() {
        _isLoadingHistory = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Geçmiş sürüşler yüklenirken hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationViewModelProvider);
    final locationViewModel = ref.read(locationViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konum Takibi'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mevcut Konum'),
            Tab(text: 'Geçmiş Sürüşler'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRouteHistory,
            tooltip: 'Geçmiş sürüşleri yenile',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: TabBarView(
            controller: _tabController,
            children: [
              CurrentLocationTab(
                locationState: locationState,
                locationViewModel: locationViewModel,
                appRouter: ref.read(appRouterProvider),
              ),
              RouteHistoryTab(
                routeHistory: _routeHistory,
                isLoading: _isLoadingHistory,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CurrentLocationTab extends StatelessWidget {
  final LocationState locationState;
  final LocationViewModel locationViewModel;
  final AppRouter appRouter;

  const CurrentLocationTab({
    super.key,
    required this.locationState,
    required this.locationViewModel,
    required this.appRouter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CurrentLocationCard(
          locationState: locationState,
        ),
        const SizedBox(height: 16),
        ActionButtonsRow(
          locationViewModel: locationViewModel,
          appRouter: appRouter,
        ),
        const SizedBox(height: 16),
        TrackingControlRow(
          locationState: locationState,
          locationViewModel: locationViewModel,
        ),
        const SizedBox(height: 24),
        Text(
          'Konum Geçmişi',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LocationHistoryList(
            locationHistory: locationState.locationHistory,
          ),
        ),
      ],
    );
  }
}

class CurrentLocationCard extends StatelessWidget {
  final LocationState locationState;

  const CurrentLocationCard({
    super.key,
    required this.locationState,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mevcut Konum',
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
                    'Enlem: ${locationState.currentLocation!.latitude}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    'Boylam: ${locationState.currentLocation!.longitude}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    'Zaman: ${DateTime.fromMillisecondsSinceEpoch(locationState.currentLocation!.timestamp.millisecondsSinceEpoch).toString()}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              )
            else
              Text(
                'Konum verisi yok',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
          ],
        ),
      ),
    );
  }
}

class ActionButtonsRow extends StatelessWidget {
  final LocationViewModel locationViewModel;
  final AppRouter appRouter;

  const ActionButtonsRow({
    super.key,
    required this.locationViewModel,
    required this.appRouter,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => locationViewModel.fetchCurrentLocation(),
            icon: const Icon(Icons.location_searching),
            label: const Text('Mevcut Konumu Al'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => appRouter.routerDelegate.navigateToMap(),
            icon: const Icon(Icons.map),
            label: const Text('Haritayı Görüntüle'),
          ),
        ),
      ],
    );
  }
}

class TrackingControlRow extends StatelessWidget {
  final LocationState locationState;
  final LocationViewModel locationViewModel;

  const TrackingControlRow({
    super.key,
    required this.locationState,
    required this.locationViewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: locationState.isTracking
              ? null
              : () => locationViewModel.startTracking(),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Takibi Başlat'),
        ),
        ElevatedButton.icon(
          onPressed: !locationState.isTracking
              ? null
              : () => locationViewModel.stopTracking(),
          icon: const Icon(Icons.stop),
          label: const Text('Takibi Durdur'),
        ),
      ],
    );
  }
}

class LocationHistoryList extends StatelessWidget {
  final List<LocationModel> locationHistory;

  const LocationHistoryList({
    required this.locationHistory,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return locationHistory.isEmpty
        ? const Center(
            child: Text('Konum geçmişi yok'),
          )
        : ListView.builder(
            itemCount: locationHistory.length,
            itemBuilder: (context, index) {
              final location =
                  locationHistory[locationHistory.length - 1 - index];
              return ListTile(
                title: Text(
                  'Enlem: ${location.latitude.toStringAsFixed(6)}, '
                  'Boylam: ${location.longitude.toStringAsFixed(6)}',
                ),
                subtitle: Text(
                  DateTime.fromMillisecondsSinceEpoch(
                    location.timestamp.millisecondsSinceEpoch,
                  ).toString(),
                ),
                leading: const Icon(Icons.location_on),
              );
            },
          );
  }
}

class RouteHistoryTab extends ConsumerWidget {
  final List<RouteHistoryModel> routeHistory;
  final bool isLoading;

  const RouteHistoryTab({
    super.key,
    required this.routeHistory,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (routeHistory.isEmpty) {
      return const Center(
        child: Text('Henüz kaydedilmiş sürüş yok'),
      );
    }

    return ListView.builder(
      itemCount: routeHistory.length,
      itemBuilder: (context, index) {
        final route = routeHistory[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: const Icon(Icons.directions_car),
            title: Text(
              'Sürüş ${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tarih: ${_formatDate(route.startTime)}'),
                Text(
                    'Mesafe: ${(route.totalDistance / 1000).toStringAsFixed(2)} km'),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Başlangıç: ${_formatDateTime(route.startTime)}'),
                    Text('Bitiş: ${_formatDateTime(route.endTime)}'),
                    Text(
                        'Süre: ${_formatDuration(route.endTime.difference(route.startTime))}'),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => ref
                          .read(appRouterProvider)
                          .routerDelegate
                          .navigateToRouteMap(route),
                      icon: const Icon(Icons.map),
                      label: const Text('Haritada Göster'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('dd.MM.yyyy').format(dateTime);
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
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
