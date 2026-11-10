import 'package:flutter_test/flutter_test.dart';
import 'package:home_hub_client/core/models/group.dart';
import 'package:home_hub_client/demo/demo_data.dart';
import 'package:home_hub_client/demo/in_memory_group_repository.dart';
import 'package:home_hub_client/demo/in_memory_user_repository.dart';

void main() {
  group('InMemoryUserRepository', () {
    test('Asha is signed in by default', () async {
      final user = await InMemoryUserRepository().currentUser();

      expect(user?.id, 'u-asha');
    });

    test('can simulate nobody signed in', () async {
      final repo = InMemoryUserRepository(signedIn: null);

      expect(await repo.currentUser(), isNull);
    });
  });

  group('InMemoryGroupRepository', () {
    test('Asha is admin of the family and member of the book club', () async {
      final memberships = await InMemoryGroupRepository().membershipsOf(
        'u-asha',
      );

      expect(memberships.map((m) => (m.group.code, m.role)).toList(), [
        ('sharma-family', GroupRole.admin),
        ('book-club', GroupRole.member),
      ]);
    });

    test('Ravi is a member of the family', () async {
      final memberships = await InMemoryGroupRepository().membershipsOf(
        DemoData.ravi.id,
      );

      expect(memberships.single.role, GroupRole.member);
    });

    test('an unknown user has no groups', () async {
      expect(await InMemoryGroupRepository().membershipsOf('nobody'), isEmpty);
    });
  });
}
