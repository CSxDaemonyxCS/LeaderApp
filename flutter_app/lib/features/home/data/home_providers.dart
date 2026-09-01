import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result/result.dart';
import '../domain/home_models.dart';
import '../domain/home_repository.dart';
import 'mock_home_repository.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return MockHomeRepository();
});

final homeSummaryProvider = FutureProvider<Result<HomeSummary>>((ref) async {
  return ref.read(homeRepositoryProvider).summary();
});
