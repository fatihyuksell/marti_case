import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marti_case/core/dep_injection.dart';
import 'package:marti_case/features/location/domain/models/location_state.dart';
import 'package:marti_case/features/location/domain/models/route_history_model.dart';
import 'package:intl/intl.dart';
import 'package:marti_case/presentation/screens/location_view_model.dart';
import 'package:marti_case/presentation/screens/route_map_screen.dart';

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

      print("Yüklenen rota sayısı: ${history.length}");

      setState(() {
        _routeHistory = history;
        _isLoadingHistory = false;
      });
    } catch (e) {
      print("Rota geçmişi yükleme hatası: $e");
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
              _buildCurrentLocationTab(locationState, locationViewModel),
              _buildRouteHistoryTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentLocationTab(
      LocationState locationState, LocationViewModel locationViewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
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
        ),
        const SizedBox(height: 16),
        Row(
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
                onPressed: () =>
                    ref.read(appRouterProvider).routerDelegate.navigateToMap(),
                icon: const Icon(Icons.map),
                label: const Text('Haritayı Görüntüle'),
              ),
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
        ),
        const SizedBox(height: 24),
        Text(
          'Konum Geçmişi',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: locationState.locationHistory.isEmpty
              ? const Center(
                  child: Text('Konum geçmişi yok'),
                )
              : ListView.builder(
                  itemCount: locationState.locationHistory.length,
                  itemBuilder: (context, index) {
                    final location = locationState.locationHistory[
                        locationState.locationHistory.length - 1 - index];
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
                ),
        ),
      ],
    );
  }

  Widget _buildRouteHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_routeHistory.isEmpty) {
      return const Center(
        child: Text('Henüz kaydedilmiş sürüş yok'),
      );
    }

    return ListView.builder(
      itemCount: _routeHistory.length,
      itemBuilder: (context, index) {
        final route = _routeHistory[index];
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
                    Text('Konum Sayısı: ${route.locationPoints.length}'),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => RouteMapScreen(route: route),
                          ),
                        );
                      },
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
    return DateFormat('dd.MM.yyyy HH:MM:ss').format(dateTime);
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
