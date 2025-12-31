import 'package:flutter/material.dart';

import '../../../services/services/auth_service.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () => signInWithWebUIProvider(context),
          icon: const Icon(Icons.login, size: 24),
          label: const Text(
            'Iniciar sesión con Google',
            style: TextStyle(fontSize: 18),
          ),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(200, 50), // 버튼 크기 설정
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // 둥근 모서리
            ),
          ),
        ),
      ),
    );
  }
}