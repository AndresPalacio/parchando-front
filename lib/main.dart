import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:parchando/services/services/amplify_config.dart';
import 'package:parchando/widgets/auth_handler.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await _configureAmplify();
    runApp(const MyApp());
  } on AmplifyException catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text("Error configuring Amplify: ${e.message}"),
          ),
        ),
      ),
    );
  }
}

Future<void> _configureAmplify() async {
  try {
    await AppAmplifyConfig.configure();
  } on Exception catch (e) {
    safePrint('Error configuring Amplify: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Parchando',
      theme: ThemeData(
        useMaterial3: true,
        // Colores principales basados en el home
        primaryColor: const Color(0xFF1E2B45), // Azul oscuro principal
        scaffoldBackgroundColor: const Color(0xFFF8F7FF), // Fondo morado/lavanda sutil
        brightness: Brightness.light,
        
        // ColorScheme para Material 3
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF1E2B45),
          secondary: const Color(0xFF2E3E5C),
          surface: Colors.white,
          background: const Color(0xFFF8F7FF),
          error: Colors.red,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.black87,
          onBackground: Colors.black87,
        ),
        
        // AppBar
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
          titleTextStyle: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        
        // Cards
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
        ),
        
        // Input decoration
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: const Color(0xFF1E2B45).withOpacity(0.3),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        
        // Buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E2B45),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF1E2B45),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        // Bottom Navigation Bar
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF1E2B45),
          unselectedItemColor: Colors.grey[400],
          elevation: 0,
          type: BottomNavigationBarType.fixed,
        ),
        
        // Dividers
        dividerTheme: DividerThemeData(
          color: Colors.grey[200],
          thickness: 1,
        ),
        
        // Shadows para cards (usando boxShadow en lugar de elevation)
        shadowColor: Colors.black.withOpacity(0.05),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF1E2B45),
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        brightness: Brightness.dark,
        
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF2E3E5C),
          secondary: const Color(0xFF1E2B45),
          surface: const Color(0xFF2A2A3E),
          background: const Color(0xFF1A1A2E),
          error: Colors.red,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white,
          onBackground: Colors.white,
        ),
        
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2A2A3E),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        
        cardTheme: CardThemeData(
          color: const Color(0xFF2A2A3E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF2A2A3E),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
        ),
      ),
      themeMode: ThemeMode.light, // Forzar tema claro para mantener consistencia
      home: const AuthHandler(),
    );
  }
}
