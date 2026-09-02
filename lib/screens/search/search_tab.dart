import 'package:flutter/material.dart';

import '../../data/mechanic_directory_repository.dart';
import '../../models/mechanic.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/skeleton_loader.dart';
import '../../widgets/search/category_filter_bar.dart';
import '../../widgets/search/empty_search_state.dart';
import '../../widgets/search/mechanic_list_tile.dart';
import '../../widgets/search/sort_filter_bar.dart';
import '../mechanic_detail/mechanic_detail_page.dart';

/// The bottom-nav "Ara" tab — always scoped to hizmetTürü 'tamir' (the only
/// category this tab is reachable from today; see MainShell). Real
/// mechanicAccounts data now, not MockData: fetched once per tab instance,
/// then filtered/sorted client-side exactly like the MockData version did.
class SearchTab extends StatefulWidget {
  const SearchTab({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final _controller = TextEditingController();
  late final Future<List<Mechanic>> _future;
  String _query = '';
  String? _selectedCategory;
  SortMode _sortMode = SortMode.rating;
  bool _openOnly = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _future = MechanicDirectoryRepository().fetchByHizmetTuru('tamir');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Mechanic> _filteredResults(List<Mechanic> mechanics) {
    final query = _query.trim().toLowerCase();
    final results = mechanics.where((mechanic) {
      final matchesQuery =
          query.isEmpty ||
          mechanic.name.toLowerCase().contains(query) ||
          mechanic.specialty.toLowerCase().contains(query);
      final matchesCategory = _selectedCategory == null || mechanic.hizmetler.contains(_selectedCategory);
      final matchesOpen = !_openOnly || (mechanic.isOpen ?? false);
      return matchesQuery && matchesCategory && matchesOpen;
    }).toList();

    results.sort((a, b) {
      switch (_sortMode) {
        case SortMode.rating:
          return b.rating.compareTo(a.rating);
        case SortMode.price:
          final aPrice = a.priceMin;
          final bPrice = b.priceMin;
          if (aPrice == null && bPrice == null) return 0;
          if (aPrice == null) return 1;
          if (bPrice == null) return -1;
          return aPrice.compareTo(bPrice);
      }
    });
    return results;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text('Usta Ara', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 22)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: TextField(
              controller: _controller,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Usta adı veya sorun ara...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CategoryFilterBar(
              selected: _selectedCategory,
              onSelected: (value) => setState(() => _selectedCategory = value),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SortFilterBar(
              sortMode: _sortMode,
              onSortChanged: (mode) => setState(() => _sortMode = mode),
              openOnly: _openOnly,
              onOpenOnlyChanged: (value) => setState(() => _openOnly = value),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Mechanic>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const MechanicListSkeleton();
                }
                final results = _filteredResults(snapshot.data ?? const []);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                      child: Text(
                        '${results.length} usta bulundu',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                    Expanded(
                      child: results.isEmpty
                          ? const EmptySearchState()
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                              itemCount: results.length,
                              itemBuilder: (context, index) => MechanicListTile(
                                mechanic: results[index],
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => MechanicDetailPage(mechanic: results[index])),
                                ),
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
