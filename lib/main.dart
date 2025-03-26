import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marti_case/core/providers.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  bg.BackgroundGeolocation.registerHeadlessTask(headlessTask);

  final container = ProviderContainer();
  final backgroundService = container.read(backgroundLocationServiceProvider);
  backgroundService.initialize();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Marti Konum Takip',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      routerDelegate: router.routerDelegate,
      routeInformationParser: router.routeInformationParser,
      routeInformationProvider: router.routeInformationProvider,
    );
  }
}

void headlessTask(bg.HeadlessEvent headlessEvent) async {
  debugPrint('[Headless] Olay alındı: ${headlessEvent.name}');

  if (headlessEvent.name == bg.Event.LOCATION) {
    bg.Location location = headlessEvent.event;
    debugPrint(
        '[Headless] Konum: ${location.coords.latitude}, ${location.coords.longitude}');

    // Burada konumu depolama veya API'ye gönderme işlemleri yapılabilir
    // Örneğin SharedPreferences veya SQLite kullanılarak konumlar kaydedilebilir

    // Dikkat: headless modda UI ile ilgili herhangi bir işlem yapılamaz!
  }
}
