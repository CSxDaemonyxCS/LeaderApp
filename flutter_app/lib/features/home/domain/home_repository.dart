import '../../../core/result/result.dart';
import 'home_models.dart';

abstract class HomeRepository {
  Future<Result<HomeSummary>> summary();
}
