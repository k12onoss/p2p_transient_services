import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wifi_direct/permission_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.sizeOf(context);
    Widget home() {
      return SizedBox(
        height: size.height,
        child: Stack(
          children: [
            Container(
              height: size.height * 0.7,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  alignment: Alignment(0, 1),
                  fit: BoxFit.cover,
                  image: AssetImage("asset/people.jpg"),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              width: size.width,
              height: size.height * 0.43,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(18, 26, 28, 1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: "I would like to join",
                            style: TextStyle(
                              height: 1.4,
                              fontSize: 26.0,
                              color: Colors.white,
                            ),
                          ),
                          TextSpan(
                            text: " the Network as",
                            style: TextStyle(
                              fontSize: 26.0,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32.0),
                    ElevatedButton(
                      style: ButtonStyle(
                        shape: MaterialStateProperty.all(
                          const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      onPressed: () => context.goNamed(
                        'Discovery',
                        extra: true,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'Service Provider',
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Color.fromRGBO(18, 26, 28, 1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      style: ButtonStyle(
                        shape: MaterialStateProperty.all(
                          const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      onPressed: () => context.goNamed(
                        'Discovery',
                        extra: false,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'Service Consumer',
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Color.fromRGBO(18, 26, 28, 1),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: BlocBuilder<PermissionBloc, PermissionState>(
          builder: (context, state) {
            if (state is PermissionRequestedState) {
              return const CircularProgressIndicator();
            } else if (state is PermissionDeniedState) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Please grant the required permissions'),
                  ElevatedButton(
                    onPressed: () => context
                        .read<PermissionBloc>()
                        .add(RequestPermissionEvent()),
                    child: const Text('Request permissions'),
                  ),
                ],
              );
            } else if (state is PermissionServiceDisabledState) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Please enable the required services'),
                  ElevatedButton(
                    onPressed: () => context
                        .read<PermissionBloc>()
                        .add(EnableServiceEvent()),
                    child: const Text('Enable services'),
                  ),
                ],
              );
            } else if (state is PermissionGrantedState) {
              return home();
            } else {
              return const SizedBox();
            }
          },
        ),
      ),
    );
  }
}
