/// Stores each user's personal dashboard layout, separately in every group.
abstract interface class DashboardRepository {
  /// Pinned feature ids, in display order, or null if [userId] never
  /// customised their dashboard in group [groupCode].
  Future<List<String>?> loadPinned({
    required String userId,
    required String groupCode,
  });

  Future<void> savePinned({
    required String userId,
    required String groupCode,
    required List<String> featureIds,
  });
}
