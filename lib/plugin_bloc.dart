import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';

class PluginBloc extends Bloc<PluginEvent, PluginState> {
  final FlutterP2pConnection flutterP2pConnection = FlutterP2pConnection();

  PluginBloc() : super(InitState()) {
    on(
      (event, emit) async {
        AppLifecycleListener(
          onStateChange: (state) {
            if (state == AppLifecycleState.paused) {
              flutterP2pConnection.unregister();
            } else if (state == AppLifecycleState.resumed) {
              flutterP2pConnection.register();
            }
          },
        );
        if (event is InitializePluginEvent) {
          bool status = await flutterP2pConnection.initialize();
          print('Initialized: $status');

          if (status) {
            await flutterP2pConnection.register();
            emit(InitializationSuccessState());
          } else {
            emit(InitializationFailState());
          }
        }
      },
    );
  }
}

abstract class PluginEvent {}

class InitializePluginEvent extends PluginEvent {}

abstract class PluginState {}

class InitState extends PluginState {}

class InitializationSuccessState extends PluginState {}

class InitializationFailState extends PluginState {}
