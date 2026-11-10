import '../models/group.dart';

/// Where group memberships come from (demo data today, the server later).
abstract interface class GroupRepository {
  /// Every group [userId] belongs to, in display order. Empty if none.
  Future<List<Membership>> membershipsOf(String userId);
}
