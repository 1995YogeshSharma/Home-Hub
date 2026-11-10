import '../core/models/group.dart';
import '../core/models/user.dart';

/// The only place fake people and groups exist.
abstract final class DemoData {
  static const asha = User(id: 'u-asha', displayName: 'Asha');
  static const ravi = User(id: 'u-ravi', displayName: 'Ravi');

  static const sharmaFamily = Group(
    code: 'sharma-family',
    name: 'Sharma Family',
  );
  static const bookClub = Group(code: 'book-club', name: 'Book Club');

  // String literals, because `asha.id` is not allowed in a const list.
  static const memberships = [
    Membership(userId: 'u-asha', group: sharmaFamily, role: GroupRole.admin),
    Membership(userId: 'u-asha', group: bookClub, role: GroupRole.member),
    Membership(userId: 'u-ravi', group: sharmaFamily, role: GroupRole.member),
  ];
}
