import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/appointment_request_store.dart';
import '../../main.dart' show pendingAppointmentsTabRequest;
import '../../mechanic/appointments/data/chat_message.dart';
import '../../mechanic/appointments/data/chat_repository.dart';
import '../../utils/identity.dart';
import '../appointments/appointments_tab.dart';
import '../appointments/customer_conversation_list_page.dart';
import '../categories/ac_climate_category_page.dart';
import '../categories/battery_electrical_category_page.dart';
import '../categories/body_paint_category_page.dart';
import '../categories/brake_system_category_page.dart';
import '../categories/exhaust_system_category_page.dart';
import '../categories/glass_lighting_category_page.dart';
import '../categories/motor_category_page.dart';
import '../categories/oil_change_category_page.dart';
import '../categories/periodic_maintenance_category_page.dart';
import '../categories/suspension_steering_category_page.dart';
import '../categories/tire_wheel_category_page.dart';
import '../categories/transmission_clutch_category_page.dart';
import '../search/search_tab.dart';
import '../service_listing/service_listing_page.dart';
import 'customer_profile_tab.dart';
import 'ekspertiz_page.dart';
import 'home_tab.dart';
import 'sigorta_page.dart';
import 'vehicle_repair_category_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Bottom-nav tab order below (tabs list in build()) — Randevularım is
  // index 2. Named here once so _onPendingAppointmentsTabRequest doesn't
  // carry a bare magic number.
  static const _appointmentsTabIndex = 2;

  int _selectedIndex = 0;
  String? _searchCategory;

  StreamSubscription<List<ChatSummary>>? _unreadChatsSubscription;
  List<ChatSummary> _unreadChats = [];

  @override
  void initState() {
    super.initState();
    AppointmentRequestStore.instance.addListener(_onAppointmentsChanged);

    // Single subscription for both the Mesajlar tab badge below and the
    // bell badge total (passed down into HomeTab/GreetingBar) — see
    // ChatRepository.watchUnreadChats.
    _unreadChatsSubscription = ChatRepository().watchUnreadChats(resolveCustomerId()).listen((chats) {
      setState(() => _unreadChats = chats);
    });

    // A notification tap (background or cold-start-via-getInitialMessage —
    // see main.dart's pendingAppointmentsTabRequest) may have already set
    // this before this MainShell was even created — consumed directly into
    // the initial value here (this contributes to the very first build, so
    // no setState is needed yet), rather than only relying on the listener
    // below, which fires solely on a *new* value arriving after this point.
    if (pendingAppointmentsTabRequest.value != null) {
      pendingAppointmentsTabRequest.value = null;
      _selectedIndex = _appointmentsTabIndex;
    }
    pendingAppointmentsTabRequest.addListener(_onPendingAppointmentsTabRequest);
  }

  void _onPendingAppointmentsTabRequest() {
    if (pendingAppointmentsTabRequest.value == null) return;
    pendingAppointmentsTabRequest.value = null; // consume once
    setState(() => _selectedIndex = _appointmentsTabIndex);
  }

  @override
  void dispose() {
    AppointmentRequestStore.instance.removeListener(_onAppointmentsChanged);
    pendingAppointmentsTabRequest.removeListener(_onPendingAppointmentsTabRequest);
    _unreadChatsSubscription?.cancel();
    super.dispose();
  }

  void _onAppointmentsChanged() => setState(() {});

  void _openSearch({String? category}) {
    setState(() {
      _searchCategory = category;
      _selectedIndex = 1;
    });
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
            MaterialPageRoute(builder: (_) => ServiceListingPage(serviceName: service, hizmetTuru: 'tamir')),
          ),
        ),
      ),
    );
  }

  /// Pushes the Araç Tamiri landing page — the same
  /// sub-category-label-to-page dispatch that used to run directly off
  /// HomeTab's onCategoryTap, moved here unchanged (see
  /// VehicleRepairCategoryPage's own doc comment).
  void _openVehicleRepair() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VehicleRepairCategoryPage(
          onCategoryTap: (category) {
            if (category == 'Periyodik Bakım') {
              _openServiceCategory((onSelected) => PeriodicMaintenanceCategoryPage(onServiceSelected: onSelected));
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
            } else if (category == 'Klima') {
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

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeTab(
        unreadMessageCount: _unreadChats.length,
        onCategoryTap: (category) {
          if (category == 'Araç Tamiri') {
            _openVehicleRepair();
          } else if (category == 'Ekspertiz') {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EkspertizPage()));
          } else if (category == 'Sigorta') {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SigortaPage()));
          }
        },
      ),
      SearchTab(key: ValueKey(_searchCategory), initialCategory: _searchCategory),
      const AppointmentsTab(),
      // Mesajlar opens the conversation list first; tapping a row is what
      // opens CustomerConversationPage (unchanged) — see
      // CustomerConversationListPage.
      const CustomerConversationListPage(),
      const CustomerProfileTab(),
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
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _unreadChats.isNotEmpty,
              label: Text('${_unreadChats.length}'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            selectedIcon: Badge(
              isLabelVisible: _unreadChats.isNotEmpty,
              label: Text('${_unreadChats.length}'),
              child: const Icon(Icons.chat_bubble),
            ),
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
