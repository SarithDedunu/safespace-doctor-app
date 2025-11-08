import 'package:flutter/material.dart';
import 'package:safespace_doctor_app/navigation/navbar.dart';
import 'package:safespace_doctor_app/screens/home_screen.dart';
import 'package:safespace_doctor_app/screens/patients_screen.dart';
import 'package:safespace_doctor_app/screens/appointment_screen.dart';
import 'package:safespace_doctor_app/screens/profile_screen.dart';


class NavManager extends StatefulWidget {
  const NavManager({super.key});

  @override
  State<NavManager> createState() => _NavManagerState();
}

class _NavManagerState extends State<NavManager> {
  int _selectedIndex = 0;

  // Use GlobalKey for HomeScreen instead of HomeScreenState
  final GlobalKey<HomeScreenState> _homeScreenKey = GlobalKey<HomeScreenState>();

  late final List<Widget> _screens = [
    HomeScreen(key: _homeScreenKey),
    const AppointmentScreen(),
    const PatientsScreen(),
    const ProfileScreen(),
  ];

  void _onTabChange(int index) {
    // If switching to home tab (index 0), refresh the home screen
    if (index == 0 && _selectedIndex != 0) {
      _homeScreenKey.currentState?.refreshData();
    }

    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavBar(
        selectedIndex: _selectedIndex,
        onTabChange: _onTabChange,
      ),
    );
  }
}