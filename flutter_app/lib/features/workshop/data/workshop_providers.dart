import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result/result.dart';
import '../domain/workshop_models.dart';
import '../domain/workshop_repository.dart';
import 'mock_workshop_repository.dart';

final workshopRepositoryProvider = Provider<WorkshopRepository>((ref) {
  return MockWorkshopRepository();
});

final workshopListProvider =
    FutureProvider<Result<List<Workshop>>>((ref) async {
  return ref.read(workshopRepositoryProvider).list();
});

final workshopByIdProvider =
    FutureProvider.family<Result<Workshop>, String>((ref, id) async {
  return ref.read(workshopRepositoryProvider).byId(id);
});

final workshopParticipantsProvider =
    FutureProvider.family<Result<List<WorkshopParticipant>>, String>(
        (ref, wsId) async {
  return ref.read(workshopRepositoryProvider).participants(wsId);
});
