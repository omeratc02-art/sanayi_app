import 'package:flutter/material.dart';

import '../../models/category.dart';
import '../../theme/app_theme.dart';
import '../../widgets/categories/category_grid.dart';

/// Shared "category grid with search" shell — reused as-is for Araç
/// Tamiri's "Tüm Kategoriler" page and for the Ekspertiz/Sigorta category
/// grids (see EkspertizPage/SigortaPage), just parameterized by title and
/// category list rather than one bespoke screen per category.
class AllCategoriesPage extends StatefulWidget {
  const AllCategoriesPage({
    super.key,
    this.title = 'Tüm Kategoriler',
    required this.categories,
    required this.onCategorySelected,
  });

  final String title;
  final List<ServiceCategory> categories;
  final ValueChanged<String> onCategorySelected;

  @override
  State<AllCategoriesPage> createState() => _AllCategoriesPageState();
}

class _AllCategoriesPageState extends State<AllCategoriesPage> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final filteredCategories = query.isEmpty
        ? widget.categories
        : widget.categories.where((category) => category.label.toLowerCase().contains(query)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Kategori ara...',
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
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: SingleChildScrollView(
                child: CategoryGrid(categories: filteredCategories, onCategoryTap: widget.onCategorySelected),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
