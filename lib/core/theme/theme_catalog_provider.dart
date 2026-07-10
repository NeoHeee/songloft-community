import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_catalog.dart';
import 'theme_catalog_repository.dart';

final themeCatalogRepositoryProvider = Provider<ThemeCatalogRepository>((ref) {
  return ThemeCatalogRepository();
});

class ThemeCatalogNotifier extends AsyncNotifier<ThemeCatalog> {
  ThemeCatalogRepository get _repository =>
      ref.read(themeCatalogRepositoryProvider);

  @override
  Future<ThemeCatalog> build() {
    return _repository.loadCatalog();
  }

  Future<void> refreshCatalog() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.loadCatalog);
  }

  Future<ThemeCatalogDownload> downloadTheme(ThemeCatalogEntry entry) {
    return _repository.downloadTheme(entry);
  }
}

final themeCatalogProvider =
    AsyncNotifierProvider<ThemeCatalogNotifier, ThemeCatalog>(
      ThemeCatalogNotifier.new,
    );
