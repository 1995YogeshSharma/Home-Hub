import '../core/models/group.dart';
import '../core/repositories/group_repository.dart';
import 'demo_data.dart';

/// [GroupRepository] backed by a list of memberships (demo data by default).
class InMemoryGroupRepository implements GroupRepository {
  InMemoryGroupRepository({this._memberships = DemoData.memberships});

  final List<Membership> _memberships;

  @override
  Future<List<Membership>> membershipsOf(String userId) async => [
    for (final m in _memberships)
      if (m.userId == userId) m,
  ];
}
