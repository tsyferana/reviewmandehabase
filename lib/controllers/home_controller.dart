import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/business_model.dart';
import '../models/category_model.dart';
import '../services/location_sim_service.dart';
import '../services/mock_data_service.dart';

final mockDataServiceProvider = Provider<MockDataService>((ref) {
  return MockDataService();
});

final locationSimServiceProvider = Provider<LocationSimService>((ref) {
  return LocationSimService();
});

final homeControllerProvider =
    AsyncNotifierProvider<HomeController, HomeState>(HomeController.new);

class HomeController extends AsyncNotifier<HomeState> {
  @override
  Future<HomeState> build() async {
    return _loadHome();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<HomeState>();
    state = await AsyncValue.guard(_loadHome);
  }

  Future<HomeState> _loadHome() async {
    final mockDataService = ref.read(mockDataServiceProvider);
    final locationService = ref.read(locationSimServiceProvider);

    final results = await Future.wait([
      locationService.getCurrentCity(),
      mockDataService.getCategories(),
      mockDataService.getBusinesses(),
      mockDataService.getUnreadNotificationsCount(),
    ]);

    final city = results[0] as String;
    final categories = results[1] as List<CategoryModel>;
    final businesses = results[2] as List<BusinessModel>;
    final unreadNotificationsCount = results[3] as int;

    final popularBusinesses =
        businesses.where((business) => business.isPopular).toList()
          ..sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    final topRatedBusinesses = [...businesses]
      ..sort((a, b) => b.rating.compareTo(a.rating));
    final nearbyBusinesses = [...businesses]
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    return HomeState(
      city: city,
      unreadNotificationsCount: unreadNotificationsCount,
      categories: categories,
      popularBusinesses: popularBusinesses,
      topRatedBusinesses: topRatedBusinesses.take(6).toList(),
      nearbyBusinesses: nearbyBusinesses.take(6).toList(),
    );
  }
}

class HomeState {
  const HomeState({
    required this.city,
    required this.unreadNotificationsCount,
    required this.categories,
    required this.popularBusinesses,
    required this.topRatedBusinesses,
    required this.nearbyBusinesses,
  });

  final String city;
  final int unreadNotificationsCount;
  final List<CategoryModel> categories;
  final List<BusinessModel> popularBusinesses;
  final List<BusinessModel> topRatedBusinesses;
  final List<BusinessModel> nearbyBusinesses;
}
