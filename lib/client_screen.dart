import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wifi_direct/service_bloc.dart';

class ClientScreen extends StatelessWidget {
  final List<DiscoveredPeers> peers;

  const ClientScreen({super.key, required this.peers});

  @override
  Widget build(BuildContext context) {
    TextEditingController controller = TextEditingController();
    Size size = MediaQuery.sizeOf(context);

    void showSnack(String content) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(content)),
      );
    }

    Widget services() {
      return GridView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8.0,
          crossAxisSpacing: 8.0,
          childAspectRatio: 2.5,
        ),
        children: [
          GestureDetector(
            onTap: () {
              final map = {
                'service': 'location',
              };
              context
                  .read<ServiceBloc>()
                  .add(SendMessageEvent(jsonEncode(map)));
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromRGBO(247, 247, 249, 1),
                borderRadius: BorderRadius.circular(12.0),
              ),
              height: 150,
              width: 150,
              child: const Center(child: Text('Geolocation')),
            ),
          ),
          GestureDetector(
            onTap: () {
              ServiceBloc serviceBloc = context.read<ServiceBloc>();

              showDialog(
                context: context,
                builder: (context) {
                  void onPressed(String? text) {
                    final map = {
                      'service': 'smart reply',
                      'content': text ?? controller.text,
                    };
                    serviceBloc.add(SendMessageEvent(jsonEncode(map)));
                  }

                  return AlertDialog(
                    title: const Text('Send message'),
                    content: SizedBox(
                      height: 70,
                      width: size.width,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            suffixIcon: IconButton(
                              onPressed: () => onPressed(null),
                              icon: const Icon(Icons.send),
                            ),
                          ),
                          onSubmitted: onPressed,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromRGBO(247, 247, 249, 1),
                borderRadius: BorderRadius.circular(12.0),
              ),
              height: 150,
              width: 150,
              child: const Center(child: Text('Smart reply')),
            ),
          ),
        ],
      );
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

    return SingleChildScrollView(
      child: SizedBox(
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
                    "Choose a service\nprovider",
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
              child: Container(
                height: size.height,
                decoration: const BoxDecoration(
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                          return peersCard(
                            peers[index],
                          );
                        },
                      ),
                    ),
                    BlocConsumer<ServiceBloc, ServiceState>(
                      listener: (context, state) {
                        if (state is MessageReceivedState) {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('New message received'),
                                content: Text(state.message),
                              );
                            },
                          );
                        } else if (state is ConnectionSuccessState) {
                          showSnack('Connected to ${state.peerName}.');
                        }
                      },
                      builder: (context, state) {
                        print(state);
                        if (state is ConnectingState ||
                            state is OpeningSocketState) {
                          return const CircularProgressIndicator();
                        } else if (state is ConnectionSuccessState) {
                          return ElevatedButton(
                            onPressed: () => context
                                .read<ServiceBloc>()
                                .add(ConnectToSocketEvent()),
                            child: const Text('Connect to socket'),
                          );
                        } else if (state is ConnectionFailState) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text('Connection with ${state.peerName} failed.'),
                              ElevatedButton(
                                onPressed: () =>
                                    context.read<ServiceBloc>().add(
                                          ConnectToPeerEvent(
                                            state.peerName,
                                            state.peerAddress,
                                          ),
                                        ),
                                child: const Text('Connect again?'),
                              ),
                            ],
                          );
                        } else if (state is ConnectToSocketSuccessState ||
                            state is SendingMessageState ||
                            state is SendMessageSuccessState ||
                            state is SendMessageSuccessState ||
                            state is MessageReceivedState) {
                          return services();
                        } else if (state is ConnectToSocketFailState) {
                          return const Text('Connection to socket failed');
                        } else {
                          return const SizedBox();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
