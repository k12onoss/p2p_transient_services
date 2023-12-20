import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_direct/permission_bloc.dart';
import 'package:wifi_direct/plugin_bloc.dart';
import 'package:wifi_direct/router_delegate.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (_) => PermissionBloc()..add(CheckPermissionStatusEvent())),
        BlocProvider(
          create: (_) => PluginBloc()..add(InitializePluginEvent()),
        ),
      ],
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.transparent,
          statusBarColor: Colors.transparent,
        ),
        child: MaterialApp.router(
          routerConfig: routerConfiguration,
        ),
      ),
    );
  }
}
