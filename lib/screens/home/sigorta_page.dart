import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../categories/all_categories_page.dart';
import '../service_listing/service_listing_page.dart';

/// Real route, reachable from the homepage's Sigorta card — reuses the same
/// category-grid shell as Araç Tamiri's "Tüm Kategoriler" page (see
/// AllCategoriesPage), parameterized with the Sigorta sub-service taxonomy.
/// Tapping a sub-service opens the shared ServiceListingPage, scoped to
/// hizmetTürü 'sigorta'.
class SigortaPage extends StatelessWidget {
  const SigortaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AllCategoriesPage(
      title: 'Sigorta',
      categories: MockData.sigortaCategories,
      onCategorySelected: (category) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ServiceListingPage(serviceName: category, hizmetTuru: 'sigorta'),
        ),
      ),
    );
  }
}
