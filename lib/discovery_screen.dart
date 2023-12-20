import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_direct/client_screen.dart';
import 'package:wifi_direct/discovery_bloc.dart';
import 'package:wifi_direct/plugin_bloc.dart';
import 'package:wifi_direct/server_screen.dart';
import 'package:wifi_direct/service_bloc.dart';

class DiscoveryScreen extends StatelessWidget {
  final bool isServer;

  const DiscoveryScreen({super.key, required this.isServer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(18, 26, 28, 1),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color.fromRGBO(18, 26, 28, 1),
      body: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) {
              if (isServer) {
                return ServiceBloc(
                    context.read<PluginBloc>().flutterP2pConnection)
                  ..add(CreateGroupEvent());
              } else {
                return ServiceBloc(
                    context.read<PluginBloc>().flutterP2pConnection);
              }
            },
          ),
          BlocProvider(
            create: (context) =>
                DiscoveryBloc(context.read<PluginBloc>().flutterP2pConnection)
                  ..add(StartDiscoveryEvent()),
          ),
        ],
        child: BlocBuilder<DiscoveryBloc, DiscoveryState>(
          builder: (context, state) {
            print(state);
            if (state is DiscoveringState) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is PeersDiscoveredState) {
              // List<DiscoveredPeers> peers = [];
              // if (isServer) {
              //   for (DiscoveredPeers peer in state.peers) {
              //     if (!peer.isGroupOwner) {
              //       peers.add(peer);
              //     }
              //   }
              // } else {
              //   for (DiscoveredPeers peer in state.peers) {
              //     if (peer.isGroupOwner) {
              //       peers.add(peer);
              //     }
              //   }
              // }
              if (isServer) {
                return ServerScreen(peers: state.peers);
              } else {
                return ClientScreen(peers: state.peers);
              }
            } else if (state is DiscoveryFailedState) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Discovery failed.'),
                    ElevatedButton(
                      onPressed: () => context
                          .read<DiscoveryBloc>()
                          .add(StartDiscoveryEvent()),
                      child: const Text('Restart discovery'),
                    ),
                  ],
                ),
              );
            } else {
              return const SizedBox();
            }
          },
        ),
      ),
    );
  }
}
