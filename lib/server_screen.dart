import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wifi_direct/plugin_bloc.dart';
import 'package:wifi_direct/service_bloc.dart';

class ServerScreen extends StatelessWidget {
  final List<DiscoveredPeers> peers;

  const ServerScreen({super.key, required this.peers});

  @override
  Widget build(BuildContext context) {
    ValueNotifier<List<String>> logs = ValueNotifier<List<String>>([]);

    void showSnack(String content) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(content)));
    }

    Widget peersCard(DiscoveredPeers peer) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: GestureDetector(
          onTap: () {
            context.read<ServiceBloc>().add(
                  ConnectToPeerEvent(
                    peer.deviceName,
                    peer.deviceAddress,
                  ),
                );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(247, 247, 249, 1),
              borderRadius: BorderRadius.circular(12.0),
            ),
            height: 150,
            width: 150,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset('asset/svg/mobile.svg'),
                const SizedBox(height: 5.0),
                Text(
                  peer.deviceName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16.0,
                    color: Color.fromRGBO(20, 20, 20, 0.96),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }

    Size size = MediaQuery.sizeOf(context);
    return SizedBox(
      height: size.height,
      child: Stack(
        children: [
          Container(
            height: 100.0,
            padding: const EdgeInsets.only(left: 24.0),
            child: Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: size.width,
                child: const Text(
                  "Choose a service\nconsumer",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32.0,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 130.0,
            width: size.width,
            height: size.height,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40.0),
                  topRight: Radius.circular(40.0),
                ),
              ),
            ),
          ),
          Positioned(
            top: 130.0,
            height: size.height,
            width: size.width,
            child: Column(
              children: [
                SizedBox(
                  height: 230,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      vertical: 40,
                      horizontal: 20,
                    ),
                    itemCount: peers.length,
                    itemBuilder: (context, index) {
                      return peersCard(peers[index]);
                    },
                  ),
                ),
                BlocConsumer<ServiceBloc, ServiceState>(
                  listener: (context, state) async {
                    if (state is RemoveGroupSuccessState) {
                      showSnack('Group removed');
                      context.read<ServiceBloc>().add(CreateGroupEvent());
                    } else if (state is MessageReceivedState) {
                      String? ip = await context
                          .read<PluginBloc>()
                          .flutterP2pConnection
                          .getIPAddress();
                      final json = jsonDecode(state.message);
                      final time = DateTime.now().toString();
                      logs.value.add(
                          '$time: $ip: ${json['service']} ${json['content']}');
                    } else if (state is CalculatingGeolocation) {
                      logs.value.add('Fetching geolocation');
                    } else if (state is GeneratingSmartReply) {
                      logs.value.add('Generating smart reply');
                    }
                  },
                  builder: (context, state) {
                    print(state);
                    if (state is CreatingGroupState ||
                        state is ConnectingState ||
                        state is OpeningSocketState) {
                      return const CircularProgressIndicator();
                    } else if (state is GroupCreationSuccessState) {
                      return const Text('Group created');
                    } else if (state is ConnectionSuccessState) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('Connected to ${state.peerName}.'),
                          ElevatedButton(
                            onPressed: () => context
                                .read<ServiceBloc>()
                                .add(OpenSocketEvent()),
                            child: const Text('Open socket'),
                          ),
                        ],
                      );
                    } else if (state is ConnectionFailState) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('Connection with ${state.peerName} failed.'),
                          ElevatedButton(
                            onPressed: () => context.read<ServiceBloc>().add(
                                  ConnectToPeerEvent(
                                    state.peerName,
                                    state.peerAddress,
                                  ),
                                ),
                            child: const Text('Connect again?'),
                          ),
                        ],
                      );
                    } else if (state is OpenSocketSuccessState) {
                      return const Text('Socket opened');
                    } else if (state is OpenSocketFailState) {
                      return const Text('Socket open failed');
                    } else if (state is ConnectToSocketSuccessState ||
                        state is SendingMessageState ||
                        state is SendMessageSuccessState ||
                        state is SendMessageSuccessState ||
                        state is MessageReceivedState ||
                        state is GeneratingSmartReply ||
                        state is CalculatingGeolocation) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: ColoredBox(
                            color: Colors.black,
                            child: SizedBox(
                              height: 280,
                              child: ValueListenableBuilder(
                                valueListenable: logs,
                                builder: (context, value, _) {
                                  return SingleChildScrollView(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: List.generate(
                                        value.length,
                                        (index) => Text(
                                          value[index],
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    } else if (state is ConnectToSocketFailState) {
                      return const Text('Connection to socket failed');
                    } else if (state is GroupCreationFailState) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('Group creation failed'),
                          ElevatedButton(
                            onPressed: () => context
                                .read<ServiceBloc>()
                                .add(RemoveGroupEvent()),
                            child: const Text('Remove group and try again?'),
                          ),
                        ],
                      );
                    } else {
                      return const SizedBox();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
