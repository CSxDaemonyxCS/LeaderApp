import 'dart:math';

import '../../../core/result/result.dart';
import '../domain/detachment_models.dart';
import '../domain/detachment_repository.dart';

class MockDetachmentRepository implements DetachmentRepository {
  MockDetachmentRepository();

  final _rand = Random(11);

  final List<Detachment> _seed = [
    const Detachment(
      id: 'd_dam_central',
      name: 'مفرزة دمشق المركزية',
      region: 'دمشق',
      mainCenter: 'مركز الشعلان',
      memberCount: 42,
      weeklyShiftCount: 21,
      coveragePercent: 92,
      status: DetachmentStatus.active,
      notes: 'أعلى تغطية في الأسبوعين الماضيين.',
    ),
    const Detachment(
      id: 'd_dam_rural',
      name: 'مفرزة ريف دمشق',
      region: 'ريف دمشق',
      mainCenter: 'مركز داريا',
      memberCount: 28,
      weeklyShiftCount: 15,
      coveragePercent: 78,
      status: DetachmentStatus.active,
    ),
    const Detachment(
      id: 'd_homs',
      name: 'مفرزة حمص',
      region: 'حمص',
      mainCenter: 'مركز الوعر',
      memberCount: 19,
      weeklyShiftCount: 10,
      coveragePercent: 84,
      status: DetachmentStatus.active,
    ),
    const Detachment(
      id: 'd_coast',
      name: 'مفرزة الساحل',
      region: 'اللاذقية',
      mainCenter: 'مركز اللاذقية',
      memberCount: 22,
      weeklyShiftCount: 12,
      coveragePercent: 88,
      status: DetachmentStatus.active,
    ),
    const Detachment(
      id: 'd_north_arch',
      name: 'مفرزة الشمال — مؤرشفة',
      region: 'حلب',
      mainCenter: 'مركز الأشرفية',
      memberCount: 0,
      weeklyShiftCount: 0,
      coveragePercent: 0,
      status: DetachmentStatus.archived,
    ),
  ];

  Future<void> _latency() => Future<void>.delayed(
        Duration(milliseconds: 400 + _rand.nextInt(400)),
      );

  @override
  Future<Result<List<Detachment>>> list({
    DetachmentStatus? filter,
    String? query,
  }) async {
    await _latency();
    Iterable<Detachment> out = _seed;
    if (filter != null) out = out.where((d) => d.status == filter);
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim();
      out = out.where((d) =>
          d.name.contains(q) ||
          d.mainCenter.contains(q) ||
          d.region.contains(q));
    }
    return Success(out.toList());
  }

  @override
  Future<Result<Detachment>> byId(String id) async {
    await _latency();
    final d = _seed.firstWhere(
      (e) => e.id == id,
      orElse: () => _seed.first,
    );
    return Success(d);
  }

  @override
  Future<Result<Detachment>> create({
    required String name,
    required String region,
    required String mainCenter,
    String? notes,
  }) async {
    await _latency();
    final d = Detachment(
      id: 'd_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      region: region,
      mainCenter: mainCenter,
      memberCount: 0,
      weeklyShiftCount: 0,
      coveragePercent: 0,
      status: DetachmentStatus.active,
      notes: notes,
    );
    _seed.add(d);
    return Success(d);
  }

  @override
  Future<Result<Detachment>> update(Detachment d) async {
    await _latency();
    final i = _seed.indexWhere((e) => e.id == d.id);
    if (i >= 0) _seed[i] = d;
    return Success(d);
  }

  @override
  Future<Result<DetachmentStats>> stats(String id) async {
    await _latency();
    return const Success(DetachmentStats(
      attendanceSeries: [72, 78, 81, 88, 84, 92, 90],
      coverageSeries: [70, 74, 78, 82, 86, 90, 92],
      stockSeries: [12, 18, 9, 22, 15, 30, 24],
    ));
  }
}
