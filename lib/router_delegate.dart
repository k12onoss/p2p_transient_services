import 'package:go_router/go_router.dart';
import 'package:wifi_direct/discovery_screen.dart';
import 'package:wifi_direct/home_screen.dart';

final routerConfiguration = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      name: 'Home',
      path: '/home',
      builder: (_, __) => const HomeScreen(),
      routes: [
        GoRoute(
          name: 'Discovery',
          path: 'discovery_screen',
          builder: (_, state) {
            final param = state.extra as bool;
            return DiscoveryScreen(isServer: param);
          },
          // routes: [
          //   GoRoute(
          //     name: 'Server',
          //     path: 'server_screen',
          //     builder: (_, __) => const ServerScreen(),
          //   ),
          //   GoRoute(
          //     name: 'Client',
          //     path: 'client_screen',
          //     builder: (_, __) => const ClientScreen(),
          //   ),
          // ],
        ),
      ],
    ),
  ],
);
