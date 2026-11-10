/// What a user may do inside one group.
enum GroupRole {
  admin('Admin'),
  member('Member');

  const GroupRole(this.label);

  /// Human-readable name for the UI.
  final String label;

  bool get isAdmin => this == GroupRole.admin;
}

/// A household, family or team. Data in Home Hub belongs to a group.
class Group {
  const Group({required this.code, required this.name});

  /// Stable identifier; matches `GroupCode` in the server's schema.
  final String code;

  final String name;
}

/// One user's place in one group, and their role there.
class Membership {
  const Membership({
    required this.userId,
    required this.group,
    required this.role,
  });

  final String userId;
  final Group group;
  final GroupRole role;
}
