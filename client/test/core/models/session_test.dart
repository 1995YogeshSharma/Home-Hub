import 'package:flutter_test/flutter_test.dart';
import 'package:home_hub_client/core/models/group.dart';
import 'package:home_hub_client/core/models/session.dart';
import 'package:home_hub_client/core/models/user.dart';

const _asha = User(id: 'u-asha', displayName: 'Asha');
const _family = Group(code: 'sharma-family', name: 'Sharma Family');
const _club = Group(code: 'book-club', name: 'Book Club');
const _adminOfFamily = Membership(
  userId: 'u-asha',
  group: _family,
  role: GroupRole.admin,
);
const _memberOfClub = Membership(
  userId: 'u-asha',
  group: _club,
  role: GroupRole.member,
);

void main() {
  test('GroupRole knows admins and has a label', () {
    expect(GroupRole.admin.isAdmin, isTrue);
    expect(GroupRole.member.isAdmin, isFalse);
    expect(GroupRole.admin.label, 'Admin');
    expect(GroupRole.member.label, 'Member');
  });

  test('group and role come from the active membership', () {
    final session = Session(
      user: _asha,
      memberships: [_adminOfFamily, _memberOfClub],
      active: _memberOfClub,
    );

    expect(session.group.name, 'Book Club');
    expect(session.role, GroupRole.member);
    expect(session.isAdmin, isFalse);
  });

  test('the same user can be admin in another group', () {
    final session = Session(
      user: _asha,
      memberships: [_adminOfFamily, _memberOfClub],
      active: _adminOfFamily,
    );

    expect(session.isAdmin, isTrue);
  });

  test('memberships cannot be changed from outside', () {
    final session = Session(
      user: _asha,
      memberships: [_adminOfFamily],
      active: _adminOfFamily,
    );

    expect(
      () => session.memberships.add(_memberOfClub),
      throwsUnsupportedError,
    );
  });

  test('the active membership must be one of the memberships', () {
    expect(
      () => Session(
        user: _asha,
        memberships: [_adminOfFamily],
        active: _memberOfClub,
      ),
      throwsAssertionError,
    );
  });
}
