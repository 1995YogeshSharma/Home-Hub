import 'group.dart';
import 'user.dart';

/// Who is signed in, and which group they are acting in right now.
class Session {
  Session({
    required this.user,
    required List<Membership> memberships,
    required this.active,
  }) : assert(
         memberships.contains(active),
         'active must be one of memberships',
       ),
       memberships = List.unmodifiable(memberships);

  final User user;

  /// Every group this user belongs to (for a group switcher later).
  final List<Membership> memberships;

  /// The group the user is acting in now, with their role in it.
  final Membership active;

  Group get group => active.group;
  GroupRole get role => active.role;
  bool get isAdmin => role.isAdmin;
}
