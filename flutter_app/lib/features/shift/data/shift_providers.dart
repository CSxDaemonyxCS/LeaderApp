import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result/result.dart';
import '../domain/shift_models.dart';
import '../domain/shift_repository.dart';
import 'mock_shift_repository.dart';

final shiftRepositoryProvider = Provider<ShiftRepository>((ref) {
  return MockShiftRepository();
});

final todaysShiftsProvider =
    FutureProvider.family<Result<List<Shift>>, String>((ref, detId) async {
  return ref.read(shiftRepositoryProvider).listForDetachmentToday(detId);
});
