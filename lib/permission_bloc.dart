import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import 'package:permission_handler/permission_handler.dart';

//TODO: Improve permissions flow
class PermissionBloc extends Bloc<PermissionEvent, PermissionState> {
  FlutterP2pConnection flutterP2pConnection = FlutterP2pConnection();

  PermissionBloc() : super(PermissionDeniedState()) {
    on(
      (event, emit) async {
        if (event is CheckPermissionStatusEvent) {
          emit(PermissionRequestedState());
          final permissionStatus = await requestPermissions();

          if (permissionStatus) {
            final serviceStatus = await requestServices();
            if (!serviceStatus) {
              emit(PermissionServiceDisabledState());
            } else {
              emit(PermissionGrantedState());
            }
          } else {
            emit(PermissionDeniedState());
          }
        } else if (event is RequestPermissionEvent) {
          emit(PermissionRequestedState());

          final status = await requestPermissions() &&
              await checkPermissions() &&
              await checkServices();

          if (status) {
            emit(PermissionGrantedState());
          } else {
            emit(PermissionDeniedState());
          }
        } else if (event is EnableServiceEvent) {
          emit(PermissionRequestedState());

          final status = await requestServices() &&
              await checkPermissions() &&
              await checkServices();

          print(status);

          if (status) {
            emit(PermissionGrantedState());
          } else {
            emit(PermissionServiceDisabledState());
          }
        }
      },
    );
  }

  Future<bool> checkPermissions() async {
    return await Permission.location.isGranted &&
        await Permission.nearbyWifiDevices.isGranted;
  }

  Future<bool> checkServices() async {
    return await Permission.location.serviceStatus.isEnabled &&
        await flutterP2pConnection.checkWifiEnabled();
  }

  Future<bool> requestPermissions() async {
    return await Permission.nearbyWifiDevices.request().isGranted &&
        await Permission.location.request().isGranted;
  }

  Future<bool> requestServices() async {
    return await flutterP2pConnection.enableLocationServices() &&
        await flutterP2pConnection.enableWifiServices();
  }
}

abstract class PermissionEvent {}

class CheckPermissionStatusEvent extends PermissionEvent {}

class RequestPermissionEvent extends PermissionEvent {}

class EnableServiceEvent extends PermissionEvent {}

abstract class PermissionState {}

class PermissionRequestedState extends PermissionState {}

class PermissionGrantedState extends PermissionState {}

class PermissionDeniedState extends PermissionState {}

class PermissionServiceDisabledState extends PermissionState {}
