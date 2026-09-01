import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result/result.dart';
import '../domain/team_models.dart';
import '../domain/team_repository.dart';
import 'mock_team_repository.dart';

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  return MockTeamRepository();
});

final teamListProvider =
    FutureProvider.family<Result<List<TeamMember>>, String>((ref, detId) async {
  return ref.read(teamRepositoryProvider).listForDetachment(detId);
});
