import '../dashboard/dashboard_repository.dart';

/// [DashboardRepository] kept in memory; forgets everything on restart.
class InMemoryDashboardRepository implements DashboardRepository {
  // Keyed by the record (userId, groupCode).
  final _pinned = <(String, String), List<String>>{};

  @override
  Future<List<String>?> loadPinned({
    required String userId,
    required String groupCode,
  }) async {
    final saved = _pinned[(userId, groupCode)];
    return saved == null ? null : List.of(saved);
  }

  @override
  Future<void> savePinned({
    required String userId,
    required String groupCode,
    required List<String> featureIds,
  }) async {
    _pinned[(userId, groupCode)] = List.of(featureIds);
  }
}
