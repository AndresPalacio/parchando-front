import 'package:flutter/material.dart';
import 'package:parchando/screens/presentation/pages/auth_screen.dart';
import 'package:parchando/screens/home_screen.dart';

import '../services/services/auth_service.dart';

class AuthHandler extends StatefulWidget {
  const AuthHandler({super.key});

  @override
  State<AuthHandler> createState() => _AuthHandlerState();
}

class _AuthHandlerState extends State<AuthHandler> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isUserSignedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        } else {
          final isSignedIn = snapshot.data ?? false;
          return isSignedIn ? const HomeScreen() : const AuthScreen();

        }
      },
    );
  }
}
