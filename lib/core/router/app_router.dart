import 'package:flutter/material.dart';
import 'package:marti_case/data/models/route_history_model.dart';
import 'package:marti_case/screens/views/map_screen.dart';
import 'package:marti_case/screens/views/home_screen.dart';
import 'package:marti_case/screens/views/route_map_screen.dart';

class AppRouter {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final AppRouterDelegate routerDelegate = AppRouterDelegate();

  final RouteInformationParser<Object> routeInformationParser =
      AppRouteInformationParser();

  final RouteInformationProvider routeInformationProvider =
      PlatformRouteInformationProvider(
    initialRouteInformation: const RouteInformation(
      location: '/',
    ),
  );
  void navigateToHome() {
    routerDelegate.navigateToHome();
  }

  void navigateToMap() {
    routerDelegate.navigateToMap();
  }

  Future<bool> pop<T extends Object?>([T? result]) async {
    if (navigatorKey.currentState?.canPop() ?? false) {
      navigatorKey.currentState!.pop(result);
      return true;
    }

    return await routerDelegate.popRoute();
  }
}

class AppRouteConfiguration {
  final String location;

  AppRouteConfiguration({
    required this.location,
  });

  static AppRouteConfiguration home = AppRouteConfiguration(location: '/');
  static AppRouteConfiguration map = AppRouteConfiguration(location: '/map');
  static AppRouteConfiguration routeMap =
      AppRouteConfiguration(location: '/route_map');
}

class AppRouterDelegate extends RouterDelegate<Object>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Object> {
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  AppRouteConfiguration _configuration = AppRouteConfiguration.home;

  AppRouteConfiguration get configuration => _configuration;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: [
        const MaterialPage(
          key: ValueKey('HomeScreen'),
          child: HomeScreen(),
        ),
        if (_configuration.location == '/map')
          const MaterialPage(
            key: ValueKey('MapScreen'),
            child: MapScreen(),
          ),
        if (_isRouteMapVisible && _selectedRoute != null)
          MaterialPage(
            key: const ValueKey('RouteMapScreen'),
            child: RouteMapScreen(route: _selectedRoute!),
          ),
      ],
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }

        if (_configuration.location == '/map') {
          _configuration = AppRouteConfiguration.home;
          notifyListeners();
        }

        if (_isRouteMapVisible) {
          _isRouteMapVisible = false;
          notifyListeners();
          return true;
        }

        return true;
      },
    );
  }

  RouteHistoryModel? _selectedRoute;
  bool _isRouteMapVisible = false;

  void navigateToRouteMap(RouteHistoryModel route) {
    _selectedRoute = route;
    _isRouteMapVisible = true;
    notifyListeners();
  }

  void navigateToHome() {
    _configuration = AppRouteConfiguration.home;
    notifyListeners();
  }

  void navigateToMap() {
    _configuration = AppRouteConfiguration.map;
    notifyListeners();
  }

  @override
  Future<bool> popRoute() async {
    if (_configuration.location != '/') {
      _configuration = AppRouteConfiguration.home;
      notifyListeners();
      return true;
    }
    return false;
  }

  @override
  Future<void> setNewRoutePath(configuration) async {
    //TODO: implement for deeplink
    return;
  }
}

class AppRouteInformationParser extends RouteInformationParser<Object> {
  @override
  Future<Object> parseRouteInformation(
      RouteInformation routeInformation) async {
    final String location = routeInformation.uri.path;

    if (location == '') {
      return AppRouteConfiguration.home;
    }

    if (location == '/map') {
      return AppRouteConfiguration.map;
    }

    if (location == '/route_map') {
      return AppRouteConfiguration.routeMap;
    }

    return AppRouteConfiguration.home;
  }

  @override
  RouteInformation? restoreRouteInformation(configuration) {
    if (configuration is AppRouteConfiguration) {
      return RouteInformation(uri: Uri.parse(configuration.location));
    }
    return null;
  }
}
