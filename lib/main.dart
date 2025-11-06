import 'package:flutter/material.dart';
import 'package:safespace_doctor_app/config.dart';
import 'package:safespace_doctor_app/navigation/navmanager.dart';
import 'package:safespace_doctor_app/authentication/auth_gate.dart';
import 'package:safespace_doctor_app/authentication/login_page.dart';
import 'package:safespace_doctor_app/authentication/regesration.dart';
import 'package:safespace_doctor_app/screens/appointment_screen.dart';




// Create a RouteObserver
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.initializeSupabase(); // ✅ Initialize Supabase connection

  runApp(const MyApp());
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