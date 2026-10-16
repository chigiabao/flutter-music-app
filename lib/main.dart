import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/player_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    try {
      await Firebase.initializeApp();
    } catch (e2) {
      runApp(_SetupError('$e'));
      return;
    }
  }
  runApp(MusicApp(auth: AuthService(), player: PlayerController()));
}

ThemeData _theme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0D0B14),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF8B5CF6),
        secondary: Color(0xFFEC4899),
        surface: Color(0xFF171426),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0D0B14),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF171426),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF1E1A33),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: Color(0xFF8B5CF6),
        inactiveTrackColor: Color(0xFF2E294E),
        thumbColor: Colors.white,
        overlayColor: Color(0x338B5CF6),
      ),
    );

class MusicApp extends StatelessWidget {
  final AuthService auth;
  final PlayerController player;
  const MusicApp({super.key, required this.auth, required this.player});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Online',
      debugShowCheckedModeBanner: false,
      theme: _theme(),
      home: HomeScreen(auth: auth, player: player),
    );
  }
}

class _SetupError extends StatelessWidget {
  final String message;
  const _SetupError(this.message);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _theme(),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Chưa cấu hình Firebase.\n'
              'Hãy đặt google-services.json vào android/app rồi chạy lại.\n\n$message',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
