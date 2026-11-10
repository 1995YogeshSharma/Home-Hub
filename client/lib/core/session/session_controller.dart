import 'package:flutter/foundation.dart';

import '../models/group.dart';
import '../models/session.dart';
import '../repositories/group_repository.dart';
import '../repositories/user_repository.dart';

/// App-wide "who am I, and in which group".
///
/// A [ChangeNotifier] so that, once onboarding exists, the router can listen
/// to it and redirect when the user signs in or out.
class SessionController extends ChangeNotifier {
  SessionController({required this._users, required this._groups});

  final UserRepository _users;
  final GroupRepository _groups;

  Session? _session;

  /// The current session, or null when nobody is signed in or the user has
  /// no group yet (both mean "needs onboarding").
  Session? get session => _session;

  /// The current session, for pages that are only reachable with one.
  Session get requireSession =>
      _session ??
      (throw StateError('No session: this page needs a user with a group'));

  /// Loads the signed-in user and their groups; the first group is active.
  Future<void> restore() async {
    final user = await _users.currentUser();
    final memberships = user == null
        ? const <Membership>[]
        : await _groups.membershipsOf(user.id);
    _session = (user == null || memberships.isEmpty)
        ? null
        : Session(
            user: user,
            memberships: memberships,
            active: memberships.first,
          );
    notifyListeners();
  }
}
