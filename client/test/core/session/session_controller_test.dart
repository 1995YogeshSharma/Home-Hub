import 'package:flutter_test/flutter_test.dart';
import 'package:home_hub_client/core/models/group.dart';
import 'package:home_hub_client/core/session/session_controller.dart';
import 'package:home_hub_client/demo/in_memory_group_repository.dart';
import 'package:home_hub_client/demo/in_memory_user_repository.dart';

void main() {
  test('has no session before restore', () {
    final controller = SessionController(
      users: InMemoryUserRepository(),
      groups: InMemoryGroupRepository(),
    );

    expect(controller.session, isNull);
  });

  test('restore builds a session in the first group', () async {
    final controller = SessionController(
      users: InMemoryUserRepository(),
      groups: InMemoryGroupRepository(),
    );

    await controller.restore();

    final session = controller.requireSession;
    expect(session.user.displayName, 'Asha');
    expect(session.group.name, 'Sharma Family');
    expect(session.role, GroupRole.admin);
    expect(session.memberships, hasLength(2));
  });

  test('restore notifies listeners once', () async {
    final controller = SessionController(
      users: InMemoryUserRepository(),
      groups: InMemoryGroupRepository(),
    );
    var calls = 0;
    controller.addListener(() => calls++);

    await controller.restore();

    expect(calls, 1);
  });

  test('no session when nobody is signed in', () async {
    final controller = SessionController(
      users: InMemoryUserRepository(signedIn: null),
      groups: InMemoryGroupRepository(),
    );

    await controller.restore();

    expect(controller.session, isNull);
  });

  test('no session when the user has no group yet', () async {
    final controller = SessionController(
      users: InMemoryUserRepository(),
      groups: InMemoryGroupRepository(memberships: const []),
    );

    await controller.restore();

    expect(controller.session, isNull);
    expect(() => controller.requireSession, throwsStateError);
  });
}
