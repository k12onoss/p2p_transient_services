import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';

class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  final FlutterP2pConnection _flutterP2pConnection;

  DiscoveryBloc(this._flutterP2pConnection) : super(InitialState()) {
    on<DiscoveryEvent>(
      (event, emit) async {
        if (event is StartDiscoveryEvent) {
          emit(DiscoveringState());
          await _flutterP2pConnection.stopDiscovery();
          final status = await _flutterP2pConnection.discover();

          if (!status) {
            emit(DiscoveryFailedState());
          }
        }

        List<DiscoveredPeers> peers = [
          const DiscoveredPeers(
              deviceName: 'Jarvis',
              deviceAddress: 'address',
              isGroupOwner: false,
              isServiceDiscoveryCapable: true,
              primaryDeviceType: '',
              secondaryDeviceType: '',
              status: 0),
          const DiscoveredPeers(
              deviceName: 'Riptide',
              deviceAddress: 'address',
              isGroupOwner: false,
              isServiceDiscoveryCapable: true,
              primaryDeviceType: '',
              secondaryDeviceType: '',
              status: 0),
          const DiscoveredPeers(
              deviceName: 'Divyan',
              deviceAddress: 'address',
              isGroupOwner: false,
              isServiceDiscoveryCapable: true,
              primaryDeviceType: '',
              secondaryDeviceType: '',
              status: 0),
          const DiscoveredPeers(
              deviceName: 'Arya',
              deviceAddress: 'address',
              isGroupOwner: false,
              isServiceDiscoveryCapable: true,
              primaryDeviceType: '',
              secondaryDeviceType: '',
              status: 0),
        ];

        // TODO: Remove later
        emit(PeersDiscoveredState(peers));

        await emit.onEach(
          _flutterP2pConnection.streamPeers(),
          onData: (peers) {
            print(peers);
            if (peers.isNotEmpty) {
              emit(PeersDiscoveredState(peers));
            }
          },
          onError: (error, trace) {
            emit(DiscoveryFailedState());
          },
        );
      },
    );
  }
}

abstract class DiscoveryEvent {}

abstract class DiscoveryState {}

class InitialState extends DiscoveryState {}

class StartDiscoveryEvent extends DiscoveryEvent {}

class DiscoveringState extends DiscoveryState {}

class PeersDiscoveredState extends DiscoveryState {
  List<DiscoveredPeers> peers;

  PeersDiscoveredState(this.peers);
}

class DiscoveryFailedState extends DiscoveryState {}
