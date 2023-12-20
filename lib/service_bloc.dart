import 'dart:convert';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_smart_reply/google_mlkit_smart_reply.dart';

abstract class ServiceEvent {}

abstract class ServiceState {}

class ServiceBloc extends Bloc<ServiceEvent, ServiceState> {
  final FlutterP2pConnection _flutterP2pConnection;
  Stream<WifiP2PInfo>? _wifiInfoStream;
  WifiP2PInfo? _wifiP2pInfo;

  ServiceBloc(this._flutterP2pConnection) : super(InitialState()) {
    _wifiInfoStream = _flutterP2pConnection.streamWifiP2PInfo();
    _wifiInfoStream!.listen(
      (wifiP2pInfo) {
        _wifiP2pInfo = wifiP2pInfo;
        print(
            'wifi p2p info: $_wifiP2pInfo, isConnected: ${_wifiP2pInfo?.isConnected}, isGroupOwner: ${_wifiP2pInfo?.isGroupOwner}');
      },
    );

    on<GroupEvent>(
      (event, emit) async {
        if (event is CreateGroupEvent) {
          emit(CreatingGroupState());

          bool status = await _flutterP2pConnection.createGroup();
          if (status) {
            emit(GroupCreationSuccessState());
          } else {
            emit(GroupCreationFailState());
          }
        } else if (event is RemoveGroupEvent) {
          emit(RemovingGroupState());

          bool status = await _flutterP2pConnection.removeGroup();
          if (status) {
            emit(RemoveGroupSuccessState());
          } else {
            emit(RemoveGroupFailState());
          }
        }
      },
      transformer: sequential(),
    );

    on<ServiceEvent>(
      (event, emit) async {
        if (event is ConnectToPeerEvent) {
          emit(ConnectingState());

          final status = await _flutterP2pConnection.connect(event.peerAddress);
          if (status) {
            emit(ConnectionSuccessState(event.peerName, event.peerAddress));
          } else {
            emit(ConnectionFailState(event.peerName, event.peerAddress));
          }

          // TODO: Remove later
          emit(ConnectionSuccessState('Jarvis', 'address'));
        }

        void onConnect(String name, String address) {
          emit(ConnectToSocketSuccessState());
        }

        void transferUpdate(TransferUpdate transfer) {}

        void receiveMessageServer(dynamic message) async {
          final String result;
          final map = jsonDecode(message);
          emit(MessageReceivedState(message.toString()));
          switch (map['service']) {
            case 'location':
              {
                emit(CalculatingGeolocation());
                result = await location();
              }
            case 'smart reply':
              {
                emit(GeneratingSmartReply());
                result = await smartReply(map['content'].toString());
              }
            default:
              {
                result = '';
              }
          }

          _flutterP2pConnection.sendStringToSocket(result);
        }

        void receiveMessageClient(dynamic message) {
          emit(MessageReceivedState(message.toString()));
        }

        if (event is OpenSocketEvent) {
          if (_wifiP2pInfo != null) {
            emit(OpeningSocketState());

            bool socketStatus = await _flutterP2pConnection.startSocket(
              groupOwnerAddress: _wifiP2pInfo!.groupOwnerAddress,
              downloadPath: "/storage/emulated/0/Download/",
              onConnect: onConnect,
              transferUpdate: transferUpdate,
              receiveString: receiveMessageServer,
            );
            print('socket opened: $socketStatus');
            if (!socketStatus) {
              emit(OpenSocketFailState());
            } else {
              emit(OpenSocketSuccessState());
            }
          } else {
            emit(ConnectToSocketFailState());
          }
        } else if (event is ConnectToSocketEvent) {
          print(_wifiP2pInfo);
          if (_wifiP2pInfo != null) {
            emit(ConnectingToSocketState());

            bool socketStatus = await _flutterP2pConnection.connectToSocket(
              groupOwnerAddress: _wifiP2pInfo!.groupOwnerAddress,
              downloadPath: "/storage/emulated/0/Download/",
              onConnect: (address) => emit(ConnectToSocketSuccessState()),
              transferUpdate: (transfer) {},
              receiveString: receiveMessageClient,
            );
            print('connected to socket: $socketStatus');
            if (!socketStatus) {
              emit(ConnectToSocketFailState());
            }

            //TODO: Remove later
            emit(ConnectToSocketSuccessState());
          } else {
            emit(ConnectToSocketFailState());
          }
        } else if (event is SendMessageEvent) {
          emit(SendingMessageState());

          bool status = _flutterP2pConnection.sendStringToSocket(event.message);
          if (status) {
            emit(SendMessageSuccessState());
          } else {
            emit(SendMessageFailState());
          }
        }

        await emit.onEach(
          _wifiInfoStream!,
          onData: (wifiP2pInfo) {
            print('isConnected: ${_wifiP2pInfo?.isConnected}');
            if (wifiP2pInfo.isConnected) {
              print('clients: ${_wifiP2pInfo?.clients}');
              emit(ConnectionSuccessState(
                _wifiP2pInfo?.clients[0].deviceName ?? 'name',
                _wifiP2pInfo?.clients[0].deviceAddress ?? 'address',
              ));
            }
          },
        );
      },
    );
  }

  String encrypt(String input, int shift) {
    StringBuffer result = StringBuffer();

    for (int i = 0; i < input.length; i++) {
      int charCode = input.codeUnitAt(i);

      if (input[i].toUpperCase().compareTo('A') >= 0 &&
          input[i].toUpperCase().compareTo('Z') <= 0) {
        charCode =
            (charCode - 'A'.codeUnitAt(0) + shift) % 26 + 'A'.codeUnitAt(0);
      } else if (input[i].toUpperCase().compareTo('a') >= 0 &&
          input[i].toUpperCase().compareTo('z') <= 0) {
        charCode =
            (charCode - 'a'.codeUnitAt(0) + shift) % 26 + 'a'.codeUnitAt(0);
      }

      result.writeCharCode(charCode);
    }

    return result.toString();
  }

  String decrypt(String input, int shift) {
    StringBuffer result = StringBuffer();

    for (int i = 0; i < input.length; i++) {
      int charCode = input.codeUnitAt(i);

      if (input[i].toUpperCase().compareTo('A') >= 0 &&
          input[i].toUpperCase().compareTo('Z') <= 0) {
        charCode =
            (charCode - 'A'.codeUnitAt(0) - shift) % 26 + 'A'.codeUnitAt(0);
        if (charCode < 'A'.codeUnitAt(0)) {
          charCode += 26;
        }
      } else if (input[i].toUpperCase().compareTo('a') >= 0 &&
          input[i].toUpperCase().compareTo('z') <= 0) {
        charCode =
            (charCode - 'a'.codeUnitAt(0) - shift) % 26 + 'a'.codeUnitAt(0);
        if (charCode < 'a'.codeUnitAt(0)) {
          charCode += 26;
        }
      }

      result.writeCharCode(charCode);
    }

    return result.toString();
  }

  Future<String> location() async {
    final location = await Geolocator.getCurrentPosition();
    double lat = location.latitude;
    double long = location.longitude;
    return 'Latitude: $lat, Longitude: $long';
  }

  Future<String> smartReply(String message) async {
    SmartReply smartReply = SmartReply();
    smartReply.addMessageToConversationFromLocalUser(
      message.toString(),
      DateTime.now().millisecondsSinceEpoch,
    );

    final response = await smartReply.suggestReplies();
    final suggestions = response.suggestions;
    print(suggestions);
    return jsonEncode(suggestions);
  }
}

class InitialState extends ServiceState {}

//---------------------------------------------------------//

abstract class GroupEvent extends ServiceEvent {}

abstract class GroupState extends ServiceState {}

class CreateGroupEvent extends GroupEvent {}

class CreatingGroupState extends GroupState {}

class GroupCreationSuccessState extends GroupState {}

class GroupCreationFailState extends GroupState {}

class RemoveGroupEvent extends GroupEvent {}

class RemovingGroupState extends GroupState {}

class RemoveGroupSuccessState extends GroupState {}

class RemoveGroupFailState extends GroupState {}

//---------------------------------------------------------//

abstract class ConnectEvent extends ServiceEvent {}

abstract class ConnectState extends ServiceState {}

class ConnectToPeerEvent extends ConnectEvent {
  String peerName;
  String peerAddress;

  ConnectToPeerEvent(this.peerName, this.peerAddress);
}

class ConnectingState extends ConnectState {}

class ConnectionSuccessState extends ConnectState {
  String peerName;
  String peerAddress;

  ConnectionSuccessState(this.peerName, this.peerAddress);
}

class ConnectionFailState extends ConnectState {
  String peerName;
  String peerAddress;

  ConnectionFailState(this.peerName, this.peerAddress);
}

//---------------------------------------------------------//

abstract class SocketEvent extends ServiceEvent {}

abstract class SocketState extends ServiceState {}

class OpenSocketEvent extends SocketEvent {}

class OpeningSocketState extends SocketState {}

class OpenSocketSuccessState extends SocketState {}

class OpenSocketFailState extends SocketState {}

class ConnectToSocketEvent extends SocketEvent {}

class ConnectingToSocketState extends SocketState {}

class ConnectToSocketSuccessState extends SocketState {}

class ConnectToSocketFailState extends SocketState {}

//----------------------------------------------------------//

class SendMessageEvent extends SocketEvent {
  String message;

  SendMessageEvent(this.message);
}

class SendingMessageState extends SocketState {}

class SendMessageSuccessState extends SocketState {}

class SendMessageFailState extends SocketState {}

class MessageReceivedState extends SocketState {
  String message;

  MessageReceivedState(this.message);
}

class CalculatingGeolocation extends SocketState {}

class GeneratingSmartReply extends SocketState {}
