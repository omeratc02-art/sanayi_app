import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../appointments/mechanic_appointments_screen.dart';
import '../profile/mechanic_profile_screen.dart';
import 'mechanic_home_screen.dart';

/// Navigation shell for the mechanic-facing module — three-tab bottom
/// navigation switching between the placeholder screens. Notifications has
/// no tab of its own; it's reached only via the bell in the Home header
/// (see MechanicHomeScreen), which will eventually navigate to a dedicated
/// notifications page. Structure only; see the TODO in main.dart for how
/// this page will eventually be selected.
class MechanicHomePage extends StatefulWidget {
  const MechanicHomePage({super.key});

  @override
  State<MechanicHomePage> createState() => _MechanicHomePageState();
}

class _MechanicHomePageState extends State<MechanicHomePage> {
  int _selectedIndex = 0;

  static const _screens = [
    MechanicHomeScreen(),
    MechanicAppointmentsScreen(),
    MechanicProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            activeIcon: Icon(Icons.event_note),
            label: 'Randevular',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
