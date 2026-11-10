/// A person using Home Hub.
class User {
  const User({required this.id, required this.displayName});

  /// Opaque id; a UUID string once the server provides users.
  final String id;

  final String displayName;
}
