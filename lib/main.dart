import 'package:flutter/material.dart';
import 'package:safespace_doctor_app/config.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:safespace_doctor_app/navigation/navmanager.dart';
import 'package:safespace_doctor_app/authentication/auth_gate.dart';
import 'package:safespace_doctor_app/authentication/login_page.dart';
import 'package:safespace_doctor_app/authentication/regesration.dart';
import 'package:safespace_doctor_app/screens/appointment_screen.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
// Import for Android specific implementation
// Import for iOS specific implementation  

// Create a RouteObserver
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize WebView platform
  await _initializeWebView();
  
  await AppConfig.initializeSupabase(); // ✅ Initialize Supabase connection

  runApp(const MyApp());
}

Future<void> _initializeWebView() async {
  // Initialize WebView platform for different platforms
  if (WebViewPlatform.instance == null) {
    // Use WebKit for iOS and AndroidWebView for Android
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      WebViewPlatform.instance = WebKitWebViewPlatform();
    } else {
      WebViewPlatform.instance = AndroidWebViewPlatform();
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doctor Management App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      navigatorObservers: [routeObserver],
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const RegistrationScreen(),
        '/home': (context) => const NavManager(),
        '/chatbot': (context) => AppointmentScreen(),
      },
      home: const AuthGate(), // ✅ Routes to AuthGate
    );
  }
}