import 'package:flutter/material.dart';

import '../../data/appointment_request_store.dart';
import '../appointments/appointments_tab.dart';
import '../appointments/customer_conversation_list_page.dart';
import '../categories/ac_climate_category_page.dart';
import '../categories/all_categories_page.dart';
import '../categories/battery_electrical_category_page.dart';
import '../categories/body_paint_category_page.dart';
import '../categories/brake_system_category_page.dart';
import '../categories/exhaust_system_category_page.dart';
import '../categories/glass_lighting_category_page.dart';
import '../categories/maintenance_major_detail_page.dart';
import '../categories/maintenance_routine_detail_page.dart';
import '../categories/maintenance_subcategory_page.dart';
import '../categories/motor_category_page.dart';
import '../categories/oil_change_category_page.dart';
import '../categories/suspension_steering_category_page.dart';
import '../categories/tire_wheel_category_page.dart';
import '../categories/transmission_clutch_category_page.dart';
import '../search/search_tab.dart';
import '../service_listing/service_listing_page.dart';
import 'home_tab.dart';
import 'placeholder_tab.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  String? _searchCategory;

  @override
  void initState() {
    super.initState();
    AppointmentRequestStore.instance.addListener(_onAppointmentsChanged);
  }

  @override
  void dispose() {
    AppointmentRequestStore.instance.removeListener(_onAppointmentsChanged);
    super.dispose();
  }

  void _onAppointmentsChanged() => setState(() {});

  void _openSearch({String? category}) {
    setState(() {
      _searchCategory = category;
      _selectedIndex = 1;
    });
  }

  void _openAllCategories() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AllCategoriesPage(
          onCategorySelected: (category) {
            Navigator.of(context).pop();
            // Only a few categories have dedicated pages reachable from
            // this list (they aren't on the Home screen's row); every
            // other category here keeps its existing search behavior.
            if (category == 'Klima') {
              _openServiceCategory((onSelected) => AcClimateCategoryPage(onServiceSelected: onSelected));
            } else if (category == 'Süspansiyon & Direksiyon') {
              _openServiceCategory(
                (onSelected) => SuspensionSteeringCategoryPage(onServiceSelected: onSelected),
              );
            } else if (category == 'Kaporta & Boya') {
              _openServiceCategory((onSelected) => BodyPaintCategoryPage(onServiceSelected: onSelected));
            } else if (category == 'Cam & Aydınlatma') {
              _openServiceCategory((onSelected) => GlassLightingCategoryPage(onServiceSelected: onSelected));
            } else if (category == 'Egzoz Sistemi') {
              _openServiceCategory((onSelected) => ExhaustSystemCategoryPage(onServiceSelected: onSelected));
            } else {
              _openSearch(category: category);
            }
          },
        ),
      ),
    );
  }

  void _openPeriodicMaintenance() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MaintenanceSubcategoryPage(
          onRoutineMaintenanceSelected: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MaintenanceRoutineDetailPage()),
          ),
          onMajorMaintenanceSelected: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MaintenanceMajorDetailPage()),
          ),
        ),
      ),
    );
  }

  /// Shared push for the "category landing page → service listing" pattern
  /// (see [OilChangeCategoryPage], [BrakeSystemCategoryPage], etc.): every
  /// such landing page takes a single `ValueChanged<String>` that should
  /// open the shared Service Listing screen for the selected service.
  void _openServiceCategory(Widget Function(ValueChanged<String> onServiceSelected) pageBuilder) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => pageBuilder(
          (service) => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ServiceListingPage(serviceName: service)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeTab(
        onCategoryTap: (category) {
          if (category == 'Tüm Hizmetler') {
            _openAllCategories();
          } else if (category == 'Periyodik Bakım') {
            _openPeriodicMaintenance();
          } else if (category == 'Yağ Değişimi') {
            _openServiceCategory((onSelected) => OilChangeCategoryPage(onServiceSelected: onSelected));
          } else if (category == 'Fren Sistemi') {
            _openServiceCategory((onSelected) => BrakeSystemCategoryPage(onServiceSelected: onSelected));
          } else if (category == 'Motor') {
            _openServiceCategory((onSelected) => MotorCategoryPage(onServiceSelected: onSelected));
          } else if (category == 'Akü & Elektrik') {
            _openServiceCategory((onSelected) => BatteryElectricalCategoryPage(onServiceSelected: onSelected));
          } else if (category == 'Lastik & Jant') {
            _openServiceCategory((onSelected) => TireWheelCategoryPage(onServiceSelected: onSelected));
          } else if (category == 'Şanzıman ve Debriyaj') {
            _openServiceCategory(
              (onSelected) => TransmissionClutchCategoryPage(onServiceSelected: onSelected),
            );
          } else {
            _openSearch(category: category);
          }
        },
        onSeeAllCategories: _openAllCategories,
      ),
      SearchTab(key: ValueKey(_searchCategory), initialCategory: _searchCategory),
      const AppointmentsTab(),
      // Mesajlar opens the conversation list first; tapping a row is what
      // opens CustomerConversationPage (unchanged) — see
      // CustomerConversationListPage.
      const CustomerConversationListPage(),
      const PlaceholderTab(icon: Icons.person_outline, label: 'Profil'),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Ara',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: AppointmentRequestStore.instance.hasActionNeeded,
              child: const Icon(Icons.event_note_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: AppointmentRequestStore.instance.hasActionNeeded,
              child: const Icon(Icons.event_note),
            ),
            label: 'Randevularım',
          ),
          const NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Mesajlar',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
