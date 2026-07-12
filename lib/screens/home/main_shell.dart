import 'package:flutter/material.dart';

import '../search/search_tab.dart';
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

  void _openSearch({String? category}) {
    setState(() {
      _searchCategory = category;
      _selectedIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeTab(
        onSearchTap: () => _openSearch(),
        onCategoryTap: (category) => _openSearch(category: category),
        onSeeAllPopular: () => _openSearch(),
        onSeeAllTopRated: () => _openSearch(),
      ),
      SearchTab(key: ValueKey(_searchCategory), initialCategory: _searchCategory),
      const PlaceholderTab(icon: Icons.event_note, label: 'Randevular'),
      const PlaceholderTab(icon: Icons.person_outline, label: 'Profil'),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Ana Sayfa'),
          NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: 'Ara'),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'Randevular',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
