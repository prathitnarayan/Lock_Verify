import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_auth/pages/home_page.dart';
import 'package:qr_code_auth/pages/app_lock.dart'; // ✅ Ensure this path is correct
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AppLockWrapper(child: MyApp())); // ✅ Wrap the root app
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MFA Authenticator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AnimatedSplashScreen(
        duration: 1500,
        splash: Image.asset('lib/assets/icons/Logo_qr_au.png', height: 250),
        splashIconSize: 250,
        backgroundColor: Colors.white,
        splashTransition: SplashTransition.fadeTransition,
        nextScreen: HomePage(),
      ),
    );
  }
}
